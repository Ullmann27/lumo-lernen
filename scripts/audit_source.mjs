import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve, relative } from 'node:path';

const root = resolve('lib');
const prefix = 'package:lumo_lernen/';
const files = [];
function walk(folder) {
  for (const item of readdirSync(folder, { withFileTypes: true })) {
    const path = join(folder, item.name);
    if (item.isDirectory()) walk(path);
    else if (path.endsWith('.dart')) files.push(path);
  }
}
walk(root);
const reachable = new Set();
const packages = new Set();
function follow(path) {
  if (reachable.has(path) || !existsSync(path)) return;
  reachable.add(path);
  const source = readFileSync(path, 'utf8');
  for (const [, uri] of source.matchAll(/(?:import|export|part)\s+['"]([^'"]+)['"]/g)) {
    if (uri.startsWith('dart:')) continue;
    if (uri.startsWith('package:') && !uri.startsWith(prefix)) {
      packages.add(uri.slice(8).split('/')[0]);
      continue;
    }
    follow(uri.startsWith(prefix)
      ? join(root, uri.slice(prefix.length))
      : resolve(dirname(path), uri));
  }
}
follow(join(root, 'main.dart'));
const orphaned = files.filter(path => !reachable.has(path)).map(path => relative(root, path));
const voiceFolder = 'assets/audio/voice/lumo';
const catalog = JSON.parse(readFileSync(join(voiceFolder, 'catalog.json'), 'utf8'));
const recordings = new Set(Object.values(catalog.clips).map(clip => `${clip.id}.m4a`));
const orphanedAudio = readdirSync(voiceFolder)
  .filter(file => file.endsWith('.m4a') && !recordings.has(file));
const missingAudio = [...recordings].filter(file => !existsSync(join(voiceFolder, file)));
console.log(JSON.stringify({
  dartFiles: files.length, reachable: reachable.size, orphaned,
  runtimePackages: [...packages].sort(), voiceClips: recordings.size,
  orphanedAudio, missingAudio,
}, null, 2));
if (orphaned.length || orphanedAudio.length || missingAudio.length) process.exitCode = 1;
