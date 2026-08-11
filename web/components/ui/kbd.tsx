import type { ComponentProps } from "react";

import { cn } from "@/lib/utils";

/** A keycap.
 *
 * diffhub's version of this renders modifier glyphs from `blode-icons-react`.
 * That is the right call there because it already depends on the package; here
 * it would mean adding an icon library to a two-section marketing page for the
 * sake of two characters. `⌥` and `⇧` are ordinary Unicode and Glide draws them
 * correctly, so they are text.
 *
 * `w-fit min-w-[1.75em]` rather than a fixed width: a single letter and `esc`
 * both have to sit in the same row without either being cramped or floating in
 * a box three times its width. */
export const Kbd = ({
  className,
  children,
  ...props
}: ComponentProps<"kbd">) => (
  <kbd
    className={cn(
      "raised inline-flex min-w-[1.75em] items-center justify-center rounded-md bg-surface-2 px-1.5 py-1 font-medium font-sans text-ink-muted text-xs leading-none",
      className
    )}
    {...props}
  >
    {children}
  </kbd>
);

/** A chord. The `+` separators are decorative — the accessible name comes from
 * the caller's surrounding text, which should say "Option D" in words rather
 * than leaving a screen reader to narrate two glyphs and a plus sign. */
export const KbdGroup = ({
  className,
  children,
  ...props
}: ComponentProps<"span">) => (
  <span className={cn("inline-flex items-center gap-1", className)} {...props}>
    {children}
  </span>
);
