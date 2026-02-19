import XCTest
@testable import Commandment

final class TranscriptionModelTests: XCTestCase {

    func test_rawValues_matchOpenAIAPIStrings() {
        XCTAssertEqual(TranscriptionModel.gpt4oMiniTranscribe.rawValue, "gpt-4o-mini-transcribe")
        XCTAssertEqual(TranscriptionModel.gpt4oTranscribe.rawValue, "gpt-4o-transcribe")
        XCTAssertEqual(TranscriptionModel.whisper1.rawValue, "whisper-1")
    }

    func test_displayName_isHumanReadable() {
        XCTAssertEqual(TranscriptionModel.gpt4oMiniTranscribe.displayName, "GPT-4o Mini Transcribe")
        XCTAssertEqual(TranscriptionModel.gpt4oTranscribe.displayName, "GPT-4o Transcribe")
        XCTAssertEqual(TranscriptionModel.whisper1.displayName, "Whisper-1 (Legacy)")
    }

    func test_allCases_containsExactlyThreeModels() {
        XCTAssertEqual(TranscriptionModel.allCases.count, 3)
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
