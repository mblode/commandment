import Foundation
import AppKit
import ApplicationServices
import Carbon

enum TranscriptionError: Error {
    case networkError(Error)
    case apiError(Int, String)
    case noData
    case decodingError
    case noAPIKey
    case fileError(String)
    case timeout

    var description: String {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error (code \(code)): \(message)"
        case .noData:
            return "No data received from API"
        case .decodingError:
            return "Failed to decode API response"
        case .noAPIKey:
            return "No API key provided"
        case .fileError(let message):
            return "File error: \(message)"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Transcription Model Selection

enum TranscriptionModel: String, CaseIterable, Codable {
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"

    var displayName: String {
        "GPT-4o Mini Transcribe"
    }

    var modelID: String { rawValue }
}

// MARK: - Language Selection

enum TranscriptionLanguage: String, CaseIterable, Codable, Identifiable {
    case auto = ""
    case en, es, fr, de, it, pt, nl, ja, ko, zh
    case ar, hi, ru, pl, sv, da, no, fi, tr, uk
    case cs, ro, hu, el, th, vi, id, ms

    var id: String { rawValue }

    var displayName: String {
        if self == .auto { return "Auto-detect" }
        return Locale.current.localizedString(forLanguageCode: rawValue)
            ?? rawValue.uppercased()
    }

    /// Value to send to the API, or nil for auto-detect.
    var apiValue: String? {
        self == .auto ? nil : rawValue
    }
}

class TranscriptionManager: ObservableObject {

    // MARK: - Pure Static Helpers

    static func retryDelay(forAttempt attempt: Int) -> TimeInterval {
        return pow(2.0, Double(attempt - 1))
    }

    static func buildMultipartBody(
        audioData: Data,
        boundary: String,
        model: TranscriptionModel,
        language: TranscriptionLanguage = .en,
        isM4A: Bool = false,
        stream: Bool = false
    ) -> Data {
        let filename = isM4A ? "recording.m4a" : "recording.wav"
        let contentType = isM4A ? "audio/mp4" : "audio/wav"

        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        data.append(audioData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(model.rawValue)\r\n".data(using: .utf8)!)
        if let langCode = language.apiValue {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(langCode)\r\n".data(using: .utf8)!)
        }
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        data.append("0.0\r\n".data(using: .utf8)!)
        if stream {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"stream\"\r\n\r\n".data(using: .utf8)!)
            data.append("true\r\n".data(using: .utf8)!)
        }
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }

    @Published var isTranscribing = false
    @Published var hasAccessibilityPermission = false
    @Published var statusMessage = ""
    @Published var selectedModel: TranscriptionModel = .gpt4oMiniTranscribe
    @Published var selectedLanguage: TranscriptionLanguage = {
        if let raw = UserDefaults.standard.string(forKey: "selectedTranscriptionLanguage"),
           let lang = TranscriptionLanguage(rawValue: raw) {
            return lang
        }
        return .en
    }() {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedTranscriptionLanguage")
        }
    }
    @Published var setupGuideDismissed: Bool = UserDefaults.standard.bool(forKey: "setupGuideDismissed") {
        didSet { UserDefaults.standard.set(setupGuideDismissed, forKey: "setupGuideDismissed") }
    }
    private var apiKey: String?

    // Retry configuration
    private let maxRetries = 3
    private let requestTimeout: TimeInterval = 15.0

    // Persistent session for connection reuse (TLS session resumption, HTTP/2 multiplexing)
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout * 2
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    init() {
        loadAPIKey()
        recheckAccessibilityPermission()
    }

    // MARK: - API Key (Keychain)

    private func loadAPIKey() {
        // XCTest host startup can block indefinitely on keychain IPC.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            apiKey = nil
            logInfo("TranscriptionManager: Skipping keychain load in test environment")
            return
        }

        // Try Keychain first
        if let keychainKey = KeychainManager.loadAPIKey() {
            apiKey = keychainKey
            logInfo("TranscriptionManager: API key loaded from keychain")
            return
        }

        // Migrate from UserDefaults if present
        if let legacyKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey"), !legacyKey.isEmpty {
            logInfo("Migrating API key from UserDefaults to Keychain")
            if KeychainManager.saveAPIKey(legacyKey) {
                apiKey = legacyKey
                UserDefaults.standard.removeObject(forKey: "OpenAIAPIKey")
                logInfo("TranscriptionManager: API key migration to keychain succeeded")
            } else {
                // Keep legacy key available for current session instead of dropping it.
                apiKey = legacyKey
                logError("TranscriptionManager: API key migration to keychain failed; legacy key retained in UserDefaults")
            }
            return
        }

