import {
  OG_CONTENT_TYPE,
  OG_SIZE,
  renderZoneOgImage,
} from "@/app/og-image-shared";
import { siteConfig } from "@/lib/config";

export const contentType = OG_CONTENT_TYPE;
export const size = OG_SIZE;

export const alt = "Commandment: voice to text for macOS";

/**
 * The house card (Rule 12), replacing the bespoke dark ImageResponse.
 */
export default function OpengraphImage() {
  return renderZoneOgImage({
    badge: "COMMANDMENT",
    eyebrow: "blode.co/commandment",
    subtitle: "Voice to text, instantly.",
    title: siteConfig.name,
  });
}
