// Full local verification gate for the Ball project.
//
// Every step is reproducible from a clean clone: dependencies are installed,
// the vendor tree is prepared, then formatting, linting, unit tests, the
// Rojo build and the Luau type check run in order. A failing step aborts.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = path.resolve(project, '..');
const logs = path.join(project, '.tools');
fs.mkdirSync(logs, { recursive: true });

const manifest = fs.readFileSync(path.join(repoRoot, 'rokit.toml'), 'utf8');
const exe = process.platform === 'win32' ? '.exe' : '';

function pinned(tool) {
  const match = manifest.match(new RegExp('^' + tool + ' = "([^/]+)/([^@]+)@([^"\\r\\n]+)"', 'm'));
  if (!match) throw new Error('Missing tool pin in rokit.toml: ' + tool);
  return path.join(os.homedir(), '.rokit', 'tool-storage', match[1].toLowerCase(), match[2], match[3], tool + exe);
}

function run(label, command, args, options = {}) {
  const cwd = options.cwd || project;
  const timeout = options.timeout || 600000;
  const result = spawnSync(command, args, {
    cwd,
    encoding: 'utf8',
    windowsHide: true,
    timeout,
    maxBuffer: 64 * 1024 * 1024,
    env: { ...process.env, ...(options.env || {}) },
  });
  const output = (result.stdout || '') + (result.stderr || '');
  fs.writeFileSync(path.join(logs, label + '.log'), output);
  if (options.silent) {
    // The full output is in the log; only a failure is worth showing.
    if (result.status !== 0 && !options.allowFailure) process.stdout.write(output);
  } else if (options.quiet) {
    if (result.status !== 0) process.stdout.write(output);
  } else {
    process.stdout.write(output);
  }
  if (result.error) {
    // A timeout reports itself as a start failure, which hides the real
    // cause: the step ran out of time instead of never starting.
    if (result.error.code === 'ETIMEDOUT') {
      throw new Error(label + ' timed out after ' + timeout + ' ms (log: .tools/' + label + '.log)');
    }
    throw new Error(label + ' failed to start: ' + result.error.message);
  }
  if (result.status !== 0 && !options.allowFailure) {
    throw new Error(label + ' failed with exit code ' + result.status + ' (log: .tools/' + label + '.log)');
  }
  return { output, status: result.status };
}

function step(label, fn) {
  process.stdout.write('== ' + label + '\n');
  fn();
}

// ---------------------------------------------------------------- dependencies
// The lines of a table of the manifest. The tables are plain TOML: a header
// in square brackets and the entries below it.
function tomlSection(text, name) {
  const table = text.split(new RegExp('^\\[' + name + '\\][ \\t]*\\r?$', 'm'))[1];
  if (!table) return null;
  return table.split(/^\[/m)[0];
}

function manifestText() {
  return fs.readFileSync(path.join(project, 'wally.toml'), 'utf8');
}

function manifestName() {
  const table = tomlSection(manifestText(), 'package');
  const match = (table || '').match(/^[ \t]*name[ \t]*=[ \t]*"([^"]+)"/m);
  if (!match) throw new Error('wally.toml has no [package] name');
  return match[1];
}

// The dependencies of the manifest: an alias and the package it asks for.
function manifestDependencies() {
  const table = tomlSection(manifestText(), 'dependencies');
  if (!table) throw new Error('wally.toml has no [dependencies] table');
  const dependencies = new Map();
  for (const line of table.split(/\r?\n/)) {
    const match = line.match(/^[ \t]*([A-Za-z0-9_-]+)[ \t]*=[ \t]*"([^"]+)"[ \t]*$/);
    if (match) dependencies.set(match[1], match[2]);
  }
  if (dependencies.size === 0) throw new Error('wally.toml lists no dependencies');
  return dependencies;
}

function lockedPackages() {
  const lock = fs.readFileSync(path.join(project, 'wally.lock'), 'utf8');
  const rootName = manifestName();
  const expected = [...lock.matchAll(/^name = "([^"]+)"\nversion = "([^"]+)"/gm)].map((m) => ({
    folder: m[1].replace('/', '_') + '@' + m[2],
    name: m[1],
    version: m[2],
  })).filter((pkg) => pkg.name !== rootName);
  if (expected.length === 0) throw new Error('wally.lock lists no packages');
  return expected;
}

