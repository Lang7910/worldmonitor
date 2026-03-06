/**
 * Build all proto-first API route entrypoints for self-hosted Node runtime.
 *
 * Sidecar/local API server loads JavaScript files under `api/`.
 * These routes are authored as TypeScript (`[rpc].ts` files), so we bundle
 * each entrypoint to JavaScript (`[rpc].js`) for runtime discovery.
 */

import { build } from 'esbuild';
import { readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const apiRoot = path.join(projectRoot, 'api');

async function collectRpcEntrypoints(dir) {
  const out = [];
  const entries = await readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...await collectRpcEntrypoints(absolute));
      continue;
    }
    if (!entry.isFile()) continue;
    if (!entry.name.endsWith('.ts')) continue;
    if (entry.name !== '[rpc].ts') continue;
    out.push(absolute);
  }
  return out;
}

if (!existsSync(apiRoot)) {
  console.error('build:selfhost-api failed: api/ directory not found');
  process.exit(1);
}

const entryPoints = (await collectRpcEntrypoints(apiRoot)).sort();
if (entryPoints.length === 0) {
  console.log('build:selfhost-api skipped (no api/**/[rpc].ts found)');
  process.exit(0);
}

await build({
  entryPoints,
  outdir: apiRoot,
  outbase: apiRoot,
  bundle: true,
  format: 'esm',
  platform: 'node',
  target: 'node20',
  sourcemap: false,
  logLevel: 'info',
});

console.log(`build:selfhost-api completed (${entryPoints.length} routes)`);
