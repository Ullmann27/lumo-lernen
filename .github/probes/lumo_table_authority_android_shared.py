#!/usr/bin/env python3
"""Shared observation contracts for the Memory and Quiz Android probes.

This module does not run the C4 probe or install, root, seed, or repair an app.
The game-specific subclasses retain their actual frames, controls, authority
ACKs, read-only saves, physical inputs, return observations and fixed budgets.
The fifteen pure geometry/JSON/APK/navigation functions are extracted exactly
from the published50503 C4 source; its C4 session logic is deliberately absent.
"""
from __future__ import annotations

import hashlib
import importlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import zipfile

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
FILES = '/data/user/0/' + PACKAGE + '/files'
SELF = '.github/probes/lumo_table_authority_android_shared.py'
PCK_PATH = 'assets/lumo_game.pck'
MODULE_PATHS = {
    'modernization_android_tour': '.github/probes/modernization_android_tour.py',
    'creative_android_probe': '.github/probes/creative_android_probe.py',
    'lumo_studio_surfaces_android_probe': '.github/probes/lumo_studio_surfaces_android_probe.py',
    'studio_creative_android_probe': '.github/probes/studio_creative_android_probe.py',
    'pr207_android_smoke': 'scripts/probes/pr207_android_smoke.py',
    'pr207_android_ui_probe': 'scripts/probes/pr207_android_ui_probe.py',
}
SOURCE_FILES = (SELF, *MODULE_PATHS.values(),
    '.github/probes/flutter_surface_readiness.py',
    'tools/android_qa/native_surface_readiness.py',
    'tools/android_qa/native_ocr_tiles.py',
    'tools/android_qa/kart_tour_evidence.py',
    'tools/android_qa/kart_garage_evidence.py',
    'tools/android_qa/kart_android_race.py')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def flutter_hub_navigation_target(nodes, size, density):
    """Resolve only the currently visible Flutter route and its real control.

    Cards returns first to its own showcase. That page has a distinct Back
    button, not the main navigation tabs. Never search or swipe for a hidden
    tab while this intermediate route is still current.
    """
    require(len(size) == 2 and size[0] > 0 and size[1] > 0 and density > 0,
            'Actual navigation viewport and density required')
    own = [n for n in nodes if n.get('package') == PACKAGE]

    def labels(node):
        return {line.strip() for field in ('text', 'content-desc')
                for line in node.get(field, '').splitlines() if line.strip()}

    visible = set().union(*(labels(n) for n in own)) if own else set()
    if 'Spiel pausiert' in visible:
        action, caption = 'leave_paused_game', 'Zur Spieleauswahl'
    elif 'LUMO CARDS' in visible:
        action, caption = 'leave_cards_showcase', 'Zur Spielwelt zurück'
    elif 'Lumo Spielewelt' in visible:
        return {'action': 'hub_ready'}
    elif 'Spielen' in visible or 'Spiele' in visible:
        action = 'open_games_tab'
        caption = 'Spielen' if 'Spielen' in visible else 'Spiele'
    else:
        return None
    candidates = {}
    for node in own:
        if caption not in labels(node) or node.get('clickable') != 'true' or node.get('enabled', 'true') != 'true':
            continue
        match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
        if not match:
            continue
        rect = tuple(map(int, match.groups()))
        if (0 <= rect[0] < rect[2] <= size[0] and 0 <= rect[1] < rect[3] <= size[1] and
                rect[2] - rect[0] >= 48 * density and rect[3] - rect[1] >= 48 * density):
            candidates[rect] = {'action': action, 'caption': caption, 'bounds': list(rect)}
    require(len(candidates) <= 1, 'Ambiguous actual Flutter navigation control')
    return next(iter(candidates.values()), None)


