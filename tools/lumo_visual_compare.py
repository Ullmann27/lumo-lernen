#!/usr/bin/env python3
"""Compare immutable runtime captures or diagnose an original art reference.

Equal-size deterministic captures can fail a supplied regression threshold.
--fit-reference is explicit diagnostic alignment, never visual acceptance.
Requires Pillow, already used by the Android evidence tools.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageOps, ImageStat


def compare(reference: Path, actual: Path, output: Path, *, fit_reference=False,
            regions=None, max_changed_fraction=None, channel_threshold=24) -> dict:
    if not 0 <= channel_threshold <= 255:
        raise ValueError('channel threshold must be between 0 and 255')
    if max_changed_fraction is not None and not 0 <= max_changed_fraction <= 1:
        raise ValueError('changed fraction must be between 0 and 1')
    with Image.open(reference) as source:
        first = source.convert('RGB')  # Explicitly frame 0 for GIF references.
    with Image.open(actual) as source:
        second = source.convert('RGB')
    original_size = first.size
    if first.size != second.size:
        if not fit_reference:
            raise ValueError('Capture sizes differ; use --fit-reference only for diagnostic art comparison')
        first = first.resize(second.size, Image.Resampling.LANCZOS)
    areas = regions or {'full': [0, 0, 1, 1]}
    if not areas:
        raise ValueError('At least one comparison region is required')
    measured = {}
    for name, bounds in areas.items():
        if len(bounds) != 4 or not all(isinstance(v, (int, float)) for v in bounds):
            raise ValueError(f'Invalid normalized region: {name}')
        x0, y0, x1, y1 = bounds
        if not (0 <= x0 < x1 <= 1 and 0 <= y0 < y1 <= 1):
            raise ValueError(f'Region outside the capture: {name}')
        box = (round(x0 * second.width), round(y0 * second.height),
               round(x1 * second.width), round(y1 * second.height))
        if box[2] <= box[0] or box[3] <= box[1]:
            raise ValueError(f'Empty pixel region: {name}')
        diff = ImageChops.difference(first.crop(box), second.crop(box))
        maximum = ImageChops.lighter(ImageChops.lighter(diff.getchannel('R'),
                                   diff.getchannel('G')), diff.getchannel('B'))
        histogram = maximum.histogram()
        changed = sum(histogram[channel_threshold + 1:]) / (diff.width * diff.height)
        measured[name] = {'bounds': bounds, 'pixel_bounds': list(box),
                          'changed_fraction': round(changed, 6),
                          'mean_channel_delta': round(sum(ImageStat.Stat(diff).mean) / 3, 4)}
    report = {
        'reference': {'path': str(reference), 'sha256': hashlib.sha256(reference.read_bytes()).hexdigest(),
                      'size': list(original_size), 'frame': 0},
        'actual': {'path': str(actual), 'sha256': hashlib.sha256(actual.read_bytes()).hexdigest(),
                   'size': list(second.size)},
        'alignment': 'diagnostic resize' if fit_reference else 'equal-size runtime captures',
        'channel_threshold': channel_threshold,
        'max_changed_fraction': max_changed_fraction,
        'regions': measured,
        'within_threshold': None if max_changed_fraction is None else all(
            m['changed_fraction'] <= max_changed_fraction for m in measured.values()),
        'limitation': 'Pixel differences do not certify reference fidelity, accessibility or performance.',
    }
    output.mkdir(parents=True, exist_ok=True)
    diff = ImageChops.difference(first, second).convert('L')
    ImageOps.colorize(diff, '#03193F', '#FFC94A').save(output / 'difference.png')
    side = Image.new('RGB', (second.width * 2, second.height))
    side.paste(first, (0, 0))
    side.paste(second, (second.width, 0))
    side.save(output / 'reference-and-runtime.png')
    (output / 'comparison.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', type=Path, required=True)
    parser.add_argument('--actual', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--fit-reference', action='store_true')
    parser.add_argument('--regions', type=Path)
    parser.add_argument('--max-changed-fraction', type=float)
    args = parser.parse_args()
    report = compare(args.reference, args.actual, args.output,
                     fit_reference=args.fit_reference,
                     regions=json.loads(args.regions.read_text()) if args.regions else None,
                     max_changed_fraction=args.max_changed_fraction)
    print(json.dumps({'report': str(args.output / 'comparison.json'),
                      'regions': report['regions'], 'within_threshold': report['within_threshold']}))
    return 1 if report['within_threshold'] is False else 0


if __name__ == '__main__':
    raise SystemExit(main())
