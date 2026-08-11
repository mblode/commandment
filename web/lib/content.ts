import { siteConfig } from "@/lib/config";

/**
 * Every word on the page that is not markup lives here.
 *
 * Two reasons, both of which have already cost somebody an afternoon somewhere
 * in this fleet. The first is that a claim in JSX cannot be asserted by a test,
 * so the answer paragraph drifts out of its word band and the FAQ stops matching
 * the JSON-LD and nobody notices until a rich result quietly stops appearing.
 * The second is that `dateModified` derived from a build clock claims every page
 * changed on every deploy, which is a freshness signal that means nothing.
 *
 * So: constants here, `lib/content.test.ts` holds them to their contracts, and
 * the page is markup.
 */

/**
 * The liftable answer. An answer engine will quote this paragraph or none, so it
 * has to stand alone with no antecedent — no "it", no "the app", no reference to
 * the headline above it.
 *
 * 40-60 words is the band, asserted in `lib/content.test.ts`. Under 40 and it
 * omits the qualifier that makes it true; over 60 and it gets truncated
 * mid-clause, which is worse than being short.
 */
export const ANSWER_QUESTION = "What is Commandment?";

export const ANSWER_TEXT =
  "Commandment is a free macOS menu bar app that turns speech into text in any app. Hold Option+D and talk. The audio goes to OpenAI on your own API key, and the transcript lands at your cursor. There is no subscription. You pay OpenAI for the seconds you dictate.";

export const ANSWER_NOTE =
  "Free and MIT licensed. Requires macOS 15.2 and an OpenAI API key.";

/**
 * Bumped when the answer, an FAQ answer, or a comparison claim changes. Not when
 * a class name moves.
 *
 * Hand-written rather than `new Date()` or a git mtime, and the reason is in
 * both of those alternatives: a build clock marks the page as changed on every
 * deploy, and an mtime marks it as changed when a formatter touches it. Three
 * surfaces read this one constant — the visible `<time>`, `WebPage.dateModified`
 * and `sitemap.ts` — so they cannot disagree with each other.
 */
export const PAGE_UPDATED = "2026-08-11";

export const PAGE_UPDATED_LABEL = "11 August 2026";

/** The fold. The h1 is a claim carrying the words somebody would search for; it
 * is deliberately not phrased as a question, because a page whose headline is a
 * typed query reads as bait to a human and gains nothing with a machine that is
 * already reading the h2 below it. */
export const HERO = {
  headline:
    "Voice dictation for macOS that types into any app, on your own OpenAI key.",
  subhead: "Hold Option+D, talk, let go. The text is already in the field.",
} as const;

/*
 * There is no problem block, and that is deliberate.
 *
 * Somebody who searched "mac dictation no subscription" arrived because they
 * already have the problem. Naming it back to them is the most skippable block
 * on the page, and neither of the landing pages this one is measured against
 * (viteplus.dev, ultracite.ai) has one.
 *
 * Removing it also took out the page's only unsourced claim: that Apple
 * Dictation "mishears names and stops mid-sentence". It was not moved anywhere,
 * and it should not come back, because it is not just unsourced — Apple's own
 * documentation contradicts it. support.apple.com/guide/mac-help/mh40584/mac,
 * read 11 Aug 2026: "You can dictate text of any length without a timeout.
 * Dictation stops automatically when no speech is detected for 30 seconds."
 * Stopping after half a minute of silence is not cutting out mid-sentence.
 *
 * That leaves a real hole, and the fix is a concession rather than a
 * replacement claim. Read the Apple column of the table below and Apple wins or
 * ties on price, account, on-device processing and offline use; the only row
 * Commandment takes outright is the licence. There is no benchmark on hand that
 * would let us claim better accuracy, so the page does not claim it. The
 * honesty paragraph now tells the reader to keep Apple Dictation if it already
 * works for them, which is both true and the version of this a reader will
 * still trust after they go and check.
 */
