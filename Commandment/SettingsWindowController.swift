import SwiftUI
import AppKit

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private weak var transcriptionManager: TranscriptionManager?
    private weak var audioManager: AudioManager?
    private var windowController: NSWindowController?

    private init() {}

    func configure(transcriptionManager: TranscriptionManager, audioManager: AudioManager) {
        self.transcriptionManager = transcriptionManager
        self.audioManager = audioManager

        if let window = windowController?.window, let storedAudioManager = self.audioManager {
            window.contentViewController = NSHostingController(
                rootView: SettingsView()
                    .environmentObject(transcriptionManager)
                    .environmentObject(storedAudioManager)
            )
        }
    }

    func show() {
        guard let transcriptionManager, let audioManager else {
            logError("SettingsWindowController: Missing managers")
            return
        }

        let controller: NSWindowController
        if let existing = windowController {
            controller = existing
        } else {
            controller = makeWindowController(transcriptionManager: transcriptionManager, audioManager: audioManager)
            windowController = controller
        }

        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindowController(
        transcriptionManager: TranscriptionManager,
        audioManager: AudioManager
    ) -> NSWindowController {
        let hostingController = NSHostingController(
            rootView: SettingsView()
                .environmentObject(transcriptionManager)
                .environmentObject(audioManager)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
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
