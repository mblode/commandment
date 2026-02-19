//
//  CommandmentApp.swift
//  Commandment
//
//  Created by Matthew Blode.
//

import AppKit
import SwiftUI

@main
struct CommandmentApp: App {
    @StateObject private var audioManager: AudioManager
    @StateObject private var hotkeyManager: HotkeyManager
    @StateObject private var transcriptionManager: TranscriptionManager
    @StateObject private var updateManager: UpdateManager
    @StateObject private var coordinator: RecordingCoordinator

    // Initialize Logger early
    private let logger = Logger.shared
    private static let menuBarLogoImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "logo", withExtension: "svg"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        // Template icons adapt correctly to light/dark menu bar appearances.
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }()

    init() {
        logInfo("CommandmentApp: Initializing")

        // Create managers first
        let audio = AudioManager()
        let transcription = TranscriptionManager()
        let hotkey = HotkeyManager()
        let updater = UpdateManager()
        SettingsWindowController.shared.configure(
            transcriptionManager: transcription,
            audioManager: audio,
            updateManager: updater
        )

        // Initialize coordinator with the same instances
        let coordinator = RecordingCoordinator(
            audioManager: audio,
            transcriptionManager: transcription
        )

        // Now create the StateObjects
        _audioManager = StateObject(wrappedValue: audio)
        _hotkeyManager = StateObject(wrappedValue: hotkey)
        _transcriptionManager = StateObject(wrappedValue: transcription)
        _updateManager = StateObject(wrappedValue: updater)
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
                       updateManager: updateManager)
        } label: {
            menuBarIcon
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(transcriptionManager)
                .environmentObject(audioManager)
                .environmentObject(updateManager)
        }
    }

    private var menuBarIcon: Image {
        if let logoImage = Self.menuBarLogoImage {
            return Image(nsImage: logoImage)
        }
        return Image(systemName: "mic.fill")
    }
}
