import SwiftUI

struct MenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var transcriptionManager: TranscriptionManager
    @ObservedObject var coordinator: RecordingCoordinator

    @State private var apiKeyInput: String = ""
    @FocusState private var isAPIKeyFieldFocused: Bool

    private var hasAPIKey: Bool {
        transcriptionManager.getAPIKey() != nil
    }

    private var microphoneReady: Bool {
        audioManager.microphonePermissionState == .granted
    }

    private var needsMicrophonePermission: Bool {
        audioManager.isMicrophonePermissionDenied
    }

    private var needsAccessibilityPermission: Bool {
        !transcriptionManager.hasAccessibilityPermission
    }

    private var autoInsertReady: Bool {
        transcriptionManager.hasAccessibilityPermission
    }

    private var completedSetupSteps: Int {
        var count = 0
        if hasAPIKey { count += 1 }
        if microphoneReady { count += 1 }
        if autoInsertReady { count += 1 }
        return count
    }

    private var requiredSetupComplete: Bool {
        hasAPIKey && microphoneReady
    }

    private var shouldShowSetupGuide: Bool {
        !transcriptionManager.setupGuideDismissed && !requiredSetupComplete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status row
            statusRow
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)

            Divider()

            if shouldShowSetupGuide {
                setupGuideSection
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                Divider()
            }

            if needsMicrophonePermission || needsAccessibilityPermission {
                Divider()

                permissionActionsSection
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

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

            Divider()

            menuButton(icon: nil, label: "Quit", shortcut: "\u{2318}Q") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.system(size: 13))
        .frame(width: 320)
        .onAppear {
            apiKeyInput = transcriptionManager.getAPIKey() ?? ""
            refreshPermissionStates()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissionStates()
        }
        .onDisappear {
            persistAPIKeyIfNeeded()
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

    private var setupGuideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quick setup")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(completedSetupSteps)/3")
                    .foregroundStyle(.secondary)
                    .font(.caption.weight(.semibold))
            }

            Text("Set up API key and microphone to start dictating.")
                .font(.caption)
                .foregroundStyle(.secondary)

            setupStepRow(
                title: "1. API key",
                detail: hasAPIKey ? "Configured in Keychain." : "Required for transcription.",
                isComplete: hasAPIKey
            ) {
                if !hasAPIKey {
                    Button("Add") {
                        isAPIKeyFieldFocused = true
                    }
                }
                Button("Test now") {
                    testAPIKeyStep()
                }
            }

            setupStepRow(
                title: "2. Microphone",
                detail: microphoneReady ? "Access is ready." : "Needed to capture your voice.",
                isComplete: microphoneReady
            ) {
                Button(microphonePermissionActionLabel) {
                    handleMicrophoneAction()
                }
                Button("Test now") {
                    testMicrophoneStep()
                }
            }

            setupStepRow(
                title: "3. Auto-insert (optional)",
                detail: autoInsertReady
                    ? "Accessibility is ready."
                    : "Grant Accessibility to paste directly into the focused app.",
                isComplete: autoInsertReady,
                isOptional: true
            ) {
                if !transcriptionManager.hasAccessibilityPermission {
                    Button("Grant") {
                        transcriptionManager.openAccessibilitySettings()
                    }
                }
                Button("Test now") {
                    testAutoInsertStep()
                }
            }

            HStack(spacing: 10) {
                Button("Skip for now") {
                    transcriptionManager.dismissSetupGuide()
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Settings") {
                    SettingsWindowController.shared.show()
                }
            }
            .padding(.top, 2)
        }
    }

    private func setupStepRow(
        title: String,
        detail: String,
        isComplete: Bool,
        isOptional: Bool = false,
        @ViewBuilder controls: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isComplete ? .green : .secondary)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.callout.weight(.semibold))
                        if isOptional {
                            Text("Optional")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                controls()
            }
            .padding(.leading, 24)
        }
    }

    private var permissionActionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if needsMicrophonePermission {
                permissionActionButton(
                    icon: "mic.badge.xmark",
                    label: microphonePermissionActionLabel,
                    action: handleMicrophoneAction
                )
            }

            if needsAccessibilityPermission {
                permissionActionButton(
                    icon: "figure.wave",
                    label: "Enable Accessibility for Auto-insert",
                    action: transcriptionManager.openAccessibilitySettings
                )
            }
        }
    }

    private func permissionActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(label)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                .focused($isAPIKeyFieldFocused)
                .accessibilityLabel("OpenAI API key")
                .onSubmit {
                    persistAPIKeyIfNeeded()
                }
                .onChange(of: isAPIKeyFieldFocused) { oldValue, newValue in
                    if oldValue && !newValue {
                        persistAPIKeyIfNeeded()
                    }
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
        if needsMicrophonePermission {
            return .orange
        } else if needsAccessibilityPermission {
            return .orange
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
            if needsMicrophonePermission {
                Text("Microphone permission needed")
                    .foregroundStyle(.orange)
            } else if needsAccessibilityPermission {
                Text("Auto-insert needs Accessibility")
                    .foregroundStyle(.orange)
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
        if needsMicrophonePermission {
            return "Needs microphone permission"
        } else if needsAccessibilityPermission {
            return "Needs accessibility permission for auto insert mode"
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

    private var microphonePermissionActionLabel: String {
        switch audioManager.microphonePermissionState {
        case .denied, .restricted:
            return "Open Microphone Settings"
        case .notDetermined:
            return "Allow Microphone Access"
        case .granted:
            return "Refresh"
        }
    }

    private func refreshPermissionStates() {
        audioManager.refreshMicrophonePermissionState()
        transcriptionManager.recheckAccessibilityPermission()
    }

    private func persistAPIKeyIfNeeded() {
        let trimmedKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingKey = transcriptionManager.getAPIKey() ?? ""

        guard trimmedKey != existingKey else {
            return
        }

        transcriptionManager.setAPIKey(trimmedKey)
        apiKeyInput = trimmedKey
    }

    private func handleMicrophoneAction() {
        switch audioManager.microphonePermissionState {
        case .granted:
            refreshPermissionStates()
        case .notDetermined:
            audioManager.requestMicrophonePermissionIfNeeded { _ in
                refreshPermissionStates()
            }
        case .denied, .restricted:
            audioManager.openMicrophoneSettings()
        }
    }

    private func testAPIKeyStep() {
        persistAPIKeyIfNeeded()
        if transcriptionManager.isAPIKeyConfigured() {
            if transcriptionManager.doesAPIKeyLookValid() {
                transcriptionManager.setStatusMessage("API key looks valid.")
            } else {
                transcriptionManager.setStatusMessage("API key is saved, but format looks unusual.")
            }
        } else {
            transcriptionManager.setStatusMessage("Add an OpenAI API key to continue setup.")
            isAPIKeyFieldFocused = true
        }
    }

    private func testMicrophoneStep() {
        audioManager.requestMicrophonePermissionIfNeeded { granted in
            if granted {
                transcriptionManager.setStatusMessage("Microphone access is ready.")
            } else {
                transcriptionManager.setStatusMessage("Microphone access is still blocked.")
            }
            refreshPermissionStates()
        }
    }

    private func testAutoInsertStep() {
        let hasPermission = transcriptionManager.refreshAccessibilityPermissionState()
        if hasPermission {
            transcriptionManager.setStatusMessage("Auto-insert is ready.")
        } else {
            transcriptionManager.setStatusMessage("Grant Accessibility to finish auto-insert setup.")
        }
    }
}
