import Image from "next/image";
import { siteConfig } from "@/lib/config";
import avatarSm from "@/public/avatar-sm.png";

export const SiteFooter = ({ version }: { version: string }) => (
  <footer className="flex flex-col items-center justify-center gap-2 bg-night px-6 pt-14 pb-8 text-night-muted text-sm">
    <div className="flex max-w-full flex-wrap items-center justify-center gap-1">
      By
      <a
        className="flex min-h-11 items-center gap-2 rounded-full py-1.5 pr-2.5 pl-1.5 hover:text-night-ink focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
        href={siteConfig.links.author}
        rel="author"
      >
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
    <div className="flex max-w-full flex-wrap items-center justify-center gap-2 text-night-muted">
      {version ? (
        <>
          <span className="text-night-muted tabular-nums">{version}</span>
          <span aria-hidden="true">·</span>
        </>
      ) : null}
      <a
        className="inline-flex min-h-11 items-center px-2 text-night-muted hover:text-night-ink focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-2"
        href={siteConfig.links.github}
        rel="noopener noreferrer"
        target="_blank"
      >
        GitHub
      </a>
    </div>
  </footer>
);
