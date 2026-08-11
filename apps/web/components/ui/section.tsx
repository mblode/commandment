import type { ComponentProps, ReactNode } from "react";

import { cn } from "@/lib/utils";

/** The page's vertical rhythm lives here. Sections are full-bleed and the
 * inner Container is a fixed max-width, so layout splits use viewport
 * breakpoints — a container query here would just measure the viewport under
 * a different, smaller scale (@lg is 32rem, not 64rem) and fire far too early. */
const Section = ({
  className,
  children,
  ...props
}: ComponentProps<"section">) => (
  <section
    className={cn("scroll-mt-24 py-20 sm:py-28 lg:py-36", className)}
    {...props}
  >
    {children}
  </section>
);

/**
 * One width for every section on the page, and no option to change it.
 *
 * This briefly took a `size` prop so text sections could be narrower than the
 * ones holding a product frame. That was wrong, and wrong in a way that only
 * shows up in a screenshot: `mx-auto` centres whatever width it is given, so a
 * narrower container is not a narrower column — it is a column with a
 * different left edge. The page rendered with "What is Commandment?" starting
 * 156px to the right of "How does Commandment work?", and every prose section
 * stepping in and out down the page.
 *
 * The measure still matters; it just does not belong here. It goes on the
 * element that holds the text (`max-w-[65ch]` on a paragraph, `[40ch]` on a
 * heading), which caps the line length without moving where the line starts.
 * That is the same rule the original single-screen page recorded in a comment
 * about padding and measure, learned the same way.
 */
const Container = ({
  className,
  children,
  ...props
}: ComponentProps<"div">) => (
  <div
    className={cn("mx-auto w-full max-w-7xl px-5 sm:px-8 lg:px-10", className)}
    {...props}
  >
    {children}
  </div>
);

interface SectionHeadingProps {
  children: ReactNode;
}

/** Every heading on these pages is a question somebody would type, so this
 * renders an `h2` and the caller supplies the question. Hierarchy is size and
 * weight only: no uppercase-tracked eyebrow, which is the label style that
 * makes a page look like it came out of a template.
 *
 * Measure caps sit on the element rather than the container. That is what makes
 * a ragged right edge read as chosen rather than as an accident of viewport
 * width. */
const SectionHeading = ({ children }: SectionHeadingProps) => (
  <div>
    <h2 className="max-w-[24ch] text-balance font-medium text-4xl text-ink tracking-[-0.035em] sm:text-5xl sm:leading-[1.05]">
      {children}
    </h2>
  </div>
);

export { Container, Section, SectionHeading };
