import { Reveal } from "@/components/ui/reveal";
import { Container, Section } from "@/components/ui/section";
import { COMPARED_ON, COMPARISON } from "@/lib/content";

const NOTE_ID = "comparison-note";

export const ComparisonTable = () => (
  <Section className="bg-night text-night-ink" id="comparison">
    <Container>
      <Reveal>
        <h2 className="max-w-[18ch] text-balance font-medium text-4xl text-night-ink tracking-[-0.04em] sm:text-6xl sm:leading-[1.05]">
          {COMPARISON.heading}
        </h2>

        <p
          className="mt-8 max-w-[60ch] text-base text-night-muted sm:text-sm"
          id={NOTE_ID}
        >
          Prices and features checked on {COMPARED_ON}.
        </p>

        <section
          aria-describedby={NOTE_ID}
          aria-label="Feature and pricing comparison"
          className="-mx-5 mt-6 overflow-x-auto overscroll-x-contain px-5 focus-visible:outline-2 focus-visible:outline-signal focus-visible:outline-offset-2 sm:-mx-8 sm:px-8 lg:mx-0 lg:px-0"
          // biome-ignore lint/a11y/noNoninteractiveTabindex: a scrollable region must be keyboard-reachable — WCAG 2.1 G202.
          tabIndex={0}
        >
          <table
            aria-describedby={NOTE_ID}
            className="w-full min-w-[46rem] border-collapse text-left text-base"
          >
            <caption className="sr-only">
              Commandment compared with Wispr Flow, Superwhisper and Apple
              Dictation.
            </caption>
            <thead>
              <tr className="border-white/20 border-b">
                <th
                  className="sticky left-0 z-10 bg-night py-4 pr-5"
                  scope="col"
                >
                  <span className="sr-only">Feature</span>
                </th>
                {COMPARISON.columns.map((column, index) => (
                  <th
                    className={
                      index === 0
                        ? "whitespace-nowrap py-4 pr-5 font-medium text-signal"
                        : "whitespace-nowrap py-4 pr-5 font-medium text-night-muted"
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
                <tr className="border-white/10 border-b" key={row.label}>
                  <th
                    className="sticky left-0 z-10 bg-night py-5 pr-5 font-medium text-night-muted"
                    scope="row"
                  >
                    {row.label}
                  </th>
                  {row.values.map((value, index) => (
                    <td
                      className={
                        index === 0
                          ? "py-5 pr-5 text-night-ink"
                          : "py-5 pr-5 text-night-muted"
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

        <p className="mt-10 max-w-[65ch] text-pretty text-base text-night-muted">
          {COMPARISON.honesty}
        </p>
      </Reveal>
    </Container>
  </Section>
);
