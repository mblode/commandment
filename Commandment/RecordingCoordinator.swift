import SwiftUI
import Combine

@MainActor
class RecordingCoordinator: ObservableObject {
    private let audioManager: RecordingAudioManaging
    private let transcriptionManager: RecordingTranscriptionManaging
    private let notificationCenter: NotificationCenter
    private let overlay: OverlayPresenting
    private let minimumRecordingDuration: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    private var recordingStartTime: Date?
    private var delayedStopWork: DispatchWorkItem?
    private var lastSettingsPromptDate: Date?
    private let settingsPromptCooldown: TimeInterval = 5
    private var isStartingRecording = false
    private var stopRequestedBeforeStart = false
    private var realtimeClient: RealtimeTranscriptionClient?
    var errorDialogPresenter: ((URL, TranscriptionError) -> Void)?

    init(
        audioManager: RecordingAudioManaging,
        transcriptionManager: RecordingTranscriptionManaging,
        notificationCenter: NotificationCenter = .default,
        overlay: OverlayPresenting? = nil,
        minimumRecordingDuration: TimeInterval = 0.3
    ) {
        logInfo("RecordingCoordinator: Initializing")
        self.audioManager = audioManager
        self.transcriptionManager = transcriptionManager
        self.notificationCenter = notificationCenter
        self.overlay = overlay ?? LiveOverlayPresenter.shared
        self.minimumRecordingDuration = minimumRecordingDuration

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

        guard transcriptionManager.getAPIKey() != nil else {
            handleMissingAPIKeyGuidance()
            return
        }

        delayedStopWork?.cancel()
        delayedStopWork = nil
        stopRequestedBeforeStart = false
        isStartingRecording = true

        // Set up connection before recording starts
        if transcriptionManager.useRealtimeAPI, let apiKey = transcriptionManager.getAPIKey() {
            let client = RealtimeTranscriptionClient()
            client.connect(apiKey: apiKey, model: transcriptionManager.selectedModel.modelID)
            self.realtimeClient = client
            audioManager.audioChunkHandler = { [weak client] pcm16Data in
                client?.sendAudioChunk(pcm16Data)
            }
        } else {
            // Pre-warm TCP+TLS connection so it's ready when recording stops
            transcriptionManager.prewarmConnection()
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

        guard let result = audioManager.stopRecordingWithData() else {
            overlay.dismiss()
            logError("RecordingCoordinator: Failed to stop recording - no file returned")
            return
        }

        let recordingURL = result.url
        let audioData = result.audioData

        // Minimum ~125ms of 24kHz mono float32 audio
        let minimumFileSize = 6000
        guard audioData.count >= minimumFileSize else {
            logInfo("RecordingCoordinator: Recording too short (\(audioData.count) bytes)")
            overlay.show(state: .tooShort)
            return
        }

        logInfo("RecordingCoordinator: Recording data size: \(audioData.count) bytes")

        // Realtime API path: audio was already streamed during recording
        if let client = realtimeClient {
            audioManager.audioChunkHandler = nil
            realtimeClient = nil
            client.commitAndTranscribe(
                onDelta: { _ in },
                completion: { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let text):
                            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                logInfo("RecordingCoordinator: Empty transcript (Realtime)")
                                self.overlay.show(state: .tooShort)
                            } else {
                                logInfo("RecordingCoordinator: Transcript (Realtime, \(text.count) chars): \(text.prefix(50))...")
                                self.overlay.show(state: .success)
                                self.transcriptionManager.pasteText(text)
                            }
                        case .failure(let error):
                            logError("RecordingCoordinator: Realtime transcription failed: \(error.description), falling back to REST")
                            // Fall back to REST streaming
                            self.sendTranscription(audioData: audioData, isM4A: false, recordingURL: recordingURL)
                        }
                        client.disconnect()
                    }
                }
            )
            return
        }

        // REST path: compress and upload
        let compressionThreshold = 192_000
        if audioData.count > compressionThreshold {
            Task {
                if let m4aURL = await audioManager.convertToM4A(wavURL: recordingURL),
                   let m4aData = try? Data(contentsOf: m4aURL) {
                    self.sendTranscription(audioData: m4aData, isM4A: true, recordingURL: recordingURL)
                } else {
                    logInfo("RecordingCoordinator: M4A compression failed, using WAV")
                    self.sendTranscription(audioData: audioData, isM4A: false, recordingURL: recordingURL)
                }
            }
            return
        }

        sendTranscription(audioData: audioData, isM4A: false, recordingURL: recordingURL)
    }

    private func sendTranscription(audioData: Data, isM4A: Bool, recordingURL: URL) {
        // Use streaming REST transcription — sends in-memory audio, receives SSE deltas
        var accumulatedTranscript = ""
        transcriptionManager.transcribeStreaming(
            audioData: audioData,
            isM4A: isM4A,
            onDelta: { delta in
                accumulatedTranscript += delta
            },
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
                        if case .noAPIKey = error {
                            self.handleMissingAPIKeyGuidance()
                        } else {
                            logError("RecordingCoordinator: Transcription failed: \(error.description)")
                            self.showTranscriptionErrorWithOptions(recordingURL: recordingURL, error: error)
                        }
                    }
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

    private func showTranscriptionErrorWithOptions(recordingURL: URL, error: TranscriptionError) {
        if let errorDialogPresenter {
            errorDialogPresenter(recordingURL, error)
            return
        }
        logInfo("Showing transcription error dialog with options")

        let alert = NSAlert()
        alert.messageText = "Transcription Error"
        alert.informativeText = """
        Failed to transcribe audio.

        Last error: \(error.description)

        Open logs for full diagnostic details.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Show in Finder")
        alert.addButton(withTitle: "Show Logs")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            logInfo("RecordingCoordinator: Retrying transcription")
            var accumulatedTranscript = ""
            transcriptionManager.transcribeStreaming(
                audioURL: recordingURL,
                onDelta: { [weak self] delta in
                    accumulatedTranscript += delta
                    DispatchQueue.main.async {
                        self?.overlay.show(state: .transcribing(accumulatedTranscript))
                    }
                },
                completion: { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let text):
                            self.overlay.show(state: .success)
                            self.transcriptionManager.pasteText(text)
                        case .failure(let retryError):
                            self.overlay.dismiss()
                            logError("RecordingCoordinator: Retry failed: \(retryError.description)")
                        }
                    }
                }
            )

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
