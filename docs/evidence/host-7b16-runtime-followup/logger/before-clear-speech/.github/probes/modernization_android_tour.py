#!/usr/bin/env python3
"""Tour the exact candidate APK on a disposable Android emulator.

Installs the APK, starts it, creates a fictional profile through the real
onboarding and walks the path a child takes: start, learning, games, Lumo Kart
(native Godot), its live menu or legacy garage steps, an actual race, pause, the return to
Flutter, the learning state afterwards, an app restart and the Fold sizes.

Flutter controls come from the live accessibility tree, native Godot controls
from OCR of current screenshots. Native state is READ ONLY: the race session
the game persists itself and Flutter's SharedPreferences. Nothing is injected.

The race only counts when the game's own session shows a running race clock,
the screenshot shows a rendered 3D scene with the race HUD instead of the
garage, and holding the visible GAS button moves the kart (saved distance)
and the rendered world. Pause must freeze the saved race; the return must show
a current Flutter frame with unchanged profile and learning data.
"""
from __future__ import annotations

import argparse
import base64
import csv
import io
import json
import os
import re
import unicodedata
from pathlib import Path
import subprocess
import sys
import time
import traceback

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import creative_android_probe as probe  # noqa: E402  (pinned live helpers)
import kart_complete_android_probe as complete  # noqa: E402  (proven race-save reader)
import kart_tour_evidence as evidence  # noqa: E402  (tools/android_qa, added by probe)
import kart_garage_evidence as garage_evidence  # noqa: E402
from kart_android_race import (  # noqa: E402
    focused_race_hud_text, focused_race_hud_visible, marker as race_marker,
    race_state, race_view_visible, read_frame,
)

base = probe.base
live = probe.live
PACKAGE = probe.PACKAGE
SESSION_NAME = 'kart_sonnenhafen_session.cfg'
HARD_STEPS = (
    'apk-identity', 'launch', 'onboarding', 'navigate-start', 'navigate-lernen',
    'atelier-roundtrip', 'navigate-spiele', 'open-kart', 'start-kart-race', 'race-running', 'race-hud',
    'race-drive', 'pause-menu', 'return-from-kart', 'learning-state-after-kart',
    'lernen-usable-after-kart', 'profile-after-kart', 'restart-keeps-learning-state',
)
# Downscaled JPEG copies of these real screenshots are written to the job log
# (originals and their SHA-256 stay in the uploaded tour artifact).
LOG_IMAGES = (
    '07_home_after_onboarding', '08_games_after_navigation', '10_lernen',
    '11_atelier_hub', '12_atelier_beispiel', '13_atelier_zehnerbruecke',
    '20_spiele', '21_lumo_kart_20s', '21_kart_premium_start', '21_kart_garage_step_1',
    '21_kart_garage_step_5',
    '21_lumo_kart_real_race', '21_race_hud', '21_race_driving_late', '21_lumo_kart_pause',
    '23_zurueck_in_flutter', '24_lernen_nach_kart', '25_start_nach_kart', '26_neustart',
    '99_fehler',
)


def logcat_fatal() -> list[str]:
    text = base.adb('logcat', '-d', '-v', 'brief', timeout=60, check=False)
    lines = text.splitlines()
    fatal = []
    for i, line in enumerate(lines):
        if 'FATAL EXCEPTION' in line or 'Fatal signal' in line:
            window = '\n'.join(lines[i:i + 6])
            if PACKAGE in window or 'lumo' in window.lower():
                fatal.append(window)
    return fatal


def alive() -> bool:
    return bool(base.adb('shell', 'pidof', PACKAGE, check=False).strip())


def godot_alive() -> bool:
    # LumoGameActivity runs in :lumo_game. The Flutter host remaining
    # alive does not prove the embedded 3D engine actually launched.
    return bool(base.adb('shell', 'pidof', PACKAGE + ':lumo_game',
                         check=False).strip())


def try_tap(out: Path, labels: list[str], tag: str) -> str | None:
    for label in labels:
        try:
            is_kart = tag == 'open-kart'
            probe.flutter_tap(
                out, label, f'{tag}-{len(label)}',
                scroll_attempts=10 if is_kart else 3,
                direction_order=(1, -1) if is_kart else (-1, 1),
                # The actual 1995 Android tree exposed 'Losfahren' at
                # [68,1992][1012,1993]: 1 pixel because it was clipped.
                # Wait for a meaningful physical touch target before pressing.
                min_visible_height_px=48 if is_kart else 1,
            )
            return label
        except Exception:  # The next alternative label is tried.
            continue
    return None


def labels(nodes: list[dict]) -> list[str]:
    """Visible Flutter captions of the current accessibility tree."""
    found = []
    for node in nodes:
        if node.get('package') != PACKAGE:
            continue
        for value in (node.get('text', ''), node.get('content-desc', '')):
            found.extend(line.strip() for line in value.split('\n') if line.strip())
    return found



def _atelier_roundtrip(out: Path) -> dict:
    """Touch the genuine Flutter learning world, build model, and return.

    Requires the same source-pinned Android installation and live accessibility
    reader as the Kart tour. Never writes fabricated progress, reward or answers.
    """
    def must_see(tag: str, expected: str) -> list[str]:
        for index in range(12):
            visible = labels(live.live_nodes(out, f'atelier-{tag}-{index}'))
            if any(expected in caption for caption in visible):
                return visible
            time.sleep(.5)
        raise RuntimeError(
            f'Atelier {tag} did not show actual Flutter text {expected!r}')

    probe.flutter_tap(out, 'Lumos Lernatelier · gemeinsam bauen',
                      'atelier-home-entry', scroll_attempts=18)
    must_see('hub', 'Lumos Lernatelier')
    must_see('topic-list', 'Die Zehnerbrücke')
    probe.capture_flutter_ready(out, '11_atelier_hub')
    probe.flutter_tap(out, 'Die Zehnerbrücke',
                      'atelier-enter-bridge', scroll_attempts=5)
    must_see('worked-example', 'Jetzt gemeinsam bauen')
    probe.capture_flutter_ready(out, '12_atelier_beispiel')
    probe.flutter_tap(out, 'Jetzt gemeinsam bauen',
                      'atelier-build', scroll_attempts=8)
    must_see('real-ten-frame', 'Dein Zehnerfeld')
    must_see('model-check', 'Mein Modell prüfen')
    probe.capture_flutter_ready(out, '13_atelier_zehnerbruecke')
    for page in ('lesson', 'hub'):
        base.adb('shell', 'input', 'keyevent', '4')
        time.sleep(1.4)
    if not alive():
        raise RuntimeError('Flutter app quit during atelier return')
    if not any('Lernen' in x for x in labels(
            live.live_nodes(out, 'atelier-after-return'))):
        raise RuntimeError('Flutter navigation unavailable after atelier return')
    return {
        'screen': 'Real native-Android Flutter Zehnerbrücke',
        'observed': ['Hub', 'Worked example', 'Interactive ten-frame',
                     'Model check', 'Flutter return'],
        'screenshots': ['11_atelier_hub.png', '12_atelier_beispiel.png',
                        '13_atelier_zehnerbruecke.png'],
    }


def _simplify(word: str) -> str:
    plain = unicodedata.normalize('NFKD', word).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', plain.lower())


def _screencap() -> bytes:
    return subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                          check=True, capture_output=True, timeout=25).stdout


def _shot(out: Path, name: str) -> bytes:
    probe.capture(out, name)
    return (out / (name + '.png')).read_bytes()


