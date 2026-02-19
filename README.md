# Commandment

A minimal macOS menu bar app for voice dictation using OpenAI's transcription API. Press a hotkey, speak, and your words are typed wherever your cursor is.

## Download

**[Download the latest release](https://github.com/mblode/commandment/releases/latest)** (macOS 15.2+)

Or install with Homebrew:

```bash
brew tap mblode/tap
brew install --cask commandment
```

## Features

- Global hotkey (default: Hyperkey+Y) — configurable in Settings
- Fast transcription via gpt-4o-mini-transcribe
- Types text directly into any app via System Events
- API key stored securely in macOS Keychain
- Floating overlay showing recording/processing/success states
- Clean menu bar interface with status indicator
- Signed and notarized by Apple

## Getting Started

1. Download the DMG and drag Commandment to Applications
2. Launch Commandment — a microphone icon appears in your menu bar
3. Open Settings (click menu bar icon → Settings) and enter your OpenAI API key
4. Grant **microphone** and **accessibility** permissions when prompted
5. Place your cursor where you want text, press your hotkey (default: ⌃⌥⇧⌘Y), speak, then press the hotkey again to stop

## Requirements

- macOS 15.2 or later
- OpenAI API key

## Privacy & Security

- API key stored in macOS Keychain (never on disk in plaintext)
- Audio processed through OpenAI's transcription API
- No audio stored locally after transcription
- Requires accessibility permission for text insertion

## Building from Source

```bash
git clone https://github.com/mblode/commandment.git
cd commandment
open Commandment.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -scheme Commandment -configuration Release build -derivedDataPath /tmp/commandment-build
```

## License

MIT License — see [LICENSE.txt](LICENSE.txt) for details.

## Author

Matthew Blode — [m@blode.co](mailto:m@blode.co)
