import Foundation

protocol RecordingAudioManaging: AnyObject {
    var isRecording: Bool { get }
    var isMicrophonePermissionDenied: Bool { get }

    func startRecording(completion: ((Bool) -> Void)?)
    func stopRecording() -> URL?
}

extension RecordingAudioManaging {
    var isMicrophonePermissionDenied: Bool { false }
}

extension AudioManager: RecordingAudioManaging {}

protocol RecordingTranscriptionManaging: AnyObject {
    var selectedModel: TranscriptionModel { get }
    var selectedLanguage: TranscriptionLanguage { get }

    func getAPIKey() -> String?
    func transcribeStreaming(
        audioURL: URL,
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, TranscriptionError>) -> Void
    )
    func pasteText(_ text: String)
    func setStatusMessage(_ message: String)
}

extension RecordingTranscriptionManaging {
    func setStatusMessage(_ message: String) {}
}

extension TranscriptionManager: RecordingTranscriptionManaging {}

@MainActor
protocol OverlayPresenting: AnyObject {
    func show(state: OverlayState)
    func dismiss()
}

@MainActor
final class LiveOverlayPresenter: OverlayPresenting {
    static let shared = LiveOverlayPresenter()

    private init() {}

    func show(state: OverlayState) {
        OverlayPanelController.shared.show(state: state)
    }

    func dismiss() {
        OverlayPanelController.shared.dismiss()
    }
}
