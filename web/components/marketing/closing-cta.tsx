import { DownloadButton } from "@/components/marketing/download-button";
import { Reveal } from "@/components/ui/reveal";
import { Container, Section } from "@/components/ui/section";
import {
  BREW_COMMAND,
  CLOSING,
  PAGE_UPDATED,
  PAGE_UPDATED_LABEL,
} from "@/lib/content";

/**
 * The last thing on the page, and the same action as the first thing.
 *
 * One button, the same words as the hero. A reader who has got this far has read
 * the comparison and the FAQ; offering them a second, different next step here
 * is asking them to make the decision again.
 *
 * The `<time>` is the visible half of a freshness signal whose other half is
 * `WebPage.dateModified`. Both read `PAGE_UPDATED` from `lib/content.ts`, as does
 * `app/sitemap.ts`, so the date a reader sees and the date a crawler is told
 * cannot drift apart.
 */
export const ClosingCta = ({
  downloadUrl,
  version,
}: {
  downloadUrl: string;
  version: string;
}) => (
  <Section className="border-white/5 border-t">
    <Container>
      <Reveal>
        <h2 className="max-w-[24ch] text-balance font-semibold text-3xl text-ink tracking-tight">
          {CLOSING.heading}
        </h2>
        <p className="mt-4 max-w-[50ch] text-pretty text-ink-muted text-lg">
          {CLOSING.lede}
        </p>

        <div className="mt-8">
          <DownloadButton href={downloadUrl} />
        </div>

        <code className="mt-4 block max-w-full overflow-x-auto whitespace-pre rounded-lg bg-surface-1 px-3 py-2 text-left font-mono text-ink-muted text-sm">
          {BREW_COMMAND}
        </code>

        <p className="mt-6 text-ink-faint text-sm">
          {version ? `${version} · ` : ""}Requires macOS 15.2 · Last updated{" "}
          <time dateTime={PAGE_UPDATED}>{PAGE_UPDATED_LABEL}</time>
        </p>
      </Reveal>
    </Container>
  </Section>
);
