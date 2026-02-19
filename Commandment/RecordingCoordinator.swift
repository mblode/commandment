import SwiftUI
import Combine

@MainActor
class RecordingCoordinator: ObservableObject {
    private let audioManager: RecordingAudioManaging
    private let transcriptionManager: RecordingTranscriptionManaging
    private let notificationCenter: NotificationCenter
    private let overlay: OverlayPresenting
    private let minimumRecordingDuration: TimeInterval
    private let realtimeFactory: (String, String) -> RealtimeTranscribing
    private var cancellables = Set<AnyCancellable>()
    private var recordingStartTime: Date?
    private var realtimeManager: RealtimeTranscribing?
    private var delayedStopWork: DispatchWorkItem?

    init(
        audioManager: RecordingAudioManaging,
        transcriptionManager: RecordingTranscriptionManaging,
        notificationCenter: NotificationCenter = .default,
        overlay: OverlayPresenting? = nil,
        minimumRecordingDuration: TimeInterval = 0.3,
        realtimeFactory: @escaping (String, String) -> RealtimeTranscribing = { apiKey, model in
            RealtimeTranscriptionManager(apiKey: apiKey, model: model)
        }
    ) {
        logInfo("RecordingCoordinator: Initializing")
        self.audioManager = audioManager
        self.transcriptionManager = transcriptionManager
        self.notificationCenter = notificationCenter
        self.overlay = overlay ?? LiveOverlayPresenter.shared
        self.minimumRecordingDuration = minimumRecordingDuration
        self.realtimeFactory = realtimeFactory

        notificationCenter.publisher(for: NSNotification.Name("HotkeyKeyDown"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.startRecordingFromHotkey() }
            .store(in: &cancellables)

        notificationCenter.publisher(for: NSNotification.Name("HotkeyKeyUp"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.stopRecordingFromHotkey() }
            .store(in: &cancellables)
    }

    // MARK: - Start Recording

    private func startRecordingFromHotkey() {
        guard !audioManager.isRecording else {
            logDebug("RecordingCoordinator: Already recording, ignoring key-down")
            return
        }

        guard let apiKey = transcriptionManager.getAPIKey() else {
            showNoAPIKeyError()
            return
        }

        // Start Realtime WebSocket connection in parallel with recording.
        let model = transcriptionManager.selectedModel.realtimeModelID
        let rtManager = realtimeFactory(apiKey, model)
        self.realtimeManager = rtManager

        audioManager.onAudioChunk = { [weak rtManager] (pcm16Data: Data) in
            rtManager?.sendAudioChunk(pcm16Data)
        }

        rtManager.connect { [weak self] connected in
            if !connected {
                logError("RecordingCoordinator: Realtime WebSocket failed to connect, will fall back to REST")
                DispatchQueue.main.async {
                    self?.realtimeManager?.disconnect()
                    self?.realtimeManager = nil
                    self?.audioManager.onAudioChunk = nil
                }
            }
        }

        audioManager.startRecording { [weak self] (didStart: Bool) in
            guard let self else { return }
            if didStart {
                self.recordingStartTime = Date()
                self.overlay.show(state: .recording)
            } else {
                self.realtimeManager?.disconnect()
                self.realtimeManager = nil
                self.audioManager.onAudioChunk = nil
                self.overlay.dismiss()
                self.showRecordingError()
            }
        }
    }

    // MARK: - Stop Recording

    private func stopRecordingFromHotkey() {
        guard audioManager.isRecording else {
            logDebug("RecordingCoordinator: Not recording, ignoring key-up")
            return
        }

        delayedStopWork?.cancel()
        delayedStopWork = nil

        // Enforce minimum recording duration so audio buffers have time to create the file
        if let startTime = recordingStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < minimumRecordingDuration {
                let remaining = minimumRecordingDuration - elapsed
                logInfo("RecordingCoordinator: Recording too short (\(Int(elapsed * 1000))ms), delaying stop by \(Int(remaining * 1000))ms")
                let work = DispatchWorkItem { [weak self] in
                    self?.delayedStopWork = nil
                    self?.performStopRecording()
                }
                delayedStopWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: work)
                return
            }
        }

        performStopRecording()
    }

