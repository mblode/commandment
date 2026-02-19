import SwiftUI

struct SetupChecklistView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var transcriptionManager: TranscriptionManager

    @State private var pollTimer: Timer?

    private var isAPIKeySet: Bool {
        transcriptionManager.getAPIKey() != nil
    }

    private var isMicrophoneGranted: Bool {
        audioManager.microphonePermissionState == .granted
    }

    private var isAccessibilityGranted: Bool {
        transcriptionManager.hasAccessibilityPermission
    }

    private var allStepsComplete: Bool {
        isAPIKeySet && isMicrophoneGranted && isAccessibilityGranted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Setup Commandment")
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Divider()

            // Step 1: API Key
            stepRow(
                number: 1,
                title: "Provide OpenAI API Key",
                description: "Required for speech-to-text",
                isComplete: isAPIKeySet
            ) {
                HStack(spacing: 6) {
                    Link("Get API key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                    Button("Add Key") {
                        SettingsWindowController.shared.show()
                    }
                    .controlSize(.small)
                }
            }

            Divider()

            // Step 2: Microphone
            stepRow(
                number: 2,
                title: "Allow microphone access",
                description: "Required to record audio",
                isComplete: isMicrophoneGranted
            ) {
                Button(microphoneActionLabel) {
                    handleMicrophoneAction()
                }
                .controlSize(.small)
            }

            Divider()

            // Step 3: Accessibility
            stepRow(
                number: 3,
                title: "Allow pasting text",
                description: "Inserts transcript into any app",
                isComplete: isAccessibilityGranted
            ) {
                Button("Allow") {
                    transcriptionManager.openAccessibilitySettings()
                }
                .controlSize(.small)
            }

            Divider()

            if allStepsComplete {
                Button(action: { transcriptionManager.setupGuideDismissed = true }) {
                    Text("Get Started")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()
            }

            HStack {
                Button("Skip for now") {
                    transcriptionManager.setupGuideDismissed = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .font(.system(size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .font(.system(size: 13))
        .frame(width: 280)
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Permission Polling

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                audioManager.refreshMicrophonePermissionState()
                transcriptionManager.recheckAccessibilityPermission()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Step Row

    private func stepRow<Action: View>(
        number: Int,
        title: String,
        description: String,
        isComplete: Bool,
        @ViewBuilder action: () -> Action
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16))
                    .frame(width: 22, height: 22)
            } else {
                Text("\(number)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.secondary.opacity(0.5)))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    if !isComplete {
                        action()
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Microphone Actions

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
}