def verify_apk_identity(apk: Path, provenance_path: Path, sums_path: Path) -> dict:
    """Bind this tour to the exact APK the build job produced and verified."""
    provenance = json.loads(provenance_path.read_text())
    digest = probe.digest(apk)
    # On pull_request, GITHUB_SHA identifies GitHub's synthetic merge commit,
    # while both build and tour explicitly checkout pull_request.head.sha.
    # Bind APK provenance to the exact immutable commit actually checked out.
    expected_source = base.command('git', 'rev-parse', 'HEAD').strip()
    pin = json.loads(Path('config/godot-source.json').read_text())['revision']
    version = re.search(r'^version:\s*([0-9.]+)\+(\d+)\s*$', Path('pubspec.yaml').read_text(), re.M)
    sums = {}
    for line in sums_path.read_text().splitlines():
        if line.strip():
            value, name = line.split(maxsplit=1)
            sums[name.strip().lstrip('*')] = value
    checks = {
        'sha256_matches_provenance': provenance.get('sha256') == digest,
        'sha256_matches_build_sums': sums.get('dist/x86_64/Lumo-Lernen-Neu.apk') == digest,
        'flutter_source_is_this_commit': provenance.get('flutter_source_commit') == expected_source,
        'tracked_source_clean': provenance.get('tracked_source_clean') is True,
        'godot_revision_is_pinned': provenance.get('godot', {}).get('revision') == pin,
        'signing_certificate': provenance.get('signingCertificateSha256') == probe.CERT,
        'version_matches_pubspec': bool(version) and provenance.get('versionName') == version[1]
        and provenance.get('versionCode') == int(version[2]),
        'x86_64_native_code': 'x86_64' in provenance.get('abis', []),
    }
    report = {'apk_sha256': digest, 'flutter_source_commit': provenance.get('flutter_source_commit'),
              'godot_revision': provenance.get('godot', {}).get('revision'),
              'godot_pck_sha256': provenance.get('godot', {}).get('pck_sha256'),
              'versionName': provenance.get('versionName'), 'versionCode': provenance.get('versionCode'),
              'signingCertificateSha256': provenance.get('signingCertificateSha256'), 'checks': checks}
    failed = [name for name, ok in checks.items() if not ok]
    if failed:
        raise RuntimeError(f'Tested APK is not the verified build: {failed} {report}')
    return report


def _read_garage_footer(png: bytes, expected: str) -> tuple[int, int] | None:
    """Read the native Godot footer from actual Android screenshots, not fixed coordinates.

    Crop fallback is essential: on 2400x1080 Flutter-hosted Godot screens,
    Tesseract skips the golden 'Weiter' button when scanning the full scene.
    The same crop also recognises 'Rennen starten' on compact 640x320 screens.
    """
    image = Image.open(io.BytesIO(png)).convert('RGB')
    crop_top = int(image.height * .54)
    lower = image.crop((0, crop_top, image.width, image.height))
    variants = [
        (0, 0, 2, image.convert('L').point(lambda value: 0 if value >= 170 else 255)
         .resize((image.width * 2, image.height * 2))),
        (0, 0, 2, image.resize((image.width * 2, image.height * 2), Image.Resampling.LANCZOS)
         .convert('L').point(lambda value: 0 if value < 140 else 255)),
        (0, crop_top, 2, lower.convert('L').resize(
            (lower.width * 2, lower.height * 2), Image.Resampling.LANCZOS)),
    ]
    for offset_x, offset_y, scale, transformed in variants:
        temp = io.BytesIO()
        transformed.save(temp, format='PNG')
        process = subprocess.run(
            ['tesseract', 'stdin', 'stdout', '--psm', '11', '-l', 'deu+eng', 'tsv'],
            input=temp.getvalue(), capture_output=True, timeout=35, check=True,
        )
        rows = csv.DictReader(io.StringIO(process.stdout.decode('utf-8', 'replace')),
                              delimiter=chr(9), quoting=csv.QUOTE_NONE)
        lines: dict[tuple[str, str, str], list[dict]] = {}
        for word in rows:
            if not (word.get('text') or '').strip() or float(word.get('conf', -1)) < 15:
                continue
            key = tuple(word[k] for k in ('block_num', 'par_num', 'line_num'))
            lines.setdefault(key, []).append(word)
        for words in lines.values():
            words.sort(key=lambda word: int(word['left']))
            for start in range(len(words)):
                for end in range(start + 1, min(start + 8, len(words)) + 1):
                    span = words[start:end]
                    if _simplify(' '.join(word['text'] for word in span)) != _simplify(expected):
                        continue
                    x0 = min(int(w['left']) for w in span)
                    x1 = max(int(w['left']) + int(w['width']) for w in span)
                    y0 = min(int(w['top']) for w in span)
                    y1 = max(int(w['top']) + int(w['height']) for w in span)
                    x = (x0 + x1) // (2 * scale) + offset_x
                    y = (y0 + y1) // (2 * scale) + offset_y
                    if y >= image.height * .6:
                        return x, y
    # Targeted OCR only after the whole-screen scans fail. A moving 3D
    # background can hide the navy word inside the bright gold action pill
    # from Tesseract's sparse-text layout. Discover the pill by its ACTUAL
    # on-screen yellow pixels and require its real caption. Nothing here
    # assumes a pixel coordinate or accepts a colour patch without text.
    # The pill can sit anywhere along the bottom: the classic garage puts
    # "Weiter" bottom-right, the NextGen landing puts "START" bottom-left.
    # Per row keep the longest contiguous gold run, so gold details of the
    # illustration elsewhere in the row cannot widen the button box.
    step = 3
    min_run = max(10, int(image.width * .02)) * step
    gold_rows: list[tuple[int, int, int]] = []
    pixels = image.load()
    for row_y in range(int(image.height * .70), image.height, step):
        best = (0, -1, -1)
        run_start = previous = None
        for col_x in range(0, image.width, step):
            r, g, b = pixels[col_x, row_y]
            if r >= 205 and g >= 185 and b <= 185 and r - b > 40:
                if run_start is None or col_x - previous > step * 3:
                    run_start = col_x
                previous = col_x
                if previous - run_start > best[0]:
                    best = (previous - run_start, run_start, previous)
        if best[0] >= min_run:
            gold_rows.append((row_y, best[1], best[2]))
    # The largest vertically contiguous band of such rows is the button.
    # Caption rows split the gold left/right of the word, so the band spans
    # the outermost run edges of all its rows.
    bands: list[list[tuple[int, int, int]]] = []
    for row in gold_rows:
        if bands and row[0] - bands[-1][-1][0] <= step * 2:
            bands[-1].append(row)
        else:
            bands.append([row])
    band = max(bands, key=len, default=[])
    if len(band) >= 6:
        top = band[0][0]
        bottom = band[-1][0]
        left = min(row[1] for row in band)
        right = max(row[2] for row in band)
        width, height = right - left, bottom - top
        # A solid rounded native action control, not isolated gold pixels
        # elsewhere in the racing-world illustration.
        if width >= image.width * .08 and height >= image.height * .04:
            inset = image.crop((
                left + round(width * .06), top + round(height * .12),
                right - round(width * .05), bottom - round(height * .08),
            ))
            if inset.width > 0 and inset.height > 0:
                enlarged = inset.resize((inset.width * 4, inset.height * 4),
                                        Image.Resampling.LANCZOS)
                buffer = io.BytesIO()
                enlarged.save(buffer, format='PNG')
                result = subprocess.run(
                    ['tesseract', 'stdin', 'stdout', '--psm', '7', '-l', 'deu+eng'],
                    input=buffer.getvalue(), capture_output=True, timeout=35,
                    check=True,
                )
                caption = _simplify(result.stdout.decode('utf-8', 'replace'))
                wanted = _simplify(expected)
                # Tolerate a misread play arrow or chevron, but never accept a
                # different caption that merely contains the word, e.g. the
                # garage's "Rennen starten" when looking for "START".
                if wanted in caption and len(caption) <= len(wanted) + 3:
                    return (left + right) // 2, (top + bottom) // 2
    return None