// The packages of the lock file: a name and the version it is locked at.
function lockedVersions() {
  const lock = fs.readFileSync(path.join(project, 'wally.lock'), 'utf8');
  const versions = new Map();
  for (const block of lock.split(/\[\[package\]\]/).slice(1)) {
    const name = block.match(/^[ \t]*name[ \t]*=[ \t]*"([^"]+)"/m);
    const version = block.match(/^[ \t]*version[ \t]*=[ \t]*"([^"]+)"/m);
    if (name && version) versions.set(name[1], version[1]);
  }
  return versions;
}

// The aliases the lock file resolved for the root package: the alias of the
// manifest and the package it points at.
function lockedAliases(rootName) {
  const lock = fs.readFileSync(path.join(project, 'wally.lock'), 'utf8');
  for (const block of lock.split(/\[\[package\]\]/).slice(1)) {
    const name = block.match(/^[ \t]*name[ \t]*=[ \t]*"([^"]+)"/m);
    if (!name || name[1] !== rootName) continue;
    const list = block.match(/dependencies[ \t]*=[ \t]*\[([^\]]*)\]/);
    const aliases = new Map();
    if (list) {
      for (const entry of list[1].matchAll(/"([^"]+)"[ \t]*,[ \t]*"([^"]+)"/g)) {
        aliases.set(entry[1], entry[2]);
      }
    }
    return aliases;
  }
  return new Map();
}

// The root aliases point at the packages the game requires. Wally creates
// them for the root package, so a missing alias means an incomplete install.
const ROOT_ALIASES = ['React.lua', 'ReactRoblox.lua', 'Ripple.lua'];
// A package folder smaller than this was not copied completely.
const MIN_PACKAGE_BYTES = 512;

function folderSize(folder) {
  let total = 0;
  for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
    const full = path.join(folder, entry.name);
    if (entry.isDirectory()) total += folderSize(full);
    else if (entry.isFile()) total += fs.statSync(full).size;
  }
  return total;
}

// Everything that keeps the vendor tree from matching wally.lock: a package
// folder that is missing, a package folder that was only half copied and a
// root alias that was not written.
function missingPackages(expected) {
  const packages = path.join(project, 'Packages');
  const index = path.join(packages, '_Index');
  if (!fs.existsSync(index)) {
    return expected.map((pkg) => pkg.name + '@' + pkg.version);
  }
  const problems = [];
  for (const pkg of expected) {
    const folder = path.join(index, pkg.folder);
    if (!fs.existsSync(folder)) {
      problems.push(pkg.name + '@' + pkg.version + ' (folder missing)');
      continue;
    }
    const size = folderSize(folder);
    if (size < MIN_PACKAGE_BYTES) {
      problems.push(pkg.name + '@' + pkg.version + ' (only ' + size + ' bytes)');
    }
  }
  for (const alias of ROOT_ALIASES) {
    const file = path.join(packages, alias);
    if (!fs.existsSync(file) || fs.statSync(file).size === 0) {
      problems.push('Packages/' + alias + ' (root alias missing)');
    }
  }
  return problems;
}

step('wally manifest', () => {
  // A dependency of the manifest that the lock file does not know is a
  // dependency the game never gets: the tree still matches the old lock,
  // so the install is skipped, and the require fails at runtime.
  const dependencies = manifestDependencies();
  const versions = lockedVersions();
  const aliases = lockedAliases(manifestName());
  const problems = [];
  for (const [alias, requirement] of dependencies) {
    const at = requirement.lastIndexOf('@');
    const name = at > 0 ? requirement.slice(0, at) : requirement;
    const version = at > 0 ? requirement.slice(at + 1) : '';
    const locked = versions.get(name);
    if (!locked) {
      problems.push(alias + ': the package ' + name + ' is missing from wally.lock');
    } else if (locked !== version) {
      problems.push(
        alias + ': wally.lock has ' + name + '@' + locked + ', wally.toml asks for ' + requirement,
      );
    }
    const resolved = aliases.get(alias);
    if (resolved && resolved !== requirement) {
      problems.push(alias + ': wally.lock resolves it to ' + resolved + ', wally.toml asks for ' + requirement);
    }
  }
  if (problems.length > 0) {
    throw new Error(
      'wally.toml and wally.lock disagree:\n  ' + problems.join('\n  ')
      + '\n  Run wally install and commit the new lock file.',
    );
  }
  process.stdout.write('wally.toml matches wally.lock: ' + dependencies.size + ' dependencies.\n');
});

