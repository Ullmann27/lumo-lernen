#!/usr/bin/env python3
"""Exercise the existing 1999 bytes as an actual offline update from 1997.

Only live touches produce the fictional child's baseline learning. Preferences
and Godot session files are read only. A failed phase aborts this release gate.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback

import modernization_android_tour as tour
from update_preservation import require_in_place_update, require_learning_preserved

probe, base, live = tour.probe, tour.base, tour.live
SOURCE = 'c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf'
BASE_SOURCE = '136f486ac3bdc4aabbd3b990e6629d2d6640c7d4'
GODOT = '4d0fd40fdf188be6ca86057596c7b51f41701fa3'


def artifact(apk: Path, source: str, version: int) -> dict:
    info = json.loads((apk.parent / 'BUILD-PROVENANCE.json').read_text())
    expected = {'flutter_source_commit': source, 'tracked_source_clean': True,
                'versionCode': version, 'package': tour.PACKAGE,
                'signingCertificateSha256': probe.CERT, 'sha256': probe.digest(apk)}
    if any(info.get(key) != value for key, value in expected.items()):
        raise RuntimeError('Artifact provenance does not identify the expected APK')
    if info['abis'] != ['x86_64']:
        raise RuntimeError('Update gate requires the actual x86_64 native APK')
    if version == 1999 and info['godot']['revision'] != GODOT:
        raise RuntimeError('Candidate Kart source is not the reviewed pin')
    return info


def wait_profile(out: Path, tag: str) -> None:
    probe.flutter_tap(out, 'Start', tag + '-start', scroll_attempts=8)
    for index in range(15):
        nodes = live.live_nodes(out, f'{tag}-{index}')
        if 'LumoTest' in base.accessible_text(nodes):
            probe.capture_flutter_ready(out, tag)
            return
        boxes = []
        for node in nodes:
            if node.get('package') != tour.PACKAGE or node.get('scrollable') != 'true':
                continue
            bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
            if len(bounds) == 4 and bounds[2] > bounds[0] and bounds[3] > bounds[1]:
                boxes.append(((bounds[2] - bounds[0]) * (bounds[3] - bounds[1]), *bounds))
        if boxes:
            _, x0, y0, x1, y1 = max(boxes)
            x = str((x0 + x1) // 2)
            base.adb('shell', 'input', 'swipe', x, str(y0 + (y1-y0)//5),
                     x, str(y0 + (y1-y0)*4//5), '390')
        time.sleep(1)
    raise RuntimeError('Retained child is not visible in the actual Flutter UI')


def native_tour(out: Path) -> dict:
    if tour.try_tap(out, ['Spielen'], 'updated-games') is None:
        raise RuntimeError('Actual games navigation is unavailable after update')
    probe.capture_flutter_ready(out, '20_spiele')
    if tour.try_tap(out, ['Lumo Kart. Fahre mit Lumo um die Wette! Spielen',
                         'Losfahren', 'Rennen starten'], 'open-kart') is None:
        raise RuntimeError('Actual Kart portal is not touchable after update')
    time.sleep(32)
    if not tour.godot_alive():
        raise RuntimeError('Native Godot process failed to launch after update')
    race = tour._start_actual_embedded_race(out)
    session = tour.RaceSession(out, expected_mode=race['expected_mode'],
                               expected_track=race['expected_track'])
    start = tour.wait_race_running(session)
    hud = tour.wait_race_hud(out)
    drive = tour.drive_with_gas(out, tour.find_gas(out, hud['capture']), session, start)
    base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    probe.native_text(out, 'Eine kleine Pause', '21_pause_title')
    probe.native_text(out, 'Weiterfahren', '21_pause_resume', exact=True)
    probe.capture(out, '21_lumo_kart_pause')
    paused = session.read('21_pause_first')
    tour.evidence.require_race_session(paused, mode=session.expected_mode,
                                     track=session.expected_track)
    if paused['result_id'] != start['result_id']:
        raise RuntimeError('Pause belongs to another native race')
    time.sleep(3)
    frozen = tour.evidence.paused_unchanged(paused, session.read('21_pause_second'),
        mode=session.expected_mode, track=session.expected_track)
    base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    returned = probe.flutter_return_capture(out, '23_zurueck_in_flutter')
    if not tour.alive():
        raise RuntimeError('Flutter did not remain usable after native return')
    return {'race': race, 'hud': hud, 'drive': drive, 'pause': frozen, 'return': returned}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'candidate_source': SOURCE,
              'scope': 'Actual 1997 learning -> install -r 1999 -> offline Kart -> restart/fold',
              'not_tested': ['physical ARM64 device', 'GPU frame times / 60 FPS',
                             'audio output', 'complete two-lap race reward']}
    try:
        result['baseline'] = artifact(args.baseline, BASE_SOURCE, 1997)
        result['candidate'] = artifact(args.candidate, SOURCE, 1999)
        result['emulator'] = probe.ensure_rooted_emulator(base.adb, out)
        base.adb('logcat', '-c')
        base.display(1080, 2400, 420)
        installed = base.adb('install', '-r', '--no-streaming', str(args.baseline), timeout=300)
        (out / 'baseline-install.txt').write_text(installed)
        if 'Success' not in installed:
            raise RuntimeError('Baseline installation failed')
        base.launch(out, 'baseline')
        result['onboarding'] = probe.onboard(out)
        if result['onboarding']['status'] != 'PASS':
            raise RuntimeError('Baseline onboarding did not pass')
        learned = out / 'baseline-learning'
        subprocess.run([sys.executable, str(Path(__file__).with_name('lumo_learning_journey_probe.py')),
                        '--out', str(learned), '--learning-hub'],
                       check=True, timeout=900)
        result['learning_journey'] = json.loads((learned / 'learning-journey-result.json').read_text())
        if result['learning_journey']['status'] != 'PASS':
            raise RuntimeError('The actual baseline answer/reward/restart did not pass')
        base.adb('shell', 'am', 'force-stop', tour.PACKAGE)
        before = probe.prefs(out, 'before-update')
        require_learning_preserved(before, before)
        old_identity = probe.package_identity(out, 'baseline')
        if int(old_identity['versionCode'].split()[0]) != 1997:
            raise RuntimeError('Installed baseline version is not 1997')
        installed = base.adb('install', '-r', '--no-streaming', str(args.candidate), timeout=300)
        (out / 'update-install.txt').write_text(installed)
        if 'Success' not in installed:
            raise RuntimeError('Candidate in-place installation failed')
        result['installation'] = require_in_place_update(
            old_identity, probe.package_identity(out, 'updated'), 1999)
        base.adb('shell', 'svc', 'wifi', 'disable')
        base.adb('shell', 'svc', 'data', 'disable')
        base.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        if base.adb('shell', 'settings', 'get', 'global', 'airplane_mode_on').strip() != '1':
            raise RuntimeError('Offline mode was not applied')
        base.display(1080, 2400, 420)
        base.launch(out, 'updated-offline')
        wait_profile(out, 'updated-profile-offline')
        result['after_update'] = require_learning_preserved(before, probe.prefs(out, 'after-update'))
        result['native_tour'] = native_tour(out)
        result['after_kart'] = require_learning_preserved(before, probe.prefs(out, 'after-kart'))
        base.adb('shell', 'am', 'force-stop', tour.PACKAGE)
        base.launch(out, 'restart-offline')
        wait_profile(out, 'restart-profile-offline')
        result['after_restart'] = require_learning_preserved(before, probe.prefs(out, 'after-restart'))
        result['fold'] = {}
        for name, size in (('cover', (904, 2316, 420)), ('open', (1812, 2176, 420)),
                           ('landscape', (2400, 1080, 420))):
            base.display(*size)
            time.sleep(4)
            wait_profile(out, 'fold-' + name)
            result['fold'][name] = require_learning_preserved(before, probe.prefs(out, 'fold-' + name))
        fatal = tour.logcat_fatal()
        (out / 'fatal-logcat.txt').write_text('\n\n'.join(fatal))
        if fatal or not tour.alive():
            raise RuntimeError('App crash or unusable Flutter after update tour')
        result.update(status='PASS', offline=True, fatal_crashes=0)
    except Exception as error:
        result.update(status='FAIL', error=str(error), traceback=traceback.format_exc())
        try:
            probe.capture(out, '99_fehler')
        except Exception:
            pass
    finally:
        (out / 'update-result.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
        try:
            (out / 'logcat.txt').write_text(base.adb('logcat', '-d', timeout=60))
        except Exception:
            pass
        print('[LumoUpdate]', result['status'], result.get('error', ''), flush=True)
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
