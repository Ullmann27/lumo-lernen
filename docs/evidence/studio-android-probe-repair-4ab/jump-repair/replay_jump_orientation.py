#!/usr/bin/env python3
"""Replay the first real Jump pause against original frames, never an Android device."""
from __future__ import annotations

import argparse
import ast
import csv
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys
import time
from types import SimpleNamespace
import unicodedata

from PIL import Image, ImageChops


def load(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class FixtureExhausted(RuntimeError):
    pass


class FirstPauseReached(RuntimeError):
    pass


def replay(root: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=False)
    studio_path = root / '.github/probes/studio_creative_android_probe.py'
    helper_path = root / '.github/probes/creative_android_probe.py'
    studio = load(studio_path, 'jump_studio_replay')
    readiness = load(root / 'tools/android_qa/native_surface_readiness.py', 'jump_readiness_replay')
    tiles = load(root / 'tools/android_qa/native_ocr_tiles.py', 'jump_tiles_replay')
    base = load(root / 'scripts/probes/pr207_android_smoke.py', 'jump_command_replay')
    fixtures = root / 'scripts/tests/fixtures/studio_creative_android'
    images = [fixtures / ('jump-portrait-' + name + '.png') for name in ('first', 'second')]
    commands, snapshots = [], []

    def capture(_out, _tag, **_kwargs):
        if len(snapshots) == len(images):
            raise FixtureExhausted('Both original portrait frames were rejected; no further replay frames exist')
        source = images[len(snapshots)].resolve()
        snapshot = {'file': str(source), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()}
        snapshots.append(snapshot)
        return snapshot

    def adb(*args, **kwargs):
        commands.append({'args': list(args), 'kwargs': kwargs,
                         'scope': 'Offline recorded dispatch only; no adb process or device input'})
        return ''

    names = {'digest', 'normalized', 'image_lines', 'native_tap', 'native_text',
             'gold_caption_boxes', 'read_component_caption'}
    definitions = [node for node in ast.parse(helper_path.read_text()).body
                   if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in names]
    namespace = {'__name__': 'jump_native_replay', 'Path': Path, 'csv': csv,
                 'hashlib': hashlib, 'json': json, 'math': __import__('math'), 're': re,
                 'unicodedata': unicodedata, 'Image': Image, 'ImageChops': ImageChops,
                 'time': SimpleNamespace(monotonic=time.monotonic, sleep=lambda _delay: None),
                 'base': SimpleNamespace(command=base.command, adb=adb), 'capture': capture,
                 'inspect_surface': readiness.inspect_surface,
                 'target_observation': readiness.target_observation,
                 'read_tiled_word': tiles.read_tiled_word,
                 'observed_matches': tiles.observed_matches}
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(helper_path), 'exec'), namespace)
    tour = studio.Tour.__new__(studio.Tour)
    tour.out, tour.counter = output, 0
    tour.probe = SimpleNamespace(**{key: namespace[key] for key in names if key in namespace})
    tour.enter = lambda *args: None
    tour.jump_save = lambda: (_ for _ in ()).throw(FirstPauseReached('Reached unchanged first checkpoint read'))
    started = time.monotonic()
    status, error = 'FAIL', None
    try:
        tour.jump()
    except FirstPauseReached:
        status = 'FIRST_PAUSE_PRECONDITION_REPLAY_PASS'
    except Exception as failure:
        error = {'type': type(failure).__name__, 'message': str(failure)}
    journals = sorted(output.glob('*-surface-readiness.json'))
    journal = json.loads(journals[0].read_text()) if len(journals) == 1 else None
    if status != 'FAIL':
        assert len(snapshots) == 2 and len(commands) == 1
        assert journal['status'] == 'TOUCH_SENT' and journal['orientation_policy'] == 'responsive'
        assert journal['frames'][0]['target']['stable_observed_target'] is False
        assert journal['frames'][1]['target']['stable_observed_target'] is True
    result = {'status': status, 'error': error, 'elapsed_seconds': time.monotonic() - started,
              'source_root': str(root), 'sources': {
                  str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
                  for path in (studio_path, helper_path)},
              'original_frames': snapshots, 'recorded_offline_commands': commands,
              'journal': journal, 'tesseract_version': base.command('tesseract', '--version'),
              'languages': base.command('tesseract', '--list-langs'),
              'tessdata_prefix': os.environ.get('TESSDATA_PREFIX'),
              'omp_thread_limit': os.environ.get('OMP_THREAD_LIMIT'),
              'scope': ['Actual Tour.jump first Pause -> actual native_text/native_tap/image_lines AST',
                        'Real Tesseract on two unchanged original Android PNGs',
                        'Entry and first checkpoint are offline sentinels; adb is a recording sink',
                        'Replay omits sleeps but keeps actual 120-second deadline and both target observations',
                        'No Android replay, motion, video, save, resume or performance acceptance']}
    (output / 'replay.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    sys.exit(0 if replay(args.source_root.resolve(), args.output.resolve())['status'] != 'FAIL' else 1)
