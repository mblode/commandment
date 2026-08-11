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
    <div className="select-none bg-night text-night-ink" ref={ref}>
      <div className="flex items-center justify-between border-white/8 border-b px-4 py-2 sm:px-5">
        <p className="font-medium text-night-muted text-sm">Commandment</p>
        <div className="flex items-center gap-3">
          <div className="flex h-3.5 items-end gap-[2px]">
            {recording ? (
              BAR_HEIGHTS.map((height, index) => (
                <span
                  className={cn(
                    "w-[2px] origin-bottom rounded-full bg-signal",
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
              <span className="mb-px h-2.5 w-[3px] rounded-full bg-night-muted" />
            )}
          </div>
          <p className="font-mono text-night-muted text-xs tabular-nums">
            9:41
          </p>
        </div>
      </div>

      <div className="p-4 sm:p-6 lg:p-8">
        <div className="overflow-hidden rounded-[min(1.5vw,1rem)] bg-night-raised outline-1 outline-white/10 -outline-offset-1">
          <div className="flex items-center gap-3 border-white/8 border-b px-4 py-3">
            <div aria-hidden="true" className="flex gap-1.5">
              <span className="size-2.5 rounded-full bg-signal" />
              <span className="size-2.5 rounded-full bg-white/15" />
              <span className="size-2.5 rounded-full bg-white/15" />
            </div>
            <p className="font-medium text-night-muted text-sm">
              Untitled note
            </p>
          </div>

          <div className="min-h-40 p-5 sm:min-h-48 sm:p-7 lg:min-h-52 lg:p-9">
            <p className="max-w-[32ch] text-pretty text-2xl text-night-ink tracking-[-0.025em] sm:text-3xl">
              {WORDS.slice(0, shown).map((word, index) => {
                const isLast = index === shown - 1;
                const interim = !settled && isLast;

                return (
                  <span
                    className={interim ? "text-night-muted" : "text-night-ink"}
                    key={word}
                  >
                    {word}{" "}
                  </span>
                );
              })}
              <span
                className={cn(
                  "ml-px inline-block h-[1.05em] w-[3px] translate-y-[0.16em] rounded-full bg-signal",
                  active &&
                    !recording &&
                    "animate-[caret_1.1s_steps(1)_infinite]"
                )}
              />
            </p>
          </div>
        </div>

        <div className="mt-4 flex items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            {["⌥", "D"].map((key) => (
              <span
                className={cn(
                  "raised inline-flex min-w-8 items-center justify-center rounded-md bg-night-high px-2 py-1.5 font-medium text-sm",
                  recording && "translate-y-px text-signal"
                )}
                key={key}
              >
                {key}
              </span>
            ))}
          </div>
          <div className="flex items-center gap-2">
            <span
              className={cn(
                "size-2.5 rounded-full bg-night-muted",
                recording && "signal-pulse bg-signal"
              )}
            />
            <p className="font-mono text-night-muted text-sm">
              {recording ? "Listening" : "Hold to dictate"}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
