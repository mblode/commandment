import Foundation

protocol RecordingAudioManaging: AnyObject {
    var isRecording: Bool { get }
    var isMicrophonePermissionDenied: Bool { get }
    var audioChunkHandler: ((Data) -> Void)? { get set }

    func startRecording(completion: ((Bool) -> Void)?)
    func stopRecording() -> URL?
    func stopRecordingWithData() -> (url: URL, audioData: Data)?
    func convertToM4A(wavURL: URL) async -> URL?
}

extension RecordingAudioManaging {
    var isMicrophonePermissionDenied: Bool { false }
    func stopRecordingWithData() -> (url: URL, audioData: Data)? {
        guard let url = stopRecording() else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (url, data)
    }
    func convertToM4A(wavURL: URL) async -> URL? { nil }
}

extension AudioManager: RecordingAudioManaging {}

protocol RecordingTranscriptionManaging: AnyObject {
    var selectedModel: TranscriptionModel { get }
    var selectedLanguage: TranscriptionLanguage { get }
    var useRealtimeAPI: Bool { get }

    func getAPIKey() -> String?
    func prewarmConnection()
    func transcribeStreaming(
        audioURL: URL,
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, TranscriptionError>) -> Void
    )
    func transcribeStreaming(
        audioData: Data,
        isM4A: Bool,
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, TranscriptionError>) -> Void
    )
    func pasteText(_ text: String)
    func setStatusMessage(_ message: String)
}

extension RecordingTranscriptionManaging {
    var useRealtimeAPI: Bool { false }
    func prewarmConnection() {}
    func setStatusMessage(_ message: String) {}
    func transcribeStreaming(
        audioData: Data,
        isM4A: Bool,
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, TranscriptionError>) -> Void
    ) {}
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
