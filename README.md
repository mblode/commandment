<div align="center">

# [Commandment](https://blode.co/commandment)

**Voice dictation for macOS that types into whatever app you already have focused, on your own OpenAI key**

Hold a hotkey, say the thing you were going to type, and the transcript lands at your cursor.

</div>

## Install

```bash
brew install --cask mblode/tap/commandment
```

Or [download the latest release](https://github.com/mblode/commandment/releases/latest). Requires macOS 15 Sequoia or later and an [OpenAI API key](https://platform.openai.com/api-keys).

## Quickstart

Press `Option + Shift + D` to open Settings and paste your OpenAI key. It goes into the macOS Keychain.

Then hold `Option + D` anywhere, say a sentence, and let go. The text appears where you were typing.

## How it works

- **Streaming transcription:** audio is captured at 24 kHz mono and streamed to OpenAI's Realtime API, transcribed with `gpt-4o-mini-transcribe` by default.
- **Menu bar only:** Commandment runs as a menu bar agent, so there is no dock icon and no window.
- **Your key, your bill:** the key sits in the macOS Keychain and requests go straight to OpenAI, with nothing in between.
- **Accessibility is optional:** grant the permission and transcripts type themselves into the focused app. Skip it and they land on your clipboard instead.

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| `Option + D` | Start or stop recording |
| `Option + Shift + D` | Open Settings |

Both are rebindable in Settings.

## Development

The repository is a Turborepo with the macOS app in `apps/macos`, its tests in
`apps/macos-tests`, and the Next.js site in `apps/web`.

```bash
npm install
npm run web:dev
```

Run `npm run build` and `npm test` for the whole workspace, or use
`npm run macos:build`, `npm run macos:test`, and `npm run web:build` for one app.

## Notes

- Commandment updates itself through Sparkle, on EdDSA-signed appcasts, or on demand from **Check for Updates...** in the menu bar or Settings.
- If the menu bar icon is hidden behind an overflow app, `Option + Shift + D` still opens Settings.

## License

MIT

---

Crafted by [<img src="https://blode.co/avatar-circle.png" width="20" align="top" />](https://blode.co) [Matthew Blode](https://blode.co)
