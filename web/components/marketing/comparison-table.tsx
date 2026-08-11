import { Reveal } from "@/components/ui/reveal";
import { Container, Section, SectionHeading } from "@/components/ui/section";
import { COMPARED_ON, COMPARISON } from "@/lib/content";

/**
 * The comparison, as a real `<table>`.
 *
 * A real table rather than a grid of divs, because this is the block most likely
 * to be quoted by something that is not a browser: `<th scope>` is what lets a
 * machine say "Commandment: free app, you pay OpenAI per second" instead of
 * reading a column of orphaned strings. The `<caption>` carries the date, which
 * is the difference between a claim and a checked claim.
 *
 * The honesty paragraph underneath is not a hedge and should not be softened. It
 * names the two products that beat this one, and the reason it is here is
 * selfish as well as honest: a comparison with no losing row reads as marketing
 * and gets discounted entirely, including the rows that were true.
 *
 * Scrolls horizontally on narrow viewports, with `tabindex` so a keyboard user
 * can actually reach the scroll — a scrollable region that only a mouse can pan
 * is a common way to lose the last two columns on a phone.
 */
/** Ties the provenance paragraph to the table via `aria-describedby`, now that
 * the two are no longer nested. */
const NOTE_ID = "comparison-note";

export const ComparisonTable = () => (
  <Section id="comparison">
    <Container>
      <Reveal>
        <SectionHeading>{COMPARISON.heading}</SectionHeading>

        {/* The provenance line sits OUTSIDE the scroller.
            As a `<caption>` it inherited the table's `min-w-[44rem]`, so on a
            390px phone it rendered 704px wide inside a 390px window and cut off
            mid-word: the reader saw the claim and had to pan sideways to reach
            the date that backs it. The date is the entire difference between a
            claim and a checked claim, so it cannot be the part that scrolls
            away. `aria-describedby` keeps it attached to the table for anyone
            who reaches the table first. */}
        <p className="mt-8 max-w-[60ch] text-ink-faint text-sm" id={NOTE_ID}>
          Checked against each vendor&rsquo;s pricing pages on {COMPARED_ON}.
          They ship often, so check first.
        </p>

        {/* A labelled landmark with a tab stop: the WCAG-documented pattern for
            a scrollable area, and all three parts are load-bearing. Without the
            tab stop a keyboard user cannot pan the table and simply loses the
            last two columns on a phone. Without the accessible name the focus
            stop is a dead end with nothing announced. The lint rule is guarding
            against a stray tab stop on an anonymous `<div>`, which this is not. */}
        <section
          aria-describedby={NOTE_ID}
          aria-label="Feature and pricing comparison"
          className="-mx-4 mt-4 overflow-x-auto px-4 sm:mx-0 sm:px-0"
          // biome-ignore lint/a11y/noNoninteractiveTabindex: a scrollable region must be keyboard-reachable — WCAG 2.1 G202.
          tabIndex={0}
        >
          <table className="w-full min-w-[38rem] border-collapse text-left text-sm">
            <caption className="sr-only">
              How Commandment compares to Wispr Flow, Superwhisper and Apple
              Dictation
            </caption>
            <thead>
              <tr className="border-white/10 border-b">
                {/* Pinned with the row labels below it, so the header row and the
                    label column scroll as one. */}
                <td className="sticky left-0 z-10 bg-canvas py-3 pr-4" />
                {COMPARISON.columns.map((column, index) => (
                  <th
                    className={
                      index === 0
                        ? "py-3 pr-4 font-medium text-ink"
                        : "py-3 pr-4 font-medium text-ink-muted"
                    }
                    key={column}
                    scope="col"
                  >
                    {column}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {COMPARISON.rows.map((row) => (
                <tr className="border-white/5 border-b" key={row.label}>
                  {/* `sticky left-0` is the difference between a comparison and
                      a column of orphaned values. At 390px the table is 608px
                      wide, so panning to the far end used to scroll the row
                      labels AND the Commandment column off-screen, leaving six
                      unlabelled rows comparing two competitors to nothing.
                      A screen-reader user always had the association through
                      `scope="row"`; the sighted phone user did not. */}
                  <th
                    className="sticky left-0 z-10 bg-canvas py-3 pr-4 font-medium text-ink-subtle"
                    scope="row"
                  >
                    {row.label}
                  </th>
                  {row.values.map((value, index) => (
                    <td
                      className={
                        index === 0
                          ? "py-3 pr-4 text-ink"
                          : "py-3 pr-4 text-ink-muted"
                      }
                      key={`${row.label}-${COMPARISON.columns[index]}`}
                    >
                      {value}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </section>

        <p className="mt-6 max-w-[65ch] text-pretty text-ink-muted">
          {COMPARISON.honesty}
        </p>
      </Reveal>
    </Container>
  </Section>
);
