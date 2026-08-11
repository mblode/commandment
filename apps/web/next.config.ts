import type { NextConfig } from "next";

const posthogOrigin = process.env.NEXT_PUBLIC_POSTHOG_HOST ?? "";

const contentSecurityPolicy = [
  "default-src 'self'",
  // 'unsafe-eval' only in dev: Turbopack's HMR runtime needs it. The site
  // ships no eval in production. PostHog lazy-loads its extra bundles from
  // the reverse-proxy origin, so that origin needs script-src and connect-src.
  `script-src 'self' 'unsafe-inline' ${posthogOrigin}${
    process.env.NODE_ENV === "development" ? " 'unsafe-eval'" : ""
  }`,
  `connect-src 'self' ${posthogOrigin}`,
  "img-src 'self' data:",
  "style-src 'self' 'unsafe-inline'",
  "font-src 'self'",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'self'",
  "upgrade-insecure-requests",
].join("; ");

const securityHeaders = [
  { key: "Content-Security-Policy", value: contentSecurityPolicy },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "X-Frame-Options", value: "SAMEORIGIN" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-DNS-Prefetch-Control", value: "on" },
  {
    key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload",
  },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), payment=()",
  },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  { key: "Cross-Origin-Resource-Policy", value: "same-origin" },
];

/** Social cards and manifest icons are fetched by other origins, so they need
 * a looser CORP than the catch-all supplies. Override only this key and let
 * the catch-all provide the rest. */
const crossOriginResource = [
  { key: "Cross-Origin-Resource-Policy", value: "cross-origin" },
];

const nextConfig: NextConfig = {
  assetPrefix: "/commandment",
  basePath: "/commandment",
  experimental: { turbopackRustReactCompiler: true },
  headers() {
    // Every matching rule applies in array order and a later one wins per
    // header key, so the catch-all has to come FIRST and the per-route
    // overrides after it. With the catch-all last it silently reinstates
    // `same-origin` on the shareable assets below.
    //
    // ":path*", not "(.*)": under a basePath the latter compiles to
    // "/commandment/(.*)", which needs at least one segment and so skips the
    // landing page itself. ":path*" matches zero segments too.
    return Promise.resolve([
      { headers: securityHeaders, source: "/:path*" },
      { headers: crossOriginResource, source: "/opengraph-image" },
      { headers: crossOriginResource, source: "/web-app-manifest-:size.png" },
    ]);
  },
  reactCompiler: true,
  redirects() {
    return Promise.resolve([
      {
        basePath: false,
        destination: "https://blode.co/commandment",
        has: [{ type: "host" as const, value: "commandment.blode.co" }],
        permanent: true,
        source: "/",
      },
      {
        basePath: false,
        destination: "https://blode.co/commandment/:path*",
        has: [{ type: "host" as const, value: "commandment.blode.co" }],
        permanent: true,
        source: "/:path*",
      },
    ]);
  },
};

export default nextConfig;
