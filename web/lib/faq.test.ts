import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import { FaqSection } from "@/components/faq-section";
import { faq, faqSchema } from "@/lib/faq";

/**
 * The FAQ and the FAQPage node must say the same thing.
 *
 * The failure this prevents: someone improves an answer in `lib/faq.ts` and the
 * rendered copy moves while `acceptedAnswer.text` does not, or an answer is
 * rendered behind something a crawler never opens. Google calls markup that
 * asserts an answer the reader cannot see a mismatch, and the penalty is that
 * the whole node stops being trusted — including the entries that were fine.
 *
 * That is not hypothetical for this page. It shipped for months as a native
 * `<details>` accordion, and the previous component carried a docblock
 * recording that Blode UI's Accordion had already been rejected because its
 * panel content does not survive server rendering at all. This test is the
 * mechanism that would have caught that without anyone reading the HTML.
 */

const CLAUSE_END = /[.,;]/u;
const PAGE_ANCHOR = /^https:\/\/blode\.co\/commandment#[a-z-]+$/u;

const html = renderToStaticMarkup(FaqSection());
const schema = faqSchema();

describe("every FAQ answer", () => {
  it("is in the server-rendered markup, not behind a disclosure", () => {
    for (const entry of faq) {
      // The first clause of each answer, which is enough to prove the text was
      // rendered and short enough to avoid the entity-encoding of apostrophes.
      const [opening] = entry.answer.split(CLAUSE_END);
      expect(
        html,
        `answer for "${entry.question}" is missing from server markup`
      ).toContain(opening);
    }
  });

  it("matches the text the graph publishes", () => {
    for (const entry of faq) {
      const question = schema.mainEntity.find((q) => q.name === entry.question);
      expect(question, `no schema entry for "${entry.question}"`).toBeDefined();
      const expected = entry.code
        ? `${entry.answer} ${entry.code}`
        : entry.answer;
      expect(question?.acceptedAnswer.text).toBe(expected);
    }
  });
});

describe("every FAQ question", () => {
  it("is rendered as a heading with the anchor the graph points at", () => {
    for (const entry of faq) {
      expect(html).toContain(entry.question);
      // `acceptedAnswer.url` is built from this id. If the heading loses it, the
      // graph points at an anchor that resolves to nothing on the page.
      expect(
        html,
        `heading for "${entry.question}" lost its id="${entry.id}"`
      ).toContain(`id="${entry.id}"`);
    }
  });

  it("has a unique anchor", () => {
    const ids = faq.map((entry) => entry.id);
    expect(new Set(ids).size).toBe(ids.length);
  });
});

describe("the FAQPage node", () => {
  it("covers every rendered entry and nothing else", () => {
    expect(schema.mainEntity).toHaveLength(faq.length);
  });

  it("points every acceptedAnswer at an anchor on this page", () => {
    for (const question of schema.mainEntity) {
      expect(question.acceptedAnswer.url).toMatch(PAGE_ANCHOR);
    }
  });
});
