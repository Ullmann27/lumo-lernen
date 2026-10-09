"""Bounded screenshot-reader fallback, never a runtime or visibility PASS."""
from __future__ import annotations

import csv
import hashlib
import json
import math
from pathlib import Path
import time

from PIL import Image, ImageChops


class ClippedOCRWord(RuntimeError):
    """An internal crop edge cannot prove a whole requested caption."""


def tile_boxes(width: int, height: int) -> list[tuple[int, int, int, int]]:
    """Cover the entire observed frame; no game-control region is assumed."""
    if width <= 0 or height <= 0:
        raise ValueError('A current nonempty screenshot is required')
    return [(max(0, math.floor(column * width / 3) - 80),
             max(0, math.floor(row * height / 2) - 80),
             min(width, math.ceil((column + 1) * width / 3) + 80),
             min(height, math.ceil((row + 1) * height / 2) + 80))
            for column in range(3) for row in range(2)]


def observed_bounds(word: dict, box: tuple, scale: int, frame: tuple) -> list[float]:
    left, top, width, height = (int(word[field]) for field in ('left', 'top', 'width', 'height'))
    x0, y0, x1, y1 = box
    frame_width, frame_height = frame
    if (scale <= 0 or not (0 <= x0 < x1 <= frame_width and 0 <= y0 < y1 <= frame_height)
            or left < 0 or top < 0 or width <= 0 or height <= 0
            or left + width > (x1 - x0) * scale
            or top + height > (y1 - y0) * scale):
        raise RuntimeError('OCR word bounds exceed the current screenshot tile')
    if ((left == 0 and x0 > 0) or (top == 0 and y0 > 0)
            or (left + width == (x1 - x0) * scale and x1 < frame_width)
            or (top + height == (y1 - y0) * scale and y1 < frame_height)):
        raise ClippedOCRWord('OCR word touches an internal crop edge and may be clipped')
    return [x0 + left / scale, y0 + top / scale,
            x0 + (left + width) / scale, y0 + (top + height) / scale]


def observed_matches(rows, box: tuple, scale: int, frame: tuple, wanted: str,
                     normalize, variant: str) -> list[dict]:
    groups = {}
    for word in rows:
        if not word.get('text', '').strip():
            continue
        confidence = float(word['conf'])
        if not math.isfinite(confidence):
            raise RuntimeError('Non-finite OCR confidence')
        if confidence < 15:
            continue
        try:
            bounds = observed_bounds(word, box, scale, frame)
        except ClippedOCRWord:
            # Overlap lets another tile read the complete glyphs. A truncated
            # unrelated 3D shape must not invalidate every caption in a tile.
            continue
        key = tuple(word[field] for field in ('page_num', 'block_num', 'par_num', 'line_num'))
        groups.setdefault(key, []).append((word['text'], bounds, confidence))
    matches = []
    for words in groups.values():
        words.sort(key=lambda word: word[1][0])
        for start in range(len(words)):
            for end in range(start + 1, min(len(words), start + 8) + 1):
                span = words[start:end]
                text = ' '.join(word[0] for word in span)
                if normalize(text) != wanted:
                    continue
                matches.append({'text': text, 'bounds': [min(word[1][0] for word in span),
                                 min(word[1][1] for word in span), max(word[1][2] for word in span),
                                 max(word[1][3] for word in span)], 'variant': variant,
                                'confidence': min(word[2] for word in span)})
    return matches


def read_tiled_word(source: Path, out: Path, tag: str, wanted: str, normalize,
                    command, *, timeout: float = 45, clock=time.monotonic) -> list[dict]:
    """Read the unchanged current image with six overlapping neutral-text tiles."""
    started = clock()
    deadline = started + timeout
    before = hashlib.sha256(source.read_bytes()).hexdigest()
    image = Image.open(source).convert('RGB')
    red, green, blue = image.split()
    darkest = ImageChops.darker(ImageChops.darker(red, green), blue)
    lightest = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    bright = darkest.point(lambda value: 255 if value >= 150 else 0)
    neutral = ImageChops.subtract(lightest, darkest).point(lambda value: 255 if value <= 45 else 0)
    white_text = ImageChops.invert(ImageChops.multiply(bright, neutral))
    evidence = {'status': 'READING', 'scope': 'Independent OCR; no gameplay or visibility PASS',
                'source': source.name, 'source_sha256': before,
                'surface': [image.width, image.height], 'wanted': wanted,
                'tile_scale': 3, 'confidence_minimum': 15, 'timeout_seconds': timeout,
                'tiles': [], 'matches': []}
    journal = out / (tag + '-ocr-tiles.json')
    try:
        if not wanted or timeout <= 0:
            raise ValueError('A requested word and positive OCR deadline are required')
        for index, box in enumerate(tile_boxes(image.width, image.height)):
            remaining = deadline - clock()
            if remaining <= 0:
                raise TimeoutError('Screenshot tile OCR deadline exceeded')
            variant = 'white-latin-tile-' + str(index)
            prefix = out / (tag + '-ocr-' + variant)
            pixels = white_text.crop(box)
            pixels.resize((pixels.width * 3, pixels.height * 3)).save(prefix.with_suffix('.png'))
            attempt = {'index': index, 'bounds': list(box), 'image': prefix.with_suffix('.png').name,
                       'tsv': prefix.with_suffix('.tsv').name, 'status': 'READING'}
            evidence['tiles'].append(attempt)
            tile_started = clock()
            remaining = deadline - tile_started
            if remaining <= 0:
                raise TimeoutError('Screenshot tile OCR deadline exceeded')
            attempt['output'] = command('tesseract', str(prefix.with_suffix('.png')), str(prefix),
                                        '--psm', '11', '-l', 'eng', 'tsv',
                                        timeout=min(15, remaining))
            with prefix.with_suffix('.tsv').open() as stream:
                matches = observed_matches(csv.DictReader(stream, delimiter='\t'), box, 3,
                                           image.size, wanted, normalize, variant)
            attempt.update(status='READ', elapsed_seconds=round(clock() - tile_started, 6),
                           matches=matches)
            evidence['matches'].extend(matches)
            if clock() > deadline:
                raise TimeoutError('Screenshot tile OCR deadline exceeded')
            if matches:
                break
        if hashlib.sha256(source.read_bytes()).hexdigest() != before:
            raise RuntimeError('Current screenshot changed during OCR')
        evidence['status'] = 'READ'
        evidence['matched'] = bool(evidence['matches'])
        return evidence['matches']
    except Exception as error:
        evidence['status'] = 'FAIL'
        evidence['error'] = str(error)
        if evidence['tiles'] and evidence['tiles'][-1]['status'] == 'READING':
            evidence['tiles'][-1]['status'] = 'FAIL'
            evidence['tiles'][-1]['error'] = str(error)
        raise
    finally:
        evidence['elapsed_seconds'] = round(clock() - started, 6)
        journal.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + '\n')
