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
# Die Startseiten-Kachel „Lernen“ trägt diesen Untertitel. Das Wort „Lernen“ allein steht
# auf breiten Bildschirmen auch als nicht antippbare Überschrift in der Seitenleiste.
LEARN_TILE = 'Mathe, Deutsch und mehr'


def load_creative():
    path = Path(__file__).with_name('creative_android_probe.py')
    spec = importlib.util.spec_from_file_location('lumo_creative_android', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    creative = load_creative()
    base, live, package = creative.base, creative.live, creative.PACKAGE
    result = {'status': 'RUNNING',
              'scope': 'Profil > Lernen > 1. Klasse > Mathe > Plus bis 10 > Antwort > '
                       'Rückmeldung > Belohnung > Speichern > App-Neustart > Wiederherstellen',
              'not_tested': ['physisches Gerät oder Fold-Scharnier', 'Bildrate', 'Sprachausgabe',
                             'falsche Antworten und Tipps auf Android (nur Flutter-Test)',
                             'andere Fächer und Klassen'],
              'captures': []}

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

    def progress(tag: str) -> dict:
        prefs = creative.prefs(out, tag)
        return {key: value for key, value in prefs.items()
                if key == WALLET_KEY or 'lumo_progress' in key}

    try:
        initial = creative.prefs(out, '00-initial')
        profile = initial.get('flutter.lumo_active_profile') or ''
        if 'LumoTest' not in profile:
            raise RuntimeError('Das über die echte Einrichtung angelegte Profil LumoTest fehlt')
        wallet_before = json.loads(initial.get(WALLET_KEY, '{}'))
        base.display(1080, 2340, 440)
        base.launch(out, '01-launch')
        creative.flutter_tap(out, LEARN_TILE, '02-learn')
        daily_before, _ = wait_for(DAILY, '02-daily-before')
        result['captures'].append(creative.capture(out, '02-learning-menu'))
        creative.flutter_tap(out, '1. Klasse', '03-grade-1')
        creative.flutter_tap(out, 'Mathe', '04-math')
        creative.flutter_tap(out, 'Plus bis 10', '05-topic')
        wait_for('Aufgabe 1 / 30', '06-task')
        prompt, _ = wait_for(PROMPT, '06-prompt')
        answer = int(prompt.group(1)) + int(prompt.group(2))
        result['task'] = {'prompt': prompt.group(0), 'answer': answer}
        result['captures'].append(creative.capture(out, '06-math-task'))
        creative.flutter_tap(out, f'Antwort {answer}', '07-answer')
        result['captures'].append(creative.capture(out, '07-feedback'))
        wait_for('Aufgabe 2 / 30', '08-next-task')
        wallet_after = creative.wallet(out, '08-wallet')
        delta = {key: int(wallet_after.get(key, 0)) - int(wallet_before.get(key, 0))
                 for key in ('stars', 'xp')}
        result['reward_delta'] = delta
        if delta['stars'] < 1 or delta['xp'] < 1:
            raise RuntimeError(f'Keine gespeicherte Belohnung für die richtige Antwort: {delta}')
        base.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        time.sleep(2)
        scroll_to_top('09-scroll-top')
        daily_after, _ = wait_for(DAILY, '09-daily-after')
        if int(daily_after.group(1)) != int(daily_before.group(1)) + 1:
            raise RuntimeError(f'Tagesziel zählt nicht genau eine Aufgabe: '
                               f'{daily_before.group(0)} -> {daily_after.group(0)}')
        result['captures'].append(creative.capture(out, '09-after-lesson'))
        saved = progress('10-before-restart')
        if not any('lumo_progress' in key for key in saved):
            raise RuntimeError('Kein gespeicherter Lernstand gefunden')
        base.adb('shell', 'am', 'force-stop', package)
        time.sleep(2)
        base.launch(out, '11-restart')
        restored = progress('11-after-restart')
        if restored != saved:
            changed = sorted(k for k in set(saved) | set(restored) if saved.get(k) != restored.get(k))
            raise RuntimeError(f'Gespeicherter Stand nach Neustart verändert: {changed}')
        creative.flutter_tap(out, LEARN_TILE, '12-learn-after-restart')
        daily_restored, _ = wait_for(DAILY, '12-daily-restored')
        if daily_restored.group(0) != daily_after.group(0):
            raise RuntimeError(f'Sichtbare Tagesanzeige nach Neustart: {daily_restored.group(0)} '
                               f'statt {daily_after.group(0)}')
        result['captures'].append(creative.capture(out, '12-restored-learning-menu'))
        result['daily'] = {'before': daily_before.group(0), 'after': daily_after.group(0),
                           'after_restart': daily_restored.group(0)}
        result['restart_restore'] = 'PASS'
        result['status'] = 'PASS'
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
