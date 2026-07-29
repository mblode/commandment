// Served at /commandment/robots.txt via basePath. Crawlers only read robots.txt
// from a host root, so blode.co/robots.txt governs the proxied path; this file is
// what commandment.blode.co resolves to, since that subdomain 308s to
// blode.co/commandment and both Google and Search Console follow the redirect.
//
// AI-open on purpose: crawl, index, ground and train are all permitted, so a
// single `*` group states the whole policy. No `Content-Signal:` line: signals
// are a reservation mechanism, so silence already means no restriction is
// expressed, and an all-yes signal only adds an unknown-directive warning in
// Search Console.
//
// No `Sitemap:` line: this zone does not publish one.
const body = `User-agent: *
Allow: /
`;

export const dynamic = "force-static";

export const GET = () =>
  new Response(body, {
    headers: {
      "Cache-Control": "public, max-age=3600",
      "Content-Type": "text/plain; charset=utf-8",
    },
  });
