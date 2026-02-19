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

    func test_hotkeyDownAndUp_realtimeFlow_commitsAndPastesTranscript() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        let realtimeFactory = RealtimeFactorySpy()
        let realtime = MockRealtimeManager()
        realtime.commitTranscript = "hello from realtime"
        realtimeFactory.nextManager = realtime

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
            realtimeFactory: realtimeFactory.make
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [pasteExpectation], timeout: 1.0)

        XCTAssertEqual(realtimeFactory.createdManagers.count, 1)
        XCTAssertEqual(realtime.connectCallCount, 1)
        XCTAssertEqual(realtime.commitAudioCallCount, 1)
        XCTAssertEqual(realtime.disconnectCallCount, 1)
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
        let realtimeFactory = RealtimeFactorySpy()
        let realtime = MockRealtimeManager()
        realtimeFactory.nextManager = realtime

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
            realtimeFactory: realtimeFactory.make
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [tooShortExpectation], timeout: 1.5)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
        XCTAssertEqual(transcription.transcribeCallCount, 0)
        XCTAssertEqual(realtime.connectCallCount, 1)
        XCTAssertEqual(realtime.commitAudioCallCount, 0)
        XCTAssertTrue(overlay.shownStates.contains(.tooShort))
    }

    func test_rapidKeyUps_cancelPriorDelayedStop() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        let realtimeFactory = RealtimeFactorySpy()
        let realtime = MockRealtimeManager()
        realtimeFactory.nextManager = realtime

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
            realtimeFactory: realtimeFactory.make
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)

        await fulfillment(of: [tooShortExpectation], timeout: 1.5)

        XCTAssertEqual(audio.stopRecordingCallCount, 1)
        XCTAssertEqual(realtime.connectCallCount, 1)
        XCTAssertEqual(realtime.commitAudioCallCount, 0)
    }

    func test_realtimeCommitError_fallsBackToRest() async throws {
        let notifications = NotificationCenter()
        let overlay = OverlaySpy()
        let audio = MockAudioManager()
        let transcription = MockTranscriptionManager(model: .gpt4oMiniTranscribe, apiKey: "test-key")
        let realtimeFactory = RealtimeFactorySpy()
        let realtime = MockRealtimeManager()
        realtime.commitError = NSError(domain: "RecordingCoordinatorTests", code: 1)
        realtimeFactory.nextManager = realtime

        let wavURL = try makeAudioFile(byteCount: 9_000, pathExtension: "wav")
        let m4aURL = try makeAudioFile(byteCount: 3_000, pathExtension: "m4a")
        audio.nextStopURL = wavURL
        audio.nextM4AURL = m4aURL
        transcription.transcribeResult = .success("hello from rest")

        let startExpectation = expectation(description: "recording started")
        audio.onStartRecording = { startExpectation.fulfill() }

        let pasteExpectation = expectation(description: "rest transcript pasted")
        transcription.onPaste = { text in
            if text == "hello from rest" {
                pasteExpectation.fulfill()
            }
        }

        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription,
            notificationCenter: notifications,
            overlay: overlay,
            minimumRecordingDuration: 0,
            realtimeFactory: realtimeFactory.make
        )
        withExtendedLifetime(coordinator) {
            notifications.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        await fulfillment(of: [startExpectation], timeout: 1.0)

        notifications.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        await fulfillment(of: [pasteExpectation], timeout: 1.5)

        XCTAssertEqual(realtimeFactory.createdManagers.count, 1)
        XCTAssertEqual(realtime.connectCallCount, 1)
        XCTAssertEqual(realtime.commitAudioCallCount, 1)
        XCTAssertEqual(realtime.disconnectCallCount, 1)
        XCTAssertEqual(transcription.transcribeCallCount, 1)
        XCTAssertEqual(transcription.transcribedURLs.first?.pathExtension.lowercased(), "m4a")
        XCTAssertEqual(audio.convertToM4ACallCount, 1)
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
    var onAudioChunk: ((Data) -> Void)?

    var onStartRecording: (() -> Void)?
    var nextStopURL: URL?
    var nextM4AURL: URL?

    private(set) var stopRecordingCallCount = 0
    private(set) var convertToM4ACallCount = 0

    func startRecording(completion: ((Bool) -> Void)?) {
        isRecording = true
        onStartRecording?()
        completion?(true)
    }

    func stopRecording() -> URL? {
        stopRecordingCallCount += 1
        isRecording = false
        return nextStopURL
    }

    func convertToM4A(wavURL: URL) async -> URL? {
        convertToM4ACallCount += 1
        return nextM4AURL
    }
}

private final class MockTranscriptionManager: RecordingTranscriptionManaging {
    var selectedModel: TranscriptionModel
    var apiKey: String?
    var transcribeResult: Result<String, TranscriptionError> = .success("")
    var onPaste: ((String) -> Void)?

    private(set) var transcribeCallCount = 0
    private(set) var transcribedURLs: [URL] = []
    private(set) var pastedTexts: [String] = []

    init(model: TranscriptionModel, apiKey: String?) {
        self.selectedModel = model
        self.apiKey = apiKey
    }

    func getAPIKey() -> String? {
        apiKey
    }

    func transcribeWithRetry(audioURL: URL, completion: @escaping (Result<String, TranscriptionError>) -> Void) {
        transcribeCallCount += 1
        transcribedURLs.append(audioURL)
        completion(transcribeResult)
    }

    func pasteText(_ text: String) {
        pastedTexts.append(text)
        onPaste?(text)
    }
}

private final class MockRealtimeManager: RealtimeTranscribing {
    var commitTranscript = ""
    var commitError: Error?

    private(set) var connectCallCount = 0
    private(set) var commitAudioCallCount = 0
    private(set) var disconnectCallCount = 0

    func connect(completion: @escaping (Bool) -> Void) {
        connectCallCount += 1
        completion(true)
    }

    func sendAudioChunk(_ pcm16Data: Data) {}

    func commitAudio(onTranscript: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        commitAudioCallCount += 1
        if let commitError {
            onError(commitError)
        } else {
            onTranscript(commitTranscript)
        }
    }

    func disconnect() {
        disconnectCallCount += 1
    }
}

private final class RealtimeFactorySpy {
    var nextManager: MockRealtimeManager?
    private(set) var createdManagers: [MockRealtimeManager] = []

    func make(_ apiKey: String, _ model: String) -> RealtimeTranscribing {
        let manager = nextManager ?? MockRealtimeManager()
        createdManagers.append(manager)
        return manager
    }
}

@MainActor
private final class OverlaySpy: OverlayPresenting {
    private(set) var shownStates: [OverlayState] = []
    var onShow: ((OverlayState) -> Void)?

    func show(state: OverlayState) {
        shownStates.append(state)
        onShow?(state)
    }

    func dismiss() {}
}
