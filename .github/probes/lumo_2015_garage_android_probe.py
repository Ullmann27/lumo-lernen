#!/usr/bin/env python3
"""Supplemental, real-input Garage QA of the immutable 2015 x86_64 APK.

The APK is never rebuilt. Existing UI/OCR, rooted-emulator and race-evidence
helpers are imported from the exact source that produced it. App files are
read only: onboarding, selection, confirmation, pause and return use real UI.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
import traceback
import unicodedata

REPOSITORY = 'Ullmann27/lumo-lernen'
REPOSITORY_ID = 1222433959
SOURCE = '2718f405e69c193d0121c6f6447fe53769d7c803'
NATIVE = 'b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1'
APK_SHA256 = 'b863bc25bc07a7ca3fb78ad4fd56a6f816d091f821c5b9af27bfb0a7aecbcb4e'
CERTIFICATE = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
SOURCE_RUN = 43024454590
SOURCE_WORKFLOW = 385610539
ARTIFACT_ID = 13858046311
ARTIFACT_NAME = 'lumo-lernen-kart-unified-2026-candidate'
ARTIFACT_DIGEST = 'sha256:f45fbeee373a339654d35d395065055aa9f1c2e4156697f9926a1f4706625d2a'
BRANCH = 'chatgpt/lumo-technical-art-host-20261111'
QA_BRANCH = 'chatgpt/lumo-2015-android-garage-qa-20261111'
LAYOUTS = {'phone': (1080, 2400, 420),
           'fold-cover': (904, 2316, 420),
           'fold-open': (1812, 2176, 420)}
KARTS = {'comet': 'Comet', 'gecko_velo': 'Gecko Velo'}
REQUIRED_STEPS = (
    'apk-identity', 'onboarding', 'phone-garage-cancel-back',
    'phone-comet-selection-confirm-start', 'phone-comet-drive',
    'phone-comet-pause-freeze', 'phone-comet-continue-and-drive',
    'phone-comet-pause-android-back', 'phone-gecko-selection-confirm-start',
    'phone-gecko-drive', 'phone-gecko-abandon',
    'fold-cover-garage-confirm-back', 'fold-open-garage-confirm-back',
    'profile-learning-preserved', 'no-native-crash',
)


def demand(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def source_run_guard(run: dict, jobs: list[dict], artifacts: list[dict]) -> dict:
    """Read-only API identity check; only the completed build supplies this APK.

    The original Android-tour/update gates keep running independently. This
    supplemental probe does not reinterpret their results or replace them.
    """
    demand(run.get('id') == SOURCE_RUN and run.get('head_sha') == SOURCE,
           'Unexpected immutable source run/head')
    demand(run.get('workflow_id') == SOURCE_WORKFLOW and
           run.get('path') == '.github/workflows/lumo-unified-integration-2026.yml',
           'Unexpected source workflow')
    demand(run.get('event') == 'pull_request' and run.get('head_branch') == BRANCH,
           'Unexpected source event/branch')
    for key in ('repository', 'head_repository'):
        demand(run.get(key, {}).get('full_name') == REPOSITORY and
               run.get(key, {}).get('id') == REPOSITORY_ID, 'Foreign source repository')
    attempt = run.get('run_attempt')
    demand(isinstance(attempt, int) and not isinstance(attempt, bool) and attempt >= 1,
           'Invalid source run attempt')
    builds = [job for job in jobs if job.get('name') == 'verify-and-build']
    demand(len(builds) == 1, 'Missing or ambiguous build job')
    build = builds[0]
    demand(build.get('run_id') == SOURCE_RUN and build.get('head_sha') == SOURCE and
           build.get('run_attempt') == attempt, 'Build job belongs to another attempt/source')
    demand(build.get('status') == 'completed' and build.get('conclusion') == 'success',
           'The fixed APK build has not passed')
    candidates = [item for item in artifacts if item.get('name') == ARTIFACT_NAME]
    demand(len(candidates) == 1, 'Missing or ambiguous source artifact')
    artifact = candidates[0]
    demand(artifact.get('id') == ARTIFACT_ID and artifact.get('digest') == ARTIFACT_DIGEST,
           'Artifact was replaced or is not the reviewed byte archive')
    demand(artifact.get('expired') is False and artifact.get('size_in_bytes', 0) > 0,
           'Source artifact unavailable')
    identity = artifact.get('workflow_run', {})
    demand(identity.get('id') == SOURCE_RUN and identity.get('head_sha') == SOURCE and
           identity.get('repository_id') == REPOSITORY_ID and
           identity.get('head_repository_id') == REPOSITORY_ID,
           'Foreign artifact source')
    return {'status': 'PASS', 'source': SOURCE, 'source_run': SOURCE_RUN,
            'build_job': build['id'], 'artifact_id': ARTIFACT_ID,
            'artifact_digest': ARTIFACT_DIGEST,
            'scope': 'Fixed successful build identity; not a runtime acceptance result'}


def require_selected_race(state: dict, kart: str, *, previous_id: str | None = None) -> None:
    demand(kart in KARTS and state.get('selected_kart') == kart,
           f'Actual race selected {state.get("selected_kart")!r}, expected {kart}')
    demand(state.get('track_id') == 'sonnenhafen' and state.get('mode') == 'cup',
           'Confirmed Garage did not start Sonnenhafen in the selected Cup mode')
    demand(state.get('selected_driver') == 'fox', 'Original Lumo driver was not preserved')
    demand(not state.get('finished') and not state.get('completed_race'),
           'Expected a newly running unfinished race')
    result_id = state.get('result_id')
    demand(isinstance(result_id, str) and bool(result_id) and result_id != previous_id,
           'Race start reused the previous saved race instead of the confirmed selection')
    for key in ('distance', 'elapsed', 'countdown'):
        value = state.get(key)
        demand(isinstance(value, (int, float)) and not isinstance(value, bool) and
               math.isfinite(value), f'Nonfinite or missing native race field: {key}')


def require_resumed_progress(paused: dict, resumed: dict, kart: str) -> dict:
    require_selected_race(paused, kart)
    require_selected_race(resumed, kart)
    demand(resumed['result_id'] == paused['result_id'], 'Continue opened a different race')
    distance = resumed['distance'] - paused['distance']
    elapsed = resumed['elapsed'] - paused['elapsed']
    demand(distance >= 8.0 and elapsed >= 2.5,
           f'Continue has not produced new driving progress: {distance} m / {elapsed} s')
    demand(resumed['countdown'] <= 0, 'Continue restarted the countdown')
    return {'result_id': resumed['result_id'], 'kart': kart,
            'distance_gain_after_continue': distance, 'elapsed_gain_after_continue': elapsed}


def require_complete(steps: list[dict], races: list[dict]) -> None:
    names = [item.get('step') for item in steps]
    demand(len(names) == len(set(names)), 'Duplicate acceptance steps')
    demand(set(names) == set(REQUIRED_STEPS) and all(item.get('status') == 'PASS' for item in steps),
           'At least one mandatory Android Garage acceptance step is missing or failed')
    demand(len(races) == 2 and {item.get('selected_kart') for item in races} == set(KARTS),
           'Both original freely available vehicles must be confirmed in actual races')
    demand(len({item.get('result_id') for item in races}) == 2, 'Two distinct races are required')


def normalize(text: str) -> str:
    text = unicodedata.normalize('NFKD', text.lower())
    return ''.join(char for char in text if char.isalnum())


def garage_scroll_observation(frame: dict, lines: list[dict]) -> dict:
    """Derive a list drag from actual header, footer and card glyph bounds.

    Godot's shipped landscape Garage puts its vehicle list left of the 3D
    preview. No hardcoded input coordinate, offscreen target or saved selection
    is used. The final desired card must still be read and pressed normally.
    """
    demand(frame.get('acceptable_for_target_sampling') is True,
           'Cannot scroll an incomplete native surface')
    width, height = frame['pixels']
    headers = [row for row in lines if normalize(row['text']) == 'deinkartdeinstil']
    footers = [row for row in lines if normalize(row['text']) in ('weiter', 'zuruck')]
    demand(headers and footers, 'Actual Garage title/footer required before list scrolling')
    header_bottom = min(row['bounds'][3] for row in headers)
    footer_top = max(row['bounds'][1] for row in footers)
    cards = [row for row in lines if normalize(row['text']) in
             ('comet', 'geckovelo', 'borurally', 'glider', 'nalacomet', 'noatide') and
             0 < row['bounds'][0] < row['bounds'][2] < width * .50 and
             header_bottom < row['bounds'][1] < row['bounds'][3] < footer_top]
    demand(cards, 'No currently visible vehicle card in the actual left list')
    # The highest visible original card cannot be confused with the selected
    # summary below the right-hand preview; start inside its own observed text.
    card = min(cards, key=lambda row: row['bounds'][1])
    x0, y0, x1, y1 = card['bounds']
    x, start = round((x0+x1)/2), round((y0+y1)/2)
    end = round(max(header_bottom + 8, start - max(40, (y1-y0)*5)))
    demand(0 <= x < width and header_bottom < end < start < footer_top < height and
           start-end >= 15, 'Observed vehicle-list span is too small for a controlled drag')
    return {'gesture': [x, start, x, end], 'card': card,
            'header_bottom': header_bottom, 'footer_top': footer_top,
            'scope': 'Scroll gesture only; target caption and real selection remain mandatory'}


def fatal_events(log: str) -> list[str]:
    """Same fatal-event criteria as the original tour, on a required successful read."""
    lines, found = log.splitlines(), []
    for index, line in enumerate(lines):
        if 'FATAL EXCEPTION' in line or 'Fatal signal' in line:
            window = '\n'.join(lines[index:index+6])
            if PACKAGE in window or 'lumo' in window.lower():
                found.append(window)
    return found


class GarageQA:
    def __init__(self, source: Path, out: Path):
        self.source, self.out = source.resolve(), out.resolve()
        self.out.mkdir(parents=True, exist_ok=True)
        actual = subprocess.check_output(['git', '-C', str(self.source), 'rev-parse', 'HEAD'], text=True).strip()
        demand(actual == SOURCE, 'Existing QA helpers must come from the exact built source')
        dirty = subprocess.check_output(['git', '-C', str(self.source), 'status', '--porcelain',
                                        '--untracked-files=no'], text=True)
        demand(not dirty.strip(), 'Pinned helper checkout contains tracked changes')
        for relative in ('scripts', 'scripts/probes', 'tools/android_qa', '.github/probes'):
            sys.path.insert(0, str(self.source / relative))
        os.chdir(self.source)
        self.tour = importlib.import_module('modernization_android_tour')
        self.probe = self.tour.probe
        self.base = self.tour.base
        self.evidence = self.tour.evidence
        self.races: list[dict] = []
        self.log_reads = 0
        self.result = {'status': 'RUNNING', 'source': SOURCE, 'godot_source': NATIVE,
                       'source_run': SOURCE_RUN, 'apk_sha256': APK_SHA256, 'steps': [],
                       'races': self.races, 'not_tested': [
                           'physical Android hardware, thermals, RAM, 60 FPS',
                           'full Sonnenhafen laps, loops or ramps on Android',
                           'Fold racing: Fold cases exercise the actual native Garage only',
                           '48 dp hit-area measurement: OCR bounds are text bounds, not touch bounds',
                           'audio playback and haptic sensation'],
                       'native_state_access': 'read only; no file writes or pose/unlock injection'}
        self.save()

    def save(self) -> None:
        write_json(self.out / 'garage-result.json', self.result)

    def step(self, name: str, action):
        started = time.monotonic()
        entry = {'step': name, 'status': 'RUNNING'}
        self.result['steps'].append(entry)
        self.save()
        try:
            detail = action()
            entry.update(status='PASS', evidence=detail)
            return detail
        except Exception as error:
            entry.update(status='FAIL', error=f'{type(error).__name__}: {error}')
            raise
        finally:
            entry['wall_seconds'] = round(time.monotonic() - started, 3)
            self.save()
            print('[GarageEvidence] ' + json.dumps(entry, ensure_ascii=False)[:2200], flush=True)

    def folder(self, name: str) -> Path:
        path = self.out / name
        path.mkdir(parents=True, exist_ok=True)
        return path

    def expect(self, out: Path, label: str, tag: str, *, exact: bool = False,
               timeout: float = 90) -> dict:
        deadline, attempt = time.monotonic() + timeout, 0
        wanted = self.probe.normalized(label)
        while time.monotonic() < deadline:
            snapshot = self.probe.capture(out, f'{tag}-{attempt}', timeout=max(1, deadline-time.monotonic()))
            source = out / snapshot['file']
            lines = self.probe.image_lines(out, f'{tag}-{attempt}', wanted,
                                          source_path=source, exact=exact,
                                          timeout=max(1, deadline-time.monotonic()))
            matches = [line for line in lines if
                       (self.probe.normalized(line['text']) == wanted if exact else
                        wanted in self.probe.normalized(line['text']))]
            if matches:
                return {'capture': snapshot, 'caption': label, 'observed': matches}
            attempt += 1
            time.sleep(1)
        raise TimeoutError('Actual native screenshot lacks ' + label)

    def tap(self, out: Path, label: str, tag: str, *, exact: bool = True) -> dict:
        actual_tag = tag
        if label == 'Rennen abbrechen':
            # The shipped pause panel scrolls. Reuse its existing guarded,
            # real-caption modal scrolling rather than requiring an offscreen row.
            navigation = importlib.import_module('lumo_1939_pause_navigation')
            navigation.tap_pause_setting(out, label, tag, scroll='down')
            actual_tag += '-stable-action'
        else:
            recovery = self.card_scroll_recovery() if label in KARTS.values() else None
            self.probe.native_tap(out, label, tag, timeout=150, exact=exact,
                                  missing_caption=recovery)
        report = json.loads((out / (actual_tag + '-surface-readiness.json')).read_text())
        demand(report.get('status') == 'TOUCH_SENT', 'No actual observed native touch was sent')
        return {'readiness': str((out / (actual_tag + '-surface-readiness.json')).relative_to(self.out)),
                'label': label, 'touch': report['touch']}

    def card_scroll_recovery(self):
        previous, swipes = None, 0
        def recovery(frame, lines, source, *, deadline, previous_missing_frame):
            nonlocal previous, swipes
            current = garage_scroll_observation(frame, lines)
            stable = (previous is not None and previous_missing_frame is not None and
                      previous_missing_frame.get('pixels') == frame['pixels'] and
                      max(abs(a-b) for a, b in zip(current['gesture'], previous['gesture'])) <= 12)
            previous = current
            if not stable:
                return {'status': 'WAITING_FOR_SECOND_LIST_FRAME', **current}
            demand(swipes < 5, 'Vehicle card remained offscreen after five observed list gestures')
            demand(self.probe.digest(source) == frame['source_sha256'],
                   'Observed vehicle-list screenshot changed before gesture')
            remaining = deadline-time.monotonic()
            demand(remaining > 0, 'Vehicle list scrolling exceeded its bounded deadline')
            self.base.adb('shell', 'input', 'swipe', *map(str, current['gesture']), '650',
                          timeout=min(15, remaining))
            swipes += 1
            previous = None
            return {'status': 'SWIPE_SENT', 'swipe_number': swipes, **current}
        return recovery

    def back(self) -> None:
        self.base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        time.sleep(1)

    def rendered_layout(self, out: Path, layout: str, tag: str) -> dict:
        snapshot = self.probe.capture(out, tag)
        from PIL import Image
        with Image.open(out / snapshot['file']) as image:
            size = list(image.size)
        width, height, density = LAYOUTS[layout]
        demand(sorted(size) == sorted([width, height]), 'Actual screenshot does not match requested display')
        demand(size[0] > size[1], 'Native game must be visibly presented in landscape')
        metrics = {'layout': layout, 'requested_portrait_pixels': [width, height],
                   'requested_density_dpi': density, 'actual_screenshot_pixels': size,
                   'screenshot': snapshot,
                   'wm_size': self.base.adb('shell', 'wm', 'size'),
                   'wm_density': self.base.adb('shell', 'wm', 'density'),
                   'foreground': self.base.foreground()}
        demand('LumoGameActivity' in metrics['foreground'], 'Native game activity is not foreground')
        write_json(out / (tag + '-display.json'), metrics)
        return metrics

    def open_native(self, out: Path) -> dict:
        label = self.tour.try_tap(out, [
            'Lumo Kart. Fahre mit Lumo um die Wette! Spielen', 'Losfahren', 'Rennen starten'], 'open-kart')
        demand(label is not None, 'Actual Flutter Kart portal could not be pressed')
        deadline = time.monotonic() + 65
        while not self.tour.godot_alive() and time.monotonic() < deadline:
            time.sleep(2)
        demand(self.tour.godot_alive(), 'Native game process did not start')
        landing = self.expect(out, 'Garage', 'native-landing', exact=True)
        return {'portal_label': label, 'landing': landing}

    def open_garage(self, out: Path) -> dict:
        touch = self.tap(out, 'Garage', 'open-real-garage')
        title = self.expect(out, 'Dein Kart. Dein Stil.', 'garage-title')
        return {'touch': touch, 'title': title}

    def read_required_logcat(self, tag: str) -> str:
        # A transport/ADB failure must never mean "zero crashes/zero markers".
        log = self.base.adb('logcat', '-d', '-v', 'brief', timeout=60, check=True)
        self.log_reads += 1
        (self.out / f'{tag}-{self.log_reads}.log').write_text(log)
        demand(bool(log.strip()), 'Required logcat observation returned an empty log')
        return log

    def marker_count(self) -> int:
        log = self.read_required_logcat('required-race-markers')
        return len(re.findall(r'\[Kart\] race_world_ready:', log))

    def cancel_to_landing(self, out: Path) -> dict:
        before = self.marker_count()
        self.tap(out, 'Gecko Velo', 'cancel-select-gecko')
        self.tap(out, 'Weiter', 'cancel-confirm-kart')
        world = self.expect(out, 'Wohin geht die Reise?', 'cancel-world')
        self.tap(out, 'Zurück', 'cancel-visible-back')
        kart = self.expect(out, 'Dein Kart. Dein Stil.', 'cancel-back-kart')
        self.back()
        driver = self.expect(out, 'Wer fährt mit?', 'cancel-back-driver')
        self.back()
        mode = self.expect(out, 'Dein nächstes Abenteuer', 'cancel-back-mode')
        self.back()
        landing = self.expect(out, 'Garage', 'cancel-back-landing', exact=True)
        demand(self.marker_count() == before, 'Cancel/back unexpectedly launched a race')
        return {'world': world, 'kart': kart, 'driver': driver, 'mode': mode,
                'landing': landing, 'race_not_started': True}

    def start_selected(self, out: Path, kart: str) -> tuple[object, dict]:
        self.open_garage(out)
        touch = self.tap(out, KARTS[kart], 'select-' + kart)
        selected_capture = self.probe.capture(out, 'selected-' + kart)
        self.rendered_layout(out, 'phone', 'phone-garage')
        self.tap(out, 'Weiter', 'confirm-kart')
        self.expect(out, 'Wohin geht die Reise?', 'world-title')
        self.tap(out, 'Weiter', 'confirm-world')
        self.expect(out, 'Finde dein Tempo', 'tempo-title')
        final = self.probe.capture(out, 'garage-final-confirmation')
        markers = self.marker_count()
        self.tap(out, 'Rennen starten', 'start-confirmed-race')
        session = self.tour.RaceSession(out, expected_mode='cup', expected_track='sonnenhafen')
        state = self.tour.wait_race_running(session)
        previous = self.races[-1]['result_id'] if self.races else None
        require_selected_race(state, kart, previous_id=previous)
        hud = self.tour.wait_race_hud(out)
        demand(self.marker_count() > markers, 'No new native world-ready marker after confirmation')
        replaced = self.evidence.garage_replaced(
            (out / final['file']).read_bytes(), (out / (hud['capture'] + '.png')).read_bytes())
        race = {key: state[key] for key in ('selected_kart', 'selected_driver', 'result_id',
                                           'mode', 'track_id', 'countdown', 'elapsed', 'distance')}
        self.races.append(race)
        return session, {'actual_race': race, 'selection_touch': touch,
                         'selection_capture': selected_capture, 'hud': hud,
                         'garage_replaced': replaced}

    def drive(self, out: Path, session, kart: str, start: dict | None = None) -> dict:
        state = start if start is not None else session.read('drive-start')
        require_selected_race(state, kart)
        hud = self.tour.wait_race_hud(out)
        point = self.tour.find_gas(out, hud['capture'])
        movement = self.tour.drive_with_gas(out, point, session, state)
        after = session.read('drive-complete')
        require_selected_race(after, kart)
        return {'start': state, 'after': after, 'movement': movement}

    def pause(self, out: Path, session, kart: str) -> dict:
        before = session.read('before-pause')
        self.back()
        title = self.expect(out, 'Eine kleine Pause', 'pause-title')
        self.expect(out, 'Weiterfahren', 'pause-continue', exact=True)
        paused = session.read('paused-first')
        require_selected_race(paused, kart)
        demand(before['result_id'] == paused['result_id'], 'Pause changed race identity')
        time.sleep(3)
        second = session.read('paused-second')
        frozen = self.evidence.paused_unchanged(paused, second, mode='cup', track='sonnenhafen')
        return {'title': title, 'state': second, 'frozen': frozen,
                'scope': 'Visible pause and unchanged app-persisted samples over 3 wall seconds; not a continuous physics trace'}

    def return_flutter(self, out: Path, tag: str) -> dict:
        snapshot = self.probe.flutter_return_capture(out, tag)
        demand(self.tour.alive() and 'LumoGameActivity' not in self.base.foreground(),
               'Flutter did not recover from native navigation')
        return {'capture': snapshot, 'foreground': self.base.foreground()}

    def fold_garage(self, name: str) -> dict:
        out = self.folder(name)
        self.base.display(*LAYOUTS[name])
        self.probe.device_rotation(out, 'portrait-before-kart', 0)
        self.probe.capture_flutter_ready(out, 'flutter-before-kart')
        self.open_native(out)
        garage = self.open_garage(out)
        comet = self.expect(out, 'Comet', 'visible-comet', exact=True)
        gecko_touch = self.tap(out, 'Gecko Velo', 'reveal-and-select-gecko')
        gecko = self.expect(out, 'Gecko Velo', 'visible-gecko', exact=True)
        screen = self.rendered_layout(out, name, 'actual-native-garage')
        navigation = self.cancel_to_landing(out)
        self.back()
        returned = self.return_flutter(out, 'flutter-after-garage')
        return {'scope': 'Native Garage, both free cards visible, selection touch, confirmation and back; no Fold race',
                'garage': garage, 'comet': comet, 'gecko': gecko, 'gecko_touch': gecko_touch, 'screen': screen,
                'navigation': navigation, 'returned': returned}

    def verify_apk(self, apk: Path, provenance: Path, sums: Path) -> dict:
        demand(hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest() == APK_SHA256,
               'APK bytes differ from the fixed built x86_64 candidate')
        verifier = importlib.import_module('verify_unified_apk')
        package = verifier.verify(apk, {'x86_64'})
        demand(package['package'] == PACKAGE and package['versionCode'] == 2015 and
               package['versionName'] == '0.13.3' and package['sha256'] == APK_SHA256 and
               package['signingCertificateSha256'] == CERTIFICATE and
               package['godot']['revision'] == NATIVE, 'APK package/signature/native identity differs')
        identity = self.tour.verify_apk_identity(apk, provenance, sums)
        demand(identity['godot_pck_sha256'] == package['godot']['pck_sha256'],
               'Tour metadata and actual embedded PCK differ')
        write_json(self.out / 'verified-actual-apk.json', package)
        return {'actual_apk': package, 'provenance': identity}

    def execute(self, args) -> None:
        self.step('apk-identity', lambda: self.verify_apk(args.apk, args.provenance, args.sums))
        self.result['root_readiness'] = self.probe.ensure_rooted_emulator(self.base.adb, self.out)
        self.base.adb('logcat', '-c', check=False)
        self.base.display(*LAYOUTS['phone'])
        installed = self.base.adb('install', '-r', '--no-streaming', str(args.apk), timeout=300)
        (self.out / 'install.txt').write_text(installed)
        demand('Success' in installed, 'Exact APK installation failed')
        self.result['installed_package'] = self.probe.package_identity(self.out, 'installed')
        self.base.launch(self.out, 'cold-start')
        self.step('onboarding', lambda: self.probe.onboard(self.out))
        before = self.probe.prefs(self.out, 'before-garage')
        initial = self.folder('phone-cancel')
        self.open_native(initial)
        self.open_garage(initial)
        self.step('phone-garage-cancel-back', lambda: self.cancel_to_landing(initial))

        comet_out = self.folder('phone-comet')
        selected = {}
        def start_comet():
            selected['session'], detail = self.start_selected(comet_out, 'comet')
            return detail
        self.step('phone-comet-selection-confirm-start', start_comet)
        session = selected['session']
        self.step('phone-comet-drive', lambda: self.drive(self.folder('phone-comet/first-drive'), session, 'comet'))
        paused = self.step('phone-comet-pause-freeze', lambda: self.pause(comet_out, session, 'comet'))
        def resume():
            touch = self.tap(comet_out, 'Weiterfahren', 'actual-continue')
            drive = self.drive(self.folder('phone-comet/after-continue'), session, 'comet', paused['state'])
            progress = require_resumed_progress(paused['state'], drive['after'], 'comet')
            return {'touch': touch, 'drive': drive, 'progress': progress}
        self.step('phone-comet-continue-and-drive', resume)
        def pause_back():
            proof = self.pause(comet_out, session, 'comet')
            self.back()
            return {'pause': proof, 'return': self.return_flutter(comet_out, 'android-back-to-flutter')}
        self.step('phone-comet-pause-android-back', pause_back)

        gecko_out = self.folder('phone-gecko')
        self.open_native(gecko_out)
        def start_gecko():
            selected['session'], detail = self.start_selected(gecko_out, 'gecko_velo')
            return detail
        self.step('phone-gecko-selection-confirm-start', start_gecko)
        session = selected['session']
        self.step('phone-gecko-drive', lambda: self.drive(self.folder('phone-gecko/drive'), session, 'gecko_velo'))
        def abandon():
            proof = self.pause(gecko_out, session, 'gecko_velo')
            touch = self.tap(gecko_out, 'Rennen abbrechen', 'actual-abandon')
            return {'pause': proof, 'touch': touch,
                    'return': self.return_flutter(gecko_out, 'abandon-to-flutter')}
        self.step('phone-gecko-abandon', abandon)

        for layout in ('fold-cover', 'fold-open'):
            self.step(layout + '-garage-confirm-back', lambda layout=layout: self.fold_garage(layout))
        self.step('profile-learning-preserved', lambda: self.evidence.learning_preserved(
            before, self.probe.prefs(self.out, 'after-all-garage-cases')))
        def no_crash():
            fatal = fatal_events(self.read_required_logcat('required-fatal-observation'))
            demand(not fatal, 'A native/host fatal crash occurred: ' + repr(fatal))
            return {'fatal_events': fatal}
        self.step('no-native-crash', no_crash)
        require_complete(self.result['steps'], self.races)
        self.result['status'] = 'PASS'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    guard = commands.add_parser('guard')
    guard.add_argument('--metadata', type=Path, required=True)
    run = commands.add_parser('run')
    for name in ('source-root', 'apk', 'provenance', 'sums', 'out'):
        run.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    if args.command == 'guard':
        data = args.metadata
        report = source_run_guard(json.loads((data / 'source-run.json').read_text()),
                                  json.loads((data / 'source-jobs.json').read_text()),
                                  json.loads((data / 'source-artifacts.json').read_text()))
        write_json(data / 'source-guard.json', report)
        print(json.dumps(report))
        return 0
    for name in ('source_root', 'apk', 'provenance', 'sums', 'out'):
        setattr(args, name, getattr(args, name).resolve())
    qa = GarageQA(args.source_root, args.out)
    started = time.monotonic()
    def deadline(_signum, _frame):
        raise TimeoutError('The real Android Garage probe exceeded its 28-minute bounded budget')
    signal.signal(signal.SIGALRM, deadline)
    signal.alarm(28 * 60)
    try:
        qa.execute(args)
    except Exception as error:
        qa.result.update(status='FAIL', error=f'{type(error).__name__}: {error}')
        (qa.out / 'failure-traceback.txt').write_text(traceback.format_exc())
        try:
            qa.probe.capture(qa.out, '99-failure', timeout=20)
        except Exception as capture_error:
            qa.result['failure_capture_error'] = str(capture_error)
    finally:
        signal.alarm(0)
        qa.result['wall_seconds'] = round(time.monotonic() - started, 3)
        try:
            log = qa.base.adb('logcat', '-d', '-v', 'threadtime', timeout=30, check=False)
            (qa.out / 'android-logcat.txt').write_text(log)
        except Exception as log_error:
            qa.result['logcat_error'] = str(log_error)
        qa.save()
    print('[GarageResult] ' + json.dumps(qa.result, ensure_ascii=False)[:12000], flush=True)
    return 0 if qa.result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
