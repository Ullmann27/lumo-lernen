#!/usr/bin/env python3
"""Exact-APK visual/navigation acceptance; real UI and read-only saved state.
Not a complete Kart race or a physical Fold/performance/audio-quality approval.
"""
import argparse
import json
import os
from pathlib import Path
import time
import traceback
import lumo_education_android_probe as edu
import lumo_free_voice_android_probe as voice
import kart_complete_android_probe as race

existing = edu.existing


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--candidate', type=Path, required=True)
    p.add_argument('--baseline', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'screenshots': [], 'not_tested': [
        'physical Fold hinge', 'ARM64 physical hardware', 'complete two-lap race',
        'human voice quality', 'mobile FPS/performance certification'],
        'paid_calls': 0, 'microphone_recording': False}
    def shot(role):
        item = existing.capture(out, role)
        item.update(flutter_commit=os.environ['LUMO_EXPECT_SOURCE'],
                    godot_commit=os.environ['LUMO_EXPECT_GODOT'],
                    candidate_sha256=result['candidate']['sha256'],
                    runtime='Android emulator, installed x86_64 APK from unified build')
        result['screenshots'].append(item)
    def tap(label, tag):
        edu.tap(out, label, tag)
    def wait(label, tag):
        return edu.wait_text(out, label, tag, timeout=50)
    try:
        candidate = voice.delivery(args.candidate, 1939, os.environ['LUMO_EXPECT_SOURCE'])
        assert candidate['godot']['revision'] == os.environ['LUMO_EXPECT_GODOT']
        result['candidate'] = candidate
        baseline = voice.delivery(args.baseline, 1937, 'a71c1cdea21af202d71273da19bb4d00988fc970')
        assert baseline['sha256'] == 'be6865fc8f5a5524d9932ad3cfa68fe499138a05499fae745a16d34c44ea3e2f'
        result['root'] = existing.ensure_rooted_emulator(existing.base.adb, out)
        result['android_api'] = existing.base.adb('shell', 'getprop', 'ro.build.version.sdk').strip()
        existing.base.display(1080, 2400, 480)
        assert 'Success' in existing.base.adb('install', '-r', '--no-streaming', str(args.baseline), timeout=180)
        existing.base.adb('shell', 'svc', 'wifi', 'disable')
        existing.base.adb('shell', 'svc', 'data', 'disable')
        existing.base.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        existing.base.launch(out, 'baseline-offline')
        result['baseline_onboarding'] = existing.onboard(out)
        identity = existing.package_identity(out, 'before-update')
        protected = voice.protected(existing.prefs(out, 'before-update'))
        wallet = existing.wallet(out, 'before-update-wallet')
        existing.base.adb('shell', 'am', 'force-stop', existing.PACKAGE)
        assert 'Success' in existing.base.adb('install', '-r', '--no-streaming', str(args.candidate), timeout=240)
        current = existing.package_identity(out, 'after-update')
        assert current['versionCode'].split()[0] == '1939'
        assert current['userId'] == identity['userId'] and current['firstInstallTime'] == identity['firstInstallTime']
        existing.base.launch(out, 'candidate-offline')
        assert voice.protected(existing.prefs(out, 'after-update')) == protected
        assert existing.wallet(out, 'after-update-wallet') == wallet
        result['update_preserved'] = {'profile_and_progress': True, 'wallet': True, 'installation': current}
        tap('Start', 'home')
        wait('LumoTest', 'home-loaded')
        shot('01-home-phone')
        tap('Mehr', 'more-open')
        wait('Mehr mit Lumo', 'more-visible')
        shot('02-more-phone')
        tap('Elternbereich', 'more-to-parents')
        wait('Sichere Einstellungen', 'parents-loaded')
        shot('03-parents-phone')
        tap('Lernen', 'learning-phone')
        # UI label observed in actual 1939 Android screenshot: 'Mathe', not 'Mathematik'.
        wait('Mathe', 'learning-phone-loaded')
        shot('04-learning-phone')
        existing.base.display(2176, 1812, 225)
        wait('Mathe', 'learning-fold-loaded')
        shot('05-learning-fold')
        tap('Start', 'home-fold')
        wait('LumoTest', 'home-fold-loaded')
        shot('06-home-fold')
        tap('Geschichten lesen und erfinden', 'library-entry')
        wait('Meine Geschichten', 'library-loaded')
        shot('07-library-fold')
        existing.base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        wait('LumoTest', 'library-back')
        tap('Spielen', 'games-entry')
        wait('Lumo Kart', 'games-loaded')
        shot('08-games-fold')
        # Same actual APK, smaller landscape surface for software-rendered 3D.
        existing.base.display(1200, 896, 160)
        existing.enter(out, 'Lumo Kart', 'Einzelrennen', 'kart-menu', launch_label='Losfahren')
        shot('09-kart-menu')
        for step in range(4):
            existing.native_tap(out, 'Weiter', 'kart-next-' + str(step))
        existing.native_tap(out, 'Rennen starten', 'kart-start')
        existing.native_text(out, 'RUNDE', 'kart-real-race-hud')
        existing.base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        existing.native_text(out, 'Eine kleine Pause', 'kart-pause')
        existing.native_tap(out, 'Gas: GAS-Taste halten', 'kart-public-autogas')
        existing.native_text(out, 'Gas: automatisch', 'kart-autogas-confirmed')
        existing.native_tap(out, 'Weiterfahren', 'kart-resume')
        # Read-only evidence of natural movement; never write race state.
        paths = existing.base.adb('shell', 'find', '/data/user/0/' + existing.PACKAGE,
                                 '-maxdepth', '12', '-type', 'f', '-name', 'kart_sonnenhafen_session.cfg').splitlines()
        assert len(paths) == 1, 'One actual profile-bound Kart save required'
        for attempt in range(45):
            time.sleep(3)
            raw = existing.base.adb('exec-out', 'cat', paths[0])
            (out / f'race-motion-{attempt}.cfg').write_text(raw)
            state = race.parse_session(raw)
            if state['countdown'] <= 0 and state['speed'] > 0 and state['distance'] > 5:
                result['actual_race_motion'] = state
                break
        else:
            raise RuntimeError('No natural race movement verified')
        shot('10-kart-running-race')
        existing.leave(out, 'kart-return', return_label='Zum Lernen')
        existing.base.display(1080, 2400, 480)
        tap('Start', 'return-home')
        wait('LumoTest', 'profile-still-present')
        assert voice.protected(existing.prefs(out, 'after-race')) == protected
        assert existing.wallet(out, 'after-race-wallet') == wallet
        existing.base.adb('shell', 'am', 'force-stop', existing.PACKAGE)
        existing.base.launch(out, 'restart')
        wait('LumoTest', 'restart-profile')
        shot('11-restart-phone')
        result['status'] = 'PASS'
        return 0
    except Exception as error:
        result.update(status='FAIL', error=str(error), traceback=traceback.format_exc())
        try:
            existing.capture(out, 'FAIL-current-screen')
        except Exception:
            pass
        return 1
    finally:
        (out / 'RESULT.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
        print(json.dumps({'status': result['status'], 'error': result.get('error'), 'screenshots': len(result['screenshots'])}), flush=True)

if __name__ == '__main__':
    raise SystemExit(main())
