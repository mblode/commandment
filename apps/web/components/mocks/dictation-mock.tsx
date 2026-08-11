"use client";
"use no memo";

import { useMockClock } from "@/components/mocks/use-mock-clock";
import { cn } from "@/lib/utils";

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

const REVEAL = [0, 0, 0, 2, 3, 5, 6, 7, 9, 9, 9, 9];
const STEPS = REVEAL.length;
const PRESS_STEP = 2;
const RELEASE_STEP = 9;
const RESTING_STEP = 10;

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
      <div className="flex items-center justify-between border-white/10 border-b px-5 py-4 sm:px-6">
        <p className="font-medium text-night-muted text-sm">Untitled note</p>
        <p className="font-mono text-night-muted text-xs tabular-nums">9:41</p>
      </div>

      <div className="flex min-h-64 items-center px-6 py-10 sm:min-h-72 sm:px-8 lg:min-h-80 lg:px-10">
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
              active && !recording && "animate-[caret_1.1s_steps(1)_infinite]"
            )}
          />
        </p>
      </div>

      <div className="flex items-center justify-between gap-4 border-white/10 border-t px-5 py-4 font-mono text-sm sm:px-6">
        <p className={recording ? "text-signal" : "text-night-muted"}>⌥D</p>
        <div className="flex items-center gap-2 text-night-muted">
          <span
            className={cn(
              "size-2 rounded-full bg-night-muted",
              recording && "bg-signal"
            )}
          />
          <p>{recording ? "Listening" : "Hold Option+D"}</p>
        </div>
      </div>
    </div>
  );
};
