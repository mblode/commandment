import { DownloadButton } from "@/components/marketing/download-button";
import { Reveal } from "@/components/ui/reveal";
import { Container, Section } from "@/components/ui/section";
import {
  BREW_COMMAND,
  CLOSING,
  PAGE_UPDATED,
  PAGE_UPDATED_LABEL,
} from "@/lib/content";

export const ClosingCta = ({
  downloadUrl,
  version,
}: {
  downloadUrl: string;
  version: string;
}) => (
  <Section className="border-ink/15 border-t bg-paper">
    <Container>
      <Reveal>
        <h2 className="max-w-[12ch] text-balance font-medium text-6xl text-ink leading-[0.92] tracking-[-0.055em] sm:text-8xl">
          {CLOSING.heading}
        </h2>
        <p className="mt-8 max-w-[42ch] text-pretty text-ink-muted text-xl sm:text-2xl">
          {CLOSING.lede}
        </p>

        <div className="mt-10">
          <DownloadButton href={downloadUrl} tone="secondary" />
        </div>

        <div className="mt-14 flex flex-col gap-4 border-ink/15 border-t pt-5 font-mono text-ink-subtle text-sm sm:flex-row sm:items-center sm:justify-between">
          <code className="max-w-full break-all">{BREW_COMMAND}</code>
          <p className="tabular-nums">
            {version ? `${version} · ` : ""}macOS 15.2+ · Updated{" "}
            <time dateTime={PAGE_UPDATED}>{PAGE_UPDATED_LABEL}</time>
          </p>
        </div>
      </Reveal>
    </Container>
  </Section>
);
