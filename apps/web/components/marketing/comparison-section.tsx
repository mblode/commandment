import { Container, Section } from "@/components/ui/section";
import { COMPARISON } from "@/lib/content";

export const ComparisonSection = () => (
  <Section className="bg-night text-night-ink" id="comparison">
    <Container>
      <h2 className="max-w-[18ch] text-balance font-medium text-4xl tracking-[-0.04em] sm:text-6xl sm:leading-[1.05]">
        {COMPARISON.heading}
      </h2>
      <p className="mt-8 max-w-[48ch] text-pretty text-2xl text-night-muted sm:text-3xl">
        {COMPARISON.body}
      </p>
    </Container>
  </Section>
);
