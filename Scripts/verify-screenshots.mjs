#!/usr/bin/env node
/**
 * Screenshot content validation.
 *
 * Existence of a PNG proves nothing. In run 38284996589 all ten files were
 * written and five were the *same wrong screen*, because a duplicate
 * AppRouter instance meant the requested route silently never pushed. A
 * file-exists check passes that every time.
 *
 * So each capture declares what it must contain, and this checks identity:
 *
 *   1. Distinctness  - no two screens may be byte-identical, with declared
 *                      exemptions for screens that are legitimately the same.
 *   2. Perceptual   - compare downscaled luminance signatures. Catches
 *                      near-duplicates that differ only by compression or by a
 *                      few pixels.
 *   3. Presence      - every declared screen must exist and be non-trivial.
 *
 * Identity is judged from image content, not from filenames or exit codes.
 *
 * Usage:
 *   node Scripts/verify-screenshots.mjs <screenshotsDir>
 */

import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';

/* ---------------------------------------------------------------- manifest */

/**
 * Every screen CI captures.
 *
 * `expect` lists phrases that must appear in the screen's rendered text. They
 * are asserted by eye against the real screenshots, not guessed.
 */
const SCREENS = [
  { file: 'home.png', expect: ['AQR360', 'Good day', 'Demo data', 'Portfolio'] },
  { file: 'market.png', expect: ['Market', 'Apartments', 'Houses'] },
  { file: 'listing.png', expect: ['Harborview', 'Marina', 'Schedule'] },
  { file: 'assets.png', expect: ['Assets', 'Marina Gate', 'Occupancy'] },
  { file: 'services.png', expect: ['Services', 'tickets', 'catalogue'] },
  { file: 'account.png', expect: ['Account', 'Points', 'adaeze@aqr360.com'] },

  { file: 'workspace.png', expect: ['Manage', 'Contracts', 'Responsibility', 'Vault', 'Tenant access'] },
  { file: 'contracts.png', expect: ['Lease', 'Maintenance', 'Deposit', 'Marina Gate'] },
  { file: 'vault.png', expect: ['Title Deed', 'Tenant Agreement', 'Receipt'] },
  { file: 'matrix.png', expect: ['Rent collection', 'approver', 'payee', 'Owner'] },
];

/** Screens allowed to be identical, with the reason. */
const EXEMPT = new Map();

/* ----------------------------------------------------------------- decode */

function decodePNG(buf) {
  let pos = 8, width = 0, height = 0, colorType = 0;
  const idat = [];
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    const data = buf.subarray(pos + 8, pos + 8 + len);
    if (type === 'IHDR') {
      width = data.readUInt32BE(0); height = data.readUInt32BE(4); colorType = data[9];
    } else if (type === 'IDAT') idat.push(data);
    else if (type === 'IEND') break;
    pos += 12 + len;
  }
  const channels = colorType === 6 ? 4 : colorType === 2 ? 3 : 1;
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = width * channels;
  const out = Buffer.alloc(height * stride);
  let prev = Buffer.alloc(stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const line = raw.subarray(y * (stride + 1) + 1, y * (stride + 1) + 1 + stride);
    const cur = Buffer.alloc(stride);
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? cur[x - channels] : 0;
      const b = prev[x];
      const c = x >= channels ? prev[x - channels] : 0;
      let v = line[x];
      if (filter === 1) v += a;
      else if (filter === 2) v += b;
      else if (filter === 3) v += (a + b) >> 1;
      else if (filter === 4) {
        const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c);
      }
      cur[x] = v & 0xff;
    }
    cur.copy(out, y * stride); prev = cur;
  }
  return { width, height, channels, data: out };
}

/**
 * Coarse luminance signature: a 16x16 grid of mean luma, plus the fraction of
 * near-white pixels (a blank or error screen is almost entirely one).
 */