def sha(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def verified_pck(apk, expected):
    require(type(expected) is str and re.fullmatch('[a-f0-9]{64}', expected),
            'Full expected PCK digest required')
    with zipfile.ZipFile(apk) as archive:
        require(archive.namelist().count(PCK_PATH) == 1,
                'Embedded PCK absent/ambiguous')
        digest = hashlib.sha256()
        with archive.open(PCK_PATH) as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(block)
    actual = digest.hexdigest()
    require(actual == expected, 'Actual APK PCK differs')
    return actual


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def parse_json(raw):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate JSON key: ' + key)
            result[key] = value
        return result
    def invalid(_):
        raise RuntimeError('Nonfinite JSON number')
    return json.loads(raw, object_pairs_hook=unique, parse_constant=invalid)


def number(value, name):
    require(type(value) in (int, float) and math.isfinite(value), 'Invalid number: ' + name)
    return float(value)


def integer(value, name, lo=0, hi=1_000_000_000):
    n = number(value, name)
    require(n.is_integer() and lo <= n <= hi, 'Invalid integer: ' + name)
    return int(n)


def vector(value, length, name):
    require(type(value) is list and len(value) == length, 'Invalid vector: ' + name)
    return [number(v, name) for v in value]


def rectangle(value, name):
    r = vector(value, 4, name)
    require(r[2] > 0 and r[3] > 0, 'Empty rectangle: ' + name)
    return r


def same_numbers(a, b, tolerance=1e-5):
    return len(a) == len(b) and all(abs(x-y) <= tolerance for x, y in zip(a, b))


def inside(rect, outer, tolerance=.15):
    return (rect[0] >= outer[0]-tolerance and rect[1] >= outer[1]-tolerance and
            rect[0]+rect[2] <= outer[0]+outer[2]+tolerance and
            rect[1]+rect[3] <= outer[1]+outer[3]+tolerance)


def project(layout, world):
    """Recompute orthographic projection; native reported pixels are not used."""
    camera = layout['camera']; axes = [vector(v,3,'camera axis') for v in camera['basis']]
    origin = vector(camera['origin'],3,'camera origin')
    require(len(axes)==3 and camera['projection']=='orthogonal', 'Unsupported camera')
    dot = lambda a,b: sum(x*y for x,y in zip(a,b))
    require(all(abs(dot(v,v)-1) < 1e-4 for v in axes) and
            all(abs(dot(axes[a],axes[b])) < 1e-4 for a,b in ((0,1),(0,2),(1,2))), 'Non-orthonormal camera')
    size = number(camera['size'],'camera size'); require(.5 <= size <= 100,'Unreasonable camera size')
    vp = vector(layout['viewport_px'],2,'viewport'); win = vector(layout['window_px'],2,'window')
    require(min(vp+win)>0, 'Invalid render size')
    aspect = vp[0]/vp[1]
    keep = integer(camera['keep_aspect'],'camera keep_aspect',0,1)
    width,height = (size,size/aspect) if keep == 0 else (size*aspect,size)
    relative = [world[i]-origin[i] for i in range(3)]
    require(dot(relative,axes[2]) < 0, 'Geometry behind camera')
    return [(0.5+dot(relative,axes[0])/width)*win[0],
            (0.5-dot(relative,axes[1])/height)*win[1]]


def to_decor(layout, point):
    r = layout['android_observation']['render_rect']; w = layout['window_px']
    return [r[0]+point[0]*r[2]/w[0],r[1]+point[1]*r[3]/w[1]]


def button_target(layout, identifier, density):
    found=[b for b in layout['buttons'] if b['id']==identifier]
    require(len(found)==1,'Required button missing/ambiguous: '+identifier)
    b=found[0]
    require(b.get('visible') is True and b.get('enabled') is True and b.get('clipped') is False,'Button is hidden, disabled or clipped: '+identifier)
    rect=rectangle(b['rect_px'],'button');hit=rectangle(b['hit_rect_px'],'hit rectangle')
    require(inside(hit,rect) and inside(hit,layout['safe_rect']), 'Touch is outside control/safe view')
    first=to_decor(layout,hit[:2]);last=to_decor(layout,[hit[0]+hit[2],hit[1]+hit[3]])
    dp=[(last[i]-first[i])/density for i in (0,1)]
    require(min(dp)>=48-.01,'Actual exposed touch target smaller than48dp')
    return {'id':identifier,'text':b['text'],'hit_rect_px':hit,'decor_bounds':[first[0],first[1],last[0],last[1]],
            'size_dp':dp,'point':[(first[i]+last[i])/2 for i in (0,1)]}


def before_deadline(deadline, limit=30):
    require(type(deadline) in (int, float) and math.isfinite(deadline),
            'A finite existing probe deadline is required')
    remaining = deadline - time.monotonic()
    require(remaining > 0, 'Authority probe deadline exhausted')
    return min(limit, remaining)


def checked_source_binding(root, expected, paths, deadline, *, executing_file=None):
    """Read exact committed bytes; never trust only a matching HEAD string."""
    root = Path(root).resolve()
    require(type(expected) is str and re.fullmatch('[a-f0-9]{40}', expected),
            'Full expected Host SHA required for shared authority helpers')
    if executing_file is not None:
        require(Path(executing_file).resolve() == root / SELF,
                'Shared authority helper was imported from another checkout')

    def git(*arguments):
        result = subprocess.run(['git', '-C', str(root), *arguments],
                                capture_output=True, timeout=before_deadline(deadline),
                                env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})
        before_deadline(deadline)
        require(result.returncode == 0 and not result.stderr,
                'Source binding Git read failed: ' + arguments[0])
        return result.stdout

    require(git('rev-parse', 'HEAD').decode().strip() == expected,
            'Shared authority Host HEAD differs')
    commit_tree = git('rev-parse', 'HEAD^{tree}').decode().strip()
    require(re.fullmatch('[a-f0-9]{40}', commit_tree), 'Actual Host tree is missing')
    require(not git('status', '--porcelain', '--untracked-files=no').strip(),
            'Tracked shared authority checkout is dirty')
    hashes = {}
    require(len(set(paths)) == len(paths), 'Duplicate shared source path')
    for relative in paths:
        require(type(relative) is str and relative and not Path(relative).is_absolute()
                and '..' not in Path(relative).parts, 'Unsafe shared source path')
        file = root / relative
        require(file.is_file() and not file.is_symlink() and file.resolve().is_relative_to(root),
                'Shared source is absent or outside the candidate')
        original = git('show', 'HEAD:' + relative)
        actual = file.read_bytes()
        require(actual == original, 'Working shared source differs: ' + relative)
        hashes[relative] = hashlib.sha256(actual).hexdigest()
    before_deadline(deadline)
    return {'host': expected, 'tree': commit_tree, 'source_sha256': hashes}


