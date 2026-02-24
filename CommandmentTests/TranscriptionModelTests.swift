import XCTest
@testable import Commandment

final class TranscriptionModelTests: XCTestCase {

    func test_rawValues_matchOpenAIAPIStrings() {
        XCTAssertEqual(TranscriptionModel.gpt4oTranscribe.rawValue, "gpt-4o-transcribe")
    }

    func test_displayName_isHumanReadable() {
        XCTAssertEqual(TranscriptionModel.gpt4oTranscribe.displayName, "GPT-4o Transcribe")
    }

    func test_allCases_containsExactlyOneModel() {
        XCTAssertEqual(TranscriptionModel.allCases, [.gpt4oTranscribe])
    }

    func test_codable_roundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for model in TranscriptionModel.allCases {
            let data = try encoder.encode(model)
            let decoded = try decoder.decode(TranscriptionModel.self, from: data)
            XCTAssertEqual(decoded, model)
        }
    }
}
