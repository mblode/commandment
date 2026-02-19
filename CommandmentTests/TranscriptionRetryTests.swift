import XCTest
@testable import Commandment

final class TranscriptionRetryTests: XCTestCase {

    func test_retryDelay_attempt1() {
        XCTAssertEqual(TranscriptionManager.retryDelay(forAttempt: 1), 1.0)
    }

    func test_retryDelay_attempt2() {
        XCTAssertEqual(TranscriptionManager.retryDelay(forAttempt: 2), 2.0)
    }

    func test_retryDelay_attempt3() {
        XCTAssertEqual(TranscriptionManager.retryDelay(forAttempt: 3), 4.0)
    }
}
