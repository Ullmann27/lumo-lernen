"""Reine Auswertung der Elternkennzahlen in „Lumo Insight“ (keine Geräteaufrufe).

Gelesen wird nur, was die App wirklich als Bedienungshilfe-Semantik ausgibt
(lib/features/parents/lumo_insight_dashboard.dart und
lib/features/report/learning_guidance_panel.dart):

* je Kachel ein Knoten mit Bezeichner ``insight-stat-<kachel>`` (Android:
  resource-id) und der Beschriftung „<Name>: <Wert>, <Hinweis>“ (content-desc),
* die Grundlage-Zeile unter den Kacheln (Bezeichner ``insight-stats-basis``),
* die Zeile „Grundlage: N Antworten auf diesem Gerät, davon X ohne Hilfe.“
  aus „Auf einen Blick“.

Alle Funktionen sind ohne Emulator prüfbar; sie lesen ElementTree-Knoten oder
Text und liefern Werte oder eine Liste verständlicher Abweichungen.
"""
from __future__ import annotations

import json
import re

TILES = {
    'answers': 'Antworten',
    'streak': 'Lerntage in Folge',
    'strengths': 'Stärken',
    'needs': 'Förderbedarf',
}
TILE_ID_PREFIX = 'insight-stat-'
STATS_BASIS_ID = 'insight-stats-basis'
LOADING = '…'
MISSING = '–'

_TILE_LINE = re.compile(
    r'(Antworten|Lerntage in Folge|Stärken|Förderbedarf): ([^,]+), (.+)')
_STATS_LOGGED = re.compile(
    r'Grundlage wie „Auf einen Blick“: (\d+) (?:Antwort|Antworten) im '
    r'Aufgabenprotokoll dieses Profils, davon (\d+) ohne Hilfe\.')
_STATS_OLDER = re.compile(r'(\d+) ältere (?:Antwort|Antworten) ohne Datum')
_STATS_NOTHING_LOGGED = 'Noch keine Antworten im Aufgabenprotokoll dieses Profils.'
_STATS_EMPTY = 'Noch keine Antworten in diesem Profil.'
_STATS_LOADING = 'Kennzahlen werden geladen …'
_STATS_ERROR = 'Die Kennzahlen konnten nicht sicher geladen werden.'
_GUIDANCE = re.compile(
    r'Grundlage: (\d+) Antworten auf diesem Gerät, davon (\d+) ohne Hilfe\.')
_GUIDANCE_EMPTY = 'Noch keine protokollierten Antworten.'
# Tesseract trennt Wörter manchmal anders; nur Leerraum ist hier tolerant.
_GUIDANCE_OCR = re.compile(
    r'Grundlage:\s*(\d+)\s+Antworten\s+auf\s+diesem\s+Ger[äa]t,\s*davon\s+'
    r'(\d+)\s+ohne\s+Hilfe')


def _values(node) -> list[str]:
    values = []
    for key in ('content-desc', 'text'):
        raw = node.get(key, '') or ''
        if raw:
            values.append(raw)
            values.extend(line for line in raw.splitlines() if line != raw)
    return values


def _in_package(node, package: str | None) -> bool:
    return package is None or node.get('package') == package


def read_tiles(nodes, package: str | None = None) -> dict:
    """Die vier Kacheln aus einem Hierarchie-Abzug.

    Ergebnis je gefundener Kachel: ``value``, ``hint``, ``source``
    (``resource-id`` oder ``content-desc``) und ``raw``. Widersprüchliche
    Doppelfunde sind ein Fehler, nie ein Raten.
    """
    found: dict[str, dict] = {}
    for node in nodes:
        if not _in_package(node, package):
            continue
        rid = node.get('resource-id', '') or ''
        for value in _values(node):
            match = _TILE_LINE.fullmatch(value.strip())
            if not match:
                continue
            key = next(k for k, label in TILES.items() if label == match.group(1))
            by_id = rid == TILE_ID_PREFIX + key or rid.endswith('/' + TILE_ID_PREFIX + key)
            entry = {'value': match.group(2).strip(), 'hint': match.group(3).strip(),
                     'source': 'resource-id' if by_id else 'content-desc',
                     'raw': value.strip()}
            old = found.get(key)
            if old and (old['value'], old['hint']) != (entry['value'], entry['hint']):
                raise ValueError(f'Mehrdeutige Kachel {TILES[key]}: '
                                 f'{old["raw"]!r} / {entry["raw"]!r}')
            if not old or entry['source'] == 'resource-id':
                found[key] = entry
    return found


