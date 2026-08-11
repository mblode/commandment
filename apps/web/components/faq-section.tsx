import { Container, Section } from "@/components/ui/section";
import { FAQ_HEADING } from "@/lib/content";
import { faq } from "@/lib/faq";

export const FaqSection = () => (
  <Section id="faq">
    <Container>
      <h2 className="max-w-[16ch] text-balance font-medium text-4xl text-ink tracking-[-0.04em] sm:text-6xl sm:leading-[1.05]">
        {FAQ_HEADING}
      </h2>
      <dl className="mt-14 grid border-ink/20 border-t lg:grid-cols-2">
        {faq.map((entry) => (
          <div
            className="border-ink/15 border-b py-8 lg:even:border-l lg:even:pl-10 lg:odd:pr-10"
            key={entry.id}
          >
            <dt>
              <h3
                className="max-w-[32ch] text-pretty font-medium text-2xl text-ink tracking-[-0.02em]"
                id={entry.id}
              >
                {entry.question}
              </h3>
            </dt>
            <dd className="mt-4 max-w-[48ch] text-pretty text-base text-ink-muted">
              {entry.answer}
              {entry.code ? (
                <code className="mt-3 block overflow-x-auto rounded-lg bg-surface-1 px-3 py-2 font-mono text-ink-muted text-sm">
                  {entry.code}
                </code>
              ) : null}
            </dd>
          </div>
        ))}
      </dl>
    </Container>
  </Section>
);
