#!/usr/bin/env python3
"""Echte Lernreise auf Android: Profil, Fach, Aufgabe, Rückmeldung, Belohnung, Speichern, Neustart.

Läuft nach creative_android_probe.py im selben Wegwerf-Emulator. Das Profil „LumoTest“
(1. Klasse) hat jene Prüfung über die echte Einrichtung angelegt. Bedient wird nur über
sichtbare Android-Bedienelemente: Lernen, 1. Klasse, Mathe, „Plus bis 10“, die richtige
Antwortkarte. Einstellungen, Geldbörse und Lernstand werden NUR GELESEN; nichts wird
eingespielt. Danach wird die App beendet und neu gestartet; gespeicherte Werte und die
sichtbare Tagesanzeige müssen erhalten bleiben.

Nicht geprüft: echtes Gerät, Fold-Scharnier, Bildrate, Sprachausgabe, andere Fächer.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import re
import time
import traceback

PROMPT = re.compile(r'(\d+) \+ (\d+) = \?')
DAILY = re.compile(r'(\d+) von (\d+) Aufgaben geschafft')
WALLET_KEY = 'flutter.lumo_reward_wallet_v1'
# Exact Android accessibility XML from run 38705170622 contains
# 'Lernen. Mathe, Deutsch und mehr\\nLernen' as ONE semantic node: the old
# subtitle-only string is never a separate node and the probe timed out.
# The persistent, clickable navigation tab has an exact 'Lernen' label and
# a smaller hitbox than the homepage tile; creative.flutter_tap chooses it.
# It also works at the Fold widths used in the later exploratory tour.
LEARN_TILE = 'Lernen'


def load_creative():
    path = Path(__file__).with_name('creative_android_probe.py')
    spec = importlib.util.spec_from_file_location('lumo_creative_android', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument(
        '--learning-hub', action='store_true',
        help='Use the verified 1997 subject-first learning hub instead of the older academy')
    parser.add_argument(
        '--dedicated-math-task', action='store_true',
        help='1999 learning hub opens the 30-task dedicated arithmetic screen with Antwort N buttons')
    args = parser.parse_args()
    if args.dedicated_math_task and not args.learning_hub:
        parser.error('--dedicated-math-task requires --learning-hub')
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    creative = load_creative()
    base, live, package = creative.base, creative.live, creative.PACKAGE
    result = {'status': 'RUNNING',
              'scope': 'Profil (1. Klasse) > Lernen > Mathe > Plus bis 10 > Antwort > '
                       'Rückmeldung > Belohnung > Speichern > App-Neustart > Wiederherstellen',
              'not_tested': ['physisches Gerät oder Fold-Scharnier', 'Bildrate', 'Sprachausgabe',
                             'falsche Antworten und Tipps auf Android (nur Flutter-Test)',
                             'andere Fächer und Klassen'],
              'captures': [], 'learning_hub': args.learning_hub,
              'dedicated_math_task': args.dedicated_math_task}

    def text(tag: str) -> str:
        nodes = live.live_nodes(out, tag)
        return base.accessible_text([n for n in nodes if n.get('package') == package])

    def wait_for(pattern, tag: str, timeout: float = 45):
        deadline = time.monotonic() + timeout
        attempt = 0
        while time.monotonic() < deadline:
            current = text(f'{tag}-{attempt}')
            match = pattern.search(current) if hasattr(pattern, 'search') else (
                pattern if pattern in current else None)
            if match:
                return match, current
            attempt += 1
            time.sleep(1)
        result['captures'].append(creative.capture(out, tag + '-missing'))
        raise RuntimeError(f'Nicht sichtbar nach {timeout:.0f} s: {getattr(pattern, "pattern", pattern)}')

    def scroll_to_top(tag: str, swipes: int = 6) -> None:
        # Nach „Zurück“ steht die Lernseite noch dort, wo das Thema lag. Im größten
        # scrollbaren Bereich der App nach oben wischen, wie ein Kind es tut.
        for index in range(swipes):
            boxes = []
            for node in live.live_nodes(out, f'{tag}-{index}'):
                if node.get('scrollable') != 'true' or node.get('package') != package:
                    continue
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if len(bounds) == 4 and bounds[2] > bounds[0] and bounds[3] > bounds[1]:
                    boxes.append(((bounds[2] - bounds[0]) * (bounds[3] - bounds[1]), *bounds))
            if not boxes:
                return
            _, x0, y0, x1, y1 = max(boxes)
            x = (x0 + x1) // 2
            base.adb('shell', 'input', 'swipe', str(x), str(round(y0 + (y1 - y0) * .2)),
                     str(x), str(round(y1 - (y1 - y0) * .2)), '300')
            time.sleep(.6)

    def tap_prefix(prefix: str, tag: str, scrolls: int = 12) -> None:
        # Akademie-Kacheln tragen eine ganze Satz-Beschriftung („Mathe. Zahlen und
        # Rechnen. 0 Prozent gemeistert …“). Exakter Text träfe sonst gleichlautende
        # Anzeigen, z. B. „1. Klasse“ im Profil-Chip oben (Lauf 38690593489).
        for attempt in range(scrolls):
            nodes = live.live_nodes(out, f'{tag}-{attempt}')
            hits = []
            for node in nodes:
                if node.get('package') != package or node.get('enabled') == 'false':
                    continue
                values = (node.get('text', ''), node.get('content-desc', ''))
                if not any(v.startswith(prefix) for v in values):
                    continue
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if len(bounds) == 4 and bounds[2] > bounds[0] and bounds[3] > bounds[1]:
                    hits.append(((bounds[2] - bounds[0]) * (bounds[3] - bounds[1]), *bounds))
            if hits:
                _, x0, y0, x1, y1 = min(hits)
                x, y = str((x0 + x1) // 2), str((y0 + y1) // 2)
                base.adb('shell', 'input', 'swipe', x, y, x, y, '120')
                time.sleep(2)
                return
            boxes = []
            for node in nodes:
                if node.get('scrollable') == 'true' and node.get('package') == package:
                    bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                    if len(bounds) == 4:
                        boxes.append(((bounds[2] - bounds[0]) * (bounds[3] - bounds[1]), *bounds))
            if boxes:
                _, x0, y0, x1, y1 = max(boxes)
                x = (x0 + x1) // 2
                base.adb('shell', 'input', 'swipe', str(x), str(round(y1 - (y1 - y0) * .25)),
                         str(x), str(round(y0 + (y1 - y0) * .25)), '400')
            time.sleep(.8)
        result['captures'].append(creative.capture(out, tag + '-missing'))
        raise RuntimeError('Kein Bedienelement beginnt mit: ' + prefix)

    def progress(tag: str) -> dict:
        prefs = creative.prefs(out, tag)
        return {key: value for key, value in prefs.items()
                if key == WALLET_KEY or 'lumo_progress' in key}

    def shot(name: str, *taps: str) -> str:
        # Bildschirmfoto-Rundgang für den Prüfbericht. Ein Fehler hier lässt die
        # bereits bestandene Lernreise unberührt und wird einzeln vermerkt.
        try:
            for index, label in enumerate(taps):
                creative.flutter_tap(out, label, f'{name}-tap-{index}', scroll_attempts=6)
            result['captures'].append(creative.capture(out, name))
            return 'PASS'
        except Exception as error:  # noqa: BLE001 - je Bild vermerkt, nicht verschluckt
            return f'FAIL: {str(error).splitlines()[0][:200]}'

    def tour() -> dict:
        done = {}
        for name, prefix in (('t1-deutsch', 'Deutsch. '), ('t2-englisch', 'Englisch. ')):
            try:
                tap_prefix(prefix, name, scrolls=6)
                result['captures'].append(creative.capture(out, name))
                done[name] = 'PASS'
            except Exception as error:  # noqa: BLE001 - je Bild vermerkt
                done[name] = f'FAIL: {str(error).splitlines()[0][:200]}'
        done['t3-spiele'] = shot('t3-spiele', 'Spielen')
        done['t4-tests'] = shot('t4-tests', 'Tests')
        done['t5-belohnungen'] = shot('t5-belohnungen', 'Mehr', 'Belohnungen')
        done['t6-lumo-agent'] = shot('t6-lumo-agent', 'Mehr', 'Lumo')
        done['t7-elternbereich'] = shot('t7-elternbereich', 'Mehr', 'Elternbereich')
        done['t8-start'] = shot('t8-start', 'Start')
        # Maße eines Galaxy Z Fold (Außen- und Innendisplay) im Emulator nachgestellt;
        # das ersetzt kein echtes Gerät mit Scharnier.
        for label, size in (('fold-cover', (904, 2316, 420)), ('fold-inner', (1812, 2176, 420))):
            try:
                base.display(*size)
                done[f't9-{label}-start'] = shot(f't9-{label}-start')
                done[f't9-{label}-lernen'] = shot(f't9-{label}-lernen', LEARN_TILE)
                # „Zurück“ könnte auf der obersten Ebene die App schließen; „Start“ nicht.
                creative.flutter_tap(out, 'Start', f't9-{label}-home', scroll_attempts=4)
            except Exception as error:  # noqa: BLE001
                done[f't9-{label}'] = f'FAIL: {str(error).splitlines()[0][:200]}'
        base.display(1080, 2340, 440)
        return done

    try:
        initial = creative.prefs(out, '00-initial')
        profile = initial.get('flutter.lumo_active_profile') or ''
        if 'LumoTest' not in profile:
            raise RuntimeError('Das über die echte Einrichtung angelegte Profil LumoTest fehlt')
        wallet_before = json.loads(initial.get(WALLET_KEY, '{}'))
        base.display(1080, 2340, 440)
        base.launch(out, '01-launch')
        creative.flutter_tap(out, LEARN_TILE, '02-learn')
        if args.learning_hub:
            # The actual 0.12.85+1997 APK (run 40201707838) shows the
            # subject-first learning hub. Its live accessibility tree says
            # "Was möchtest du lernen?" and "Mathematik\\nRechnen & Knobeln",
            # not the former academy daily-goal label or "Mathe. " card.
            # Require these real controls; never skip the learning exercise.
            wait_for('Was möchtest du lernen?', '02-learning-hub')
            result['captures'].append(creative.capture(out, '02-learning-hub'))
            creative.flutter_tap(out, 'Mathematik', '04-math', min_visible_height_px=40)
            wait_for('Wähle ein Thema.', '04-math-topics')
            creative.flutter_tap(out, 'Plus bis 10', '05-topic', min_visible_height_px=40)
        else:
            daily_before, _ = wait_for(DAILY, '02-daily-before')
            result['captures'].append(creative.capture(out, '02-learning-menu'))
            tap_prefix('Mathe. ', '04-math')
            tap_prefix('Plus bis 10', '05-topic')
        # The 1997 subject-first hub launches the adaptive 10-question
        # lesson, while the historic academy probe runs the dedicated
        # 30-question PlusBis10Screen. Both must solve real UI tasks.
        task_count = 10 if args.learning_hub and not args.dedicated_math_task else 30
        wait_for(f'Aufgabe 1 / {task_count}', '06-task')
        prompt, _ = wait_for(PROMPT, '06-prompt')
        answer = int(prompt.group(1)) + int(prompt.group(2))
        result['task'] = {'prompt': prompt.group(0), 'answer': answer}
        result['captures'].append(creative.capture(out, '06-math-task'))
        # AdaptiveTaskRenderer exposes the number itself on its crystal.
        # Dedicated PlusBis10Screen exposes "Antwort N" instead.
        answer_label = str(answer) if args.learning_hub and not args.dedicated_math_task else f'Antwort {answer}'
        creative.flutter_tap(out, answer_label, '07-answer')
        result['captures'].append(creative.capture(out, '07-feedback'))
        if args.learning_hub and not args.dedicated_math_task:
            # 1997 adaptive renderer auto-advances but preserves the scroll
            # position near the answer crystals. CI screenshot/XML proved the
            # correct answer earned 6 stars / 37 XP, while the next heading was
            # above the viewport. Scroll up like a real user before requiring
            # the NEXT lesson task, without weakening the assertion.
            time.sleep(2)
            scroll_to_top('08-next-task-scroll', swipes=4)
        wait_for(f'Aufgabe 2 / {task_count}', '08-next-task')
        wallet_after = creative.wallet(out, '08-wallet')
        delta = {key: int(wallet_after.get(key, 0)) - int(wallet_before.get(key, 0))
                 for key in ('stars', 'xp')}
        result['reward_delta'] = delta
        if delta['stars'] < 1 or delta['xp'] < 1:
            raise RuntimeError(f'Keine gespeicherte Belohnung für die richtige Antwort: {delta}')
        base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        time.sleep(2)
        if not args.learning_hub:
            scroll_to_top('09-scroll-top')
            daily_after, _ = wait_for(DAILY, '09-daily-after')
            if int(daily_after.group(1)) != int(daily_before.group(1)) + 1:
                raise RuntimeError(f'Tagesziel zählt nicht genau eine Aufgabe: '
                                   f'{daily_before.group(0)} -> {daily_after.group(0)}')
        result['captures'].append(creative.capture(out, '09-after-lesson'))
        saved = progress('10-before-restart')
        if not any('lumo_progress' in key for key in saved):
            raise RuntimeError('Kein gespeicherter Lernstand gefunden')
        if args.learning_hub:
            # On the 1997 hub the old visual daily-goal widget does not exist.
            # Instead enforce actual saved, positive answers and rewards here;
            # require_learning_preserved enforces them again across the update.
            total_correct = 0
            for key, raw in saved.items():
                if key.startswith('flutter.lumo_progress_skills'):
                    records = json.loads(raw)
                    if not isinstance(records, dict):
                        raise RuntimeError('Ungültige gespeicherte Lernrecords')
                    for record in records.values():
                        count = record.get('correct') if isinstance(record, dict) else None
                        if type(count) is not int or count < 0:
                            raise RuntimeError('Ungültige Anzahl richtiger Antworten')
                        total_correct += count
            if total_correct < 1:
                raise RuntimeError('Keine nachweislich gespeicherte richtige Antwort')
            result['saved_correct_answers'] = total_correct
        base.adb('shell', 'am', 'force-stop', package)
        time.sleep(2)
        base.launch(out, '11-restart')
        restored = progress('11-after-restart')
        if restored != saved:
            changed = sorted(k for k in set(saved) | set(restored) if saved.get(k) != restored.get(k))
            raise RuntimeError(f'Gespeicherter Stand nach Neustart verändert: {changed}')
        creative.flutter_tap(out, LEARN_TILE, '12-learn-after-restart')
        if args.learning_hub:
            wait_for('Was möchtest du lernen?', '12-learning-hub-restored')
            result['hub'] = {
                'visible_after_restart': True,
                'saved_correct_answers': result['saved_correct_answers'],
                'wallet_and_progress_after_restart': 'UNCHANGED',
            }
        else:
            daily_restored, _ = wait_for(DAILY, '12-daily-restored')
            if daily_restored.group(0) != daily_after.group(0):
                raise RuntimeError(
                    f'Sichtbare Tagesanzeige nach Neustart: {daily_restored.group(0)} '
                    f'statt {daily_after.group(0)}')
            result['daily'] = {
                'before': daily_before.group(0),
                'after': daily_after.group(0),
                'after_restart': daily_restored.group(0),
            }
        result['captures'].append(creative.capture(out, '12-restored-learning-menu'))
        result['restart_restore'] = 'PASS'
        result['status'] = 'PASS'
        result['tour'] = tour()
        return 0
    except Exception:
        result['status'] = 'FAIL'
        result['error'] = traceback.format_exc()
        return 1
    finally:
        (out / 'learning-journey-result.json').write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + '\n')
        try:
            (out / 'learning-journey-logcat.txt').write_text(base.adb('logcat', '-d', '-t', '2000'))
        except Exception:
            pass


if __name__ == '__main__':
    raise SystemExit(main())
