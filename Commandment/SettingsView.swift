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
                    Text("Toggle Recording:")
                    Spacer()
                    KeyboardShortcuts.Recorder("", name: .toggleRecording)
                }

                HStack {
                    Text("Default:")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                    Text("\u{2303}\u{2325}\u{21E7}\u{2318}Y")
                        .foregroundStyle(.secondary)
                        .font(.caption)
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
    @State private var selectedModel: TranscriptionModel = .gpt4oMiniTranscribe

    var body: some View {
        Form {
            Section {
                SecureField("OpenAI API Key", text: $apiKey)
                    .onChange(of: apiKey) { _, newValue in
                        saveAPIKey(newValue)
                    }

                Text("Stored securely in macOS Keychain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Model", selection: $selectedModel) {
                    ForEach(TranscriptionModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .onChange(of: selectedModel) { _, newValue in
                    transcriptionManager.setModel(newValue)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            apiKey = transcriptionManager.getAPIKey() ?? ""
            selectedModel = transcriptionManager.selectedModel
        }
    }

    private func saveAPIKey(_ key: String) {
        if key.isEmpty {
            KeychainManager.deleteAPIKey()
        } else {
            KeychainManager.saveAPIKey(key)
        }
        transcriptionManager.setAPIKey(key)
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
