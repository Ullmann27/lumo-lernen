#!/usr/bin/env python3
"""Tour the exact candidate APK on a disposable Android emulator.

Installs the APK, starts it, creates a fictional profile through the real
onboarding and walks the path a child takes: start, learning, games, Lumo Kart
(native Godot), the five garage steps, an actual race, pause, the return to
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
from kart_android_race import race_state, race_view_visible, read_frame  # noqa: E402

base = probe.base
live = probe.live
PACKAGE = probe.PACKAGE
SESSION_NAME = 'kart_sonnenhafen_session.cfg'
HARD_STEPS = (
    'apk-identity', 'launch', 'onboarding', 'navigate-start', 'navigate-lernen',
    'navigate-spiele', 'open-kart', 'start-kart-race', 'race-running', 'race-hud',
    'race-drive', 'pause-menu', 'return-from-kart', 'learning-state-after-kart',
    'lernen-usable-after-kart', 'profile-after-kart', 'restart-keeps-learning-state',
)
# Downscaled JPEG copies of these real screenshots are written to the job log
# (originals and their SHA-256 stay in the uploaded tour artifact).
LOG_IMAGES = (
    '07_home_after_onboarding', '08_games_after_navigation', '10_lernen', '20_spiele', '21_kart_garage_step_5',
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
            probe.flutter_tap(out, label, f'{tag}-{len(label)}',
                              scroll_attempts=10 if tag == 'open-kart' else 3)
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
    expected_source = os.environ.get('GITHUB_SHA') or base.command('git', 'rev-parse', 'HEAD').strip()
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
    min_hits = max(10, int(image.width * .02))
    gold_rows: list[tuple[int, int, int]] = []
    pixels = image.load()
    for row_y in range(int(image.height * .70), image.height, 3):
        matches = []
        for col_x in range(int(image.width * .70), image.width, 3):
            r, g, b = pixels[col_x, row_y]
            if r >= 205 and g >= 185 and b <= 185 and r - b > 40:
                matches.append(col_x)
        if len(matches) >= min_hits:
            gold_rows.append((row_y, min(matches), max(matches)))
    if len(gold_rows) >= 6:
        top = gold_rows[0][0]
        bottom = gold_rows[-1][0]
        left = min(row[1] for row in gold_rows)
        right = max(row[2] for row in gold_rows)
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
                if _simplify(expected) in caption:
                    return (left + right) // 2, (top + bottom) // 2
    return None


def _start_actual_embedded_race(out: Path) -> dict:
    if not godot_alive():
        raise RuntimeError('Native Godot game process is not alive')
    evidence_taps = []
    garage_fifth = None
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
                base.adb('shell', 'input', 'tap', str(point[0]), str(point[1]))
                evidence_taps.append({'step': index + 1, 'button': wanted, 'tap': point})
                time.sleep(2)
                break
            time.sleep(1)
        else:
            raise RuntimeError(f'Missing Android kart footer at step {index + 1}: {wanted}')
    (out / '21_kart_real_touches.json').write_text(json.dumps(evidence_taps, indent=2))
    if garage_fifth is None:
        raise RuntimeError('Last garage image was not captured')

    # Godot logs belong to a separate :lumo_game process, not Flutter.
    deadline = time.monotonic() + 55
    last_error = 'race_world_ready marker not observed'
    while time.monotonic() < deadline:
        if not godot_alive():
            raise RuntimeError('Godot quit before showing the race')
        screen = _screencap()
        (out / '21_lumo_kart_real_race.png').write_bytes(screen)
        log = base.adb('logcat', '-d', '-v', 'brief', timeout=60, check=False)
        if '[Kart] race_world_ready: sonnenhafen mode=race' in log:
            try:
                report = {'touches': evidence_taps,
                          'garage_replaced': evidence.garage_replaced(garage_fifth, screen),
                          'rendered_frame': evidence.rendered_race_frame(screen)}
                (out / '21_kart_race_frame_check.json').write_text(json.dumps(report, indent=2))
                return report
            except RuntimeError as error:
                last_error = str(error)
        time.sleep(2)
    raise RuntimeError(f'Native Android kart race did not visibly replace the garage: {last_error}')


class RaceSession:
    """READ ONLY access to the race session the game itself persists."""

    def __init__(self, out: Path):
        self.out = out
        self.path: str | None = None

    def read(self, tag: str) -> dict:
        if self.path is None:
            found = [line.strip() for line in base.adb(
                'shell', 'find', f'/data/user/0/{PACKAGE}', '-maxdepth', '12', '-type', 'f',
                '-name', SESSION_NAME, check=False).splitlines() if line.strip().endswith(SESSION_NAME)]
            if len(found) != 1:
                raise RuntimeError(f'Expected one persisted Kart race session, found {found}')
            self.path = found[0]
        raw = base.adb('exec-out', 'cat', self.path, timeout=60)
        (self.out / f'{tag}-session.cfg').write_text(raw)
        return complete.parse_session(raw)


def wait_race_running(session: RaceSession, timeout: float = 150) -> dict:
    """The countdown is over and the saved race clock has run for a second."""
    deadline = time.monotonic() + timeout
    attempt, last = 0, 'no session read yet'
    while time.monotonic() < deadline:
        if not godot_alive():
            raise RuntimeError('Godot quit before the race clock started')
        try:
            state = session.read(f'21_race_running_{attempt}')
            if evidence.race_running(state):
                return state
            last = {key: state[key] for key in ('countdown', 'elapsed', 'distance')}
        except RuntimeError as error:
            last = str(error)
        attempt += 1
        time.sleep(2)
    raise RuntimeError(f'Saved race never showed a running race clock: {last}')


def wait_race_hud(out: Path, timeout: float = 90) -> dict:
    """Current screenshot: rendered 3D scene plus the in-race HUD, no pause/result."""
    deadline = time.monotonic() + timeout
    attempt, last = 0, ''
    while time.monotonic() < deadline:
        name = f'21_race_hud_{attempt}'
        screen = _shot(out, name)
        frame = read_frame(out / (name + '.png'))
        last = frame['text'][:300]
        if race_view_visible(frame):
            (out / '21_race_hud.png').write_bytes(screen)
            try:
                state = race_state(frame)
            except RuntimeError:
                state = None
            return {'capture': name, 'race_state': state,
                    'rendered_frame': evidence.rendered_race_frame(screen),
                    'hud_lines': [line['text'] for line in frame['lines']
                                  if any(word in line['text'].upper() for word in ('RUNDE', 'PLATZ', 'KM/H'))][:6]}
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
        progress = evidence.driving_progress(start, last)
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

        kart = try_tap(out, ['Losfahren', 'Rennen starten'], 'open-kart')
        race_started = False
        if kart is not None:
            # The embedded Godot engine needs time on the software renderer.
            for wait in (12, 20):
                time.sleep(wait)
                probe.capture(out, f'21_lumo_kart_{wait}s')
            step('open-kart', godot_alive(), label=kart)
            race_started = attempt('start-kart-race', lambda: _start_actual_embedded_race(out)) is not None
        else:
            step('open-kart', False, label=None)

        session = RaceSession(out)
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
                # Back while driving opens the game's own pause menu.
                base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK', check=False)
                probe.native_text(out, 'Eine kleine Pause', '21_pause_title')
                probe.native_text(out, 'Weiterfahren', '21_pause_resume', exact=True)
                probe.capture(out, '21_lumo_kart_pause')
                paused = session.read('21_pause_first')
                evidence.require_race_session(paused)
                if paused['result_id'] != start_state['result_id']:
                    raise RuntimeError('The pause belongs to a different race')
                time.sleep(3)
                frozen = evidence.paused_unchanged(paused, session.read('21_pause_second'))
                return {'frozen_while_paused': frozen}

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
            text = base.accessible_text(live.live_nodes(out, 'start-after-kart'))
            probe.capture(out, '25_start_nach_kart')
            if 'LumoTest' not in text:
                raise RuntimeError('The child profile name is missing from Start after the Kart')
            return {'profile_name_visible': 'LumoTest'}

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
