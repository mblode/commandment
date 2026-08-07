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
    { path: "../public/glide-variable.woff2", style: "normal" },
    { path: "../public/glide-variable-italic.woff2", style: "italic" },
  ],
  variable: "--font-glide",
  weight: "400 900",
});

export const metadata: Metadata = {
  alternates: {
    canonical: siteConfig.url,
  },
  appleWebApp: {
    title: siteConfig.name,
  },
  description: siteConfig.description,
  metadataBase: new URL(siteConfig.url),
  openGraph: {
    description: siteConfig.description,
    locale: "en_US",
    siteName: siteConfig.name,
    title: siteConfig.title,
    type: "website",
    url: siteConfig.url,
  },
  robots: {
    follow: true,
    index: true,
  },
  title: siteConfig.title,
  twitter: {
    card: "summary_large_image",
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
      isPartOf: { "@id": websiteId },
      name: siteConfig.name,
      offers: {
        "@type": "Offer",
        price: "0",
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
    <html className="dark" lang="en">
      <head>
        <link href={process.env.NEXT_PUBLIC_POSTHOG_HOST} rel="preconnect" />
      </head>
      <body className={`${glide.variable} antialiased`}>
        {children}
        <JsonLd data={structuredData} />
        {process.env.NODE_ENV === "development" && <Agentation />}
      </body>
    </html>
  );
}
