"use client";
"use no memo";

import type { ElementType, ReactNode } from "react";
import { useEffect, useRef, useState } from "react";

interface RevealProps {
  as?: "div" | "figure" | "li" | "section";
  children: ReactNode;
  className?: string;
  delay?: number;
}

/** How long to wait before showing content anyway. If IntersectionObserver
 * never fires — a broken polyfill, an embedded webview, a throttled background
 * tab — the page must not be permanently blank. */
const SAFETY_MS = 4000;

/** Scroll reveal that fails open. Copied from convene, unchanged.
 *
 * The server renders every child *visible*. Only after mount, and only for
 * elements that are actually below the fold, does this hide them to animate
 * them back in. So with no JS, no observer, or reduced motion, the reader gets
 * the whole page — the animation is decoration layered on top, never the thing
 * standing between them and the content.
 *
 * This is why it is not `motion`'s `whileInView`, which starts hidden in the
 * DOM and decides afterwards whether to show. It is also why this page carries
 * no motion dependency at all: every animation here is opacity, transform and
 * text slicing, and 40KB for that is the wrong trade.
 *
 * 4px of blur, not the hero's 8px. The hero entrance happens once and can be
 * heavier; this runs a dozen times down the page and has to stay cheap. */
export const Reveal = ({
  children,
  className,
  delay = 0,
  as = "div",
}: RevealProps) => {
  const ref = useRef<HTMLElement | null>(null);
  const [hidden, setHidden] = useState(false);
  // Widened deliberately: a union of intrinsic tags makes React intersect
  // their ref types, which no single element can satisfy.
  const Component = as as ElementType;

  useEffect(() => {
    const el = ref.current;
    if (!el || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return;
    }

    // Anything already on screen stays put. Hiding it now would flash.
    if (el.getBoundingClientRect().top < window.innerHeight * 0.9) {
      return;
    }

    setHidden(true);

    const reveal = () => setHidden(false);
    const safety = setTimeout(reveal, SAFETY_MS);
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          reveal();
          observer.disconnect();
          clearTimeout(safety);
        }
      },
      { rootMargin: "-80px" }
    );
    observer.observe(el);

    return () => {
      clearTimeout(safety);
      observer.disconnect();
    };
  }, []);

  const ease = "cubic-bezier(0.25, 1, 0.5, 1)";

  return (
    <Component
      className={className}
      ref={ref}
      style={{
        filter: hidden ? "blur(4px)" : "blur(0px)",
        opacity: hidden ? 0 : 1,
        transform: hidden ? "translateY(8px)" : "translateY(0)",
        transition: hidden
          ? "none"
          : `filter 0.65s ${ease} ${delay}s, opacity 0.65s ${ease} ${delay}s, transform 0.65s ${ease} ${delay}s`,
      }}
    >
      {children}
    </Component>
  );
};
