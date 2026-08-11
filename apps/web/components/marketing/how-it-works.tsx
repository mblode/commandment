import { Reveal } from "@/components/ui/reveal";
import { Container, Section, SectionHeading } from "@/components/ui/section";
import { SOLUTION } from "@/lib/content";

export const HowItWorks = () => (
  <Section className="bg-canvas" id="how-it-works">
    <Container>
      <Reveal>
        <SectionHeading>{SOLUTION.heading}</SectionHeading>
      </Reveal>

      <Reveal>
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
