import SwiftUI

struct MenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var transcriptionManager: TranscriptionManager
    @ObservedObject var coordinator: RecordingCoordinator

    @State private var apiKeyInput: String = ""

    private var hasAPIKey: Bool {
        transcriptionManager.getAPIKey() != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status row
            statusRow
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)

            Divider()

            // API key
            apiKeySection
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // Shortcut hint
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

            // Actions
            menuButton(icon: "gearshape", label: "Settings...", shortcut: "\u{2318},") {
                SettingsWindowController.shared.show()
            }

            menuButton(icon: "doc.text.magnifyingglass", label: "View Logs") {
                Logger.shared.openLogFile()
            }

            Divider()

            menuButton(icon: nil, label: "Quit", shortcut: "\u{2318}Q") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.system(size: 13))
        .frame(width: 260)
        .onAppear {
            transcriptionManager.recheckAccessibilityPermission()
        }
    }

    // MARK: - Sections

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

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("API key")
                    .foregroundStyle(.secondary)
                Spacer()
                if hasAPIKey {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel("API key configured")
                }
            }
            SecureField("sk-...", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .accessibilityLabel("OpenAI API key")
                .onAppear {
                    apiKeyInput = transcriptionManager.getAPIKey() ?? ""
                }
                .onSubmit {
                    transcriptionManager.setAPIKey(apiKeyInput)
                }
        }
    }

    // MARK: - Reusable Menu Button

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

    // MARK: - Status

    private var statusColor: Color {
        if !transcriptionManager.hasAccessibilityPermission {
            return .red
        } else if audioManager.isRecording {
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
            if !transcriptionManager.hasAccessibilityPermission {
                Button("Needs permission") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
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
            } else if !hasAPIKey {
                Text("Add API key")
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
        if !transcriptionManager.hasAccessibilityPermission {
            return "Needs accessibility permission. Activate to open System Settings."
        } else if audioManager.isRecording {
            return "Recording audio"
        } else if transcriptionManager.isTranscribing {
            return "Transcribing audio"
        } else if !hasAPIKey {
            return "No API key configured"
        } else {
            return "Ready to record"
        }
    }
}
