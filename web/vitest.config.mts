import { defineConfig } from "vitest/config";

/** `environment: "node"` on purpose. Every test here renders with
 * `renderToStaticMarkup` and asserts against the resulting string, because
 * server markup is the surface that matters: it is what a crawler, an answer
 * engine, and a reader with JS disabled actually receive. Asserting against a
 * hydrated DOM would pass on content none of them can see, which is the exact
 * failure these tests exist to catch. So there is no jsdom and no React
 * plugin — esbuild handles the TSX from `tsconfig.json`'s `jsx` setting. */
export default defineConfig({
  resolve: {
    alias: {
      "@": import.meta.dirname,
    },
  },
  test: {
    environment: "node",
    include: ["{app,components,lib}/**/*.test.{ts,tsx}"],
  },
});
