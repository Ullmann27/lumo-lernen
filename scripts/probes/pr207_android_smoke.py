#!/usr/bin/env python3
"""Check one digest-pinned APK on a disposable Android emulator.

Checks install, offline startup, resizing, actual profile creation and games
navigation, then profile recovery after restart. No full race/card match,
physical Fold, hinge, frame-rate or visual-parity acceptance is implied.
Only disposable emulator data is touched. No source or real device is modified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import subprocess
import time
import traceback
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CODE_SHA = '35a7a0a56a9519fb6c33e35b5aad78cd6f589d08'
MATRIX = (
    ('01_phone', 1080, 2400, 480),
    ('02_fold_outer', 1080, 2520, 480),
    ('03_fold_inner', 2520, 2220, 480),
    ('04_fold_outer_return', 1080, 2520, 480),
    ('05_tablet', 1920, 1200, 240),
)


def command(*args: str, timeout: int = 60, check: bool = True) -> str:
    result = subprocess.run(args, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=timeout)
    text = result.stdout.decode('utf-8', errors='replace')
    if check and result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {args}\n{text}')
    return text.strip()


def adb(*args: str, timeout: int = 60, check: bool = True) -> str:
    return command('adb', *args, timeout=timeout, check=check)


def png_size(data: bytes) -> tuple[int, int]:
    if len(data) < 24 or not data.startswith(b'\x89PNG\r\n\x1a\n'):
        raise RuntimeError('screencap did not return a PNG')
    return struct.unpack('>II', data[16:24])


PNG_END = b'\x00\x00\x00\x00IEND\xaeB`\x82'


def png_complete(data: bytes) -> bool:
    """A screencap transfer cut off by a busy emulator lacks the IEND chunk."""
    return data.startswith(b'\x89PNG\r\n\x1a\n') and data.endswith(PNG_END)


def capture(out: Path, name: str) -> dict[str, Any]:
    # Retry only an incomplete transfer; every saved file is a complete,
    # unmodified device screenshot. (Recorded failure: "image file is truncated".)
    for attempt in range(4):
        data = subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=45, check=True).stdout
        if png_complete(data):
            break
        time.sleep(1)
    else:
        raise RuntimeError('screencap stayed incomplete after 4 transfers')
    width, height = png_size(data)
    path = out / (name + '.png')
    path.write_bytes(data)
    return dict(file=path.name, width=width, height=height,
                sha256=hashlib.sha256(data).hexdigest())


def display(width: int, height: int, density: int) -> None:
    adb('shell', 'wm', 'size', f'{width}x{height}')
    adb('shell', 'wm', 'density', str(density))
    time.sleep(3)


def foreground() -> str:
    activities = adb('shell', 'dumpsys', 'activity', 'activities')
    lines = [line for line in activities.splitlines()
             if 'mResumedActivity' in line or 'topResumedActivity' in line]
    if not any(PACKAGE in line for line in lines):
        raise RuntimeError('Probe app not foreground:\n' + '\n'.join(lines))
    return '\n'.join(lines)


def pid() -> str:
    value = adb('shell', 'pidof', PACKAGE, check=False).strip()
    if not re.fullmatch(r'\d+(?:\s+\d+)*', value):
        raise RuntimeError('App process missing: ' + value)
    return value


def inspect_installed_icon(out: Path) -> dict[str, Any]:
    adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    time.sleep(2)
    adb('shell', 'input', 'swipe', '540', '2150', '540', '350', '400')
    time.sleep(3)
    image = capture(out, '00_installed_launcher')
    detail: dict[str, Any] = {'capture': image, 'icon_found': False}
    try:
        adb('shell', 'uiautomator', 'dump', '/sdcard/lumo-ui.xml', timeout=30)
        xml = adb('exec-out', 'cat', '/sdcard/lumo-ui.xml')
        (out / 'installed-launcher.xml').write_text(xml)
        for node in ET.fromstring(xml).iter('node'):
            label = ' '.join((node.get('text', ''), node.get('content-desc', '')))
            if 'Lumo Lernen Neu' in label:
                detail.update(icon_found=True, label=label.strip(),
                              bounds=node.get('bounds'))
                break
    except (RuntimeError, subprocess.TimeoutExpired, ET.ParseError) as error:
        detail['inspection_error'] = str(error)
    return detail


def launch(out: Path, name: str) -> str:
    result = adb('shell', 'monkey', '-p', PACKAGE, '-c',
                 'android.intent.category.LAUNCHER', '1', timeout=90)
    (out / (name + '-launch.txt')).write_text(result)
    for _ in range(12):
        time.sleep(1)
        try:
            current = pid()
            foreground()
            time.sleep(5)
            return current
        except RuntimeError:
            pass
    raise RuntimeError('App did not become foreground within startup deadline')


def ui_nodes(out: Path, name: str) -> list:
    adb('shell', 'uiautomator', 'dump', '/sdcard/lumo-app-ui.xml', timeout=30)
    xml = adb('exec-out', 'cat', '/sdcard/lumo-app-ui.xml')
    (out / (name + '.xml')).write_text(xml)
    return list(ET.fromstring(xml).iter('node'))


def accessible_text(nodes: list) -> str:
    return ' '.join(n.get('text', '') + ' ' + n.get('content-desc', '') for n in nodes)


def tap_label(out: Path, label: str, tag: str) -> None:
    for attempt in range(5):
        nodes = ui_nodes(out, tag + '-' + str(attempt))
        candidates = []
        for node in nodes:
            texts = (node.get('text', ''), node.get('content-desc', ''))
            if not any(label == text or label in text.split('\n') for text in texts):
                continue
            if node.get('enabled') == 'false':
                continue
            match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
            if match:
                x0, y0, x1, y1 = map(int, match.groups())
                if x1 > x0 and y1 > y0:
                    candidates.append((node.get('clickable') != 'true',
                                       (x1-x0)*(y1-y0), x0,y0,x1,y1))
        if candidates:
            _, _, x0,y0,x1,y1 = min(candidates)
            adb('shell', 'input', 'tap', str((x0+x1)//2), str((y0+y1)//2))
            time.sleep(2)
            return
        # Only scroll the app's known narrow onboarding content area. Never
        # invent a coordinate for a missing named button or bypass a gate.
        adb('shell', 'input', 'swipe', '540', '1960', '540', '1200', '350')
        time.sleep(1)
    capture(out, tag + '-missing-control')
    raise RuntimeError('Accessible control not found after bounded scroll: ' + label)


def onboard(out: Path) -> dict[str, Any]:
    tap_label(out, "Los geht's!", 'onboard-welcome')
    nodes = ui_nodes(out, 'onboard-name')
    field = next((n for n in nodes if n.get('class') == 'android.widget.EditText'), None)
    if field is None:
        raise RuntimeError('No accessible name field; do not invent coordinate entry')
    coordinates = list(map(int, re.findall(r'\d+', field.get('bounds', ''))))
    if len(coordinates) != 4:
        raise RuntimeError('Name field bounds unavailable')
    x0,y0,x1,y1 = coordinates
    adb('shell', 'input', 'tap', str((x0+x1)//2), str((y0+y1)//2))
    adb('shell', 'input', 'text', 'LumoTest')
    adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    tap_label(out, 'Weiter', 'onboard-name-next')
    tap_label(out, 'Weiter', 'onboard-age-next')
    tap_label(out, 'Profil speichern', 'onboard-grade-save')
    time.sleep(4)
    home = capture(out, '07_home_after_onboarding')
    if 'LumoTest' not in accessible_text(ui_nodes(out, 'home-after-onboarding')):
        raise RuntimeError('Saved profile name not visible on the resulting home screen')
    tap_label(out, 'Spiele', 'home-to-games')
    games = capture(out, '08_games_after_navigation')
    text = accessible_text(ui_nodes(out, 'games-after-navigation'))
    if not any(value in text for value in ('Lumo Cards', 'Lumo Kart', 'Spielewelt')):
        raise RuntimeError('Games entry could not be verified after navigation')
    return {'status': 'PASS', 'profile_name': 'LumoTest', 'captures': [home, games],
            'scope': 'Actual UI onboarding and games entry; no complete card match or race'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--out', type=Path, default=Path('runtime-evidence'))
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    result: dict[str, Any] = {
        'status': 'RUNNING', 'apk_source_sha': CODE_SHA,
        'apk_sha256': hashlib.sha256(args.apk.read_bytes()).hexdigest(),
        'package': PACKAGE, 'captures': [],
        'scope': 'Fresh Android emulator: install, offline boot, resize, onboarding, games entry, profile restart',
        'not_tested': ['physical Fold', 'hinge posture', 'FPS', 'complete races',
                       'Cards saved-match recovery', 'visual reference parity'],
    }
    try:
        if result['apk_sha256'] != args.sha256:
            raise RuntimeError('APK hash differs from verified artifact')
        result['harness_sha'] = command('git', 'rev-parse', 'HEAD')
        result['android_version'] = adb('shell', 'getprop', 'ro.build.version.release')
        result['abi'] = adb('shell', 'getprop', 'ro.product.cpu.abi')
        install = adb('install', '-r', '--no-streaming', str(args.apk), timeout=180)
        (args.out / 'install.txt').write_text(install)
        if 'Success' not in install:
            raise RuntimeError('APK installation was not confirmed')
        package_info = adb('shell', 'dumpsys', 'package', PACKAGE)
        (args.out / 'installed-package.txt').write_text(package_info)
        if 'versionCode=280' not in package_info or 'versionName=0.10.5' not in package_info:
            raise RuntimeError('Installed package has unexpected version')
        adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
        adb('shell', 'wm', 'dismiss-keyguard', check=False)
        display(1080, 2400, 480)
        result['launcher'] = inspect_installed_icon(args.out)
        if not result['launcher']['icon_found']:
            raise RuntimeError('Installed launcher entry was not found')
        adb('logcat', '-c')
        adb('shell', 'svc', 'wifi', 'disable')
        adb('shell', 'svc', 'data', 'disable')
        adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable', check=False)
        result['airplane_mode'] = adb('shell', 'settings', 'get', 'global', 'airplane_mode_on')
        result['network_state'] = adb('shell', 'dumpsys', 'connectivity')
        if result['airplane_mode'] != '1':
            raise RuntimeError('Offline mode not confirmed; cannot claim offline startup')
        initial_pid = launch(args.out, 'first')
        for name, width, height, density in MATRIX:
            display(width, height, density)
            current_pid = pid()
            view = capture(args.out, name)
            if (view['width'], view['height']) != (width, height):
                raise RuntimeError(f'Capture resolution mismatch: {view}')
            view.update(requested_density=density, logical_width=width*160/density,
                        logical_height=height*160/density, process_id=current_pid,
                        same_process=current_pid == initial_pid,
                        foreground=foreground())
            result['captures'].append(view)
        adb('shell', 'am', 'force-stop', PACKAGE)
        display(1080, 2400, 480)
        restart_pid = launch(args.out, 'restart')
        image = capture(args.out, '06_offline_restart')
        image.update(process_id=restart_pid, foreground=foreground())
        result['captures'].append(image)
        result['onboarding'] = onboard(args.out)
        games_pid = pid()
        for name, width, height, density in MATRIX[1:]:
            display(width, height, density)
            view = capture(args.out, 'games_' + name)
            current_pid = pid()
            view.update(process_id=current_pid, same_process=current_pid == games_pid,
                        foreground=foreground())
            result['captures'].append(view)
        adb('shell', 'am', 'force-stop', PACKAGE)
        display(1080, 2400, 480)
        launch(args.out, 'profile-restart')
        profile = capture(args.out, '09_saved_profile_after_restart')
        if 'LumoTest' not in accessible_text(ui_nodes(args.out, 'saved-profile-after-restart')):
            raise RuntimeError('Saved profile did not reappear after offline restart')
        result['onboarding']['profile_restart'] = profile
        crashes = adb('logcat', '-d', '-b', 'crash', check=False)
        (args.out / 'crash-buffer.txt').write_text(crashes)
        if PACKAGE in crashes:
            raise RuntimeError('Probe package appears in Android crash buffer')
        result['resize_process_continuity'] = all(
            item.get('same_process', True) for item in result['captures'])
        if not result['resize_process_continuity']:
            raise RuntimeError('App process changed during display resizing')
        result['status'] = 'PASS'
        print('[PR207AndroidSmoke] PASS: install, offline boot, resize, UI onboarding, games entry, profile restart; visual review still required')
        return 0
    except Exception as error:
        result['status'] = 'FAIL'
        result['error'] = str(error)
        result['traceback'] = traceback.format_exc()
        try:
            result['failure_capture'] = capture(args.out, 'failure_screen')
        except Exception as capture_error:
            result['capture_error'] = str(capture_error)
        print('[PR207AndroidSmoke] FAIL:', error)
        return 1
    finally:
        try:
            (args.out / 'logcat.txt').write_text(adb('logcat', '-d', check=False))
        except Exception as error:
            result['log_collection_error'] = str(error)
        (args.out / 'runtime-report.json').write_text(json.dumps(result, indent=2) + '\n')


if __name__ == '__main__':
    raise SystemExit(main())
