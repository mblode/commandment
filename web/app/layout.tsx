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

export const metadata: Metadata = {
  title: "Commandment",
  description:
    "Voice to text, instantly. BYO OpenAI API key — no subscription required.",
  metadataBase: new URL("https://commandment.blode.co"),
  verification: {
    google: "mFwyBIbXTaKK4uF_NA0MzVWFyY40hPgBjFObg3rje04",
  },
  openGraph: {
    title: "Commandment",
    description:
      "Voice to text, instantly. BYO OpenAI API key — no subscription required.",
    siteName: "Commandment",
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
