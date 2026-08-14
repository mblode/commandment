import { Agentation } from "agentation";
import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";
import { JsonLd } from "@/components/json-ld";
import {
  appId,
  breadcrumbId,
  breadcrumbSchema,
  orgId,
  personId,
  siteConfig,
  webPageId,
  websiteId,
} from "@/lib/config";
import { PAGE_UPDATED } from "@/lib/content";
import { getLatestRelease } from "@/lib/release";
import "./globals.css";

/**
 * Roman and italic are declared separately so only the roman is preloaded.
 *
 * `next/font` emits a `<link rel="preload">` for every face in a call, and
 * `preload` is a per-call option, not per-face. Declared together, the italic
 * was 105KB fetched at the highest priority to render zero glyphs — this page
 * contains no emphasis at all — while competing for the same connection as the
 * roman, which *is* the LCP font. Every LCP element on this fleet is text, so
 * that contention is not theoretical.
 *
 * Deleting the italic outright would have been simpler and is the wrong trade:
 * the browser then synthesises an oblique the first time anyone writes `<em>`,
 * and faked italic is exactly the kind of defect the house type rules exist to
 * stop. So it stays, real and drawn, one priority tier down — see the `em, i`
 * rule in globals.css that binds it.
 */
const glide = localFont({
  display: "swap",
  src: [{ path: "./fonts/glide-variable.woff2", style: "normal" }],
  variable: "--font-glide",
  weight: "100 950",
});
const glideItalic = localFont({
  display: "swap",
  preload: false,
  src: [{ path: "./fonts/glide-variable-italic.woff2", style: "italic" }],
  variable: "--font-glide-italic",
  weight: "100 950",
});

const glideMono = localFont({
  display: "swap",
  src: "./fonts/glide-mono.woff2",
  variable: "--font-glide-mono",
  weight: "400",
});

export const metadata: Metadata = {
  alternates: {
    canonical: siteConfig.url,
  },
  appleWebApp: {
    title: siteConfig.name,
  },
  authors: [{ name: siteConfig.author, url: siteConfig.links.author }],
  creator: siteConfig.author,
  description: siteConfig.description,
  metadataBase: new URL(siteConfig.url),
  openGraph: {
    description: siteConfig.description,
    locale: "en_US",
    // Every zone is a path on blode.co, so the site is the person. The product
    // name already has the og:title slot; repeating it here would spend the one
    // field in the card that could say who made the thing.
    siteName: siteConfig.author,
    title: siteConfig.title,
    type: "website",
    url: siteConfig.url,
  },
  robots: {
    follow: true,
    index: true,
  },
  title: {
    default: siteConfig.title,
    template: `%s | ${siteConfig.name}`,
  },
  twitter: {
    card: "summary_large_image",
    creator: "@mattblode",
    description: siteConfig.description,
    title: siteConfig.title,
  },
  verification: {
    google: "mFwyBIbXTaKK4uF_NA0MzVWFyY40hPgBjFObg3rje04",
  },
};

export const viewport: Viewport = {
  colorScheme: "light",
  themeColor: "#f2efe8",
};

/*
 * The Person and WebSite nodes are blode.co's and are referenced by `@id`, not
 * redefined here. See the note on the ids in `lib/config.ts`.
 */
/**
 * `featureList` is seven capabilities the app actually has, each of which is
 * demonstrable in the running binary. It is not a keyword list: a feature named
 * here that a reviewer cannot find is a markup error, not a marketing decision.
 */
const FEATURE_LIST = [
  "Dictate into any Mac app with Option+D",
  "Live transcription with OpenAI",
  "API key stored in macOS Keychain",
  "Type at the cursor or copy to the clipboard",
  "Menu bar app with no Dock icon",
  "Change the record and Settings shortcuts",
];

const structuredData = (version: string) => ({
  "@context": "https://schema.org",
  "@graph": [
    {
      "@id": webPageId,
      "@type": "WebPage",
      about: { "@id": appId },
      breadcrumb: { "@id": breadcrumbId },
      // Hand-maintained in lib/content.ts and shared with the visible <time> in
      // the closing section and with app/sitemap.ts. Deliberately not a build
      // clock: "changed on every deploy" is not a freshness signal.
      dateModified: PAGE_UPDATED,
      description: siteConfig.description,
      inLanguage: "en-AU",
      isPartOf: { "@id": websiteId },
      name: siteConfig.name,
      url: siteConfig.url,
    },
    {
      "@id": appId,
      "@type": "SoftwareApplication",
      // Was "DeveloperApplication". Commandment types into Slack, Notes and
      // Mail as readily as into an editor, so filing it as a developer tool
      // described the author's own use rather than the software.
      applicationCategory: "UtilitiesApplication",
      applicationSubCategory: "Dictation",
      author: { "@id": personId },
      description: siteConfig.description,
      downloadUrl: `${siteConfig.links.github}/releases/latest`,
      featureList: FEATURE_LIST,
      image: `${siteConfig.url}/opengraph-image`,
      isAccessibleForFree: true,
      isPartOf: { "@id": websiteId },
      license: `${siteConfig.links.github}/blob/main/LICENSE.md`,
      name: siteConfig.name,
      offers: {
        "@type": "Offer",
        availability: "https://schema.org/InStock",
        // Numeric 0 matches Google's SoftwareApplication example. String "0"
        // is schema.org-legal but Semrush Site Audit flags it as invalid markup.
        price: 0,
        priceCurrency: "USD",
        url: siteConfig.url,
      },
      operatingSystem: "macOS 15.2",
      publisher: { "@id": orgId },
      // Omitted rather than guessed when the GitHub API is unreachable. An
      // absent property is honest; a stale one is a claim.
      ...(version ? { softwareVersion: version } : {}),
      url: siteConfig.url,
    },
    breadcrumbSchema(),
  ],
});

/**
 * Async so the graph can publish the same `softwareVersion` the page renders.
 * `getLatestRelease` is one `fetch` shared with `app/page.tsx` — identical
 * arguments are deduplicated within a render pass and both read the same 3600s
 * cache entry, so this is not a second request.
 */
export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const { version } = await getLatestRelease();

  return (
    <html
      className={`${glide.variable} ${glideItalic.variable} ${glideMono.variable}`}
      lang="en-AU"
    >
      <head>
        <link href={process.env.NEXT_PUBLIC_POSTHOG_HOST} rel="preconnect" />
      </head>
      <body className="antialiased">
        <a
          className="fixed top-3 left-3 z-100 -translate-y-20 rounded-md bg-ink px-4 py-3 text-paper focus-visible:translate-y-0 focus-visible:outline-2 focus-visible:outline-signal focus-visible:outline-offset-2"
          href="#main-content"
        >
          Skip to content
        </a>
        {children}
        <JsonLd data={structuredData(version)} />
        {process.env.NODE_ENV === "development" && <Agentation />}
      </body>
    </html>
  );
}
