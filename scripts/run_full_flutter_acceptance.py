#!/usr/bin/env python3
"""Run the full Flutter suite including optional visual proofs; reject skips."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import signal
import shutil
import subprocess
import sys
import threading
import time

CAPTURE_DIRECTORIES = {
    'LUMO_TUTORING_CAPTURE_DIR': 'tutoring',
    'LUMO_RIG_STRESS': 'rig-stress',
    'LUMO_CARDS_OPPONENT_CAPTURE': 'cards-opponents',
    'LUMO_STREAM_E_CAPTURE': 'cards-memory',
    'LUMO_NAVIGATION_CAPTURES': 'navigation',
    'LUMO_GUIDED_CAPTURE_DIR': 'guided-learning',
    'LUMO_VISUAL_CAPTURE_DIR': 'reasoning',
    'LUMO_TOUR_DIR': 'tour',
    'LUMO_FLUTTER_GAMES_CAPTURE': 'games',
    'LUMO_LEARNING_CAPTURE_DIR': 'learning-adventure',
    'LUMO_COMPANION_CAPTURE_DIR': 'companion',
    'LUMO_SPATIAL_CAPTURES': 'reading',
    'LUMO_CAPTURE_DIR': 'modernization',
    'LUMO_CARD_FACE_EXPORT_DIR': 'card-face-exports',
    'LUMO_NEXTGEN_READING_CAPTURES': 'nextgen-reading',
    'LUMO_READING_CAPTURES': 'reading-passages',
    'LUMO_ASSISTED_LEARNING_CAPTURES': 'assisted-learning',
}
CAPTURE_FILES = {'LUMO_CARDS_CUP_CAPTURE': 'cards-cup/trophy.png'}


def summarize(events: list[dict], exit_code: int, errors: list[str]) -> dict:
    names = {}
    finished = {}
    done = False
    for event in events:
        if event.get('type') == 'testStart':
            test = event['test']
            names[test['id']] = test['name']
        elif event.get('type') == 'testDone':
            finished[event['testID']] = event
        elif event.get('type') == 'done':
            done = event.get('success') is True
    failed = [names.get(i, str(i)) for i, item in finished.items()
              if item.get('result') != 'success']
    skipped = [names.get(i, str(i)) for i, item in finished.items()
               if item.get('skipped') is True]
    passed = sum(item.get('result') == 'success' and not item.get('skipped')
                 and not item.get('hidden') for item in finished.values())
    return {
        'status': 'PASS' if exit_code == 0 and done and passed > 0
                  and not failed and not skipped and not errors else 'FAIL',
        'passed': passed,
        'failed': failed,
        'skipped': skipped,
        'capture_error_files': errors,
        'flutter_exit_code': exit_code,
        'runner_completed_successfully': done,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--flutter', default=shutil.which('flutter'))
    parser.add_argument('tests', nargs='*', help='Optional focused files; default: every test')
    args = parser.parse_args()
    if not args.flutter:
        parser.error('Flutter executable is unavailable')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ, CI='true', BOT='true', FLUTTER_SUPPRESS_ANALYTICS='true',
               LUMO_EXPORT_CARD_FACES='1', LUMO_TOUR_CAPTURE_SCALE='1')
    for key, directory in CAPTURE_DIRECTORIES.items():
        location = output / directory
        location.mkdir()
        env[key] = str(location)
    for key, relative in CAPTURE_FILES.items():
        location = output / relative
        location.parent.mkdir(parents=True, exist_ok=True)
        env[key] = str(location)
    command = [args.flutter, 'test', '--no-pub', '--machine', '--concurrency=2',
               '--timeout=60s', *args.tests]
    events = []
    completed = 0
    watchdog_errors = []
    with (output / 'flutter-machine.jsonl').open('w') as log:
        process = subprocess.Popen(command, env=env, text=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, bufsize=1,
                                   start_new_session=True)
        started = time.monotonic()
        last_output = [started]
        stopped = threading.Event()

        def monitor() -> None:
            while not stopped.wait(5):
                now = time.monotonic()
                if now - last_output[0] < 180 and now - started < 2400:
                    continue
                watchdog_errors.append('Runner stalled for 180 seconds or exceeded 40 minutes')
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                    if not stopped.wait(5):
                        os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                return

        watchdog = threading.Thread(target=monitor, daemon=True)
        watchdog.start()
        assert process.stdout is not None
        for line in process.stdout:
            last_output[0] = time.monotonic()
            log.write(line)
            log.flush()
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(event, dict):
                continue
            events.append(event)
            if event.get('type') == 'testDone' and not event.get('hidden'):
                completed += 1
                if completed % 100 == 0:
                    print(f'Flutter acceptance: {completed} tests completed', flush=True)
        exit_code = process.wait()
        stopped.set()
        watchdog.join(timeout=1)
    errors = sorted(str(path.relative_to(output)) for path in output.rglob('*.error.txt'))
    report = summarize(events, exit_code, errors)
    report['runner_errors'] = watchdog_errors
    if watchdog_errors:
        report['status'] = 'FAIL'
    report['scope'] = args.tests or ['complete Flutter suite; capture outputs recorded below']
    report['capture_png_counts'] = {
        key: {'directory': directory, 'pngs': sum(1 for _ in (output / directory).rglob('*.png'))}
        for key, directory in CAPTURE_DIRECTORIES.items()
    }
    report['capture_file_outputs'] = {
        key: {'path': relative, 'created': (output / relative).is_file()}
        for key, relative in CAPTURE_FILES.items()
    }
    report['rendered_png_count'] = sum(1 for _ in output.rglob('*.png'))
    (output / 'acceptance-summary.json').write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + '\n')
    print(json.dumps(report, ensure_ascii=False), flush=True)
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
