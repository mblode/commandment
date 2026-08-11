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
  <Section className="border-white/5 border-y bg-surface-1/40 py-12 sm:py-16">
    <Container>
      <h2 className="max-w-[40ch] text-balance font-medium text-2xl text-ink tracking-tight sm:text-3xl sm:tracking-[-0.02em]">
        {ANSWER_QUESTION}
      </h2>
      <p className="mt-4 max-w-[60ch] text-pretty text-ink-muted text-lg leading-relaxed">
        {ANSWER_TEXT}
      </p>
      <p className="mt-4 text-ink-faint text-sm">{ANSWER_NOTE}</p>
    </Container>
  </Section>
);
