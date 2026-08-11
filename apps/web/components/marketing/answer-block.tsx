import { Container, Section } from "@/components/ui/section";
import { ANSWER_NOTE, ANSWER_QUESTION, ANSWER_TEXT } from "@/lib/content";

export const AnswerBlock = () => (
  <Section className="border-ink/15 border-b bg-paper/65">
    <Container>
      <div className="grid gap-10 lg:grid-cols-[3fr_7fr] lg:gap-14">
        <h2 className="max-w-[40ch] font-mono text-ink-subtle text-sm">
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