def tile_number(entry: dict | None) -> int | None:
    """Zahl einer Kachel; ``None`` für „…“ (lädt), „–“ (offen/fehlend) oder fehlend."""
    if not entry:
        return None
    value = entry['value']
    return int(value) if re.fullmatch(r'\d+', value) else None


def parse_answers_hint(hint: str) -> dict:
    """Hinweiszeile der Kachel „Antworten“ (siehe _statsRow im Dashboard)."""
    if hint == 'wird geladen':
        return {'kind': 'loading'}
    if hint == 'nicht geladen':
        return {'kind': 'error'}
    if hint == 'noch keine':
        return {'kind': 'none'}
    if hint == 'ältere, ohne Datum':
        return {'kind': 'all-older'}
    match = re.fullmatch(r'(\d+) ohne Hilfe', hint)
    if match:
        return {'kind': 'independent', 'independent': int(match.group(1))}
    match = re.fullmatch(r'inkl\. (\d+) ältere', hint)
    if match:
        return {'kind': 'older', 'older': int(match.group(1))}
    return {'kind': 'unknown', 'raw': hint}


def read_stats_basis(nodes, package: str | None = None) -> dict | None:
    """Grundlage-Zeile direkt unter den Kacheln."""
    candidates = []
    for node in nodes:
        if not _in_package(node, package):
            continue
        rid = node.get('resource-id', '') or ''
        for value in _values(node):
            text = value.strip()
            if not (rid.endswith(STATS_BASIS_ID) or text.startswith((
                    'Grundlage wie „Auf einen Blick“', _STATS_NOTHING_LOGGED,
                    _STATS_EMPTY, _STATS_LOADING, _STATS_ERROR))):
                continue
            candidates.append(text)
            break
    if not candidates:
        return None
    if len(set(candidates)) > 1:
        raise ValueError('Mehrdeutige Grundlage-Zeile: ' + repr(sorted(set(candidates))))
    return parse_stats_basis(candidates[0])


def parse_stats_basis(text: str) -> dict:
    older = _STATS_OLDER.search(text)
    result = {'raw': text, 'older': int(older.group(1)) if older else 0}
    if text == _STATS_LOADING:
        return {**result, 'state': 'loading'}
    if text == _STATS_ERROR:
        return {**result, 'state': 'error'}
    if text == _STATS_EMPTY:
        return {**result, 'state': 'empty', 'logged': 0, 'independent': 0}
    match = _STATS_LOGGED.match(text)
    if match:
        return {**result, 'state': 'logged', 'logged': int(match.group(1)),
                'independent': int(match.group(2))}
    if text.startswith(_STATS_NOTHING_LOGGED):
        return {**result, 'state': 'older-only', 'logged': 0, 'independent': 0}
    return {**result, 'state': 'unknown'}


