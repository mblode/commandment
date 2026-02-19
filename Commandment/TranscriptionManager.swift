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

    /// Model ID to use with the Realtime API
    var realtimeModelID: String { rawValue }
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
        isM4A: Bool = false
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
    @Published var setupGuideDismissed = false {
        didSet {
            UserDefaults.standard.set(setupGuideDismissed, forKey: Self.setupGuideDismissedDefaultsKey)
        }
    }
    private var apiKey: String?
    private static let setupGuideDismissedDefaultsKey = "SetupGuideDismissed"

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
        setupGuideDismissed = UserDefaults.standard.bool(forKey: Self.setupGuideDismissedDefaultsKey)
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
            apiKey = legacyKey
            KeychainManager.saveAPIKey(legacyKey)
            UserDefaults.standard.removeObject(forKey: "OpenAIAPIKey")
            return
        }

        logInfo("TranscriptionManager: No API key configured")
    }

    func setAPIKey(_ key: String) {
        if key.isEmpty {
            apiKey = nil
            KeychainManager.deleteAPIKey()
        } else {
            apiKey = key
            KeychainManager.saveAPIKey(key)
        }
    }

    func getAPIKey() -> String? {
        return apiKey
    }

    func isAPIKeyConfigured() -> Bool {
        guard let key = apiKey else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func doesAPIKeyLookValid() -> Bool {
        guard let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty else {
            return false
        }
        return key.hasPrefix("sk-") && key.count >= 20
    }

    func dismissSetupGuide() {
        setupGuideDismissed = true
    }

    func resetSetupGuide() {
        setupGuideDismissed = false
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

        let isM4A = audioURL.pathExtension.lowercased() == "m4a"
        request.httpBody = TranscriptionManager.buildMultipartBody(
            audioData: audioData,
            boundary: boundary,
            model: selectedModel,
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
            showTransientStatus("Accessibility permission is required for Auto-Insert. Transcript copied to clipboard.", duration: 4)
            logError("TranscriptionManager: Auto-insert unavailable without accessibility permission")
            return
        }

        let pasteboard = NSPasteboard.general
        let previousContents = snapshotPasteboardItems(from: pasteboard)
        copyTextToClipboard(text)

        if postCommandV() {
            logInfo("TranscriptionManager: Auto-inserted transcript via CGEvent")
            updateStatus("")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
