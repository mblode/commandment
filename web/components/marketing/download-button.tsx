import { cn } from "@/lib/utils";

/** The one action on the page, so it looks the same in both places it appears
 * and the label never drifts between them.
 *
 * `outline-offset-4` is kept for visual separation, not for contrast. An earlier
 * version of this comment claimed the ring measured ~3:1 on the pill and 4.4:1
 * on the canvas, so the offset moved it somewhere safer. Measured, it is the
 * other way round: `--ring` in dark is `oklch(0.58 0.21 268)`, which is 4.51:1
 * against the white pill and 3.77:1 against the `#1c1c1e` canvas. The offset
 * moves the ring to the *weaker* of the two surfaces.
 *
 * It stays anyway. Both surfaces clear the 3:1 that WCAG 1.4.11 asks of a focus
 * indicator, and a ring drawn tight against a white pill on a near-black page
 * reads as a border on the button rather than as focus. The gap is what makes it
 * legible as a state. The number was wrong; the decision was not. */
export const DownloadButton = ({
  className,
  href,
}: {
  className?: string;
  href: string;
}) => (
  <a
    className={cn(
      "inline-flex items-center gap-[7px] rounded-lg bg-white px-4 py-2.5 font-semibold text-black text-sm hover:opacity-80 focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-4 active:opacity-60",
      className
    )}
    href={href}
  >
    <svg
      aria-hidden="true"
      className="relative -top-px"
      fill="currentColor"
      height="14"
      viewBox="0 0 814 1000"
      width="12"
    >
      <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57.8-155.5-127.4c-58.3-81.8-105.3-209.2-105.3-330.3 0-194.3 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8.6 15.7 1.3 18.2 2.6.6 6.4 1.3 10.2 1.3 45.4 0 103.5-30.4 139.5-71.4z" />
    </svg>
    Download for macOS
  </a>
);
