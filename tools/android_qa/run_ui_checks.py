#!/usr/bin/env python3
"""Install the exact supplied APK and drive the real Flutter/Godot screens."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback

from android_ui import Android, ADB
from kart_android_race import marker, read_frame, race_state
from flutter_flows import FlutterChecks


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main(args):
    args.out.mkdir(parents=True, exist_ok=True)
    if digest(args.apk) != args.sha256.lower():
        raise ValueError('APK bytes differ from the requested SHA-256 before installation')
    sdk = Path(os.environ['ANDROID_HOME'])/'build-tools/35.0.0'
    badging = subprocess.check_output([str(sdk/'aapt'), 'dump', 'badging', str(args.apk)], text=True)
    (args.out/'apk-badging.txt').write_text(badging)
    package_match = re.search(r"package: name='([^']+)'", badging)
    if not package_match:
        raise ValueError('Could not identify the actual package from this APK')
    package = package_match.group(1)
    device = Android(args.serial, fast_input=False)
    environment = {
        'api': device.adb('shell', 'getprop', 'ro.build.version.sdk').strip(),
        'abi': device.adb('shell', 'getprop', 'ro.product.cpu.abi').strip(),
        'model': device.adb('shell', 'getprop', 'ro.product.model').strip(),
        'package': package, 'sha256': args.sha256.lower(), 'bytes': args.apk.stat().st_size,
        'physical_device_tested': False,
    }
    if environment['api'] != '35' or environment['abi'] != 'x86_64':
        raise RuntimeError(f'Expected API35 x86_64 emulator; received {environment}')
    (args.out/'environment.json').write_text(json.dumps(environment, indent=2)+'\n')
    installed = device.install(args.apk)
    (args.out/'installation.json').write_text(json.dumps(installed, indent=2)+'\n')
    if installed['sha256'] != args.sha256.lower():
        raise RuntimeError('Installed input hash differs from the downloaded/verified APK')
    device.resize('720x1280', '320')
    device.adb('logcat', '-c')
    device.foreground(package)

    def labels(root):
        return [node.attrib.get('text') or node.attrib.get('content-desc')
                for node in root.iter('node') if node.attrib.get('text') or node.attrib.get('content-desc')]

    def find(root, phrase, contains=False):
        parents = {child: parent for parent in root.iter() for child in parent}
        candidates = {}
        for node in root.iter('node'):
            values = [node.attrib.get('text', ''), node.attrib.get('content-desc', '')]
            matches = any(phrase.casefold() in value.casefold() if contains else phrase == value
                          for value in values if value)
            if not matches or node.attrib.get('enabled', 'true') != 'true':
                continue
            target = node
            while target in parents and target.attrib.get('clickable') != 'true':
                target = parents[target]
            if target.attrib.get('clickable') != 'true':
                target = node
            try:
                bounds = device.bounds(target)
            except RuntimeError:
                continue
            if bounds[1] >= 1280 or bounds[3] <= 0:
                continue
            candidates[bounds] = target
        # Nested Flutter semantics can repeat a caption on the same clickable
        # ancestor. Pick its smallest visible rectangle, preserving real input.
        return min(candidates, key=lambda b: (b[2]-b[0])*(b[3]-b[1])) if candidates else None

    def wait_for(phrases, timeout=50):
        deadline = time.monotonic()+timeout
        last = []
        while time.monotonic() < deadline:
            root = device.dump()
            last = labels(root)
            if any(any(phrase.casefold() in label.casefold() for label in last) for phrase in phrases):
                return root
            time.sleep(1)
        raise RuntimeError(f'Expected UI captions {phrases}; actually exposed: {last}')

    def click(phrase, contains=False, scroll=False):
        for _ in range(7 if scroll else 1):
            root = device.dump()
            bounds = find(root, phrase, contains)
            if bounds:
                left, top, right, bottom = bounds
                device.tap((left+right)//2, (top+bottom)//2)
                time.sleep(1)
                return
            if scroll:
                device.swipe(360, 1060, 360, 460, 350)
                time.sleep(.5)
        raise RuntimeError(f'Actual Flutter control missing: {phrase}')

    def native_frame(label):
        path = args.out/'screens'/f'{label}.png'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(device.adb('exec-out', 'screencap', '-p', binary=True))
        frame = read_frame(path)
        path.with_suffix('.txt').write_text(frame['text'])
        path.with_suffix('.tsv').write_text(frame['tsv'])
        return frame

    def wait_native(label, paused=False):
        deadline = time.monotonic()+90
        while time.monotonic() < deadline:
            frame = native_frame(label)
            if frame['width'] > frame['height'] and marker(frame, 'RUNDE'):
                if not paused or marker(frame, 'Weiterfahren'):
                    return frame
            time.sleep(1)
        raise RuntimeError('Actual native landscape race/resume frame did not render')

    try:
        root = wait_for(['Willkommen', 'Wie heißt', 'Spielen'])
        if any('Willkommen' in value for value in labels(root)):
            device.capture('onboarding-welcome')
            click("Los geht's!", contains=True, scroll=True)
            wait_for(['Dein Name'])
            # Blank name intentionally uses the app's synthetic default Kind.
            device.capture('onboarding-name')
            click('Weiter', scroll=True)
            wait_for(['Wie alt'])
            click('Weiter', scroll=True)
            wait_for(['Klasse gehst'])
            click('1. Klasse')
            device.capture('onboarding-grade-1')
            click('Profil speichern', scroll=True)
        elif any('Wie heißt' in value for value in labels(root)):
            raise RuntimeError('Unexpected partial onboarding on a fresh emulator; evidence retained')
        wait_for(['Spielen'])
        device.capture('flutter-home')
        # Work against the actual offline app, including its visible rewards.
        # The profile comes solely from the real onboarding controls above.
        device.adb('shell', 'svc', 'wifi', 'disable')
        device.adb('shell', 'svc', 'data', 'disable')
        flutter_checks = FlutterChecks(device, args.out, package)
        flutter_checks.learning()
        click('Spielen', contains=True)
        wait_for(['Lumo Spielewelt', 'Losfahren'])
        device.capture('flutter-games')
        # Native Kart must work without an external APK or network connection.
        device.adb('shell', 'svc', 'wifi', 'disable')
        device.adb('shell', 'svc', 'data', 'disable')
        click('Losfahren', scroll=True)
        wait_native('native-first-race')
        first_pid = device.adb('shell', 'pidof', package+':lumo_game').strip()
        subprocess.run([sys.executable, str(Path(__file__).with_name('kart_android_race.py')),
                        '--serial', args.serial, '--package', package,
                        '--out', str(args.out/'kart-race'), '--pause-back', '--require-correct',
                        '--check-wrong-hint', '--restart', '--return-to', 'games', '--timeout', '600'],
                       check=True)
        wait_for(['Losfahren'])
        device.capture('flutter-games-after-full-race')
        # Open from Flutter again, proving a new Engine process and saved race.
        click('Losfahren', scroll=True)
        frame = wait_native('native-fresh-process-saved-race', paused=True)
        next_pid = device.adb('shell', 'pidof', package+':lumo_game').strip()
        if not first_pid or not next_pid or first_pid == next_pid:
            raise RuntimeError('Reopening from Flutter did not create a fresh engine PID')
        saved_state = json.loads((args.out/'kart-race/saved-pause-before-return.json').read_text())
        restored_state = race_state(frame)
        if saved_state != restored_state:
            raise RuntimeError(f'Saved/restored visible race HUD differs: {saved_state} / {restored_state}')
        button = marker(frame, 'Zur Spieleauswahl')
        if not button:
            raise RuntimeError('Resumed native pause does not expose return to games')
        device.tap(button['left']+button['width']//2, button['top']+button['height']//2)
        wait_for(['Losfahren'])
        device.capture('flutter-after-native-reopen')
        # Exercise the other actual native return destination. Reopening the
        # retained race shows its real pause; Back while already paused would
        # return to games, so tap the visible learning button directly.
        click('Losfahren', scroll=True)
        learn_frame = wait_native('native-pause-before-return-to-learning', paused=True)
        learn_engine_pid = device.adb('shell', 'pidof', package+':lumo_game').strip()
        if not learn_engine_pid or learn_engine_pid == next_pid:
            raise RuntimeError('Learning-return check did not open a fresh native engine process')
        learn_button = marker(learn_frame, 'Zum Lernen')
        if not learn_button:
            raise RuntimeError('Actual native pause does not expose its learning return button')
        device.tap(learn_button['left']+learn_button['width']//2,
                   learn_button['top']+learn_button['height']//2)
        wait_for(['Was möchtest du üben?'])
        device.capture('flutter-learning-after-native-return')
        learn_flutter_pid = device.adb('shell', 'pidof', package).strip()
        if not learn_flutter_pid:
            raise RuntimeError('Native learning return did not leave Flutter running')
        deadline = time.monotonic()+45
        while time.monotonic() < deadline:
            engine = subprocess.run([ADB, '-s', args.serial, 'shell', 'pidof',
                                     package+':lumo_game'], capture_output=True, text=True).stdout.strip()
            if not engine:
                break
            time.sleep(.5)
        else:
            raise RuntimeError('Native learning return left the engine process running')
        learn_return_proof = {'engine_pid_before_return': learn_engine_pid,
                              'flutter_pid_after_return': learn_flutter_pid,
                              'visible_caption': 'Was möchtest du üben?',
                              'native_engine_stopped': True}
        # Full real board/card rounds, Fold-shaped resize/navigation, and exact
        # visible wallet/profile/daily-progress equality across process restart.
        flutter_checks.boards()
        flutter_proof = flutter_checks.fold_and_restart()
        if digest(args.apk) != args.sha256.lower():
            raise RuntimeError('APK input was modified during the test')
        proof = {'passed': True, **environment, 'first_engine_pid': first_pid,
                 'reopened_engine_pid': next_pid,
                 'saved_race_hud': saved_state, 'restored_race_hud': restored_state,
                 'native_learning_return': learn_return_proof,
                 'flutter_checks': flutter_proof,
                 'flow': 'Flutter learning/help/answer/reward → Kart two-lap race/result/restart/fresh native resume → native return to Flutter learning → Memory twelve pairs → Cards complete round → Fold resize/navigation → offline restart with identical visible wallet/profile/progress',
                 'race_uses_real_physics_and_wall_time': True,
                 'no_apk_rebuild_resign_or_publish': True}
        (args.out/'result.json').write_text(json.dumps(proof, indent=2, ensure_ascii=False)+'\n')
        print(json.dumps(proof, indent=2, ensure_ascii=False))
    finally:
        logs = device.adb('logcat', '-d', '-v', 'threadtime', timeout=45)
        (args.out/'android-logcat.txt').write_text(logs)
        fatal = [line for line in logs.splitlines() if re.search(
            r'FATAL EXCEPTION|Fatal signal|SCRIPT ERROR|Parse Error| E godot.*ERROR:|LUMO_ASSET_ERROR(?:\s|$)', line)]
        if fatal:
            (args.out/'fatal-errors.txt').write_text('\n'.join(fatal)+'\n')
            raise RuntimeError('Android, engine or bundled-asset errors appeared during the real usage checks; logs retained')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--serial', default='emulator-5554')
    args = parser.parse_args()
    try:
        main(args)
    except Exception:
        args.out.mkdir(parents=True, exist_ok=True)
        details = traceback.format_exc()
        (args.out/'failure.txt').write_text(details)
        (args.out/'result.json').write_text(json.dumps({'passed': False, 'sha256': args.sha256,
                                                       'physical_device_tested': False})+'\n')
        print(details, file=sys.stderr)
        raise SystemExit(1)
