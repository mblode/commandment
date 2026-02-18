# WhisperDictate

macOS menu bar app for voice dictation via OpenAI Whisper API. Swift 5 / SwiftUI, no external dependencies.

## Commands
- `open WhisperDictate.xcodeproj` — Open in Xcode
- `xcodebuild -scheme WhisperDictate -configuration Debug build` — Build from CLI
- `xcodebuild -scheme WhisperDictate -configuration Release build` — Release build

## Setup
- Requires Xcode 15+ and macOS 15.2+ SDK
- No dependency manager — all frameworks are Apple system frameworks
- API key (OpenAI) is stored in UserDefaults, entered via the menu bar settings UI

## Architecture
- **WhisperDictateApp.swift** — Entry point, app delegate, menu bar scene
- **AudioManager.swift** — AVAudioEngine recording, format conversion, adaptive compression
- **TranscriptionManager.swift** — Whisper API calls, retry logic, AppleScript text insertion
- **RecordingCoordinator.swift** — Orchestrates record → transcribe → type flow
- **HotkeyManager.swift** — Global Option+D hotkey via Carbon APIs
- **MenuBarView.swift** — SwiftUI settings panel and status display
- **Logger.swift** — File-based logging to ~/Documents/WhisperDictate.log

## Gotchas
- Audio is recorded at 16 kHz PCM mono (Whisper-optimized) — do not change the sample rate without updating the compression pipeline in AudioManager
- Text insertion uses AppleScript/System Events — requires Accessibility permission; test with a real text field, not just the console
- Global hotkey uses Carbon Event APIs (not modern SwiftUI keyboard shortcuts) — this is intentional for reliability across all apps
- Temp audio file is written to `/tmp/whisper-dictate-recording.wav` — cleaned up after transcription
- The app runs as a menu bar agent (`LSUIElement = true`) — it has no dock icon or main window

## Conventions
- All audio processing uses Int16 PCM buffers for memory efficiency
- Network retries use exponential backoff (1s, 2s, 4s) with max 3 attempts
- Logging goes through the singleton `Logger.shared` — use `Logger.shared.log()` not `print()`
