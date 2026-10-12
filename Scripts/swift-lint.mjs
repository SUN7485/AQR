#!/usr/bin/env node
/**
 * Structural lint for the AQR360 iOS app.
 *
 * There is no Swift toolchain on Windows, so this catches the classes of error
 * that are cheap to detect without a compiler:
 *
 *   1. Unbalanced braces / parens / brackets, measured after stripping comments
 *      and string literals so delimiters inside them do not skew the count.
 *   2. Odd quote counts per line — a string that does not close on its line.
 *   3. Unbalanced string interpolation `\(...)`.
 *   4. iOS 26-only APIs used outside an `#available` gate. The deployment
 *      target is iOS 18, so `.glassEffect`, `.buttonStyle(.glass)` and
 *      `GlassEffectContainer` will not compile ungated. All gating lives in
 *      Core/Design/LiquidGlassSupport.swift.
 *   5. APIs the project has ruled out: NavigationView, ObservableObject,
 *      foregroundColor, AnyView, index-based ForEach ids, TODO/FIXME.
 *
 * This is a lint, not a type checker. Run `builder ios build` to compile.
 *
 * Usage: node Scripts/swift-lint.mjs [sourceDir]
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SOURCE_DIR = process.argv[2] ?? path.join(ROOT, 'AQR360');

/* The one file allowed to contain gated iOS 26 APIs. */
const GLASS_GATE_FILE = path.join('Core', 'Design', 'LiquidGlassSupport.swift');

/* Collect .swift files, skipping asset catalogs and VCS metadata. */
const files = [];
(function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === '.git' || entry.name.endsWith('.xcassets')) continue;
      walk(full);
    } else if (entry.name.endsWith('.swift')) {
      files.push(full);
    }
  }
})(SOURCE_DIR);

let problems = 0;
const fail = (file, line, msg) => {
  const rel = path.relative(ROOT, file);
  console.log(`  ${rel}${line ? `:${line}` : ''}  ${msg}`);
  problems++;
};

/**
 * Strip comments and string literals so only structural code remains.
 *
 * Interpolations are kept: `\(...)` is emitted as code, so its delimiters
 * count toward the balance totals, while the string text around it does not.
 */
function strip(source) {
  let out = '';
  let i = 0;
  let mode = 'code';
  let interpDepth = 0;
  const stack = [];        // saved modes, so nested constructs restore correctly

  while (i < source.length) {
    const ch = source[i];
    const next = source[i + 1];

    if (mode === 'line') {
      if (ch === '\n') { mode = stack.pop() ?? 'code'; out += '\n'; }
      i++;
      continue;
    }

    if (mode === 'block') {
      if (ch === '*' && next === '/') { mode = stack.pop() ?? 'code'; i += 2; continue; }
      if (ch === '\n') out += '\n';
      i++;
      continue;
    }

    if (mode === 'string') {
      if (ch === '\\' && next === '(') { stack.push('string'); mode = 'code'; interpDepth = 1; i += 2; continue; }
      if (ch === '\\') { i += 2; continue; }
      if (ch === '"') { mode = stack.pop() ?? 'code'; i++; continue; }
      if (ch === '\n') out += '\n';   // unterminated literal; keep line numbering stable
      i++;
      continue;
    }

    /* code */
    if (interpDepth > 0) {
      if (ch === '(') interpDepth++;
      else if (ch === ')') {
        interpDepth--;
        if (interpDepth === 0) { mode = stack.pop() ?? 'code'; i++; continue; }
      }
    }
    if (ch === '/' && next === '/') { stack.push('code'); mode = 'line'; i += 2; continue; }
    if (ch === '/' && next === '*') { stack.push('code'); mode = 'block'; i += 2; continue; }
    if (ch === '"') { stack.push('code'); mode = 'string'; i++; continue; }
    out += ch;
    i++;
  }
  return out;
}

const count = (s, re) => (s.match(re) ?? []).length;

/**
 * Split Swift source into top-level declarations.
 *
 * Needed because several checks must be scoped to a single type: a sibling
 * type in the same file must not satisfy (or trip) another type's rules.
 */
function topLevelBlocks(source) {
  const lines = source.split(/\r?\n/);
  const starts = [];
  lines.forEach((line, i) => {
    if (/^(?:public |internal |private |fileprivate |final |indirect )*(?:struct|class|enum|actor|extension)\b/.test(line)) {
      starts.push(i);
    }
  });
  if (starts.length === 0) return [{ text: source, lines, offset: 0 }];

  return starts.map((start, idx) => {
    const end = idx + 1 < starts.length ? starts[idx + 1] : lines.length;
    return {
      text: lines.slice(start, end).join('\n'),
      lines: lines.slice(start, end),
      offset: start,
    };
  });
}

