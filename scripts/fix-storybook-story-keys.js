/**
 * @storybook/preset-server-webpack's loader converts *.stories.json into a JS
 * module by emitting `key: value` for every object property WITHOUT quoting
 * the key. An argType `options` map keyed by a human-readable SDC
 * `meta:enum` label (e.g. "Extra Small", "Body secondary") breaks the
 * resulting JS. Quote any such key with embedded single quotes -- the same
 * workaround already generated for most components -- so it renders as a
 * valid JS string-literal key.
 */
const fs = require('fs');
const path = require('path');

// The theme ships as a contrib package (web/themes/contrib), but a working
// copy may sit in web/themes/custom. Take the first one that exists.
function resolveRoot() {
  if (process.argv[2]) {
    return process.argv[2];
  }
  const web = path.join(__dirname, '..', 'web', 'themes');
  for (const kind of ['contrib', 'custom']) {
    const candidate = path.join(web, kind, 'vartheme_bs5_educare', 'components');
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

const root = resolveRoot();

if (!root || !fs.existsSync(root)) {
  console.log('SKIP: no vartheme_bs5_educare components directory found.');
  process.exit(0);
}

function isSafeKey(key) {
  return /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(key) || /^\d+$/.test(key);
}

function isAlreadyQuoted(key) {
  return (
    (key.startsWith("'") && key.endsWith("'") && key.length >= 2) ||
    (key.startsWith('"') && key.endsWith('"') && key.length >= 2)
  );
}

function quoteKey(key) {
  return `'${key.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
}

function fixOptions(options) {
  const fixed = {};
  let changed = false;
  for (const [key, value] of Object.entries(options)) {
    if (!isSafeKey(key) && !isAlreadyQuoted(key)) {
      fixed[quoteKey(key)] = value;
      changed = true;
    } else {
      fixed[key] = value;
    }
  }
  return { fixed, changed };
}

function walk(dir, callback) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, callback);
    else if (entry.isFile() && entry.name.endsWith('.stories.json')) callback(full);
  }
}

let filesChanged = 0;

walk(root, (file) => {
  const raw = fs.readFileSync(file, 'utf8');
  let data;
  try {
    data = JSON.parse(raw);
  } catch (e) {
    console.error(`SKIP (invalid JSON): ${file}: ${e.message}`);
    return;
  }

  let fileChanged = false;
  if (data.argTypes && typeof data.argTypes === 'object') {
    for (const argType of Object.values(data.argTypes)) {
      if (argType && typeof argType === 'object' && argType.options && typeof argType.options === 'object' && !Array.isArray(argType.options)) {
        const { fixed, changed } = fixOptions(argType.options);
        if (changed) {
          argType.options = fixed;
          fileChanged = true;
        }
      }
    }
  }

  if (fileChanged) {
    fs.writeFileSync(file, JSON.stringify(data), 'utf8');
    filesChanged++;
    console.log(`fixed: ${path.relative(root, file)}`);
  }
});

console.log(`Done. Files changed: ${filesChanged}`);
