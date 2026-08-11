import { describe, expect, it } from "vitest";

import { breadcrumbSchema } from "@/lib/config";
import { PAGE_UPDATED } from "@/lib/content";

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/u;

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