def _stage_kart_scroll_recovery():
    """Reuse the observed two-frame list scroll from supplemental Garage QA."""
    previous, swipes = None, 0

    def recovery(frame, lines, source, *, deadline, previous_missing_frame):
        nonlocal previous, swipes
        current = garage_evidence.stage_garage_scroll_observation(frame, lines)
        stable = (previous is not None and previous_missing_frame is not None and
                  previous_missing_frame.get('pixels') == frame['pixels'] and
                  max(abs(a - b) for a, b in zip(current['gesture'], previous['gesture'])) <= 12)
        previous = current
        if not stable:
            return {'status': 'WAITING_FOR_SECOND_LIST_FRAME', **current}
        garage_evidence.demand(swipes < 5, 'Vehicle card remained offscreen after five observed list gestures')
        garage_evidence.demand(probe.digest(source) == frame['source_sha256'],
                               'Observed vehicle-list screenshot changed before gesture')
        remaining = deadline - time.monotonic()
        garage_evidence.demand(remaining > 0, 'Vehicle list scrolling exceeded its bounded deadline')
        base.adb('shell', 'input', 'swipe', *map(str, current['gesture']), '650',
                 timeout=min(15, remaining))
        swipes += 1
        previous = None
        return {'status': 'SWIPE_SENT', 'swipe_number': swipes, **current}

    return recovery


def _select_stage_kart(out: Path, kart: str) -> dict:
    label = garage_evidence.KARTS[kart]
    tag = '21_stage_select_' + kart
    probe.native_tap(out, label, tag, exact=True, timeout=150,
                     missing_caption=_stage_kart_scroll_recovery())
    journal = out / (tag + '-surface-readiness.json')
    touch = json.loads(journal.read_text())
    garage_evidence.demand(touch.get('status') == 'TOUCH_SENT',
                           'No observed native kart-selection touch was sent')
    return {'kart': kart, 'caption': label, 'touch': touch['touch'],
            'readiness': journal.name, 'scope': 'Touch only; actual new race selection is checked separately'}


def _select_stage_driver(out: Path, timeout: float = 150) -> dict:
    """Select the observed driver card without confusing it with the Lumo logo."""
    tag = '21_stage_driver-select-original-lumo'
    journal = out / (tag + '-surface-readiness.json')
    started = time.monotonic()
    deadline = started + timeout
    touch = {'status': 'WAITING', 'label': 'Lumo', 'driver': 'fox',
             'timeout_seconds': timeout, 'frames': [],
             'scope': 'Observed driver-card touch; actual new race selection is checked separately'}
    previous = None
    try:
        while time.monotonic() < deadline:
            name = f'{tag}-{len(touch["frames"])}'
            snapshot = probe.capture(out, name, timeout=deadline - time.monotonic())
            source = out / snapshot['file']
            frame = probe.inspect_surface(source, orientation='landscape')
            touch['frames'].append(frame)
            if not frame['acceptable_for_target_sampling']:
                previous = None
            else:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                # Read every full-frame variant. Stopping at the first exact
                # Lumo could find only the logo and miss the actual card.
                lines = probe.image_lines(out, name, source_path=source, timeout=remaining)
                try:
                    scoped = garage_evidence.stage_driver_target_observation(frame, lines)
                except RuntimeError as error:
                    if str(error) not in (
                            'No exact Lumo driver caption in the observed left-hand list',
                            'Ambiguous Lumo driver captions in the observed list'):
                        raise
                    # The existing TSV retains the exact word when OCR joined
                    # the adjacent fox icon into a larger text-line rectangle.
                    words = garage_evidence.stage_driver_word_observations(out, name, lines)
                    scoped = garage_evidence.stage_driver_target_observation(
                        frame, lines, caption_words=words['words'])
                    scoped.update(caption_source='original_tsv_words',
                                  line_ocr_error=str(error), ocr_sources=words['sources'])
                frame['driver_region'] = scoped
                observed = probe.target_observation(frame, scoped['target']['bounds'], previous)
                frame['target'] = observed
                previous = observed
                if observed['stable_observed_target']:
                    garage_evidence.demand(probe.digest(source) == frame['source_sha256'],
                                           'Observed driver screenshot changed before touch')
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        break
                    x0, y0, x1, y1 = observed['bounds']
                    x, y = round((x0 + x1) / 2), round((y0 + y1) / 2)
                    base.adb('shell', 'input', 'swipe', str(x), str(y), str(x), str(y), '120',
                             timeout=min(15, remaining))
                    touch.update(status='TOUCH_SENT', touch=[x, y],
                                 final_observed_bounds=observed['bounds'])
                    time.sleep(min(1.5, max(0, deadline - time.monotonic())))
                    return {'driver': 'fox', 'caption': 'Lumo', 'touch': [x, y],
                            'readiness': journal.name, 'scope': touch['scope']}
            time.sleep(min(1.5, max(0, deadline - time.monotonic())))
        raise TimeoutError('Actual Lumo driver card was not observed twice before touch')
    except Exception as error:
        touch.update(status='FAIL', error=str(error))
        raise
    finally:
        touch['elapsed_seconds'] = round(time.monotonic() - started, 6)
        journal.write_text(json.dumps(touch, indent=2, ensure_ascii=False) + '\n')


def _stage_cup_text(out: Path, tag: str, *, tap: bool = False, timeout: float = 150) -> dict:
    """Observe the current cup caption and, when requested, touch it exactly once."""
    journal = out / (tag + '-surface-readiness.json')
    started = time.monotonic()
    deadline = started + timeout
    report = {'status': 'WAITING', 'mode': 'cup', 'touch_requested': tap, 'frames': [],
              'scope': 'Current landing cup caption; actual new race mode remains mandatory'}
    previous = None
    previous_caption = None
    try:
        while time.monotonic() < deadline:
            name = f'{tag}-{len(report["frames"])}'
            snapshot = probe.capture(out, name, timeout=deadline - time.monotonic())
            source = out / snapshot['file']
            frame = probe.inspect_surface(source, orientation='landscape')
            report['frames'].append(frame)
            if not frame['acceptable_for_target_sampling']:
                previous = None
                previous_caption = None
            else:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                lines = probe.image_lines(out, name, source_path=source, timeout=remaining)
                choice = garage_evidence.stage_cup_target_observation(frame, lines)
                frame['cup_choice'] = choice
                if choice['caption'] != previous_caption:
                    previous = None
                observed = probe.target_observation(frame, choice['target']['bounds'], previous)
                frame['target'] = observed
                previous, previous_caption = observed, choice['caption']
                if observed['target_geometry_valid'] and (not tap or observed['stable_observed_target']):
                    garage_evidence.demand(probe.digest(source) == frame['source_sha256'],
                                           'Observed cup screenshot changed before acceptance')
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        break
                    report.update(caption=choice['caption'], final_observed_bounds=observed['bounds'])
                    if tap:
                        x0, y0, x1, y1 = observed['bounds']
                        x, y = round((x0 + x1) / 2), round((y0 + y1) / 2)
                        base.adb('shell', 'input', 'swipe', str(x), str(y), str(x), str(y), '120',
                                 timeout=min(15, remaining))
                        report.update(status='TOUCH_SENT', touch=[x, y])
                        time.sleep(min(1.5, max(0, deadline - time.monotonic())))
                    else:
                        report['status'] = 'OBSERVED'
                    return {'caption': choice['caption'], 'readiness': journal.name}
            time.sleep(min(1.5, max(0, deadline - time.monotonic())))
        raise TimeoutError('Actual cup caption did not settle on the current landing')
    except Exception as error:
        report.update(status='FAIL', error=str(error))
        raise
    finally:
        report['elapsed_seconds'] = round(time.monotonic() - started, 6)
        journal.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')


