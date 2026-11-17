"""Genuine three-device games-hub before/after screenshot comparison."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

SIZES = ("phone", "fold", "reference-phone")


def compare(directory: Path, baseline: str, candidate: str) -> dict:
    if len(baseline) != 40 or len(candidate) != 40 or baseline == candidate:
        raise ValueError("Two distinct pinned Git source identities required")
    results = directory / "vergleich"
    results.mkdir(parents=True, exist_ok=True)
    records = []
    for size in SIZES:
        name = size + "_games.png"
        old = directory / "before" / name
        new = directory / "after" / name
        if not old.is_file() or not new.is_file():
            raise FileNotFoundError(name)
        if old.stat().st_size < 10_000 or new.stat().st_size < 10_000:
            raise ValueError("Unexpectedly tiny captured image: " + name)
        with Image.open(old) as former, Image.open(new) as newer:
            a = former.convert("RGB")
            b = newer.convert("RGB")
            if a.size != b.size or min(a.size) < 300:
                raise ValueError("Comparison must share real logical device size")
            diff = ImageChops.difference(a, b)
            visibly_altered = sum(1 for pixel in diff.getdata()
                                  if max(pixel) >= 32)
            visibly_altered_ratio = visibly_altered / (a.width * a.height)
            altered = visibly_altered_ratio >= 0.12
            target_width = min(500, a.width)
            target_height = round(a.height * target_width / a.width)
            a = a.resize((target_width, target_height), Image.Resampling.LANCZOS)
            b = b.resize((target_width, target_height), Image.Resampling.LANCZOS)
            canvas = Image.new("RGB", (target_width * 2 + 72,
                                       target_height + 100), "#071c38")
            draw = ImageDraw.Draw(canvas)
            try:
                font = ImageFont.truetype(
                    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 19)
            except OSError:
                font = ImageFont.load_default()
            draw.text((24, 24), "VORHER · 1989", font=font, fill="#e6f6ff")
            draw.text((target_width + 48, 24), "NACHHER · 1990",
                      font=font, fill="#53e0ff")
            canvas.paste(a, (24, 70))
            canvas.paste(b, (target_width + 48, 70))
            target = results / (size + "_games_vorher_nachher.png")
            canvas.save(target)
        records.append({
            "device": size, "changed": altered,
            "visibly_changed_ratio": round(visibly_altered_ratio, 4),
            "original_before": "before/" + name,
            "original_after": "after/" + name,
            "comparison": "vergleich/" + target.name,
            "before_sha256": hashlib.sha256(old.read_bytes()).hexdigest(),
            "after_sha256": hashlib.sha256(new.read_bytes()).hexdigest(),
        })
    if not all(r["changed"] for r in records):
        raise ValueError("Visible design change below 12% on at least one device")
    manifest = {
        "type": "actual_flutter_rendered_screenshots",
        "baseline_sha": baseline, "candidate_sha": candidate,
        "baseline_release": "lumo-v0.12.77-1989-test",
        "note": "Flutter raster captures, not physical Samsung screenshots.",
        "pairs": records,
    }
    (directory / "MANIFEST.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    page = ['<!doctype html><html lang="de"><meta charset="utf-8">',
            '<title>Lumo Spielewelt – Vorher/Nachher</title>',
            '<style>body{font:16px system-ui;background:#081d37;color:white;',
            'padding:22px;max-width:1100px;margin:auto}img{max-width:100%}',
            'section{border-bottom:1px solid #44ccea;padding:22px 0}</style>',
            '<h1>Spielewelt: Originalscreenshots 1989 / 1990</h1>']
    for r in records:
        page += ['<section><h2>' + r["device"] + '</h2>',
                 '<img src="' + r["comparison"] + '">',
                 '<p>Sichtbar verändert: ' + str(round(r["visibly_changed_ratio"] * 100, 1)) + '%</p></section>']
    page.append("</html>")
    (directory / "index.html").write_text("\n".join(page), encoding="utf-8")
    return manifest


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: script OUTPUT BASE_SHA CANDIDATE_SHA")
    report = compare(Path(sys.argv[1]), sys.argv[2], sys.argv[3])
    print("Genuine game-hub screenshot pairs:", len(report["pairs"]))
