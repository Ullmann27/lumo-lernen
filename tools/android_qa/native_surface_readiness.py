"""Reject observed incomplete native frames before sampling a live touch target.

These checks are prerequisites, not proof of a working scene. Post-action UI,
save and reward assertions must still pass on the actual Android runtime.
"""
from __future__ import annotations

import hashlib
import math
from pathlib import Path

from PIL import Image


def inspect_surface(source: Path) -> dict:
    raw = source.read_bytes()
    with Image.open(source) as original:
        image = original.convert('RGB')
    width, height = image.size
    # Ignore Android status/navigation bars. Sample the native canvas itself;
    # a single dark tree/shadow is not a full-height missing viewport band.
    rows = [min(height - 1, round(height * fraction))
            for fraction in (.12, .22, .32, .42, .52, .62, .72, .82)]
    pixels = image.load()
    blank = [sum(max(pixels[x, y]) <= 8 for y in rows) >= 7
             for x in range(width)]
    left = next((index for index, value in enumerate(blank) if not value), width)
    right = next((index for index, value in enumerate(reversed(blank)) if not value), width)
    reasons = []
    if width <= height:
        reasons.append('native landscape surface has not arrived')
    if max(left, right) >= width * .20:
        reasons.append('observed blank edge band occupies at least20% of native surface')
    return {'source': source.name, 'source_sha256': hashlib.sha256(raw).hexdigest(),
            'source_bytes': len(raw),
            'pixels': [width, height], 'sample_rows': rows,
            'blank_edge_columns': {'left': left, 'right': right},
            'blank_threshold_rgb_max': 8, 'blank_required_rows': 7,
            'acceptable_for_target_sampling': not reasons, 'reasons': reasons,
            'scope': 'Reject observed partial surface; no scene/gameplay PASS'}


def target_observation(frame: dict, bounds, previous: dict | None = None,
                       *, anchor: str = '', tolerance: float = 12) -> dict:
    result = {'surface_sha256': frame['source_sha256'], 'pixels': frame['pixels'],
              'bounds': bounds, 'anchor': anchor, 'reasons': list(frame['reasons']),
              'target_geometry_valid': False, 'stable_observed_target': False}
    width, height = frame['pixels']
    if (not isinstance(bounds, (list, tuple)) or len(bounds) != 4
            or any(isinstance(value, bool) or not isinstance(value, (int, float))
                   or not math.isfinite(value) for value in bounds)):
        result['reasons'].append('invalid observed target bounds')
        return result
    x0, y0, x1, y1 = bounds
    if not 0 <= x0 < x1 <= width or not 0 <= y0 < y1 <= height:
        result['reasons'].append('observed target exceeds current screenshot')
    # These are source-confirmed layout anchors, never touch coordinates.
    # Treasure's Rucksack is in the right-aligned toolbar; Puzzle's start and
    # resume buttons are in its centered selection panel. Aim only at OCR.
    center_x = (x0 + x1) / (2 * width)
    if anchor == 'right-toolbar' and center_x < .70:
        result['reasons'].append('observed right-toolbar target is still in an old narrow layout')
    elif anchor == 'center-panel' and not .35 <= center_x <= .65:
        result['reasons'].append('observed centered target is still in an old narrow layout')
    elif anchor not in ('', 'right-toolbar', 'center-panel'):
        raise ValueError('Unknown source-confirmed native target anchor')
    if result['reasons']:
        return result
    result['target_geometry_valid'] = True
    if (previous is None or previous.get('pixels') != frame['pixels']
            or not previous.get('target_geometry_valid')
            or max(abs(a - b) for a, b in zip(bounds, previous['bounds'])) > tolerance):
        result['reasons'].append('waiting for second stable observed target bounds')
        return result
    result['stable_observed_target'] = True
    return result
