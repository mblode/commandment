import Foundation
import AppKit

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
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case whisper1 = "whisper-1"

    var displayName: String {
        switch self {
        case .gpt4oMiniTranscribe: return "GPT-4o Mini Transcribe"
        case .gpt4oTranscribe: return "GPT-4o Transcribe"
        case .whisper1: return "Whisper-1 (Legacy)"
        }
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
        model: TranscriptionModel
    ) -> Data {
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        data.append(audioData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(model.rawValue)\r\n".data(using: .utf8)!)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        data.append("0.0\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }

    @Published var isTranscribing = false
    @Published var hasAccessibilityPermission = false
    @Published var statusMessage = ""
    @Published var selectedModel: TranscriptionModel = .gpt4oMiniTranscribe
    private var apiKey: String?

    // Retry configuration
    private let maxRetries = 3
    private let requestTimeout: TimeInterval = 15.0

    init() {
        loadAPIKey()
        loadModel()
        checkAccessibilityPermission()
    }

    // MARK: - API Key (Keychain)

    private func loadAPIKey() {
        // Try Keychain first
        if let keychainKey = KeychainManager.loadAPIKey() {
            apiKey = keychainKey
            return
        }

        // Migrate from UserDefaults if present
        if let legacyKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey"), !legacyKey.isEmpty {
            logInfo("Migrating API key from UserDefaults to Keychain")
            apiKey = legacyKey
            KeychainManager.saveAPIKey(legacyKey)
            UserDefaults.standard.removeObject(forKey: "OpenAIAPIKey")
        }
    }

    func setAPIKey(_ key: String) {
        apiKey = key
        KeychainManager.saveAPIKey(key)
    }

    func getAPIKey() -> String? {
        return apiKey
    }

    // MARK: - Model Selection

    private func loadModel() {
        if let modelRaw = UserDefaults.standard.string(forKey: "TranscriptionModel"),
           let model = TranscriptionModel(rawValue: modelRaw) {
            selectedModel = model
        }
    }

    func setModel(_ model: TranscriptionModel) {
        selectedModel = model
        UserDefaults.standard.set(model.rawValue, forKey: "TranscriptionModel")
    }

    // MARK: - Accessibility

    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = trusted
            if !trusted {
                self.showAccessibilityAlert()
            }
        }
    }

    // MARK: - Transcription with Retry

    private func updateStatus(_ message: String) {
        DispatchQueue.main.async { self.statusMessage = message }
    }

    func transcribeWithRetry(audioURL: URL, completion: @escaping (String?) -> Void) {
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
                    completion(text)

                case .failure(let error):
                    logError("Transcription attempt \(currentRetry + 1) failed: \(error.description)")

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
                        completion(nil)
                    }
                }
            }
        }

        attemptTranscription()
    }

    // MARK: - Core Request

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

        request.httpBody = TranscriptionManager.buildMultipartBody(
            audioData: audioData,
            boundary: boundary,
            model: selectedModel
        )

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout * 2
        config.waitsForConnectivity = true

        let session = URLSession(configuration: config)

        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
            }

            session.finishTasksAndInvalidate()

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
        logInfo("Starting text paste operation")

        if !AXIsProcessTrusted() {
            logError("No accessibility permission")
            DispatchQueue.main.async {
                self.showAccessibilityAlert()
            }
            return
        }

        // Use clipboard + ⌘V to avoid AppleScript injection
        let pasteboard = NSPasteboard.general
        let previousContents = snapshotPasteboardItems(from: pasteboard)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                logError("AppleScript error: \(error)")
                DispatchQueue.main.async {
                    self.checkAccessibilityPermission()
                }
            } else {
                logInfo("Successfully pasted text")
            }
        }

        // Restore previous clipboard after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.restorePasteboardItems(previousContents, to: pasteboard)
        }
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

    // MARK: - Alerts

    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permission Required"
            alert.informativeText = "Commandment needs accessibility permission to simulate keyboard events. Please grant access in System Settings > Privacy & Security > Accessibility, then quit and relaunch Commandment."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
