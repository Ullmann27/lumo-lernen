#!/usr/bin/env python3
"""Observe one digest-pinned APK on a disposable Android emulator.

This checks installation, offline startup, size changes, process continuity and
restart. It is NOT a complete game, progress, physical Fold or FPS acceptance.
Only fresh emulator data is touched. No production code or device is modified.
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
CODE_SHA = '4a50e01410d5dee3816e1c4fa283dfdf3629b079'
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


def capture(out: Path, name: str) -> dict[str, Any]:
    data = subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=45, check=True).stdout
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
    """Launcher UI is accessible independently of Flutter semantics."""
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
    # Missing icon evidence is reported as missing, never upgraded to PASS.
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
        'scope': 'Fresh Android emulator; boot/size/restart smoke only',
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
        crashes = adb('logcat', '-d', '-b', 'crash', check=False)
        (args.out / 'crash-buffer.txt').write_text(crashes)
        if PACKAGE in crashes:
            raise RuntimeError('Probe package appears in Android crash buffer')
        result['resize_process_continuity'] = all(
            item.get('same_process', True) for item in result['captures'])
        if not result['resize_process_continuity']:
            raise RuntimeError('App process changed during display resizing')
        result['status'] = 'PASS'
        print('[PR207AndroidSmoke] PASS: install, boot, display changes, restart; visual review still required')
        return 0
    except Exception as error:
        result['status'] = 'FAIL'
        result['error'] = str(error)
        result['traceback'] = traceback.format_exc()
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
