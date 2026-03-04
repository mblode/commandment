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

    func test_hotkeyDownAndUp_streamingFlow_pastesTranscript() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        transcription.streamingResult = .success("hello from streaming")

        audio.nextStopURL = try makeAudioFile(byteCount: 9_000, pathExtension: "wav")

        let startExpectation = expectation(description: "recording started")
        audio.onStartRecording = { startExpectation.fulfill() }

        let pasteExpectation = expectation(description: "transcript pasted")
        transcription.onPaste = { text in
            if text == "hello from streaming" {
                pasteExpectation.fulfill()
            }
        }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [pasteExpectation], timeout: 1.0)

        XCTAssertEqual(transcription.streamingCallCount, 1)
        XCTAssertEqual(transcription.pastedTexts, ["hello from streaming"])
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
            minimumRecordingDuration: 0.3
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [tooShortExpectation], timeout: 1.5)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
        XCTAssertEqual(transcription.streamingCallCount, 0)
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
            minimumRecordingDuration: 0.3
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)

        await fulfillment(of: [tooShortExpectation], timeout: 1.5)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
        XCTAssertEqual(transcription.streamingCallCount, 0)
    }

    func test_streamingFailure_showsError() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        transcription.streamingResult = .failure(.timeout)

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
            minimumRecordingDuration: 0
        )
        coordinator.errorDialogPresenter = { _, _ in } // bypass NSAlert.runModal() on CI
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [dismissExpectation], timeout: 1.5)

        XCTAssertEqual(transcription.streamingCallCount, 1)
        XCTAssertTrue(overlay.shownStates.contains(.processing))
    }

    func test_streamingDeltas_updateOverlay() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        transcription.streamingDeltas = ["Hello", " world"]
        transcription.streamingResult = .success("Hello world")

        audio.nextStopURL = try makeAudioFile(byteCount: 9_000, pathExtension: "wav")

        let startExpectation = expectation(description: "recording started")
        audio.onStartRecording = { startExpectation.fulfill() }

        let pasteExpectation = expectation(description: "transcript pasted")
        transcription.onPaste = { _ in pasteExpectation.fulfill() }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [pasteExpectation], timeout: 1.0)

        // Verify overlay showed success after streaming completed
        XCTAssertTrue(overlay.shownStates.contains(.success))
    }

    func test_holdMode_keyUpBeforeStart_stopsAfterStartCompletes() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        audio.setRecordingBeforeCompletion = false
        audio.startCompletionDelay = 0.05
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        transcription.streamingResult = .success("race condition fixed")

        audio.nextStopURL = try makeAudioFile(byteCount: 9_000, pathExtension: "wav")

        let pasteExpectation = expectation(description: "transcript pasted")
        transcription.onPaste = { _ in pasteExpectation.fulfill() }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
            notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        }

        await fulfillment(of: [pasteExpectation], timeout: 2.0)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
        XCTAssertEqual(transcription.streamingCallCount, 1)
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

private final class MockAudioManager: RecordingAudioManaging {
    var isRecording = false

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
    var streamingResult: Result<String, TranscriptionError> = .success("")
    var streamingDeltas: [String] = []
    var onPaste: ((String) -> Void)?

    private(set) var streamingCallCount = 0
    private(set) var pastedTexts: [String] = []

    init(model: TranscriptionModel, apiKey: String?) {
        self.selectedModel = model
        self.apiKey = apiKey
    }

    func getAPIKey() -> String? {
        apiKey
    }

    func transcribeStreaming(
        audioURL: URL,
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, TranscriptionError>) -> Void
    ) {
        streamingCallCount += 1
        for delta in streamingDeltas {
            onDelta(delta)
        }
        completion(streamingResult)
    }

    func pasteText(_ text: String) {
        pastedTexts.append(text)
        onPaste?(text)
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
