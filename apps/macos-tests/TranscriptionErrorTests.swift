import XCTest
@testable import Commandment

final class TranscriptionErrorTests: XCTestCase {

    func test_networkError_description() {
        let underlying = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        let error = TranscriptionError.networkError(underlying)
        XCTAssertTrue(error.description.contains("Network error:"))
        XCTAssertTrue(error.description.contains("offline"))
    }

    func test_apiError_description() {
        let error = TranscriptionError.apiError(401, "Invalid API key")
        XCTAssertEqual(error.description, "API error (code 401): Invalid API key")
    }

    func test_noData_description() {
        XCTAssertEqual(TranscriptionError.noData.description, "No data received from API")
    }

    func test_decodingError_description() {
        XCTAssertEqual(TranscriptionError.decodingError.description, "Failed to decode API response")
    }

    func test_noAPIKey_description() {
        XCTAssertEqual(TranscriptionError.noAPIKey.description, "No API key provided")
    }

    func test_fileError_description() {
        let error = TranscriptionError.fileError("not found")
        XCTAssertEqual(error.description, "File error: not found")
    }

    func test_timeout_description() {
        XCTAssertEqual(TranscriptionError.timeout.description, "Request timed out")
    }
}
