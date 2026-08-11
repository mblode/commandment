import { DownloadButton } from "@/components/marketing/download-button";
import { Container, Section } from "@/components/ui/section";
import { CLOSING } from "@/lib/content";

export const ClosingCta = ({ downloadUrl }: { downloadUrl: string }) => (
  <Section className="border-ink/15 border-t bg-paper">
    <Container>
      <h2 className="max-w-[12ch] text-balance font-medium text-6xl text-ink leading-[0.92] tracking-[-0.055em] sm:text-8xl">
        {CLOSING.heading}
      </h2>
      <p className="mt-8 max-w-[42ch] text-pretty text-ink-muted text-xl sm:text-2xl">
        {CLOSING.lede}
      </p>

      <div className="mt-10">
        <DownloadButton href={downloadUrl} tone="secondary" />
      </div>
    </Container>
  </Section>
);