function signature(img) {
  const { width, height, channels, data } = img;
  const N = 16;
  const grid = new Float64Array(N * N);
  const counts = new Uint32Array(N * N);
  let white = 0, dark = 0, total = width * height;

  for (let y = 0; y < height; y++) {
    const gy = Math.min(N - 1, Math.floor((y / height) * N));
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * channels;
      const a = channels === 4 ? data[i + 3] / 255 : 1;
      if (a < 0.5) continue;
      const luma = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
      const gx = Math.min(N - 1, Math.floor((x / width) * N));
      grid[gy * N + gx] += luma;
      counts[gy * N + gx]++;
      if (luma > 240) white++;
      if (luma < 40) dark++;
    }
  }
  const norm = Array.from(grid, (v, k) => (counts[k] ? v / counts[k] : 255) / 255);
  return { norm, whiteFrac: white / total, darkFrac: dark / total };
}

function distance(a, b) {
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += (a[i] - b[i]) ** 2;
  return Math.sqrt(sum / a.length);
}

/* ------------------------------------------------------------------- run */

const dir = process.argv[2];
if (!dir || !fs.existsSync(dir)) {
  console.error(`verify-screenshots: ${dir ?? '<none>'} is not a directory`);
  process.exit(2);
}

console.log(`verify-screenshots  ${dir}\n`);

let problems = 0;
const fail = (m) => { console.log(`  FAIL  ${m}`); problems++; };

/* 1. presence */
const present = [];
for (const s of SCREENS) {
  const p = path.join(dir, s.file);
  if (!fs.existsSync(p)) { fail(`${s.file} missing`); continue; }
  const size = fs.statSync(p).size;
  if (size < 20_000) { fail(`${s.file} suspiciously small (${size} bytes)`); continue; }
  present.push(s.file);
}

/* 2 + 3. distinctness, byte and perceptual */
const decoded = new Map();
const hashes = new Map();

for (const file of present) {
  const buf = fs.readFileSync(path.join(dir, file));
  const sha = crypto.createHash('sha256').update(buf).digest('hex').slice(0, 16);
  hashes.set(file, sha);
  try {
    decoded.set(file, signature(decodePNG(buf)));
  } catch (e) {
    fail(`${file} could not be decoded as PNG: ${e.message}`);
  }
}

console.log('  distinctness');
for (let i = 0; i < present.length; i++) {
  for (let j = i + 1; j < present.length; j++) {
    const a = present[i], b = present[j];
    if (EXEMPT.get(a)?.includes(b)) continue;

    const sameBytes = hashes.get(a) === hashes.get(b);
    const sigA = decoded.get(a), sigB = decoded.get(b);
    const d = (sigA && sigB) ? distance(sigA.norm, sigB.norm) : 1;

    // Threshold chosen from measurement, not taste. Across two runs:
    //   true duplicates  d = 0.0000 - 0.0006
    //   distinct screens d = 0.042 - 0.269
    // 0.01 sits ~16x above the duplicates and ~4x below the nearest
    // legitimate pair, so it separates with margin on both sides.
    //
    // An earlier version also demanded near-identical white-pixel fractions.
    // That was wrong: two genuinely different screens can coincidentally
    // share an overall white fraction. It produced a false positive on
    // assets.png vs matrix.png (d=0.0481, w=0.0020) in run 38288497522.
    if (sameBytes || d < 0.01) {
      fail(`${a} and ${b} look like the same screen ` +
           `(bytes ${sameBytes ? 'identical' : 'differ'}, luma distance ${d.toFixed(4)}) ` +
           `— a requested route may not have navigated`);
    } else {
      console.log(`    ok  ${a} <-> ${b}  d=${d.toFixed(3)}`);
    }
  }
}

/* 4. each screen is not blank */
console.log('\n  content sanity');
for (const file of present) {
  const s = decoded.get(file);
  if (!s) continue;
  const variance = (() => {
    const m = s.norm.reduce((a, b) => a + b, 0) / s.norm.length;
    return Math.sqrt(s.norm.reduce((a, b) => a + (b - m) ** 2, 0) / s.norm.length);
  })();
  if (variance < 0.05) fail(`${file} looks blank (luma variance ${variance.toFixed(4)})`);
  else console.log(`    ok  ${file}  variance=${variance.toFixed(3)} white=${s.whiteFrac.toFixed(2)}`);
}

console.log(`\n  ${present.length}/${SCREENS.length} screens present, ${problems} problem(s)`);
console.log('  NOTE: this validates screen identity, not on-screen wording.');
console.log('        Wording expectations still need a human eye or an OCR check.');
process.exit(problems ? 1 : 0);