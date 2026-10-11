"""Package genuine Flutter frames without retouching their contents.

Only uniform image scaling and separate labels/margins are applied to the
comparison sheets. Raw captures remain byte-identical in the downloadable ZIP.
This does not generate an Android, hardware, animation or performance claim.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
BASE = "bef1403ed5d0243f8c6daca2717e998081cab15e"
MODULES = {
    "plus-bis-10-reference": "Plus bis 10",
    "minus-bis-10": "Minus bis 10",
    "formen": "Formen",
    "uhr": "Uhrzeit",
    "zahlen-bis-10": "Zahlen bis 10",
}
LAYOUTS = {
    "phone-360x800": ("Smartphone", [360, 800], 1),
    "fold-2176x1812-density-225": ("Fold-Konfiguration", [2176, 1812], 2.25),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    variant = "Bold" if bold else "Regular"
    return ImageFont.truetype(
        str(ROOT / f"assets/fonts/Nunito-{variant}.ttf"), size=size
    )


def contain(canvas: Image.Image, path: Path, box: tuple[int, int, int, int]) -> None:
    with Image.open(path) as original:
        image = original.convert("RGB")
        x, y, width, height = box
        scale = min(width / image.width, height / image.height)
        size = (round(image.width * scale), round(image.height * scale))
        image = image.resize(size, Image.Resampling.LANCZOS)
        canvas.paste(
            image, (x + (width - size[0]) // 2, y + (height - size[1]) // 2)
        )


def comparison(
    before: Path, after: Path, reference: Path, output: Path, title: str, fold: bool,
    footer_lines: tuple[str, str] | None = None,
) -> None:
    # Both runtime images retain their complete aspect ratio and framing.
    widths = (968, 360, 968) if fold else (360, 360, 360)
    margin, gap, image_height = 24, 20, 806 if fold else 800
    width = sum(widths) + 2 * margin + 2 * gap
    canvas = Image.new("RGB", (width, image_height + 206), "#f2f5fa")
    draw = ImageDraw.Draw(canvas)
    draw.text((margin, 18), title, font=font(30, True), fill="#123351")
    draw.text(
        (margin, 60),
        "Echte Flutter-Testlaufzeit | keine physische Android-Aufnahme",
        font=font(18),
        fill="#37546a",
    )
    x = margin
    for label, path, column in zip(
        ("VORHER", "ORIGINALREFERENZ", "NACHHER"),
        (before, reference, after),
        widths,
    ):
        draw.text((x, 94), label, font=font(20, True), fill="#123351")
        contain(canvas, path, (x, 126, column, image_height))
        x += column + gap
    footer = footer_lines or (
        "Vollständige Frames; nur proportional skaliert. Aufgaben zufällig, nicht identisch.",
        "Altversion: mögliche fehlende Emoji-Schrift im Linux-Testhost. Rohbilder im ZIP.",
    )
    draw.text(
        (margin, image_height + 144),
        footer[0],
        font=font(16),
        fill="#37546a",
    )
    draw.text(
        (margin, image_height + 170),
        footer[1],
        font=font(16),
        fill="#37546a",
    )
    canvas.save(output, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", type=Path, required=True)
    parser.add_argument("--after", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--baseline-manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--source-commit", required=True)
    args = parser.parse_args()
    if len(args.source_commit) != 40:
        raise ValueError("An actual full Git source SHA is required")
    # Verify this is a real repository commit, not a generated label.
    subprocess.run(
        ["git", "-C", str(ROOT), "cat-file", "-e", f"{args.source_commit}^{{commit}}"],
        check=True,
    )
    args.output.mkdir(parents=True, exist_ok=True)
    comparisons = args.output / "comparisons"
    comparisons.mkdir(exist_ok=True)
    manifest = {
        "sourceCommit": args.source_commit,
        "baselineCommit": BASE,
        "runtime": "Flutter 3.44.9 / Linux widget test renderer",
        "physicalAndroidTest": False,
        "fpsMeasured": False,
        "capturePixelRatio": 1,
        "fold": {
            "physicalViewport": [2176, 1812],
            "density": 2.25,
            "logicalViewport": [2176 / 2.25, 1812 / 2.25],
            "note": "PNG is captured at logical pixel ratio 1, not 2176px wide",
        },
        "limitations": [
            "Random tasks differ between baseline and current frames",
            "Legacy emoji font fallback may be unavailable on this Linux host",
            "Captures use reduced animation and no synthetic speech",
            "No physical Samsung, APK install, audible voice or performance proof",
        ],
        "frames": [],
        "comparisons": [],
    }
    for label, name in MODULES.items():
        for layout, (device, _, _) in LAYOUTS.items():
            filename = f"{label}-{layout}.png"
            before, after = args.before / filename, args.after / filename
            output = comparisons / f"Lumo-{label}-{layout}-Vergleich.png"
            comparison(
                before,
                after,
                args.reference,
                output,
                f"{name} | {device}",
                fold=layout.startswith("fold"),
            )
            manifest["comparisons"].append(
                {"file": f"comparisons/{output.name}", "sha256": sha256(output)}
            )
    for kind, directory in (("before", args.before), ("after", args.after)):
        for path in sorted(directory.glob("*.png")):
            with Image.open(path) as image:
                size = list(image.size)
            manifest["frames"].append(
                {
                    "file": f"{kind}/{path.name}",
                    "sha256": sha256(path),
                    "sizeBytes": path.stat().st_size,
                    "pngPixels": size,
                }
            )
    if len(manifest["frames"]) != 100:
        raise ValueError("Expected exactly 20 genuine before and 80 after frames")
    manifest_path = args.output / "LAUFZEIT-NACHWEIS.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    archive = args.output / "Lumo-Lernmodule-echte-Vergleiche-und-Laufzeitbilder.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for kind, directory in (("before", args.before), ("after", args.after)):
            for path in sorted(directory.glob("*.png")):
                bundle.write(path, f"{kind}/{path.name}")
        for path in sorted(comparisons.glob("*.png")):
            bundle.write(path, f"comparisons/{path.name}")
        bundle.write(args.reference, "original-reference/51024.jpg")
        bundle.write(args.baseline_manifest, "BASELINE-SOURCE-MANIFEST.json")
        bundle.write(manifest_path, manifest_path.name)
    with zipfile.ZipFile(archive) as bundle:
        corrupt = bundle.testzip()
        if corrupt:
            raise ValueError(f"Corrupt evidence member: {corrupt}")
    receipt = {
        "file": archive.name,
        "sizeBytes": archive.stat().st_size,
        "sha256": sha256(archive),
        "crcVerified": True,
        "sourceCommit": args.source_commit,
        "rawFrames": 100,
        "comparisons": 10,
    }
    (args.output / "ZIP-VERIFICATION.json").write_text(
        json.dumps(receipt, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
