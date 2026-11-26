// Rendert die Szenen Bild für Bild mit Chromium (Playwright) und setzt sie mit ffmpeg zusammen.
//   node render.mjs --format=land|port --out=build/x.mp4 [--from=0 --to=140] [--still=12.5,30 --dir=build/stills]
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../..');
const arg = Object.fromEntries(process.argv.slice(2).map((a) => a.replace(/^--/, '').split('=')));
const format = arg.format === 'port' ? 'port' : 'land';
const [W, H] = format === 'port' ? [1080, 1920] : [1920, 1080];
const cfg = JSON.parse(fs.readFileSync(path.join(here, 'config.json'), 'utf8'));
const fps = cfg.fps;

const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp', '.ttf': 'font/ttf' };
const server = http.createServer((req, res) => {
  const file = path.join(repo, decodeURIComponent(req.url.split('?')[0]));
  if (!file.startsWith(repo) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'content-type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}/tools/promo_video/scenes/index.html?f=${format}`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
page.on('pageerror', (e) => { console.error('Seitenfehler:', e.message); process.exitCode = 1; });
await page.goto(url);
await page.evaluate(() => window.ready);
const missing = await page.evaluate(() => window.MISSING);
if (missing.length) { console.error('Fehlende Bilder:', missing); process.exit(2); }
const duration = await page.evaluate(() => window.DURATION);

if (arg.still) {
  fs.mkdirSync(arg.dir, { recursive: true });
  for (const t of arg.still.split(',').map(Number)) {
    await page.evaluate((x) => window.setTime(x), t);
    await page.screenshot({ path: path.join(arg.dir, `${format}_${String(t.toFixed(1)).padStart(5, '0')}.jpg`), type: 'jpeg', quality: 88 });
  }
} else {
  const from = Math.round(+(arg.from ?? 0) * fps), to = Math.round(+(arg.to ?? duration) * fps);
  const ff = spawn('ffmpeg', ['-v', 'error', '-y', '-f', 'image2pipe', '-c:v', 'mjpeg', '-framerate', String(fps), '-i', '-',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '15', '-pix_fmt', 'yuv420p', '-r', String(fps), arg.out], { stdio: ['pipe', 'inherit', 'inherit'] });
  const done = new Promise((r) => ff.on('close', r));
  for (let f = from; f < to; f++) {
    await page.evaluate((x) => window.setTime(x), f / fps);
    const shot = await page.screenshot({ type: 'jpeg', quality: 95 });
    if (!ff.stdin.write(shot)) await new Promise((r) => ff.stdin.once('drain', r));
    if ((f - from) % 300 === 0) console.log(`${format} ${arg.out}: Bild ${f - from}/${to - from}`);
  }
  ff.stdin.end();
  const code = await done;
  if (code) process.exitCode = code;
}
console.log(JSON.stringify({ format, duration }));
await browser.close();
server.close();
