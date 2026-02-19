import SwiftUI

struct MenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var transcriptionManager: TranscriptionManager

    private var hasAPIKey: Bool {
        transcriptionManager.getAPIKey() != nil
    }

    private var shouldShowSetupChecklist: Bool {
        !transcriptionManager.setupGuideDismissed
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
        VStack(alignment: .leading, spacing: 0) {
            statusRow
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)

            Divider()

            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .foregroundStyle(.secondary)
                Text(hotkeyManager.shortcutDisplay)
                    .foregroundStyle(.secondary)
                Text("to record")
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            menuButton(icon: "gearshape", label: "Settings...", shortcut: "\u{2318},") {
                SettingsWindowController.shared.show()
            }

            Divider()

            menuButton(icon: nil, label: "Quit", shortcut: "\u{2318}Q") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.system(size: 13))
        .frame(width: 280)
    }

    // MARK: - Status

    private var statusRow: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            statusText
            Spacer()
            if transcriptionManager.isTranscribing {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var statusColor: Color {
        if audioManager.isRecording {
            return .red
        } else if transcriptionManager.isTranscribing {
            return .yellow
        } else if !hasAPIKey {
            return .orange
        } else if !transcriptionManager.statusMessage.isEmpty {
            return .orange
        } else {
            return .green
        }
    }

    private var statusText: some View {
        Group {
            if audioManager.isRecording {
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
            } else if !hasAPIKey {
                Text("Add API key in Settings")
                    .foregroundStyle(.orange)
            } else if !transcriptionManager.statusMessage.isEmpty {
                Text(transcriptionManager.statusMessage)
                    .foregroundStyle(.orange)
            } else {
                Text("Ready")
                    .foregroundStyle(.primary)
            }
        }
        .fontWeight(.medium)
        .accessibilityLabel(statusAccessibilityLabel)
    }

    private var statusAccessibilityLabel: String {
        if audioManager.isRecording {
            return "Recording audio"
        } else if transcriptionManager.isTranscribing {
            return "Transcribing audio"
        } else if !hasAPIKey {
            return "No API key configured"
        } else {
            return "Ready to record"
        }
    }

    // MARK: - Menu Button

    private func menuButton(icon: String?, label: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .frame(width: 16)
                }
                Text(label)
                if let shortcut {
                    Spacer()
                    Text(shortcut)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
