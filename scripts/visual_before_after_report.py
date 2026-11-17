#!/usr/bin/env python3
"""Render genuine, version-pinned side-by-side PNGs from Flutter captures.

No synthetic screenshots: image sources are the byte-for-byte rasterizations
saved by the actual Flutter widget trees on the pinned 1986 and 1987 commits.
"""
from __future__ import annotations

import hashlib
from html import escape
import json
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

SIZES = ("phone-412x915", "fold-cover-344x882", "fold-open-690x829")
SCENES = (
    ("denkprofil-01-oeffnen", "Denkprofil – Start / bisheriger Fragescreen"),
    ("denkprofil-02-erste-frage", "Denkprofil – erste Frage"),
    ("knobel-01-start", "Knobeltest – Start und Entdeckermodus"),
    ("knobel-02-bereich", "Knobeltest – Bereichseinführung"),
    ("knobel-03-raetsel", "Knobeltest – erstes Rätsel"),
)

def _digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def generate(root: Path, baseline_commit: str, candidate_commit: str) -> dict:
    if not baseline_commit or not candidate_commit or baseline_commit == candidate_commit:
        raise ValueError("Distinct immutable source revisions are required")
    dest = root / "vergleich"
    dest.mkdir(parents=True, exist_ok=True)
    records = []
    changed = 0
    for size in SIZES:
        for stem, title in SCENES:
            before = root / "before" / size / f"{stem}.png"
            after = root / "after" / size / f"{stem}.png"
            if not before.is_file() or not after.is_file():
                raise FileNotFoundError(f"Required matched screenshots missing: {before} / {after}")
            if before.stat().st_size < 10_000 or after.stat().st_size < 10_000:
                raise ValueError(f"Screenshot is suspiciously small: {stem} {size}")
            with Image.open(before) as before_img, Image.open(after) as after_img:
                old = before_img.convert("RGB")
                new = after_img.convert("RGB")
                if old.size != new.size:
                    raise ValueError(f"Same physical device size must match: {size}, {stem}")
                if old.width < 500 or old.height < 500:
                    raise ValueError(f"Rendered screenshot resolution too small: {size}, {stem}")
                def scaled(img: Image.Image) -> Image.Image:
                    target = min(470, img.width)
                    height = round(img.height * target / img.width)
                    return img.resize((target, height), Image.Resampling.LANCZOS)
                old, new = scaled(old), scaled(new)
                pad, header = 24, 72
                canvas = Image.new("RGB", (old.width * 2 + pad * 3,
                                           max(old.height, new.height) + header + pad),
                                   "#0b1a34")
                draw = ImageDraw.Draw(canvas)
                try:
                    font = ImageFont.truetype(
                        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
                except OSError:
                    font = ImageFont.load_default()
                draw.text((pad, 18), "VORHER  ·  1986", font=font, fill="#d9efff")
                draw.text((pad * 2 + old.width, 18), "NACHHER  ·  1987", font=font,
                          fill="#60e4ff")
                canvas.paste(old, (pad, header))
                canvas.paste(new, (pad * 2 + old.width, header))
                target = dest / f"{size}--{stem}.png"
                canvas.save(target, format="PNG", optimize=True)
            old_hash, new_hash = _digest(before), _digest(after)
            changed += old_hash != new_hash
            records.append({
                "title": title, "size": size, "scene": stem,
                "before": str(before.relative_to(root)),
                "after": str(after.relative_to(root)),
                "comparison": str(target.relative_to(root)),
                "before_sha256": old_hash, "after_sha256": new_hash,
            })
    if changed < 3:
        raise ValueError("Expected visible differences in at least three exact UI captures")
    manifest = {
        "kind": "genuine_flutter_raster_comparison",
        "baseline": baseline_commit,
        "candidate": candidate_commit,
        "source_tag": "lumo-v0.12.74-1986-integrated-reading",
        "pairs": records,
        "changed_pairs": changed,
        "note": "Flutter widget-render captures, not actual Samsung device photographs.",
    }
    (root / "MANIFEST.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    cards = "\n".join(
        f'<section><h2>{escape(r["title"])} · {escape(r["size"])}</h2>'
        f'<a href="{escape(r["comparison"])}">'
        f'<img loading="lazy" src="{escape(r["comparison"])}" '
        f'alt="{escape(r["title"])} Vorher und Nachher"></a>'
        f'<p><a href="{escape(r["before"])}">Original vorher</a> · '
        f'<a href="{escape(r["after"])}">Original nachher</a></p></section>'
        for r in records
    )
    html = f"""<!doctype html>
<html lang="de"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lumo · echte Vorher-Nachher-Screenshots</title>
<style>
body{{font:16px system-ui,sans-serif;background:#07162e;color:#effaff;
max-width:1060px;margin:auto;padding:22px}}
header{{border-bottom:1px solid #5aa9dd;padding:0 0 18px}}
section{{margin:28px 0;padding:16px;background:#153a60;border:1px solid #4ccff0;
border-radius:18px}}
img{{display:block;max-width:100%;height:auto;border-radius:8px}}
a{{color:#69e6ff}}small{{color:#b5d2e5}}
</style></head><body>
<header><h1>Lumo · Vorher / Nachher</h1>
<p>Links: Build 1986 (Originalstand), rechts: Build 1987 (Entwicklungsstand).</p>
<small>Beide Spalten stammen aus echten Flutter-Widget-Renderings mit identischen
Gerätegrößen. Keine Render-Konzepte oder retuschierten Screenshots.
Das sind keine Fotos eines echten Android-Geräts.</small>
<p><small>Baseline: {escape(baseline_commit)}<br>
Neuer Code: {escape(candidate_commit)}</small></p></header>
{cards}
</body></html>"""
    (root / "index.html").write_text(html, encoding="utf-8")
    return manifest

if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: render_report.py OUTPUT_DIR BASELINE_SHA CANDIDATE_SHA")
    result = generate(Path(sys.argv[1]), sys.argv[2], sys.argv[3])
    print(f"Compared {len(result['pairs'])} genuine screenshot pairs; "
          f"{result['changed_pairs']} differ.")
