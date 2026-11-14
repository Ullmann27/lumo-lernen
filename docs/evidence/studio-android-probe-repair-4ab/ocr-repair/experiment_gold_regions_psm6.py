#!/usr/bin/env python3
"""Offline whole-frame color-component experiment; no app input."""
from collections import deque
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import unicodedata

from PIL import Image, ImageChops


def regions(image):
    width, height = image.size
    small = image.resize((math.ceil(width / 4), math.ceil(height / 4)), Image.Resampling.NEAREST)
    red, green, blue = small.split()
    mask = ImageChops.multiply(red.point(lambda v: 255 if v >= 140 else 0),
                              green.point(lambda v: 255 if v >= 80 else 0))
    mask = ImageChops.multiply(mask, ImageChops.subtract(red, green).point(lambda v: 255 if v >= 15 else 0))
    mask = ImageChops.multiply(mask, ImageChops.subtract(green, blue).point(lambda v: 255 if v >= 25 else 0))
    pixels = bytearray(mask.tobytes())
    sw, sh = small.size
    sx, sy = width / sw, height / sh
    found = []
    for index in range(len(pixels)):
        if not pixels[index]:
            continue
        pixels[index] = 0
        queue = deque([index])
        x0 = x1 = index % sw
        y0 = y1 = index // sw
        area = 0
        while queue:
            cell = queue.popleft()
            x, y = cell % sw, cell // sw
            x0, x1, y0, y1 = min(x0, x), max(x1, x), min(y0, y), max(y1, y)
            area += 1
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < sw and 0 <= ny < sh:
                    n = ny * sw + nx
                    if pixels[n]:
                        pixels[n] = 0
                        queue.append(n)
        cw, ch = x1 - x0 + 1, y1 - y0 + 1
        if cw * sx < 32 or ch * sy < 20 or cw * sx < ch * sy or ch * sy > height / 3:
            continue
        if area / (cw * ch) < .3:
            continue
        box = [max(0, math.floor(x0 * sx) - 8), max(0, math.floor(y0 * sy) - 8),
               min(width, math.ceil((x1 + 1) * sx) + 8), min(height, math.ceil((y1 + 1) * sy) + 8)]
        found.append((area, box))
    return [box for area, box in sorted(found, reverse=True)[:16]]


def main():
    os.environ['OMP_THREAD_LIMIT'] = '1'
    root = Path('/workspace/scratch/5987865ae883')
    sys.path.insert(0, str(root / 'lumo-studio-final-e3d/tools/android_qa'))
    from native_ocr_tiles import observed_matches
    normalize = lambda text: re.sub('[^a-z0-9]', '', unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode().lower())
    out = root / 'qa/ocr-original-scale-4ab/gold-region-psm6-german-experiment'
    out.mkdir(exist_ok=False)
    reports = []
    for api, index in [(35, 0), (35, 7), (37, 0), (37, 6)]:
        source = root / f'qa/studio-final-4ab96666/api{api}/selected-originals/nextgen/learning-move-1-{index}.png'
        before = hashlib.sha256(source.read_bytes()).hexdigest()
        with Image.open(source) as original:
            rgb = original.convert('RGB')
        boxes = regions(rgb)
        report = dict(api=api, frame=index, source=str(source), source_sha256=before,
                      boxes=boxes, attempts=[])
        for region, box in enumerate(boxes):
            prefix = out / f'api{api}-frame{index}-region{region}'
            rgb.crop(box).save(prefix.with_suffix('.png'))
            command = ['tesseract', str(prefix.with_suffix('.png')), str(prefix), '--psm', '6', '-l', 'deu+eng', 'tsv']
            start = time.monotonic()
            process = subprocess.run(command, timeout=15, capture_output=True, text=True)
            with prefix.with_suffix('.tsv').open() as stream:
                matches = observed_matches(csv.DictReader(stream, delimiter='\t', quoting=csv.QUOTE_NONE),
                                           tuple(box), 1, rgb.size, 'einobjektzeigen', normalize, 'gold-component-1x')
            report['attempts'].append(dict(command=command, region=region, box=box,
                                           exit_code=process.returncode, elapsed_seconds=time.monotonic() - start,
                                           stderr=process.stderr, exact_matches=matches))
            if matches:
                break
        report['source_unchanged'] = hashlib.sha256(source.read_bytes()).hexdigest() == before
        reports.append(report)
        print(json.dumps(report, ensure_ascii=False), flush=True)
    (out / 'experiment.json').write_text(json.dumps(dict(scope='Offline real OCR only, no app input', cases=reports), indent=2) + '\n')


if __name__ == '__main__':
    main()
