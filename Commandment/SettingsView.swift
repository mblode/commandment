import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @EnvironmentObject private var transcriptionManager: TranscriptionManager
    @EnvironmentObject private var audioManager: AudioManager
    @State private var apiKey: String = ""
    @FocusState private var isAPIKeyFieldFocused: Bool

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        Form {
            Section("API Key") {
                SecureField("sk-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($isAPIKeyFieldFocused)
                    .onSubmit { persistAPIKeyIfNeeded() }
                    .onChange(of: isAPIKeyFieldFocused) { oldValue, newValue in
                        if oldValue && !newValue { persistAPIKeyIfNeeded() }
                    }

                Text("Stored securely in macOS Keychain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Shortcut") {
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
                        Label("Granted", systemImage: "checkmark.circle.fill")
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
                        Label("Enabled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                    } else {
                        Button("Grant Access") {
                            transcriptionManager.openAccessibilitySettings()
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("Commandment v\(appVersion)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("GitHub", destination: URL(string: "https://github.com/mblode/commandment")!)
                    Link("Contact", destination: URL(string: "mailto:m@blode.co")!)
                }
                .font(.callout)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
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
}
