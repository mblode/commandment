import SwiftUI
import KeyboardShortcuts

enum SettingsTab: Hashable {
    case setup
    case general
    case api
    case about
}

struct SettingsView: View {
    @EnvironmentObject private var transcriptionManager: TranscriptionManager
    @State private var selectedTab: SettingsTab = .general
    @State private var initializedSelection = false

    var body: some View {
        TabView(selection: $selectedTab) {
            SetupSettingsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Setup", systemImage: "checklist")
                }
                .tag(SettingsTab.setup)

            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            APISettingsView()
                .tabItem {
                    Label("API", systemImage: "key")
                }
                .tag(SettingsTab.api)

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 480, height: 360)
        .onAppear {
            guard !initializedSelection else { return }
            selectedTab = transcriptionManager.setupGuideDismissed ? .general : .setup
            initializedSelection = true
        }
    }
}

// MARK: - Setup

struct SetupSettingsView: View {
    @EnvironmentObject private var transcriptionManager: TranscriptionManager
    @EnvironmentObject private var audioManager: AudioManager
    @Binding var selectedTab: SettingsTab

    private var hasAPIKey: Bool {
        transcriptionManager.isAPIKeyConfigured()
    }

    private var microphoneReady: Bool {
        audioManager.microphonePermissionState == .granted
    }

    private var autoInsertReady: Bool {
        transcriptionManager.hasAccessibilityPermission
    }

    private var completedSteps: Int {
        var count = 0
        if hasAPIKey { count += 1 }
        if microphoneReady { count += 1 }
        if autoInsertReady { count += 1 }
        return count
    }

    private var requiredSetupComplete: Bool {
        hasAPIKey && microphoneReady
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Quick setup")
                        .font(.headline)
                    Spacer()
                    Text("\(completedSteps)/3")
                        .foregroundStyle(.secondary)
                        .font(.callout.weight(.semibold))
                }
                Text("Get first transcription working in under a minute.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                setupStep(
                    title: "1. Add API key",
                    detail: hasAPIKey
                        ? "Key is saved in Keychain."
                        : "Required to send audio to OpenAI.",
                    isComplete: hasAPIKey
                ) {
                    if !hasAPIKey {
                        Button("Open API tab") {
                            selectedTab = .api
                        }
                    }
                    Button("Test now") {
                        testAPIKeyStep()
                    }
                }

                setupStep(
                    title: "2. Allow microphone",
                    detail: microphoneReady
                        ? "Microphone access is ready."
                        : "Needed to capture your voice.",
                    isComplete: microphoneReady
                ) {
                    Button(microphoneActionLabel) {
                        handleMicrophoneAction()
                    }
                    Button("Test now") {
                        testMicrophoneStep()
                    }
                }

