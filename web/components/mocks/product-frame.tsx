import type { ComponentProps, ReactNode } from "react";

import { cn } from "@/lib/utils";

interface ProductFrameProps extends Omit<ComponentProps<"figure">, "children"> {
  caption?: ReactNode;
  children: ReactNode;
  /** Read aloud in place of the mock, which is decorative to a screen reader.
   * Every mock must supply one: the information in the pixels has to exist as
   * text too, or the page says less to some visitors than to others. */
  description: string;
}

/** The single frame every product mock sits in, so a real screenshot can
 * replace the markup later without touching surrounding layout.
 *
 * Convene's version leans on its scoped `chrome-surface` / `bg-chrome` /
 * `shadow-lifted` classes, which exist there because its page is warm paper and
 * the mocks are the only dark thing on it. Here the whole page is already
 * `--surface-0`, so the frame lifts with `raised-strong` instead: a lit top
 * edge, a ring, and the one shadow this palette keeps — the job of separating a
 * floating thing from the page.
 *
 * The caller must give the frame a height (`aspect-ratio` or a per-breakpoint
 * `min-h`) sized to its *tallest* state. A mock that grows as lines arrive is
 * the most likely source of layout shift on these pages. */
export const ProductFrame = ({
  caption,
  children,
  className,
  description,
  ...props
}: ProductFrameProps) => (
  <figure className={cn("group/frame", className)} {...props}>
    <div
      aria-hidden="true"
      className="raised-strong overflow-hidden rounded-2xl bg-surface-1"
    >
      {children}
    </div>
    <figcaption className="sr-only">{description}</figcaption>
    {caption ? (
      <p aria-hidden="true" className="mt-4 text-center text-ink-faint text-sm">
        {caption}
      </p>
    ) : null}
  </figure>
);
