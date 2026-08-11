import Image from "next/image";
import { DownloadButton } from "@/components/marketing/download-button";
import { DictationMock } from "@/components/mocks/dictation-mock";
import { ProductFrame } from "@/components/mocks/product-frame";
import { Container } from "@/components/ui/section";
import { BREW_COMMAND, HERO } from "@/lib/content";

/**
 * The fold.
 *
 * The h1 carries no entrance animation, and that is a rule rather than an
 * oversight. It is the LCP element on this page: an animation that starts it at
 * `opacity: 0` moves the largest contentful paint to the end of the animation,
 * so the page measures slower for the sake of an effect nobody scrolled past yet
 * to see. The delay ladder starts at the subhead.
 *
 * One action, once. A second button here — "View on GitHub", "Read the docs" —
 * splits the decision at the exact moment the reader has made it.
 */
export const Hero = ({
  downloadUrl,
  fileSizeMB,
  version,
}: {
  downloadUrl: string;
  fileSizeMB: string;
  version: string;
}) => (
  <Container className="pt-10 pb-16 sm:pt-14 sm:pb-24">
    {/* Centred, which is the one place this page departs from the left-aligned
        rhythm every section below it keeps.

        Left-aligned, the hero left the right half of a desktop viewport empty
        above a full-width product frame, and the mismatch read as unfinished
        rather than as restraint. Centring costs nothing here because there is
        one column of content and one action: the reasons to left-align a hero
        (a second column, a long lede, a form) are all absent. */}
    <div className="mx-auto flex max-w-[46ch] flex-col items-center text-center">
      <Image
        alt=""
        className="rounded-[22%]"
        height={72}
        priority
        src="/commandment/app-icon.png"
        width={72}
      />

      <h1 className="mt-6 max-w-[24ch] text-balance font-semibold text-4xl text-ink tracking-tight sm:text-5xl sm:tracking-[-0.03em]">
        {HERO.headline}
      </h1>

      <p className="mt-5 max-w-[46ch] text-pretty text-ink-muted text-lg blur-up [animation-delay:80ms]">
        {HERO.subhead}
      </p>

      <div className="mt-8 flex flex-wrap items-center justify-center gap-3.5 blur-up [animation-delay:160ms]">
        <DownloadButton href={downloadUrl} />
        {fileSizeMB ? (
          <p className="text-ink-faint text-sm">{fileSizeMB}</p>
        ) : null}
      </div>

      <p className="mt-3 text-ink-faint text-sm blur-up [animation-delay:240ms]">
        {version ? `${version} · ` : ""}Requires macOS 15.2
      </p>

      <code className="mt-4 block max-w-full overflow-x-auto whitespace-pre rounded-lg bg-surface-1 px-3 py-2 text-left font-mono text-ink-muted text-sm blur-up [animation-delay:240ms]">
        {BREW_COMMAND}
      </code>
    </div>

    {/* Below the copy, not beside it. The mock is the proof, but the claim and
        the button are what a visitor came for, and a two-column fold puts them
        in competition for the same first second.

        No `caption`. It read "Hold the shortcut, speak, and the words land
        where the cursor already was", which is the subhead above it and step
        three below it said a third time under a picture of both.

        The `description` is shorter but still carries the dictated sentence
        verbatim. That is the one part of it that cannot be trimmed for length:
        it is the only route by which a screen reader user gets the words a
        sighted visitor watches being typed. */}
    <ProductFrame
      className="mt-12 blur-up [animation-delay:350ms] sm:mt-16"
      description="A macOS menu bar recording meter above a Notes window, where “Can you send me the deck before standup tomorrow?” types itself one word at a time while Option and D are held."
    >
      <DictationMock />
    </ProductFrame>
  </Container>
);
