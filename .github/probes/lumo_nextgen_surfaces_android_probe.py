#!/usr/bin/env python3
"""Exercise the shipped 2018 learning and Cards surfaces on the already toured APK.

Only live accessibility/OCR controls are pressed. The private Cards mailbox and
persisted child data are read, never seeded or rewritten. The existing Android
tour must have passed on these exact APK bytes before this probe can run.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import time
import traceback

sys.path.insert(0, str(Path(__file__).resolve().parent))
import modernization_android_tour as tour
from nextgen_evidence import (require_cards_draw, require_learning_bridge_moves,
                             require_public_saved_match, require_saved_round)

probe, base, live = tour.probe, tour.base, tour.live
PACKAGE = probe.PACKAGE


def wait_for(description, observe, accept, *, timeout=45):
    deadline = time.monotonic() + timeout
    latest = None
    while time.monotonic() < deadline:
        latest = observe()
        if accept(latest):
            return latest
        time.sleep(.5)
    raise RuntimeError(f'{description} not observed before deadline; latest={latest!r}')


def must_see(out: Path, caption: str, tag: str) -> list[str]:
    return wait_for('Actual Flutter text ' + caption,
                    lambda: tour.labels(live.live_nodes(out, tag)),
                    lambda labels: any(caption in text for text in labels))


def tap_flutter(out: Path, captions: list[str], tag: str) -> str:
    for caption in captions:
        try:
            probe.flutter_tap(out, caption, tag + '-' + str(len(caption)),
                              scroll_attempts=16, min_visible_height_px=48)
            return caption
        except RuntimeError:
            continue
    raise RuntimeError(f'No live Flutter route: {captions}')


def native_ready(out: Path, caption: str, tag: str) -> None:
    wait_for('Actual isolated Godot activity',
             lambda: tour.godot_alive() and 'LumoGameActivity' in base.foreground(), bool,
             timeout=60)
    probe.native_text(out, caption, tag, settle=True)


def returned_to_flutter(out: Path, caption: str, tag: str) -> None:
    wait_for('Native return and isolated process exit',
             lambda: not tour.godot_alive() and 'LumoGameActivity' not in base.foreground(),
             bool, timeout=45)
    if not tour.alive():
        raise RuntimeError('Flutter host quit during native return')
    must_see(out, caption, tag)
    probe.capture_flutter_ready(out, tag)


def learning_roundtrip(out: Path) -> dict:
    tap_flutter(out, ['Lernen'], 'learning-tab')
    tap_flutter(out, ['Lumo erklärt es mir'], 'guided-hub')
    tap_flutter(out, ['Über den Zehner'], 'guided-bridge')
    must_see(out, 'Heute lernen wir einen Rechentrick', 'guided-greeting')
    tap_flutter(out, ['Weiter'], 'guided-next')
    must_see(out, 'Zähle die Äpfel', 'guided-foundation')
    tap_flutter(out, ['6'], 'guided-answer-six')
    tap_flutter(out, ['Weiter'], 'guided-example')
    must_see(out, 'Acht und fünf', 'guided-current-example')
    probe.capture_flutter_ready(out, '01_learning_flutter_before')
    before = probe.prefs(out, 'learning-before-native')
    # Only clear the emulator diagnostic log. Application data is untouched.
    base.adb('logcat', '-c')
    tap_flutter(out, ['Mit Lumo in 3D ausprobieren'], 'learning-native-entry')
    native_ready(out, 'Zahlen zum Anfassen', 'learning-native-title')
    probe.capture(out, '02_learning_native_eight_plus_five')
    for index in range(5):
        probe.native_text(out, 'Ein Objekt zeigen', f'learning-move-{index + 1}',
                          tap=True, exact=True, settle=True)
        time.sleep(.5)
        if index == 1:
            probe.native_text(out, 'Zehn sind voll', 'learning-ten-filled', settle=True)
            probe.capture(out, '03_learning_native_ten_and_three')
    probe.native_text(out, 'gefüllt', 'learning-complete', settle=True)
    probe.capture(out, '04_learning_native_thirteen')
    movement_log = base.adb('logcat', '-d', '-v', 'brief', timeout=60)
    (out / 'learning-movement-logcat.txt').write_text(movement_log)
    moves = require_learning_bridge_moves(movement_log)
    probe.native_text(out, 'Zur Aufgabe', 'learning-back', tap=True, exact=True, settle=True)
    returned_to_flutter(out, 'Acht und fünf', '05_learning_same_flutter_lesson')
    after = probe.prefs(out, 'learning-after-native')
    preservation = tour.evidence.learning_preserved(before, after)
    if tour.evidence.learning_snapshot(before) != tour.evidence.learning_snapshot(after):
        raise RuntimeError('The explanatory 3D illustration changed learning/mastery/reward data')
    # Return through the two actually opened Flutter routes to the academy.
    for _ in range(2):
        base.adb('shell', 'input', 'keyevent', '4')
        time.sleep(1)
    must_see(out, 'Spielen', 'learning-return-navigation')
    return {'moves': moves, 'preservation': preservation, 'same_lesson_after_return': True,
            'illustration_did_not_award_mastery': True}


class CardsMailbox:
    def __init__(self, out: Path):
        self.out = out
        self.root = f'/data/user/0/{PACKAGE}/files/lumo_cards_table_v1'
        self.path = ''
        self.token = ''
        self.counter = 0

    def locate(self) -> bool:
        found = base.adb('shell', 'find', self.root, '-maxdepth', '2', '-type', 'f',
                         '-name', 'state.json', check=False).splitlines()
        matches = [p for p in found if re.fullmatch(
            re.escape(self.root) + r'/[a-f0-9]{32}/state\.json', p)]
        if len(matches) > 1:
            raise RuntimeError('Multiple live Cards sessions exist for the single opened table')
        if not matches:
            return False
        self.path = str(Path(matches[0]).parent)
        self.token = Path(self.path).name
        return True

    def read(self, name='state') -> dict:
        if name not in ('state', 'request', 'lifecycle') or not self.path:
            raise RuntimeError('Read requires an observed Cards mailbox and known file')
        raw = base.adb('exec-out', 'cat', self.path + '/' + name + '.json')
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise RuntimeError('Actual Cards mailbox is not an object')
        if name != 'lifecycle' and value.get('token') != self.token:
            raise RuntimeError('Cards mailbox identity changed')
        self.counter += 1
        (self.out / f'cards-mailbox-{self.counter:03d}-{name}.json').write_text(
            json.dumps(value, indent=2, ensure_ascii=False))
        return value

    def saved(self, round_id: str) -> dict:
        values = probe.prefs(self.out, f'cards-save-{self.counter:03d}')
        matches = []
        for key, value in values.items():
            if re.fullmatch(r'flutter\.lumo\.cards\.round\.v1\.[a-f0-9]{64}\.[1-4]\.solo', key):
                parsed = json.loads(value)
                if parsed.get('id') == round_id:
                    if parsed.get('owner') != key.split('.')[-3]:
                        raise RuntimeError('Cards save owner differs from its per-child storage key')
                    matches.append(parsed)
        if len(matches) != 1:
            raise RuntimeError('Expected exactly one actual per-child save of this Cards round')
        require_saved_round(matches[0], round_id)
        return matches[0]


def cards_roundtrip(out: Path) -> dict:
    tap_flutter(out, ['Spielen', 'Spiele'], 'cards-games-tab')
    tap_flutter(out, ['Lumo Cards', 'Lumo Cards. Sammeln. Spielen. Staunen! Spielen',
                      'Lumo Cards · Klassik'], 'cards-portal')
    tap_flutter(out, ['Solo spielen'], 'cards-solo')
    must_see(out, 'Lumo Cards', 'cards-flutter')
    probe.capture_flutter_ready(out, '10_cards_flutter_round')
    before_prefs = probe.prefs(out, 'cards-before-native')
    tap_flutter(out, ['Am 3D-Tisch spielen', '3D'], 'cards-native-entry')
    native_ready(out, '3D-Tisch', 'cards-native-title')
    box = CardsMailbox(out)
    wait_for('Private Cards IPC session created by app', box.locate, bool)
    first = box.read()
    if first.get('paused'):
        probe.native_text(out, 'Weiterspielen', 'cards-native-resume', tap=True,
                          exact=True, settle=True)
    before = wait_for('Child can draw in the real table', box.read,
                      lambda state: state.get('canDraw') is True and state.get('paused') is False)
    before_save = box.saved(before['roundId'])
    require_public_saved_match(before, before_save)
    probe.capture(out, '11_cards_real_table_before_draw')
    probe.native_text(out, 'Ziehen', 'cards-native-draw', tap=True, exact=True, settle=True)
    request = box.read('request')
    if request.get('action') != 'draw':
        raise RuntimeError('Actual native Ziehen did not publish a draw request')
    after = wait_for('Dart acknowledged native draw and the bot finished its turn', box.read,
                     lambda state: state.get('ack', -1) >= request.get('sequence', 10**10)
                     and state.get('canDraw') is True and state.get('paused') is False)
    saved = box.saved(after['roundId'])
    draw = require_cards_draw(before, request, after, saved, owner=before_save['owner'])
    probe.capture(out, '12_cards_real_table_persisted_draw')
    probe.native_text(out, 'Pause', 'cards-native-pause', tap=True, exact=True, settle=True)
    paused = wait_for('Cards clock actually paused', box.read,
                      lambda state: state.get('paused') is True)
    paused_save = box.saved(paused['roundId'])
    time.sleep(2)
    still = box.read()
    if still.get('paused') is not True or box.saved(still['roundId']) != paused_save:
        raise RuntimeError('Persisted Cards round changed while native pause was shown')
    probe.capture(out, '13_cards_native_pause')
    probe.native_text(out, 'Zurück', 'cards-native-back', tap=True, exact=True, settle=True)
    returned_to_flutter(out, 'Spiel pausiert', '14_cards_same_flutter_round')
    restored = box.saved(after['roundId'])
    if restored != paused_save:
        raise RuntimeError('Native return replaced or mutated the persisted Cards round')
    remaining = base.adb('shell', 'find', box.path, '-maxdepth', '1', '-type', 'f',
                         check=False).splitlines()
    if any(path.startswith(box.path + '/') for path in remaining):
        raise RuntimeError('Closed Cards surface left its private IPC session alive')
    preservation = tour.evidence.learning_preserved(
        before_prefs, probe.prefs(out, 'cards-after-native'))
    # The public table is temporary; the exact original saved round survives a
    # second launch through the visible Flutter button with a fresh token.
    labels = tour.labels(live.live_nodes(out, 'cards-paused-flutter-controls'))
    if 'Fortsetzen' in labels:
        tap_flutter(out, ['Fortsetzen'], 'cards-flutter-resume')
    tap_flutter(out, ['Am 3D-Tisch spielen', '3D'], 'cards-reopen')
    native_ready(out, '3D-Tisch', 'cards-reopened-title')
    reopened = CardsMailbox(out)
    wait_for('Reopened actual Cards IPC', reopened.locate, bool)
    state = reopened.read()
    if state.get('roundId') != after['roundId'] or reopened.token == box.token:
        raise RuntimeError('Cards reopen reused a mailbox or lost the same persisted round')
    if reopened.saved(state['roundId']) != restored:
        raise RuntimeError('Reopened Cards table changed the saved round before any action')
    probe.capture(out, '15_cards_reopened_same_round')
    probe.native_text(out, 'Zurück', 'cards-reopened-back', tap=True, exact=True, settle=True)
    returned_to_flutter(out, 'Spiel pausiert', '16_cards_final_flutter_return')
    return {'draw': draw, 'pause_saved_state_unchanged': True,
            'reopened_same_round': True, 'new_mailbox_token': True,
            'learning_preservation': preservation}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', required=True, type=Path)
    parser.add_argument('--provenance', required=True, type=Path)
    parser.add_argument('--sums', required=True, type=Path)
    parser.add_argument('--prior-tour', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'physical_fold7_performance_measured': False}
    try:
        identity = tour.verify_apk_identity(args.apk, args.provenance, args.sums)
        result['apk_identity'] = identity
        prior = json.loads(args.prior_tour.read_text())
        if prior.get('status') != 'PASS' or prior.get('apk_sha256') != identity['apk_sha256']:
            raise RuntimeError('The mandatory original Android tour did not pass')
        if identity['versionCode'] != 2018:
            raise RuntimeError('Nextgen surface acceptance requires versionCode 2018')
        result['emulator_root_readiness'] = probe.ensure_rooted_emulator(base.adb, out)
        base.display(1080, 2400, 420)
        if not tour.alive() or tour.godot_alive():
            raise RuntimeError('Expected the original tour to leave the installed Flutter app alive')
        result['learning'] = learning_roundtrip(out)
        result['cards'] = cards_roundtrip(out)
        fatal = tour.logcat_fatal()
        if fatal:
            raise RuntimeError(f'Actual Android crash during new surfaces: {fatal}')
        result['fatal_crashes'] = 0
        result['status'] = 'PASS'
    except Exception as error:
        result.update(status='FAIL', error=f'{type(error).__name__}: {error}',
                      traceback=traceback.format_exc())
        try:
            probe.capture(out, '99_nextgen_failure')
        except Exception:
            pass
    finally:
        (out / 'native-surfaces-result.json').write_text(
            json.dumps(result, indent=2, ensure_ascii=False) + '\n')
        print(json.dumps(result, indent=2, ensure_ascii=False), flush=True)
        try:
            (out / 'logcat.txt').write_text(base.adb('logcat', '-d', timeout=60))
        except Exception:
            pass
    if result['status'] == 'PASS':
        print('[NextgenAndroid] PASS: real learning touch, Cards IPC, save, pause, return and reopen',
              flush=True)
        return 0
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
