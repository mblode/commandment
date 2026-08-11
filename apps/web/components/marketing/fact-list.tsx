import { Reveal } from "@/components/ui/reveal";
import { Container, Section, SectionHeading } from "@/components/ui/section";

interface Fact {
  detail: string;
  href?: string;
  term: string;
}

export const FactList = ({
  facts,
  heading,
  id,
}: {
  facts: readonly Fact[];
  heading: string;
  id?: string;
}) => (
  <Section id={id}>
    <Container>
      <Reveal>
        <SectionHeading>{heading}</SectionHeading>
        <dl className="mt-14 grid border-ink/20 border-t lg:grid-cols-2">
          {facts.map((fact) => (
            <div
              className="grid gap-3 border-ink/15 border-b py-7 lg:grid-cols-[minmax(0,8rem)_minmax(0,1fr)] lg:gap-6 lg:even:border-l lg:even:pl-8 lg:odd:pr-8"
              key={fact.term}
            >
              <dt className="font-medium text-ink">{fact.term}</dt>
              <dd className="text-pretty text-base text-ink-muted">
                {fact.detail}
                {fact.href ? (
                  <>
                    {" "}
                    <a
                      aria-label={`View ${fact.term.toLowerCase()}`}
                      className="whitespace-nowrap text-ink underline decoration-ink/25 underline-offset-4 hover:decoration-ink/70 focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
                      href={fact.href}
                    >
                      View
                    </a>
                  </>
                ) : null}
              </dd>
            </div>
          ))}
        </dl>
      </Reveal>
    </Container>
  </Section>
);
