import { Agentation } from "agentation";
import type { Metadata } from "next";
import localFont from "next/font/local";
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

const title = "Commandment: Voice to Text for macOS, No Subscription";
const description =
  "Commandment turns your voice into text instantly on macOS. Press a shortcut, speak, and paste anywhere. Bring your own OpenAI API key, no subscription.";
const siteUrl = "https://blode.co/commandment";

export const metadata: Metadata = {
  alternates: {
    canonical: siteUrl,
  },
  appleWebApp: {
    title: "Commandment",
  },
  description,
  metadataBase: new URL("https://blode.co"),
  openGraph: {
    description,
    images: [
      {
        alt: "Commandment app icon",
        height: 512,
        url: "/commandment/app-icon.png",
        width: 512,
      },
    ],
    siteName: "Commandment",
    title,
    type: "website",
    url: siteUrl,
  },
  title,
  twitter: {
    card: "summary",
    description,
    images: ["/commandment/app-icon.png"],
    title,
  },
  verification: {
    google: "mFwyBIbXTaKK4uF_NA0MzVWFyY40hPgBjFObg3rje04",
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
        <link href={process.env.NEXT_PUBLIC_POSTHOG_HOST} rel="preconnect" />
      </head>
      <body className={`${glide.variable} antialiased`}>
        {children}
        {process.env.NODE_ENV === "development" && <Agentation />}
      </body>
    </html>
  );
}