step('wally install', () => {
  // Wally rewrites the whole Packages tree, which drops the aliases a running
  // Rojo server is serving. Install only when the tree is actually missing.
  const expected = lockedPackages();
  const missing = missingPackages(expected);
  if (missing.length === 0) {
    process.stdout.write('Packages/ already matches wally.lock, install skipped.\n');
    return;
  }
  process.stdout.write('Packages/ is incomplete: ' + missing.join(', ') + '\n');
  // The install writes the lock file as well. A lock that changes means
  // that the committed lock was stale, and the difference belongs into a
  // review instead of into the tree of the next build.
  const lockFile = path.join(project, 'wally.lock');
  const before = fs.readFileSync(lockFile, 'utf8');
  run('wally-install', pinned('wally'), ['install'], { cwd: project });
  const after = fs.readFileSync(lockFile, 'utf8');
  if (after !== before) {
    throw new Error(
      'wally install changed wally.lock: the committed lock file is stale.'
      + ' Run wally install and commit the new lock file.',
    );
  }
});

step('prepare Ripple aliases', () => {
  run('prepare-ui', process.execPath, [path.join(project, 'tools', 'prepare-ui.mjs')], { cwd: project });
});

step('verify Packages match wally.lock', () => {
  const expected = lockedPackages();
  const missing = missingPackages(expected);
  if (missing.length > 0) {
    throw new Error('Packages/ does not match wally.lock: ' + missing.join(', '));
  }
  process.stdout.write('Packages/ matches ' + expected.length + ' locked packages and the root aliases.\n');
});

// ------------------------------------------------------------------ static checks
step('stylua', () => {
  run('stylua', pinned('stylua'), ['--check', '--glob', '**/*.luau', 'src/client', 'src/server', 'src/shared', 'src/loading', 'tests', 'lune', 'tools']);
});

step('selene', () => {
  run('selene', pinned('selene'), ['--display-style', 'quiet', '--config', 'selene.toml', 'src', 'tests', 'lune']);
  run('selene-tools', pinned('selene'), ['--display-style', 'quiet', '--config', 'tools/selene.toml', 'tools']);
});

step('lune unit tests', () => {
  run('lune', pinned('lune'), ['run', 'lune/test.luau']);
});

step('rojo build', () => {
  run('rojo-build', pinned('rojo'), ['build', 'default.project.json', '-o', '.tools/Ball.rbxlx']);
});

step('rojo sourcemap', () => {
  run('rojo-sourcemap', pinned('rojo'), ['sourcemap', 'default.project.json', '-o', '.tools/sourcemap.json']);
});

// ------------------------------------------------------------ studio verify scripts
// The Verify scripts run inside Roblox Studio: they need the DataModel, the
// module tree of the running game and HttpService, so the gate cannot execute
// them. The gate keeps them honest instead: every module of the game they use
// must still exist and every function they call must still be defined. A
// rename that would break a manual check fails the build instead of the
// Studio run.
const MODULE_PATHS = [
  { source: 'game\\.ServerScriptService\\.Server\\.([A-Za-z0-9_.]+)', folder: 'server' },
  { source: 'game\\.ReplicatedStorage\\.Shared\\.([A-Za-z0-9_.]+)', folder: 'shared' },
  { source: '(?<![\\w.])(?:server)\\.([A-Za-z0-9_.]+)', folder: 'server' },
  { source: '(?<![\\w.])(?:shared|Shared)\\.([A-Za-z0-9_.]+)', folder: 'shared' },
];

