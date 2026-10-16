#!/usr/bin/env python3
"""Tour the exact candidate APK on a disposable Android emulator.

Installs the APK, starts it, creates a fictional profile through the real
onboarding and records the screens a child actually sees: start, learning,
games, Lumo Kart (native Godot) and the Fold cover/open sizes. Controls are
found in the live accessibility tree; nothing is injected into the app.

The run fails on install, onboarding, primary navigation or a missing native
Godot launch. Every mandatory failure stays in the report; a visible Kart
preview never counts as an actual working game.
"""
from __future__ import annotations

import argparse
import json
import csv
import io
import re
import unicodedata
from pathlib import Path
import subprocess
import sys
import time
import traceback

from PIL import Image, ImageChops, ImageStat

sys.path.insert(0, str(Path(__file__).resolve().parent))
import creative_android_probe as probe  # noqa: E402  (pinned live helpers)

base = probe.base
live = probe.live
PACKAGE = probe.PACKAGE


def logcat_fatal() -> list[str]:
    text = base.adb('logcat', '-d', '-v', 'brief', timeout=60, check=False)
    lines = text.splitlines()
    fatal = []
    for i, line in enumerate(lines):
        if 'FATAL EXCEPTION' in line or 'Fatal signal' in line:
            window = '\n'.join(lines[i:i + 6])
            if PACKAGE in window or 'lumo' in window.lower():
                fatal.append(window)
    return fatal


def alive() -> bool:
    return bool(base.adb('shell', 'pidof', PACKAGE, check=False).strip())


def godot_alive() -> bool:
    # LumoGameActivity runs in :lumo_game. The Flutter host remaining
    # alive does not prove the embedded 3D engine actually launched.
    return bool(base.adb('shell', 'pidof', PACKAGE + ':lumo_game',
                         check=False).strip())


def try_tap(out: Path, labels: list[str], tag: str) -> str | None:
    for label in labels:
        try:
            probe.flutter_tap(out, label, f'{tag}-{len(label)}',
                              scroll_attempts=10 if tag == 'open-kart' else 3)
            return label
        except Exception:  # The next alternative label is tried.
            continue
    return None


def _simplify(word: str) -> str:
    plain = unicodedata.normalize('NFKD', word).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', plain.lower())


def _read_garage_footer(png: bytes, expected: str) -> tuple[int, int] | None:
    """Read the native Godot footer from actual Android screenshots, not fixed coordinates.

    Crop fallback is essential: on 2400x1080 Flutter-hosted Godot screens,
    Tesseract skips the golden 'Weiter' button when scanning the full scene.
    The same crop also recognises 'Rennen starten' on compact 640x320 screens.
    """
    image = Image.open(io.BytesIO(png)).convert('RGB')
    crop_top = int(image.height * .54)
    lower = image.crop((0, crop_top, image.width, image.height))
    variants = [
        (0, 0, 2, image.convert('L').point(lambda value: 0 if value >= 170 else 255)
         .resize((image.width * 2, image.height * 2))),
        (0, 0, 2, image.resize((image.width * 2, image.height * 2), Image.Resampling.LANCZOS)
         .convert('L').point(lambda value: 0 if value < 140 else 255)),
        (0, crop_top, 2, lower.convert('L').resize(
            (lower.width * 2, lower.height * 2), Image.Resampling.LANCZOS)),
    ]
    for offset_x, offset_y, scale, transformed in variants:
        temp = io.BytesIO()
        transformed.save(temp, format='PNG')
        process = subprocess.run(
            ['tesseract', 'stdin', 'stdout', '--psm', '11', '-l', 'deu+eng', 'tsv'],
            input=temp.getvalue(), capture_output=True, timeout=35, check=True,
        )
        rows = csv.DictReader(io.StringIO(process.stdout.decode('utf-8', 'replace')),
                              delimiter=chr(9), quoting=csv.QUOTE_NONE)
        lines: dict[tuple[str, str, str], list[dict]] = {}
        for word in rows:
            if not (word.get('text') or '').strip() or float(word.get('conf', -1)) < 15:
                continue
            key = tuple(word[k] for k in ('block_num', 'par_num', 'line_num'))
            lines.setdefault(key, []).append(word)
        for words in lines.values():
            words.sort(key=lambda word: int(word['left']))
            for start in range(len(words)):
                for end in range(start + 1, min(start + 8, len(words)) + 1):
                    span = words[start:end]
                    if _simplify(' '.join(word['text'] for word in span)) != _simplify(expected):
                        continue
                    x0 = min(int(w['left']) for w in span)
                    x1 = max(int(w['left']) + int(w['width']) for w in span)
                    y0 = min(int(w['top']) for w in span)
                    y1 = max(int(w['top']) + int(w['height']) for w in span)
                    x = (x0 + x1) // (2 * scale) + offset_x
                    y = (y0 + y1) // (2 * scale) + offset_y
                    if y >= image.height * .6:
                        return x, y
    return None


