import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            APISettingsView()
                .tabItem {
                    Label("API", systemImage: "key")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 280)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
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
        }
        .formStyle(.grouped)
    }
}

// MARK: - API

struct APISettingsView: View {
    @EnvironmentObject var transcriptionManager: TranscriptionManager
    @State private var apiKey: String = ""

    var body: some View {
        Form {
            Section {
                SecureField("OpenAI API Key", text: $apiKey)
                    .onChange(of: apiKey) { _, newValue in
                        transcriptionManager.setAPIKey(newValue)
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
