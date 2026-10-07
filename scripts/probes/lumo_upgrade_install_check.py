#!/usr/bin/env python3
"""Reproduce 1321->280 rejection; verify a data-preserving 1321->1335 update.

Disposable emulator only. No uninstall, clear-data or downgrade override is used.
This is an actual package-manager/UI test, not a mock installer or Samsung test.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import traceback

import pr207_android_smoke as p
import pr207_android_ui_probe as ui

BASELINE_SHA256 = 'c946a008509fc1c1cd322552ed353d39d945192f85fb32ad4429b2a237e63f40'
REJECTED_SHA256 = 'dbd445466a49ed4e23a899f4a166c19d7f11cc4200a3835efc53f1937befd970'


def digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def package_info(out: Path, tag: str) -> dict:
    text = p.adb('shell', 'dumpsys', 'package', p.PACKAGE)
    (out / (tag + '-package.txt')).write_text(text)
    def match(pattern):
        value = re.search(pattern, text)
        if not value:
            raise RuntimeError('Missing package field: ' + pattern)
        return value[1]
    return {'uid': int(match(r'\b(?:userId|appId)=(\d+)')),
            'versionCode': int(match(r'\bversionCode=(\d+)')),
            'versionName': match(r'\bversionName=([^\s]+)'),
            'dataDir': match(r'\bdataDir=([^\s]+)')}


def install(path: Path, out: Path, name: str, expected_failure: str | None = None) -> dict:
    args = ['adb', 'install', '-r', '--no-streaming', str(path)]
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            timeout=240, text=True)
    (out / (name + '.txt')).write_text(result.stdout)
    if expected_failure is None:
        if result.returncode or 'Success' not in result.stdout:
            raise RuntimeError('Package update rejected: ' + result.stdout)
    elif result.returncode == 0 or expected_failure not in result.stdout:
        raise RuntimeError('Expected rejection not reproduced: ' + result.stdout)
    return {'command': args, 'exitCode': result.returncode, 'output': result.stdout,
            'expectedFailure': expected_failure}


def profile_visible(out: Path, tag: str) -> dict:
    nodes = ui.live_nodes(out, tag)
    if 'LumoTest' not in p.accessible_text(nodes):
        raise RuntimeError('Original UI-created profile was not restored: ' + tag)
    p.foreground()
    return p.capture(out, tag)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--rejected', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--proof', type=Path, required=True)
    parser.add_argument('--out', type=Path, default=Path('upgrade-evidence'))
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    report = {'status': 'RUNNING', 'scope': 'Real Android emulator update with UI-created profile',
              'physicalSamsungTest': 'NOT EXECUTED', 'userDeviceFailureCode': 'UNKNOWN',
              'fullLearningAndMatchRecovery': 'NOT EXECUTED', 'steps': []}
    p.ui_nodes = ui.live_nodes
    p.tap_label = ui.live_tap_label
    try:
        if p.adb('shell', 'getprop', 'ro.kernel.qemu') != '1':
            raise RuntimeError('Refuse install probe on anything except a disposable emulator')
        if p.adb('shell', 'pm', 'path', p.PACKAGE, check=False).strip():
            raise RuntimeError('Emulator is not fresh; will not delete pre-existing app data')
        proof = json.loads(args.proof.read_text())
        if digest(args.baseline) != BASELINE_SHA256 or digest(args.rejected) != REJECTED_SHA256:
            raise RuntimeError('Wrong historical artifact bytes')
        if digest(args.candidate) != proof['sha256'] or proof['versionCode'] != 1335:
            raise RuntimeError('Wrong repaired candidate')
        if proof['tracked_source_clean'] is not True or proof['package'] != p.PACKAGE:
            raise RuntimeError('Candidate source or package check failed')
        report.update(candidateSourceSha=proof['flutter_source_commit'],
                      candidateSha256=proof['sha256'],
                      baselineSha256=BASELINE_SHA256, rejectedSha256=REJECTED_SHA256,
                      harnessSha=p.command('git', 'rev-parse', 'HEAD'),
                      android=p.adb('shell', 'getprop', 'ro.build.version.release'),
                      abi=p.adb('shell', 'getprop', 'ro.product.cpu.abi'))
        p.adb('logcat', '-c')
        report['steps'].append(install(args.baseline, out, '01_install_baseline_1321'))
        before = package_info(out, 'baseline')
        if before['versionCode'] != 1321:
            raise RuntimeError('Installed baseline version is not 1321')
        report['installedBefore'] = before
        p.adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
        p.adb('shell', 'wm', 'dismiss-keyguard', check=False)
        p.display(1080, 2400, 480)
        p.adb('shell', 'svc', 'wifi', 'disable')
        p.adb('shell', 'svc', 'data', 'disable')
        p.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        if p.adb('shell', 'settings', 'get', 'global', 'airplane_mode_on') != '1':
            raise RuntimeError('Offline mode was not confirmed')
        p.launch(out, 'baseline')
        report['createdProfileThroughUI'] = p.onboard(out)
        report['steps'].append(install(args.rejected, out, '02_reject_280',
                                        'INSTALL_FAILED_VERSION_DOWNGRADE'))
        if package_info(out, 'after_rejection') != before:
            raise RuntimeError('Failed downgrade altered installed package metadata')
        p.adb('shell', 'am', 'force-stop', p.PACKAGE)
        report['steps'].append(install(args.candidate, out, '03_update_1335'))
        after = package_info(out, 'candidate')
        if after['versionCode'] != 1335 or after['uid'] != before['uid'] or after['dataDir'] != before['dataDir']:
            raise RuntimeError('Package identity or data directory changed across update')
        report['installedAfter'] = after
        p.launch(out, 'updated')
        report['profileAfterUpdate'] = profile_visible(out, '10_profile_after_update')
        p.tap_label(out, 'Spiele', 'home-to-games')
        nodes = ui.live_nodes(out, 'updated-games')
        if not any(s in p.accessible_text(nodes) for s in ('Lumo Cards', 'Lumo Kart', 'Spielewelt')):
            raise RuntimeError('Updated games screen did not open')
        report['gamesAfterUpdate'] = p.capture(out, '11_games_after_update')
        p.adb('shell', 'am', 'force-stop', p.PACKAGE)
        p.launch(out, 'updated_restart')
        report['profileAfterRestart'] = profile_visible(out, '12_profile_after_restart')
        report['launcher'] = p.inspect_installed_icon(out)
        if not report['launcher']['icon_found']:
            raise RuntimeError('Updated launcher entry was not found')
        crash = p.adb('logcat', '-d', '-b', 'crash', check=False)
        (out / 'crash-buffer.txt').write_text(crash)
        if p.PACKAGE in crash:
            raise RuntimeError('Crash buffer contains the tested package')
        report['status'] = 'PASS'
        print('[LumoInstallUpgrade] PASS: downgrade reproduced; 1335 updates 1321 without clearing data; original profile restored twice')
        return 0
    except Exception as error:
        report.update(status='FAIL', error=str(error), traceback=traceback.format_exc())
        try:
            report['failureScreenshot'] = p.capture(out, 'failure_screen')
        except Exception as capture_error:
            report['captureError'] = str(capture_error)
        print('[LumoInstallUpgrade] FAIL: ' + str(error))
        return 1
    finally:
        try:
            (out / 'logcat.txt').write_text(p.adb('logcat', '-d', check=False))
        except Exception as error:
            report['logError'] = str(error)
        (out / 'INSTALL-UPGRADE-REPORT.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    sys.exit(main())
