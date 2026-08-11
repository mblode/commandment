import { AudioSection } from "@/components/marketing/audio-section";
import { ClosingCta } from "@/components/marketing/closing-cta";
import { ComparisonSection } from "@/components/marketing/comparison-section";
import { Hero } from "@/components/marketing/hero";
import { SiteFooter } from "@/components/site-footer";
import { Container } from "@/components/ui/section";
import { ZoneBreadcrumb } from "@/components/zone-breadcrumb";
import { getLatestRelease } from "@/lib/release";

export default async function Page() {
  const { downloadUrl, fileSizeMB, version } = await getLatestRelease();

  return (
    <div className="isolate flex min-h-dvh flex-col bg-canvas font-sans">
      <header className="material-header sticky top-0 z-50 bg-canvas/78 backdrop-blur-xl backdrop-saturate-150">
        <Container className="flex h-16 items-center">
          <ZoneBreadcrumb product="Commandment" />
        </Container>
      </header>

      <main className="flex-1" id="main-content">
        <Hero
          downloadUrl={downloadUrl}
          fileSizeMB={fileSizeMB}
          version={version}
        />
        <AudioSection />
        <ComparisonSection />
        <ClosingCta downloadUrl={downloadUrl} />
      </main>

      <SiteFooter />
    </div>
  );
}
