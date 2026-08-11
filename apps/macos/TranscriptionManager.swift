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

    // MARK: - Status

    func setStatusMessage(_ message: String) {
        DispatchQueue.main.async { self.statusMessage = message }
    }

    private func showTransientStatus(_ message: String, duration: TimeInterval = 2.5) {
        setStatusMessage(message)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self else { return }
            if self.statusMessage == message && !self.isTranscribing {
                self.statusMessage = ""
            }
        }
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
            setStatusMessage("")
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
