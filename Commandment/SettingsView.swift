import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    @EnvironmentObject private var transcriptionManager: TranscriptionManager
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var updateManager: UpdateManager
    @State private var apiKey: String = ""
    @FocusState private var isAPIKeyFieldFocused: Bool

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        Form {
            Section {
                SecureField("", text: $apiKey, prompt: Text("sk-..."))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .labelsHidden()
                    .focused($isAPIKeyFieldFocused)
                    .onSubmit { persistAPIKeyIfNeeded() }
                    .onChange(of: isAPIKeyFieldFocused) { oldValue, newValue in
                        if oldValue && !newValue { persistAPIKeyIfNeeded() }
                    }

                HStack {
                    Text("Stored securely in macOS Keychain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("Get API key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                }
            } header: {
                Text("OpenAI API Key")
            }

            Section("General") {
                LaunchAtLogin.Toggle("Launch at login")

                HStack {
                    Text("Hold to record")
                    Spacer()
                    KeyboardShortcuts.Recorder("", name: .toggleRecording)
                }
            }

            Section("Permissions") {
                HStack {
                    Text("Microphone")
                    Spacer()
                    if audioManager.microphonePermissionState == .granted {
                        Label("Allowed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                    } else {
                        Button(microphoneActionLabel) {
                            handleMicrophoneAction()
                        }
                    }
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-insert")
                        Text("Pastes directly into the focused app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if transcriptionManager.hasAccessibilityPermission {
                        Label("Allowed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                    } else {
                        Button("Allow") {
                            transcriptionManager.openAccessibilitySettings()
                        }
                    }
                }
            }

            Section("Updates") {
                HStack {
                    Button("Check for Updates...") {
                        updateManager.checkForUpdates()
                    }
                    .disabled(!updateManager.canCheckForUpdates)

                    Spacer()

                    Link("Release Notes", destination: URL(string: "https://github.com/mblode/commandment/releases")!)
                        .font(.callout)
                }

                Toggle("Automatically check for updates", isOn: automaticallyChecksBinding)

                Toggle("Automatically download updates", isOn: automaticallyDownloadsBinding)
                    .disabled(!updateManager.automaticallyChecksForUpdates)

                Text("Updates are checked against signed, notarized GitHub releases.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Commandment v\(appVersion)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("GitHub", destination: URL(string: "https://github.com/mblode/commandment")!)
                }
                .font(.callout)
            }
        }
        .formStyle(.grouped)
        .frame(width: 430, height: 390)
        .onAppear {
            apiKey = transcriptionManager.getAPIKey() ?? ""
            audioManager.refreshMicrophonePermissionState()
            transcriptionManager.recheckAccessibilityPermission()
        }
        .onDisappear {
            persistAPIKeyIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            audioManager.refreshMicrophonePermissionState()
            transcriptionManager.recheckAccessibilityPermission()
        }
    }

    private var microphoneActionLabel: String {
        switch audioManager.microphonePermissionState {
        case .granted: return "Granted"
        case .notDetermined: return "Allow"
        case .denied, .restricted: return "Open Settings"
        }
    }

    private func handleMicrophoneAction() {
        switch audioManager.microphonePermissionState {
        case .granted:
            audioManager.refreshMicrophonePermissionState()
        case .notDetermined:
            audioManager.requestMicrophonePermissionIfNeeded { _ in
                audioManager.refreshMicrophonePermissionState()
            }
        case .denied, .restricted:
            audioManager.openMicrophoneSettings()
        }
    }

    private func persistAPIKeyIfNeeded() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingKey = transcriptionManager.getAPIKey() ?? ""
        guard trimmedKey != existingKey else { return }
        transcriptionManager.setAPIKey(trimmedKey)
        apiKey = trimmedKey
    }

    private var automaticallyChecksBinding: Binding<Bool> {
        Binding(
            get: { updateManager.automaticallyChecksForUpdates },
            set: { updateManager.setAutomaticallyChecksForUpdates($0) }
        )
    }

    private var automaticallyDownloadsBinding: Binding<Bool> {
        Binding(
            get: { updateManager.automaticallyDownloadsUpdates },
            set: { updateManager.setAutomaticallyDownloadsUpdates($0) }
        )
    }
}