        logInfo("TranscriptionManager: No API key configured")
    }

    @discardableResult
    func setAPIKey(_ key: String) -> Bool {
        if key.isEmpty {
            let didDelete = KeychainManager.deleteAPIKey()
            if didDelete {
                apiKey = nil
            }
            return didDelete
        } else {
            let didSave = KeychainManager.saveAPIKey(key)
            if didSave {
                apiKey = key
            }
            return didSave
        }
    }

    func getAPIKey() -> String? {
        return apiKey
    }

    // MARK: - Accessibility

    @discardableResult
    func refreshAccessibilityPermissionState() -> Bool {
        let trusted = AXIsProcessTrusted()
        if Thread.isMainThread {
            hasAccessibilityPermission = trusted
        } else {
            DispatchQueue.main.async {
                self.hasAccessibilityPermission = trusted
            }
        }
        return trusted
    }

    func recheckAccessibilityPermission() {
        _ = refreshAccessibilityPermissionState()
    }

    func resetSetupGuide() {
        setupGuideDismissed = false
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Transcription with Retry

    private func updateStatus(_ message: String) {
        DispatchQueue.main.async { self.statusMessage = message }
    }

    private func showTransientStatus(_ message: String, duration: TimeInterval = 2.5) {
        updateStatus(message)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self else { return }
            if self.statusMessage == message && !self.isTranscribing {
                self.statusMessage = ""
            }
        }
    }

    func setStatusMessage(_ message: String) {
        updateStatus(message)
    }

    func transcribeWithRetry(audioURL: URL, completion: @escaping (Result<String, TranscriptionError>) -> Void) {
        var currentRetry = 0
        updateStatus("Starting transcription...")

        func attemptTranscription() {
            logInfo("Attempting transcription (try \(currentRetry + 1) of \(self.maxRetries + 1))")

            if currentRetry > 0 {
                self.updateStatus("Retry \(currentRetry) of \(self.maxRetries)...")
            }

            self.performTranscriptionRequest(audioURL: audioURL) { result in
                switch result {
                case .success(let text):
                    self.updateStatus("")
                    completion(.success(text))

                case .failure(let error):
                    logError("Transcription attempt \(currentRetry + 1) failed: \(error.description)")

                    // Don't retry errors that won't resolve themselves
                    switch error {
                    case .noAPIKey, .fileError:
                        self.updateStatus("")
                        completion(.failure(error))
                        return
                    case .apiError(let code, _) where code == 401 || code == 403:
                        self.updateStatus("")
                        completion(.failure(error))
                        return
                    default:
                        break
                    }

                    if currentRetry < self.maxRetries {
                        currentRetry += 1

                        let delay = TranscriptionManager.retryDelay(forAttempt: currentRetry)
                        self.updateStatus("Retry in \(Int(delay))s... (\(currentRetry)/\(self.maxRetries))")

                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            attemptTranscription()
                        }
                    } else {
                        self.updateStatus("")
                        logError("Transcription failed after \(self.maxRetries + 1) attempts")
                        completion(.failure(error))
                    }
                }
            }
        }

        attemptTranscription()
    }

    // MARK: - Streaming Transcription

    func transcribeStreaming(
        audioURL: URL,
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, TranscriptionError>) -> Void
    ) {
        var currentRetry = 0
        updateStatus("Starting transcription...")

        func attempt() {
            logInfo("Streaming transcription attempt \(currentRetry + 1) of \(self.maxRetries + 1)")

            if currentRetry > 0 {
                self.updateStatus("Retry \(currentRetry) of \(self.maxRetries)...")
            }

            self.performStreamingRequest(audioURL: audioURL, onDelta: onDelta) { result in
                switch result {
                case .success(let text):
                    self.updateStatus("")
                    completion(.success(text))

                case .failure(let error):
                    logError("Streaming transcription attempt \(currentRetry + 1) failed: \(error.description)")

                    switch error {
                    case .noAPIKey, .fileError:
                        self.updateStatus("")
                        completion(.failure(error))
                        return
                    case .apiError(let code, _) where code == 401 || code == 403:
                        self.updateStatus("")
                        completion(.failure(error))
                        return
                    default:
                        break
                    }

                    if currentRetry < self.maxRetries {
                        currentRetry += 1
                        let delay = TranscriptionManager.retryDelay(forAttempt: currentRetry)
                        self.updateStatus("Retry in \(Int(delay))s... (\(currentRetry)/\(self.maxRetries))")
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { attempt() }
                    } else {
                        self.updateStatus("")
                        logError("Streaming transcription failed after \(self.maxRetries + 1) attempts")
                        completion(.failure(error))
                    }
                }
            }
        }

        attempt()
    }

    private func performStreamingRequest(
        audioURL: URL,
        onDelta: @escaping (String) -> Void,
        completion: @escaping (Result<String, TranscriptionError>) -> Void
    ) {
        guard let apiKey = apiKey else {
            completion(.failure(.noAPIKey))
            return
        }

        DispatchQueue.main.async { self.isTranscribing = true }

        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
            logInfo("Streaming transcription: audio file \(audioData.count) bytes")
        } catch {
            logError("Error reading audio file: \(error)")
            DispatchQueue.main.async { self.isTranscribing = false }
            completion(.failure(.fileError(error.localizedDescription)))
            return
        }

        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = requestTimeout

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let isM4A = audioURL.pathExtension.lowercased() == "m4a"
        request.httpBody = TranscriptionManager.buildMultipartBody(
            audioData: audioData,
            boundary: boundary,
            model: selectedModel,
            language: selectedLanguage,
            isM4A: isM4A,
            stream: true
        )

        let delegate = SSEDataDelegate(
            onDelta: onDelta,
            onComplete: { [weak self] result in
                DispatchQueue.main.async { self?.isTranscribing = false }
                completion(result)
            }
        )

        let streamSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = streamSession.dataTask(with: request)
        task.resume()
    }

    // MARK: - Core Request (non-streaming fallback)

    private func performTranscriptionRequest(audioURL: URL, completion: @escaping (Result<String, TranscriptionError>) -> Void) {
        guard let apiKey = apiKey else {
            logError("Transcription error: No API key provided")
            completion(.failure(.noAPIKey))
            return
        }

        DispatchQueue.main.async {
            self.isTranscribing = true
        }

        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = requestTimeout

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
            logInfo("Audio file size being sent to API: \(audioData.count) bytes")
        } catch {
            logError("Error reading audio file: \(error)")
            DispatchQueue.main.async {
                self.isTranscribing = false
            }
            completion(.failure(.fileError(error.localizedDescription)))
            return
        }

        let isM4A = audioURL.pathExtension.lowercased() == "m4a"
        request.httpBody = TranscriptionManager.buildMultipartBody(
            audioData: audioData,
            boundary: boundary,
            model: selectedModel,
            language: selectedLanguage,
            isM4A: isM4A
        )

        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
            }

            if let error = error {
                let nsError = error as NSError

                if nsError.domain == NSURLErrorDomain &&
                   (nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorNetworkConnectionLost) {
                    logError("Transcription timed out: \(error.localizedDescription)")
                    completion(.failure(.timeout))
                    return
                }

                logError("Transcription network error: \(error.localizedDescription)")
                logError("Error domain: \(nsError.domain), code: \(nsError.code)")
                completion(.failure(.networkError(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                logInfo("Transcription API response status: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    logError("Transcription API error: Non-200 status code (\(httpResponse.statusCode))")

                    var errorMessage = "Unknown error"

                    if let data = data, let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        logError("API error response: \(errorJson)")
                        if let errorObj = errorJson["error"] as? [String: Any],
                           let message = errorObj["message"] as? String {
                            errorMessage = message
                            logError("Error message: \(message)")
                        }
                    }

                    completion(.failure(.apiError(httpResponse.statusCode, errorMessage)))
                    return
                }
            }

            guard let data = data else {
                logError("Transcription error: No data received from API")
                completion(.failure(.noData))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let text = json["text"] as? String {
                        logInfo("Transcription successful, received text of length: \(text.count)")
                        completion(.success(text))
                    } else {
                        logError("Transcription error: Response missing 'text' field")
                        logError("Full API response: \(json)")
                        completion(.failure(.decodingError))
                    }
                } else {
                    logError("Transcription error: Invalid JSON response")
                    if let responseString = String(data: data, encoding: .utf8) {
                        logError("Raw API response: \(responseString)")
                    }
                    completion(.failure(.decodingError))
                }
            } catch {
                logError("Transcription JSON parsing error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    logError("Raw API response: \(responseString)")
                }
                completion(.failure(.decodingError))
            }
        }.resume()
    }

    // MARK: - Text Insertion

    func pasteText(_ text: String) {
        let trusted = refreshAccessibilityPermissionState()

        guard trusted else {
            copyTextToClipboard(text)
            showTransientStatus("Transcript copied to clipboard.", duration: 4)
            logError("TranscriptionManager: Auto-insert unavailable without accessibility permission")
            DispatchQueue.main.async {
                OverlayPanelController.shared.show(state: .copiedToClipboard)
            }
            return
        }

        let pasteboard = NSPasteboard.general
        let previousContents = snapshotPasteboardItems(from: pasteboard)
        copyTextToClipboard(text)

        if postCommandV() {
            logInfo("TranscriptionManager: Auto-inserted transcript via CGEvent")
            updateStatus("")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.restorePasteboardItems(previousContents, to: pasteboard)
            }
        } else {
            logError("TranscriptionManager: Failed to send auto-insert key events, leaving transcript on clipboard")
            showTransientStatus("Auto-insert failed. Transcript copied to clipboard.", duration: 4)
        }
    }

    private func copyTextToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func postCommandV() -> Bool {
        guard let keyCode = keyCodeForCurrentLayout(character: "v"),
              let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func keyCodeForCurrentLayout(character: Character) -> CGKeyCode? {
        guard let inputSource = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let rawLayoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }

        let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self)
        guard let layoutPtr = CFDataGetBytePtr(layoutData) else {
            return nil
        }
        let keyboardLayout = UnsafePointer<UCKeyboardLayout>(OpaquePointer(layoutPtr))
        let target = String(character).lowercased()

        for keyCode in UInt16(0)...UInt16(127) {
            if translatedCharacter(
                for: keyCode,
                modifiers: 0,
                keyboardLayout: keyboardLayout
            ).lowercased() == target {
                return CGKeyCode(keyCode)
            }

            if translatedCharacter(
                for: keyCode,
                modifiers: UInt32(shiftKey >> 8),
                keyboardLayout: keyboardLayout
            ).lowercased() == target {
                return CGKeyCode(keyCode)
            }
        }

        return nil
    }

    private func translatedCharacter(
        for keyCode: UInt16,
        modifiers: UInt32,
        keyboardLayout: UnsafePointer<UCKeyboardLayout>
    ) -> String {
        var deadKeyState: UInt32 = 0
        var characters = [UniChar](repeating: 0, count: 4)
        var actualLength = 0

        let status = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDown),
            modifiers,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysMask),
            &deadKeyState,
            characters.count,
            &actualLength,
            &characters
        )

        guard status == noErr, actualLength > 0 else {
            return ""
        }

        return String(utf16CodeUnits: characters, count: actualLength)
    }

    private func snapshotPasteboardItems(from pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        return (pasteboard.pasteboardItems ?? []).map { item in
            let snapshotItem = NSPasteboardItem()

            for type in item.types {
                if let data = item.data(forType: type) {
                    snapshotItem.setData(data, forType: type)
                } else if let propertyList = item.propertyList(forType: type) {
                    snapshotItem.setPropertyList(propertyList, forType: type)
                } else if let string = item.string(forType: type) {
                    snapshotItem.setString(string, forType: type)
                }
            }

            return snapshotItem
        }
    }

    private func restorePasteboardItems(_ items: [NSPasteboardItem], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        guard !items.isEmpty else {
            return
        }

        if !pasteboard.writeObjects(items) {
            logError("Failed to restore clipboard contents")
        }
    }
}

