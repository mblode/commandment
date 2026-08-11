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
        setupSteps
            .onAppear { startPolling() }
            .onDisappear { stopPolling() }
    }

    @ViewBuilder
    private var setupSteps: some View {
        Text("Finish Setup")

        if isAPIKeySet {
            Label("OpenAI API key configured", systemImage: "checkmark.circle.fill")
        } else {
            Label("OpenAI API key required", systemImage: "exclamationmark.circle.fill")
            Button("Add API Key...") {
                SettingsWindowController.shared.show()
            }
            Link("Get API key", destination: URL(string: "https://platform.openai.com/api-keys")!)
        }

        if isMicrophoneGranted {
            Label("Microphone access allowed", systemImage: "checkmark.circle.fill")
        } else {
            Label("Microphone access required", systemImage: "mic.slash.fill")
            Button(microphoneActionLabel) {
                handleMicrophoneAction()
            }
        }

        if isAccessibilityGranted {
            Label("Auto-insert permission allowed", systemImage: "checkmark.circle.fill")
        } else {
            Label("Auto-insert permission required", systemImage: "keyboard.badge.eye")
            Button("Allow Pasting...") {
                transcriptionManager.openAccessibilitySettings()
            }
        }

        Divider()

        if allStepsComplete {
            Button("Get Started") {
                transcriptionManager.setupGuideDismissed = true
            }
        }

        Button("Skip for Now") {
            transcriptionManager.setupGuideDismissed = true
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
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

    // MARK: - Microphone Actions

    private var microphoneActionLabel: String {
        switch audioManager.microphonePermissionState {
        case .granted: return "Granted"
        case .notDetermined: return "Allow Microphone..."
        case .denied, .restricted: return "Open Microphone Settings..."
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
