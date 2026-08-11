// Subsets the Glide webfonts from assets/fonts (full, as-delivered) into
// app/fonts (what ships). Adapted from donebear's scripts/subset-fonts.mjs,
// which this fleet has already proven: 430KB -> 219KB there, ~1.1s off mobile
// LCP.
//
// Why it matters here specifically. Every LCP element on all four blode.co
// product pages is *text*, so webfont delivery is not one input to LCP, it is
// the input. The 2026-08-11 production baseline measured ~421KB of font on
// every page — more bytes than the JavaScript on three of the four — sitting
// directly on the critical path, with no page scoring better than "needs
// improvement".
//
// They live under app/ rather than public/ because next/font emits its own
// hashed copy; a copy in public/ would republish the same face a second time at
// a guessable URL.
//
// Not part of `build` — it needs pyftsubset (fontTools), which is not a repo
// dependency and should not become one for something that runs when the source
// fonts change, which is approximately never. Run it by hand and commit the
// regenerated app/fonts/*.woff2:
//
//   pip install fonttools brotli
//   node scripts/subset-fonts.mjs
//
// Verify with `--check`, which reports sizes without writing.

import { execFileSync } from "node:child_process";
import { mkdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sourceDir = join(root, "assets/fonts");
const outDir = join(root, "app/fonts");

// Deliberately wider than the characters this page uses today. A subset cut to
// exactly the current copy is a trap: the first FAQ answer mentioning a
// colleague called Müller, or a price in €, renders as tofu, and nobody
// connects that to a build script they ran six months earlier.
//
// Full Latin-1 and Latin Extended-A cover European names. The punctuation
// ranges cover what typographic quotes and dashes need — this page ships
// `&rsquo;` in the comparison caption and em dashes throughout, and those live
// outside Basic Latin.
const UNICODES = [
  "U+0020-007E", // Basic Latin
  "U+00A0-00FF", // Latin-1 Supplement
  "U+0100-017F", // Latin Extended-A
  "U+2010-2027", // dashes, quotes, bullet, ellipsis
  "U+2030-205E", // per-mille, primes, misc punctuation
  "U+20A0-20BF", // currency symbols
  "U+2122", // trademark
  "U+2190-2193", // arrows
  "U+2212", // minus
  "U+25CF", // filled circle
  "U+2713-2714", // check marks
].join(",");

const FONTS = [
  "glide-variable.woff2",
  "glide-variable-italic.woff2",
  "glide-mono.woff2",
];

const kb = (path) => `${(statSync(path).size / 1024).toFixed(1)}KB`;

const check = process.argv.includes("--check");

mkdirSync(outDir, { recursive: true });

let before = 0;
let after = 0;

for (const font of FONTS) {
  const src = join(sourceDir, font);
  const dest = join(outDir, font);

  const srcSize = statSync(src).size;
  before += srcSize;

  if (check) {
    let destSize = 0;
    try {
      destSize = statSync(dest).size;
    } catch {
      // Not yet generated.
    }
    after += destSize;
    process.stdout.write(
      `${font}: ${kb(src)} -> ${destSize ? kb(dest) : "(not generated)"}\n`
    );
    continue;
  }

  execFileSync("pyftsubset", [
    src,
    `--output-file=${dest}`,
    `--unicodes=${UNICODES}`,
    "--flavor=woff2",
    // The variable axis must survive. Glide is loaded as `weight: "100 950"`
    // and the page uses 400 through 600; dropping the axis would silently clamp
    // every weight to the default instance and quietly flatten the hierarchy.
    "--layout-features=*",
    "--no-hinting",
    "--desubroutinize",
  ]);

  after += statSync(dest).size;
  process.stdout.write(`${font}: ${kb(src)} -> ${kb(dest)}\n`);
}

process.stdout.write(
  `\ntotal: ${(before / 1024).toFixed(1)}KB -> ${(after / 1024).toFixed(1)}KB` +
    ` (${(100 - (after / before) * 100).toFixed(0)}% smaller)\n`
);
