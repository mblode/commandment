import XCTest
@testable import Commandment

final class LoggerTests: XCTestCase {

    func test_logLevel_rawValues() {
        XCTAssertEqual(Logger.LogLevel.info.rawValue, "INFO")
        XCTAssertEqual(Logger.LogLevel.error.rawValue, "ERROR")
        XCTAssertEqual(Logger.LogLevel.debug.rawValue, "DEBUG")
    }

    func test_sharedInstance_isSingleton() {
        let a = Logger.shared
        let b = Logger.shared
        XCTAssertTrue(a === b)
    }
}
