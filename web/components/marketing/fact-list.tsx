import { Reveal } from "@/components/ui/reveal";
import { Container, Section, SectionHeading } from "@/components/ui/section";

interface Fact {
  detail: string;
  /** Where the reader checks it. Optional only because two of the cost rows are
   * statements about billing rather than about the repository — every row that
   * asserts something about the software carries one. */
  href?: string;
  term: string;
}

/**
 * Proof, as a list of things somebody can go and verify.
 *
 * What is not here matters more than what is. No star count, no download total,
 * no testimonials, no logo wall. This project has four GitHub stars; a page that
 * renders "4" beside a download button has spent real credibility to say
 * nothing, and diffhub deleted its own star count for exactly that reason — a
 * release count is a signal about a project, not an answer about a product.
 *
 * So every row is a fact with a link, and the closing line says out loud that
 * there is no customer roster yet. A reader who checks two of these and finds
 * them true will believe the third. A reader who finds a padded number will not
 * check anything else on the page.
 */
export const FactList = ({
  closing,
  facts,
  heading,
  id,
}: {
  closing?: string;
  facts: readonly Fact[];
  heading: string;
  id?: string;
}) => (
  <Section id={id}>
    <Container>
      <Reveal>
        <SectionHeading>{heading}</SectionHeading>
        <dl className="mt-8 max-w-[72ch] divide-y divide-white/5 border-white/5 border-t">
          {facts.map((fact) => (
            <div
              className="grid gap-1 py-4 sm:grid-cols-[minmax(0,10rem)_minmax(0,1fr)] sm:gap-6"
              key={fact.term}
            >
              <dt className="font-medium text-ink text-sm">{fact.term}</dt>
              <dd className="text-pretty text-ink-muted text-sm">
                {fact.detail}
                {fact.href ? (
                  <>
                    {" "}
                    {/*
                      Six rows, six links, and the visible text on all of them is
                      "Check it" — which reads fine in place and is useless out of
                      it. A screen reader user pulling up a list of links on this
                      page would get "Check it" six times with nothing to choose
                      between. The `aria-label` restores the row's own subject to
                      the accessible name while the visible text stays short
                      enough not to break the sentence it sits in.
                    */}
                    <a
                      aria-label={`Check it: ${fact.term.toLowerCase()}`}
                      className="whitespace-nowrap text-ink underline decoration-white/25 underline-offset-4 hover:decoration-white/60 focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
                      href={fact.href}
                    >
                      Check it
                    </a>
                  </>
                ) : null}
              </dd>
            </div>
          ))}
        </dl>
        {closing ? (
          <p className="mt-6 max-w-[60ch] text-pretty text-ink-faint text-sm">
            {closing}
          </p>
        ) : null}
      </Reveal>
    </Container>
  </Section>
);
