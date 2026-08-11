import { Reveal } from "@/components/ui/reveal";
import { Container, Section, SectionHeading } from "@/components/ui/section";
import { SOLUTION } from "@/lib/content";

/** How it works, as three steps and nothing else.
 *
 * The three steps are the whole interaction, and each one is a real keystroke
 * rather than a stage name. "Configure your workspace" is what a step is called
 * when the product does not have one.
 *
 * There is no lede. The paragraph that used to sit here restated the steps
 * before the steps, and every fact in it is elsewhere on the page — see the
 * comment above `SOLUTION` in `lib/content.ts` for where each one went. */
export const HowItWorks = () => (
  <Section className="bg-canvas" id="how-it-works">
    <Container>
      <Reveal>
        <SectionHeading>{SOLUTION.heading}</SectionHeading>
      </Reveal>

      <Reveal delay={0.08}>
        <ol className="mt-14 grid border-ink/20 border-t sm:grid-cols-3">
          {SOLUTION.steps.map((step, index) => (
            <li
              className="flex min-w-0 flex-col gap-10 border-ink/15 border-b py-8 sm:border-b-0 sm:not-first:border-l sm:px-7 sm:last:pr-0 sm:first:pl-0 lg:gap-16 lg:py-10"
              key={step.title}
            >
              <p className="font-mono text-signal text-sm tabular-nums">
                0{index + 1}
              </p>
              <div className="flex flex-col gap-3">
                <p className="font-medium text-2xl text-ink tracking-[-0.025em]">
                  {step.title}
                </p>
                <p className="max-w-[28ch] text-pretty text-base text-ink-muted">
                  {step.body}
                </p>
              </div>
            </li>
          ))}
        </ol>
      </Reveal>
    </Container>
  </Section>
);