// A require of a module of the tree by its path in the tree:
// require(script.Parent.GameConfig) and require(script.Parent.Core.Economy).
// The path depends on the folder of the requiring file, so it is resolved
// per file and not by a pattern of the whole tree.
const RELATIVE_REQUIRE = /require\(\s*script((?:\.Parent)+(?:\.[A-Za-z0-9_]+)+)\s*\)/g;
const RELATIVE_PATH = /^script((?:\.Parent)+(?:\.[A-Za-z0-9_]+)+)$/;

function moduleFile(folder, name) {
  const file = path.join(project, 'src', folder, ...name.split('.')) + '.luau';
  return fs.existsSync(file) ? file : null;
}

// The module of the tree a relative require points at, or null when the path
// leaves the tree or the file does not exist. The first .Parent is the folder
// of the requiring module and every further .Parent goes one folder up.
function relativeModule(file, chain) {
  const parts = path.relative(path.join(project, 'src'), file).split(path.sep);
  const name = parts.pop();
  // A file named init.luau becomes the module of its own folder, so its
  // parent is the folder above and not the folder of the file.
  if (/^init(\.[a-z]+)?\.luau$/.test(name)) parts.pop();
  const steps = chain.split('.').filter(Boolean);
  let parents = 0;
  while (parents < steps.length && steps[parents] === 'Parent') parents++;
  if (parents === 0) return null;
  const base = parts.slice(0, Math.max(0, parts.length - (parents - 1)));
  const rest = steps.slice(parents);
  if (base.length === 0 || rest.length === 0) return null;
  const target = path.join(project, 'src', ...base, ...rest) + '.luau';
  if (!fs.existsSync(target)) return null;
  return { folder: base[0], name: base.slice(1).concat(rest).join('.'), file: target };
}

// The module of the game an expression points at, or null. A relative
// require is resolved against the folder of the requiring file.
function resolveModule(expression, from) {
  for (const entry of MODULE_PATHS) {
    const match = expression.match(new RegExp(entry.source));
    if (match) return { name: match[1], folder: entry.folder };
  }
  const relative = expression.match(RELATIVE_PATH);
  if (relative && from) return relativeModule(from, relative[1]);
  return null;
}

// The local names under which a script uses the modules of the game.
function studioBindings(source, from) {
  const clones = new Map();
  for (const match of source.matchAll(/local\s+([A-Za-z0-9_]+)\s*=\s*([^;]+?):Clone\(\)/g)) {
    const module = resolveModule(match[2], from);
    if (module) clones.set(match[1], module);
  }
  const bindings = new Map();
  for (const match of source.matchAll(/local\s+([A-Za-z0-9_]+)\s*=\s*require\(([^)]+)\)/g)) {
    const module = clones.get(match[2]) || resolveModule(match[2], from);
    if (module) bindings.set(match[1], module);
  }
  // An instance that uses the module as its metatable exposes the same members.
  for (const match of source.matchAll(/local\s+([A-Za-z0-9_]+)\s*=\s*setmetatable\(.*?,\s*([A-Za-z0-9_]+)\s*\)/g)) {
    const module = bindings.get(match[2]);
    if (module) bindings.set(match[1], module);
  }
  return bindings;
}

// The functions a script calls on a module of the game.
function studioCalls(source, alias) {
  const calls = new Set();
  for (const match of source.matchAll(new RegExp('\\b' + alias + '[.:]([A-Za-z0-9_]+)\\s*\\(', 'g'))) {
    calls.add(match[1]);
  }
  return calls;
}

// A module defines a member as a function or as an assigned value.
function definesMember(source, member) {
  const name = member.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp('(?:function\\s+[A-Za-z0-9_]+[.:]|[A-Za-z0-9_]+[.:])' + name + '\\b\\s*(?:\\(|=)').test(source);
}

