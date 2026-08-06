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
 */
export const personId = `${siteConfig.url}/#person`;
export const websiteId = `${siteConfig.url}/#website`;
export const appId = `${siteConfig.url}/#software`;
export const faqId = `${siteConfig.url}/#faq`;
