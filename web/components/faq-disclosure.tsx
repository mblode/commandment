import { faq } from "@/lib/faq";

/**
 * A native accordion: one `<details>` per question, sharing a `name` so opening
 * one closes the rest the way `type="single"` does. Not the Blode UI Accordion,
 * deliberately. That component holds its panel children behind an `isOpen` state
 * that starts false and only flips after hydration, so every answer is absent
 * from the server HTML. Verified against the blode-ui docs build: 15
 * `accordion-trigger` slots present, 0 `accordion-content`. The answers are the
 * whole reason this section exists, and a FAQPage schema asserting text the page
 * does not serve reads as spam rather than as markup.
 *
 * Browsers without exclusive-accordion support treat these as six independent
 * toggles, which is a fine degradation. The open and close height animation
 * lives in globals.css via `::details-content`.
 */
export const FaqDisclosure = () => (
  <section className="mt-16 border-white/10 border-t pt-6">
    <h2 className="font-semibold text-base text-ink-muted">Common questions</h2>

    <div className="mt-2">
      {faq.map((entry) => (
        <details
          className="group border-white/10 border-b last:border-b-0"
          id={entry.id}
          key={entry.id}
          name="faq"
        >
          <summary className="flex cursor-pointer list-none items-start justify-between gap-4 rounded-sm py-4 focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2 [&::-webkit-details-marker]:hidden">
            <h3 className="font-semibold text-base text-ink-muted">
              {entry.question}
            </h3>

            {/*
              Plus that becomes a minus. Odd sizes (11px box, 1px bar) keep each
              bar's centred offset a whole number, so it does not straddle two
              pixels and render soft.
            */}
            <span
              aria-hidden="true"
              className="relative mt-1 size-[11px] shrink-0"
            >
              <span className="absolute top-1/2 left-0 h-px w-[11px] -translate-y-1/2 rounded-full bg-ink-faint" />
              <span className="absolute top-0 left-1/2 h-[11px] w-px -translate-x-1/2 rounded-full bg-ink-faint transition-transform duration-300 group-open:scale-y-0" />
            </span>
          </summary>

          <div className="pb-4">
            <p className="text-pretty text-base text-ink-subtle">
              {entry.answer}
            </p>
            {entry.code ? (
              <pre className="mt-2.5 overflow-x-auto rounded-lg bg-white/5 px-3 py-2 text-ink-muted text-sm">
                <code>{entry.code}</code>
              </pre>
            ) : null}
          </div>
        </details>
      ))}
    </div>
  </section>
);