step('studio verify scripts', () => {
  const folder = path.join(project, 'tools');
  const scripts = fs.readdirSync(folder).filter((name) => /^Verify.*\.luau$/.test(name)).sort();
  if (scripts.length === 0) throw new Error('No Studio verification scripts found in tools/');
  const problems = [];
  for (const name of scripts) {
    const source = fs.readFileSync(path.join(folder, name), 'utf8');
    // The scripts are run from game.ServerScriptService.Server, so a require
    // of script.Parent points at a module of src/server.
    const from = path.join(project, 'src', 'server', name);
    for (const entry of MODULE_PATHS) {
      for (const match of source.matchAll(new RegExp(entry.source, 'g'))) {
        if (!moduleFile(entry.folder, match[1])) {
          problems.push(name + ': module ' + match[1] + ' is missing from src/' + entry.folder);
        }
      }
    }
    for (const match of source.matchAll(RELATIVE_REQUIRE)) {
      if (!relativeModule(from, match[1])) {
        problems.push(name + ': require(script' + match[1] + ') does not point at a module');
      }
    }
    for (const [alias, module] of studioBindings(source, from)) {
      const file = moduleFile(module.folder, module.name);
      if (!file) continue;
      const text = fs.readFileSync(file, 'utf8');
      for (const call of studioCalls(source, alias)) {
        if (!definesMember(text, call)) {
          problems.push(name + ': ' + module.name + '.' + call + '() is not defined in ' + path.relative(project, file));
        }
      }
    }
  }
  if (problems.length > 0) {
    throw new Error('Studio verification scripts do not match the sources:\n  ' + problems.join('\n  '));
  }
  process.stdout.write(
    scripts.length
      + ' Studio verification scripts match the sources. They need a running Studio (Edit mode) and are not executed here.\n',
  );
});

step('module requires', () => {
  // A module of the tree is required by its path: require(script.Parent.X).
  // A renamed module breaks every caller that requires it, and the game
  // finds out in the middle of a session. The path is resolved here, so a
  // broken require fails the build instead of the game.
  const problems = [];
  let checked = 0;
  const visit = (folder) => {
    for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
      const full = path.join(folder, entry.name);
      if (entry.isDirectory()) {
        // The vendored ProfileStore is third-party code.
        if (entry.name !== 'serverPackages') visit(full);
      } else if (entry.name.endsWith('.luau')) {
        const source = fs.readFileSync(full, 'utf8');
        for (const match of source.matchAll(RELATIVE_REQUIRE)) {
          checked++;
          if (!relativeModule(full, match[1])) {
            problems.push(
              path.relative(project, full) + ': require(script' + match[1] + ') does not point at a module',
            );
          }
        }
      }
    }
  };
  visit(path.join(project, 'src'));
  if (problems.length > 0) {
    throw new Error('The modules of the tree require files that do not exist:\n  ' + problems.join('\n  '));
  }
  process.stdout.write(checked + ' relative requires of the tree point at existing modules.\n');
});

// -------------------------------------------------------------------- type check
// The analyzer prints one finding per line:
//   <path> [<instance path>](line,column): <Kind>: <message>
// The instance path is optional: depending on how the analyzer resolves a
// file through the sourcemap the line reads <path>(line,column): <Kind>: ...
// The path is parsed greedily on purpose. The source tree has folders of any
// depth and a positional split used to drop every finding of a nested folder.
const FINDING = /^(.+?)\s*(?:\[([^\]]*)\])?\((\d+),(\d+)\): (\w+): (.*)$/;

// The path of a finding, relative to the source folder.
function relativeToSrc(file) {
  const normalized = file.replace(/\\/g, '/');
  const marker = '/src/';
  const index = normalized.lastIndexOf(marker);
  if (index >= 0) return normalized.slice(index + marker.length);
  if (normalized.startsWith('src/')) return normalized.slice(4);
  return normalized;
}

