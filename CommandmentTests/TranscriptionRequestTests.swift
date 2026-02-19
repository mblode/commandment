import XCTest
@testable import Commandment

final class TranscriptionRequestTests: XCTestCase {

    private let boundary = "test-boundary-123"
    private let sampleAudio = Data([0x00, 0x01, 0x02, 0x03])

    func test_containsFilePart() {
        let body = TranscriptionManager.buildMultipartBody(
            audioData: sampleAudio, boundary: boundary, model: .gpt4oMiniTranscribe)
        let bodyString = String(data: body, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains(#"name="file"; filename="recording.wav""#))
    }

    func test_containsModelParameter() {
        let body = TranscriptionManager.buildMultipartBody(
            audioData: sampleAudio, boundary: boundary, model: .whisper1)
        let bodyString = String(data: body, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("whisper-1"))
    }

    func test_containsTemperatureParameter() {
        let body = TranscriptionManager.buildMultipartBody(
            audioData: sampleAudio, boundary: boundary, model: .gpt4oMiniTranscribe)
        let bodyString = String(data: body, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains(#"name="temperature""#))
        XCTAssertTrue(bodyString.contains("0.0"))
    }

    func test_boundaryDelimiters() {
        let body = TranscriptionManager.buildMultipartBody(
            audioData: sampleAudio, boundary: boundary, model: .gpt4oMiniTranscribe)
        let bodyString = String(data: body, encoding: .utf8)!
        XCTAssertTrue(bodyString.hasPrefix("--\(boundary)"))
        XCTAssertTrue(bodyString.contains("--\(boundary)--"))
    }
}
