import type { CSSProperties } from "react";

import { cn } from "@/lib/utils";

/**
 * A small, static adaptation of react-components' GradualBlur. The original
 * component supports responsive dimensions, hover state and scroll observers;
 * this page only needs the material edge, so five masked backdrop layers do
 * the same job without a client boundary.
 */
export const EdgeBlur = ({ className }: { className?: string }) => (
  <div
    aria-hidden="true"
    className={cn(
      "pointer-events-none absolute inset-x-0 h-12 overflow-hidden",
      className
    )}
  >
    {Array.from({ length: 5 }, (_, index) => {
      const start = index * 20;
      const end = Math.min(100, start + 40);
      const style = {
        backdropFilter: `blur(${(index + 1) * 1.2}px)`,
        maskImage: `linear-gradient(to bottom, transparent ${start}%, black ${start + 20}%, transparent ${end}%)`,
        WebkitMaskImage: `linear-gradient(to bottom, transparent ${start}%, black ${start + 20}%, transparent ${end}%)`,
      } satisfies CSSProperties;

      return <span className="absolute inset-0" key={start} style={style} />;
    })}
  </div>
);
