import SwiftUI
import Combine

@MainActor
class RecordingCoordinator: ObservableObject {
    private let audioManager: RecordingAudioManaging
    private let transcriptionManager: RecordingTranscriptionManaging
    private let notificationCenter: NotificationCenter
    private let overlay: OverlayPresenting
    private let minimumRecordingDuration: TimeInterval
    private let makeRealtimeClient: () -> RealtimeTranscribing
    private var cancellables = Set<AnyCancellable>()
    private var recordingStartTime: Date?
    private var delayedStopWork: DispatchWorkItem?
    private var lastSettingsPromptDate: Date?
    private let settingsPromptCooldown: TimeInterval = 5
    private var isStartingRecording = false
    private var stopRequestedBeforeStart = false
    private var realtimeClient: RealtimeTranscribing?
    var errorDialogPresenter: ((URL, Error) -> Void)?

    init(
        audioManager: RecordingAudioManaging,
        transcriptionManager: RecordingTranscriptionManaging,
        notificationCenter: NotificationCenter = .default,
        overlay: OverlayPresenting? = nil,
        minimumRecordingDuration: TimeInterval = 0.3,
        makeRealtimeClient: @escaping () -> RealtimeTranscribing = { RealtimeTranscriptionClient() }
    ) {
        logInfo("RecordingCoordinator: Initializing")
        self.audioManager = audioManager
        self.transcriptionManager = transcriptionManager
        self.notificationCenter = notificationCenter
        self.overlay = overlay ?? LiveOverlayPresenter.shared
        self.minimumRecordingDuration = minimumRecordingDuration
        self.makeRealtimeClient = makeRealtimeClient

        notificationCenter.publisher(for: NSNotification.Name("HotkeyKeyDown"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleHotkeyDown() }
            .store(in: &cancellables)

        notificationCenter.publisher(for: NSNotification.Name("HotkeyKeyUp"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleHotkeyUp() }
            .store(in: &cancellables)
    }

    // MARK: - Hotkey Handling

    private func handleHotkeyDown() {
        startRecordingFromHotkey()
    }

    private func handleHotkeyUp() {
        stopRecordingFromHotkey()
    }

    // MARK: - Start Recording

    private func startRecordingFromHotkey() {
        guard !audioManager.isRecording && !isStartingRecording else {
            logDebug("RecordingCoordinator: Recording already active or starting, ignoring key-down")
            return
        }

        guard let apiKey = transcriptionManager.getAPIKey() else {
            handleMissingAPIKeyGuidance()
            return
        }

        delayedStopWork?.cancel()
        delayedStopWork = nil
        stopRequestedBeforeStart = false
        isStartingRecording = true

        // Connect Realtime API WebSocket before recording starts
        let client = makeRealtimeClient()
        client.connect(apiKey: apiKey, model: transcriptionManager.selectedModel.modelID, language: transcriptionManager.selectedLanguage.rawValue)
        self.realtimeClient = client
        audioManager.audioChunkHandler = { [weak client] pcm16Data in
            client?.sendAudioChunk(pcm16Data)
        }

        audioManager.startRecording { [weak self] (didStart: Bool) in
            guard let self else { return }
            self.isStartingRecording = false
            if didStart {
                self.recordingStartTime = Date()
                self.overlay.show(state: .recording)
                if self.stopRequestedBeforeStart {
                    self.stopRequestedBeforeStart = false
                    self.stopRecordingFromHotkey()
                }
            } else {
                self.stopRequestedBeforeStart = false
                self.realtimeClient?.disconnect()
                self.realtimeClient = nil
                self.audioManager.audioChunkHandler = nil
                self.overlay.dismiss()
                if self.audioManager.isMicrophonePermissionDenied {
                    logInfo("RecordingCoordinator: Recording start blocked by missing microphone permission")
                    self.transcriptionManager.setStatusMessage("Microphone permission is required. Enable it in System Settings > Privacy & Security > Microphone.")
                } else {
                    self.showRecordingError()
                }
            }
        }
    }

    // MARK: - Stop Recording

    private func stopRecordingFromHotkey() {
        if audioManager.isRecording {
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
            return
        }

        if isStartingRecording {
            stopRequestedBeforeStart = true
            logDebug("RecordingCoordinator: Stop requested before recording started; will stop once start completes")
        } else {
            logDebug("RecordingCoordinator: Not recording, ignoring key-up")
        }
    }

    private func performStopRecording() {
        delayedStopWork?.cancel()
        delayedStopWork = nil
        recordingStartTime = nil
        stopRequestedBeforeStart = false
        isStartingRecording = false

        overlay.show(state: .processing)

        guard let recordingURL = audioManager.stopRecording() else {
            overlay.dismiss()
            realtimeClient?.disconnect()
            realtimeClient = nil
            audioManager.audioChunkHandler = nil
            logError("RecordingCoordinator: Failed to stop recording - no file returned")
            return
        }

        audioManager.audioChunkHandler = nil

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: recordingURL.path)[.size] as? Int64) ?? 0

        // Minimum ~125ms of 24kHz mono float32 audio
        let minimumFileSize: Int64 = 6000
        guard fileSize >= minimumFileSize else {
            logInfo("RecordingCoordinator: Recording too short (\(fileSize) bytes)")
            realtimeClient?.disconnect()
            realtimeClient = nil
            overlay.show(state: .tooShort)
            return
        }

        logInfo("RecordingCoordinator: Recording file size: \(fileSize) bytes")

        guard let client = realtimeClient else {
            logError("RecordingCoordinator: No Realtime client available")
            overlay.dismiss()
            return
        }
        realtimeClient = nil

        client.commitAndTranscribe(
            onDelta: { _ in },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let text):
                        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            logInfo("RecordingCoordinator: Empty transcript")
                            self.overlay.show(state: .tooShort)
                        } else {
                            logInfo("RecordingCoordinator: Transcript (\(text.count) chars): \(text.prefix(50))...")
                            self.overlay.show(state: .success)
                            self.transcriptionManager.pasteText(text)
                        }
                    case .failure(let error):
                        self.overlay.dismiss()
                        logError("RecordingCoordinator: Transcription failed: \(error.localizedDescription)")
                        self.showTranscriptionError(recordingURL: recordingURL, error: error)
                    }
                    client.disconnect()
                }
            }
        )
    }

    // MARK: - Error Handling

    private func handleMissingAPIKeyGuidance() {
        transcriptionManager.setStatusMessage("Add your OpenAI API key in Settings to start dictating.")

        let now = Date()
        if let lastSettingsPromptDate, now.timeIntervalSince(lastSettingsPromptDate) < settingsPromptCooldown {
            return
        }

        logInfo("RecordingCoordinator: Opening settings to configure missing API key")
        self.lastSettingsPromptDate = now
        SettingsWindowController.shared.show()
    }

    private func showRecordingError() {
        let alert = NSAlert()
        alert.messageText = "Recording Error"
        alert.informativeText = "Failed to capture audio recording. Please try again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showTranscriptionError(recordingURL: URL, error: Error) {
        if let errorDialogPresenter {
            errorDialogPresenter(recordingURL, error)
            return
        }
        logInfo("Showing transcription error dialog")

        let alert = NSAlert()
        alert.messageText = "Transcription Error"
        alert.informativeText = """
        Failed to transcribe audio.

        Error: \(error.localizedDescription)

        Open logs for full diagnostic details.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Show in Finder")
        alert.addButton(withTitle: "Show Logs")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            logInfo("RecordingCoordinator: Showing in Finder: \(recordingURL)")
            NSWorkspace.shared.selectFile(recordingURL.path, inFileViewerRootedAtPath: "")

        case .alertSecondButtonReturn:
            logInfo("RecordingCoordinator: Opening log file")
            Logger.shared.openLogFile()

        default:
            logInfo("RecordingCoordinator: Transcription error dismissed")
        }
    }
}
