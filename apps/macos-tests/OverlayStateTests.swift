import XCTest
@testable import Commandment

final class OverlayStateTests: XCTestCase {

    func test_equatable_sameCase() {
        XCTAssertEqual(OverlayState.recording, OverlayState.recording)
        XCTAssertEqual(OverlayState.transcribing("hello"), OverlayState.transcribing("hello"))
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
        XCTAssertNotEqual(OverlayState.transcribing("a"), OverlayState.transcribing("b"))
        XCTAssertNotEqual(OverlayState.transcribing("text"), OverlayState.recording)
    }

    func test_allCasesDistinct() {
        let states: [OverlayState] = [.recording, .transcribing("test"), .processing, .success, .copiedToClipboard, .tooShort]
        let unique = Set(states.map { "\($0)" })
        XCTAssertEqual(unique.count, 6)
    }
}