def _race_frame_difference(garage: bytes, race: bytes) -> dict:
    """Fail if the screenshot still looks like the garage despite log markers.

    Screenshots must come from the same live emulator and orientation.
    """
    a, b = Image.open(io.BytesIO(garage)).convert('RGB'), Image.open(io.BytesIO(race)).convert('RGB')
    if a.size != b.size:
        raise RuntimeError(f'Race and garage viewport differ: {a.size} / {b.size}')
    left, top, right, bottom = (a.width // 12, a.height // 8,
                                a.width * 11 // 12, a.height * 7 // 8)
    first, second = a.crop((left, top, right, bottom)), b.crop((left, top, right, bottom))
    first.thumbnail((400, 200))
    second = second.resize(first.size)
    diff = ImageChops.difference(first, second)
    thresholded = diff.convert('RGB')
    pixels = list(thresholded.getdata())
    changed = sum(1 for p in pixels if sum(p) >= 96) / max(1, len(pixels))
    mean = sum(ImageStat.Stat(diff).mean) / 3
    report = {'changed_fraction': round(changed, 3), 'mean_channel_delta': round(mean, 2)}
    if changed < .22 or mean < 18:
        raise RuntimeError(f'Android still shows the garage, not the race: {report}')
    return report


def _start_actual_embedded_race(out: Path) -> dict:
    if not godot_alive():
        raise RuntimeError('Native Godot game process is not alive')
    evidence = []
    garage_fifth = None
    for index in range(5):
        wanted = 'Weiter' if index < 4 else 'Rennen starten'
        for attempt in range(12):
            png = subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                                 check=True, capture_output=True, timeout=25).stdout
            capture = out / f'21_kart_garage_step_{index + 1}.png'
            capture.write_bytes(png)
            point = _read_garage_footer(png, wanted)
            if point is not None:
                if index == 4:
                    garage_fifth = png
                base.adb('shell', 'input', 'tap', str(point[0]), str(point[1]))
                evidence.append({'step': index + 1, 'button': wanted, 'tap': point})
                time.sleep(2)
                break
            time.sleep(1)
        else:
            raise RuntimeError(f'Missing Android kart footer at step {index + 1}: {wanted}')
    (out / '21_kart_real_touches.json').write_text(json.dumps(evidence, indent=2))
    if garage_fifth is None:
        raise RuntimeError('Last garage image was not captured')

    # Godot logs belong to a separate :lumo_game process, not Flutter.
    deadline = time.monotonic() + 55
    while time.monotonic() < deadline:
        if not godot_alive():
            raise RuntimeError('Godot quit before showing the race')
        screen = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], check=True,
                                capture_output=True, timeout=25).stdout
        (out / '21_lumo_kart_real_race.png').write_bytes(screen)
        log = base.adb('logcat', '-d', '-v', 'brief', timeout=60, check=False)
        if '[Kart] race_world_ready: sonnenhafen mode=race' in log:
            try:
                report = _race_frame_difference(garage_fifth, screen)
                (out / '21_kart_race_frame_check.json').write_text(
                    json.dumps(report, indent=2))
                return report
            except RuntimeError:
                pass
        time.sleep(2)
    raise RuntimeError('Native Android kart race did not visibly replace the garage')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result: dict = {'status': 'RUNNING', 'apk_sha256': probe.digest(args.apk),
                    'steps': [], 'not_tested': [
                        'physical Samsung Fold', 'device GPU frame times',
                        'audio output']}

    def step(name: str, ok: bool, **extra) -> None:
        entry = {'step': name, 'ok': ok, **extra}
        result['steps'].append(entry)
        (out / 'tour-result.json').write_text(json.dumps(result, indent=2))

    try:
        result['android_sdk'] = base.adb('shell', 'getprop', 'ro.build.version.sdk').strip()
        base.adb('logcat', '-c', check=False)
        base.display(1080, 2400, 420)
        install = base.adb('install', '-r', '--no-streaming', str(args.apk), timeout=300)
        (out / 'install.txt').write_text(install)
        if 'Success' not in install:
            raise RuntimeError('APK installation failed')
        identity = base.adb('shell', 'dumpsys', 'package', PACKAGE, timeout=60)
        result['version'] = [l.strip() for l in identity.splitlines()
                             if 'versionCode=' in l or 'versionName=' in l][:2]
        started = time.monotonic()
        base.launch(out, 'cold-start')
        result['cold_start_seconds_until_foreground'] = round(time.monotonic() - started, 1)
        probe.capture(out, '01_erster_start')
        step('launch', True)

        onboarding = probe.onboard(out)  # Captures 07_home and 08_games.
        step('onboarding', onboarding.get('status') == 'PASS')

        for name, labels in (
            ('start', ['Start', 'Home']),
            ('lernen', ['Lernen']),
        ):
            tapped = try_tap(out, labels, f'nav-{name}')
            time.sleep(2)
            probe.capture(out, f'10_{name}')
            step(f'navigate-{name}', tapped is not None, label=tapped)

        tapped = try_tap(out, ['Spielen', 'Spiele'], 'nav-spiele')
        time.sleep(2)
        probe.capture(out, '20_spiele')
        step('navigate-spiele', tapped is not None, label=tapped)
        kart = try_tap(out, ['Losfahren', 'Rennen starten'], 'open-kart')
        if kart is not None:
            # The embedded Godot engine needs time on the software renderer.
            for wait in (12, 20):
                time.sleep(wait)
                probe.capture(out, f'21_lumo_kart_{wait}s')
            step('open-kart', godot_alive(), label=kart)
            report = _start_actual_embedded_race(out)
            step('start-kart-race', True, **report)
            # Back while driving opens pause; Back while paused hands the
            # session back to Flutter. Both are the actual native UI flow.
            base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK', check=False)
            time.sleep(2)
            probe.capture(out, '21_lumo_kart_pause')
            base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK', check=False)
            time.sleep(6)
            probe.capture(out, '22_nach_kart_zurueck')
            # Android is allowed to keep the Godot process cached after Activity
            # finishes; requiring pidof == empty would be a false failure.
            # The actual Flutter screen has returned to portrait.
            returned = Image.open(out / '22_nach_kart_zurueck.png')
            step('return-from-kart', alive() and returned.height > returned.width)
        else:
            step('open-kart', False, label=None)

        for name, (w, h, d) in (
            ('fold_offen', (1812, 2176, 420)),
            ('fold_aussen', (904, 2316, 420)),
            ('quer', (2400, 1080, 420)),
        ):
            base.display(w, h, d)
            time.sleep(4)
            probe.capture(out, f'30_{name}')
            step(f'display-{name}', alive(), size=f'{w}x{h}@{d}')
        base.display(1080, 2400, 420)

        fatal = logcat_fatal()
        (out / 'fatal-logcat.txt').write_text('\n\n'.join(fatal))
        result['fatal_crashes'] = len(fatal)
        hard = [s['step'] for s in result['steps']
                if not s['ok'] and s['step'] in (
                    'launch', 'onboarding', 'navigate-start',
                    'navigate-lernen', 'navigate-spiele', 'open-kart',
                    'start-kart-race', 'return-from-kart')]
        if fatal or hard or not alive():
            raise RuntimeError(f'Hard failure: crashes={len(fatal)} steps={hard} '
                               f'alive={alive()}')
        result['status'] = 'PASS'
    except Exception as error:  # Keep every observation for the report.
        result.update(status='FAIL', error=f'{type(error).__name__}: {error}',
                      traceback=traceback.format_exc())
        try:
            probe.capture(out, '99_fehler')
        except Exception:
            pass
    finally:
        try:
            log = subprocess.run(['adb', 'logcat', '-d'], capture_output=True,
                                 text=True, timeout=60).stdout
            (out / 'logcat.txt').write_text(log[-2_000_000:])
        except Exception:
            pass
        (out / 'tour-result.json').write_text(json.dumps(result, indent=2))
        print(json.dumps({k: result[k] for k in ('status', 'steps') if k in result},
                         indent=2))
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
