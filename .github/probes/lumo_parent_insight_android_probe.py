#!/usr/bin/env python3
"""Elternkennzahlen „Lumo Insight“ in der echten Android-Oberfläche (API35-Wegwerf-Emulator).

Läuft nach modernization_android_tour.py (und optional nach der Sicherungsprobe) im selben
Emulator mit dem fiktiven Tour-Profil „LumoTest“ (1. Klasse). Keine echten Kinderdaten.

Ablauf, nur über sichtbare Bedienelemente:
1. Elternbereich → Elternbericht → „Lumo Insight“: Ausgangswerte lesen.
2. Lernen → Mathematik → „Plus bis 10“: sechs echte Antworten (eine falsch, danach richtig;
   eine nach „Tipp“, falls der Knopf erreichbar ist; sonst richtig ohne Hilfe).
3. Lumo Insight erneut: „Antworten“ = „Grundlage: N Antworten …“ aus „Auf einen Blick“
   (+ ältere Antworten), Zuwachs = beantwortete Aufgaben = neue Einträge im gespeicherten
   Aufgabenprotokoll, „X ohne Hilfe“ = „davon X ohne Hilfe“, „Lerntage in Folge“ ≥ 1.
4. ``am force-stop``, Neustart, Lumo Insight: dieselben Zahlen.

Gelesen wird die Bedienungshilfe-Hierarchie (uiautomator): Kacheln über ihre Semantik
„<Name>: <Wert>, <Hinweis>“ mit Bezeichner ``insight-stat-<kachel>``. Nur die Zeile aus
„Auf einen Blick“ hat einen OCR-Ersatzweg (Tesseract), falls sie in der Hierarchie fehlt.
Einstellungen und Aufgabenprotokoll werden NUR GELESEN; nichts wird eingespielt.

Nicht geprüft: echtes Gerät, Fold-Scharnier, ältere Zählerstände vor dem Aufgabenprotokoll
(nur Flutter-Test), Tonausgabe.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import time
import traceback

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools' / 'android_qa'))
import creative_android_probe as probe
from modernization_android_tour import verify_apk_identity
import lumo_local_backup_android_probe as backup
import parent_insight_reader as reader

base, live, PACKAGE = probe.base, probe.live, probe.PACKAGE
PROFILE = 'lumo_active_profile'
ATTEMPT_LOG = 'flutter.lumo_attempt_log_v1'
RESULT = 'parent-insight-result.json'
# Sechs Antworten: richtig; falsch und dann richtig (mit Hilfe gespeichert);
# „Tipp“ und dann richtig (mit Hilfe); zweimal richtig.
PLAN = ('correct', 'wrong-then-correct', 'hint-then-correct', 'correct', 'correct')
REQUIRED = ('apk-identity', 'fictional-profile', 'insight-before', 'answer-tasks',
            'insight-after', 'insight-restart')


def nodes(out: Path, tag: str) -> list:
    return [node for node in live.live_nodes(out, tag) if node.get('package') == PACKAGE]


def app_text(current: list) -> str:
    return '\n'.join(node.get('text', '') + '\n' + node.get('content-desc', '')
                     for node in current)


def swipe(current: list, direction: int) -> bool:
    """Im größten scrollbaren App-Bereich wischen: 1 = weiter nach unten, -1 = nach oben."""
    return backup.scroll_current(current, direction)


def scroll_to_top(out: Path, tag: str, swipes: int = 4) -> None:
    for index in range(swipes):
        if not swipe(nodes(out, f'{tag}-{index}'), -1):
            return


def ocr_text(path: Path) -> str:
    try:
        return subprocess.run(['tesseract', str(path), 'stdout', '-l', 'deu+eng', '--psm', '6'],
                              capture_output=True, text=True, timeout=90, check=True).stdout
    except (OSError, subprocess.SubprocessError):
        return ''


def read_insight(out: Path, tag: str, timeout: float = 60) -> dict:
    """Kacheln lesen, sobald keine mehr lädt; dann „Auf einen Blick“ suchen."""
    deadline = time.monotonic() + timeout
    attempt = 0
    tiles: dict = {}
    while time.monotonic() < deadline:
        current = nodes(out, f'{tag}-tiles-{attempt}')
        tiles = reader.read_tiles(current)
        if reader.is_settled(tiles):
            break
        attempt += 1
        time.sleep(1)
    else:
        probe.capture(out, tag + '-tiles-missing')
        raise RuntimeError('Kacheln nicht vollständig geladen: ' + json.dumps(
            {key: value['raw'] for key, value in tiles.items()}, ensure_ascii=False))
    evidence = {'tiles_hierarchy': f'{tag}-tiles-{attempt}.xml',
                'captures': [probe.capture(out, tag + '-kacheln')]}
    stats = reader.read_stats_basis(current)
    guidance = reader.read_guidance_basis(current)
    shots = []
    for index in range(8):
        if guidance is not None and stats is not None:
            break
        swipe(current, 1)
        time.sleep(.8)
        current = nodes(out, f'{tag}-scroll-{index}')
        stats = stats or reader.read_stats_basis(current)
        guidance = guidance or reader.read_guidance_basis(current)
        shots.append(probe.capture(out, f'{tag}-scroll-{index}'))
    if guidance is None:
        # Ersatzweg nur für diese Zeile: Tesseract auf den eben gemachten Bildern.
        for shot in shots:
            guidance = reader.read_guidance_basis_ocr(ocr_text(out / shot['file']))
            if guidance is not None:
                guidance['ocr_image'] = shot['file']
                break
    else:
        evidence['captures'].append(probe.capture(out, tag + '-auf-einen-blick'))
    evidence['scroll_captures'] = [shot['file'] for shot in shots]
    snap = reader.snapshot(tiles, stats, guidance)
    snap['evidence'] = evidence
    return snap


def open_insight(out: Path, tag: str) -> None:
    backup.parents(out, tag + '-parents')
    probe.flutter_tap(out, 'Lumo Insight', tag + '-cta', scroll_attempts=40,
                      direction_order=(1, -1), min_visible_height_px=48)


def cold_start(out: Path, tag: str) -> None:
    base.adb('shell', 'am', 'force-stop', PACKAGE)
    time.sleep(2)
    base.launch(out, tag)
    time.sleep(3)


def current_task(out: Path, tag: str, timeout: float = 30) -> dict:
    deadline = time.monotonic() + timeout
    attempt = 0
    while time.monotonic() < deadline:
        current = nodes(out, f'{tag}-{attempt}')
        task = reader.read_task(current)
        if task['round_continue']:
            probe.flutter_tap(out, task['round_continue'], f'{tag}-round-{attempt}',
                              min_visible_height_px=40)
        elif task['index'] is not None and task['correct'] is not None:
            return task
        else:
            swipe(current, -1)
        attempt += 1
        time.sleep(.8)
    probe.capture(out, tag + '-missing')
    raise RuntimeError('Aktuelle Aufgabe „Plus bis 10“ nicht sichtbar')


def wait_answer_enabled(out: Path, value: int, tag: str, timeout: float = 15) -> None:
    deadline = time.monotonic() + timeout
    attempt = 0
    while time.monotonic() < deadline:
        task = reader.read_task(nodes(out, f'{tag}-{attempt}'))
        if task['answers'].get(value):
            return
        attempt += 1
        time.sleep(.6)
    raise RuntimeError(f'Antwortkarte {value} wurde nicht wieder freigegeben')


def tap_answer(out: Path, value: int, tag: str) -> None:
    probe.flutter_tap(out, f'Antwort {value}', tag, scroll_attempts=10,
                      direction_order=(1, -1), min_visible_height_px=40)


def wait_next_task(out: Path, previous: int, tag: str, timeout: float = 30) -> dict:
    deadline = time.monotonic() + timeout
    attempt = 0
    while time.monotonic() < deadline:
        time.sleep(1)
        current = nodes(out, f'{tag}-{attempt}')
        task = reader.read_task(current)
        if task['round_continue']:
            probe.flutter_tap(out, task['round_continue'], f'{tag}-round-{attempt}',
                              min_visible_height_px=40)
        elif task['index'] is not None and task['index'] != previous:
            return task
        elif task['index'] is None:
            swipe(current, -1)
        attempt += 1
    probe.capture(out, tag + '-missing')
    raise RuntimeError(f'Nach Aufgabe {previous} kam keine neue Aufgabe')


def try_hint(out: Path, tag: str) -> bool:
    """„Tipp“ tippen und belegen, dass die Hilfe sichtbar ist („Anderer Tipp“)."""
    try:
        probe.flutter_tap(out, 'Tipp', tag, scroll_attempts=6, direction_order=(1, -1),
                          min_visible_height_px=40)
    except RuntimeError:
        return False
    for attempt in range(10):
        if 'Anderer Tipp' in app_text(nodes(out, f'{tag}-shown-{attempt}')):
            return True
        time.sleep(.6)
    return False


def answer_tasks(out: Path) -> dict:
    cold_start(out, 'lernen-start')
    probe.flutter_tap(out, 'Lernen', 'lernen')
    probe.flutter_tap(out, 'Mathematik', 'fach-mathematik', min_visible_height_px=40)
    for attempt in range(20):
        if 'Wähle ein Thema.' in app_text(nodes(out, f'thema-liste-{attempt}')):
            break
        time.sleep(1)
    else:
        raise RuntimeError('Themenliste Mathematik nicht sichtbar')
    probe.flutter_tap(out, 'Plus bis 10', 'thema-plus-bis-10', scroll_attempts=16,
                      direction_order=(1, -1), min_visible_height_px=40)
    submissions, captures, hint_reached = [], [], None
    task = current_task(out, 'aufgabe-0')
    captures.append(probe.capture(out, 'aufgabe-erste'))
    for number, step in enumerate(PLAN, start=1):
        tag = f'aufgabe-{number}'
        assisted = False
        if step == 'wrong-then-correct':
            wrong = reader.choose_distractor(task)
            tap_answer(out, wrong, tag + '-falsch')
            submissions.append({'task': task['index'], 'prompt': f'{task["a"]} + {task["b"]} = ?',
                                'given': wrong, 'correct': False, 'assisted': False})
            time.sleep(1.5)
            captures.append(probe.capture(out, tag + '-nach-falscher-antwort'))
            wait_answer_enabled(out, task['correct'], tag + '-wieder-frei')
            assisted = True  # richtig nach falscher Antwort = mit Hilfe gespeichert
        elif step == 'hint-then-correct':
            hint_reached = try_hint(out, tag + '-tipp')
            if hint_reached:
                captures.append(probe.capture(out, tag + '-tipp-sichtbar'))
            assisted = hint_reached
        tap_answer(out, task['correct'], tag + '-richtig')
        submissions.append({'task': task['index'], 'prompt': f'{task["a"]} + {task["b"]} = ?',
                            'given': task['correct'], 'correct': True, 'assisted': assisted})
        if number < len(PLAN):
            task = wait_next_task(out, task['index'], tag + '-weiter')
        else:
            time.sleep(3)  # letzte Antwort speichern lassen
            captures.append(probe.capture(out, 'aufgabe-letzte'))
    return {'submissions': submissions, 'hint_reached': hint_reached,
            'expected': reader.expected_from_submissions(submissions),
            'captures': [shot['file'] for shot in captures]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('apk', 'provenance', 'sums', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'steps': [],
              'scope': 'Echte API35-Oberfläche: Lernaufgaben → Elternbereich → Lumo Insight → Neustart',
              'not_tested': ['physisches Gerät / Fold-Scharnier',
                             'ältere Zählerstände vor dem Aufgabenprotokoll (nur Flutter-Test)',
                             'Tonausgabe']}
    phase = 'apk-identity'

    def save() -> None:
        (out / RESULT).write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')

    def passed(name: str, **details) -> None:
        result['steps'].append({'step': name, 'ok': True, **details})
        save()
        print('[ParentInsightEvidence]', name, 'PASS', flush=True)

    try:
        result['identity'] = verify_apk_identity(args.apk, args.provenance, args.sums)
        if base.adb('shell', 'getprop', 'ro.kernel.qemu') != '1' or base.adb(
                'shell', 'getprop', 'ro.build.version.sdk') != '35':
            raise RuntimeError('Diese Probe läuft nur im Wegwerf-Emulator API 35')
        result['emulator_root_readiness'] = probe.ensure_rooted_emulator(base.adb, out)
        result['installed'] = backup.installed_identity(out, result['identity'], 'before')
        passed(phase, installed_sha256=result['installed']['sha256'])

        phase = 'fictional-profile'
        initial = probe.prefs(out, 'initial')
        profile = backup.stored_json(initial, PROFILE, physical=True)
        if profile.get('name') != 'LumoTest':
            raise RuntimeError('Nur das fiktive Tour-Profil LumoTest ist erlaubt')
        if profile.get('grade') != 1:
            raise RuntimeError('„Plus bis 10“ setzt das Tour-Profil der 1. Klasse voraus')
        passed(phase, profile_name='LumoTest', grade=1)

        phase = 'insight-before'
        cold_start(out, 'vorher-start')
        open_insight(out, 'vorher')
        before = read_insight(out, 'vorher')
        log_before = probe.prefs(out, 'vorher-protokoll').get(ATTEMPT_LOG)
        result['before'] = before
        failures = reader.consistency_failures(before)
        if failures:
            raise RuntimeError('Ausgangswerte widersprüchlich: ' + '; '.join(failures))
        passed(phase, answers=before['answers'], guidance=before['guidance'],
               captures=[c['file'] for c in before['evidence']['captures']])

        phase = 'answer-tasks'
        lesson = answer_tasks(out)
        result['lesson'] = lesson
        log_after = probe.prefs(out, 'nachher-protokoll').get(ATTEMPT_LOG)
        delta = reader.attempt_log_delta(log_before, log_after)
        result['attempt_log_delta'] = delta
        if delta['count'] != lesson['expected']['count']:
            raise RuntimeError(f'Gespeichert {delta["count"]} neue Antworten statt '
                               f'{lesson["expected"]["count"]}')
        if (delta['assisted'] < 1 or delta['wrong'] != lesson['expected']['wrong']
                or delta['units'] != ['Mathematik · Plus bis 10']):
            raise RuntimeError('Falsche Antwort, Hilfenutzung oder Thema anders gespeichert: '
                               + json.dumps(delta, ensure_ascii=False))
        passed(phase, submissions=len(lesson['submissions']), hint_reached=lesson['hint_reached'],
               expected=lesson['expected'], stored=delta)

        phase = 'insight-after'
        base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        time.sleep(2)
        try:
            open_insight(out, 'nachher')
            result['after_navigation'] = 'ohne Neustart'
        except RuntimeError:
            cold_start(out, 'nachher-start')
            open_insight(out, 'nachher-kalt')
            result['after_navigation'] = 'Kaltstart (Elternbereich vom Lernbereich nicht erreichbar)'
        after = read_insight(out, 'nachher')
        result['after'] = after
        failures = reader.consistency_failures(after) + reader.answer_failures(
            before, after, lesson['submissions'], delta)
        if failures:
            raise RuntimeError('Kennzahlen nach den Aufgaben: ' + '; '.join(failures))
        passed(phase, answers=after['answers'], answers_hint=after['answers_hint'],
               streak=after['streak'], streak_hint=after['streak_hint'],
               strengths=after['strengths'], needs=after['needs'], guidance=after['guidance'],
               captures=[c['file'] for c in after['evidence']['captures']])

        phase = 'insight-restart'
        cold_start(out, 'neustart')
        open_insight(out, 'neustart')
        restarted = read_insight(out, 'neustart')
        result['restart'] = restarted
        failures = reader.consistency_failures(restarted) + reader.restart_failures(after, restarted)
        if failures:
            raise RuntimeError('Nach Neustart anders: ' + '; '.join(failures))
        passed(phase, answers=restarted['answers'], streak=restarted['streak'],
               captures=[c['file'] for c in restarted['evidence']['captures']])

        if [step['step'] for step in result['steps']] != list(REQUIRED):
            raise RuntimeError('Pflichtschritte unvollständig')
        result['status'] = 'PASS'
        return 0
    except Exception as error:
        result.update(status='FAIL', error=f'{type(error).__name__}: {error}')
        result['steps'].append({'step': phase, 'ok': False, 'error': str(error)})
        (out / 'failure-trace.txt').write_text(traceback.format_exc())
        try:
            probe.capture(out, 'parent-insight-failure')
            live.live_nodes(out, 'parent-insight-failure')
        except Exception as capture_error:
            result['failure_capture_error'] = str(capture_error)
        return 1
    finally:
        save()
        print('[ParentInsightResult]', json.dumps(
            {k: result[k] for k in ('status', 'error', 'steps') if k in result},
            ensure_ascii=False), flush=True)


if __name__ == '__main__':
    raise SystemExit(main())
