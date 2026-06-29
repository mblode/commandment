import type { Metadata } from "next";
import localFont from "next/font/local";
import { GoogleAnalytics } from "@next/third-parties/google";
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

export const metadata: Metadata = {
  title,
  description,
  metadataBase: new URL("https://commandment.blode.co"),
  alternates: {
    canonical: "/",
  },
  verification: {
    google: "mFwyBIbXTaKK4uF_NA0MzVWFyY40hPgBjFObg3rje04",
  },
  openGraph: {
    type: "website",
    url: "https://commandment.blode.co",
    title,
    description,
    siteName: "Commandment",
    images: [
      {
        url: "/app-icon.png",
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
    images: ["/app-icon.png"],
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
      <body className={`${glide.variable} antialiased`}>
        {children}
        {process.env.NODE_ENV === "development" && <Agentation />}
      </body>
      <GoogleAnalytics gaId="G-XMFQF7NCQZ" />
    </html>
  );
}