/*
 * There is no lede paragraph above the steps, and that is deliberate too.
 *
 * It used to carry five sentences, and every fact in them was already on the
 * page: the shortcut is in the hero and in `PROOF.rows`, the 24 kHz Realtime
 * path is in `PROOF.rows` and in `AUDIO_ROUTE`, the Keychain is in `PROOF.rows`
 * and the key-safety FAQ, and the Accessibility prompt with its clipboard
 * fallback is the second half of `AUDIO_ROUTE`. A paragraph that says the steps
 * before the steps do is the block a reader skips, so it went rather than being
 * rewritten.
 */
export const SOLUTION = {
  heading: "How does Commandment work?",
  steps: [
    {
      body: "Anywhere. There is no window to find first.",
      title: "Press Option+D.",
    },
    {
      body: "The menu bar icon shows it is listening.",
      title: "Say the thing.",
    },
    {
      body: "The text appears where your cursor already was.",
      title: "Press it again.",
    },
  ],
} as const;

/**
 * The two blockers that stop an install, in one section.
 *
 * They were two sections with two headings and ninety words between them, and
 * the second heading ("Do I need to grant Accessibility permission?") bought a
 * whole section break for one paragraph that only ever said "only if you want
 * the text typed for you". The audio question is the one people actually type,
 * so it keeps the heading.
 *
 * Both anchors survive on the merged section. `#audio` and `#accessibility`
 * were each published as an `acceptedAnswer.url` at some point, so dropping
 * either one points a live link at nothing.
 */
export const AUDIO_ROUTE = {
  accessibilityId: "accessibility",
  body: "Your microphone, then Commandment, then OpenAI at 24 kHz mono on your own key. A temporary WAV sits in the system temp directory, overwritten by the next take. There is no Commandment server. Accessibility permission only lets it type for you. Decline it and the transcript goes to your clipboard.",
  heading: "Where does my audio go?",
  id: "audio",
} as const;

/**
 * The comparison.
 *
 * MacWhisper is missing on purpose. Its promise is that audio never leaves the
 * Mac, which is exactly the thing Commandment does not do, so a row for it hands
 * the reader a reason to buy something else with no counterweight in the same
 * row. It is named in `COMPARISON.honesty` instead, where the same fact reads as
 * candour rather than as a lost argument.
 *
 * `COMPARED_ON` is not decoration. Every competing product here ships often, and
 * a table with no date on it is a claim about the present tense that nobody has
 * checked. Re-verify each cell against the vendor's own pricing page before
 * changing this date; never carry a price forward on memory.
 *
 * That is not hypothetical advice. The first draft of this table was written
 * from notes rather than from the vendors' pages, and an audit on 11 Aug 2026
 * found three cells flatly wrong and four that stacked the deck:
 *
 * - Superwhisper was listed as requiring an account. Its own page names "No
 *   account required" as an advantage it holds over Wispr Flow.
 * - Wispr Flow was listed as "Subscription". It has a $0/mo plan with 2,000
 *   words a week on desktop.
 * - Apple Dictation was listed as requiring an Apple ID, which no Apple page
 *   supports; their privacy page says the request identifier is deliberately
 *   not tied to an Apple Account.
 *
 * Every one of those errors ran in our favour, which is the tell. A reader who
 * clicks one cell and finds a free tier we called a subscription stops
 * believing the other five rows, including the true ones — so an overstated
 * table costs more than a conceded row ever does.
 */
export const COMPARED_ON = "11 August 2026";

