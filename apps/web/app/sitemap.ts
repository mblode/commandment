import type { MetadataRoute } from "next";
import { siteConfig } from "@/lib/config";
import { PAGE_UPDATED } from "@/lib/content";

/**
 * `lastModified` is the hand-maintained `PAGE_UPDATED` constant, not
 * `new Date()`.
 *
 * A build clock claims the page changed at every deploy, including deploys that
 * only moved a class name. That is a freshness signal that carries no
 * information, and a crawler that learns the date always changes stops treating
 * it as meaning anything. The same constant feeds the visible `<time>` in the
 * closing section and `WebPage.dateModified` in the graph, so the three can
 * never disagree.
 */
export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      changeFrequency: "weekly",
      lastModified: PAGE_UPDATED,
      priority: 1,
      url: siteConfig.url,
    },
  ];
}
