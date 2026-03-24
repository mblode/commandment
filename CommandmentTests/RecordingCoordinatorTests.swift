import XCTest
@testable import Commandment

@MainActor
final class RecordingCoordinatorTests: XCTestCase {
    private var tempURLs: [URL] = []

    override func tearDown() {
        for url in tempURLs {
            try? FileManager.default.removeItem(at: url)
        }
        tempURLs.removeAll()
        super.tearDown()
    }

    func test_hotkeyDownAndUp_realtimeFlow_pastesTranscript() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        let mockClient = MockRealtimeClient()
        mockClient.transcriptionResult = .success("hello from realtime")

        audio.nextStopURL = try makeAudioFile(byteCount: 9_000, pathExtension: "wav")

        let startExpectation = expectation(description: "recording started")
        audio.onStartRecording = { startExpectation.fulfill() }

        let pasteExpectation = expectation(description: "transcript pasted")
        transcription.onPaste = { text in
            if text == "hello from realtime" {
                pasteExpectation.fulfill()
            }
        }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0,
            makeRealtimeClient: { mockClient }
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [pasteExpectation], timeout: 1.0)

        XCTAssertEqual(mockClient.commitCallCount, 1)
        XCTAssertEqual(transcription.pastedTexts, ["hello from realtime"])
        XCTAssertTrue(overlay.shownStates.contains(.recording))
        XCTAssertTrue(overlay.shownStates.contains(.processing))
        XCTAssertTrue(overlay.shownStates.contains(.success))
    }

    func test_shortHold_showsTooShortOverlay() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")

        audio.nextStopURL = try makeAudioFile(byteCount: 1_000, pathExtension: "wav")

        let startExpectation = expectation(description: "recording started")
        audio.onStartRecording = { startExpectation.fulfill() }

        let tooShortExpectation = expectation(description: "too short shown")
        overlay.onShow = { state in
            if state == .tooShort {
                tooShortExpectation.fulfill()
            }
        }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0.3,
            makeRealtimeClient: { MockRealtimeClient() }
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [tooShortExpectation], timeout: 1.5)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
        XCTAssertTrue(overlay.shownStates.contains(.tooShort))
    }

    func test_rapidKeyUps_cancelPriorDelayedStop() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")

        audio.nextStopURL = try makeAudioFile(byteCount: 1_000, pathExtension: "wav")

        let startExpectation = expectation(description: "recording started")
        audio.onStartRecording = { startExpectation.fulfill() }

        let tooShortExpectation = expectation(description: "too short shown")
        overlay.onShow = { state in
            if state == .tooShort {
                tooShortExpectation.fulfill()
            }
        }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0.3,
            makeRealtimeClient: { MockRealtimeClient() }
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)

        await fulfillment(of: [tooShortExpectation], timeout: 1.5)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
    }

    func test_realtimeFailure_showsError() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        let mockClient = MockRealtimeClient()
        mockClient.transcriptionResult = .failure(RealtimeTranscriptionClient.ClientError.transcriptionFailed("test error"))

        audio.nextStopURL = try makeAudioFile(byteCount: 9_000, pathExtension: "wav")

        let startExpectation = expectation(description: "recording started")
        audio.onStartRecording = { startExpectation.fulfill() }

        let dismissExpectation = expectation(description: "overlay dismissed")
        overlay.onDismiss = { dismissExpectation.fulfill() }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0,
            makeRealtimeClient: { mockClient }
        )
        coordinator.errorDialogPresenter = { _, _ in }
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [dismissExpectation], timeout: 1.5)

        XCTAssertEqual(mockClient.commitCallCount, 1)
        XCTAssertTrue(overlay.shownStates.contains(.processing))
    }

    func test_holdMode_keyUpBeforeStart_stopsAfterStartCompletes() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        audio.setRecordingBeforeCompletion = false
        audio.startCompletionDelay = 0.05
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        let mockClient = MockRealtimeClient()
        mockClient.transcriptionResult = .success("race condition fixed")

        audio.nextStopURL = try makeAudioFile(byteCount: 9_000, pathExtension: "wav")

        let pasteExpectation = expectation(description: "transcript pasted")
        transcription.onPaste = { _ in pasteExpectation.fulfill() }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0,
            makeRealtimeClient: { mockClient }
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
            notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        }

        await fulfillment(of: [pasteExpectation], timeout: 2.0)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
        XCTAssertEqual(mockClient.commitCallCount, 1)
    }

    private func makeAudioFile(byteCount: Int, pathExtension: String) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("commandment-test-\(UUID().uuidString)")
            .appendingPathExtension(pathExtension)
        let data = Data(repeating: 0x2A, count: byteCount)
        try data.write(to: url)
        tempURLs.append(url)
        return url
    }
}

// MARK: - Mocks

private final class MockAudioManager: RecordingAudioManaging {
    var isRecording = false
    var audioChunkHandler: ((Data) -> Void)?

    var onStartRecording: (() -> Void)?
    var nextStopURL: URL?
    var startCompletionDelay: TimeInterval = 0
    var setRecordingBeforeCompletion = true

    private(set) var stopRecordingCallCount = 0

    func startRecording(completion: ((Bool) -> Void)?) {
        onStartRecording?()

        if setRecordingBeforeCompletion {
            isRecording = true
            if startCompletionDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + startCompletionDelay) {
                    completion?(true)
                }
            } else {
                completion?(true)
            }
            return
        }

        let completeStart = { [weak self] in
            self?.isRecording = true
            completion?(true)
        }

        if startCompletionDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + startCompletionDelay, execute: completeStart)
        } else {
            completeStart()
        }
    }

    func stopRecording() -> URL? {
        stopRecordingCallCount += 1
        isRecording = false
        return nextStopURL
    }
}

private final class MockTranscriptionManager: RecordingTranscriptionManaging {
    var selectedModel: TranscriptionModel
    var selectedLanguage: TranscriptionLanguage = .en
    var apiKey: String?
    var onPaste: ((String) -> Void)?

    private(set) var pastedTexts: [String] = []

    init(model: TranscriptionModel, apiKey: String?) {
        self.selectedModel = model
        self.apiKey = apiKey
    }

    func getAPIKey() -> String? {
        apiKey
    }

    func pasteText(_ text: String) {
        pastedTexts.append(text)
        onPaste?(text)
    }
}

private final class MockRealtimeClient: RealtimeTranscribing {
    var transcriptionResult: Result<String, Error> = .success("")
    private(set) var connectCallCount = 0
    private(set) var commitCallCount = 0
    private(set) var disconnectCallCount = 0

    func connect(apiKey: String, model: String, language: String) {
        connectCallCount += 1
    }

    func sendAudioChunk(_ pcm16Data: Data) {}

    func commitAndTranscribe(
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        commitCallCount += 1
        completion(transcriptionResult)
    }

    func disconnect() {
        disconnectCallCount += 1
    }
}

@MainActor
private final class OverlaySpy: OverlayPresenting {
    private(set) var shownStates: [OverlayState] = []
    var onShow: ((OverlayState) -> Void)?
    var onDismiss: (() -> Void)?

    func show(state: OverlayState) {
        shownStates.append(state)
        onShow?(state)
    }

    func dismiss() {
        onDismiss?()
    }
}
