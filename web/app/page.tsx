import { FaqSection } from "@/components/faq-section";
import { AnswerBlock } from "@/components/marketing/answer-block";
import { ClosingCta } from "@/components/marketing/closing-cta";
import { ComparisonTable } from "@/components/marketing/comparison-table";
import { Hero } from "@/components/marketing/hero";
import { HowItWorks } from "@/components/marketing/how-it-works";
import { ProseSection } from "@/components/marketing/prose-section";
import { SiteFooter } from "@/components/site-footer";
import { Container } from "@/components/ui/section";
import { ZoneBreadcrumb } from "@/components/zone-breadcrumb";
import { AUDIO_ROUTE } from "@/lib/content";
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
    <div className="isolate flex min-h-dvh flex-col bg-canvas font-sans">
      {/* Root page only, and matched word for word by the BreadcrumbList in
          lib/config.ts. Google treats a mismatch between the visible trail and
          the markup as an error, so the two change together. */}
      <Container className="pt-8">
        <ZoneBreadcrumb product="Commandment" />
      </Container>

      <main className="flex-1">
        {/* The glow is a light source above the fold, not a wash behind the
            headline. Pointer-events-none and behind everything. */}
        <div className="relative">
          <div
            aria-hidden="true"
            className="hero-glow pointer-events-none absolute inset-x-0 top-0 -z-10 h-[36rem]"
          />
          <Hero
            downloadUrl={downloadUrl}
            fileSizeMB={fileSizeMB}
            version={version}
          />
        </div>

        <AnswerBlock />
        <HowItWorks />
        <ProseSection
          body={AUDIO_ROUTE.body}
          heading={AUDIO_ROUTE.heading}
          id={AUDIO_ROUTE.id}
          secondaryId={AUDIO_ROUTE.accessibilityId}
        />
        <ComparisonTable />
        <FaqSection />
        <ClosingCta downloadUrl={downloadUrl} version={version} />
      </main>

      <SiteFooter version={version} />
    </div>
  );
}
