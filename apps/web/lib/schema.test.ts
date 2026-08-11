import { describe, expect, it } from "vitest";

import { breadcrumbSchema } from "@/lib/config";

/**
 * Structural rules for the `@graph`, each of which has broken somewhere in this
 * fleet before.
 *
 * The last one is the important one. Every zone under blode.co is a path behind
 * a rewrite, not a site of its own, so a `blode.co/commandment/#person` node
 * publishes a second Matthew Blode on the same domain and splits the entity that
 * every other zone is pointing at. The fleet auditor catches it after deploy;
 * this catches it before commit, which is several hours earlier and free.
 */

/** Rebuilt here rather than imported, because the graph in `app/layout.tsx` is a
 * module-private constant. Keep the node list in step with that file — a node
 * added there and not here is simply untested, which is the failure mode this
 * comment exists to make visible. */
const graph = [breadcrumbSchema()];

const ZONE_ENTITY_REDEFINITION =
  /^https:\/\/blode\.co\/commandment\/?#(person|website|organization)$/u;

const ids = (nodes: readonly { "@id"?: string }[]) =>
  nodes.map((node) => node["@id"]).filter(Boolean) as string[];

describe("the graph", () => {
  it("gives every node a unique @id", () => {
    const seen = ids(graph);
    expect(new Set(seen).size).toBe(seen.length);
  });

  it("never redefines a blode.co entity inside the zone", () => {
    // Person, WebSite and Organization belong to blode.co and are referenced by
    // @id from here, never declared. A zone-local copy of any of them forks the
    // entity across 33 sites.
    for (const id of ids(graph)) {
      expect(id, `${id} redefines a blode.co-level entity`).not.toMatch(
        ZONE_ENTITY_REDEFINITION
      );
    }
  });

  it("keeps zone-local ids inside the zone", () => {
    for (const id of ids(graph)) {
      expect(id.startsWith("https://blode.co/commandment")).toBe(true);
    }
  });
});

describe("the BreadcrumbList", () => {
  it("resolves its trail to real blode.co URLs", () => {
    for (const item of breadcrumbSchema().itemListElement) {
      expect(item.item.startsWith("https://blode.co")).toBe(true);
    }
  });
});
