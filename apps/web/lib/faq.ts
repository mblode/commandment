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

/** Only the two unresolved install objections. Everything else is answered by
 * the hero, comparison, audio route, or footer. */
export const faq: FaqEntry[] = [
  {
    // Deliberately no rate. OpenAI's per-minute price for this model changes,
    // and a number typed here becomes wrong silently.
    answer:
      "No. Add your OpenAI API key in Settings. You pay OpenAI for usage. Commandment is free.",
    id: "subscription",
    question: "Do I need a subscription?",
  },
  {
    answer:
      "In macOS Keychain. It stays there until you delete it. Requests go straight from your Mac to OpenAI.",
    id: "key-safety",
    question: "Where is my API key stored?",
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
  inLanguage: "en-AU",
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
