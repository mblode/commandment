import { renderZoneOgImage } from "@/app/og-image-shared";
import { siteConfig } from "@/lib/config";

export {
  OG_CONTENT_TYPE as contentType,
  OG_SIZE as size,
} from "@/app/og-image-shared";

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
