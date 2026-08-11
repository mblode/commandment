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

export interface Release {
  downloadUrl: string;
  fileSizeMB: string;
  /** Empty when unknown, so the page omits it rather than asserting a stale tag. */
  version: string;
}

/**
 * Pulled out of `app/page.tsx` so the layout's `SoftwareApplication` node can
 * publish the same `softwareVersion` the page renders. Two callers, one request:
 * `fetch` with identical arguments is deduplicated within a render pass, and
 * both share the one 3600s cache entry, so this costs nothing extra.
 *
 * A version asserted in the graph that disagrees with the version printed on the
 * page is the kind of mismatch nobody finds by looking, which is why this is
 * shared rather than typed twice.
 */
export async function getLatestRelease(): Promise<Release> {
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
