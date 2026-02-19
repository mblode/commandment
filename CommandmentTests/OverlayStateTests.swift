import XCTest
@testable import Commandment

final class OverlayStateTests: XCTestCase {

    func test_equatable_sameCase() {
        XCTAssertEqual(OverlayState.recording, OverlayState.recording)
        XCTAssertEqual(OverlayState.processing, OverlayState.processing)
        XCTAssertEqual(OverlayState.success, OverlayState.success)
        XCTAssertEqual(OverlayState.copiedToClipboard, OverlayState.copiedToClipboard)
        XCTAssertEqual(OverlayState.tooShort, OverlayState.tooShort)
    }

    func test_equatable_differentCases() {
        XCTAssertNotEqual(OverlayState.recording, OverlayState.processing)
        XCTAssertNotEqual(OverlayState.processing, OverlayState.success)
        XCTAssertNotEqual(OverlayState.recording, OverlayState.success)
        XCTAssertNotEqual(OverlayState.success, OverlayState.tooShort)
        XCTAssertNotEqual(OverlayState.copiedToClipboard, OverlayState.success)
    }

    func test_allCasesDistinct() {
        let states: [OverlayState] = [.recording, .processing, .success, .copiedToClipboard, .tooShort]
        let unique = Set(states.map { "\($0)" })
        XCTAssertEqual(unique.count, 5)
    }
}
