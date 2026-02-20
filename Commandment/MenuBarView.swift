import SwiftUI

struct MenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var transcriptionManager: TranscriptionManager
    @ObservedObject var updateManager: UpdateManager

    private var hasAPIKey: Bool {
        transcriptionManager.getAPIKey() != nil
    }

    private var shouldShowSetupChecklist: Bool {
        !transcriptionManager.setupGuideDismissed
    }

    private var statusSymbolName: String {
        if audioManager.isRecording {
            return "record.circle.fill"
        } else if transcriptionManager.isTranscribing {
            return "arrow.triangle.2.circlepath"
        } else if !hasAPIKey || !transcriptionManager.statusMessage.isEmpty {
            return "exclamationmark.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    private var statusText: String {
        if audioManager.isRecording {
            return "Recording..."
        }
        if transcriptionManager.isTranscribing {
            if !transcriptionManager.statusMessage.isEmpty {
                return transcriptionManager.statusMessage
            }
            return "Transcribing..."
        }
        if !hasAPIKey {
            return "Add API key in Settings"
        }
        if !transcriptionManager.statusMessage.isEmpty {
            return transcriptionManager.statusMessage
        }
        return "Ready"
    }

    private func handleStatusAction() {
        if !hasAPIKey {
            SettingsWindowController.shared.show()
            return
        }

        if !transcriptionManager.statusMessage.isEmpty {
            Logger.shared.openLogFile()
            return
        }

        SettingsWindowController.shared.show()
    }

    var body: some View {
        if shouldShowSetupChecklist {
            SetupChecklistView(
                audioManager: audioManager,
                transcriptionManager: transcriptionManager
            )
        } else {
            normalMenuContent
        }
    }

    @ViewBuilder
    private var normalMenuContent: some View {
        Button(action: handleStatusAction) {
            Label(statusText, systemImage: statusSymbolName)
        }

        Divider()

        Button("Record shortcut: \(hotkeyManager.shortcutDisplay)") {
            SettingsWindowController.shared.show()
        }

        Divider()

        Button("Settings...") {
            SettingsWindowController.shared.show()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Show Logs") {
            Logger.shared.openLogFile()
        }

        Button("Check for Updates...") {
            updateManager.checkForUpdates()
        }
        .disabled(!updateManager.canCheckForUpdates)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