// The analyzer prints the type it inferred as a table or as a free type with
// its definitions. Both are printed in full and both change with every change
// of the code around them, so they are replaced by a placeholder. The quotes
// inside a type are always inside braces, so the end of a type is the first
// quote that closes no brace.
function stripTypes(text) {
  let out = '';
  let i = 0;
  while (i < text.length) {
    const quote = text.indexOf("'", i);
    if (quote < 0) {
      out += text.slice(i);
      break;
    }
    const rest = text.slice(quote + 1);
    const isTable = rest.startsWith('{');
    const isFree = /^[a-z]+\d* where\b/.test(rest);
    if (!isTable && !isFree) {
      out += text.slice(i, quote + 1);
      i = quote + 1;
      continue;
    }
    let depth = 0;
    let end = -1;
    for (let j = quote + 1; j < text.length; j++) {
      const c = text[j];
      if (c === '{') depth++;
      else if (c === '}') depth--;
      else if (c === "'" && depth === 0) {
        end = j;
        break;
      }
    }
    if (end < 0) {
      // The type was cut off by the analyzer, so its braces do not close and
      // the rest of the line belongs to the type.
      out += text.slice(i, quote) + "'<type>'";
      break;
    }
    out += text.slice(i, quote) + "'<type>'";
    i = end + 1;
  }
  return out;
}

