import Image from "next/image";
import { siteConfig } from "@/lib/config";
import avatarSm from "@/public/avatar-sm.png";

export const SiteFooter = ({ version }: { version: string }) => (
  <footer className="flex flex-col items-center justify-center gap-2 px-6 pt-16 pb-8 text-ink-subtle text-sm">
    {/*
      blode.co and blode.co/projects are this same origin behind a rewrite, so
      both are internal links: same tab, and no rel="noopener noreferrer", which
      only means something cross-origin. The projects link is the edge back to
      the hub, without which this zone is a dead end for crawlers and readers.
      See blode-co/apps/web/.claude/knowledge/zone-conventions.md.

      Structure and copy are allmd's footer, the canonical one. Only the colour
      tokens differ: this page paints on `--color-canvas` with the Apple grey
      `ink` scale, so `text-muted-foreground` would read wrong here.
    */}
    <div className="flex max-w-full flex-wrap items-center justify-center gap-1">
      Crafted by
      <a
        className="flex items-center gap-2 rounded-full py-1.5 pr-2.5 pl-1.5 transition-colors hover:text-ink focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
        href={siteConfig.links.author}
        rel="author"
      >
        {/*
          Decorative, so alt="". The link's own text already reads "Matthew
          Blode"; any alt here makes the accessible name "Matthew Blode Matthew
          Blode". zone-conventions.md Rule 1.
        */}
        <Image
          alt=""
          className="rounded-full"
          height={20}
          loading="lazy"
          src={avatarSm}
          width={20}
        />
        Matthew Blode
      </a>
    </div>
    <div className="flex max-w-full flex-wrap items-center justify-center gap-2 text-ink-faint">
      {/*
        No version, no separator: the middot only exists to divide two things.
        The tag already carries its own "v", unlike the canonical footer which
        prefixes a bare package version.
      */}
      {version ? (
        <>
          <span className="text-ink-subtle">{version}</span>
          <span aria-hidden="true">·</span>
        </>
      ) : null}
      <a
        className="text-ink-subtle transition-colors hover:text-ink focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
        href={siteConfig.links.github}
        rel="noopener noreferrer"
        target="_blank"
      >
        GitHub
      </a>
    </div>
  </footer>
);
