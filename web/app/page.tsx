import Image from "next/image";

import { SiteFooter } from "@/components/site-footer";

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

async function getLatestRelease(): Promise<{
  downloadUrl: string;
  fileSizeMB: string;
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
      downloadUrl: dmg?.browser_download_url ?? "#",
      fileSizeMB: dmg ? `${(dmg.size / 1024 / 1024).toFixed(1)} MB` : "",
      version: release.tag_name ?? "v0.1.10",
    };
  } catch {
    return {
      downloadUrl: "https://github.com/mblode/commandment/releases/latest",
      fileSizeMB: "",
      version: "v0.1.10",
    };
  }
}

export default async function Page() {
  const { downloadUrl, fileSizeMB, version } = await getLatestRelease();

  return (
    <div className="relative flex min-h-dvh flex-col overflow-hidden bg-[#1c1c1e] font-sans">
      {/* Main content — left-aligned with clamped left padding */}
      <main className="relative z-10 mx-auto flex flex-1 flex-col items-start justify-center px-6 pt-16 text-left md:pt-0">
        {/* App icon */}
        <div>
          <Image
            alt="Commandment"
            className="rounded-[22%]"
            height={80}
            priority
            src="/commandment/app-icon.png"
            width={80}
          />
        </div>

        {/* Title */}
        <h1 className="mt-6 font-bold text-[#f5f5f7] text-[38px] leading-none tracking-[-0.035em]">
          Commandment
        </h1>

        {/* Subtitle */}
        <p className="mt-[10px] font-medium text-[#c5c5ca] text-[17px] tracking-normal">
          Voice to text, instantly.
        </p>

        {/* Description */}
        <p className="mt-5 font-light text-[#98989d] text-[14px] leading-[1.7]">
          Just press a shortcut and speak.
          <br />
          BYO OpenAI API key — no subscription required.
        </p>

        {/* Download row */}
        <div className="mt-7 inline-flex items-center gap-[14px]">
          <a
            className="inline-flex items-center gap-[7px] rounded-lg bg-white px-[18px] py-[9px] font-semibold text-[13px] text-black transition-opacity hover:opacity-80 active:opacity-60"
            href={downloadUrl}
          >
            <svg
              aria-hidden="true"
              fill="currentColor"
              height="14"
              style={{ position: "relative", top: "-1px" }}
              viewBox="0 0 814 1000"
              width="12"
            >
              <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57.8-155.5-127.4c-58.3-81.8-105.3-209.2-105.3-330.3 0-194.3 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8.6 15.7 1.3 18.2 2.6.6 6.4 1.3 10.2 1.3 45.4 0 103.5-30.4 139.5-71.4z" />
            </svg>
            Download for macOS
          </a>
          {fileSizeMB ? (
            <span className="font-normal text-[#636366] text-[13px]">
              {fileSizeMB}
            </span>
          ) : null}
        </div>

        {/* Version */}
        <span className="mt-3 text-[#636366] text-[12px]">
          {version} · Requires macOS 15
        </span>
      </main>

      <SiteFooter />
    </div>
  );
}
