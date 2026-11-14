#!/usr/bin/env python3
"""Replay actual screenshot bytes through a named unchanged/patched OCR reader.

This is an offline diagnostic, not an Android input or gameplay acceptance.
"""
import argparse
import ast
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
import traceback
import types
import unicodedata

from PIL import Image, ImageChops


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--probe', type=Path, required=True)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--host', type=Path, required=True)
    parser.add_argument('--label', default='Ein Objekt zeigen')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    sys.path[:0] = [str(args.host / '.github/probes'),
                   str(args.host / 'scripts/probes'),
                   str(args.host / 'tools/android_qa')]
    # Execute the exact production reader AST with its real subprocess helper.
    # The unrelated Android UI import requires uiautomator2; this offline
    # replay neither installs that service nor stubs a screenshot or OCR result.
    from native_ocr_tiles import observed_matches, read_tiled_word
    import pr207_android_smoke as base
    os.environ.setdefault('OMP_THREAD_LIMIT', '1')
    parsed = ast.parse(args.probe.read_text())
    body = [node for node in parsed.body if isinstance(node, ast.FunctionDef)
            and node.name in {'digest', 'normalized', 'image_lines', 'gold_caption_boxes', 'read_component_caption'}]
    assert len(body) in (3, 5)
    namespace = dict(Path=Path, Image=Image, ImageChops=ImageChops, time=time,
                     deque=deque, math=math, observed_matches=observed_matches,
                     csv=csv, json=json, re=re, unicodedata=unicodedata,
                     hashlib=hashlib, read_tiled_word=read_tiled_word, base=base)
    exec(compile(ast.Module(body=body, type_ignores=[]), str(args.probe), 'exec'), namespace)
    probe = types.SimpleNamespace(**namespace)
    before = hashlib.sha256(args.source.read_bytes()).hexdigest()
    report = {
        'scope': 'Offline original-frame OCR replay; no app input or gameplay PASS',
        'reader_execution': 'Exact image_lines/normalized/digest AST; real base.command and Tesseract; no Android connection',
        'source': str(args.source), 'source_sha256_before': before,
        'probe': str(args.probe),
        'probe_sha256': hashlib.sha256(args.probe.read_bytes()).hexdigest(),
        'label': args.label, 'exact': True, 'timeout_seconds': 120,
        'tesseract_version': subprocess.check_output(
            ['tesseract', '--version'], text=True).splitlines()[0],
        'language_listing': subprocess.check_output(['tesseract', '--list-langs'], text=True),
        'tessdata_prefix': os.environ.get('TESSDATA_PREFIX', ''),
        'status': 'FAIL',
    }
    start = time.monotonic()
    try:
        lines = probe.image_lines(args.output, 'original-frame',
                                  probe.normalized(args.label),
                                  source_path=args.source, timeout=120, exact=True)
        matches = [line for line in lines
                   if probe.normalized(line['text']) == probe.normalized(args.label)]
        report.update(matches=matches, recognized_line_count=len(lines),
                      variants=sorted({line['variant'] for line in lines}))
        if not matches:
            raise AssertionError('Actual unchanged screenshot did not yield the exact requested caption')
        report['status'] = 'PASS'
    except Exception as error:
        report.update(error=f'{type(error).__name__}: {error}', traceback=traceback.format_exc())
    finally:
        report['elapsed_seconds'] = round(time.monotonic() - start, 6)
        report['source_sha256_after'] = hashlib.sha256(args.source.read_bytes()).hexdigest()
        if report['source_sha256_after'] != before:
            report.update(status='FAIL', error='Original source bytes changed')
        (args.output / 'replay.json').write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(report, indent=2), flush=True)
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
