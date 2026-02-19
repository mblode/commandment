import SwiftUI

struct MenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var transcriptionManager: TranscriptionManager
    @ObservedObject var coordinator: RecordingCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status row
            HStack(spacing: 6) {
                statusDot
                statusText
                Spacer()
                if transcriptionManager.isTranscribing {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Divider()

            // Shortcut hint
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(hotkeyManager.shortcutDisplay)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("to record")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Actions
            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings...")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                Logger.shared.openLogFile()
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("View Logs")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Text("Quit Commandment")
                    Spacer()
                    Text("\u{2318}Q")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 240)
    }

    // MARK: - Status Components

    @ViewBuilder
    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        if !transcriptionManager.hasAccessibilityPermission {
            return .red
        } else if audioManager.isRecording {
            return .red
        } else if transcriptionManager.isTranscribing {
            return .yellow
        } else if !transcriptionManager.statusMessage.isEmpty {
            return .orange
        } else {
            return .green
        }
    }

    private var statusText: some View {
        Group {
            if !transcriptionManager.hasAccessibilityPermission {
                Text("Needs Permission")
                    .foregroundStyle(.red)
            } else if audioManager.isRecording {
                Text("Recording...")
                    .foregroundStyle(.primary)
            } else if transcriptionManager.isTranscribing {
                if !transcriptionManager.statusMessage.isEmpty {
                    Text(transcriptionManager.statusMessage)
                        .foregroundStyle(.primary)
                } else {
                    Text("Transcribing...")
                        .foregroundStyle(.primary)
                }
            } else if !transcriptionManager.statusMessage.isEmpty {
                Text(transcriptionManager.statusMessage)
                    .foregroundStyle(.orange)
            } else {
                Text("Ready")
                    .foregroundStyle(.primary)
            }
        }
        .font(.callout.weight(.medium))
    }
}
