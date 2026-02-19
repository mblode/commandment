import Foundation
import Cocoa
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.d, modifiers: [.option]))
}

@MainActor
class HotkeyManager: ObservableObject {
    @Published var shortcutDisplay: String = ""
    private var shortcutChangeObserver: NSObjectProtocol?

    init() {
        logInfo("HotkeyManager: Initializing")
        updateShortcutDisplay()
        observeShortcutChanges()

        KeyboardShortcuts.onKeyDown(for: .toggleRecording) {
            logDebug("HotkeyManager: Hotkey key down")
            NotificationCenter.default.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        KeyboardShortcuts.onKeyUp(for: .toggleRecording) {
            logDebug("HotkeyManager: Hotkey key up")
            NotificationCenter.default.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        }
    }

    deinit {
        if let shortcutChangeObserver {
            NotificationCenter.default.removeObserver(shortcutChangeObserver)
        }
    }

    private func observeShortcutChanges() {
        shortcutChangeObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let name = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
                name == .toggleRecording
            else {
                return
            }

            Task { @MainActor [weak self] in
                self?.updateShortcutDisplay()
            }
        }
    }

    func updateShortcutDisplay() {
        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleRecording) {
            let raw = shortcut.description
            // Replace all four modifier symbols with ✦ (Hyper Key)
            let allModifiers = "\u{2303}\u{2325}\u{21E7}\u{2318}" // ⌃⌥⇧⌘
            if raw.hasPrefix(allModifiers) {
                shortcutDisplay = "✦" + raw.dropFirst(allModifiers.count)
            } else {
                shortcutDisplay = raw
            }
        } else {
            shortcutDisplay = "Not set"
        }
    }
}
