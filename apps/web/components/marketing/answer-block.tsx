import { Container, Section } from "@/components/ui/section";
import { ANSWER_NOTE, ANSWER_QUESTION, ANSWER_TEXT } from "@/lib/content";

/**
 * The liftable answer, directly under the fold.
 *
 * An answer engine asked "what is Commandment" will quote one paragraph or
 * none. This is that paragraph, and it is written to survive being lifted with
 * nothing around it: no pronoun referring to the h1, no "the app", no dependency
 * on the sentence before it.
 *
 * The `h2` is the literal question. That is the split this page makes — the h1
 * is a claim a person wants to read, the h2 is the query a machine matched, and
 * the paragraph answers it once for both of them. Making the h1 itself the
 * question would have served the machine and cost the reader.
 *
 * Deliberately not wrapped in `Reveal`: it sits in the first viewport on a tall
 * desktop window, and content that fades in is content that is briefly absent.
 */
export const AnswerBlock = () => (
  <Section className="border-ink/15 border-b bg-paper/65">
    <Container>
      <div className="grid gap-10 lg:grid-cols-[3fr_7fr] lg:gap-14">
        <h2 className="max-w-[40ch] font-mono text-ink-subtle text-sm uppercase tracking-wide">
          {ANSWER_QUESTION}
        </h2>
        <div className="min-w-0">
          <p className="max-w-[42ch] text-pretty text-2xl text-ink tracking-[-0.025em] sm:text-3xl">
            {ANSWER_TEXT}
          </p>
          <p className="mt-8 max-w-[48ch] text-base text-ink-subtle sm:text-sm">
            {ANSWER_NOTE}
          </p>
        </div>
      </div>
    </Container>
  </Section>
);
