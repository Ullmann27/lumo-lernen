// Deterministic asset import, not live TTS. Requires ffmpeg on the build host.
import { readFileSync, writeFileSync, readdirSync, unlinkSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { join, resolve } from 'node:path';

const input = resolve(process.argv[2] ?? '..');
const output = resolve('assets/audio/voice/lumo');
const phrases = [
  ['greeting', 'Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues!', []],
  ['super', 'Super! Das hast du toll gemacht!', ['Super!', 'Toll gemacht!', 'Genau richtig!']],
  ['comfort', 'Fast! Schau nochmal.', ['Fast! Schau nochmal.']],
  ['encourage', 'Du schaffst das! Wir probieren es gemeinsam.', ['Du schaffst das!', 'Kein Problem, wir schaffen das zusammen.']],
  ['connect-intro', 'Vier gewinnt! Du spielst mit Cyan, Lumo mit Gold. Du fängst an!', []],
  ['turn', 'Du bist dran! Schau mal, wo dein Stein am besten passt.', ['Du bist dran!']],
];
const keyFor = text => text.toLowerCase().replace(/[^a-z0-9äöüß]+/g, ' ').trim();
const clips = {};
const aliases = {};
const imported = new Set();
for (const [name, text, triggers] of phrases) {
  const source = join(input, `clip-${name}.mp3`);
  const id = createHash('sha256').update(readFileSync(source)).digest('hex').slice(0, 12);
  const target = `${id}.m4a`;
  imported.add(target);
  execFileSync('ffmpeg', ['-y', '-v', 'error', '-i', source, '-af',
    'highpass=f=80,loudnorm=I=-18:TP=-2:LRA=9', '-c:a', 'aac', '-b:a', '80k',
    join(output, target)]);
  const pcm = execFileSync('ffmpeg', ['-v', 'error', '-i', join(output, target),
    '-f', 's16le', '-ac', '1', '-ar', '8000', 'pipe:1']);
  const step = 400; // 20 Hz envelope, derived from the actual AAC playback bytes.
  const rms = [];
  for (let offset = 0; offset < pcm.length; offset += step * 2) {
    let power = 0, n = 0;
    for (let i = offset; i + 1 < Math.min(pcm.length, offset + step * 2); i += 2) {
      power += (pcm.readInt16LE(i) / 32768) ** 2;
      n++;
    }
    rms.push(Math.sqrt(power / Math.max(1, n)));
  }
  const max = Math.max(...rms, .001);
  const key = keyFor(text);
  clips[key] = {
    id, text, ms: Math.round(pcm.length / 16), // 8000 mono signed 16-bit samples.
    env: rms.map(value => String(Math.round(Math.min(9, value / max * 9)))).join(''),
    source_sha256: createHash('sha256').update(readFileSync(source)).digest('hex'),
  };
  for (const trigger of triggers) aliases[keyFor(trigger)] = key;
}
// Only obsolete catalog recordings, never references or user data.
for (const file of readdirSync(output)) {
  if (/^[0-9a-f]{12}\.m4a$/.test(file) && !imported.has(file)) {
    unlinkSync(join(output, file));
  }
}
writeFileSync(join(output, 'catalog.json'), JSON.stringify({
  version: 2, fps: 20, variant: 'warm_sulafat',
  generation: 'Gemini TTS / Sulafat',
  voice: 'Lumo: warm, natural German delivery',
  license: 'AI-generated project audio. Provider terms apply.',
  clips, aliases,
}, null, 2) + '\n');
console.log(`Imported ${Object.keys(clips).length} clips with source hashes and real audio envelopes.`);