// MARK: - SSE Stream Delegate

/// Parses Server-Sent Events from OpenAI's streaming transcription endpoint.
/// Events: `transcript.text.delta` (partial text) and `transcript.text.done` (final text).
final class SSEDataDelegate: NSObject, URLSessionDataDelegate {
    private let onDelta: (String) -> Void
    private let onComplete: (Result<String, TranscriptionError>) -> Void
    private var buffer = Data()
    private var completedText: String?
    private var httpStatusCode: Int?
    private var hasCompleted = false

    init(
        onDelta: @escaping (String) -> Void,
        onComplete: @escaping (Result<String, TranscriptionError>) -> Void
    ) {
        self.onDelta = onDelta
        self.onComplete = onComplete
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            httpStatusCode = httpResponse.statusCode
            logInfo("Streaming transcription response status: \(httpResponse.statusCode)")
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Check for HTTP error (non-streaming JSON error response)
        if let statusCode = httpStatusCode, statusCode != 200 {
            buffer.append(data)
            return
        }

        buffer.append(data)
        processBuffer()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !hasCompleted else { return }
        hasCompleted = true

        session.invalidateAndCancel()

        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain &&
               (nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorNetworkConnectionLost) {
                onComplete(.failure(.timeout))
            } else {
                onComplete(.failure(.networkError(error)))
            }
            return
        }

