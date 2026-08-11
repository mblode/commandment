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
  <Section id="how-it-works">
    <Container>
      <Reveal>
        <SectionHeading>{SOLUTION.heading}</SectionHeading>
      </Reveal>

      <Reveal delay={0.08}>
        <ol className="mt-10 grid gap-6 sm:grid-cols-3">
          {SOLUTION.steps.map((step, index) => (
            <li className="raised rounded-xl bg-surface-1 p-5" key={step.title}>
              <p className="font-mono text-ink-faint text-xs tabular-nums">
                {index + 1}
              </p>
              <p className="mt-3 font-medium text-ink">{step.title}</p>
              <p className="mt-1.5 text-pretty text-ink-muted text-sm">
                {step.body}
              </p>
            </li>
          ))}
        </ol>
      </Reveal>
    </Container>
  </Section>
);