// The key of a finding: file, kind and the message without the inferred
// types. The line and column numbers are left out on purpose: inserting a
// line above a known error must not look like a new finding.
function findingKey(file, kind, message, block) {
  const parts = [];
  for (const line of [message, ...block]) {
    // These lines carry nothing but inferred types.
    if (/^Table type /.test(line)) continue;
    if (/^'/.test(line.trim())) continue;
    parts.push(stripTypes(line));
  }
  // The fields of a table type are not printed in a stable order.
  const sorted = parts.join(' ').replace(/\{([^{}]*)\}/g, (all, inner) => {
    const fields = inner
      .split(',')
      .map((field) => field.trim())
      .filter((field) => field.length > 0)
      .sort();
    return '{' + fields.join(', ') + '}';
  });
  // Generic variables are numbered per run, so they are renamed.
  const head = sorted.replace(/\b(t|tp|[a-z])\d+\b/g, 'T').replace(/\s+/g, ' ').trim();
  return file + '|' + kind + '|' + (head.length >= 6 ? head : '<type-expression>');
}

step('luau type check', () => {
  const types = path.join(project, '.tools', 'luau-types', 'globalTypes.d.luau');
  // The definitions are downloaded once, but the hash is checked on every
  // run: a truncated download would leave the analyzer working on broken
  // definitions, and the gate would report nothing at all.
  run('fetch-luau-types', process.execPath, [path.join(project, 'tools', 'fetch-luau-types.mjs')], {
    cwd: project,
    quiet: true,
  });
  if (!fs.existsSync(types)) throw new Error('Luau type definitions are missing: ' + types);

  const sources = [];
  const collect = (folder) => {
    for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
      const full = path.join(folder, entry.name);
      if (entry.isDirectory()) collect(full);
      else if (entry.name.endsWith('.luau')) sources.push(full);
    }
  };
  collect(path.join(project, 'src'));
  // The vendored ProfileStore is third-party code and is not type checked here.
  const checked = sources.filter((file) => !file.includes(path.join('src', 'serverPackages')));
  if (checked.length === 0) throw new Error('Type check has no source files to analyse');

  const analyzed = run('luau-analyze', pinned('luau-lsp'), [
    'analyze',
    '--defs',
    types,
    '--sourcemap',
    path.join(project, '.tools', 'sourcemap.json'),
    '--ignore',
    'src/serverPackages/*',
    ...checked,
  ], { quiet: true, allowFailure: true, silent: true });
  const output = analyzed.output;

  // The analyzer uses 0 for a clean run and 1 for "findings found". Any
  // other code means that it crashed or was killed, and then its findings
  // describe only the files it reached before it died.
  if (analyzed.status !== 0 && analyzed.status !== 1) {
    throw new Error(
      'Type check failed: the analyzer exited with code ' + analyzed.status
      + ' (log: .tools/luau-analyze.log)',
    );
  }

  const findings = [];
  const lines = output.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const match = lines[i].match(FINDING);
    if (!match) continue;
    // A finding can carry more lines: the type the analyzer complains about
    // is printed under the message.
    const block = [];
    let next = i + 1;
    while (
      next < lines.length
      && lines[next].trim()
      && !FINDING.test(lines[next])
      && !/^\[(INFO|WARN|ERROR)\]/.test(lines[next])
    ) {
      block.push(lines[next].trim());
      next++;
    }
    i = next - 1;
    findings.push({
      file: relativeToSrc(match[1]),
      kind: match[5],
      message: match[6],
      block,
      raw: match[1] + ' (' + match[3] + ',' + match[4] + '): ' + match[5] + ': ' + match[6],
    });
  }
  // The gate has to fail closed. An analyzer that printed nothing, or an
  // output format the parser does not understand, used to look like a clean
  // run: zero findings meant zero regressions.
  if (findings.length === 0) {
    throw new Error(
      'Type check found no findings at all: the analyzer output could not be parsed'
      + ' (exit code ' + analyzed.status + ', log: .tools/luau-analyze.log)',
    );
  }

  // An analyzer that died halfway reports the findings of the files it
  // reached and says nothing about the rest, and a partial set of findings
  // looks like a clean run against the baseline. The healthy project reports
  // findings in 68 of its 92 analysed files, so half of the files is a wide
  // margin: a run that covered a third of the tree fails, and a project that
  // fixed half of its type errors still passes.
  const MIN_FINDING_COVERAGE = 0.5;
  const covered = new Set(findings.map((finding) => finding.file)).size;
  const required = Math.ceil(checked.length * MIN_FINDING_COVERAGE);
  if (covered < required) {
    throw new Error(
      'Type check covered only ' + covered + ' of the ' + checked.length
      + ' analysed files: the analyzer run was partial'
      + ' (exit code ' + analyzed.status + ', log: .tools/luau-analyze.log)',
    );
  }

  const baselineFile = path.join(project, 'tools', 'typecheck-baseline.txt');
  const baseline = new Set(fs.existsSync(baselineFile) ? fs.readFileSync(baselineFile, 'utf8').split('\n').filter(Boolean) : []);
  const seen = new Map();
  for (const finding of findings) {
    const k = findingKey(finding.file, finding.kind, finding.message, finding.block);
    if (!seen.has(k)) seen.set(k, finding.raw);
  }
  if (process.env.UPDATE_TYPECHECK_BASELINE === '1') {
    fs.writeFileSync(baselineFile, [...seen.keys()].sort().join('\n') + '\n');
    process.stdout.write('Type check baseline written: ' + seen.size + ' known errors.\n');
    return;
  }
  const regressions = [...seen.entries()].filter(([k]) => !baseline.has(k));
  const known = [...seen.keys()].filter((k) => baseline.has(k)).length;
  const stale = [...baseline].filter((k) => !seen.has(k));
  fs.writeFileSync(path.join(logs, 'typecheck-summary.txt'), [
    'known errors: ' + known,
    'new errors: ' + regressions.length,
    'stale entries: ' + stale.length,
    '',
    ...regressions.map(([k, line]) => line),
  ].join('\n'));
  process.stdout.write(
    'Type check: ' + known + ' known errors, ' + regressions.length + ' new, ' + stale.length + ' stale.\n',
  );
  const failures = [];
  if (regressions.length > 0) {
    for (const [, line] of regressions.slice(0, 40)) process.stdout.write('  ' + line + '\n');
    failures.push('Type check found ' + regressions.length + ' new errors (see .tools/typecheck-summary.txt)');
  }
  // A stale entry is an error the baseline describes and the analyzer does
  // not report any more: the baseline is out of date and it hides the next
  // regression behind itself. The gate fails on it, and a deliberate
  // refresh of the baseline is done with UPDATE_TYPECHECK_BASELINE=1. A
  // run that only looks at the gate accepts a stale baseline with
  // ALLOW_STALE_TYPECHECK_BASELINE=1 and warns about it.
  if (stale.length > 0) {
    const message = 'Type check baseline has ' + stale.length + ' stale entries: the errors it describes are gone'
      + ' (refresh the baseline with UPDATE_TYPECHECK_BASELINE=1,'
      + ' or set ALLOW_STALE_TYPECHECK_BASELINE=1 to accept them for now)';
    if (process.env.ALLOW_STALE_TYPECHECK_BASELINE === '1') {
      process.stdout.write('Warning: ' + message + '\n');
    } else {
      failures.push(message);
    }
  }
  if (failures.length > 0) throw new Error(failures.join('\n'));
});

console.log('All checks passed. Studio Play is a separate runtime check.');
