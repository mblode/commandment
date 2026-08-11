import { FaqSection } from "@/components/faq-section";
import { AnswerBlock } from "@/components/marketing/answer-block";
import { ClosingCta } from "@/components/marketing/closing-cta";
import { ComparisonTable } from "@/components/marketing/comparison-table";
import { FactList } from "@/components/marketing/fact-list";
import { Hero } from "@/components/marketing/hero";
import { HowItWorks } from "@/components/marketing/how-it-works";
import { ProseSection } from "@/components/marketing/prose-section";
import { SiteFooter } from "@/components/site-footer";
import { EdgeBlur } from "@/components/ui/edge-blur";
import { Container } from "@/components/ui/section";
import { ZoneBreadcrumb } from "@/components/zone-breadcrumb";
import { AUDIO_ROUTE, HERO, PROOF } from "@/lib/content";
import { getLatestRelease } from "@/lib/release";

/**
 * Section order, and why it is this order.
 *
 * Claim, then the answer to "what is this", then how it works,
 * then the section holding both things that stop an install, then the
 * comparison, then proof, then the questions, then the ask. Proof sits *before*
 * the closing CTA rather than after it: a reader who has already decided does
 * not need it,
 * and a reader who has not will never see it below the button.
 *
 * Every `h2` on this page is a question somebody would type into a search box.
 * That is not a stylistic preference — it is what lets an answer engine lift a
 * self-contained answer from a section instead of guessing what the section was
 * about from a noun phrase.
 */
export default async function Page() {
  const { downloadUrl, fileSizeMB, version } = await getLatestRelease();

  return (
    <div className="paper-field isolate flex min-h-dvh flex-col bg-canvas font-sans">
      <header className="material-header sticky top-0 z-50 bg-canvas/78 backdrop-blur-xl backdrop-saturate-150">
        <Container className="flex h-16 items-center justify-between gap-6">
          <ZoneBreadcrumb product="Commandment" />
          <p className="font-mono text-ink-subtle text-sm">
            {HERO.shortcutLabel}
          </p>
        </Container>
        <EdgeBlur className="top-full" />
      </header>

      <main className="flex-1">
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
