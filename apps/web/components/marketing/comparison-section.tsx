import { Container, Section } from "@/components/ui/section";
import { COMPARISON } from "@/lib/content";

export const ComparisonSection = () => (
  <Section className="bg-night text-night-ink" id="comparison">
    <Container>
      <h2 className="max-w-[18ch] text-balance font-medium text-4xl tracking-[-0.04em] sm:text-6xl sm:leading-[1.05]">
        {COMPARISON.heading}
      </h2>
      <p className="mt-8 max-w-[52ch] text-pretty text-2xl text-night-muted sm:text-3xl">
        {COMPARISON.lede}
      </p>
      <div className="mt-16 overflow-x-auto">
        <table className="w-full min-w-[40rem] border-collapse text-left text-lg">
          <caption className="sr-only">
            Commandment compared with Apple Dictation, Willow, and Superwhisper
          </caption>
          <thead>
            <tr className="border-night-ink/35 border-b">
              <th
                className="py-4 pr-6 font-medium text-night-muted"
                scope="col"
              >
                Feature
              </th>
              {COMPARISON.columns.map((column) => (
                <th
                  className="py-4 pr-6 font-medium last:pr-0"
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
              <tr className="border-night-ink/25 border-b" key={row.feature}>
                <th
                  className="py-5 pr-6 font-medium text-night-muted"
                  scope="row"
                >
                  {row.feature}
                </th>
                {row.values.map((value, index) => (
                  <td
                    className="py-5 pr-6 last:pr-0"
                    key={COMPARISON.columns[index]}
                  >
                    {value}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Container>
  </Section>
);
