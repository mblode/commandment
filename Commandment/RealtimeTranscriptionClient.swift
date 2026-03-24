import Foundation

/// Protocol for testability — allows mocking the Realtime client in unit tests.
protocol RealtimeTranscribing: AnyObject {
    func connect(apiKey: String, model: String)
    func sendAudioChunk(_ pcm16Data: Data)
    func commitAndTranscribe(
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, Error>) -> Void
    )
    func disconnect()
}

/// Streams audio to OpenAI's Realtime API via WebSocket during recording for near-instant transcription.
final class RealtimeTranscriptionClient: NSObject, URLSessionWebSocketDelegate, RealtimeTranscribing {
    enum State {
        case disconnected
        case connecting
        case ready
        case transcribing
        case failed(Error)
    }

    enum ClientError: Error, CustomStringConvertible {
        case notConnected
        case connectionFailed(String)
        case transcriptionFailed(String)

        var description: String {
            switch self {
            case .notConnected: return "WebSocket not connected"
            case .connectionFailed(let msg): return "Connection failed: \(msg)"
            case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
            }
        }
    }

    private(set) var state: State = .disconnected
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var onDelta: ((String) -> Void)?
    private var onComplete: ((Result<String, Error>) -> Void)?
    private var accumulatedText = ""
    private let lock = NSLock()

    /// Connect to the Realtime API.
    func connect(apiKey: String, model: String = "gpt-4o-mini-transcribe") {
        guard case .disconnected = state else { return }
        state = .connecting

        let urlString = "wss://api.openai.com/v1/realtime?intent=transcription&model=\(model)"
        guard let url = URL(string: urlString) else {
            state = .failed(ClientError.connectionFailed("Invalid URL"))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.urlSession = session
        let task = session.webSocketTask(with: request)
        self.webSocketTask = task
        task.resume()

        listenForMessages()
        sendSessionUpdate(model: model)
    }

    /// Send a chunk of PCM16 audio (base64-encoded).
    func sendAudioChunk(_ pcm16Data: Data) {
        switch state {
        case .ready, .transcribing:
            sendAudioAppend(pcm16Data)
        default:
            break
        }
    }

    /// Commit the audio buffer and await transcription result.
    func commitAndTranscribe(
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        self.onDelta = onDelta
        self.onComplete = completion
        self.accumulatedText = ""
        state = .transcribing

        sendJSON(["type": "input_audio_buffer.commit"])
    }

    /// Disconnect and clean up.
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        state = .disconnected
        onDelta = nil
        onComplete = nil
    }

    // MARK: - Private

    private func sendSessionUpdate(model: String) {
        let config: [String: Any] = [
            "type": "session.update",
            "session": [
                "input_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": model
                ],
                "turn_detection": NSNull()
            ] as [String: Any]
        ]
        sendJSON(config)
    }

    private func sendAudioAppend(_ pcm16Data: Data) {
        let base64 = pcm16Data.base64EncodedString()
        sendJSON([
            "type": "input_audio_buffer.append",
            "audio": base64
        ])
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let string = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(string)) { error in
            if let error = error {
                logError("RealtimeClient: Send error: \(error.localizedDescription)")
            }
        }
    }

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // Continue listening
                self.listenForMessages()

            case .failure(let error):
                logError("RealtimeClient: Receive error: \(error.localizedDescription)")
                self.handleDisconnect(error: error)
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "session.created", "session.updated":
            logInfo("RealtimeClient: Session \(type)")
            if case .connecting = state {
                state = .ready
            }

        case "conversation.item.input_audio_transcription.delta":
            if let delta = json["delta"] as? String {
                logDebug("RealtimeClient: Transcription delta: \(delta.count) chars")
                accumulatedText += delta
                onDelta?(delta)
            }

        case "conversation.item.input_audio_transcription.completed":
            let finalText: String
            if let text = json["transcript"] as? String, !text.isEmpty {
                finalText = text
            } else {
                finalText = accumulatedText
            }
            logInfo("RealtimeClient: Transcription completed (\(finalText.count) chars)")
            finish(.success(finalText))

        case "error":
            let errorMsg = (json["error"] as? [String: Any])?["message"] as? String ?? "Unknown error"
            logError("RealtimeClient: Error event: \(errorMsg)")
            if case .transcribing = state {
                finish(.failure(ClientError.transcriptionFailed(errorMsg)))
            } else {
                state = .failed(ClientError.connectionFailed(errorMsg))
            }

        case "input_audio_buffer.speech_started":
            logDebug("RealtimeClient: Speech detected")

        case "input_audio_buffer.speech_stopped":
            logDebug("RealtimeClient: Speech ended")

        case "input_audio_buffer.committed":
            logInfo("RealtimeClient: Audio buffer committed")

        default:
            logDebug("RealtimeClient: Event: \(type)")
        }
    }

    private func finish(_ result: Result<String, Error>) {
        lock.lock()
        let completion = onComplete
        onComplete = nil
        lock.unlock()

        state = .ready
        completion?(result)
    }

    private func handleDisconnect(error: Error) {
        lock.lock()
        let completion = onComplete
        onComplete = nil
        lock.unlock()

        state = .disconnected
        completion?(.failure(ClientError.connectionFailed(error.localizedDescription)))
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        logInfo("RealtimeClient: WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        logInfo("RealtimeClient: WebSocket closed (code: \(closeCode.rawValue))")
        handleDisconnect(error: ClientError.connectionFailed("WebSocket closed"))
    }
}

