// Resolve Ripple's package aliases after every Wally installation.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const index = path.join(project, 'Packages/_Index');
if (!fs.existsSync(index)) throw new Error('Packages/_Index is missing. Run wally install first.');
// The installed version folder changes on every dependency bump, so it is
// never written into this script and never taken from a directory listing:
// an old copy of Ripple in _Index sorts after the current one and would be
// patched while the alias of the root package keeps pointing at the locked
// version. The version comes from wally.lock or from that alias.
const PACKAGE = 'littensy/ripple';
const FOLDER = 'littensy_ripple@';

function lockedVersion() {
  const lock = path.join(project, 'wally.lock');
  if (!fs.existsSync(lock)) return null;
  const text = fs.readFileSync(lock, 'utf8');
  for (const block of text.split(/\[\[package\]\]/).slice(1)) {
    const name = block.match(/^[ \t]*name[ \t]*=[ \t]*"([^"]+)"/m);
    const version = block.match(/^[ \t]*version[ \t]*=[ \t]*"([^"]+)"/m);
    if (name && version && name[1] === PACKAGE) return version[1];
  }
  return null;
}

// The version the alias of the root package points at:
//   require(script.Parent._Index["littensy_ripple@0.10.2"]["ripple"])
function aliasedVersion() {
  const alias = path.join(project, 'Packages/Ripple.lua');
  if (!fs.existsSync(alias)) return null;
  const match = fs.readFileSync(alias, 'utf8').match(/_Index\["littensy_ripple@([^"]+)"\]/);
  return match ? match[1] : null;
}

const version = lockedVersion() || aliasedVersion();
if (!version) throw new Error('The version of Ripple is unknown. Run wally install first.');
const packageFolder = FOLDER + version;
const aliased = aliasedVersion();
if (aliased && aliased !== version) {
  throw new Error(
    'Packages/Ripple.lua points at ' + FOLDER + aliased + ', wally.lock has ' + packageFolder
    + '. Run wally install first.'
  );
}
const root = path.join(index, packageFolder, 'ripple/src');
if (!fs.existsSync(root)) {
  const installed = fs.readdirSync(index).filter((entry) => entry.startsWith(FOLDER)).sort();
  throw new Error(
    'Ripple ' + packageFolder + ' is missing from Packages/_Index (installed: '
    + (installed.join(', ') || 'none') + '). Run wally install first.'
  );
}
let changed = 0;
function visit(folder) {
  for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
    const filename = path.join(folder, entry.name);
    if (entry.isDirectory()) visit(filename);
    else if (entry.name.endsWith('.luau')) {
      const source = fs.readFileSync(filename, 'utf8');
      const result = source.replace(/require\("([^"\n]+)"\)/g, (match, value) => {
        if (!value.startsWith('@self/') && !value.startsWith('.')) return match;
        const target = value.startsWith('@self/') ? path.resolve(root, value.slice(6)) : path.resolve(path.dirname(filename), value);
        const relative = path.relative(root, target);
        if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('Ripple alias escapes package: ' + value);
        const parts = relative.split(path.sep);
        const depth = path.relative(root, filename).split(path.sep).length - 1;
        const parents = depth + (path.basename(filename, '.luau') !== 'init' ? 1 : 0);
        return 'require(script' + '.Parent'.repeat(parents) + parts.map(p => '[' + JSON.stringify(p) + ']').join('') + ')';
      });
      if (result !== source) { fs.writeFileSync(filename, result); changed++; }
    }
  }
}
visit(root);
console.log('Ripple prepared: ' + changed + ' files changed (' + packageFolder + ').');
