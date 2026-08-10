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
import { faqSchema } from "@/lib/faq";
import "./globals.css";

const glide = localFont({
  display: "swap",
  src: [
    { path: "./fonts/glide-variable.woff2", style: "normal" },
    { path: "./fonts/glide-variable-italic.woff2", style: "italic" },
  ],
  variable: "--font-glide",
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
  colorScheme: "dark",
  themeColor: "#1c1c1e",
};

/*
 * The Person and WebSite nodes are blode.co's and are referenced by `@id`, not
 * redefined here. See the note on the ids in `lib/config.ts`.
 */
const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@id": webPageId,
      "@type": "WebPage",
      about: { "@id": appId },
      breadcrumb: { "@id": breadcrumbId },
      description: siteConfig.description,
      inLanguage: "en-US",
      isPartOf: { "@id": websiteId },
      name: siteConfig.name,
      url: siteConfig.url,
    },
    {
      "@id": appId,
      "@type": "SoftwareApplication",
      applicationCategory: "DeveloperApplication",
      author: { "@id": personId },
      description: siteConfig.description,
      downloadUrl: `${siteConfig.links.github}/releases/latest`,
      image: `${siteConfig.url}/opengraph-image`,
      isAccessibleForFree: true,
      isPartOf: { "@id": websiteId },
      name: siteConfig.name,
      offers: {
        "@type": "Offer",
        availability: "https://schema.org/InStock",
        // Numeric 0 matches Google's SoftwareApplication example. String "0"
        // is schema.org-legal but Semrush Site Audit flags it as invalid markup.
        price: 0,
        priceCurrency: "USD",
      },
      operatingSystem: "macOS 15.2",
      publisher: { "@id": orgId },
      url: siteConfig.url,
    },
    breadcrumbSchema(),
    faqSchema(),
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html className={`dark ${glide.variable} ${glideMono.variable}`} lang="en">
      <head>
        <link href={process.env.NEXT_PUBLIC_POSTHOG_HOST} rel="preconnect" />
      </head>
      <body className="antialiased">
        {children}
        <JsonLd data={structuredData} />
        {process.env.NODE_ENV === "development" && <Agentation />}
      </body>
    </html>
  );
}
