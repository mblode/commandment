import Foundation

protocol RecordingAudioManaging: AnyObject {
    var isRecording: Bool { get }
    var isMicrophonePermissionDenied: Bool { get }
    var onAudioChunk: ((Data) -> Void)? { get set }

    func startRecording(completion: ((Bool) -> Void)?)
    func stopRecording() -> URL?
    func convertToM4A(wavURL: URL) async -> URL?
}

extension RecordingAudioManaging {
    var isMicrophonePermissionDenied: Bool { false }
}

extension AudioManager: RecordingAudioManaging {}

protocol RecordingTranscriptionManaging: AnyObject {
    var selectedModel: TranscriptionModel { get }

    func getAPIKey() -> String?
    func transcribeWithRetry(audioURL: URL, completion: @escaping (Result<String, TranscriptionError>) -> Void)
    func pasteText(_ text: String)
    func setStatusMessage(_ message: String)
}

extension RecordingTranscriptionManaging {
    func setStatusMessage(_ message: String) {}
}

extension TranscriptionManager: RecordingTranscriptionManaging {}

protocol RealtimeTranscribing: AnyObject {
    func connect(completion: @escaping (Bool) -> Void)
    func sendAudioChunk(_ pcm16Data: Data)
    func commitAudio(onTranscript: @escaping (String) -> Void, onError: @escaping (Error) -> Void)
    func disconnect()
}

extension RealtimeTranscriptionManager: RealtimeTranscribing {}

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
