import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import { AnswerBlock } from "@/components/marketing/answer-block";
import { breadcrumbSchema } from "@/lib/config";
import { ANSWER_TEXT, PAGE_UPDATED } from "@/lib/content";

/**
 * The contracts that hold this page together, each one guarding a failure that
 * is invisible by inspection.
 *
 * Everything here asserts against `renderToStaticMarkup` output rather than a
 * hydrated tree, on purpose. Server markup is what a crawler, an answer engine
 * and a reader with JS disabled actually receive. A test that passes against a
 * hydrated DOM will happily approve content none of those three can see, which
 * is precisely the class of bug these exist to catch.
 */

const WHITESPACE = /\s+/u;
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/u;

const words = (text: string) => text.split(WHITESPACE).filter(Boolean).length;

describe("the answer block", () => {
  /**
   * 40-60 words. Under 40 and the paragraph has dropped the qualifier that made
   * it true; over 60 and an answer engine truncates it mid-clause, which quotes
   * you saying half of something.
   *
   * This is a real band, not a style preference — it is the reason the copy
   * lives in `lib/content.ts` as a constant instead of inline in JSX, because a
   * string in JSX cannot be counted by anything.
   */
  it("stays inside the 40-60 word band", () => {
    expect(words(ANSWER_TEXT)).toBeGreaterThanOrEqual(40);
    expect(words(ANSWER_TEXT)).toBeLessThanOrEqual(60);
  });

  /** It must survive with nothing around it: an answer engine lifts the
   * paragraph alone, so a leading "It" or "The app" refers to a headline the
   * quote does not include. */
  it("opens with the product name rather than a pronoun", () => {
    expect(ANSWER_TEXT.startsWith("Commandment")).toBe(true);
  });

  it("is present in the server-rendered markup", () => {
    const html = renderToStaticMarkup(AnswerBlock());
    // Apostrophes are entity-encoded on the way out, so compare on a stretch
    // that has none rather than escaping the whole paragraph.
    expect(html).toContain("Commandment is a free macOS menu bar app");
    expect(html).toContain("You pay OpenAI for the seconds you dictate.");
  });
});

describe("PAGE_UPDATED", () => {
  it("is a valid ISO date", () => {
    expect(PAGE_UPDATED).toMatch(ISO_DATE);
    expect(Number.isNaN(Date.parse(PAGE_UPDATED))).toBe(false);
  });

  /** A last-updated stamp in the future is worse than none: it is the one thing
   * on the page a reader can prove is wrong without leaving it. */
  it("is not in the future", () => {
    expect(Date.parse(PAGE_UPDATED)).toBeLessThanOrEqual(Date.now());
  });
});

describe("the breadcrumb", () => {
  /**
   * The visible trail and the BreadcrumbList must read the same words in the
   * same order — Google treats a mismatch as a markup error, and the two live in
   * different files, so nothing but this notices when one is edited.
   *
   * `ZoneBreadcrumb` is shared byte-for-byte across the fleet and renders these
   * three names; the assertion is on the schema half, which is the half that
   * changes when a product is renamed.
   */
  it("names Matthew Blode, Projects, then the product, in order", () => {
    const names = breadcrumbSchema().itemListElement.map((item) => item.name);
    expect(names).toEqual(["Matthew Blode", "Projects", "Commandment"]);
  });

  it("numbers its positions from one, without gaps", () => {
    const positions = breadcrumbSchema().itemListElement.map(
      (item) => item.position
    );
    expect(positions).toEqual([1, 2, 3]);
  });
});
