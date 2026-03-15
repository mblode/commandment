import type { Metadata } from "next";
import { Geist } from "next/font/google";
import { GoogleAnalytics } from "@next/third-parties/google";
import { Agentation } from "agentation";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
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
      <body className={`${geistSans.variable} antialiased`}>
        {children}
        {process.env.NODE_ENV === "development" && <Agentation />}
      </body>
      <GoogleAnalytics gaId="G-XMFQF7NCQZ" />
    </html>
  );
}