console.log(`swift-lint  ${path.relative(ROOT, SOURCE_DIR)}  (${files.length} files)\n`);

for (const file of files) {
  const source = fs.readFileSync(file, 'utf8');
  const lines = source.split(/\r?\n/);
  const rel = path.relative(ROOT, file).split(path.sep).join('/');

  /* 1. delimiter parity */
  const code = strip(source);
  for (const [open, close, label] of [['{', '}', 'braces'], ['(', ')', 'parens'], ['[', ']', 'brackets']]) {
    const o = count(code, new RegExp(`\\${open}`, 'g'));
    const c = count(code, new RegExp(`\\${close}`, 'g'));
    if (o !== c) fail(file, null, `${label} unbalanced: ${o} open vs ${c} close`);
  }

  /* 2. per-line quote parity + interpolation balance */
  lines.forEach((line, n) => {
    const quotes = (line.match(/(?<!\\)"/g) ?? []).length;
    if (quotes % 2 !== 0) fail(file, n + 1, `odd quote count (${quotes}) — string may not close`);
    const opens = count(line, /\\\(/g);
    const closes = count(line, /\)/g);
    const innerClosed = count(line, /\)/g) - opens;
    if (opens > 0 && innerClosed < 0) fail(file, n + 1, 'interpolation may be unbalanced');
  });

  /* 3. availability-aware policy scan */
  const gated = new Array(lines.length).fill(false);
  let gateDepth = 0;
  lines.forEach((line, n) => {
    gated[n] = gateDepth > 0;
    const delta = count(line, /\{/g) - count(line, /\}/g);
    if (/#available\s*\(/.test(line)) gateDepth += Math.max(delta, 1);
    else if (gateDepth > 0) gateDepth = Math.max(gateDepth + delta, 0);
    if (gateDepth <= 0) gateDepth = 0;
  });

  const isGateFile = rel.endsWith(GLASS_GATE_FILE.split(path.sep).join('/'));
  const policy = [
    [/\.buttonStyle\(\s*\.glass/, 'ungated iOS 26 glass button — use aqGlassButtonStyle()'],
    [/\.glassEffect\(/, 'ungated iOS 26 .glassEffect — use aqGlass()'],
    [/\bGlassEffectContainer\(/, 'ungated iOS 26 GlassEffectContainer — use aqGlassGroup()'],
    [/\bNavigationView\b/, 'NavigationView is deprecated — use NavigationStack'],
    [/\bObservableObject\b/, 'ObservableObject — use @Observable'],
    [/\.foregroundColor\(/, 'foregroundColor — use foregroundStyle'],
    [/\bAnyView\b/, 'AnyView — type erasure, branch with @ViewBuilder'],
    [/ForEach\(\s*(?:\d+\s*\.\.<|\w[\w.]*\.indices)/, 'range/index-based ForEach id — use a stable Identifiable'],
    [/\bTODO\b|\bFIXME\b/, 'unresolved TODO/FIXME'],
  ];

  lines.forEach((line, n) => {
    for (const [re, msg] of policy) {
      if (re.test(line) && !gated[n] && !isGateFile) fail(file, n + 1, msg);
    }
  });

  /* 4. $ projection on an @Environment @Observable.
   *
   * `@Environment(Type.self) private var store` yields no `$store`, so
   * projecting one is a compile error rather than a warning.
   *
   * Checked per top-level type, not per file: the escape hatch is
   * `@Bindable var store = store` inside body, and a sibling type's copy of
   * that must not mask this type's mistake. Matched by declared name rather
   * than by pattern, because a bare `$\w+\.` also matches string interpolation
   * and key paths and yields false positives.
   */
  for (const block of topLevelBlocks(source)) {
    const envNames = [...block.text.matchAll(
      /@Environment\(\s*\w[\w.]*\.self\s*\)\s*(?:private\s+)?var\s+(\w+)/g
    )].map(m => m[1]);

    for (const name of envNames) {
      if (new RegExp(`@Bindable\\s+(?:var|let)\\s+${name}\\b`).test(block.text)) continue;
      const projection = new RegExp(`\\$${name}\\b`);
      block.lines.forEach((line, i) => {
        if (projection.test(line)) {
          fail(file, block.offset + i + 1,
            `$${name} on an @Environment @Observable — add \`@Bindable var ${name} = ${name}\` in body first`);
        }
      });
    }
  }
}

if (problems === 0) {
  console.log('  no problems found');
} else {
  console.log(`\n${problems} problem(s)`);
}
process.exit(problems ? 1 : 0);