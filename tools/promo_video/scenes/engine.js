// Zeitsteuerung: Jede Szene hat data-in/data-out (Sekunden). setTime(t) stellt
// jede CSS-Animation exakt auf ihren Zeitpunkt – so entsteht Bild für Bild
// dasselbe Ergebnis (kein Echtzeit-Abspielen nötig).
const params = new URLSearchParams(location.search);
const FORMAT = params.get('f') === 'port' ? 'port' : 'land';
document.body.classList.add(FORMAT);

function seeded(seed) { let s = seed; return () => (s = (s * 16807) % 2147483647) / 2147483647; }

function fillStars() {
  document.querySelectorAll('.stars').forEach((box, k) => {
    const rnd = seeded(97 + k * 13);
    const n = +(box.dataset.n || 46);
    for (let i = 0; i < n; i++) {
      const s = document.createElement('i');
      const size = 2 + rnd() * 5;
      s.style.cssText = `left:${rnd() * 100}%;top:${rnd() * 100}%;width:${size}px;height:${size}px;--p:${2 + rnd() * 3}s;--d:${-rnd() * 5}s`;
      box.appendChild(s);
    }
  });
}

function applyConfig(cfg) {
  const a = cfg.angebot;
  document.querySelectorAll('[data-cfg]').forEach((el) => { el.textContent = a[el.dataset.cfg] ?? ''; });
}

const scenes = [];
function setup() {
  document.querySelectorAll('.scene').forEach((el) => {
    const s = { el, a: +el.dataset.in, b: +el.dataset.out };
    el.style.setProperty('--dur', (s.b - s.a + 0.7) + 's');
    scenes.push(s);
  });
  scenes.forEach((s, i) => { s.end = i + 1 < scenes.length ? scenes[i + 1].a + 0.7 : s.b; s.el.style.zIndex = i + 1; });
  // Zusätze nur für ein Format: data-port / data-land überschreiben Stilwerte.
  document.querySelectorAll(`[data-${FORMAT}]`).forEach((el) => { el.style.cssText += ';' + el.dataset[FORMAT]; });
  document.querySelectorAll(`img[data-src-${FORMAT}]`).forEach((el) => { el.src = el.dataset[FORMAT === 'port' ? 'srcPort' : 'srcLand']; });
}

window.DURATION = 0;
window.setTime = (t) => {
  for (const s of scenes) s.el.classList.toggle('on', t >= s.a && t < s.end);
  void document.body.offsetHeight;
  for (const anim of document.getAnimations()) {
    const target = anim.effect && anim.effect.target;
    const sc = target && target.closest('.scene');
    const base = sc ? +sc.dataset.in : 0;
    anim.currentTime = Math.max(0, (t - base) * 1000);
  }
};

window.ready = (async () => {
  const cfg = await (await fetch('../config.json')).json();
  applyConfig(cfg);
  fillStars();
  setup();
  window.DURATION = Math.max(...scenes.map((s) => s.b));
  await document.fonts.ready;
  await Promise.all([...document.images].map((im) => im.decode().catch(() => { im.dataset.fehlt = '1'; })));
  window.MISSING = [...document.images].filter((im) => !im.naturalWidth && im.getAttribute('src')).map((im) => im.getAttribute('src'));
  window.setTime(+(params.get('t') || 0));
  return true;
})();
