import { Download } from "lucide-react";

import { cn } from "@/lib/utils";

export const DownloadButton = ({
  className,
  href,
  tone = "primary",
}: {
  className?: string;
  href: string;
  tone?: "primary" | "secondary";
}) => (
  <a
    className={cn(
      "group/download inline-flex min-h-12 items-center gap-2.5 rounded-full py-3 pr-5 pl-4 font-medium text-base outline-ink hover:bg-signal-deep hover:text-paper focus-visible:outline-2 focus-visible:outline-offset-4 active:translate-y-px sm:min-h-11 sm:py-2.5 sm:text-sm",
      tone === "primary"
        ? "bg-signal text-ink"
        : "bg-transparent text-ink outline-1 -outline-offset-1",
      className
    )}
    href={href}
  >
    <Download
      aria-hidden="true"
      className="size-4 shrink-0 stroke-ink group-hover/download:stroke-paper"
    />
    Download Commandment
  </a>
);