        // Handle HTTP error response
        if let statusCode = httpStatusCode, statusCode != 200 {
            var errorMessage = "Unknown error"
            if let errorJson = try? JSONSerialization.jsonObject(with: buffer) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                errorMessage = message
            }
            logError("Streaming transcription API error: \(statusCode) - \(errorMessage)")
            onComplete(.failure(.apiError(statusCode, errorMessage)))
            return
        }

        // Process any remaining data in buffer
        processBuffer()

        if let text = completedText {
            logInfo("Streaming transcription completed, length: \(text.count)")
            onComplete(.success(text))
        } else {
            logError("Streaming transcription: stream ended without completion event")
            onComplete(.failure(.noData))
        }
    }

    private func processBuffer() {
        guard let bufferString = String(data: buffer, encoding: .utf8) else { return }

        // SSE format: lines separated by \n\n, each event has "event:" and "data:" lines
        let events = bufferString.components(separatedBy: "\n\n")

        // Keep the last incomplete chunk in the buffer
        if !bufferString.hasSuffix("\n\n") {
            if let lastIncomplete = events.last {
                buffer = lastIncomplete.data(using: .utf8) ?? Data()
            }
            // Process all complete events (everything except the last incomplete chunk)
            for event in events.dropLast() {
                parseSSEEvent(event)
            }
        } else {
            buffer = Data()
            for event in events where !event.isEmpty {
                parseSSEEvent(event)
            }
        }
    }

    private func parseSSEEvent(_ eventBlock: String) {
        let lines = eventBlock.components(separatedBy: "\n")
        var eventType: String?
        var dataLines: [String] = []

        for line in lines {
            if line.hasPrefix("event: ") {
                eventType = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                dataLines.append(String(line.dropFirst(6)))
            } else if line == "data: [DONE]" || line == "[DONE]" {
                return
            }
        }

        guard let type = eventType, !dataLines.isEmpty else { return }
        let dataString = dataLines.joined(separator: "\n")

        guard let jsonData = dataString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }

        switch type {
        case "transcript.text.delta":
            if let delta = json["delta"] as? String {
                logDebug("Streaming delta: \(delta.count) chars")
                onDelta(delta)
            }
        case "transcript.text.done":
            if let text = json["text"] as? String {
                completedText = text
            }
        default:
            logDebug("Streaming SSE event: \(type)")
        }
    }
}
