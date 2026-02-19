import Foundation

class RealtimeTranscriptionManager {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let apiKey: String
    private let model: String

    // Serial queue protects all mutable state below
    private let queue = DispatchQueue(label: "co.blode.commandment.realtime")
    private var onTranscriptCompleted: ((String) -> Void)?
    private var onError: ((Error) -> Void)?
    private var isSessionConfigured = false
    private var connectCompletion: ((Bool) -> Void)?
    private var pendingAudioChunks: [Data] = []

    init(apiKey: String, model: String = "gpt-4o-mini-transcribe") {
        self.apiKey = apiKey
        self.model = model
    }

    // MARK: - Connection

    func connect(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        request.timeoutInterval = 10

        let session = URLSession(configuration: .default)
        self.urlSession = session

        queue.sync {
            self.connectCompletion = completion
        }

        let task = session.webSocketTask(with: request)
        self.webSocketTask = task
        task.resume()

        listenForMessages()

        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.queue.async {
                guard let completion = self.connectCompletion else { return }
                self.connectCompletion = nil
                logError("RealtimeTranscription: Connection timeout")
                completion(false)
            }
        }
    }

    private func configureSession(completion: @escaping (Bool) -> Void) {
        let config: [String: Any] = [
            "type": "transcription_session.update",
            "session": [
                "input_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": model,
                    "language": "en"
                ],
                "turn_detection": NSNull(),
                "input_audio_noise_reduction": [
                    "type": "near_field"
                ]
            ] as [String: Any]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: config),
              let jsonString = String(data: data, encoding: .utf8) else {
            logError("RealtimeTranscription: Failed to serialize session config")
            completion(false)
            return
        }

        webSocketTask?.send(.string(jsonString)) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                logError("RealtimeTranscription: Failed to send session config: \(error)")
                completion(false)
            } else {
                logInfo("RealtimeTranscription: Session configuration sent (model: \(self.model))")
                completion(true)
            }
        }
    }

    // MARK: - Audio Streaming

    func sendAudioChunk(_ pcm16Data: Data) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if self.isSessionConfigured {
                self.sendChunkDirectly(pcm16Data)
            } else {
                self.pendingAudioChunks.append(pcm16Data)
            }
        }
    }

    /// Must be called on `queue`
    private func flushPendingChunks() {
        let chunks = pendingAudioChunks
        pendingAudioChunks.removeAll()
        logInfo("RealtimeTranscription: Flushing \(chunks.count) buffered audio chunks")
        for chunk in chunks {
            sendChunkDirectly(chunk)
        }
    }

    /// Must be called on `queue`
    private func sendChunkDirectly(_ pcm16Data: Data) {
        let base64Audio = pcm16Data.base64EncodedString()
        let message: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": base64Audio
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                logError("RealtimeTranscription: Failed to send audio chunk: \(error)")
            }
        }
    }

    func commitAudio(onTranscript: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.onTranscriptCompleted = onTranscript
            self.onError = onError
        }

        let message: [String: String] = ["type": "input_audio_buffer.commit"]

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else {
            onError(TranscriptionError.decodingError)
            return
        }

        logInfo("RealtimeTranscription: Committing audio buffer")

        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                logError("RealtimeTranscription: Failed to commit: \(error)")
                onError(TranscriptionError.networkError(error))
            }
        }

        // Timeout after 10 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self else { return }
            self.queue.async {
                guard self.onTranscriptCompleted != nil else { return }
                logError("RealtimeTranscription: Transcript timeout")
                let errorCallback = self.onError
                self.onTranscriptCompleted = nil
                self.onError = nil
                errorCallback?(TranscriptionError.timeout)
            }
        }
    }

    // MARK: - Message Handling

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
                self.listenForMessages()

            case .failure(let error):
                logError("RealtimeTranscription: WebSocket receive error: \(error)")
                self.queue.async {
                    let errorCallback = self.onError
                    self.onError = nil
                    self.onTranscriptCompleted = nil
                    errorCallback?(TranscriptionError.networkError(error))
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "transcription_session.created":
            logInfo("RealtimeTranscription: Session created")
            queue.async { [weak self] in
                guard let self = self else { return }
                if let completion = self.connectCompletion {
                    self.connectCompletion = nil
                    self.configureSession(completion: completion)
                }
            }

        case "transcription_session.updated":
            logInfo("RealtimeTranscription: Session updated")
            queue.async { [weak self] in
                guard let self = self else { return }
                guard !self.isSessionConfigured else { return }
                self.isSessionConfigured = true
                self.flushPendingChunks()
            }

        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String {
                logInfo("RealtimeTranscription: Completed, length: \(transcript.count)")
                queue.async { [weak self] in
                    guard let self = self else { return }
                    let callback = self.onTranscriptCompleted
                    self.onTranscriptCompleted = nil
                    self.onError = nil
                    callback?(transcript)
                }
            }

        case "error":
            if let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                logError("RealtimeTranscription: Server error: \(message)")
                queue.async { [weak self] in
                    guard let self = self else { return }
                    let callback = self.onError
                    self.onError = nil
                    self.onTranscriptCompleted = nil
                    callback?(TranscriptionError.apiError(0, message))
                }
            }

        default:
            logDebug("RealtimeTranscription: \(type)")
        }
    }

    // MARK: - Disconnect

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        queue.sync {
            connectCompletion = nil
            onTranscriptCompleted = nil
            onError = nil
            isSessionConfigured = false
            pendingAudioChunks.removeAll()
        }
        logInfo("RealtimeTranscription: Disconnected")
    }
}