def bound_module(module, root, relative):
    require(getattr(module, '__file__', None) is not None and
            Path(module.__file__).resolve() == Path(root).resolve() / relative,
            'Runtime module came from another checkout: ' + relative)
    return module


class AndroidProbe:
    """Only the inherited API used by the two game-specific probes."""
    def __init__(self, args):
        before_deadline(self.deadline)
        self.args, self.out = args, args.out
        self.count, self.events = 0, []
        require(Path.cwd().resolve() == args.candidate_source.resolve(),
                'Shared authority probe requires its candidate source CWD')
        require(not self.out.exists() or not any(self.out.iterdir()),
                'Refusing to overwrite previous authority evidence')
        self.out.mkdir(parents=True, exist_ok=True)
        self.initial_shared_binding = self.bind_shared_sources()
        write(self.out / 'shared-source-binding-initial.json', self.initial_shared_binding)
        os.environ['ANDROID_SERIAL'] = args.serial
        for relative in ('.github/probes', 'scripts/probes', 'tools/android_qa'):
            sys.path.insert(0, str(args.candidate_source / relative))
        loaded = {name: bound_module(importlib.import_module(name), args.candidate_source, relative)
                  for name, relative in MODULE_PATHS.items()}
        self.tour = loaded['modernization_android_tour']
        self.probe = bound_module(self.tour.probe, args.candidate_source,
                                  MODULE_PATHS['creative_android_probe'])
        self.base = bound_module(self.tour.base, args.candidate_source,
                                 MODULE_PATHS['pr207_android_smoke'])
        self.live = bound_module(self.tour.live, args.candidate_source,
                                 MODULE_PATHS['pr207_android_ui_probe'])
        self.surfaces = loaded['lumo_studio_surfaces_android_probe']
        self.creative = loaded['studio_creative_android_probe']
        require(self.bind_shared_sources() == self.initial_shared_binding,
                'Shared source changed while importing observed helpers')
        self.old_adb = self.base.adb
        self.base.adb = self.adb

    def bind_shared_sources(self):
        return checked_source_binding(self.args.candidate_source, self.args.expected_source,
                                      SOURCE_FILES, self.deadline, executing_file=__file__)

    def tag(self, name):
        self.count += 1
        return f'{self.count:04d}-{name}'

    def pid(self):
        value = self.adb('shell', 'pidof', PACKAGE + ':lumo_game', check=False).strip()
        require(re.fullmatch(r'[1-9]\d*', value) is not None,
                'Actual isolated table process absent or ambiguous')
        return int(value)

    def wait(self, name, observe, accept, timeout=45):
        deadline = time.monotonic() + min(timeout, before_deadline(self.deadline, timeout))
        errors = []
        while time.monotonic() < deadline:
            try:
                value = observe()
                if accept(value):
                    before_deadline(min(deadline, self.deadline))
                    return value
            except (RuntimeError, json.JSONDecodeError, KeyError, TypeError) as error:
                errors.append(str(error))
            time.sleep(min(.4, max(0, deadline - time.monotonic())))
        write(self.out / (self.tag(name) + '-failure.json'),
              {'last_errors': errors[-12:], 'budget_seconds': timeout})
        raise RuntimeError(name + ' not observed before deadline')
