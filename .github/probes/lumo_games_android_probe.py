#!/usr/bin/env python3
"""Real current APK game input, live Fold resize and read-only persisted setup.
No save, balance, selection, result or target is injected into the running app.
"""
import argparse
import json
import os
from pathlib import Path
import re
import time
import traceback

import lumo_free_voice_android_probe as voice
from kart_complete_android_probe import parse_session
from lumo_games_android_controls import enabled_button_bounds, navigation_scroll_bounds
existing = voice.existing


def navigation_tap(out, caption):
    for attempt in range(10):
        nodes = existing.live.live_nodes(out, 'games-targeted-navigation-' + str(attempt))
        box = enabled_button_bounds(nodes, existing.PACKAGE, caption)
        if box:
            existing.base.adb('shell', 'input', 'tap', str((box[0]+box[2])//2), str((box[1]+box[3])//2))
            time.sleep(1)
            return
        scroll = navigation_scroll_bounds(nodes, existing.PACKAGE)
        if scroll is None:
            raise RuntimeError('No actual navigation scroll for ' + caption)
        x = (scroll[0]+scroll[2])//2
        low, high = round(scroll[1]+.2*(scroll[3]-scroll[1])), round(scroll[1]+.8*(scroll[3]-scroll[1]))
        existing.base.adb('shell', 'input', 'swipe', str(x), str(high), str(x), str(low), '400')
        time.sleep(.5)
    raise RuntimeError('No fully visible enabled navigation button: ' + caption)


def observed_label(out, label, tag):
    wanted = existing.normalized(label)
    lines = existing.image_lines(out, tag, wanted, exact=True, timeout=75)
    matches = [line for line in lines if existing.normalized(line['text']) == wanted]
    if not matches:
        raise RuntimeError('No actual current native caption: ' + label)
    return min(matches, key=lambda line: (line['bounds'][2]-line['bounds'][0]) * (line['bounds'][3]-line['bounds'][1]))


def swipe_cards(out, first, second, tag):
    anchor = observed_label(out, first, tag + '-anchor')
    before = observed_label(out, second, tag + '-second-before')
    x0, y0, x1, y1 = anchor['bounds']
    x, y = round((x0+x1)/2), round((y0+y1)/2)
    # The drag starts on a CURRENT card word, not a guessed screen coordinate.
    destination = max(1, y - 220)
    existing.base.adb('shell', 'input', 'swipe', str(x), str(y), str(x), str(destination), '600')
    time.sleep(1)
    after = observed_label(out, second, tag + '-second-after')
    shift = (before['bounds'][1]+before['bounds'][3]-after['bounds'][1]-after['bounds'][3])/2
    if shift < 40:
        raise RuntimeError('Actual card caption did not scroll at least40px: ' + tag)
    return {'before': before, 'after': after, 'movement_pixels': shift,
            'input': {'start': [x,y], 'end': [x,destination], 'milliseconds': 600}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'physical_device': False, 'paid_api_calls': 0,
              'candidate_source': os.environ['LUMO_EXPECT_SOURCE'],
              'godot_revision': os.environ['LUMO_EXPECT_GODOT']}
    try:
        identity = existing.package_identity(out, 'games-installed-identity')
        if int(identity['versionCode'].split()[0]) != int(os.environ['LUMO_EXPECT_VERSION']):
            raise RuntimeError('Games probe is not running the declared new APK')
        before_profiles = voice.protected(existing.prefs(out, 'games-before-profiles'))
        before_wallet = existing.wallet(out, 'games-before-wallet')
        # Enter through the actual normal overview before testing the standalone
        # game's short enlarged-text layout. The shell's 90px content viewport
        # needs far more list movement than the independent game under test.
        existing.base.display(1200, 896, 160)
        existing.base.adb('shell', 'settings', 'put', 'system', 'font_scale', '1.0')
        navigation_tap(out, 'Spielen')
        existing.flutter_tap(out, 'Würfel-Wettlauf', 'actual-dice-entry', scroll_attempts=32)
        existing.base.display(926, 362, 160)
        existing.base.adb('shell', 'settings', 'put', 'system', 'font_scale', '1.6')
        existing.capture(out, '30_actual_android_dice_large_text_before')
        existing.flutter_tap(out, 'Würfeln!', 'actual-dice-roll')
        existing.flutter_tap(out, 'Pausieren / Zurück', 'actual-dice-pause')
        existing.capture(out, '31_actual_android_dice_paused')
        existing.flutter_tap(out, 'Fortsetzen', 'actual-dice-resume')
        time.sleep(3)
        nodes = existing.live.live_nodes(out, 'dice-real-move-state')
        text = existing.base.accessible_text([n for n in nodes if n.get('package') == existing.PACKAGE])
        positions = [int(n) for n in re.findall(r'([0-9]{1,2})\s*/\s*30', text)]
        if len(positions) < 2 or not any(0 < n <= 6 for n in positions):
            raise RuntimeError('No actual first dice movement was observed')
        result['dice'] = {'real_roll_pause_resume': True, 'observed_positions': positions}
        existing.capture(out, '32_actual_android_dice_large_text_after')
        existing.flutter_tap(out, 'Pausieren / Zurück', 'dice-exit-pause')
        existing.flutter_tap(out, 'Zur Spieleauswahl', 'dice-return')
        existing.base.adb('shell', 'settings', 'put', 'system', 'font_scale', '1.0')
        existing.base.display(1200, 896, 160)
        existing.enter(out, 'Lumo Kart', 'Einzelrennen', 'fold-kart', launch_label='Losfahren')
        existing.native_tap(out, 'Weiter', 'fold-driver-step')
        existing.native_text(out, 'Wer fährt mit', 'fold-driver-heading')
        before_pid = existing.base.adb('shell', 'pidof', existing.PACKAGE + ':lumo_game').strip()
        existing.base.display(2176, 1812, 360)
        existing.native_tap(out, 'Lumo', 'fold-current-lumo', exact=True)
        existing.capture(out, '33_actual_android_fold_driver_selection')
        after_pid = existing.base.adb('shell', 'pidof', existing.PACKAGE + ':lumo_game').strip()
        if not before_pid or before_pid != after_pid:
            raise RuntimeError('Live Fold resize restarted the actual native process')
        result['fold_driver'] = {'native_process_retained': True, 'selected': 'fox',
            'note': 'Available Lumo tapped; alternate unlocked driver tested in isolated desktop balance fixture, not fabricated in Android'}
        existing.native_tap(out, 'Weiter', 'fold-kart-step')
        result['kart_scroll'] = swipe_cards(out, 'Comet', 'Gecko Velo', 'fold-kart-scroll')
        existing.native_tap(out, 'Gecko Velo', 'fold-select-gecko', exact=True)
        existing.capture(out, '34_actual_android_fold_scrolled_kart')
        existing.native_tap(out, 'Weiter', 'fold-world-step')
        result['track_scroll'] = swipe_cards(out, 'Sonnenhafen', 'Zauberwald', 'fold-world-scroll')
        existing.native_tap(out, 'Zauberwald', 'fold-select-world', exact=True)
        existing.capture(out, '35_actual_android_fold_scrolled_world')
        existing.native_tap(out, 'Weiter', 'fold-tempo-step')
        existing.native_tap(out, 'Rennen starten', 'fold-selected-race-start')
        time.sleep(5)
        existing.base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        time.sleep(2)
        paths = existing.base.adb('shell', 'find', f'/data/user/0/{existing.PACKAGE}', '-maxdepth', '12',
            '-type', 'f', '-name', 'kart_sonnenhafen_session.cfg').splitlines()
        if len(paths) != 1:
            raise RuntimeError('Exactly one actual race save required')
        raw = existing.base.adb('exec-out', 'cat', paths[0])
        (out/'actual-fold-selected-session.cfg').write_text(raw)
        saved = parse_session(raw)
        if (saved['selected_driver'], saved['selected_kart'], saved['track_id']) != ('fox', 'gecko_velo', 'zauberwald'):
            raise RuntimeError('Actual persisted race differs from driver/kart/world taps')
        result['saved_setup'] = {'driver': saved['selected_driver'], 'kart': saved['selected_kart'],
            'track': saved['track_id'], 'result_id': saved['result_id']}
        existing.leave(out, 'fold-return', already_menu=True, return_label='Zur Spieleauswahl')
        existing.base.display(360, 800, 160)
        after_profiles = voice.protected(existing.prefs(out, 'games-after-profiles'))
        after_wallet = existing.wallet(out, 'games-after-wallet')
        if after_profiles != before_profiles or after_wallet != before_wallet:
            raise RuntimeError('Playing or resizing mixed/changed profiles, learning progress or wallet')
        result['profiles_unchanged'] = result['wallet_unchanged'] = True
        existing.base.adb('shell', 'am', 'force-stop', existing.PACKAGE)
        existing.base.launch(out, 'games-final-restart')
        if (voice.protected(existing.prefs(out, 'games-restarted-profiles')) != before_profiles
            or existing.wallet(out, 'games-restarted-wallet') != before_wallet):
            raise RuntimeError('Profiles/progress/wallet changed after games restart')
        result['restart_unchanged'] = True
        result['status'] = 'PASS'
        return 0
    except Exception:
        result['status'] = 'FAIL'
        result['error'] = traceback.format_exc()
        try:
            existing.capture(out, 'games-FAIL-current-frame')
        except Exception:
            pass
        return 1
    finally:
        existing.base.adb('shell', 'settings', 'put', 'system', 'font_scale', '1.0', check=False)
        (out/'games-android-result.json').write_text(json.dumps(result, indent=2, ensure_ascii=False)+'\n')


if __name__ == '__main__':
    raise SystemExit(main())
