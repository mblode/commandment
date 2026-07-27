import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  assetPrefix: "/commandment",
  basePath: "/commandment",
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
