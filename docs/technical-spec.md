Technical spec (80/20) for a native macOS “AI dictation anywhere” app with BYO OpenAI API key.

Core concept and constraints
The app is a background-first macOS agent: global hotkey starts/stops capture, a small floating overlay gives state feedback, and the result is inserted into whatever app currently has focus. The app never needs to create an account. The user supplies their own OpenAI API key. By default, nothing leaves the machine except the audio/text sent directly to OpenAI using the user’s key, and optional model prompts the user enables (modes, formatting instructions, context capture).

Target platform and stack
Build as a native app in Swift. Use AppKit for the menu bar status item, global hotkeys, accessibility insertion, and floating panel behaviour; SwiftUI for settings, mode editor, history viewer. Persist local data with SQLite (via GRDB) or Core Data; Keychain for secrets. Ship as a notarised .dmg (or Sparkle for updates).

High-level architecture
Split into four processes/components (implemented as modules in one app bundle unless you later need an XPC split):

1. Agent/UI shell: menu bar item, overlay panel, settings window, history window.
2. Audio capture pipeline: microphone capture, buffering, optional VAD, file/stream encoder.
3. Transcription + post-processing: OpenAI requests, mode prompting, text normalisation, replacements.
4. Insertion engine: determines best way to place text into the focused app; falls back to clipboard with user-visible confirmation.

Runtime flow
When the user triggers dictation, the app captures audio from the selected input device, shows overlay state “Recording”, and continuously buffers audio in memory. When the user stops, the app finalises an audio segment (typically 16 kHz mono PCM), transitions overlay to “Processing”, sends the audio to OpenAI for transcription, then runs optional post-processing (mode transforms, punctuation rules, replacements). Finally, it attempts insertion into the previously focused element. If insertion is unsafe (focus lost/app changed/no editable target), it copies the final text to clipboard and shows “Copied to clipboard” with a “Paste” hint.

UI surfaces
Menu bar item shows current status (Idle/Recording/Processing/Error) and provides quick actions: Start/Stop, choose mode, open History, open Settings, quit. Overlay is a small non-activating floating panel near the bottom centre: waveform/level meter during capture, spinner during processing, short success toast after paste. Settings is a standard macOS window with a left sidebar: General (hotkeys, behaviour), Audio (mic selection, level test), OpenAI (API key, model selection, limits), Modes, Dictionary/Replacements, Privacy (context capture toggles, retention), History (storage limits). History shows recent dictations with raw transcript, final output, mode used, and “Copy/Re-run/Delete”.

Permissions and macOS entitlements
Microphone permission is required. Accessibility permission is required for reliable insertion in arbitrary apps. Screen recording permission is optional and only needed if you implement “screen context” capture. Apple Events/Automation permissions are optional; avoid if you can, because AX + pasteboard covers most use-cases.

Audio capture implementation
Use AVAudioEngine with an input node tap feeding a ring buffer. Keep capture low-latency and resilient to device changes. On stop, assemble buffered PCM into a WAV container (or whatever OpenAI accepts), or stream chunks if you implement streaming transcription. Add a basic VAD option later; 80/20 is manual start/stop with a configurable “auto-stop after silence” toggle as an enhancement.

OpenAI integration (BYO key)
Store the key in Keychain, never in UserDefaults or logs. The network layer should be a small, testable client that can call the OpenAI transcription endpoint with multipart audio upload and receive a transcript. Keep model choice abstract in the UI: “Fast / Balanced / Accurate” mapped to concrete model IDs in code, so you can update without changing UX. Provide a per-request cost guardrail: max audio seconds per dictation, and an optional daily cap that simply prevents sending (with a clear message).

Post-processing and modes
Treat post-processing as a pipeline. Start with deterministic steps: whitespace normalisation, punctuation heuristics, smart formatting for lists, dictionary replacements (exact and regex), and optional “remove filler words” toggle. Then a mode step can optionally call an OpenAI text model to rewrite the transcript according to the mode prompt (Email, Message, Note, Code, Custom). This keeps the system useful even if the user only wants transcription (no rewriting), and makes failures easier to debug.

Context capture (keep it simple)
80/20 context is selected text + clipboard. If the user enables it, capture currently selected text via Accessibility (AXSelectedText) where possible, and always capture the clipboard string at start/stop. Include that context in the mode prompt as bounded, clearly delimited sections. Screen context is a later phase: take a screenshot of the active window only when enabled, OCR locally if you must, then summarise; but this is complexity you can skip initially.

Insertion engine (the hard bit)
Implement a layered approach:

First choice: Accessibility set value on the focused element when it supports AXValue/AXSelectedTextRange editing. This can preserve cursor position and avoid clipboard disruption.
Second choice: simulate paste via NSPasteboard + synthetic Cmd+V, with “restore clipboard” enabled by default (save prior pasteboard contents, paste, then restore).
Third choice: if focus/app changed or element isn’t editable, put the text on clipboard and notify. Do not attempt to paste into a different app than the one focused at dictation start unless you can prove the caret is in an editable field.

Keep a “safety latch”: record the frontmost application PID and a token for the focused UI element at dictation start. If they don’t match at insertion time, do clipboard fallback unless the user explicitly enables “paste into current app even if changed”.

Local storage and retention
Store History locally with a simple schema: dictation id, timestamps, mode id, app bundle id/title at start, raw transcript, final output, insertion outcome, optional audio file path, error metadata. Default retention: 7 days or 500 items, whichever first; user configurable. Audio retention off by default; when enabled, store compressed audio files in Application Support and prune with the same policy. Provide “Delete all history” and “Export selected” (text only) from History.

Security, privacy, and logging
Never log transcripts or the API key. Redact network errors. Offer a “diagnostic mode” that logs only timings and error codes. Use ATS defaults. Consider certificate pinning as optional; for 80/20, rely on standard TLS.

Performance expectations
Keep perceived latency low by optimising UI state changes: show “Processing” immediately on stop, and paste as soon as transcript is ready. For longer recordings, show a progress indicator based on upload bytes sent (even if transcription itself is opaque). Ensure the app remains responsive by doing capture and network work off the main thread (actors or operation queues).

Error handling (minimum viable)
Handle these explicitly with user-facing copy: missing mic permission, missing accessibility permission, no API key set, network failure, OpenAI authentication failure, request too large, and insertion failure. Every error should end with the transcript copied to clipboard when available.

Configuration and defaults
Default hotkey: press-and-hold Fn (or a configurable single-modifier) for push-to-talk, and Option+Space for toggle/hands-free (avoid clashing with Spotlight). Default mode: “Message”. Default behaviour: restore clipboard, safe insertion (clipboard fallback if focus changes), store text history but not audio.

Phased build plan (engineering-focused)
Phase 1 (MVP): menu bar + overlay, hotkeys, AVAudioEngine capture, OpenAI transcription, clipboard paste with restore, settings for key/hotkeys/mic, basic history.
Phase 2: accessibility insertion (better than paste), modes with optional rewrite call, replacements/dictionary, safer focus tracking, export/delete controls.
Phase 3: file transcription import, optional silence auto-stop, optional context capture, polishing and app compatibility hardening.

If you want, I can turn this into an implementable task breakdown (repo structure, key classes/protocols, and a minimal DB schema) while keeping the same 80/20 approach.
