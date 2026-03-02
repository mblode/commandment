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
            audioData: sampleAudio, boundary: boundary, model: .gpt4oMiniTranscribe)
        let bodyString = String(data: body, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("gpt-4o-mini-transcribe"))
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

    func test_streamParameter_whenEnabled() {
        let body = TranscriptionManager.buildMultipartBody(
            audioData: sampleAudio, boundary: boundary, model: .gpt4oMiniTranscribe, stream: true)
        let bodyString = String(data: body, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains(#"name="stream""#))
        XCTAssertTrue(bodyString.contains("true"))
    }

    func test_streamParameter_whenDisabled() {
        let body = TranscriptionManager.buildMultipartBody(
            audioData: sampleAudio, boundary: boundary, model: .gpt4oMiniTranscribe, stream: false)
        let bodyString = String(data: body, encoding: .utf8)!
        XCTAssertFalse(bodyString.contains(#"name="stream""#))
    }
}

final class SSEDataDelegateTests: XCTestCase {
    private let streamURL = URL(string: "https://example.com/transcriptions")!
    private var session: URLSession!
    private var dataTask: URLSessionDataTask!

    override func setUp() {
        super.setUp()
        session = URLSession(configuration: .ephemeral)
        dataTask = session.dataTask(with: URLRequest(url: streamURL))
    }

    override func tearDown() {
        session.invalidateAndCancel()
        dataTask = nil
        session = nil
        super.tearDown()
    }

    func test_sseDoneEventLF_completesSuccess() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData(
            """
            data: {"type":"transcript.text.delta","delta":"Hello"}

            data: {"type":"transcript.text.done","text":"Hello"}

            """,
            delegate: delegate
        )
        complete(delegate: delegate)

        XCTAssertEqual(probe.deltas, ["Hello"])
        XCTAssertEqual(probe.successText, "Hello")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_sseDoneEventCRLF_completesSuccess() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData(
            "data: {\"type\":\"transcript.text.delta\",\"delta\":\"Hey\"}\r\n\r\n" +
            "data: {\"type\":\"transcript.text.done\",\"text\":\"Hey, this is a test.\"}\r\n\r\n",
            delegate: delegate
        )
        complete(delegate: delegate)

        XCTAssertEqual(probe.deltas, ["Hey"])
        XCTAssertEqual(probe.successText, "Hey, this is a test.")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_sseDoneEventFieldCRLF_withoutJSONType_completesSuccess() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData(
            "event: transcript.text.done\r\n" +
            "data: {\"text\":\"field-driven done\"}\r\n\r\n",
            delegate: delegate
        )
        complete(delegate: delegate)

        XCTAssertEqual(probe.successText, "field-driven done")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_sseDoneEventWithoutTrailingTerminator_completesOnFinalFlush() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData("data: {\"type\":\"transcript.text.done\",\"text\":\"final text\"}", delegate: delegate)
        complete(delegate: delegate)

        XCTAssertEqual(probe.successText, "final text")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_sseDoneEventSplitAcrossChunks_completesSuccess() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData("data: {\"type\":\"transcript.text.done\",\"text\":\"chunk", delegate: delegate)
        receiveData(" split\"}\n\n", delegate: delegate)
        complete(delegate: delegate)

        XCTAssertEqual(probe.successText, "chunk split")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_sseDoneThenDONECRLF_completesSuccess() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData(
            "data: {\"type\":\"transcript.text.done\",\"text\":\"done text\"}\r\n\r\n" +
            "data: [DONE]\r\n\r\n",
            delegate: delegate
        )
        complete(delegate: delegate)

        XCTAssertEqual(probe.successText, "done text")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_plainJSONFallback_completesSuccess() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData("{\"text\":\"fallback text\"}", delegate: delegate)
        complete(delegate: delegate)

        XCTAssertEqual(probe.successText, "fallback text")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_noDoneAndNoJSON_returnsNoData() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData("data: {\"type\":\"transcript.text.delta\",\"delta\":\"partial\"}\n\n", delegate: delegate)
        complete(delegate: delegate)

        guard case .failure(let error)? = probe.result else {
            return XCTFail("Expected failure result")
        }
        guard case .noData = error else {
            return XCTFail("Expected noData error, got \(error.description)")
        }
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_httpErrorResponse_mapsApiErrorMessage() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 429)
        receiveData("{\"error\":{\"message\":\"Rate limit\"}}", delegate: delegate)
        complete(delegate: delegate)

        guard case .failure(let error)? = probe.result else {
            return XCTFail("Expected failure result")
        }
        guard case .apiError(let code, let message) = error else {
            return XCTFail("Expected apiError")
        }
        XCTAssertEqual(code, 429)
        XCTAssertEqual(message, "Rate limit")
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_timeoutError_mapsTimeout() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        delegate.urlSession(session, task: dataTask, didCompleteWithError: error)

        guard case .failure(let receivedError)? = probe.result else {
            return XCTFail("Expected failure result")
        }
        guard case .timeout = receivedError else {
            return XCTFail("Expected timeout error")
        }
        XCTAssertEqual(probe.completionCount, 1)
    }

    func test_completionCallbackOnlyOnce() {
        let probe = DelegateProbe()
        let delegate = makeDelegate(probe: probe)

        receiveResponse(delegate: delegate, statusCode: 200)
        receiveData("data: {\"type\":\"transcript.text.done\",\"text\":\"done\"}\n\n", delegate: delegate)
        complete(delegate: delegate)
        let lateError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        delegate.urlSession(session, task: dataTask, didCompleteWithError: lateError)

        XCTAssertEqual(probe.successText, "done")
        XCTAssertEqual(probe.completionCount, 1)
    }

    private func makeDelegate(probe: DelegateProbe) -> SSEDataDelegate {
        SSEDataDelegate(
            onDelta: { delta in
                probe.deltas.append(delta)
            },
            onComplete: { result in
                probe.completionCount += 1
                probe.result = result
            }
        )
    }

    private func receiveResponse(delegate: SSEDataDelegate, statusCode: Int) {
        let response = HTTPURLResponse(url: streamURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        delegate.urlSession(session, dataTask: dataTask, didReceive: response) { _ in }
    }

    private func receiveData(_ raw: String, delegate: SSEDataDelegate) {
        delegate.urlSession(session, dataTask: dataTask, didReceive: Data(raw.utf8))
    }

    private func complete(delegate: SSEDataDelegate) {
        delegate.urlSession(session, task: dataTask, didCompleteWithError: nil)
    }
}

private final class DelegateProbe {
    var deltas: [String] = []
    var completionCount = 0
    var result: Result<String, TranscriptionError>?

    var successText: String? {
        guard case .success(let text)? = result else { return nil }
        return text
    }
}
