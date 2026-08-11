import Foundation
import Cocoa
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.d, modifiers: [.option]))
    static let openSettings = Self("openSettings", default: .init(.d, modifiers: [.option, .shift]))
}

@MainActor
class HotkeyManager: ObservableObject {
    @Published var shortcutDisplay: String = ""
    @Published var settingsShortcutDisplay: String = ""
    private var shortcutChangeObserver: NSObjectProtocol?

    init() {
        logInfo("HotkeyManager: Initializing")
        updateShortcutDisplay()
        updateSettingsShortcutDisplay()
        observeShortcutChanges()

        KeyboardShortcuts.onKeyDown(for: .toggleRecording) {
            logDebug("HotkeyManager: Hotkey key down")
            NotificationCenter.default.post(name: NSNotification.Name("HotkeyKeyDown"), object: nil)
        }

        KeyboardShortcuts.onKeyUp(for: .toggleRecording) {
            logDebug("HotkeyManager: Hotkey key up")
            NotificationCenter.default.post(name: NSNotification.Name("HotkeyKeyUp"), object: nil)
        }

        KeyboardShortcuts.onKeyUp(for: .openSettings) {
            guard !Self.shortcutsConflict(.openSettings, .toggleRecording) else {
                logInfo("HotkeyManager: Ignoring open settings shortcut because it conflicts with record shortcut")
                return
            }
            logDebug("HotkeyManager: Open settings hotkey key up")
            SettingsWindowController.shared.show()
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
                name == .toggleRecording || name == .openSettings
            else {
                return
            }

            Task { @MainActor [weak self] in
                if name == .toggleRecording {
                    self?.updateShortcutDisplay()
                } else {
                    self?.updateSettingsShortcutDisplay()
                }
            }
        }
    }

    func updateShortcutDisplay() {
        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleRecording) {
            shortcutDisplay = HotkeyManager.formattedShortcut(shortcut)
        } else {
            shortcutDisplay = "Not set"
        }
    }

    func updateSettingsShortcutDisplay() {
        if let shortcut = KeyboardShortcuts.getShortcut(for: .openSettings) {
            settingsShortcutDisplay = HotkeyManager.formattedShortcut(shortcut)
        } else {
            settingsShortcutDisplay = "Not set"
        }
    }

    private static func formattedShortcut(_ shortcut: KeyboardShortcuts.Shortcut) -> String {
        let raw = shortcut.description

        // Replace all four modifier symbols with ✦ (Hyper Key).
        let allModifiers = "\u{2303}\u{2325}\u{21E7}\u{2318}" // ⌃⌥⇧⌘
        if raw.hasPrefix(allModifiers) {
            return "✦" + raw.dropFirst(allModifiers.count)
        }
        return raw
    }

    private static func shortcutsConflict(
        _ lhs: KeyboardShortcuts.Name,
        _ rhs: KeyboardShortcuts.Name
    ) -> Bool {
        guard
            let lhsShortcut = KeyboardShortcuts.getShortcut(for: lhs),
            let rhsShortcut = KeyboardShortcuts.getShortcut(for: rhs)
        else {
            return false
        }

        return lhsShortcut == rhsShortcut
    }
}
