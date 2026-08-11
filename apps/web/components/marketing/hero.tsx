import Image from "next/image";

import { DownloadButton } from "@/components/marketing/download-button";
import { DictationMock } from "@/components/mocks/dictation-mock";
import { ProductFrame } from "@/components/mocks/product-frame";
import { Container } from "@/components/ui/section";
import { BREW_COMMAND, HERO } from "@/lib/content";

export const Hero = ({
  downloadUrl,
  fileSizeMB,
  version,
}: {
  downloadUrl: string;
  fileSizeMB: string;
  version: string;
}) => (
  <section className="relative overflow-hidden border-ink/15 border-b">
    <Container className="flex min-h-[calc(100svh-4rem)] flex-col pt-4 pb-8 sm:pt-8 sm:pb-12">
      <h1 className="text-ink">
        <span className="block whitespace-nowrap font-medium text-[clamp(3.35rem,13.1vw,10.5rem)] leading-[0.82] tracking-[-0.065em]">
          Commandment
        </span>
        <span className="mt-10 block max-w-[13ch] text-balance font-medium text-[clamp(2.75rem,5.3vw,4.8rem)] leading-[0.95] tracking-[-0.055em] sm:mt-14 lg:mt-16">
          {HERO.headline}
        </span>
      </h1>

      <div className="mt-10 grid flex-1 items-end gap-12 lg:mt-[-7rem] lg:grid-cols-[4fr_7fr] lg:gap-14">
        <div className="flex min-w-0 flex-col items-start gap-7 lg:pb-6">
          <p className="max-w-[38ch] text-pretty text-ink-muted text-lg">
            {HERO.subhead}
          </p>

          <div className="flex flex-wrap items-center gap-4">
            <DownloadButton href={downloadUrl} />
            <p className="text-base text-ink-subtle sm:text-sm">
              {HERO.downloadNote}
            </p>
          </div>

          <div className="flex max-w-full items-center gap-3 overflow-x-auto font-mono text-ink-subtle text-sm">
            <code className="whitespace-pre">{BREW_COMMAND}</code>
          </div>
        </div>

        <div className="min-w-0 blur-up [animation-delay:180ms]">
          <ProductFrame description="A macOS menu bar recording meter above a Notes window, where ‘Can you send me the deck before standup tomorrow?’ appears one word at a time while Option and D are held.">
            <DictationMock />
          </ProductFrame>
        </div>
      </div>

      <div className="mt-8 flex flex-wrap items-center justify-between gap-4 border-ink/15 border-t pt-4 font-mono text-ink-subtle text-sm">
        <div className="flex items-center gap-3">
          <Image
            alt=""
            className="size-8 shrink-0 rounded-[22%]"
            height={32}
            preload
            src="/commandment/app-icon.png"
            width={32}
          />
          <span>{HERO.utilityLabel}</span>
        </div>
        <p className="tabular-nums">
          {[version, fileSizeMB, HERO.requirement].filter(Boolean).join(" · ")}
        </p>
      </div>
    </Container>
  </section>
);
