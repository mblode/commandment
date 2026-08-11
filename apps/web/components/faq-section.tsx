import { Container, Section } from "@/components/ui/section";
import { FAQ_HEADING } from "@/lib/content";
import { faq } from "@/lib/faq";

/**
 * The FAQ, as plain headings and paragraphs.
 *
 * This replaced a native `<details>` accordion, and the reasoning is worth
 * keeping because the obvious reading of it is wrong. `<details>` was never a
 * crawler bug — the copy stays in the DOM whether it is open or shut, which is
 * exactly why it was chosen over Blode UI's Accordion, whose panel content does
 * not survive server rendering at all. The problem with `<details>` here is
 * narrower and still real:
 *
 * - a `<summary>` is not a heading, so seven questions produced no document
 *   outline and a screen-reader user could not jump between them;
 * - a collapsed answer is not *rendered text*, and an answer engine asked to
 *   quote a page has to decide whether it is looking at content or at markup
 *   with something hidden in it. `acceptedAnswer.text` matching something the
 *   reader must click to see is the shape Google calls a mismatch;
 * - the page it was protecting no longer exists. Collapsing existed to keep this
 *   one screen tall. It is now nine sections, so the constraint that justified
 *   the trade is gone.
 *
 * The `id` moves onto the `<h3>` and must stay there: `faqSchema()` publishes it
 * as `acceptedAnswer.url`, so deleting it points the graph at an anchor that
 * resolves to nothing.
 *
 * `h3`, not `h2`, because the section now has a heading of its own above it.
 */
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
