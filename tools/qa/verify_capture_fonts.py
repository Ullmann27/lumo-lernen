#!/usr/bin/env python3
"""Reject Flutter Ahem-font placeholder rectangles in visual QA screenshots.

Flutter's default test font draws each glyph as a solid block. This test
looks for its telltale uninterrupted *light* rectangles in the header text
area; it does not identify or transcribe any text (no OCR). It is a visual
artifact-quality gate, not a functional or accessibility test.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys
from PIL import Image


def header_white_run_lengths(path: Path) -> list[int]:
    with Image.open(path) as image:
        image.load()
        rgb = image.convert("RGB")
    width, height = rgb.size
    if width < 400 or height < 500:
        raise ValueError(f"Unexpected screenshot size {width}x{height}: {path}")
    # Inspect the top quarter, where the actual app header and hero copy live.
    top = min(height - 1, max(0, round(height * 0.055)))
    bottom = min(height, max(top + 10, round(height * 0.235)))
    px = rgb.load()
    lengths: list[int] = []
    for y in range(top, bottom):
        run = longest = 0
        for x in range(2, width - 2):
            red, green, blue = px[x, y]
            if red >= 224 and green >= 224 and blue >= 224:
                run += 1
                longest = max(longest, run)
            else:
                run = 0
        lengths.append(longest)
    return lengths


def assert_real_text_rendering(path: Path) -> dict:
    lengths = header_white_run_lengths(path)
    with Image.open(path) as image:
        width, height = image.size
    long_run = max(75, round(width * 0.13))
    streak = highest_streak = 0
    for pixels in lengths:
        streak = streak + 1 if pixels >= long_run else 0
        highest_streak = max(highest_streak, streak)
    # Ahem's solid placeholder lines in the original 1977 evidence have
    # uninterrupted widths 190-268 px for 40-96 rows. A legitimate glyph
    # consists of strokes with internal negative space, not filled bars.
    if highest_streak >= 9:
        raise ValueError(
            f"Unusable visual evidence (likely Ahem test font): {path}; "
            f"{highest_streak} consecutive rows contain a >= {long_run}-pixel "
            "solid light rectangle. Load real Nunito + MaterialIcons first."
        )
    return {
        "file": str(path),
        "width": width,
        "height": height,
        "max_near_white_run": max(lengths, default=0),
        "continuous_solid_bar_rows": highest_streak,
        "status": "PASS",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    root: Path = args.directory
    if not root.is_dir():
        parser.error(f"Missing capture directory: {root}")
    patterns = ("abc_premium_*.png", "cross_grade_*.png")
    files = sorted({p for glob in patterns for p in root.glob(glob)})
    if len(files) != 6:
        parser.error(f"Expected exactly six new ABC and cross-grade screens, found {len(files)}")
    failures = []
    for path in files:
        try:
            print("FONT_VISUAL_QA", assert_real_text_rendering(path))
        except (OSError, ValueError) as error:
            failures.append(str(error))
            print("FONT_VISUAL_QA_FAILED", error, file=sys.stderr)
    if failures:
        return 1
    print("FONT_VISUAL_QA_PASS: six complete screenshots without Ahem bars")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
