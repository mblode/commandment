import { FaqSection } from "@/components/faq-section";
import { AnswerBlock } from "@/components/marketing/answer-block";
import { ClosingCta } from "@/components/marketing/closing-cta";
import { ComparisonTable } from "@/components/marketing/comparison-table";
import { FactList } from "@/components/marketing/fact-list";
import { Hero } from "@/components/marketing/hero";
import { HowItWorks } from "@/components/marketing/how-it-works";
import { ProseSection } from "@/components/marketing/prose-section";
import { SiteFooter } from "@/components/site-footer";
import { Container } from "@/components/ui/section";
import { ZoneBreadcrumb } from "@/components/zone-breadcrumb";
import { AUDIO_ROUTE, HERO, PROOF } from "@/lib/content";
import { getLatestRelease } from "@/lib/release";

export default async function Page() {
  const { downloadUrl, fileSizeMB, version } = await getLatestRelease();

  return (
    <div className="isolate flex min-h-dvh flex-col bg-canvas font-sans">
      <header className="material-header sticky top-0 z-50 bg-canvas/78 backdrop-blur-xl backdrop-saturate-150">
        <Container className="flex h-16 items-center justify-between gap-6">
          <ZoneBreadcrumb product="Commandment" />
          <p className="hidden font-mono text-ink-subtle text-sm sm:block">
            {HERO.shortcutLabel}
          </p>
        </Container>
      </header>

      <main className="flex-1" id="main-content">
        <Hero
          downloadUrl={downloadUrl}
          fileSizeMB={fileSizeMB}
          version={version}
        />

        <AnswerBlock />
        <HowItWorks />
        <ProseSection
          body={AUDIO_ROUTE.body}
          heading={AUDIO_ROUTE.heading}
          id={AUDIO_ROUTE.id}
          secondaryId={AUDIO_ROUTE.accessibilityId}
        />
        <FactList facts={PROOF.rows} heading={PROOF.heading} id="proof" />
        <ComparisonTable />
        <FaqSection />
        <ClosingCta downloadUrl={downloadUrl} version={version} />
      </main>

      <SiteFooter version={version} />
    </div>
  );
}
