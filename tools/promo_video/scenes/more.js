// Montage „noch mehr Spiele“ und Sternenflug – aus Listen erzeugt, damit Reihenfolge
// und Takt (1,2 s je Bild) an einer Stelle stehen.
const MORE = [
  ['memory', 'Memory'],
  ['c4', 'Vier gewinnt'],
  ['quiz', 'Quizshow'],
  ['kart', 'Lumo Kart'],
  ['kart_vulkan', 'Neue Strecke: Vulkanexpress'],
  ['kart_wolken', 'Neue Strecke: Wolkensturm'],
  ['kart_flut', 'Neue Strecke: Kristallflut'],
  ['skypost', 'Sternenpost'],
  ['world', 'Offene Welt Sonnenhafen'],
];
(() => {
  const screen = document.getElementById('more-screen');
  const list = document.getElementById('more-list');
  const step = 1.3, start = 1.0;
  MORE.forEach(([file, label], i) => {
    const d = start + i * step;
    const img = document.createElement('img');
    img.className = 'zoom';
    img.src = `../build/cap/more_${file}.jpg`;
    img.style.cssText = `--d:${d}s;--zd:${step + 0.6}s`;
    screen.appendChild(img);
    const tag = document.createElement('span');
    tag.className = 'tag';
    tag.textContent = label;
    tag.style.cssText = `--d:${d + 0.05}s;--len:${i === MORE.length - 1 ? 2.4 : step - 0.05}s`;
    screen.appendChild(tag);
  });
  const names = ['Memory · Vier gewinnt · Quizshow', 'Lumo Kart mit neuen Strecken', 'Lumo Lauf · Sternenpost', 'Offene Welt Sonnenhafen'];
  const at = [0, 3, 7, 8];
  names.forEach((n, i) => {
    const row = document.createElement('div');
    row.className = 'row glass a right';
    row.style.cssText = `--d:${start + at[i] * step}s`;
    row.innerHTML = `<span class="ic">★</span><div>${n}</div>`;
    list.appendChild(row);
  });

  // Sterne fliegen vom Lern-Handy zum Spiel-Handy.
  const fly = document.getElementById('flyers');
  const port = new URLSearchParams(location.search).get('f') === 'port';
  const from = port ? [275, 1160] : [525, 700];
  const to = port ? [805, 1160] : [1395, 700];
  for (let i = 0; i < 14; i++) {
    const el = document.createElement('div');
    el.className = 'fly';
    const lift = 140 + (i % 5) * 46;
    el.style.cssText = `left:-32px;top:-32px;--d:${1.8 + i * 0.22}s;--x0:${from[0]}px;--y0:${from[1] + (i % 3) * 40 - 40}px;` +
      `--xm:${(from[0] + to[0]) / 2}px;--ym:${from[1] - lift}px;--x1:${to[0]}px;--y1:${to[1] + (i % 4) * 30 - 45}px`;
    el.innerHTML = '<div class="starwrap"><div class="star"></div></div>';
    fly.appendChild(el);
  }
})();
