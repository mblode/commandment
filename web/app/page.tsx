import Image from "next/image";

import { FaqDisclosure } from "@/components/faq-disclosure";
import { SiteFooter } from "@/components/site-footer";
import { ZoneBreadcrumb } from "@/components/zone-breadcrumb";

interface GitHubAsset {
  browser_download_url: string;
  name: string;
  size: number;
}

// Shape of an unvalidated GitHub API response, so every field is optional. The
// fetch below guards each access; declaring them required would make those
// guards look redundant while the runtime payload could still omit them.
interface GitHubRelease {
  assets?: GitHubAsset[];
  tag_name?: string;
}

/**
 * Where the download button points when the API gives us no `.dmg` asset. A
 * real page that lists every asset, rather than a version we have guessed.
 */
const RELEASES_URL = "https://github.com/mblode/commandment/releases/latest";

async function getLatestRelease(): Promise<{
  downloadUrl: string;
  fileSizeMB: string;
  /** Empty when unknown, so the page omits it rather than asserting a stale tag. */
  version: string;
}> {
  try {
    const res = await fetch(
      "https://api.github.com/repos/mblode/commandment/releases/latest",
      { next: { revalidate: 3600 } }
    );
    if (!res.ok) {
      throw new Error("Failed to fetch release");
    }
    const release: GitHubRelease = await res.json();
    const dmg = release.assets?.find((a) => a.name.endsWith(".dmg"));
    return {
      downloadUrl: dmg?.browser_download_url ?? RELEASES_URL,
      fileSizeMB: dmg ? `${(dmg.size / 1024 / 1024).toFixed(1)} MB` : "",
      version: release.tag_name ?? "",
    };
  } catch {
    return {
      downloadUrl: RELEASES_URL,
      fileSizeMB: "",
      version: "",
    };
  }
}

export default async function Page() {
  const { downloadUrl, fileSizeMB, version } = await getLatestRelease();

  return (
    <div className="isolate flex min-h-dvh flex-col bg-canvas font-sans">
      {/* Root page only, and matched word for word by the BreadcrumbList in
          lib/config.ts. Outside the vertically centred block so it stays at the
          top of the page rather than drifting with the hero. */}
      <div className="mx-auto w-full max-w-[62ch] px-6 pt-8">
        <ZoneBreadcrumb product="Commandment" />
      </div>

      <main className="flex flex-1 flex-col justify-center px-6 pt-10 pb-16">
        {/* One block, centred in the viewport, everything inside left-aligned.
            Margins live on these children rather than a gap, because the
            spacing between them is deliberately uneven. */}
        <div className="mx-auto w-full max-w-[62ch]">
          <Image
            alt="Commandment"
            className="rounded-[22%]"
            height={80}
            priority
            src="/commandment/app-icon.png"
            width={80}
          />

          <h1 className="mt-6 text-balance font-semibold text-4xl text-ink tracking-tight">
            Commandment
          </h1>

          <p className="mt-2.5 text-ink-muted text-lg">
            Voice to text, instantly.
          </p>

          <p className="mt-5 text-pretty text-base text-ink-subtle">
            Just press a shortcut and speak. Bring your own OpenAI API key, no
            subscription required. It needs macOS Accessibility permission to
            type into other apps.
          </p>

          {/* Download row */}
          <div className="mt-7 flex items-center gap-3.5">
            <a
              className="inline-flex items-center gap-[7px] rounded-lg bg-white px-4 py-2.5 font-semibold text-black text-sm hover:opacity-80 focus-visible:outline-2 focus-visible:outline-ring focus-visible:outline-offset-4 active:opacity-60"
              href={downloadUrl}
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
            {fileSizeMB ? (
              <p className="text-ink-faint text-sm">{fileSizeMB}</p>
            ) : null}
          </div>

          <p className="mt-3 text-ink-faint text-sm">
            {version ? `${version} · ` : ""}Requires macOS 15.2
          </p>

          {/*
            The answers people want before installing a menu bar app that
            listens to them: where the audio goes, and why it asks for
            Accessibility. Collapsed rather than cut, so the page stays one
            screen tall while the copy stays in the DOM.
          */}
          <FaqDisclosure />
        </div>
      </main>

      <SiteFooter version={version} />
    </div>
  );
}
