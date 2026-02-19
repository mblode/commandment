<p align="center">
  <img src="commandment-macOS-Default-1024x1024@1x.png" width="128" alt="Commandment app icon">
</p>

<h1 align="center">Commandment</h1>

<p align="center">
  Voice dictation for macOS. Press a hotkey, speak, and your words are transcribed instantly.
</p>

<p align="center">
  <strong><a href="https://github.com/mblode/commandment/releases/latest">Download for macOS</a></strong>
  &nbsp;&middot;&nbsp;
  macOS 15.2+
  &nbsp;&middot;&nbsp;
  Free &amp; open source
</p>

Or install with Homebrew:

```bash
brew tap mblode/tap
brew install --cask commandment
```

## Features

- **Global hotkey** — hold to record, release to transcribe (default: Hyperkey+Y, configurable)
- **Fast transcription** — powered by OpenAI's gpt-4o-mini-transcribe model
- **Real-time streaming** — audio streams to OpenAI's Realtime API via WebSocket, with REST fallback
- **Auto-insert output** — transcripts paste directly into the focused app
- **Clipboard fallback** — if Accessibility isn't granted (or paste fails), transcript is copied to your clipboard
- **Secure** — API key stored in macOS Keychain, never written to disk in plaintext
- **Floating overlay** — shows recording, processing, and success states
- **Menu bar native** — lives in the menu bar with a color-coded status indicator
- **Guided setup checklist** — first-run steps with “Test now”, skip-for-now, and reset controls
- **Clipboard preservation** — restores your clipboard after text insertion
- **Clear permission guidance** — Accessibility is needed for direct insertion into other apps
- **Reliable** — automatic retry with exponential backoff on network failures
- **Signed and notarized** — code-signed and notarized by Apple for Gatekeeper

## Getting Started

1. Download the DMG from [Releases](https://github.com/mblode/commandment/releases/latest) and drag Commandment to Applications
2. Launch Commandment — a microphone icon appears in your menu bar
3. Follow the built-in **Quick setup** checklist (API key -> microphone -> optional auto-insert)
4. Use **Test now** on each step to verify setup quickly
5. (Optional) Skip setup steps and come back later from Settings > Setup
6. Hold your hotkey (default: ⌃⌥⇧⌘Y), speak, then release to transcribe. Commandment auto-inserts when Accessibility is enabled, and falls back to clipboard copy otherwise.

## Requirements

- macOS 15.2 or later
- [OpenAI API key](https://platform.openai.com/api-keys)

## Privacy & Security

- Your API key is stored in the macOS Keychain, never on disk in plaintext
- Audio is sent directly to OpenAI's API using your own key — no intermediary servers
- Temporary audio files are deleted after transcription
- Accessibility permission is required for direct auto-insert into other apps
- Microphone permission is required for audio capture

## Building from Source

Requires Xcode 16+ and macOS 15.2+ SDK.

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

MIT — see [LICENSE.md](LICENSE.md) for details.
