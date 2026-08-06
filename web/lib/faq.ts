/**
 * One source for the FAQ, read by both the rendered disclosure and the
 * FAQPage JSON-LD. Hand-writing the schema separately from the copy is how the
 * two drift apart, and the schema is the half nobody proofreads.
 */
export interface FaqEntry {
  answer: string;
  /** Shell command shown under the answer, and appended to the schema answer. */
  code?: string;
  question: string;
}

export const faq: FaqEntry[] = [
  {
    answer:
      "No. Paste an OpenAI API key into Settings and you pay OpenAI for the seconds you actually dictate, rather than a monthly fee to have it sit idle. The key goes into the macOS Keychain.",
    question: "Do I need a subscription?",
  },
  {
    answer:
      "Audio is captured at 24 kHz mono and streamed to the OpenAI Realtime API on your own key, transcribed by gpt-4o-mini-transcribe. One temporary WAV sits in the system temp directory and is overwritten on the next take. Nothing else receives it.",
    question: "Where does my audio go?",
  },
  {
    answer:
      "Typing into another app is the one thing macOS puts behind Accessibility, and that is how transcripts reach your cursor. Skip the prompt and nothing breaks: the transcript goes to your clipboard and you paste it yourself.",
    question: "Why does it need Accessibility permission?",
  },
  {
    answer:
      "No window and no dock icon. It runs as a menu bar agent, so the only time you see it is when you go looking for it.",
    question: "Is there a window to manage?",
  },
  {
    answer:
      "Option+D starts and stops recording. Option+Shift+D opens Settings. Both rebind in Settings.",
    question: "What are the shortcuts?",
  },
  {
    answer:
      "Download the DMG from the latest GitHub release, or install from the Homebrew tap. Requires macOS 15.2 or later.",
    code: "brew install --cask mblode/tap/commandment",
    question: "How do I install it?",
  },
];

export const faqSchema = (id: string) => ({
  "@id": id,
  "@type": "FAQPage",
  mainEntity: faq.map((entry) => ({
    "@type": "Question",
    acceptedAnswer: {
      "@type": "Answer",
      text: entry.code ? `${entry.answer} ${entry.code}` : entry.answer,
    },
    name: entry.question,
  })),
});
