import SwiftUI
import AppKit

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private weak var transcriptionManager: TranscriptionManager?
    private var windowController: NSWindowController?

    private init() {}

    func configure(transcriptionManager: TranscriptionManager) {
        self.transcriptionManager = transcriptionManager

        if let window = windowController?.window {
            window.contentViewController = NSHostingController(
                rootView: SettingsView().environmentObject(transcriptionManager)
            )
        }
    }

    func show() {
        guard let transcriptionManager else {
            logError("SettingsWindowController: Missing TranscriptionManager")
            return
        }

        let controller: NSWindowController
        if let existing = windowController {
            controller = existing
        } else {
            controller = makeWindowController(transcriptionManager: transcriptionManager)
            windowController = controller
        }

        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindowController(transcriptionManager: TranscriptionManager) -> NSWindowController {
        let hostingController = NSHostingController(
            rootView: SettingsView().environmentObject(transcriptionManager)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("CommandmentSettingsWindow")
        window.center()

        return NSWindowController(window: window)
    }
}