def _return_stage_kart_menu(out: Path, tag: str, *, timeout: float = 120) -> dict:
    """Observe the section/footer and the real landing; a press is never a return."""
    if type(timeout) not in (int, float) or not 0 < timeout <= 150:
        raise ValueError('Kart return requires a bounded positive observation deadline')
    started = time.monotonic()
    deadline = started + timeout
    journal = out / (tag + '-return-readiness.json')
    report = {'status': 'WAITING', 'timeout_seconds': timeout, 'touch_budget': 3,
              'frames': [], 'touches': [],
              'scope': 'Observed section/footer touches and confirmed landing; no race or gameplay PASS'}
    previous_footer = previous_landing = None
    footer_caption = landing_caption = None
    try:
        while time.monotonic() < deadline:
            name = f'{tag}-return-observation-{len(report["frames"])}'
            snapshot = probe.capture(out, name, timeout=deadline - time.monotonic())
            source = out / snapshot['file']
            frame = probe.inspect_surface(source, orientation='landscape')
            frame['state'] = 'unready'
            report['frames'].append(frame)
            if not frame['acceptable_for_target_sampling']:
                previous_footer = previous_landing = None
            else:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                rows = probe.image_lines(out, name, source_path=source, timeout=remaining)
                garage_evidence.demand(probe.digest(source) == frame['source_sha256'],
                                       'Current Kart return screenshot changed during observation')
                words = {garage_evidence.normalize(word) for row in rows
                         for word in row['text'].split()}
                # The existing direct sections expose Karts; the illustrated
                # landing exposes Fahrer/Garage instead. The full original cup
                # validator still owns landing geometry and ambiguity checks.
                if 'karts' not in words and {'fahrer', 'garage'} <= words:
                    choice = garage_evidence.stage_cup_target_observation(frame, rows)
                    if choice['caption'] != landing_caption:
                        previous_landing = None
                    observed = probe.target_observation(frame, choice['target']['bounds'],
                                                        previous_landing)
                    frame.update(state='landing', cup_choice=choice, target=observed)
                    previous_landing, landing_caption = observed, choice['caption']
                    previous_footer = None
                    if observed['stable_observed_target']:
                        report.update(status='PASS', landing_caption=choice['caption'],
                                      landing_frame_index=len(report['frames']) - 1)
                        last = report['touches'][-1] if report['touches'] else None
                        return {'caption': choice['caption'], 'readiness': journal.name,
                                'return_caption': last['caption'] if last else None,
                                'return_touch': last['point'] if last else None}
                elif {'fahrer', 'karts'} <= words:
                    frame['state'] = 'section'
                    previous_landing = None
                    exact = [row for row in rows
                             if probe.normalized(row['text']) == 'kartmenu']
                    # Preserve the historical Menu alias only when the full
                    # Kart-Menü caption is absent; never aim at part of a label.
                    matches = exact or [row for row in rows
                                        if probe.normalized(row['text']) == 'menu']
                    footer = []
                    for row in matches:
                        geometry = probe.target_observation(frame, row.get('bounds'))
                        garage_evidence.demand(geometry['target_geometry_valid'],
                                               'Invalid observed Kart return bounds')
                        if (row['bounds'][1] + row['bounds'][3]) / 2 >= frame['pixels'][1] * .6:
                            footer.append(row)
                    if not footer:
                        previous_footer = None
                        frame['reasons'].append('actual section return footer not observed')
                    else:
                        selected = footer[0]
                        x0, y0, x1, y1 = selected['bounds']
                        for row in footer[1:]:
                            a0, b0, a1, b1 = row['bounds']
                            overlap = max(0, min(x1, a1) - max(x0, a0)) * max(
                                0, min(y1, b1) - max(y0, b0))
                            union = (x1 - x0) * (y1 - y0) + (a1 - a0) * (b1 - b0) - overlap
                            garage_evidence.demand(overlap / union >= .6,
                                                   'Ambiguous current Kart return targets')
                        caption = 'Kart-Menü' if exact else 'Menü'
                        if caption != footer_caption:
                            previous_footer = None
                        observed = probe.target_observation(frame, selected['bounds'], previous_footer)
                        frame.update(return_caption=caption, observed_caption=selected['text'],
                                     target=observed)
                        previous_footer, footer_caption = observed, caption
                        if observed['stable_observed_target']:
                            garage_evidence.demand(len(report['touches']) < report['touch_budget'],
                                'Spatial Kart section did not return after three observed footer gestures')
                            remaining = deadline - time.monotonic()
                            if remaining <= 0:
                                break
                            point = [round((x0 + x1) / 2), round((y0 + y1) / 2)]
                            touch = {'status': 'REQUESTED', 'caption': caption,
                                     'point': point, 'bounds': observed['bounds'],
                                     'source_sha256': frame['source_sha256'],
                                     'frame_index': len(report['frames']) - 1, 'duration_ms': 120}
                            report['touches'].append(touch)
                            # Same observed120ms stationary gesture as the
                            # successful current Garage/Comet/Gecko touches.
                            base.adb('shell', 'input', 'swipe', str(point[0]), str(point[1]),
                                     str(point[0]), str(point[1]), '120', timeout=min(15, remaining))
                            touch['status'] = 'TOUCH_SENT'
                            # A possible retry needs two NEW section frames.
                            # Observe after the final allowed gesture as well.
                            previous_footer = None
                else:
                    frame['state'] = 'unknown'
                    frame['reasons'].append('neither current section nor actual landing observed')
                    previous_footer = previous_landing = None
            time.sleep(min(1.5, max(0, deadline - time.monotonic())))
        raise TimeoutError('Actual Kart landing was not observed after the section return')
    except Exception as error:
        report.update(status='FAIL', error=str(error))
        raise
    finally:
        report['elapsed_seconds'] = round(time.monotonic() - started, 6)
        journal.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')


