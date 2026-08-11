export const PAGE_UPDATED = "2026-08-11";

export const HERO = {
  downloadNote: "Free · No subscription",
  headline: "Talk instead of typing.",
  requirement: "macOS 15.2+",
  subhead:
    "Hold Option+D, talk, then let go. Your words appear wherever you’re typing.",
  trustLabel: "Signed and notarised",
} as const;

export const AUDIO_ROUTE = {
  heading: "Where does the audio go?",
  id: "audio",
  points: [
    "Audio goes straight from your Mac to OpenAI.",
    "Your API key is stored in Keychain.",
    "Nothing passes through a Commandment server.",
  ],
} as const;

export const COMPARISON = {
  body: "Apple Dictation is free and often works offline. Commandment is for dictation in any app using your own OpenAI key.",
  heading: "Why Commandment?",
} as const;

export const CLOSING = {
  heading: "Try it on your Mac.",
  lede: "Free. No account. Add your OpenAI key and start talking.",
} as const;
