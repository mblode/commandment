import { Reveal } from "@/components/ui/reveal";
import { Container, Section, SectionHeading } from "@/components/ui/section";

/**
 * A question and its answer, with nothing around it.
 *
 * The two blockers that stop an install — where the audio goes, and why it wants
 * Accessibility — are one honest paragraph. They were briefly a diagram and a
 * permissions matrix, and both versions said less than the sentence does: a
 * three-node flow chart of "microphone → app → OpenAI" is a picture of a
 * sentence, and a reader deciding whether to trust this is reading, not
 * scanning. So there is no graphic here on purpose.
 *
 * `secondaryId` exists because those two blockers used to be two sections with
 * two anchors, and both anchors were published as an `acceptedAnswer.url`. The
 * section keeps one and the paragraph keeps the other, so a link to either one
 * still lands on visible text rather than on nothing.
 */
export const ProseSection = ({
  body,
  heading,
  id,
  secondaryId,
}: {
  body: string;
  heading: string;
  id?: string;
  secondaryId?: string;
}) => (
  <Section id={id}>
    <Container>
      <Reveal>
        <SectionHeading>{heading}</SectionHeading>
        <p
          className="mt-4 max-w-[65ch] text-pretty text-ink-muted text-lg leading-relaxed"
          id={secondaryId}
        >
          {body}
        </p>
      </Reveal>
    </Container>
  </Section>
);
