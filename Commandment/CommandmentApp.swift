//
//  CommandmentApp.swift
//  Commandment
//
//  Created by Matthew Blode.
//

import SwiftUI

@main
struct CommandmentApp: App {
    @StateObject private var audioManager: AudioManager
    @StateObject private var hotkeyManager: HotkeyManager
    @StateObject private var transcriptionManager: TranscriptionManager
    @StateObject private var coordinator: RecordingCoordinator

    // Initialize Logger early
    private let logger = Logger.shared

    init() {
        logInfo("CommandmentApp: Initializing")

        // Create managers first
        let audio = AudioManager()
        let transcription = TranscriptionManager()
        let hotkey = HotkeyManager()
        SettingsWindowController.shared.configure(transcriptionManager: transcription)

        // Initialize coordinator with the same instances
        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription
        )

        // Now create the StateObjects
        _audioManager = StateObject(wrappedValue: audio)
        _hotkeyManager = StateObject(wrappedValue: hotkey)
        _transcriptionManager = StateObject(wrappedValue: transcription)
        _coordinator = StateObject(wrappedValue: coordinator)

        // Log system info
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        logInfo("System: \(osVersion), App Version: \(appVersion)")
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(audioManager: audioManager,
                       hotkeyManager: hotkeyManager,
                       transcriptionManager: transcriptionManager,
                       coordinator: coordinator)
        } label: {
            if audioManager.isRecording {
                Image(systemName: "mic.badge.xmark.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .primary)
            } else if transcriptionManager.isTranscribing {
                Image(systemName: "mic.fill.badge.plus")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.primary, .yellow)
            } else {
                Image(systemName: "mic.fill")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(transcriptionManager)
        }
    }
}
