import { Download } from "lucide-react";

import { cn } from "@/lib/utils";

export const DownloadButton = ({
  className,
  href,
}: {
  className?: string;
  href: string;
}) => (
  <a
    className={cn(
      "inline-flex min-h-12 items-center gap-2.5 rounded-full bg-signal py-3 pr-5 pl-4 font-medium text-base text-paper outline-signal hover:bg-signal-deep focus-visible:outline-2 focus-visible:outline-offset-4 active:translate-y-px sm:min-h-11 sm:py-2.5 sm:text-sm",
      className
    )}
    href={href}
  >
    <Download aria-hidden="true" className="size-4 shrink-0 stroke-paper" />
    Download Commandment
  </a>
);