export const COMPARISON = {
  columns: ["Commandment", "Wispr Flow", "Superwhisper", "Apple Dictation"],
  heading:
    "How does Commandment compare to Wispr Flow, Superwhisper, and Apple Dictation?",
  /* Three concessions, one per competitor, and none of them may be softened or
   * dropped for length. The audit that put them here found three cells wrong in
   * our favour, and a table whose prose concedes nothing reads as the same kind
   * of document. What went, when this was halved, was only what the table below
   * already says in a cell: that Superwhisper needs no account (row two), and
   * that Commandment hands back a transcript rather than prose (row five). */
  honesty:
    "Keep Apple's dictation if it already works: free, on device for many languages, no network needed. For local-only that does more, run MacWhisper or Superwhisper, both free to start. Wispr Flow rewrites your rambling into finished prose, Commandment does not.",
  rows: [
    {
      label: "What you pay",
      values: [
        "Free app, pay OpenAI per second dictated",
        "Free tier, then subscription",
        "Free tier, subscription, or one-time",
        "Included with macOS",
      ],
    },
    {
      label: "Account required",
      values: ["None", "Yes", "None", "None"],
    },
    {
      label: "Where audio is transcribed",
      values: [
        "OpenAI, on your own key",
        "The vendor's servers",
        "On device, or the vendor's",
        "On device for many languages",
      ],
    },
    {
      label: "Works with no internet",
      values: [
        "No",
        "No",
        "Yes, with a local model",
        "Yes, for on-device languages",
      ],
    },
    {
      label: "Rewrites what you said",
      values: ["No, you get the transcript", "Yes", "Yes", "No"],
    },
    {
      label: "Source code",
      values: ["MIT on GitHub", "Closed", "Closed", "Closed"],
    },
  ],
} as const;

/**
 * Proof.
 *
 * Every row is a fact somebody can check, and every row carries the link they
 * would check it with. There are no stars, no download counts and no
 * testimonials here, and that is a decision rather than an omission: this
 * project has four GitHub stars, and a page that renders "4" next to a download
 * button has spent its credibility to say nothing. diffhub cut its own star
 * count for the same reason — a release count is a signal about the project, not
 * an answer about the product.
 *
 * Note what is NOT claimed: the app is notarised but it is *not* sandboxed —
 * `Commandment/Commandment.entitlements` carries no `com.apple.security.app-sandbox`
 * key. Saying "sandboxed and notarised" would have been one word of polish and
 * one false statement.
 */
const REPO = siteConfig.links.github;

export const PROOF = {
  /* The Melbourne credit that used to open this line now lives once, in the
   * "Who makes Commandment?" FAQ entry, which is the question a reader asks it
   * under. What is left is the part no other block says. */
  closing:
    "No case studies and no customer logos, because there is no roster yet.",
  heading: "What is shipped today?",
  /* Two facts moved in here when the FAQ was halved, because each was the only
   * place on the page that carried it: language selection came from the
   * "Can it transcribe languages other than English?" entry, and launch at
   * login came from "Is there a window to manage?". Both landed on the row that
   * already links to the code they are true of. */
  rows: [
    {
      detail: "MIT, so fork it and ship it.",
      href: `${REPO}/blob/main/LICENSE`,
      term: "Licence",
    },
    {
      detail: "Developer ID signed and notarised on every tagged release.",
      href: `${REPO}/blob/main/.github/workflows`,
      term: "Notarised",
    },
    {
      detail: "The macOS Keychain, never a config file.",
      href: `${REPO}/blob/main/Commandment/KeychainManager.swift`,
      term: "Your OpenAI key",
    },
    {
      detail:
        "24 kHz mono to the Realtime API via gpt-4o-mini-transcribe, in a language you set or it detects.",
      href: `${REPO}/blob/main/Commandment/RealtimeTranscriptionClient.swift`,
      term: "Audio path",
    },
    {
      detail:
        "Option+D records, Option+Shift+D opens Settings, both rebindable, plus launch at login.",
      href: `${REPO}/blob/main/Commandment/HotkeyManager.swift`,
      term: "Default shortcuts",
    },
    {
      detail: "macOS 15.2 or later, Apple silicon or Intel.",
      href: `${REPO}/releases/latest`,
      term: "Requirements",
    },
  ],
} as const;

export const FAQ_HEADING = "What do people ask before installing?";

export const CLOSING = {
  heading: "Ready to stop typing it out?",
  lede: "Free, MIT licensed, no account. Speak the next thing instead of typing it.",
} as const;

export const BREW_COMMAND = "brew install --cask mblode/tap/commandment";
