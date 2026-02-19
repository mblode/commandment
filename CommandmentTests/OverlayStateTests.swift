import XCTest
@testable import Commandment

final class OverlayStateTests: XCTestCase {

    func test_equatable_sameCase() {
        XCTAssertEqual(OverlayState.recording, OverlayState.recording)
        XCTAssertEqual(OverlayState.processing, OverlayState.processing)
        XCTAssertEqual(OverlayState.success, OverlayState.success)
    }

    func test_equatable_differentCases() {
        XCTAssertNotEqual(OverlayState.recording, OverlayState.processing)
        XCTAssertNotEqual(OverlayState.processing, OverlayState.success)
        XCTAssertNotEqual(OverlayState.recording, OverlayState.success)
    }

    func test_allThreeCasesDistinct() {
        let states: [OverlayState] = [.recording, .processing, .success]
        let unique = Set(states.map { "\($0)" })
        XCTAssertEqual(unique.count, 3)
    }
}
