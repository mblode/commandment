"use client";
"use no memo";

import { useEffect, useRef, useState } from "react";

/** Drives a looping mock animation as a step counter. Copied from convene.
 *
 * Two things every mock needs, and neither is free:
 * - it stops advancing while scrolled out of view, so several mocks don't all
 *   run timers at once, and
 * - it parks on `reducedStep` and never ticks when the visitor has asked for
 *   reduced motion, so the frame they see is a deliberate one rather than
 *   whichever frame the loop happened to be on.
 *
 * `reducedStep` must always be the *finished* frame, never step 0. A reader on
 * reduced motion is owed the outcome the animation was going to show them, not
 * the empty state it starts from. The same value is what the server renders,
 * so first paint is a full mock rather than a box with nothing in it — which
 * also keeps it out of the running as an empty LCP candidate.
 *
 * `active` is the same condition, exposed so CSS keyframe loops (a level meter,
 * a caret) can be switched off under the same rules. A CSS animation keeps
 * burning compositor time off-screen otherwise.
 */
export const useMockClock = ({
  intervalMs,
  steps,
  reducedStep,
}: {
  intervalMs: number;
  steps: number;
  reducedStep: number;
}) => {
  const ref = useRef<HTMLDivElement | null>(null);
  const [step, setStep] = useState(reducedStep);
  const [reduced, setReduced] = useState(false);
  const [inView, setInView] = useState(false);

  useEffect(() => {
    const query = window.matchMedia("(prefers-reduced-motion: reduce)");
    const apply = () => {
      setReduced(query.matches);
      if (query.matches) {
        setStep(reducedStep);
      }
    };
    apply();
    query.addEventListener("change", apply);
    return () => query.removeEventListener("change", apply);
  }, [reducedStep]);

  useEffect(() => {
    const el = ref.current;
    if (!el) {
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => setInView(entry.isIntersecting),
      {
        threshold: 0.15,
      }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (reduced || !inView) {
      return;
    }
    const timer = setInterval(
      () => setStep((current) => (current + 1) % steps),
      intervalMs
    );
    return () => clearInterval(timer);
  }, [inView, intervalMs, reduced, steps]);

  return { active: inView && !reduced, reduced, ref, step };
};
