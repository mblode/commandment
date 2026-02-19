import XCTest
@testable import Commandment

final class TranscriptionModelTests: XCTestCase {

    func test_rawValues_matchOpenAIAPIStrings() {
        XCTAssertEqual(TranscriptionModel.gpt4oMiniTranscribe.rawValue, "gpt-4o-mini-transcribe")
    }

    func test_displayName_isHumanReadable() {
        XCTAssertEqual(TranscriptionModel.gpt4oMiniTranscribe.displayName, "GPT-4o Mini Transcribe")
    }

    func test_allCases_containsExactlyOneModel() {
        XCTAssertEqual(TranscriptionModel.allCases, [.gpt4oMiniTranscribe])
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
