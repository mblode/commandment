export const PAGE_UPDATED = "2026-08-21";

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
  columns: [
    "Commandment",
    "Apple Dictation",
    "Willow",
    "Superwhisper",
  ] as const,
  heading: "Commandment vs other Mac dictation",
  lede: "Apple Dictation is free and often works offline. Willow and Superwhisper are paid apps with their own transcription. Commandment types into any Mac app using your own OpenAI key.",
  rows: [
    {
      feature: "Types into",
      values: ["Any Mac app", "System dictation", "Any Mac app", "Any Mac app"],
    },
    {
      feature: "Who transcribes",
      values: [
        "Your OpenAI key",
        "Apple",
        "Their service",
        "Local or their service",
      ],
    },
    {
      feature: "Works offline",
      values: ["No", "Often", "No", "Local models can"],
    },
    {
      feature: "Cost",
      values: ["Free app, you pay OpenAI", "Free", "Paid", "Paid"],
    },
  ],
} as const;

export const CLOSING = {
  heading: "Try it on your Mac.",
  lede: "Free. No account. Add your OpenAI key and start talking.",
} as const;
