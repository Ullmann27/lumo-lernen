#!/usr/bin/env python3
"""Tour the exact candidate APK on a disposable Android emulator.

Installs the APK, starts it, creates a fictional profile through the real
onboarding and records the screens a child actually sees: start, learning,
games, Lumo Kart (native Godot) and the Fold cover/open sizes. Controls are
found in the live accessibility tree; nothing is injected into the app.

The run fails only on hard defects: install/launch failure, broken
onboarding, a fatal crash or a dead app process. Optional navigation steps
are recorded as observations with their screenshots either way.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import time
import traceback

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


def try_tap(out: Path, labels: list[str], tag: str) -> str | None:
    for label in labels:
        try:
            probe.flutter_tap(out, label, f'{tag}-{len(label)}', scroll_attempts=3)
            return label
        except Exception:  # The next alternative label is tried.
            continue
    return None


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
        kart = try_tap(out, ['Lumo Kart'], 'open-kart')
        if kart is not None:
            # The embedded Godot engine needs time on the software renderer.
            for wait in (12, 20):
                time.sleep(wait)
                probe.capture(out, f'21_lumo_kart_{wait}s')
            step('open-kart', alive(), label=kart)
            base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK', check=False)
            time.sleep(6)
            probe.capture(out, '22_nach_kart_zurueck')
            step('return-from-kart', alive())
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
                if not s['ok'] and s['step'] in ('launch', 'onboarding')]
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
