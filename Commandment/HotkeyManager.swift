import Foundation
import Cocoa
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.y, modifiers: [.control, .option, .shift, .command]))
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
            logDebug("HotkeyManager: Hotkey pressed")
            NotificationCenter.default.post(name: NSNotification.Name("HotkeyPressed"), object: nil)
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
            shortcutDisplay = shortcut.description
        } else {
            shortcutDisplay = "Not set"
        }
    }
}
