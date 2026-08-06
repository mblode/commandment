import { ChevronRight } from "lucide-react";

import { faq } from "@/lib/faq";

/**
 * Native `<details>`, so the copy is in the DOM and crawlable while the page
 * stays one screen tall. No JS, and keyboard and screen reader behaviour comes
 * free. `<summary>` is allowed to hold heading content, which is how the h2
 * survives being the toggle.
 */
export const FaqDisclosure = () => (
  <details className="group mt-16 border-white/10 border-t pt-6">
    <summary className="flex cursor-pointer list-none items-center gap-2 rounded-sm focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-4 [&::-webkit-details-marker]:hidden">
      <ChevronRight
        aria-hidden="true"
        className="size-4 shrink-0 opacity-60 transition-transform duration-200 group-open:rotate-90"
      />
      <h2 className="font-semibold text-base text-ink-muted">
        Common questions
      </h2>
    </summary>

    <div className="mt-6 space-y-6">
      {faq.map((entry) => (
        <div key={entry.question}>
          <h3 className="font-semibold text-base text-ink-muted">
            {entry.question}
          </h3>
          <p className="mt-1.5 text-pretty text-base text-ink-subtle">
            {entry.answer}
          </p>
          {entry.code ? (
            <pre className="mt-2.5 overflow-x-auto rounded-lg bg-white/5 px-3 py-2 text-ink-muted text-sm">
              <code>{entry.code}</code>
            </pre>
          ) : null}
        </div>
      ))}
    </div>
  </details>
);