def _inspect_spatial_kart_menu(out: Path) -> dict:
    """Use the 2017 mode and direct sections through their actual rendered labels."""
    mode = _stage_cup_text(out, '21_stage_mode_cup', tap=True)
    sections = []
    selection_touches = []
    for key, label in (('garage', 'Garage'), ('driver', 'Fahrer')):
        tag = '21_stage_' + key
        probe.native_text(out, label, tag + '-open', tap=True, exact=True)
        # Karts is a direct-section tab; it is absent from the landing. This
        # also works on compact layouts where the large section title hides.
        probe.native_text(out, 'Karts', tag + '-section-visible', exact=True)
        if key == 'garage':
            for kart in ('comet', 'gecko_velo'):
                selection_touches.append(_select_stage_kart(out, kart))
        else:
            # A retained setup may contain another driver. Select the original
            # free Lumo card explicitly before requiring fox in the real save.
            selection_touches.append(_select_stage_driver(out))
        landing = _return_stage_kart_menu(out, tag)
        sections.append({'section': key, 'visible_label': label,
                         'return_caption': landing['return_caption'],
                         'return_touch': landing['return_touch'],
                         'return_evidence': landing['readiness'],
                         'landing_caption': landing['caption'],
                         'touch_evidence': tag + '-open-surface-readiness.json'})
    report = {'status': 'PASS', 'selected_mode': 'cup', 'sections': sections,
              'selection_touches': selection_touches, 'expected_kart': 'gecko_velo',
              'mode_caption': mode['caption'], 'mode_touch_evidence': mode['readiness'],
              'scope': 'Live Android OCR touches; no injected Godot selection or coordinates'}
    (out / '21_stage_navigation.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


def _previous_kart_race_id(out: Path) -> str | None:
    paths = [line.strip() for line in base.adb(
        'shell', 'find', f'/data/user/0/{PACKAGE}', '-maxdepth', '12', '-type', 'f',
        '-name', SESSION_NAME).splitlines() if line.strip().endswith(SESSION_NAME)]
    if not paths:
        return None
    if len(paths) != 1:
        raise RuntimeError('Expected at most one previous saved Kart race')
    raw = base.adb('exec-out', 'cat', paths[0], timeout=60)
    (out / '21_before_garage-session.cfg').write_text(raw)
    identity = complete.parse_session(raw).get('result_id')
    garage_evidence.demand(isinstance(identity, str) and bool(identity),
                           'Previous saved Kart race has no valid identity')
    return identity


def _confirm_stage_selection(out: Path, mode: str, track: str, kart: str,
                              previous_id: str | None) -> dict:
    session = RaceSession(out, expected_mode=mode, expected_track=track)
    state = wait_race_running(session, selected_kart=kart, previous_id=previous_id)
    report = {key: state[key] for key in ('result_id', 'selected_kart', 'selected_driver',
                                          'mode', 'track_id', 'countdown', 'elapsed', 'distance')}
    report['previous_result_id'] = previous_id
    (out / '21_stage_confirmed_selection.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


def _start_actual_embedded_race(out: Path) -> dict:
    if not godot_alive():
        raise RuntimeError('Native Godot game process is not alive')
    evidence_taps = []
    garage_fifth = None
    spatial_navigation = None
    previous_id = None
    if os.environ.get('LUMO_NATIVE_STAGE_MENU') == '1':
        previous_id = _previous_kart_race_id(out)
        spatial_navigation = _inspect_spatial_kart_menu(out)
    # NextGen Android opens the real illustrated landing before the preserved
    # five-step garage. The real golden START starts the race directly.
    # Recognise its text from an actual screenshot; do not inject an
    # unverified coordinate or claim a race merely because the game is alive.
    premium_start = None
    for attempt in range(8):
        screen = _screencap()
        (out / '21_kart_premium_start.png').write_bytes(screen)
        premium_start = _read_garage_footer(screen, 'START')
        if premium_start is not None:
            garage_fifth = screen
            base.adb('shell', 'input', 'tap',
                     str(premium_start[0]), str(premium_start[1]))
            evidence_taps.append({
                'step': 'premium-start', 'button': 'START', 'tap': premium_start,
            })
            time.sleep(2)
            break
        time.sleep(1)
    if premium_start is None:
        # Older/compatibility builds still expose the verified five-step
        # wizard. Require each actual Android-rendered button explicitly.
        for index in range(5):
            wanted = 'Weiter' if index < 4 else 'Rennen starten'
            for attempt in range(12):
                png = _screencap()
                capture = out / f'21_kart_garage_step_{index + 1}.png'
                capture.write_bytes(png)
                point = _read_garage_footer(png, wanted)
                if point is not None:
                    if index == 4:
                        garage_fifth = png
                    base.adb('shell', 'input', 'tap',
                             str(point[0]), str(point[1]))
                    evidence_taps.append({
                        'step': index + 1, 'button': wanted, 'tap': point,
                    })
                    time.sleep(2)
                    break
                time.sleep(1)
            else:
                raise RuntimeError(
                    f'Missing Android kart footer at step {index + 1}: {wanted}'
                )
    (out / '21_kart_real_touches.json').write_text(json.dumps(evidence_taps, indent=2))
    if garage_fifth is None:
        raise RuntimeError('Last garage image was not captured')

    # Godot logs belong to a separate :lumo_game process, not Flutter.
    # The production premium landing defaults to Grand Prix (cup); the
    # compatibility wizard defaults to a single race. Bind every later gate
    # to this actual UI path, never accept an arbitrary saved mode.
    expected_mode = 'cup' if premium_start is not None else 'race'
    expected_track = 'sonnenhafen'
    deadline = time.monotonic() + 55
    last_error = 'race_world_ready marker not observed'
    while time.monotonic() < deadline:
        if not godot_alive():
            raise RuntimeError('Godot quit before showing the race')
        screen = _screencap()
        (out / '21_lumo_kart_real_race.png').write_bytes(screen)
        log = base.adb('logcat', '-d', '-v', 'brief', timeout=60, check=False)
        expected_marker = (r'\[Kart\] race_world_ready: ' + re.escape(expected_track)
                           + r' mode=' + re.escape(expected_mode) + r'(?:\s|$)')
        if re.search(expected_marker, log):
            try:
                report = {'touches': evidence_taps,
                          'expected_mode': expected_mode, 'expected_track': expected_track,
                          'garage_replaced': evidence.garage_replaced(garage_fifth, screen),
                          'rendered_frame': evidence.rendered_race_frame(screen)}
            except RuntimeError as error:
                last_error = str(error)
            else:
                # A wrong newly persisted vehicle/identity is a hard failure,
                # not a loading frame to discard and retry from scratch.
                if spatial_navigation is not None:
                    report['spatial_menu_navigation'] = spatial_navigation
                    report['confirmed_selection'] = _confirm_stage_selection(
                        out, expected_mode, expected_track, spatial_navigation['expected_kart'], previous_id)
                (out / '21_kart_race_frame_check.json').write_text(json.dumps(report, indent=2))
                return report
        time.sleep(2)
    raise RuntimeError(f'Native Android kart race did not visibly replace the garage: {last_error}')


class RaceSession:
    """READ ONLY access to the race session the game itself persists."""

    def __init__(self, out: Path, *, expected_mode: str = 'race',
                 expected_track: str = 'sonnenhafen', expected_kart: str | None = None,
                 expected_result_id: str | None = None):
        self.out = out
        self.expected_mode = expected_mode
        self.expected_track = expected_track
        self.expected_kart = expected_kart
        self.expected_result_id = expected_result_id
        self.path: str | None = None

    def in_folder(self, out: Path) -> 'RaceSession':
        out.mkdir(parents=True, exist_ok=True)
        scoped = RaceSession(out, expected_mode=self.expected_mode, expected_track=self.expected_track,
                             expected_kart=self.expected_kart, expected_result_id=self.expected_result_id)
        scoped.path = self.path
        return scoped

    def read(self, tag: str, *, validate: bool = True) -> dict:
        if self.path is None:
            found = [line.strip() for line in base.adb(
                'shell', 'find', f'/data/user/0/{PACKAGE}', '-maxdepth', '12', '-type', 'f',
                '-name', SESSION_NAME, check=False).splitlines() if line.strip().endswith(SESSION_NAME)]
            if len(found) != 1:
                raise RuntimeError(f'Expected one persisted Kart race session, found {found}')
            self.path = found[0]
        raw = base.adb('exec-out', 'cat', self.path, timeout=60)
        (self.out / f'{tag}-session.cfg').write_text(raw)
        state = complete.parse_session(raw)
        if not validate:
            # The selection-start observer must distinguish the previous
            # saved race from a wrong NEW race before enforcing its identity.
            return state
        evidence.require_race_session(state, mode=self.expected_mode, track=self.expected_track)
        if self.expected_kart is not None:
            garage_evidence.require_selected_race(state, self.expected_kart,
                                                  mode=self.expected_mode, track=self.expected_track)
        if self.expected_result_id is not None and state['result_id'] != self.expected_result_id:
            raise RuntimeError('Native snapshot changed the confirmed Garage race identity')
        return state


def wait_race_running(session: RaceSession, timeout: float = 150, *,
                      selected_kart: str | None = None, previous_id: str | None = None) -> dict:
    """The countdown is over and the saved race clock has run for a second."""
    deadline = time.monotonic() + timeout
    attempt, last = 0, 'no session read yet'
    observed_new_id = None
    while time.monotonic() < deadline:
        if not godot_alive():
            raise RuntimeError('Godot quit before the race clock started')
        try:
            state = (session.read(f'21_race_running_{attempt}', validate=False)
                     if selected_kart is not None else session.read(f'21_race_running_{attempt}'))
        except RuntimeError as error:
            if getattr(session, 'expected_result_id', None) is not None:
                # Once the selected race has been confirmed, a different or
                # unreadable snapshot is no longer an initial loading state.
                raise
            last = str(error)
        else:
            if selected_kart is not None:
                observed_new_id, ready = garage_evidence.selected_race_readiness(
                    state, selected_kart, previous_id, observed_new_id,
                    mode=session.expected_mode, track=session.expected_track)
            else:
                ready = evidence.race_running(state, mode=session.expected_mode, track=session.expected_track)
            if ready:
                return state
            last = {key: state[key] for key in ('countdown', 'elapsed', 'distance')}
        attempt += 1
        time.sleep(2)
    raise RuntimeError(f'Saved race never showed a running race clock: {last}')


def _pause_actual_race(out: Path, session: RaceSession, identity: str) -> dict:
    scoped = session.in_folder(out)
    base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK', check=False)
    probe.native_text(out, 'Eine kleine Pause', '21_pause_title')
    probe.native_text(out, 'Weiterfahren', '21_pause_resume', exact=True)
    probe.capture(out, '21_lumo_kart_pause')
    paused = scoped.read('21_pause_first')
    if paused['result_id'] != identity:
        raise RuntimeError('The pause belongs to a different race')
    time.sleep(3)
    frozen = evidence.paused_unchanged(paused, scoped.read('21_pause_second'),
                                      mode=session.expected_mode, track=session.expected_track)
    return {'frozen_while_paused': frozen, 'state': paused}


def _continue_actual_race(out: Path, session: RaceSession, paused: dict) -> dict:
    scoped = session.in_folder(out)
    kart = scoped.expected_kart
    garage_evidence.require_selected_race(paused, kart,
                                          mode=scoped.expected_mode, track=scoped.expected_track)
    probe.native_text(out, 'Weiterfahren', '21_continue_touch', tap=True, exact=True)
    journal = out / '21_continue_touch-surface-readiness.json'
    touch = json.loads(journal.read_text())
    garage_evidence.demand(touch.get('status') == 'TOUCH_SENT',
                           'Continue was not pressed through an observed native control')
    # Resume does not write an immediate snapshot. Require the real racing
    # HUD, physical GAS input, changing pixels and a later native save.
    hud = wait_race_hud(out)
    drive = drive_with_gas(out, find_gas(out, hud['capture']), scoped, paused)
    resumed = scoped.read('21_after_continue')
    progress = garage_evidence.require_resumed_progress(
        paused, resumed, kart, mode=scoped.expected_mode, track=scoped.expected_track)
    report = {'touch': touch['touch'], 'touch_evidence': journal.name,
              'hud': hud, 'drive': drive, 'progress': progress}
    (out / '21_continue-result.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


def wait_race_hud(out: Path, timeout: float = 90) -> dict:
    """Current screenshot: rendered 3D scene plus the in-race HUD, no pause/result."""
    deadline = time.monotonic() + timeout
    attempt, last = 0, ''
    while time.monotonic() < deadline:
        name = f'21_race_hud_{attempt}'
        screen = _shot(out, name)
        frame = read_frame(out / (name + '.png'))
        last = frame['text'][:300]
        # The original 1978 emulator PNG visibly contains RUNDE 1/2,
        # PLATZ 6/6 and km/h, yet full-frame OCR omitted the first token.
        # Re-read only the real top HUD pixels with Tesseract psm 7.
        # This is NOT a bypass: the native save was already verified as
        # countdown=0 with an advancing race clock, and the existing GAS
        # distance + changing-world gates remain mandatory downstream.
        focus = None
        if not race_view_visible(frame):
            focus_text = focused_race_hud_text(out / (name + '.png'))
            focus = {
                'ocr': focus_text,
                'three_hud_indicators': focused_race_hud_visible(focus_text),
                'not_paused_or_finished': not any(
                    race_marker(frame, caption) for caption in
                    ('Weiterfahren', 'Kleine Pause', 'geschafft', 'Noch ein Rennen')),
            }
            (out / (name + '-focused-hud.json')).write_text(
                json.dumps(focus, ensure_ascii=False, indent=2) + '\n')
        if race_view_visible(frame) or (
            focus is not None
            and focus['three_hud_indicators']
            and focus['not_paused_or_finished']
        ):
            (out / '21_race_hud.png').write_bytes(screen)
            try:
                state = race_state(frame)
            except RuntimeError:
                state = None
            return {'capture': name, 'race_state': state,
                    'rendered_frame': evidence.rendered_race_frame(screen),
                    'hud_lines': [line['text'] for line in frame['lines']
                                  if any(word in line['text'].upper() for word in ('RUNDE', 'PLATZ', 'KM/H'))][:6],
                    'focused_hud': focus}
        attempt += 1
        time.sleep(1)
    raise RuntimeError(f'No current race HUD (RUNDE) was observed. Last OCR: {last!r}')


def find_gas(out: Path, name: str) -> tuple[int, int]:
    """The visible GAS caption's own OCR bounds; never a fixed coordinate."""
    source = out / (name + '.png')
    with Image.open(source) as image:
        width, height = image.size
    lines = probe.image_lines(out, name + '-gas', 'gas', source_path=source, exact=True)
    matches = []
    for line in lines:
        if probe.normalized(line['text']) != 'gas':
            continue
        x0, y0, x1, y1 = line['bounds']
        x, y = (x0 + x1) / 2, (y0 + y1) / 2
        if x > width * .5 and y > height * .5:
            matches.append((y, x))
    if not matches:
        raise RuntimeError('The GAS button caption is not visible in the race HUD')
    y, x = max(matches)
    return round(x), round(y)


def drive_with_gas(out: Path, point: tuple[int, int], session: 'RaceSession', start: dict,
                   hold_ms: int = 9000) -> dict:
    """Prove *physical* driving on a slow software-rendered Android emulator.

    Godot persists its session every 5 seconds of simulated race time, not
    Android wall time. One 7-second ADB hold plus a 30-second wall-clock poll
    can therefore read an unchanged save although the race is alive. We never
    inject or modify save data, never lower the 8m/2.5s threshold and never
    infer an actual drive from an animated HUD alone. Repeat bounded *real*
    GAS holds and archive the intermediate read-only telemetry.
    """
    before = _shot(out, '21_race_before_gas')
    x, y = map(str, point)
    samples = []
    late = before
    last = start
    for pulse in range(3):
        if not godot_alive():
            raise RuntimeError('Godot exited during the actual GAS touch test')
        holding = subprocess.Popen(
            ['adb', 'shell', 'input', 'swipe', x, y, x, y, str(hold_ms)])
        try:
            time.sleep(hold_ms / 1000 * .45)
            _shot(out, f'21_race_driving_mid_{pulse}')
            time.sleep(hold_ms / 1000 * .40)
        finally:
            return_code = holding.wait(timeout=hold_ms / 1000 + 30)
        if return_code:
            raise RuntimeError(f'Android GAS input swipe exited {return_code}')
        late = _shot(out, f'21_race_driving_late_{pulse}')
        # The save may still be from the previous five seconds of in-game
        # physics. Each snapshot and its speed are archived independently.
        last = session.read(f'21_race_after_gas_pulse_{pulse}')
        sample = {
            'pulse': pulse + 1, 'distance': last['distance'],
            'elapsed': last['elapsed'], 'speed': last['speed'],
            'distance_gain': round(last['distance'] - start['distance'], 3),
            'elapsed_gain': round(last['elapsed'] - start['elapsed'], 3),
        }
        samples.append(sample)
        print('[KartDriveSample] ' + json.dumps(sample, sort_keys=True),
              flush=True)
        if (sample['distance_gain'] >= 8.0 and
                sample['elapsed_gain'] >= 2.5):
            break

    # Bounded post-input wait: the native save must catch up after the
    # simulator has processed the touch and physics frames.
    deadline, index = time.monotonic() + 90, 0
    while (last['distance'] - start['distance'] < 8 or
           last['elapsed'] - start['elapsed'] < 2.5) and time.monotonic() < deadline:
        if not godot_alive():
            raise RuntimeError('Godot exited while awaiting persisted GAS progress')
        time.sleep(3)
        last = session.read(f'21_race_after_gas_poll_{index}')
        sample = {
            'poll': index + 1, 'distance': last['distance'],
            'elapsed': last['elapsed'], 'speed': last['speed'],
            'distance_gain': round(last['distance'] - start['distance'], 3),
            'elapsed_gain': round(last['elapsed'] - start['elapsed'], 3),
        }
        samples.append(sample)
        print('[KartDriveSample] ' + json.dumps(sample, sort_keys=True),
              flush=True)
        index += 1

    # Both the moving world *and* same-race actual persisted drive must pass.
    # This intentionally preserves the original hard failure on a stuck kart.
    moved = evidence.world_moved(before, late)
    frame = evidence.rendered_race_frame(late)
    try:
        progress = evidence.driving_progress(start, last, mode=session.expected_mode, track=session.expected_track)
    except RuntimeError as error:
        (out / '21_race_drive_telemetry.json').write_text(
            json.dumps({'gas_touch': list(point), 'hold_ms': hold_ms,
                        'samples': samples, 'failure': str(error)},
                       ensure_ascii=False, indent=2))
        raise RuntimeError(
            f'{error}; ADB GAS held in {len([s for s in samples if "pulse" in s])} '
            f'physical pulses; final native speed={last["speed"]}; '
            f'see 21_race_drive_telemetry.json') from error
    (out / '21_race_drive_telemetry.json').write_text(
        json.dumps({'gas_touch': list(point), 'hold_ms': hold_ms,
                    'samples': samples, 'native_progress': progress},
                   ensure_ascii=False, indent=2))
    return {'gas_touch': list(point), 'hold_ms': hold_ms,
            'gas_pulses': len([s for s in samples if 'pulse' in s]),
            'world_moved': moved, 'rendered_frame': frame,
            'native_progress': progress}


def log_images(out: Path) -> None:
    """Print downscaled JPEG copies of real screenshots for log-only reviewers."""
    for name in LOG_IMAGES:
        path = out / (name + '.png')
        if not path.exists():
            continue
        raw = path.read_bytes()
        image = Image.open(io.BytesIO(raw)).convert('RGB')
        size = image.size
        image.thumbnail((960, 960))
        buffer = io.BytesIO()
        image.save(buffer, format='JPEG', quality=72)
        data = base64.b64encode(buffer.getvalue()).decode()
        chunks = [data[index:index + 4000] for index in range(0, len(data), 4000)]
        print(f'[TourImage] {name} png_sha256={probe.digest(path)} png_size={size[0]}x{size[1]} '
              f'jpeg_size={image.size[0]}x{image.size[1]} parts={len(chunks)}', flush=True)
        for index, chunk in enumerate(chunks):
            print(f'[TourImage:{name}:{index}] {chunk}', flush=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--provenance', type=Path, required=True)
    parser.add_argument('--sums', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result: dict = {'status': 'RUNNING', 'apk_sha256': probe.digest(args.apk),
                    'steps': [], 'not_tested': [
                        'physical Samsung Fold', 'device GPU frame times / 60 FPS',
                        'audio output', 'complete two-lap race and reward (kart_complete_android_probe)']}

    def step(name: str, ok: bool, **extra) -> None:
        entry = {'step': name, 'ok': ok, **extra}
        result['steps'].append(entry)
        (out / 'tour-result.json').write_text(json.dumps(result, indent=2))
        print('[TourEvidence]', json.dumps(entry, ensure_ascii=False)[:1500], flush=True)

    def attempt(name: str, action) -> dict | None:
        """Run one checked phase; record a failure and continue the tour."""
        try:
            report = action() or {}
            step(name, True, **report)
            return report
        except Exception as error:  # Every failure stays in the report.
            step(name, False, error=f'{type(error).__name__}: {error}'[:1200])
            return None

    try:
        identity = attempt('apk-identity', lambda: verify_apk_identity(
            args.apk, args.provenance, args.sums))
        if identity is None:
            raise RuntimeError('Refusing to tour an APK that is not the verified build')
        result['emulator_root_readiness'] = probe.ensure_rooted_emulator(base.adb, out)
        result['android_sdk'] = base.adb('shell', 'getprop', 'ro.build.version.sdk').strip()
        base.adb('logcat', '-c', check=False)
        base.display(1080, 2400, 420)
        install = base.adb('install', '-r', '--no-streaming', str(args.apk), timeout=300)
        (out / 'install.txt').write_text(install)
        if 'Success' not in install:
            raise RuntimeError('APK installation failed')
        package = probe.package_identity(out, 'installed')
        # dumpsys prints "versionCode=1957 minSdk=24 targetSdk=36" on one line.
        if int(package['versionCode'].split()[0]) != identity['versionCode']:
            raise RuntimeError(f'Installed versionCode {package} differs from the verified APK')
        result['installed_package'] = package
        started = time.monotonic()
        base.launch(out, 'cold-start')
        result['cold_start_seconds_until_foreground'] = round(time.monotonic() - started, 1)
        probe.capture(out, '01_erster_start')
        step('launch', True)

        onboarding = probe.onboard(out)  # Captures 07_home and 08_games.
        step('onboarding', onboarding.get('status') == 'PASS')

        tapped = try_tap(out, ['Start', 'Home'], 'nav-start')
        time.sleep(2)
        probe.capture_flutter_ready(out, '10_start')
        step('navigate-start', tapped is not None, label=tapped)
        # The child must be able to reach the shipped atelier in the
        # actual installed APK, not merely pass Flutter widget screenshots.
        # Returning to Start is necessary before the existing Kart journey.
        attempt('atelier-roundtrip', lambda: _atelier_roundtrip(out))
        tapped = try_tap(out, ['Lernen'], 'nav-lernen')
        time.sleep(2)
        lernen_before = labels(live.live_nodes(out, 'lernen-before-kart'))
        probe.capture_flutter_ready(out, '10_lernen')
        step('navigate-lernen', tapped is not None and bool(lernen_before), label=tapped,
             visible_labels=len(lernen_before))

        tapped = try_tap(out, ['Spielen', 'Spiele'], 'nav-spiele')
        time.sleep(2)
        probe.capture_flutter_ready(out, '20_spiele')
        step('navigate-spiele', tapped is not None, label=tapped)
        prefs_before = probe.prefs(out, 'before-kart')
        if json.loads(prefs_before.get(evidence.PROFILE_KEY, '{}')).get('name') != 'LumoTest':
            raise RuntimeError('The onboarded child profile LumoTest is not stored')

        kart = try_tap(out, [
            'Lumo Kart. Fahre mit Lumo um die Wette! Spielen',
            'Losfahren', 'Rennen starten',
        ], 'open-kart')
        race_started = False
        race_launch = None
        if kart is not None:
            # The embedded Godot engine needs time on the software renderer.
            for wait in (12, 20):
                time.sleep(wait)
                probe.capture(out, f'21_lumo_kart_{wait}s')
            step('open-kart', godot_alive(), label=kart)
            race_launch = attempt('start-kart-race', lambda: _start_actual_embedded_race(out))
            race_started = race_launch is not None
        else:
            step('open-kart', False, label=None)

        confirmed = race_launch.get('confirmed_selection') if race_launch else None
        session = RaceSession(out,
            expected_mode=race_launch['expected_mode'] if race_launch else 'race',
            expected_track=race_launch['expected_track'] if race_launch else 'sonnenhafen',
            expected_kart=confirmed['selected_kart'] if confirmed else None,
            expected_result_id=confirmed['result_id'] if confirmed else None)
        running: dict = {}

        def race_clock() -> dict:
            running.update(wait_race_running(session))
            return {'state': {key: running[key] for key in (
                'result_id', 'countdown', 'elapsed', 'distance', 'checkpoint_index')}}

        if race_started and attempt('race-running', race_clock) is not None:
            start_state = dict(running)
            hud = attempt('race-hud', lambda: wait_race_hud(out))
            if hud is not None:
                attempt('race-drive', lambda: drive_with_gas(
                    out, find_gas(out, hud['capture']), session, start_state))

            def pause() -> dict:
                paused = _pause_actual_race(out, session, start_state['result_id'])
                if session.expected_kart is not None:
                    paused['continued'] = _continue_actual_race(out / '21_continue', session, paused['state'])
                    # Keep the established Android Back → Flutter path after
                    # proving Continue, by opening the actual pause a second time.
                    paused['paused_after_continue'] = _pause_actual_race(
                        out / '21_pause_after_continue', session, start_state['result_id'])
                return paused

            attempt('pause-menu', pause)

        def return_to_flutter() -> dict:
            # Back while paused hands the session back to Flutter. Whatever
            # happened before, leave the game the way a child would.
            for _ in range(3):
                try:
                    current = base.foreground()
                except RuntimeError:  # No resumed activity during the rotation.
                    current = ''
                if PACKAGE in current and 'LumoGameActivity' not in current:
                    break
                if 'LumoGameActivity' in current:
                    base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK', check=False)
                time.sleep(4)
            shot = probe.flutter_return_capture(out, '23_zurueck_in_flutter')
            returned = Image.open(out / '23_zurueck_in_flutter.png')
            if not alive() or returned.height <= returned.width:
                raise RuntimeError('Flutter is not visible in portrait after the Kart')
            return {'capture': shot['file'], 'foreground_is_flutter': True}

        if kart is not None:
            attempt('return-from-kart', return_to_flutter)

        attempt('learning-state-after-kart', lambda: evidence.learning_preserved(
            prefs_before, probe.prefs(out, 'after-kart')))

        def lernen_usable() -> dict:
            if try_tap(out, ['Lernen'], 'nav-lernen-after-kart') is None:
                raise RuntimeError('The Lernen tab is not tappable after the Kart')
            time.sleep(2)
            after = labels(live.live_nodes(out, 'lernen-after-kart'))
            probe.capture(out, '24_lernen_nach_kart')
            return evidence.labels_still_present(lernen_before, after)

        attempt('lernen-usable-after-kart', lernen_usable)

        def profile_visible() -> dict:
            if try_tap(out, ['Start', 'Home'], 'nav-start-after-kart') is None:
                raise RuntimeError('The Start tab is not tappable after the Kart')
            time.sleep(2)
            # Flutter intentionally preserves the Start scroll position. After
            # visiting the atelier at the foot of Start, the greeting is out
            # of view. A missing off-screen semantics label is not evidence
            # of lost profile data. Check actual on-screen greeting by moving
            # the live scrollable content toward its top, no fake profiles.
            for index in range(12):
                nodes = live.live_nodes(out, f'start-after-kart-{index}')
                if 'LumoTest' in base.accessible_text(nodes):
                    probe.capture(out, '25_start_nach_kart')
                    return {
                        'profile_name_visible': 'LumoTest',
                        'observed_after_scrolls': index,
                        'source': 'live Android accessibility tree',
                    }
                scrolls = []
                for node in nodes:
                    if node.get('package') != PACKAGE or node.get('scrollable') != 'true':
                        continue
                    bounds = list(map(int, re.findall('[0-9]+', node.get('bounds', ''))))
                    if len(bounds) == 4:
                        x0, y0, x1, y1 = bounds
                        if x1 > x0 and y1 > y0:
                            scrolls.append(((x1 - x0) * (y1 - y0), x0, y0, x1, y1))
                if not scrolls:
                    break
                _, x0, y0, x1, y1 = max(scrolls)
                x = str((x0 + x1) // 2)
                top = str(y0 + (y1 - y0) // 5)
                bottom = str(y0 + (y1 - y0) * 4 // 5)
                base.adb('shell', 'input', 'swipe', x, top, x, bottom, '390')
                time.sleep(1)
            probe.capture(out, '25_start_nach_kart_greeting_missing')
            raise RuntimeError(
                'The child greeting is missing from the actual Start accessibility '
                'tree even after scrolling to its top; check profile rendering')

        attempt('profile-after-kart', profile_visible)

        def restart() -> dict:
            base.adb('shell', 'am', 'force-stop', PACKAGE)
            time.sleep(2)
            base.launch(out, 'restart-after-kart')
            for index in range(30):
                if 'LumoTest' in base.accessible_text(live.live_nodes(out, f'restart-{index}')):
                    break
                time.sleep(1)
            else:
                raise RuntimeError('The child profile did not load after an app restart')
            probe.capture(out, '26_neustart')
            return evidence.learning_preserved(prefs_before, probe.prefs(out, 'after-restart'))

        attempt('restart-keeps-learning-state', restart)

        for name, (w, h, d) in (
            ('fold_offen', (1812, 2176, 420)),
            ('fold_aussen', (904, 2316, 420)),
            ('quer', (2400, 1080, 420)),
        ):
            base.display(w, h, d)
            time.sleep(4)
            probe.capture(out, f'30_{name}')
            step(f'display-{name}', alive(), size=f'{w}x{h}@{d}')
        base.display(1080, 2400, 420)

        fatal = logcat_fatal()
        (out / 'fatal-logcat.txt').write_text('\n\n'.join(fatal))
        result['fatal_crashes'] = len(fatal)
        hard = [s['step'] for s in result['steps'] if not s['ok'] and s['step'] in HARD_STEPS]
        missing = [name for name in HARD_STEPS if not any(s['step'] == name for s in result['steps'])]
        if fatal or hard or missing or not alive():
            raise RuntimeError(f'Hard failure: crashes={len(fatal)} failed={hard} '
                               f'not_reached={missing} alive={alive()}')
        result['status'] = 'PASS'
    except Exception as error:  # Keep every observation for the report.
        result.update(status='FAIL', error=f'{type(error).__name__}: {error}',
                      traceback=traceback.format_exc())
        try:
            probe.capture(out, '99_fehler')
        except Exception:
            pass
    finally:
        try:
            log = subprocess.run(['adb', 'logcat', '-d'], capture_output=True,
                                 text=True, timeout=60).stdout
            (out / 'logcat.txt').write_text(log[-2_000_000:])
        except Exception:
            pass
        (out / 'tour-result.json').write_text(json.dumps(result, indent=2))
        print(json.dumps({k: result[k] for k in ('status', 'error', 'steps') if k in result},
                         indent=2, ensure_ascii=False), flush=True)
        try:
            log_images(out)
        except Exception as error:
            print('[TourImage] logging failed:', error, flush=True)
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
