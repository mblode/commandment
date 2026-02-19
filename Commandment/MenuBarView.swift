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

            menuButton(icon: "doc.text.magnifyingglass", label: "Show Logs") {
                Logger.shared.openLogFile()
            }

            menuButton(
                icon: "arrow.triangle.2.circlepath",
                label: "Check for Updates...",
                isEnabled: updateManager.canCheckForUpdates
            ) {
                updateManager.checkForUpdates()
            }

            Divider()

            menuButton(icon: "xmark", label: "Quit", shortcut: "\u{2318}Q") {
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

    private func menuButton(
        icon: String?,
        label: String,
        shortcut: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        MenuBarRowButton(
            icon: icon,
            label: label,
            shortcut: shortcut,
            isEnabled: isEnabled,
            action: action
        )
    }

    private struct MenuBarRowButton: View {
        let icon: String?
        let label: String
        let shortcut: String?
        let isEnabled: Bool
        let action: () -> Void

        private enum Metrics {
            static let rowHeight: CGFloat = 24
            static let horizontalInset: CGFloat = 12
            static let iconColumnWidth: CGFloat = 18
            static let iconSize: CGFloat = 16
            static let contentSpacing: CGFloat = 8
            static let shortcutMinWidth: CGFloat = 40
        }

        @State private var isHovering = false

        private var rowBackgroundColor: Color {
            (isEnabled && isHovering) ? Color(nsColor: .selectedContentBackgroundColor) : .clear
        }

        private var rowForegroundColor: Color {
            if !isEnabled {
                return .secondary
            }
            return isHovering ? Color(nsColor: .selectedMenuItemTextColor) : .primary
        }

        private var shortcutForegroundColor: Color {
            if !isEnabled {
                return .secondary
            }
            return isHovering ? Color(nsColor: .selectedMenuItemTextColor) : .secondary
        }

        private var iconColumn: some View {
            Group {
                if let icon {
                    Image(systemName: icon)
                        .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                } else {
                    Color.clear
                        .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                }
            }
            .frame(width: Metrics.iconColumnWidth, alignment: .center)
        }

        var body: some View {
            Button(action: action) {
                HStack(spacing: Metrics.contentSpacing) {
                    iconColumn
                    Text(label)
                        .lineLimit(1)
                    if let shortcut {
                        Spacer(minLength: 0)
                        Text(shortcut)
                            .lineLimit(1)
                            .frame(minWidth: Metrics.shortcutMinWidth, alignment: .trailing)
                            .foregroundStyle(shortcutForegroundColor)
                    }
                }
                .padding(.horizontal, Metrics.horizontalInset)
                .frame(maxWidth: .infinity, minHeight: Metrics.rowHeight, maxHeight: Metrics.rowHeight, alignment: .leading)
                .contentShape(Rectangle())
                .foregroundStyle(rowForegroundColor)
                .background(rowBackgroundColor)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .onHover { hovering in
                isHovering = isEnabled && hovering
            }
        }
    }
}
