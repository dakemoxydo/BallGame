// Fetch the Roblox Luau type definitions used by the type checker.
// The snapshot is pinned by tag and SHA-256 so a local run and a CI run
// analyse the exact same API surface.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const tag = '1.70.1';
const url = `https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/${tag}/scripts/globalTypes.d.luau`;
const sha256 = '2857efa8245485f8c25c19c018ee1ef9b46afab4efd2ea70fc3257cd3faf7080';
const target = path.join(project, '.tools', 'luau-types', 'globalTypes.d.luau');

function hash(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

if (fs.existsSync(target)) {
  const current = hash(fs.readFileSync(target));
  if (current === sha256) {
    console.log(`Luau types ready (${tag}).`);
    process.exit(0);
  }
  fs.rmSync(target);
}

console.log(`Downloading Luau types ${tag}...`);
const response = await fetch(url, { redirect: 'follow' });
if (!response.ok) throw new Error(`Type download failed: ${response.status} ${url}`);
const body = Buffer.from(await response.arrayBuffer());
const actual = hash(body);
if (actual !== sha256) throw new Error(`Type snapshot hash mismatch: expected ${sha256}, got ${actual}`);
fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, body);
console.log(`Luau types ready (${tag}, ${body.length} bytes).`);
