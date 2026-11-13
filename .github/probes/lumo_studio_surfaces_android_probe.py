#!/usr/bin/env python3
"""Exercise the shipped Studio 2019 learning and Cards surfaces on the already toured APK.

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
import lumo_education_android_probe as education
from nextgen_evidence import (require_cards_authority_binding, require_cards_draw, require_learning_bridge_moves,
                             require_learning_voice, require_public_saved_match, require_saved_round)
from nextgen_evidence import cards_projected_faces, require_cards_face_pixels

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
             lambda: tour.godot_alive() and 'LumoGameActivity' in resumed_activity(), bool,
             timeout=60)
    probe.native_text(out, caption, tag, settle=True, orientation='responsive')


def resumed_activity() -> str:
    try:
        return base.foreground()
    except RuntimeError as error:
        # During an actual activity handoff Android can briefly report no
        # resumed app. Keep waiting; an empty observation never passes a gate.
        if str(error).startswith('Probe app not foreground:'):
            return ''
        raise


def returned_to_flutter(out: Path, caption: str, tag: str, *, scroll_to_caption=False) -> None:
    wait_for('Native return and isolated process exit',
             lambda: not tour.godot_alive() and 'MainActivity' in resumed_activity(),
             bool, timeout=45)
    if not tour.alive():
        raise RuntimeError('Flutter host quit during native return')
    if scroll_to_caption:
        # Returning preserves the real lesson's scroll offset. Its 3D launch
        # control is below the illustration; bring the same title back into
        # view through actual content swipes, never a different route.
        education.wait_text(out, caption, tag, timeout=45, scroll=True)
    else:
        must_see(out, caption, tag)
    probe.capture_flutter_ready(out, tag)


def local_voice_permission(out: Path) -> dict:
    """Use the existing assent dialog on this disposable, fictional test profile."""
    def settings(tag):
        raw = probe.prefs(out, tag).get('flutter.lumo_app_settings_v1')
        value = json.loads(raw) if raw else {}
        if not isinstance(value, dict):
            raise RuntimeError('Saved settings are not an object')
        return value

    before = settings('voice-settings-before')
    tap_flutter(out, ['Spielen', 'Spiele'], 'voice-games-entry')
    tap_flutter(out, ['Einstellungen'], 'voice-settings-entry')
    must_see(out, 'Elternbereich', 'voice-settings-open')
    if before.get('localVoiceLicenseAccepted') is not True:
        tap_flutter(out, ['Neue Sätze offline vorlesen'], 'voice-license-open')
        must_see(out, 'Neue Sätze kostenlos vorlesen', 'voice-license-dialog')
        tap_flutter(out, [
            'Als erwachsene Person akzeptiere ich für die lokale Sprachfunktion die '
            'obenstehenden Modellbedingungen einschließlich der Nutzungsbeschränkungen.'
        ], 'voice-license-checkbox')
        probe.capture_flutter_ready(out, '00a_voice_local_model_assent')
        tap_flutter(out, ['Lokale Stimme freigeben'], 'voice-license-confirm')
    wait_for('Local model assent persisted through its actual dialog',
             lambda: settings('voice-license-observed'),
             lambda value: value.get('localVoiceLicenseAccepted') is True)
    for label, key, wanted in (('Lumo-Stimme', 'voiceEnabled', True),
                               ('Automatisch vorlesen', 'autoReadEnabled', True),
                               ('Ruhiger Modus', 'calmMode', False)):
        current = settings('voice-setting-' + key)
        if type(current.get(key)) is not bool:
            raise RuntimeError('Actual voice setting is unavailable: ' + key)
        if current[key] != wanted:
            tap_flutter(out, [label], 'voice-switch-' + key)
            wait_for('Actual setting ' + key, lambda: settings('voice-read-' + key),
                     lambda value: value.get(key) is wanted)
    after = settings('voice-settings-after')
    for key in ('microphoneEnabled', 'scannerEnabled', 'aiProxyEnabled', 'cloudVoiceEnabled'):
        # Unwritten legacy settings default false in the production AppSettings.
        if after.get(key) is not before.get(key, False):
            raise RuntimeError('Local model assent changed an unrelated permission: ' + key)
    probe.capture_flutter_ready(out, '00b_voice_local_model_enabled')
    return {'local_model_assent': True, 'voice_enabled': True, 'auto_read': True,
            'unrelated_permissions_unchanged': True, 'no_audio_emulator': True,
            'audible_quality_verified': False, 'lip_sync_verified': False}


def _speech_logcat() -> str:
    """Collect real native speech and Godot events without draining every system log.

    CI emulators may return adb/logcat 255 on a disconnected logd stream.
    A failed transport read is never speech evidence.
    """
    for attempt in range(3):
        try:
            return base.adb('logcat', '-d', '-v', 'brief', '-s',
                            'LumoLearningSpeech:I', 'godot:I', 'Godot:I', '*:S',
                            timeout=60)
        except RuntimeError as error:
            if "Command failed (255): ('adb', 'logcat'" not in str(error) or attempt == 2:
                raise
            time.sleep(1)
    raise RuntimeError('Unreachable speech logcat retry state')


def completed_native_speech(out: Path, *, after_final_move=False) -> dict:
    def observe():
        log = _speech_logcat()
        (out / 'learning-speech-logcat.txt').write_text(log)
        try:
            return require_learning_voice(log, after_final_move=after_final_move)
        except RuntimeError:
            return None
    return wait_for('Actual original local MediaPlayer start and completion',
                    observe, lambda evidence: evidence is not None, timeout=180)


def learning_roundtrip(out: Path) -> dict:
    tap_flutter(out, ['Lernen'], 'learning-tab')
    tap_flutter(out, ['Lernwerkzeuge & Geschichten'], 'guided-tools')
    must_see(out, 'Dein Lernatelier', 'guided-tools-open')
    tap_flutter(out, ['Lumo erklärt es mir'], 'guided-hub')
    must_see(out, 'Über den Zehner', 'guided-bridge-card')
    education.tap_named_course(out, 'Über den Zehner', 'guided-bridge')
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
    initial_voice = completed_native_speech(out)
    for index in range(5):
        probe.native_text(out, 'Ein Objekt zeigen', f'learning-move-{index + 1}',
                          tap=True, exact=True, settle=True, orientation='responsive')
        time.sleep(.5)
        if index == 1:
            probe.native_text(out, 'Zehn sind voll', 'learning-ten-filled', settle=True,
                              orientation='responsive')
            probe.capture(out, '03_learning_native_ten_and_three')
    probe.native_text(out, 'gefüllt', 'learning-complete', settle=True,
                      orientation='responsive')
    probe.capture(out, '04_learning_native_thirteen')
    movement_log = _speech_logcat()
    (out / 'learning-movement-logcat.txt').write_text(movement_log)
    moves = require_learning_bridge_moves(movement_log)
    final_voice = completed_native_speech(out, after_final_move=True)
    if (initial_voice['native_process_pid'] != final_voice['native_process_pid'] or
            min(final_voice['completed_utterance_ids']) <= max(initial_voice['completed_utterance_ids'])):
        raise RuntimeError('The spoken result was not a new utterance in the same native lesson')
    probe.native_text(out, 'Zur Aufgabe', 'learning-back', tap=True, exact=True, settle=True,
                      orientation='responsive')
    returned_to_flutter(out, 'Acht und fünf', '05_learning_same_flutter_lesson',
                        scroll_to_caption=True)
    after = probe.prefs(out, 'learning-after-native')
    preservation = tour.evidence.learning_preserved(before, after)
    if tour.evidence.learning_snapshot(before) != tour.evidence.learning_snapshot(after):
        raise RuntimeError('The explanatory 3D illustration changed learning/mastery/reward data')
    # Return through the two actually opened Flutter routes to the academy.
    for caption, tag in (('Mit Lumo anfangen', 'learning-return-hub'),
                         ('LUMO AKADEMIE', 'learning-return-academy')):
        base.adb('shell', 'input', 'keyevent', '4')
        time.sleep(1)
        must_see(out, caption, tag)
    must_see(out, 'Spielen', 'learning-return-navigation')
    return {'moves': moves, 'preservation': preservation, 'same_lesson_after_return': True,
            'speech': {'initial': initial_voice, 'result': final_voice,
                       'native_process_gone_on_return': True,
                       'audible_quality_verified': False, 'lip_sync_verified': False},
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


def cards_ready_to_draw(out: Path, box: CardsMailbox, *, timeout=90) -> tuple[dict, dict]:
    """Observe current state throughout OCR; never press a vanished pause modal."""
    started = time.monotonic()
    deadline = started + timeout
    evidence = {'status': 'WAITING', 'states': [], 'frames': [], 'touch': None,
                'scope': 'Actual initial Cards state and, only if needed, native resume'}
    identity = None
    previous = None
    previous_revision = None

    def observe():
        nonlocal identity
        state = box.read()
        current = (state.get('token'), state.get('roundId'), state.get('viewer'))
        if (state.get('protocol') != 1 or current[0] != box.token or current[2] != 0 or
                not re.fullmatch(r'cards-[a-f0-9]{32}', current[1] or '')):
            raise RuntimeError('Cards readiness requires the actual child session')
        if identity is not None and current != identity:
            raise RuntimeError('Cards session changed while observing its pause control')
        identity = current
        facts = {key: state.get(key) for key in
                 ('token', 'roundId', 'viewer', 'current', 'phase', 'paused',
                  'canDraw', 'revision', 'ack')}
        evidence['states'].append(facts)
        if state.get('phase') == 'gameOver':
            raise RuntimeError('Cards round ended before the requested child draw')
        return state

    def child_turn(state):
        return (state.get('paused') is False and state.get('canDraw') is True and
                state.get('phase') == 'playing' and state.get('current') == 0)

    try:
        while time.monotonic() < deadline:
            state = observe()
            if child_turn(state):
                evidence.update(status='READY', mode='active_without_resume_touch')
                return state, evidence
            if state.get('paused') is not True:
                previous = None
                time.sleep(min(.5, max(0, deadline - time.monotonic())))
                continue
            tag = f'cards-native-resume-{len(evidence["frames"]):02d}'
            snapshot = probe.capture(out, tag, timeout=deadline - time.monotonic())
            source = out / snapshot['file']
            frame = probe.inspect_surface(source, orientation='responsive')
            evidence['frames'].append(frame)
            if not frame['acceptable_for_target_sampling']:
                previous = None
                time.sleep(min(.5, max(0, deadline - time.monotonic())))
                continue
            wanted = probe.normalized('Weiterspielen')
            lines = probe.image_lines(out, tag, wanted, source_path=source, exact=True,
                                      timeout=max(.001, deadline - time.monotonic()))
            latest = observe()
            # Opening the mailbox pauses Dart until the first native heartbeat.
            # It may resume while screenshot/OCR work is in progress. Discard
            # those old coordinates instead of searching for or pressing them.
            if latest.get('paused') is not True or latest.get('revision') != state.get('revision'):
                frame['state_changed_during_ocr'] = True
                previous = None
                continue
            matches = [line for line in lines if probe.normalized(line['text']) == wanted]
            if not matches:
                previous = None
            else:
                selected = min(matches, key=lambda line: len(line['text']))
                observed = probe.target_observation(
                    frame, selected['bounds'],
                    previous if previous_revision == latest.get('revision') else None)
                frame['target'] = observed
                previous, previous_revision = observed, latest.get('revision')
                if observed['stable_observed_target']:
                    if probe.digest(source) != frame['source_sha256']:
                        raise RuntimeError('Cards screenshot changed during target observation')
                    before_touch = observe()
                    if (before_touch.get('paused') is not True or
                            before_touch.get('revision') != previous_revision):
                        frame['state_changed_before_touch'] = True
                        previous = None
                        continue
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        break
                    x0, y0, x1, y1 = observed['bounds']
                    x, y = str(round((x0 + x1) / 2)), str(round((y0 + y1) / 2))
                    base.adb('shell', 'input', 'swipe', x, y, x, y, '120',
                             timeout=min(15, remaining))
                    evidence['touch'] = [int(x), int(y)]
                    time.sleep(min(1.5, max(0, deadline - time.monotonic())))
                    request = box.read('request')
                    sequence = request.get('sequence')
                    if (request.get('action') != 'resume' or request.get('token') != box.token or
                            request.get('revision') != before_touch.get('revision') or
                            type(sequence) is not int or sequence <= before_touch.get('ack', -1)):
                        raise RuntimeError('Actual Weiterspielen touch did not publish a fresh resume request')
                    evidence['resume_request'] = request
                    ready = wait_for('Same Cards round acknowledged native resume', observe,
                                     lambda value: child_turn(value) and
                                     value.get('ack', -1) >= sequence and
                                     value.get('revision', -1) > request['revision'],
                                     timeout=max(0, deadline - time.monotonic()))
                    evidence.update(status='READY', mode='native_resume_acknowledged')
                    return ready, evidence
            time.sleep(min(.5, max(0, deadline - time.monotonic())))
        raise TimeoutError('Cards did not expose an active child turn or a current resume control')
    except Exception as error:
        evidence.update(status='FAIL', error=str(error))
        raise
    finally:
        evidence['elapsed_seconds'] = round(time.monotonic() - started, 6)
        (out / 'cards-initial-readiness.json').write_text(
            json.dumps(evidence, indent=2, ensure_ascii=False) + '\n')


def cards_display_density(out: Path) -> float:
    observed = base.adb('shell', 'wm', 'density')
    (out / 'cards-actual-display-density.txt').write_text(observed + '\n')
    override = re.findall(r'(?m)^Override density:\s*(\d+)\s*$', observed)
    physical = re.findall(r'(?m)^Physical density:\s*(\d+)\s*$', observed)
    values = override if override else physical
    if len(values) != 1 or not 72 <= int(values[0]) <= 1280:
        raise RuntimeError('Cards pixel proof could not read the actual Android display density')
    # Same documented clamp as MobileRuntime.get_ui_density, whose supplied
    # value comes from Android Resources.displayMetrics.density.
    return min(4, max(.75, int(values[0]) / 160))


def capture_cards_faces(out: Path, box: CardsMailbox, tag: str, identity: dict,
                        density: float, *, timeout=60) -> tuple[dict, dict]:
    """Wait for two actual unpaused frames of one public revision and page."""
    started = time.monotonic()
    deadline = started + timeout
    report = {'status': 'WAITING', 'stage': tag, 'frames': [],
              'scope': 'Current projected card fronts, observed UI and stable IPC; no pixel card-identity claim'}
    previous = None
    expected = tuple(identity.get(key) for key in ('token', 'roundId', 'viewer'))

    def observe():
        state = box.read()
        if tuple(state.get(key) for key in ('token', 'roundId', 'viewer')) != expected:
            raise RuntimeError('Cards identity changed during front-face pixel evidence')
        return state

    try:
        while time.monotonic() < deadline:
            before = observe()
            if (before.get('paused') is not False or before.get('canDraw') is not True or
                    before.get('phase') != 'playing' or before.get('current') != 0):
                previous = None
                time.sleep(min(.5, max(0, deadline - time.monotonic())))
                continue
            name = f'{tag}-face-check-{len(report["frames"]):02d}'
            shot = probe.capture(out, name, timeout=deadline - time.monotonic())
            source = out / shot['file']
            frame = {'source': source.name, 'source_sha256': probe.digest(source),
                     'revision': before.get('revision'), 'public_before': before, 'status': 'CHECKING'}
            report['frames'].append(frame)
            try:
                surface = probe.inspect_surface(source, orientation='responsive')
                if not surface['acceptable_for_target_sampling']:
                    raise RuntimeError('Cards viewport is not complete')
                width, height = surface['pixels']
                geometry = cards_projected_faces(width, height, density, len(before.get('hand', [])))
                lines = probe.image_lines(out, name, probe.normalized('Pause'), source_path=source,
                                          exact=True, timeout=max(.001, deadline - time.monotonic()))
                pauses = [line for line in lines if line.get('text', '').strip() == 'Pause']
                if not pauses:
                    raise RuntimeError('Current Cards frame still has a paused/modal transition')
                pages = [line for line in lines if ''.join(line.get('text', '').split()) == geometry['page']]
                if not pages:
                    lines = probe.image_lines(out, name + '-page', probe.normalized(geometry['page']),
                                              source_path=source, exact=True,
                                              timeout=max(.001, deadline - time.monotonic()))
                    pages = [line for line in lines if ''.join(line.get('text', '').split()) == geometry['page']]
                if not pages:
                    raise RuntimeError('Current Cards frame does not expose its expected first hand page')
                observations = {'source_sha256': frame['source_sha256'],
                                'pause': min(pauses, key=lambda line: line['bounds'][1]),
                                'page': max(pages, key=lambda line: line['bounds'][1])}
                after = observe()
                frame['public_after'] = after
                if before != after:
                    raise RuntimeError('Cards public state changed while its current frame was inspected')
                pixels = require_cards_face_pixels(source, after, density=density, observations=observations)
                frame.update(status='VISIBLE_FRONT_ARTWORK', observations=observations, pixels=pixels)
                if previous == after:
                    # Keep the original captured bytes; this is not an edited
                    # screenshot or an image synthesized from the saved state.
                    (out / (tag + '.png')).write_bytes(source.read_bytes())
                    report.update(status='PASS', consecutive_same_revision_frames=2,
                                  revision=after['revision'], page=geometry['page'],
                                  token=after['token'], roundId=after['roundId'], viewer=after['viewer'],
                                  source=tag + '.png', source_sha256=frame['source_sha256'])
                    return after, report
                previous = after
            except (RuntimeError, TimeoutError) as error:
                frame.update(status='REJECTED', error=str(error))
                previous = None
            time.sleep(min(.5, max(0, deadline - time.monotonic())))
        raise RuntimeError('Cards front faces did not pass current unpaused pixel/UI evidence before deadline')
    except Exception as error:
        report.update(status='FAIL', error=str(error))
        raise
    finally:
        report['elapsed_seconds'] = round(time.monotonic() - started, 6)
        (out / (tag + '-face-evidence.json')).write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')


def cards_roundtrip(out: Path) -> dict:
    tap_flutter(out, ['Spielen', 'Spiele'], 'cards-games-tab')
    tap_flutter(out, ['Lumo Cards. Sammeln. Spielen. Staunen! Spielen', 'Lumo Cards',
                      'Lumo Cards · Klassik'], 'cards-portal')
    tap_flutter(out, ['Solo spielen'], 'cards-solo')
    must_see(out, 'Lumo Cards', 'cards-flutter')
    probe.capture_flutter_ready(out, '10_cards_flutter_round')
    before_prefs = probe.prefs(out, 'cards-before-native')
    tap_flutter(out, ['Am 3D-Tisch spielen', '3D'], 'cards-native-entry')
    native_ready(out, 'Lumos Kartenstube', 'cards-native-title')
    density = cards_display_density(out)
    box = CardsMailbox(out)
    wait_for('Private Cards IPC session created by app', box.locate, bool)
    before, initial_readiness = cards_ready_to_draw(out, box)
    before, faces_before = capture_cards_faces(out, box, '11_cards_real_table_before_draw', before, density)
    before_save = box.saved(before['roundId'])
    require_public_saved_match(before, before_save)
    probe.native_text(out, 'Ziehen', 'cards-native-draw', tap=True, exact=True, settle=True,
                      orientation='responsive')
    request = box.read('request')
    if request.get('action') != 'draw':
        raise RuntimeError('Actual native Ziehen did not publish a draw request')
    after = wait_for('Dart acknowledged native draw and the bot finished its turn', box.read,
                     lambda state: state.get('ack', -1) >= request.get('sequence', 10**10)
                     and state.get('canDraw') is True and state.get('paused') is False)
    after, faces_after = capture_cards_faces(out, box, '12_cards_real_table_persisted_draw', after, density)
    saved = box.saved(after['roundId'])
    draw = require_cards_draw(before, request, after, saved, owner=before_save['owner'])
    # Android must see the dependency on the Dart host while its native child
    # activity is visible. Archive OS importance data rather than inferring it
    # from a successful first turn immediately after the activity launch.
    bindings = []
    started = time.monotonic()
    for stage in ('before-idle', 'after-idle'):
        if stage == 'after-idle':
            deadline = started + 35
            while time.monotonic() < deadline:
                if 'LumoGameActivity' not in resumed_activity() or not tour.alive():
                    raise RuntimeError('Cards authority or native table disappeared during visible idle')
                time.sleep(min(1, max(0, deadline - time.monotonic())))
        services = base.adb('shell', 'dumpsys', 'activity', 'services', PACKAGE, timeout=60)
        processes = base.adb('shell', 'dumpsys', 'activity', 'processes', PACKAGE, timeout=60)
        (out / f'cards-authority-services-{stage}.txt').write_text(services)
        (out / f'cards-authority-processes-{stage}.txt').write_text(processes)
        bindings.append(require_cards_authority_binding(services, PACKAGE))
    if bindings[0] != bindings[1]:
        raise RuntimeError('Cards authority processes restarted during the visible table session')
    idle_seconds = time.monotonic() - started
    before_late = box.read()
    before_late, faces_before_late = capture_cards_faces(
        out, box, '12a_cards_real_table_before_late_draw', before_late, density)
    before_late_save = box.saved(before_late['roundId'])
    require_public_saved_match(before_late, before_late_save)
    if before_late_save != saved:
        raise RuntimeError('The idle child turn mutated its persisted Cards round')
    probe.native_text(out, 'Ziehen', 'cards-native-late-draw', tap=True, exact=True, settle=True,
                      orientation='responsive')
    late_request = box.read('request')
    after = wait_for('Dart acknowledged the actual draw after visible idle', box.read,
                    lambda state: state.get('ack', -1) >= late_request.get('sequence', 10**10)
                    and state.get('canDraw') is True and state.get('paused') is False)
    after, faces_after_late = capture_cards_faces(
        out, box, '12b_cards_persisted_draw_after_visible_idle', after, density)
    late_draw = require_cards_draw(before_late, late_request, after,
                                   box.saved(after['roundId']), owner=before_save['owner'])
    probe.native_text(out, 'Pause', 'cards-native-pause', tap=True, exact=True, settle=True,
                      orientation='responsive')
    paused = wait_for('Cards clock actually paused', box.read,
                      lambda state: state.get('paused') is True)
    paused_save = box.saved(paused['roundId'])
    time.sleep(2)
    still = box.read()
    if still.get('paused') is not True or box.saved(still['roundId']) != paused_save:
        raise RuntimeError('Persisted Cards round changed while native pause was shown')
    probe.capture(out, '13_cards_native_pause')
    probe.native_text(out, 'Zurück', 'cards-native-back', tap=True, exact=True, settle=True,
                      orientation='responsive')
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
    native_ready(out, 'Lumos Kartenstube', 'cards-reopened-title')
    reopened = CardsMailbox(out)
    wait_for('Reopened actual Cards IPC', reopened.locate, bool)
    state = reopened.read()
    if state.get('roundId') != after['roundId'] or reopened.token == box.token:
        raise RuntimeError('Cards reopen reused a mailbox or lost the same persisted round')
    if reopened.saved(state['roundId']) != restored:
        raise RuntimeError('Reopened Cards table changed the saved round before any action')
    probe.capture(out, '15_cards_reopened_same_round')
    probe.native_text(out, 'Zurück', 'cards-reopened-back', tap=True, exact=True, settle=True,
                      orientation='responsive')
    returned_to_flutter(out, 'Spiel pausiert', '16_cards_final_flutter_return')
    return {'initial_readiness': initial_readiness,
            'front_face_pixels': [faces_before, faces_after, faces_before_late, faces_after_late],
            'draw': draw, 'draw_after_visible_idle': late_draw,
            'visible_idle_seconds': idle_seconds,
            'android_authority_binding': bindings,
            'pause_saved_state_unchanged': True,
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
        if identity['versionCode'] != 2019:
            raise RuntimeError('Studio surface acceptance requires versionCode 2019')
        result['emulator_root_readiness'] = probe.ensure_rooted_emulator(base.adb, out)
        base.display(1080, 2400, 420)
        if not tour.alive() or tour.godot_alive():
            raise RuntimeError('Expected the original tour to leave the installed Flutter app alive')
        base.adb('shell', 'svc', 'wifi', 'disable')
        base.adb('shell', 'svc', 'data', 'disable')
        base.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        if base.adb('shell', 'settings', 'get', 'global', 'airplane_mode_on').strip() != '1':
            raise RuntimeError('The new offline native-surface probe could not enable airplane mode')
        result['offline'] = True
        result['local_voice_permission'] = local_voice_permission(out)
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
