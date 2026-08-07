export const siteConfig = {
  author: "Matthew Blode",
  description:
    "Commandment turns your voice into text instantly on macOS. Press a shortcut, speak, and the transcript lands at your cursor. Bring your own OpenAI API key, no subscription.",
  links: {
    author: "https://blode.co",
    github: "https://github.com/mblode/commandment",
  },
  name: "Commandment",
  title: "Commandment | Voice to text for macOS, no subscription",
  url: "https://blode.co/commandment",
} as const;

/**
 * Stable schema.org node ids. Each entity is defined once in the root layout's
 * `@graph` and referenced by `@id` from anywhere else, so crawlers resolve one
 * graph instead of several disconnected snippets.
 *
 * The Person, WebSite and Organization ids belong to blode.co and are only ever
 * referenced here, never redefined. blode.co/commandment is a path on blode.co
 * behind a rewrite, not a site of its own: a `blode.co/commandment/#person`
 * would publish a second Matthew Blode on the same domain and split the entity.
 * Contract: blode-co/apps/web/.claude/knowledge/zone-conventions.md
 */
const host = "https://blode.co";

export const personId = `${host}/#person`;
export const websiteId = `${host}/#website`;
export const orgId = `${host}/#organization`;

// Zone-local nodes keep the zone in the id.
export const appId = `${siteConfig.url}/#software`;
export const faqId = `${siteConfig.url}/#faq`;
export const webPageId = `${siteConfig.url}/#webpage`;
export const breadcrumbId = `${siteConfig.url}/#breadcrumb`;

export const breadcrumbSchema = () => ({
  "@id": breadcrumbId,
  "@type": "BreadcrumbList",
  itemListElement: [
    { "@type": "ListItem", item: `${host}/`, name: "Home", position: 1 },
    {
      "@type": "ListItem",
      item: `${host}/projects`,
      name: "Projects",
      position: 2,
    },
    {
      "@type": "ListItem",
      item: siteConfig.url,
      name: siteConfig.name,
      position: 3,
    },
  ],
});
