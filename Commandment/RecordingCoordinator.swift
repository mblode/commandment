import SwiftUI
import Combine

@MainActor
class RecordingCoordinator: ObservableObject {
    private let audioManager: AudioManager
    private let transcriptionManager: TranscriptionManager
    private var cancellables = Set<AnyCancellable>()

    init(audioManager: AudioManager, transcriptionManager: TranscriptionManager) {
        logInfo("RecordingCoordinator: Initializing")
        self.audioManager = audioManager
        self.transcriptionManager = transcriptionManager

        NotificationCenter.default.publisher(for: NSNotification.Name("HotkeyPressed"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.toggleRecording() }
            .store(in: &cancellables)
    }

    private func toggleRecording() {
        guard audioManager.isRecording else {
            audioManager.startRecording { [weak self] didStart in
                guard let self else { return }
                if didStart {
                    OverlayPanelController.shared.show(state: .recording)
                } else {
                    OverlayPanelController.shared.dismiss()
                    self.showRecordingError()
                }
            }
            return
        }

        OverlayPanelController.shared.show(state: .processing)

        guard let recordingURL = audioManager.stopRecording() else {
            OverlayPanelController.shared.dismiss()
            return
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: recordingURL.path)[.size] as? Int64) ?? 0
        guard fileSize > 0 else {
            OverlayPanelController.shared.dismiss()
            logError("RecordingCoordinator: Recording file is empty or unreadable")
            showRecordingError()
            return
        }

        logInfo("RecordingCoordinator: Recording file size: \(fileSize) bytes")
        transcribeAudio(recordingURL: recordingURL)
    }

    private func transcribeAudio(recordingURL: URL) {
        logInfo("Beginning transcription for file: \(recordingURL.lastPathComponent)")

        transcriptionManager.transcribeWithRetry(audioURL: recordingURL) { [weak self] text in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let text = text {
                    logInfo("Transcription successful: \(text.prefix(50))...")
                    OverlayPanelController.shared.show(state: .success)
                    self.transcriptionManager.pasteText(text)
                } else {
                    logError("RecordingCoordinator: Transcription failed after retries")
                    OverlayPanelController.shared.dismiss()
                    self.showTranscriptionErrorWithOptions(recordingURL: recordingURL)
                }
            }
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
            transcribeAudio(recordingURL: recordingURL)

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