def read_guidance_basis(nodes, package: str | None = None) -> dict | None:
    """„Grundlage: N Antworten …“ aus „Auf einen Blick“ (oder deren Leerhinweis)."""
    found = set()
    empty = False
    for node in nodes:
        if not _in_package(node, package):
            continue
        for value in _values(node):
            for line in value.splitlines() or [value]:
                match = _GUIDANCE.search(line)
                if match:
                    found.add((int(match.group(1)), int(match.group(2)), match.group(0)))
                elif line.strip().startswith(_GUIDANCE_EMPTY):
                    empty = True
    if len(found) > 1:
        raise ValueError('Mehrdeutige „Auf einen Blick“-Grundlage: ' + repr(sorted(found)))
    if found:
        total, independent, raw = next(iter(found))
        return {'state': 'logged', 'total': total, 'independent': independent,
                'raw': raw, 'source': 'hierarchy'}
    if empty:
        return {'state': 'empty', 'total': 0, 'independent': 0,
                'raw': _GUIDANCE_EMPTY, 'source': 'hierarchy'}
    return None


def read_guidance_basis_ocr(text: str) -> dict | None:
    """Ersatzweg: dieselbe Zeile aus Tesseract-Text eines Bildschirmfotos."""
    flat = ' '.join(text.split())
    matches = {(int(m.group(1)), int(m.group(2))) for m in _GUIDANCE_OCR.finditer(flat)}
    if len(matches) != 1:
        return None
    total, independent = next(iter(matches))
    return {'state': 'logged', 'total': total, 'independent': independent,
            'raw': f'Grundlage: {total} Antworten auf diesem Gerät, davon '
                   f'{independent} ohne Hilfe.', 'source': 'ocr'}


def snapshot(tiles: dict, stats_basis: dict | None, guidance: dict | None) -> dict:
    """Alle gelesenen Werte in einer vergleichbaren Form."""
    answers = tiles.get('answers')
    hint = parse_answers_hint(answers['hint']) if answers else {'kind': 'missing'}
    return {
        'tiles': {key: ({'value': entry['value'], 'hint': entry['hint'],
                         'source': entry['source']} if entry else None)
                  for key, entry in ((k, tiles.get(k)) for k in TILES)},
        'answers': tile_number(answers),
        'answers_hint': hint,
        'streak': tile_number(tiles.get('streak')),
        'streak_hint': tiles['streak']['hint'] if tiles.get('streak') else None,
        'strengths': tiles['strengths']['value'] if tiles.get('strengths') else None,
        'needs': tiles['needs']['value'] if tiles.get('needs') else None,
        'stats_basis': stats_basis,
        'guidance': guidance,
    }


def is_settled(tiles: dict) -> bool:
    """Alle vier Kacheln da und keine zeigt mehr „…“ (lädt)."""
    return set(tiles) == set(TILES) and all(
        entry['value'] != LOADING for entry in tiles.values())


def consistency_failures(snap: dict) -> list[str]:
    """Kacheln gegen „Auf einen Blick“ und die eigene Grundlage-Zeile."""
    failures = []
    missing = [TILES[k] for k, v in snap['tiles'].items() if v is None]
    if missing:
        failures.append('Kacheln fehlen in der Bedienungshilfe-Hierarchie: ' + ', '.join(missing))
        return failures
    loading = [TILES[k] for k, v in snap['tiles'].items() if v['value'] == LOADING]
    if loading:
        failures.append('Kacheln laden noch: ' + ', '.join(loading))
    if snap['answers_hint']['kind'] in ('error', 'unknown', 'missing'):
        failures.append('Kachel „Antworten“ nicht auswertbar: ' + snap['tiles']['answers']['hint'])
    guidance, basis = snap['guidance'], snap['stats_basis']
    if guidance is None:
        failures.append('„Grundlage: N Antworten …“ aus „Auf einen Blick“ nicht gefunden')
        return failures
    answers = snap['answers']
    if answers is None:
        failures.append('Kachel „Antworten“ hat keine Zahl: ' + snap['tiles']['answers']['value'])
        return failures
    older = snap['answers_hint'].get('older', 0)
    if snap['answers_hint']['kind'] == 'all-older':
        older = answers
    if guidance['total'] > 0 and answers == 0:
        failures.append(f'„Antworten“ zeigt 0, obwohl „Auf einen Blick“ '
                        f'{guidance["total"]} Antworten nennt')
    if answers != guidance['total'] + older:
        failures.append(f'„Antworten“ {answers} ≠ Grundlage {guidance["total"]}'
                        + (f' + {older} ältere' if older else ''))
    hint = snap['answers_hint']
    if hint['kind'] == 'independent' and hint['independent'] != guidance['independent']:
        failures.append(f'Hinweis „{hint["independent"]} ohne Hilfe“ ≠ „davon '
                        f'{guidance["independent"]} ohne Hilfe“')
    if basis is None:
        failures.append('Grundlage-Zeile unter den Kacheln nicht gefunden')
    elif basis['state'] in ('loading', 'error', 'unknown'):
        failures.append('Grundlage-Zeile unter den Kacheln: ' + basis['raw'])
    elif basis['logged'] != guidance['total'] or basis['independent'] != guidance['independent']:
        failures.append(f'Grundlage-Zeile ({basis["logged"]}/{basis["independent"]}) ≠ '
                        f'„Auf einen Blick“ ({guidance["total"]}/{guidance["independent"]})')
    elif basis['older'] != older:
        failures.append(f'Ältere Antworten: Kachel {older} ≠ Grundlage-Zeile {basis["older"]}')
    return failures


