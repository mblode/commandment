import { Container, Section } from "@/components/ui/section";
import { AUDIO_ROUTE } from "@/lib/content";

export const AudioSection = () => (
  <Section className="bg-signal text-ink" id={AUDIO_ROUTE.id}>
    <Container>
      <h2 className="max-w-[14ch] text-balance font-medium text-5xl leading-[0.98] tracking-[-0.05em] sm:text-7xl sm:leading-[0.94]">
        {AUDIO_ROUTE.heading}
      </h2>
      <ul className="mt-16 grid border-ink/35 border-t sm:grid-cols-3">
        {AUDIO_ROUTE.points.map((point) => (
          <li
            className="text-pretty border-ink/25 border-b py-7 text-xl sm:border-b-0 sm:not-first:border-l sm:px-7 sm:last:pr-0 sm:first:pl-0"
            key={point}
          >
            {point}
          </li>
        ))}
      </ul>
    </Container>
  </Section>
);
