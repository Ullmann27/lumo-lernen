"""Observe the real Flutter host after game exit, without navigation or restart.

A dead native process alone can leave its last compositor frame visible. Two
fresh host observations therefore require MainActivity, live Flutter semantics
and text pixels from their corresponding complete screenshots.
"""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import re
import sys
import time
import unicodedata
import xml.etree.ElementTree as ET

from PIL import Image

SHELL_CAPTIONS = ('start', 'lernen', 'spielen', 'profil')


def normalized(value):
    plain = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', plain.lower())


def shell_bounds(root, package, pixels):
    """Use visible current package-owned navigation captions, never fixed boxes."""
    width, height = pixels
    matches = {caption: [] for caption in SHELL_CAPTIONS}
    for node in root.iter('node'):
        if (node.get('package') != package or node.get('enabled') == 'false' or
                node.get('visible-to-user') == 'false' or
                node.get('clickable') != 'true'):
            continue
        lines = {normalized(line) for key in ('text', 'content-desc')
                 for line in node.get(key, '').splitlines()}
        for caption in set(SHELL_CAPTIONS) & lines:
            box = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
            if box is None:
                continue
            bounds = list(map(int, box.groups()))
            x0, y0, x1, y1 = bounds
            if not 0 <= x0 < x1 <= width or not 0 <= y0 < y1 <= height:
                continue
            if not any(max(abs(a-b) for a, b in zip(bounds, old)) <= 4 for old in matches[caption]):
                matches[caption].append(bounds)
    return {caption: boxes[0] for caption, boxes in matches.items() if len(boxes) == 1}


def return_observation(observed, package, previous=None):
    resumed = [line for line in observed['foreground'].splitlines()
               if 'mResumedActivity' in line or 'topResumedActivity' in line]
    components = [component for line in resumed
                  for component in re.findall(r'\b([A-Za-z0-9_.]+)/([A-Za-z0-9_.]+)', line)]
    host_class = package.removesuffix('.coachpreview') + '.MainActivity'
    host = bool(resumed) and len(components) == len(resumed) and all(
        observed_package == package and
        (observed_package+component if component.startswith('.') else component) == host_class
        for observed_package, component in components)
    surface = observed['surface']
    reasons = []
    if not host:
        reasons.append('exact Flutter MainActivity is not the observed foreground')
    if observed['native_process'].strip():
        reasons.append('native game process is still present')
    if not surface['complete_png'] or max(surface['blank_edge_columns'].values()) >= surface['pixels'][0] * .20:
        reasons.append('observed complete Flutter surface is not available')
    if set(observed['semantics']) != set(SHELL_CAPTIONS):
        reasons.append('visible live Flutter navigation semantics are absent or ambiguous')
    if not all(observed['pixel_captions'].get(caption, {}).get('matches') and
               observed['pixel_captions'][caption].get('source_png_sha256') == surface['source_sha256']
               for caption in SHELL_CAPTIONS):
        reasons.append('current screenshot pixels do not confirm the live Flutter captions')
    result = {'observed': observed, 'valid': not reasons, 'stable': False, 'reasons': reasons}
    if result['valid'] and previous and previous['valid']:
        before = previous['observed']
        result['stable'] = (before['capture']['file'] != observed['capture']['file'] and
                            before['xml_file'] != observed['xml_file'] and
                            before['surface']['pixels'] == surface['pixels'] and
                            all(max(abs(a-b) for a, b in zip(before['semantics'][caption],
                                                            observed['semantics'][caption])) <= 12
                                for caption in SHELL_CAPTIONS))
    return result


def wait_flutter_return(observe, record, package, *, timeout=60,
                        clock=time.monotonic, sleep=time.sleep):
    began, previous = clock(), None
    deadline = began + timeout
    evidence = {'status': 'RUNNING', 'observations': [],
                'scope': 'read-only MainActivity, fresh live XML and two complete pixel-confirmed Flutter frames; no restart'}
    try:
        while clock() < deadline:
            observed = observe(len(evidence['observations']), timeout=deadline-clock())
            current = return_observation(observed, package, previous)
            evidence['observations'].append(current)
            record(evidence)
            if clock() >= deadline:
                raise TimeoutError('Actual Flutter return observation exceeded its total deadline')
            if current['stable']:
                evidence.update(status='PASS', elapsed_seconds=round(clock()-began, 6))
                return evidence
            previous = current
            sleep(min(.5, max(0, deadline-clock())))
        raise TimeoutError('Two fresh visible Flutter frames did not arrive before the return deadline')
    except Exception as error:
        evidence.update(status='FAIL', error=str(error), elapsed_seconds=round(clock()-began, 6))
        raise
    finally:
        record(evidence)


