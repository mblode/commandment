import XCTest
@testable import Commandment

final class TranscriptionRetryTests: XCTestCase {
    func test_transcribeWithRetry_noAPIKey_failsImmediately() {
        let manager = TranscriptionManager()
        let expectation = expectation(description: "completion")

        manager.transcribeWithRetry(audioURL: URL(fileURLWithPath: "/tmp/does-not-matter.wav")) { result in
            guard case .failure(let error) = result, case .noAPIKey = error else {
                return XCTFail("Expected noAPIKey failure")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_transcribeStreaming_noAPIKey_failsImmediately() {
        let manager = TranscriptionManager()
        let expectation = expectation(description: "completion")

        // Use audioData overload to bypass file I/O and test API key check directly
        manager.transcribeStreaming(
            audioData: Data([0x00]),
            isM4A: false,
            onDelta: { _ in XCTFail("Expected no deltas when API key is missing") },
            completion: { result in
                guard case .failure(let error) = result, case .noAPIKey = error else {
                    return XCTFail("Expected noAPIKey failure")
                }
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
    }
}
