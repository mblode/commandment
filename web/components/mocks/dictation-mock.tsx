"use client";
"use no memo";

import { useMockClock } from "@/components/mocks/use-mock-clock";
import { cn } from "@/lib/utils";

/**
 * The hero demonstration: where the text goes.
 *
 * Every voice product shows you a waveform. A waveform proves the microphone
 * works, which nobody doubts. The claim this app actually makes is that the text
 * lands *at your cursor, in the app you were already in* — so the app being
 * typed into has to be in the frame. That is the whole reason this is two
 * stacked surfaces rather than a single pretty menu-bar popover.
 *
 * Three details do the work, and each was chosen over a more obvious one:
 *
 * 1. Words arrive one at a time, not characters. A per-character reveal is the
 *    typewriter effect and it reads as *typing*, which is the thing the product
 *    replaces. Whole words appearing at once is what dictation actually looks
 *    like.
 * 2. The last word sits grey for one beat and then resolves to full ink on
 *    release. That is the interim-to-final transition every speech recogniser
 *    has, and it is the single detail that stops this reading as a paste.
 * 3. The level meter is seven bars driven by one CSS keyframe with a per-bar
 *    `--bar-delay`, gated on the clock's `active`. Its `animation-play-state`
 *    follows the same in-view and reduced-motion rules as the step counter, so
 *    it is not still burning compositor time three screens up the page.
 *
 * No `motion` dependency: opacity, transform, and slicing an array. The frame
 * has a fixed height sized to its tallest state, because a mock that grows as
 * lines arrive is the most likely source of layout shift on this page.
 */

const WORDS = [
  "Can",
  "you",
  "send",
  "me",
  "the",
  "deck",
  "before",
  "standup",
  "tomorrow?",
];

/** Words visible at each step. Index is the step; the plateau at the end is the
 * hold, so the finished sentence is on screen for a third of the loop rather
 * than flashing past. */
const REVEAL = [0, 0, 0, 2, 3, 5, 6, 7, 9, 9, 9, 9];
const STEPS = REVEAL.length;

/** Recording runs from the keypress to the release. */
const PRESS_STEP = 2;
const RELEASE_STEP = 9;

/** The frame the server renders, and the frame a reduced-motion reader is left
 * on: the finished sentence, typed and final. Never step 0 — the outcome is the
 * thing worth showing, not the empty state it starts from. */
const RESTING_STEP = 10;

const BAR_HEIGHTS = [40, 70, 100, 55, 85, 45, 65];

export const DictationMock = () => {
  const { active, ref, step } = useMockClock({
    intervalMs: 400,
    reducedStep: RESTING_STEP,
    steps: STEPS,
  });

  const recording = step >= PRESS_STEP && step < RELEASE_STEP;
  const shown = REVEAL[step] ?? 0;
  const settled = step >= RELEASE_STEP;

  return (
    <div className="select-none" ref={ref}>
      {/* Menu bar. Right-aligned status items, the way the real one sits. */}
      <div className="flex items-center justify-end gap-3 border-white/5 border-b bg-surface-0/80 px-3 py-1.5">
        <div className="flex h-3.5 items-end gap-[2px]">
          {recording ? (
            BAR_HEIGHTS.map((height, index) => (
              <span
                className={cn(
                  "w-[2px] origin-bottom rounded-full bg-ink",
                  active && "animate-[meter_620ms_ease-in-out_infinite]"
                )}
                key={height}
                style={{
                  animationDelay: `${index * 70}ms`,
                  height: `${height}%`,
                }}
              />
            ))
          ) : (
            /* The resting glyph the meter grows out of. */
            <span className="mb-[1px] h-2.5 w-[3px] rounded-full bg-ink-subtle" />
          )}
        </div>
        <span className="font-mono text-[10px] text-ink-subtle tabular-nums">
          9:41
        </span>
      </div>

      {/* The ordinary app the text lands in. Deliberately mundane — the point is
          that it is not this app's own window. */}
      <div className="px-4 pt-4 pb-5 sm:px-6 sm:pt-6 sm:pb-8">
        <div className="raised rounded-xl bg-surface-2">
          <div className="border-white/5 border-b px-3 py-2">
            <p className="font-medium text-[11px] text-ink-subtle">
              Untitled — Notes
            </p>
          </div>
          {/* Fixed height, sized to the tallest state. The sentence wraps to two
              lines on narrow viewports and must not push the frame open. */}
          <div className="min-h-[5.5rem] px-3 py-3 sm:min-h-[5rem]">
            <p className="text-pretty text-ink text-sm leading-relaxed sm:text-base">
              {WORDS.slice(0, shown).map((word, index) => {
                const isLast = index === shown - 1;
                /* Interim text: the recogniser's best guess so far, not yet
                   committed. Grey until the release commits it. */
                const interim = !settled && isLast;
                return (
                  <span
                    className={cn(
                      "transition-colors duration-200",
                      interim ? "text-ink-subtle" : "text-ink"
                    )}
                    key={word}
                  >
                    {word}{" "}
                  </span>
                );
              })}
              {/* Caret. Sits after the words while dictating, blinks when idle. */}
              <span
                className={cn(
                  "ml-px inline-block h-[1.1em] w-[2px] translate-y-[0.2em] rounded-full bg-ink/80",
                  active &&
                    !recording &&
                    "animate-[caret_1.1s_steps(1)_infinite]"
                )}
              />
            </p>
          </div>
        </div>

        {/* The chord, held down while recording. */}
        <div className="mt-4 flex items-center gap-2">
          <span
            className={cn(
              "raised inline-flex min-w-[1.75em] items-center justify-center rounded-md px-1.5 py-1 font-medium text-xs leading-none transition-all duration-150",
              recording
                ? "translate-y-px bg-surface-3 text-ink"
                : "bg-surface-2 text-ink-muted"
            )}
          >
            ⌥
          </span>
          <span
            className={cn(
              "raised inline-flex min-w-[1.75em] items-center justify-center rounded-md px-1.5 py-1 font-medium text-xs leading-none transition-all duration-150",
              recording
                ? "translate-y-px bg-surface-3 text-ink"
                : "bg-surface-2 text-ink-muted"
            )}
          >
            D
          </span>
          <span className="ml-1 text-ink-faint text-xs">
            {recording ? "Listening" : "Hold to dictate"}
          </span>
        </div>
      </div>
    </div>
  );
};
