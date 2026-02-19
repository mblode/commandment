# Commandment

macOS menu bar dictation app — BYO OpenAI API key. Swift 5 / SwiftUI + KeyboardShortcuts SPM.

## Commands
- `open Commandment.xcodeproj` — Open in Xcode
- `xcodebuild -scheme Commandment -configuration Debug build -derivedDataPath /tmp/commandment-build` — Build from CLI
- `xcodebuild -scheme Commandment -configuration Release build -derivedDataPath /tmp/commandment-build` — Release build
- `xcodebuild -scheme Commandment -configuration Debug -destination 'platform=macOS' test -derivedDataPath /tmp/commandment-build` — Run tests

## Setup
- Requires Xcode 16+ and macOS 15.2+ SDK
- SPM dependency: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) v2+
- API key (OpenAI) stored in macOS Keychain, configured via Settings window

## Gotchas
- Audio is recorded at 16 kHz PCM mono
- Text insertion uses AppleScript/System Events — the app requires Accessibility permission in System Settings > Privacy & Security > Accessibility. Without it, transcribed text will not be inserted
- Temp audio file is written to `/tmp/commandment-recording.wav` — do not change this path without updating `RecordingCoordinator`
- The app runs as a menu bar agent (`LSUIElement = true`) — no dock icon or main window. Do not add a `WindowGroup` or `DocumentGroup` scene
- HotkeyManager is `@MainActor` — removing this will cause KeyboardShortcuts crashes on background threads
- Settings changes propagate via `@EnvironmentObject` (`TranscriptionManager`) — do not replace with NotificationCenter
- Default transcription model is `gpt-4o-mini-transcribe` — configured in `TranscriptionManager`
- Default global hotkey is Hyperkey+Y — configured via KeyboardShortcuts in `HotkeyManager`

## Conventions
- Network retries use exponential backoff (1s, 2s, 4s) with max 3 attempts
- Logging goes through `Logger.shared` — use `logInfo()`, `logError()`, `logDebug()` global functions
- Bundle ID: `co.blode.commandment`

## Distribution
- `make build` — Release build
- `make dmg` — Build + create DMG (requires `brew install create-dmg`)
- `make notarize` — Build + DMG + notarize (requires Apple Developer credentials in env)
- `make clean` — Remove build artifacts
- Release: `git tag v1.0.0 && git push origin main --tags` — GitHub Actions handles build/sign/notarize/release
- Secrets (GitHub): `DEVELOPER_ID_CERT_P12`, `DEVELOPER_ID_CERT_PASSWORD`, `APPLE_TEAM_ID`, `NOTARIZE_APPLE_ID`, `NOTARIZE_PASSWORD`
- Homebrew template: `homebrew/commandment.rb` — copy to `mblode/homebrew-tap` repo
