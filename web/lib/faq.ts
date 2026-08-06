import { faqId, siteConfig, websiteId } from "@/lib/config";

/**
 * One source for the FAQ, read by both the rendered accordion and the FAQPage
 * JSON-LD. Hand-writing the schema separately from the copy is how the two
 * drift apart, and the schema is the half nobody proofreads.
 */
export interface FaqEntry {
  answer: string;
  /** Shell command shown under the answer, and appended to the schema answer. */
  code?: string;
  /**
   * Anchor slug. Rendered as the `id` on the question's own `<details>`, so the
   * URL in `acceptedAnswer.url` lands on something that exists and is visible
   * without opening anything. Hand-written rather than derived from the
   * question, so rewording a question cannot silently break an inbound link.
   */
  id: string;
  question: string;
}

export const faq: FaqEntry[] = [
  {
    answer:
      "No. Paste an OpenAI API key into Settings and you pay OpenAI for the seconds you actually dictate, rather than a monthly fee to have it sit idle. The key goes into the macOS Keychain.",
    id: "subscription",
    question: "Do I need a subscription?",
  },
  {
    answer:
      "Audio is captured at 24 kHz mono and streamed to the OpenAI Realtime API on your own key, transcribed by gpt-4o-mini-transcribe. One temporary WAV sits in the system temp directory and is overwritten on the next take. Nothing else receives it.",
    id: "audio",
    question: "Where does my audio go?",
  },
  {
    answer:
      "Typing into another app is the one thing macOS puts behind Accessibility, and that is how transcripts reach your cursor. Skip the prompt and nothing breaks: the transcript goes to your clipboard and you paste it yourself.",
    id: "accessibility",
    question: "Why does it need Accessibility permission?",
  },
  {
    answer:
      "No window and no dock icon. It runs as a menu bar agent, so the only time you see it is when you go looking for it.",
    id: "menu-bar",
    question: "Is there a window to manage?",
  },
  {
    answer:
      "Option+D starts and stops recording. Option+Shift+D opens Settings. Both rebind in Settings.",
    id: "shortcuts",
    question: "What are the shortcuts?",
  },
  {
    answer:
      "Download the DMG from the latest GitHub release, or install from the Homebrew tap. Requires macOS 15.2 or later.",
    code: "brew install --cask mblode/tap/commandment",
    id: "install",
    question: "How do I install it?",
  },
];

const anchor = (entry: FaqEntry) => `${siteConfig.url}#${entry.id}`;

/**
 * A single FAQPage node for the layout's `@graph`. One per page is the limit,
 * and `isPartOf` is what ties it to the WebSite rather than leaving it as a
 * disconnected snippet.
 */
export const faqSchema = () => ({
  "@id": faqId,
  "@type": "FAQPage",
  inLanguage: "en",
  isPartOf: { "@id": websiteId },
  mainEntity: faq.map((entry) => ({
    "@id": anchor(entry),
    "@type": "Question",
    acceptedAnswer: {
      "@type": "Answer",
      text: entry.code ? `${entry.answer} ${entry.code}` : entry.answer,
      url: anchor(entry),
    },
    name: entry.question,
  })),
  name: `${siteConfig.name} questions`,
  url: siteConfig.url,
});