def attempt_log_delta(before_raw: str | None, after_raw: str | None) -> dict:
    """Neue Einträge im gespeicherten Aufgabenprotokoll (nur gelesen)."""
    def rows(raw):
        if not raw:
            return []
        data = json.loads(raw)
        if not isinstance(data, list):
            raise ValueError('Aufgabenprotokoll ist keine Liste')
        return [row for row in data if isinstance(row, dict) and isinstance(row.get('id'), str)]

    before = {row['id'] for row in rows(before_raw)}
    added = [row for row in rows(after_raw) if row['id'] not in before]
    return {
        'count': len(added),
        'correct': sum(1 for row in added if row.get('ok') is True),
        'wrong': sum(1 for row in added if row.get('ok') is not True),
        'assisted': sum(1 for row in added if row.get('hint') is True),
        'independent': sum(1 for row in added if row.get('hint') is not True),
        'students': sorted({str(row.get('sid')) for row in added}),
        'units': sorted({f'{row.get("sub")} · {row.get("unit")}' for row in added}),
    }


def answer_failures(before: dict, after: dict, submissions: list[dict], log: dict) -> list[str]:
    """Nach den beantworteten Aufgaben: Zuwachs, Hilfenutzung, Lerntage."""
    failures = []
    count = len(submissions)
    if log['count'] != count:
        failures.append(f'Aufgabenprotokoll: {log["count"]} neue Einträge statt {count}')
    if before['answers'] is None or after['answers'] is None:
        failures.append('Kachel „Antworten“ vorher oder nachher ohne Zahl')
    elif after['answers'] - before['answers'] != count:
        failures.append(f'„Antworten“ stieg um {after["answers"] - before["answers"]} '
                        f'statt um {count} beantwortete Aufgaben')
    if before['guidance'] and after['guidance']:
        grown = after['guidance']['total'] - before['guidance']['total']
        if grown != count:
            failures.append(f'„Auf einen Blick“ stieg um {grown} statt um {count}')
        independent = after['guidance']['independent'] - before['guidance']['independent']
        if independent != log['independent']:
            failures.append(f'„ohne Hilfe“ stieg um {independent}, gespeichert sind '
                            f'{log["independent"]} neue Antworten ohne Hilfe')
    if any(s.get('correct') for s in submissions):
        if after['streak'] is None or after['streak'] < 1:
            failures.append('„Lerntage in Folge“ < 1 trotz richtiger Antwort heute')
        if after['streak_hint'] != 'zuletzt heute':
            failures.append('„Lerntage in Folge“ zeigt nicht „zuletzt heute“: '
                            + str(after['streak_hint']))
    if any(s.get('wrong') for s in submissions) and log['wrong'] < 1:
        failures.append('Die bewusst falsche Antwort fehlt im Aufgabenprotokoll')
    return failures