def observe_flutter_return(base, creative, out, package, index, *, timeout):
    """All external reads share the caller's remaining wall-time budget."""
    from native_surface_readiness import inspect_surface
    deadline = time.monotonic() + timeout
    tag = f'13-flutter-return-{index:02d}'

    def remaining():
        value = deadline-time.monotonic()
        if value <= 0:
            raise TimeoutError('Actual Flutter return read deadline expired')
        return value

    def command(*args, adb=False, **kwargs):
        output = (base.adb if adb else base.command)(*args, timeout=min(15, remaining()), **kwargs)
        remaining()
        return output

    foreground = command('shell', 'dumpsys', 'activity', 'activities', adb=True)
    (out / (tag+'-foreground.txt')).write_text(foreground)
    native_process = command('shell', 'pidof', package+':lumo_game', adb=True, check=False)
    xml = out / (tag+'.xml')
    png = out / (tag+'.png')
    if xml.exists() or png.exists():
        raise RuntimeError('Flutter return requires newly acquired XML and PNG paths')
    # Reuse the existing pinned no-idle accessibility reader in a bounded
    # subprocess so a stalled HTTP/UI read cannot extend this total deadline.
    command(sys.executable, str(Path(__file__).resolve()), '--read-ui', str(out), tag)
    root = ET.fromstring(xml.read_text())
    if root.tag != 'hierarchy':
        raise RuntimeError('Fresh Flutter return XML lacks the Android hierarchy root')
    capture = creative.capture(out, tag, timeout=remaining())
    remaining()
    with Image.open(png) as image:
        image.verify()
    surface = inspect_surface(png)
    # Flutter is allowed to return in portrait. Keep the actual pixel/blank
    # checks; only the native reader's landscape prerequisite is inapplicable.
    surface['reasons'] = [reason for reason in surface['reasons']
                          if reason != 'native landscape surface has not arrived']
    surface['acceptable_for_target_sampling'] = not surface['reasons']
    surface['scope'] = 'Actual complete Flutter PNG and blank-edge check; portrait is allowed'
    surface['complete_png'] = base.png_complete(png.read_bytes())
    semantics = shell_bounds(root, package, surface['pixels'])
    pixels = {}
    with Image.open(png) as image:
        for caption, bounds in semantics.items():
            crop = out / (tag+'-'+caption+'-crop.png')
            image.crop(bounds).convert('RGB').resize(((bounds[2]-bounds[0])*2,
                                                     (bounds[3]-bounds[1])*2)).save(crop)
            prefix = out / (tag+'-'+caption+'-ocr')
            command('tesseract', str(crop), str(prefix), '--psm', '11', '-l', 'deu+eng', 'tsv')
            tsv = prefix.with_suffix('.tsv')
            matches = []
            for word in csv.DictReader(tsv.read_text().splitlines(), delimiter='\t'):
                if normalized(word.get('text', '')) == caption and float(word['conf']) >= 15:
                    x, y, width, height = (int(word[key]) for key in ('left', 'top', 'width', 'height'))
                    if 0 <= x < x+width <= (bounds[2]-bounds[0])*2 and 0 <= y < y+height <= (bounds[3]-bounds[1])*2:
                        matches.append([bounds[0]+x/2, bounds[1]+y/2,
                                        bounds[0]+(x+width)/2, bounds[1]+(y+height)/2])
            pixels[caption] = {'matches': matches, 'source_bounds': bounds,
                               'source_png_sha256': surface['source_sha256'], 'crop': crop.name,
                               'crop_sha256': hashlib.sha256(crop.read_bytes()).hexdigest(),
                               'tsv': tsv.name, 'tsv_sha256': hashlib.sha256(tsv.read_bytes()).hexdigest()}
    remaining()
    if hashlib.sha256(png.read_bytes()).hexdigest() != surface['source_sha256']:
        raise RuntimeError('Flutter return screenshot changed during its pixel inspection')
    return {'foreground': foreground, 'foreground_file': tag+'-foreground.txt',
            'foreground_sha256': hashlib.sha256(foreground.encode()).hexdigest(),
            'native_process': native_process, 'xml_file': xml.name,
            'xml_sha256': hashlib.sha256(xml.read_bytes()).hexdigest(),
            'capture': capture, 'surface': surface, 'semantics': semantics, 'pixel_captions': pixels}


if __name__ == '__main__':
    if len(sys.argv) != 4 or sys.argv[1] != '--read-ui':
        raise SystemExit('Use --read-ui OUTPUT_DIRECTORY UNIQUE_TAG')
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts/probes'))
    from pr207_android_ui_probe import live_nodes
    live_nodes(Path(sys.argv[2]), sys.argv[3])
