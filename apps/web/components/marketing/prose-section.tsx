import { Reveal } from "@/components/ui/reveal";
import { Container, Section } from "@/components/ui/section";
import { AUDIO_ROUTE } from "@/lib/content";

export const ProseSection = ({
  body,
  heading,
  id,
  secondaryId,
}: {
  body: string;
  heading: string;
  id?: string;
  secondaryId?: string;
}) => (
  <Section className="bg-signal text-paper" id={id}>
    <Container>
      <Reveal>
        <h2 className="max-w-[14ch] text-balance font-medium text-5xl text-paper leading-[0.98] tracking-[-0.05em] sm:text-7xl sm:leading-[0.94]">
          {heading}
        </h2>

        <ol className="mt-16 grid border-paper/35 border-t sm:grid-cols-2 lg:grid-cols-4">
          {AUDIO_ROUTE.stops.map((stop, index) => (
            <li
              className="flex min-w-0 flex-col gap-8 border-paper/25 border-b py-6 sm:px-6 lg:border-b-0 lg:last:pr-0 lg:[&:not(:first-child)]:border-l lg:[&:nth-child(3)]:pl-6 sm:[&:nth-child(even)]:border-l sm:[&:nth-child(odd)]:pl-0"
              key={stop.name}
            >
              <p className="font-mono text-paper/70 text-sm tabular-nums">
                0{index + 1}
              </p>
              <div className="flex flex-col gap-1">
                <p className="font-medium text-2xl tracking-[-0.025em]">
                  {stop.name}
                </p>
                <p className="text-base text-paper/75 sm:text-sm">
                  {stop.detail}
                </p>
              </div>
            </li>
          ))}
        </ol>

        <p
          className="mt-12 max-w-[64ch] text-pretty text-lg text-paper/85"
          id={secondaryId}
        >
          {body}
        </p>
      </Reveal>
    </Container>
  </Section>
);