                setupStep(
                    title: "3. Enable auto-insert (optional)",
                    detail: autoInsertReady
                        ? "Auto-insert is ready."
                        : "Grant Accessibility to paste directly into focused apps.",
                    isComplete: autoInsertReady,
                    isOptional: true
                ) {
                    if !transcriptionManager.hasAccessibilityPermission {
                        Button("Grant Access") {
                            transcriptionManager.openAccessibilitySettings()
                        }
                    }
                    Button("Test now") {
                        testAutoInsertStep()
                    }
                }
            }

            Section {
                if requiredSetupComplete {
                    Button("Mark setup done") {
                        transcriptionManager.dismissSetupGuide()
                        selectedTab = .general
                    }
                } else {
                    Button("Skip for now") {
                        transcriptionManager.dismissSetupGuide()
                        selectedTab = .general
                    }
                }

                Button("Reset setup guide") {
                    transcriptionManager.resetSetupGuide()
                    refreshPermissions()
                }
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
        }
    }

    private var microphoneActionLabel: String {
        switch audioManager.microphonePermissionState {
        case .granted:
            return "Granted"
        case .notDetermined:
            return "Allow"
        case .denied, .restricted:
            return "Open Settings"
        }
    }

    private func setupStep(
        title: String,
        detail: String,
        isComplete: Bool,
        isOptional: Bool = false,
        @ViewBuilder controls: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isComplete ? .green : .secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.callout.weight(.semibold))
                        if isOptional {
                            Text("Optional")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
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
            .padding(.leading, 30)
        }
        .padding(.vertical, 2)
    }

    private func refreshPermissions() {
        audioManager.refreshMicrophonePermissionState()
        transcriptionManager.recheckAccessibilityPermission()
    }

    private func testAPIKeyStep() {
        if transcriptionManager.isAPIKeyConfigured() {
            if transcriptionManager.doesAPIKeyLookValid() {
                transcriptionManager.setStatusMessage("API key looks valid.")
            } else {
                transcriptionManager.setStatusMessage("API key is saved, but format looks unusual.")
            }
        } else {
            transcriptionManager.setStatusMessage("Add an OpenAI API key first.")
            selectedTab = .api
        }
    }

    private func handleMicrophoneAction() {
        switch audioManager.microphonePermissionState {
        case .granted:
            refreshPermissions()
        case .notDetermined:
            audioManager.requestMicrophonePermissionIfNeeded { _ in
                refreshPermissions()
            }
        case .denied, .restricted:
            audioManager.openMicrophoneSettings()
        }
    }

    private func testMicrophoneStep() {
        audioManager.requestMicrophonePermissionIfNeeded { granted in
            if granted {
                transcriptionManager.setStatusMessage("Microphone access is ready.")
            } else {
                transcriptionManager.setStatusMessage("Microphone access is still blocked.")
            }
            refreshPermissions()
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

// MARK: - General

struct GeneralSettingsView: View {
    @EnvironmentObject private var transcriptionManager: TranscriptionManager

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Hold to record:")
                    Spacer()
                    KeyboardShortcuts.Recorder("", name: .toggleRecording)
                }

                HStack {
                    Text("Default:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("✦Y")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Text("After transcription")
                    Spacer()
                    Text("Auto-insert")
                        .foregroundStyle(.secondary)
                }

                Text("Auto-insert pastes into the focused app when Accessibility permission is granted. Without it, transcripts are copied to your clipboard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !transcriptionManager.hasAccessibilityPermission {
                    Button("Grant Accessibility Permission") {
                        transcriptionManager.openAccessibilitySettings()
                    }
                }
            }

            Section {
                Button("Reset setup guide") {
                    transcriptionManager.resetSetupGuide()
                }
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            transcriptionManager.recheckAccessibilityPermission()
        }
    }
}

// MARK: - API

struct APISettingsView: View {
    @EnvironmentObject private var transcriptionManager: TranscriptionManager
    @State private var apiKey: String = ""
    @FocusState private var isAPIKeyFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                SecureField("OpenAI API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($isAPIKeyFieldFocused)
                    .onSubmit {
                        persistAPIKeyIfNeeded()
                    }
                    .onChange(of: isAPIKeyFieldFocused) { oldValue, newValue in
                        if oldValue && !newValue {
                            persistAPIKeyIfNeeded()
                        }
                    }

                Text("Stored securely in macOS Keychain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Model")
                    Spacer()
                    Text(TranscriptionModel.gpt4oMiniTranscribe.displayName)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            apiKey = transcriptionManager.getAPIKey() ?? ""
        }
        .onDisappear {
            persistAPIKeyIfNeeded()
        }
    }

    private func persistAPIKeyIfNeeded() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingKey = transcriptionManager.getAPIKey() ?? ""

        guard trimmedKey != existingKey else {
            return
        }

        transcriptionManager.setAPIKey(trimmedKey)
        apiKey = trimmedKey
    }
}

// MARK: - About

struct AboutSettingsView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Commandment")
                .font(.title2.bold())

            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("by Matthew Blode")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Link("GitHub", destination: URL(string: "https://github.com/mblode/commandment")!)
                    .font(.callout)
                Link("Contact", destination: URL(string: "mailto:m@blode.co")!)
                    .font(.callout)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