    private func performStopRecording() {
        delayedStopWork?.cancel()
        delayedStopWork = nil
        recordingStartTime = nil
        audioManager.onAudioChunk = nil

        overlay.show(state: .processing)

        guard let recordingURL = audioManager.stopRecording() else {
            realtimeManager?.disconnect()
            realtimeManager = nil
            overlay.dismiss()
            logError("RecordingCoordinator: Failed to stop recording - no file returned")
            return
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: recordingURL.path)[.size] as? Int64) ?? 0

        // Minimum ~125ms of 24kHz mono float32 audio
        let minimumFileSize: Int64 = 6000
        guard fileSize >= minimumFileSize else {
            logInfo("RecordingCoordinator: Recording too short (\(fileSize) bytes)")
            realtimeManager?.disconnect()
            realtimeManager = nil
            overlay.show(state: .tooShort)
            return
        }

        logInfo("RecordingCoordinator: Recording file size: \(fileSize) bytes")

        // Try Realtime API first, fall back to REST
        if let rtManager = realtimeManager {
            logInfo("RecordingCoordinator: Committing audio via Realtime API")
            rtManager.commitAudio(
                onTranscript: { [weak self] transcript in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        self.realtimeManager?.disconnect()
                        self.realtimeManager = nil

                        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            logInfo("RecordingCoordinator: Empty transcript from Realtime API")
                            self.overlay.show(state: .tooShort)
                        } else {
                            logInfo("RecordingCoordinator: Realtime transcript (\(transcript.count) chars): \(transcript.prefix(50))...")
                            self.overlay.show(state: .success)
                            self.transcriptionManager.pasteText(transcript)
                        }
                    }
                },
                onError: { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        logError("RecordingCoordinator: Realtime API failed: \(error), falling back to REST")
                        self.realtimeManager?.disconnect()
                        self.realtimeManager = nil
                        self.fallbackToREST(recordingURL: recordingURL)
                    }
                }
            )
        } else {
            fallbackToREST(recordingURL: recordingURL)
        }
    }

    // MARK: - REST Fallback

    private func fallbackToREST(recordingURL: URL) {
        Task {
            let m4aURL = await audioManager.convertToM4A(wavURL: recordingURL)
            let urlToTranscribe = m4aURL ?? recordingURL
            logInfo("RecordingCoordinator: REST fallback using \(urlToTranscribe.pathExtension)")
            transcribeAudioViaREST(recordingURL: urlToTranscribe)
        }
    }

    private func transcribeAudioViaREST(recordingURL: URL) {
        logInfo("Beginning REST transcription for file: \(recordingURL.lastPathComponent)")

        transcriptionManager.transcribeWithRetry(audioURL: recordingURL) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    logInfo("Transcription successful: \(text.prefix(50))...")
                    self.overlay.show(state: .success)
                    self.transcriptionManager.pasteText(text)

                case .failure(let error):
                    self.overlay.dismiss()
                    if case .noAPIKey = error {
                        self.showNoAPIKeyError()
                    } else {
                        logError("RecordingCoordinator: Transcription failed: \(error.description)")
                        self.showTranscriptionErrorWithOptions(recordingURL: recordingURL)
                    }
                }
            }
        }
    }

    private func showNoAPIKeyError() {
        logInfo("Showing no API key dialog")
        let alert = NSAlert()
        alert.messageText = "No API Key"
        alert.informativeText = "Please add your OpenAI API key in Settings to enable transcription."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            SettingsWindowController.shared.show()
        }
    }

    private func showRecordingError() {
        let alert = NSAlert()
        alert.messageText = "Recording Error"
        alert.informativeText = "Failed to capture audio recording. Please try again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showTranscriptionErrorWithOptions(recordingURL: URL) {
        logInfo("Showing transcription error dialog with options")

        let alert = NSAlert()
        alert.messageText = "Transcription Error"
        alert.informativeText = "Failed to transcribe audio after multiple attempts. Please check your API key and internet connection."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Show in Finder")
        alert.addButton(withTitle: "View Logs")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            logInfo("RecordingCoordinator: Retrying transcription")
            transcribeAudioViaREST(recordingURL: recordingURL)

        case .alertSecondButtonReturn:
            logInfo("RecordingCoordinator: Showing in Finder: \(recordingURL)")
            NSWorkspace.shared.selectFile(recordingURL.path, inFileViewerRootedAtPath: "")

        case .alertThirdButtonReturn:
            logInfo("RecordingCoordinator: Opening log file")
            Logger.shared.openLogFile()

        default:
            logInfo("RecordingCoordinator: Transcription error dismissed")
        }
    }
}
