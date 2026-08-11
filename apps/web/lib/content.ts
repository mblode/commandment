import { siteConfig } from "@/lib/config";

export const ANSWER_QUESTION = "What is Commandment?";

export const ANSWER_TEXT =
  "Commandment is a free macOS menu bar app for dictation. Hold Option+D, talk, then let go. Your words appear at the cursor in any app. It uses your OpenAI API key. There’s no Commandment account or subscription.";

export const ANSWER_NOTE = "Needs macOS 15.2 or later and an OpenAI API key.";

export const PAGE_UPDATED = "2026-08-11";
export const PAGE_UPDATED_LABEL = "11 August 2026";

export const HERO = {
  downloadNote: "Free and open source",
  headline: "Talk instead of typing.",
  requirement: "macOS 15.2+",
  shortcutLabel: "Hold ⌥D to talk",
  subhead:
    "Hold Option+D, talk, then let go. Your words appear wherever you’re typing.",
  utilityLabel: "Mac menu bar app",
} as const;

export const SOLUTION = {
  heading: "How does it work?",
  steps: [
    {
      body: "Use it in any app.",
      title: "Hold Option+D",
    },
    {
      body: "The menu bar icon lights up.",
      title: "Talk",
    },
    {
      body: "Your words appear at the cursor.",
      title: "Let go",
    },
  ],
} as const;

export const AUDIO_ROUTE = {
  accessibilityId: "accessibility",
  body: "Your recording goes straight from your Mac to OpenAI. Commandment keeps one temporary audio file and replaces it after every recording. Nothing goes through a Commandment server. If you skip Accessibility permission, your transcript is copied instead.",
  heading: "Where does the audio go?",
  id: "audio",
  stops: [
    { detail: "24 kHz audio", name: "Your mic" },
    { detail: "Temporary audio", name: "On your Mac" },
    { detail: "Your API key", name: "OpenAI" },
    { detail: "Or the clipboard", name: "Your cursor" },
  ],
} as const;

export const COMPARED_ON = "11 August 2026";

export const COMPARISON = {
  columns: ["Commandment", "Wispr Flow", "Superwhisper", "Apple Dictation"],
  heading: "How does it compare?",
  honesty:
    "If Apple Dictation works for you, keep it. It’s free and often works offline. MacWhisper and Superwhisper can keep audio on your Mac. Wispr Flow rewrites what you say; Commandment only transcribes it.",
  rows: [
    {
      label: "Price",
      values: [
        "Free app; pay OpenAI for usage",
        "Free plan, then subscription",
        "Free plan, subscription, or one-time purchase",
        "Included with macOS",
      ],
    },
    {
      label: "Account",
      values: ["None", "Required", "None", "None"],
    },
    {
      label: "Transcription",
      values: [
        "OpenAI, using your key",
        "Wispr Flow servers",
        "On your Mac or Superwhisper servers",
        "On your Mac for many languages",
      ],
    },
    {
      label: "Offline",
      values: [
        "No",
        "No",
        "Yes, with a local model",
        "Yes, for many languages",
      ],
    },
    {
      label: "Rewrites",
      values: ["No", "Yes", "Yes", "No"],
    },
    {
      label: "Source code",
      values: ["MIT on GitHub", "Closed", "Closed", "Closed"],
    },
  ],
} as const;

const REPO = siteConfig.links.github;

export const PROOF = {
  heading: "What’s included?",
  rows: [
    {
      detail: "MIT licensed.",
      href: `${REPO}/blob/main/LICENSE.md`,
      term: "Open source",
    },
    {
      detail: "Signed and notarised on every release.",
      href: `${REPO}/blob/main/.github/workflows`,
      term: "macOS",
    },
    {
      detail: "Stored in macOS Keychain.",
      href: `${REPO}/blob/main/apps/macos/KeychainManager.swift`,
      term: "API key",
    },
    {
      detail: "24 kHz audio sent to the OpenAI Realtime API.",
      href: `${REPO}/blob/main/apps/macos/RealtimeTranscriptionClient.swift`,
      term: "Audio",
    },
    {
      detail: "Option+D to record. Option+Shift+D for Settings.",
      href: `${REPO}/blob/main/apps/macos/HotkeyManager.swift`,
      term: "Shortcuts",
    },
    {
      detail: "macOS 15.2 or later. Apple silicon and Intel.",
      href: `${REPO}/releases/latest`,
      term: "Mac",
    },
  ],
} as const;

export const FAQ_HEADING = "Before you install";

export const CLOSING = {
  heading: "Try it on your Mac.",
  lede: "Free and open source. Add your OpenAI key and start talking.",
} as const;

export const BREW_COMMAND = "brew install --cask mblode/tap/commandment";