# Lernaufgabe „Plus bis 10“ (lib/features/learning_modules/plus_bis_10/
# plus_bis_10_screen.dart): Kopfzeile, Rechnung und Antwortkristalle.
_TASK_HEADER = re.compile(r'Aufgabe (\d+) / (\d+)')
_TASK_PROMPT = re.compile(r'(?<!\d)(\d{1,2}) \+ (\d{1,2}) = \?')
_ANSWER = re.compile(r'Antwort (\d+)')
_ROUND_CONTINUE = re.compile(r'Weiter mit Runde \d+')


def read_task(nodes, package: str | None = None) -> dict:
    """Aktuelle Aufgabe: Nummer, Rechnung, sichtbare Antwortkristalle."""
    headers, prompts, answers, rounds = set(), set(), {}, set()
    for node in nodes:
        if not _in_package(node, package):
            continue
        for value in _values(node):
            for match in _TASK_HEADER.finditer(value):
                headers.add((int(match.group(1)), int(match.group(2))))
            for match in _TASK_PROMPT.finditer(value):
                prompts.add((int(match.group(1)), int(match.group(2))))
            answer = _ANSWER.fullmatch(value.strip())
            if answer:
                number = int(answer.group(1))
                enabled = node.get('enabled') != 'false'
                answers[number] = answers.get(number, False) or enabled
            if _ROUND_CONTINUE.fullmatch(value.strip()):
                rounds.add(value.strip())
    if len(headers) > 1 or len(prompts) > 1:
        raise ValueError(f'Mehrdeutige Aufgabe: {sorted(headers)} {sorted(prompts)}')
    header = next(iter(headers), None)
    prompt = next(iter(prompts), None)
    return {
        'index': header[0] if header else None,
        'total': header[1] if header else None,
        'a': prompt[0] if prompt else None,
        'b': prompt[1] if prompt else None,
        'correct': prompt[0] + prompt[1] if prompt else None,
        'answers': dict(sorted(answers.items())),
        'round_continue': next(iter(sorted(rounds)), None),
    }


def choose_distractor(task: dict) -> int:
    """Eine sichtbare, freigegebene, falsche Antwortkarte (kleinste Zahl)."""
    wrong = [n for n, enabled in task['answers'].items()
             if enabled and n != task['correct']]
    if task['correct'] is None or not wrong:
        raise ValueError('Keine freigegebene falsche Antwortkarte sichtbar')
    return min(wrong)


def expected_from_submissions(submissions: list[dict]) -> dict:
    """Was die App laut plus_bis_10_screen.dart speichern muss.

    Hilfe gilt dort, wenn „Tipp“ gezeigt wurde oder vorher eine falsche
    Antwort zu derselben Aufgabe kam (_pendingHintUsed).
    """
    return {
        'count': len(submissions),
        'correct': sum(1 for s in submissions if s['correct']),
        'wrong': sum(1 for s in submissions if not s['correct']),
        'assisted': sum(1 for s in submissions if s['assisted']),
        'independent': sum(1 for s in submissions if not s['assisted']),
    }


COMPARED = ('answers', 'answers_hint', 'streak', 'streak_hint', 'strengths', 'needs')


def restart_failures(after: dict, restarted: dict) -> list[str]:
    """Nach ``am force-stop`` und Neustart müssen alle Kennzahlen gleich sein."""
    failures = [f'{key}: {after[key]!r} → {restarted[key]!r}'
                for key in COMPARED if after[key] != restarted[key]]
    for key in ('guidance', 'stats_basis'):
        a, b = after.get(key) or {}, restarted.get(key) or {}
        if {k: v for k, v in a.items() if k != 'source'} != {
                k: v for k, v in b.items() if k != 'source'}:
            failures.append(f'{key}: {a.get("raw")!r} → {b.get("raw")!r}')
    return failures
