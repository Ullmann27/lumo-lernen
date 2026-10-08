#!/usr/bin/env python3
"""Complete a genuine offline Android Kart race and recover its finished result.

Run after creative_android_probe.py in the same disposable emulator. The existing
LumoTest profile is retained. Only actual Android UI/input operates the game:
fresh garage setup, the public automatic-gas option, pause, resume and return.
Unmodified beginner steering/rail assistance drives Sonnenhafen with a neutral
stick. This is lifecycle evidence, not a steering-quality or device-FPS test.

Application saves/events/preferences are READ ONLY. No score, position, finish,
unlock, result, acknowledgement or reward is injected. Full completion needs an
observed first lap, an in-progress second lap, 16 real checkpoints, native result,
host event, exact wallet change and a deduplicated completed-result replay.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import threading
import time
import traceback


def load_creative():
    path = Path(__file__).with_name('creative_android_probe.py')
    spec = importlib.util.spec_from_file_location('lumo_creative_android', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


SCALAR_FIELDS = {
    'version', 'result_id', 'distance', 'checkpoint_index', 'lane', 'speed',
    'countdown', 'elapsed', 'difficulty', 'mode', 'track_id', 'selected_driver',
    'selected_kart', 'finished', 'completed_race', 'reset_count',
    'player_heading', 'previous_road_distance',
}


def parse_session(raw: str) -> dict:
    """Read a Godot ConfigFile without eval or parsing its unrelated Variant data."""
    if not re.search(r'^\[race\]\s*$', raw, re.M):
        raise RuntimeError('Read-only save has no race section')
    race = re.split(r'^\[race\]\s*$', raw, flags=re.M)[1]
    race = re.split(r'^\[', race, maxsplit=1, flags=re.M)[0]
    result = {}
    for key in SCALAR_FIELDS:
        matches = re.findall(r'^' + re.escape(key) + r'=(.*)$', race, re.M)
        if len(matches) != 1:
            raise RuntimeError('Race save needs one field: ' + key)
        try:
            result[key] = json.loads(matches[0])
        except json.JSONDecodeError as error:
            raise RuntimeError('Invalid scalar in race save: ' + key) from error
    for key in ('distance', 'lane', 'speed', 'countdown', 'elapsed',
                'player_heading', 'previous_road_distance'):
        value = result[key]
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
            raise RuntimeError('Non-finite race field: ' + key)
    for key in ('version', 'checkpoint_index', 'reset_count'):
        if type(result[key]) is not int:
            raise RuntimeError('Non-integer race field: ' + key)
    for key in ('finished', 'completed_race'):
        if type(result[key]) is not bool:
            raise RuntimeError('Non-boolean race field: ' + key)
    if not isinstance(result['result_id'], str) or not result['result_id']:
        raise RuntimeError('Race result identity missing')
    payloads = list(re.finditer(r'^result_payload=', race, re.M))
    if len(payloads) != 1:
        raise RuntimeError('Race save needs one result payload')
    try:
        payload, _ = json.JSONDecoder().raw_decode(race[payloads[0].end():])
    except json.JSONDecodeError as error:
        raise RuntimeError('Race result payload is not a JSON-compatible dictionary') from error
    if not isinstance(payload, dict):
        raise RuntimeError('Race result payload is not a dictionary')
    result['result_payload'] = payload
    return result


def require_race_identity(state: dict, result_id: str) -> None:
    expected = {'result_id': result_id, 'mode': 'race', 'track_id': 'sonnenhafen',
                'selected_driver': 'fox', 'selected_kart': 'comet', 'difficulty': 'gemuetlich'}
    if any(state.get(key) != value for key, value in expected.items()):
        raise RuntimeError('The observed save belongs to a different race/setup')
    if not 0 <= state['checkpoint_index'] <= 16 or state['distance'] < 0 or state['elapsed'] < 0:
        raise RuntimeError('Race progress outside the physical two-lap range')


def fresh_race_ready(state: dict, previous_id: str) -> bool:
    """A preexisting or still-counting save cannot identify the newly started race."""
    if not isinstance(previous_id, str) or not previous_id:
        raise RuntimeError('Prior actual race identity is required before starting')
    if state['result_id'] == previous_id:
        return False
    require_race_identity(state, state['result_id'])
    if (state['checkpoint_index'] != 0 or state['finished'] or state['completed_race']
            or state['result_payload']):
        raise RuntimeError('Fresh physical race already advanced or finished before initial setup')
    if state['countdown'] < 0:
        raise RuntimeError('Fresh physical race has an invalid countdown')
    return state['countdown'] == 0 and state['elapsed'] >= 1


def wait_fresh_race(read_session, previous_id: str, record, *, timeout: float = 180,
                    clock=time.monotonic, sleep=time.sleep) -> dict:
    """Poll untouched runtime saves; two ready reads must retain one new identity."""
    started = clock()
    deadline = started + timeout
    evidence = {'status': 'WAITING', 'previous_result_id': previous_id,
                'timeout_seconds': timeout, 'observations': [],
                'scope': 'read-only actual saved identity/countdown; no forced race state'}
    candidate_id, ready_reads = None, 0
    try:
        if timeout <= 0 or not isinstance(previous_id, str) or not previous_id:
            raise ValueError('A prior race identity and positive readiness deadline are required')
        index = 0
        while True:
            remaining = deadline - clock()
            if remaining <= 0:
                raise TimeoutError('Fresh physical race did not become ready before its deadline')
            tag = '02-race-readiness-%03d' % index
            state = read_session(tag, timeout=min(10, remaining))
            if state['result_id'] != previous_id:
                if candidate_id is not None and candidate_id != state['result_id']:
                    raise RuntimeError('Fresh race identity changed again while awaiting readiness')
                candidate_id = state['result_id']
            elif candidate_id is not None:
                raise RuntimeError('Fresh race reverted to the prior saved identity')
            ready = fresh_race_ready(state, previous_id)
            ready_reads = ready_reads + 1 if ready else 0
            evidence['observations'].append({'snapshot': tag + '-session.cfg', 'state': state,
                                             'ready': ready, 'consecutive_ready_reads': ready_reads,
                                             'wall_seconds': round(clock() - started, 6)})
            record(evidence)
            remaining = deadline - clock()
            if remaining <= 0:
                raise TimeoutError('Fresh physical race did not become ready before its deadline')
            if ready_reads >= 2:
                evidence.update(status='READY', fresh_result_id=candidate_id)
                return state
            sleep(min(2, remaining))
            index += 1
    except Exception as error:
        evidence.update(status='FAIL', error=str(error))
        raise
    finally:
        evidence['elapsed_seconds'] = round(clock() - started, 6)
        record(evidence)


def require_completion(trace: list[dict], final: dict, result_id: str) -> dict:
    if len(trace) < 3 or not any(0 < row['checkpoint_index'] < 8 and not row['finished'] for row in trace):
        raise RuntimeError('A genuinely advancing first lap was not observed')
    if not any(8 <= row['checkpoint_index'] < 16 and not row['finished'] for row in trace):
        raise RuntimeError('A genuinely advancing second lap was not observed')
    for row in trace:
        require_race_identity(row, result_id)
    if not final['finished'] or not final['completed_race'] or final['checkpoint_index'] != 16:
        raise RuntimeError('Two laps and all 16 checkpoints were not completed')
    payload = final['result_payload']
    expected = {'resultId': result_id, 'status': 'completed', 'game': 'kart',
                'mode': 'race', 'track': 'sonnenhafen', 'driver': 'fox', 'kart': 'comet',
                'checkpoints': 16, 'solved': 0, 'stars': 3}
    if any(payload.get(key) != value for key, value in expected.items()):
        raise RuntimeError('Native completed result does not match the observed race')
    if type(payload.get('place')) is not int or not 1 <= payload['place'] <= 6:
        raise RuntimeError('Native result lacks an actual valid race place')
    if final['elapsed'] <= 10 or final['distance'] <= trace[0]['distance']:
        raise RuntimeError('Physical elapsed time/distance did not advance')
    return payload


def require_reward(before: dict, after: dict, payload: dict) -> None:
    result_id = payload['resultId']
    before_ids, after_ids = before.get('gameResultIds', []), after.get('gameResultIds', [])
    if result_id in before_ids or after_ids.count(result_id) != 1:
        raise RuntimeError('Completed race ID was missing, old or duplicated in the wallet')
    expected_xp = payload.get('xp', payload['solved'] * 10)
    for key, change in (('stars', payload['stars']), ('totalEarnedStars', payload['stars']), ('xp', expected_xp)):
        if after.get(key, 0) - before.get(key, 0) != change:
            raise RuntimeError('Completed race wallet delta is wrong: ' + key)
    if set(after_ids) - set(before_ids) != {result_id}:
        raise RuntimeError('An unrelated result entered the wallet during the isolated race')


def require_event(events: dict, payload: dict) -> None:
    rows = [row for row in events.get('results', []) if row.get('resultId') == payload['resultId']]
    if len(rows) != 1 or rows[0] != payload:
        raise RuntimeError('Host did not durably retain exactly this native finish result')


def require_ack(events: dict, result_id: str) -> None:
    if any(row.get('resultId') == result_id for row in events.get('results', [])):
        raise RuntimeError('Host completed event was not acknowledged after wallet persistence')


def scroll_observation(lines: list[dict], direction: str, context: str) -> dict:
    """Locate visible scroll content, excluding the paused HUD and pinned footer."""
    def norm(text):
        import unicodedata
        plain = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode()
        return re.sub('[^a-z0-9]', '', plain.lower())
    pause = ('einekleinepause', 'deinrennenwartet', 'weiterfahren', 'ruhigebewegung',
             'tonan', 'tonaus', 'grafik', 'tempo', 'gasautomatisch', 'gasgastastehalten',
             'musik', 'effekte', 'neuefahrtauswahlen',
             'rennenabbrechen')
    finished = ('gesamtzeit', 'besterunde', 'sternegesammelt', 'belohnung',
                'nocheinmalfahren', 'neuefahrtauswahlen', 'zurspieleauswahl', 'zumlernen')
    if context not in ('pause', 'finished'):
        raise ValueError('Scroll context must be pause or finished')
    if direction not in ('down', 'up'):
        raise ValueError('Scroll direction must be up or down')
    prefixes = pause if context == 'pause' else finished
    observed = []
    for row in lines:
        caption = norm(row['text'])
        if not (any(caption.startswith(prefix) for prefix in prefixes)
                or caption in ('zurspieleauswahl', 'zumlernen')):
            continue
        bounds = row.get('bounds', [])
        if (not isinstance(bounds, (list, tuple)) or len(bounds) != 4 or any(isinstance(value, bool)
                or not isinstance(value, (int, float)) or not math.isfinite(value)
                for value in bounds) or not 0 <= bounds[0] < bounds[2]
                or not 0 <= bounds[1] < bounds[3]):
            raise RuntimeError('Invalid observed modal caption bounds')
        # OCR variants may describe the same caption with subpixel differences.
        if any(old['caption'] == caption and max(abs(a-b) for a, b in zip(
                bounds, old['bounds'])) <= 4 for old in observed):
            continue
        observed.append({'caption': caption, 'bounds': list(bounds)})
    rows = [row for row in observed
            if any(row['caption'].startswith(prefix) for prefix in prefixes)]
    footer = []
    if context == 'pause':
        # Source: PauseNavigation is outside modal_scroll and remains visible
        # while the settings scroll. Its two actual captions bound the content.
        for caption in ('zurspieleauswahl', 'zumlernen'):
            matches = [row for row in observed if row['caption'] == caption]
            if len(matches) != 1:
                raise RuntimeError('No observed central modal captions: missing or ambiguous pause footer')
            footer.append(matches[0]['bounds'])
        left, right = footer
        if (left[2] >= right[0] or max(left[1], right[1]) >= min(left[3], right[3])):
            raise RuntimeError('Observed pause footer does not form one ordered navigation row')
        left_x, right_x = (left[0]+left[2])/2, (right[0]+right[2])/2
        footer_top = min(left[1], right[1])
        rows = [row for row in rows if left_x < (row['bounds'][0]+row['bounds'][2])/2 < right_x
                and row['bounds'][3] < footer_top]
    if len(rows) < 2:
        raise RuntimeError('No observed central modal captions provide a safe scrolling gesture')
    top = min(rows, key=lambda row: row['bounds'][1])
    bottom = max(rows, key=lambda row: row['bounds'][3])
    top_y = round((top['bounds'][1] + top['bounds'][3]) / 2)
    bottom_y = round((bottom['bounds'][1] + bottom['bounds'][3]) / 2)
    if bottom_y - top_y < 60:
        raise RuntimeError('Observed modal captions provide too little room to scroll')
    x = round((bottom['bounds'][0] + bottom['bounds'][2]) / 2)
    gesture = [x, bottom_y, x, top_y] if direction == 'down' else [x, top_y, x, bottom_y]
    return {'gesture': gesture, 'context': context, 'direction': direction,
            'content_bounds': [min(row['bounds'][0] for row in rows),
                               min(row['bounds'][1] for row in rows),
                               max(row['bounds'][2] for row in rows),
                               max(row['bounds'][3] for row in rows)],
            'footer_bounds': footer, 'selected_captions': rows}


def observed_scroll(lines: list[dict], direction: str, context: str) -> list[int]:
    return scroll_observation(lines, direction, context)['gesture']


def stable_scroll_observation(frame: dict, observation: dict, previous: dict | None = None) -> dict:
    """A swipe requires two complete current frames with matching modal geometry."""
    result = {'frame': frame, 'observation': observation, 'valid': False, 'stable': False}
    if not frame.get('acceptable_for_target_sampling'):
        return result
    width, height = frame['pixels']
    for bounds in [observation['content_bounds'], *observation['footer_bounds']]:
        if not 0 <= bounds[0] < bounds[2] <= width or not 0 <= bounds[1] < bounds[3] <= height:
            raise RuntimeError('Observed scroll geometry exceeds the current screenshot')
    x0, y0, x1, y1 = observation['content_bounds']
    a, b, c, d = observation['gesture']
    if not (x0 <= a <= x1 and x0 <= c <= x1 and y0 <= b <= y1 and y0 <= d <= y1):
        raise RuntimeError('Observed swipe leaves the visible modal content')
    result['valid'] = True
    if previous and previous['valid'] and previous['frame']['pixels'] == frame['pixels']:
        old = previous['observation']
        geometry = lambda value: [*value['gesture'], *value['content_bounds'],
                                  *(coordinate for bounds in value['footer_bounds'] for coordinate in bounds)]
        before, after = geometry(old), geometry(observation)
        result['stable'] = (old['context'] == observation['context'] and old['direction'] == observation['direction']
                            and len(before) == len(after)
                            and max(abs(a-b) for a, b in zip(before, after)) <= 12)
    return result


def require_no_runtime_error(logcat: str) -> None:
    errors = [line for line in logcat.splitlines()
              if re.search(r'\b(?:godot|Godot)\b', line) and
              re.search(r'(?:SCRIPT ERROR|USER ERROR|ERROR:|Parse Error|Assertion failed)', line)]
    if errors:
        raise RuntimeError('Actual native runtime logged an error:\n' + '\n'.join(errors[:10]))


def require_saved_progress_unchanged(before: dict, after: dict, context: str) -> None:
    """A resize must not change the actual paused or completed persisted race."""
    keys = ('result_id', 'distance', 'elapsed', 'checkpoint_index', 'finished',
            'completed_race', 'mode', 'track_id', 'selected_driver', 'selected_kart',
            'difficulty', 'result_payload')
    changed = [key for key in keys if before.get(key) != after.get(key)]
    if changed:
        raise RuntimeError(f'{context} resize changed saved race state: ' + ', '.join(changed))


class VideoRecorder:
    """Segmented raw Android screenrecord; never replace footage with a render."""
    def __init__(self, out: Path, adb):
        self.out, self.adb = out, adb
        self.stop_event = threading.Event()
        self.records, self.errors = [], []
        self.thread = threading.Thread(target=self._run, name='real-android-screenrecord', daemon=True)

    def start(self):
        if self.adb('shell', 'pidof', 'screenrecord', check=False).strip():
            raise RuntimeError('Another screenrecord owns this disposable emulator')
        self.thread.start()

    def _run(self):
        index = 0
        while not self.stop_event.is_set():
            remote = '/sdcard/lumo-full-race-%03d.mp4' % index
            local = self.out / ('android-race-%03d.mp4' % index)
            process = subprocess.Popen(['adb', 'shell', 'screenrecord', '--size', '960x540',
                                        '--bit-rate', '2000000', '--time-limit', '180', remote],
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            started = time.monotonic()
            try:
                while process.poll() is None and not self.stop_event.wait(1):
                    if time.monotonic() - started > 200:
                        raise RuntimeError('Android screenrecord exceeded its segment deadline')
                if process.poll() is None:
                    pids = self.adb('shell', 'pidof', 'screenrecord', check=False).split()
                    if len(pids) != 1 or not pids[0].isdigit():
                        raise RuntimeError('Cannot safely identify the owned screenrecord process')
                    self.adb('shell', 'kill', '-2', pids[0])
                output, _ = process.communicate(timeout=20)
                (self.out / ('android-race-%03d-screenrecord.txt' % index)).write_bytes(output)
                self.adb('pull', remote, str(local), timeout=90)
                if local.stat().st_size < 1024:
                    raise RuntimeError('Android screenrecord produced no usable footage')
                self.records.append({'file': local.name, 'bytes': local.stat().st_size,
                                     'sha256': hashlib.sha256(local.read_bytes()).hexdigest(),
                                     'wall_seconds': round(time.monotonic() - started, 2),
                                     'screenrecord_size': [960, 540], 'exit_code': process.returncode,
                                     'scope': 'actual emulator display; no FPS or native-resolution claim'})
            except Exception as error:
                self.errors.append(str(error))
                if process.poll() is None:
                    process.terminate()
                break
            index += 1

    def stop(self) -> dict:
        self.stop_event.set()
        self.thread.join(timeout=115)
        if self.thread.is_alive():
            self.errors.append('Screenrecord collector did not stop within its deadline')
        return {'segments': self.records, 'errors': self.errors,
                'status': 'PASS' if self.records and not self.errors else 'NOT_EXECUTED_OR_FAILED'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--timeout', type=int, default=1200)
    args = parser.parse_args()
    if not 180 <= args.timeout <= 2400:
        parser.error('--timeout must be from 180 to 2400 seconds')
    args.out.mkdir(parents=True, exist_ok=True)
    out = args.out
    result = {'status': 'RUNNING', 'scope': 'actual offline Android two-lap race and finished-result recovery',
              'driver': 'actual public automatic-gas setting; neutral stick; existing beginner/rail assistance',
              'not_tested': ['physical Samsung/Fold hinge', 'CPU/GPU frame-time or 60 FPS',
                             'steering quality', 'network/provider failure', 'host storage-failure injection',
                             'visual reference parity', 'all tracks/karts']}
    video = None
    creative = load_creative()
    base, package = creative.base, creative.PACKAGE
    original_adb = base.adb

    def logged_adb(*commands, **kwargs):
        started = time.monotonic()
        try:
            return original_adb(*commands, **kwargs)
        finally:
            with (out / 'android-actions.jsonl').open('a') as stream:
                stream.write(json.dumps({'arguments': list(commands),
                                         'wall_seconds': round(time.monotonic() - started, 3)}) + '\n')

    base.adb = logged_adb

    def deadline(_signal, _frame):
        raise TimeoutError('Full-race Android probe reached its hard wall-clock deadline')

    previous_alarm = signal.signal(signal.SIGALRM, deadline)
    signal.alarm(args.timeout)

    def write_json(name: str, value):
        (out / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')

    session_path = None

    def session(tag: str, *, timeout: float = 60) -> dict:
        nonlocal session_path
        if session_path is None:
            paths = base.adb('shell', 'find', f'/data/user/0/{package}', '-maxdepth', '12',
                             '-type', 'f', '-name', 'kart_sonnenhafen_session.cfg').splitlines()
            if len(paths) != 1:
                raise RuntimeError('One actual persisted Kart session was required')
            session_path = paths[0]
        raw = base.adb('exec-out', 'cat', session_path, timeout=timeout)
        (out / (tag + '-session.cfg')).write_text(raw)
        return parse_session(raw)

    def events(tag: str) -> dict:
        raw = base.adb('exec-out', 'cat', f'/data/user/0/{package}/files/lumo_game_events.json')
        data = json.loads(raw)
        write_json(tag + '-host-events.json', data)
        return data

    def tap_native(label: str, tag: str, *, scroll: str | None = None, context: str = 'pause') -> None:
        wanted = creative.normalized(label)
        deadline, previous_scroll = time.monotonic() + 180, None
        for attempt in range(10):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('Observed native action preparation exceeded 180 seconds')
            capture = creative.capture(out, f'{tag}-{attempt}', timeout=remaining)
            source = out / capture['file']
            frame = creative.inspect_surface(source)
            if not frame['acceptable_for_target_sampling']:
                previous_scroll = None
                write_json(f'{tag}-{attempt}-observed-scroll.json', {'status': 'SURFACE_REJECTED', 'frame': frame})
                continue
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('Observed native action preparation exceeded 180 seconds')
            lines = creative.image_lines(out, f'{tag}-{attempt}', wanted, exact=True,
                                         source_path=source, timeout=remaining)
            matches = [row for row in lines if creative.normalized(row['text']) == wanted]
            if matches:
                # The final action also needs the shared current-full-surface
                # and two-frame target gate, with this exact caption retained.
                creative.native_text(out, label, tag + '-stable-action', tap=True, exact=True)
                return
            if scroll and attempt >= 1:
                observation = scroll_observation(lines, scroll, context)
                current = stable_scroll_observation(frame, observation, previous_scroll)
                evidence = {
                    'target': label, 'direction': scroll, 'observed_captions': lines,
                    'gesture': observation['gesture'], 'current': current,
                    'previous': previous_scroll, 'status': 'WAITING_FOR_STABLE_MODAL',
                    'scope': 'two complete current frames; gesture inside observed modal captions',
                }
                previous_scroll = current
                if not current['stable']:
                    write_json(f'{tag}-{attempt}-observed-scroll.json', evidence)
                    continue
                if creative.digest(source) != frame['source_sha256']:
                    raise RuntimeError('The observed scroll screenshot changed before input')
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError('Observed native action preparation exceeded 180 seconds')
                base.adb('shell', 'input', 'swipe', *map(str, observation['gesture']), '450',
                         timeout=min(10, remaining))
                evidence['status'] = 'SWIPE_SENT'
                write_json(f'{tag}-{attempt}-observed-scroll.json', evidence)
                previous_scroll = None
                time.sleep(1.5)
                continue
            time.sleep(1)
        raise RuntimeError('Exact current native action caption is missing: ' + label)

    def restarted_home(tag: str):
        base.adb('shell', 'am', 'force-stop', package)
        creative.device_rotation(out, tag + '-upright', 0)
        base.display(1080, 2400, 480)
        base.launch(out, tag)
        current = creative.prefs(out, tag).get('flutter.lumo_active_profile')
        if current != profile:
            raise RuntimeError('Actual profile changed during offline race recovery')
        creative.capture(out, tag + '-home')

    def open_kart(tag: str):
        creative.flutter_tap(out, 'Spielen', tag + '-games')
        base.display(1080, 1920, 300)
        creative.enter(out, 'Lumo Kart', 'LUMO / KART', tag, launch_label='Losfahren')

    def fold_cycle(tag: str, labels: tuple[str, ...], saved_before: dict | None = None) -> dict:
        """Observed outer→inner→outer emulator surfaces, then the normal phone."""
        captures = []
        for stage, width, height, density, expected in (
            ('outer-before', 904, 2316, 420, [2316, 904]),
            ('inner', 1812, 2176, 420, [2176, 1812]),
            ('outer-after', 904, 2316, 420, [2316, 904]),
            ('phone-restored', 1080, 1920, 300, [1920, 1080]),
        ):
            base.display(width, height, density)
            creative.device_rotation(out, tag + '-' + stage + '-landscape', 1)
            for label in labels:
                creative.native_text(out, label, tag + '-' + stage + '-' + creative.normalized(label))
            snapshot = creative.capture(out, tag + '-' + stage)
            if [snapshot['width'], snapshot['height']] != expected:
                raise RuntimeError(f'{tag}/{stage} did not render the expected actual emulator surface')
            captures.append({'stage': stage, 'surface': expected, 'capture': snapshot})
            if saved_before is not None:
                require_saved_progress_unchanged(saved_before, session(tag + '-' + stage), tag)
        return {'status': 'PASS', 'sequence': 'outer → inner → outer → phone',
                'observed_labels': list(labels), 'captures': captures,
                'saved_progress_stable': saved_before is not None,
                'scope': 'actual emulator surfaces and explicit rotation; physical Samsung/Fold hinge NOT EXECUTED'}

    try:
        expected_source = os.environ['LUMO_EXPECT_SOURCE']
        expected_godot = os.environ['LUMO_EXPECT_GODOT']
        expected_version = int(os.environ['LUMO_EXPECT_VERSION'])
        provenance = json.loads((args.candidate.parent / 'BUILD-PROVENANCE.json').read_text())
        candidate_digest = creative.digest(args.candidate)
        if (provenance['flutter_source_commit'] != expected_source or
                provenance['godot']['revision'] != expected_godot or
                provenance['versionCode'] != expected_version or provenance['sha256'] != candidate_digest or
                provenance['tracked_source_clean'] is not True or
                provenance['signingCertificateSha256'] != creative.CERT):
            raise RuntimeError('Exact candidate provenance mismatch')
        result.update(source=expected_source, godot=expected_godot, apk_sha256=candidate_digest,
                      harness=base.command('git', 'rev-parse', 'HEAD'))
        from emulator_handoff import ensure_emulator_handoff
        previous = json.loads((out.parent / 'result.json').read_text())
        result['emulator_handoff'] = ensure_emulator_handoff(base.adb, out, previous, {
            'source': expected_source, 'godot': expected_godot,
            'apk_sha256': candidate_digest,
            'android_sdk': int(os.environ['LUMO_EXPECT_ANDROID_API']),
        })
        serial = result['emulator_handoff']['serial']
        result['serial'] = serial
        os.environ['ANDROID_SERIAL'] = serial
        apk_paths = base.adb('shell', 'pm', 'path', package).splitlines()
        apk_bases = [row.removeprefix('package:') for row in apk_paths if row.endswith('/base.apk')]
        if len(apk_bases) != 1:
            raise RuntimeError('One currently installed candidate base.apk required')
        installed = base.adb('shell', 'toybox', 'sha256sum', apk_bases[0], timeout=180).split()[0]
        installed_size = int(base.adb('shell', 'toybox', 'stat', '-c', '%s', apk_bases[0]))
        if installed != candidate_digest or installed_size != args.candidate.stat().st_size:
            raise RuntimeError('Installed bytes differ from the exact candidate APK')
        result['installed_apk'] = {'sha256': installed, 'bytes': installed_size, 'matches_candidate': True}
        result['emulator_root_readiness'] = creative.ensure_rooted_emulator(base.adb, out)
        result['android_sdk'] = int(base.adb('shell', 'getprop', 'ro.build.version.sdk'))
        expected_sdk = os.environ.get('LUMO_EXPECT_ANDROID_API')
        if expected_sdk and result['android_sdk'] != int(expected_sdk):
            raise RuntimeError('Android API differs from the requested probe')
        base.adb('shell', 'svc', 'wifi', 'disable')
        base.adb('shell', 'svc', 'data', 'disable')
        base.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        if base.adb('shell', 'settings', 'get', 'global', 'airplane_mode_on') != '1':
            raise RuntimeError('Actual offline mode not confirmed')
        profile = creative.prefs(out, 'initial').get('flutter.lumo_active_profile')
        if not profile or 'LumoTest' not in profile:
            raise RuntimeError('Existing real LumoTest profile from creative probe is required')
        before_wallet = creative.wallet(out, 'before-race')
        previous_race = session('00-prior-race-before-garage')
        result['previous_result_id'] = previous_race['result_id']
        base.adb('logcat', '-c')
        base.launch(out, 'full-race-start')
        open_kart('01-garage')
        if os.environ.get('LUMO_FOLD_PROBE') == '1':
            result['menu_resize'] = fold_cycle('01-garage-resize', ('LUMO / KART', 'Dein nächstes Abenteuer', 'Weiter'))
            result['menu_resize']['preserved_garage_step'] = 'Dein nächstes Abenteuer (step 1 / 5)'
        for step in range(4):
            tap_native('Weiter', f'garage-next-{step + 1}')
        tap_native('Rennen starten', 'garage-start')
        ready = wait_fresh_race(session, previous_race['result_id'],
                               lambda evidence: write_json('fresh-race-readiness.json', evidence))
        result['fresh_race_readiness'] = json.loads((out / 'fresh-race-readiness.json').read_text())
        creative.native_text(out, 'RUNDE', '02-fresh-race-hud')
        chase = creative.capture(out, '02-fresh-race-phone')
        if [chase['width'], chase['height']] != [1920, 1080]:
            raise RuntimeError('Fresh chase HUD did not use the actual phone surface')
        initial = session('02-new-race')
        result_id = initial['result_id']
        require_race_identity(initial, result_id)
        if result_id != ready['result_id'] or not fresh_race_ready(initial, previous_race['result_id']):
            raise RuntimeError('The public garage setup did not start a fresh race')
        result['result_id'] = result_id
        base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        creative.native_text(out, 'Eine kleine Pause', 'initial-pause')
        paused_initial = session('02-initial-pause-fresh')
        require_race_identity(paused_initial, result_id)
        if not fresh_race_ready(paused_initial, previous_race['result_id']):
            raise RuntimeError('Initial pause changed the fresh race readiness')
        tap_native('Gas: GAS-Taste halten', 'enable-public-auto-gas', scroll='down')
        creative.native_text(out, 'Gas: automatisch', 'public-auto-gas-confirmed')
        result['automatic_gas'] = {'enabled_by': 'observed native pause button', 'stick': 'neutral'}
        creative.capture(out, '03-automatic-gas-pause')
        video = VideoRecorder(out, base.adb)
        video.start()
        tap_native('Weiterfahren', 'race-resume-after-gas-setting', scroll='up')

        trace, paused_once = [initial], False
        race_started, last_progress = time.monotonic(), time.monotonic()
        previous = initial
        for index in range(500):
            time.sleep(5)
            if not base.adb('shell', 'pidof', package + ':lumo_game', check=False):
                raise RuntimeError('Actual native process died during the two-lap race')
            state = session('race-%03d' % index)
            require_race_identity(state, result_id)
            state['wall_seconds_since_resume'] = round(time.monotonic() - race_started, 3)
            trace.append(state)
            write_json('race-trace.json', trace)
            if state['elapsed'] > previous['elapsed'] + 0.1:
                last_progress = time.monotonic()
            elif time.monotonic() - last_progress > 180:
                raise RuntimeError('Physical race stopped advancing for 180 wall-clock seconds')
            print('[CompleteKartAndroid] checkpoints=%d elapsed=%.2f distance=%.2f finished=%s' %
                  (state['checkpoint_index'], state['elapsed'], state['distance'], state['finished']), flush=True)
            if index % 3 == 0 or state['checkpoint_index'] // 8 != previous['checkpoint_index'] // 8:
                creative.capture(out, '04-driving-%03d' % index)
            if not paused_once and 0 < state['checkpoint_index'] < 8:
                base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
                creative.native_text(out, 'Eine kleine Pause', 'mid-race-pause')
                paused = session('05-pause-start')
                creative.capture(out, '05-first-lap-pause')
                time.sleep(2)
                still = session('05-pause-still')
                if any(paused[key] != still[key] for key in ('elapsed', 'distance', 'checkpoint_index', 'result_id')):
                    raise RuntimeError('The saved race progress changed while the actual pause menu was open')
                if creative.wallet(out, 'during-unfinished-race') != before_wallet:
                    raise RuntimeError('An unfinished race credited a host reward')
                if os.environ.get('LUMO_FOLD_PROBE') == '1':
                    result['pause_resize'] = fold_cycle('05-pause-resize', ('Eine kleine Pause', 'Weiterfahren'), paused)
                    if creative.wallet(out, 'after-pause-resize') != before_wallet:
                        raise RuntimeError('Resizing an unfinished paused race credited a host reward')
                tap_native('Weiterfahren', 'mid-race-continue')
                # Resize/OCR time belongs to genuine pause overhead, not a stall
                # of the resumed race. Restart only the monitoring deadline.
                last_progress = time.monotonic()
                paused_once = True
                result['pause_resume'] = {'status': 'PASS', 'checkpoint': paused['checkpoint_index'],
                                          'saved_pause_progress_stable': True, 'unfinished_reward_unchanged': True,
                                          'scope': 'observed pause UI and read-only persisted progress; engine regression checks actual paused physics'}
            previous = state
            if state['finished']:
                final = state
                break
        else:
            raise RuntimeError('Natural two-lap race did not finish before the polling limit')
        payload = require_completion(trace, final, result_id)
        if not paused_once:
            raise RuntimeError('Actual in-progress pause/resume was not executed')
        result['native_result'] = payload
        require_event(events('06-native-finish'), payload)
        creative.native_text(out, 'Gesamtzeit', 'result-total-time')
        creative.native_text(out, 'Belohnung', 'result-reward')
        creative.capture(out, '06-completed-result-phone')
        if os.environ.get('LUMO_FOLD_PROBE') == '1':
            result['result_resize'] = fold_cycle('07-finished-result-resize', ('Gesamtzeit', 'Belohnung'), final)

        # Actual interrupted-result recovery: the untouched saved race survives
        # process death. Flutter drains/ACKs the real native result after restart.
        restarted_home('10-offline-result-recovery')
        for attempt in range(30):
            rewarded_wallet = creative.wallet(out, f'recovery-wallet-{attempt}')
            if result_id in rewarded_wallet.get('gameResultIds', []):
                require_reward(before_wallet, rewarded_wallet, payload)
                pending = events(f'recovery-ack-{attempt}')
                if not any(row.get('resultId') == result_id for row in pending.get('results', [])):
                    break
            time.sleep(1)
        else:
            raise RuntimeError('Offline recovery did not persist and acknowledge the finish reward')
        require_ack(pending, result_id)
        result['offline_result_recovery'] = {'status': 'PASS', 'reward_stars': 3,
                                             'reward_xp': payload.get('xp', 0), 'host_acknowledged': True}
        open_kart('11-reopen-completed-race')
        tap_native('Gespeichertes Rennen', 'actual-completed-race-resume')
        reopened = session('12-reopened-finished-result')
        require_race_identity(reopened, result_id)
        if not reopened['finished'] or reopened['result_payload'] != payload:
            raise RuntimeError('The actual saved completed race reopened a different result')
        creative.native_text(out, 'Gesamtzeit', 'reopened-result-total-time')
        creative.capture(out, '12-same-completed-result-reopened')
        tap_native('Zur Spieleauswahl', 'return-completed-result-to-app', scroll='down', context='finished')
        for _ in range(30):
            if not base.adb('shell', 'pidof', package + ':lumo_game', check=False):
                break
            time.sleep(1)
        else:
            raise RuntimeError('Native process remained after genuine completed-result return')
        base.foreground()
        creative.capture(out, '13-completed-race-returned-to-app')
        for attempt in range(30):
            if creative.wallet(out, f'replayed-wallet-{attempt}') != rewarded_wallet:
                raise RuntimeError('Reopening/returning the same completed result duplicated a reward')
            replay_events = events(f'replayed-ack-{attempt}')
            if not any(row.get('resultId') == result_id for row in replay_events.get('results', [])):
                break
            time.sleep(1)
        else:
            raise RuntimeError('Replayed completed result was not acknowledged')
        require_ack(replay_events, result_id)
        restarted_home('14-final-offline-restart')
        if creative.wallet(out, 'final-wallet') != rewarded_wallet:
            raise RuntimeError('Completed/replayed reward changed after the final offline restart')
        result['replay_deduplication'] = {'status': 'PASS', 'same_completed_result_reopened': True,
                                         'host_return': True, 'wallet_unchanged': True,
                                         'host_acknowledged': True, 'final_offline_restart': True}
        crashes = base.adb('logcat', '-d', '-b', 'crash', check=False)
        (out / 'crash-buffer.txt').write_text(crashes)
        if package in crashes:
            raise RuntimeError('Lumo appears in the actual Android crash buffer')
        runtime_log = base.adb('logcat', '-d', check=False)
        (out / 'logcat.txt').write_text(runtime_log)
        require_no_runtime_error(runtime_log)
        result['video'] = video.stop()
        video = None
        if result['video']['status'] != 'PASS':
            raise RuntimeError('Actual Android footage collection failed: ' +
                               '; '.join(result['video']['errors'] or ['no nonempty video segments']))
        result['status'] = 'PASS'
        print('[CompleteKartAndroid] PASS: 16 checkpoints, pause, actual result, offline recovery, host ACK and reward deduplication', flush=True)
        return 0
    except Exception as error:
        result.update(status='FAIL', error=str(error), traceback=traceback.format_exc())
        try:
            creative.capture(out, 'failure')
        except Exception as capture_error:
            result['failure_capture_error'] = str(capture_error)
        print('[CompleteKartAndroid] FAIL:', error, flush=True)
        return 1
    finally:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, previous_alarm)
        if video is not None:
            result['video'] = video.stop()
        write_json('result.json', result)
        try:
            (out / 'logcat.txt').write_text(base.adb('logcat', '-d', check=False))
        except Exception as error:
            write_json('logcat-collection-error.json', {'error': str(error)})


if __name__ == '__main__':
    raise SystemExit(main())
