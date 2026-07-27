import type { Metadata } from "next";
import localFont from "next/font/local";
import { Agentation } from "agentation";
import "./globals.css";

const glide = localFont({
  src: [
    { path: "../public/glide-variable.woff2", style: "normal" },
    { path: "../public/glide-variable-italic.woff2", style: "italic" },
  ],
  variable: "--font-glide",
  weight: "400 900",
  display: "swap",
});

const title = "Commandment — Voice to Text for macOS, No Subscription";
const description =
  "Commandment turns your voice into text instantly on macOS. Press a shortcut, speak, and paste anywhere — bring your own OpenAI API key, no subscription.";
const siteUrl = "https://blode.co/commandment";

export const metadata: Metadata = {
  title,
  description,
  metadataBase: new URL("https://blode.co"),
  alternates: {
    canonical: siteUrl,
  },
  verification: {
    google: "mFwyBIbXTaKK4uF_NA0MzVWFyY40hPgBjFObg3rje04",
  },
  openGraph: {
    type: "website",
    url: siteUrl,
    title,
    description,
    siteName: "Commandment",
    images: [
      {
        url: "/commandment/app-icon.png",
        width: 512,
        height: 512,
        alt: "Commandment app icon",
      },
    ],
  },
  twitter: {
    card: "summary",
    title,
    description,
    images: ["/commandment/app-icon.png"],
  },
  appleWebApp: {
    title: "Commandment",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link href="https://us.i.posthog.com" rel="preconnect" />
        <link href="https://us-assets.i.posthog.com" rel="dns-prefetch" />
      </head>
      <body className={`${glide.variable} antialiased`}>
        {children}
        {process.env.NODE_ENV === "development" && <Agentation />}
      </body>
    </html>
  );
}
