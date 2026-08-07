import Image from "next/image";
import { siteConfig } from "@/lib/config";
import avatarSm from "@/public/avatar-sm.png";

export const SiteFooter = ({ version }: { version: string }) => (
  <footer className="flex flex-col items-center justify-center gap-2 pt-16 pb-8 text-ink-subtle text-sm">
    {/*
      blode.co and blode.co/projects are this same origin behind a rewrite, so
      both are internal links: same tab, and no rel="noopener noreferrer", which
      only means something cross-origin. The projects link is the edge back to
      the hub, without which this zone is a dead end for crawlers and readers.
      See blode-co/apps/web/.claude/knowledge/zone-conventions.md.
    */}
    <div className="flex items-center gap-1">
      Crafted by
      <a
        className="flex items-center gap-2 rounded-full py-1.5 pr-2.5 pl-1.5 hover:text-ink focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
        href={siteConfig.links.author}
        rel="author"
      >
        <Image
          alt="Avatar of Matthew Blode"
          className="rounded-full"
          height={20}
          loading="lazy"
          src={avatarSm}
          width={20}
        />
        Matthew Blode
      </a>
    </div>
    <div className="flex items-center gap-2 text-ink-faint">
      {/* No version, no separator: the bullet only exists to divide two things. */}
      {version ? (
        <>
          <span className="text-ink-subtle">{version}</span> &bull;
        </>
      ) : null}
      <a
        className="text-ink-subtle hover:text-ink focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
        href="https://blode.co/projects"
      >
        All projects
      </a>{" "}
      &bull;
      <a
        className="text-ink-subtle hover:text-ink focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
        href={siteConfig.links.github}
        rel="noopener noreferrer"
        target="_blank"
      >
        GitHub
      </a>
    </div>
  </footer>
);
