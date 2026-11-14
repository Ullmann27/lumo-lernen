"""Replay original API35 Village entry/visible-return evidence without a device.

The Android producer reuses the existing real UI/OCR helpers. This verifier
reads their original command replies, screenshots and TSVs; reported PASS or
expected scene names alone cannot establish a completed host roundtrip.
"""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import re
import unicodedata
import xml.etree.ElementTree as ET

from PIL import Image

import connect_four_android_evidence as c4
from native_surface_readiness import inspect_surface, target_observation

PORTAL = 'Dorf & Wirtschaft. Versorge dein Dorf, baue Häuser und hilf deinen Nachbarn! Spielen'
SCENE = 'res://scenes/creative/build_settlement_world.tscn'
REPORT = 'village-result.json'
PREFS = f'/data/user/0/{c4.PACKAGE}/shared_prefs/FlutterSharedPreferences.xml'
MARKER = '[VillageHostReady] '
HUD = ('LUMO DORFWELT', 'Nächster Tag')


def normalized(value: str) -> str:
    plain = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', plain.lower())


def read(root: Path, name: str) -> dict:
    value = json.loads(c4.safe_member(root, name).read_text())
    c4.demand(isinstance(value, dict), 'Missing original Village evidence object: '+name)
    return value


def original(root: Path, name: str, arguments: list[str], *, absent=False) -> str:
    c4.demand(isinstance(name, str) and name.endswith('.stdout'), 'Missing original ADB reply')
    if not absent:
        return c4.read_original(root, name, empty_ok=True, command=['adb', *arguments])
    path = c4.safe_member(root, name)
    meta = read(root, name[:-7]+'.json')
    stderr = c4.safe_member(root, name[:-7]+'.stderr')
    c4.demand(arguments == ['shell', 'pidof', c4.PACKAGE+':lumo_game']
              and meta.get('command') == ['adb', *arguments]
              and meta.get('returncode') in (0, 1) and not path.read_bytes()
              and not stderr.read_bytes() and meta.get('stdout_bytes') == 0
              and meta.get('stderr_bytes') == 0
              and meta.get('stdout_sha256') == hashlib.sha256(b'').hexdigest()
              and meta.get('stderr_sha256') == hashlib.sha256(b'').hexdigest(),
              'Native process absence was not observed by successful pidof')
    return ''


def owner(prefs: dict) -> str:
    selected = (prefs.get('flutter.lumo_school_active_student_v1') or '').strip()
    value = selected or (prefs.get('flutter.lumo_learning_local_student_id_v1') or '').strip()
    c4.demand(bool(value) and len(value) <= 300, 'Actual Village learning owner is missing')
    return value


def child_key(prefs: dict) -> str:
    registry = json.loads(prefs.get('flutter.lumo_3d_profile_keys_v1', '{}'))
    owners = registry.get('owners', {})
    c4.demand(registry.get('version') == 1 and isinstance(owners, dict)
              and isinstance(registry.get('legacy'), dict)
              and type(registry.get('legacyAvailable')) is bool
              and prefs.get('flutter.lumo_3d_save_salt_v1')
              and all(isinstance(k, str) and k and isinstance(v, str)
                      and re.fullmatch(r'p_[a-f0-9]{32}', v) for k, v in owners.items())
              and len(set(owners.values())) == len(owners)
              and owner(prefs) in owners, 'Actual native child-key registry is missing or invalid')
    return owners[owner(prefs)]


def unchanged(before: dict, after: dict) -> None:
    c4.learning_unchanged(before, after)
    selected = lambda values: {k: v for k, v in values.items()
                              if k.startswith(c4.LEARNING_PREFIXES)
                              or k == 'flutter.lumo_active_profile'}
    c4.demand(selected(before) == selected(after) and owner(before) == owner(after),
              'Village changed profile, learning, rewards or selected child')


def ready(raw: str, pid: int, prefs: dict) -> dict:
    found = []
    for line in raw.splitlines():
        if MARKER not in line:
            continue
        match = re.fullmatch(r'\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+\s+'
                             r'(\d+)\s+\d+\s+[VDIWEF]\s+[^:]+:\s*(.*)', line)
        c4.demand(match is not None and int(match[1]) == pid
                  and match[2].startswith(MARKER), 'Village marker is not from the actual native PID')
        found.append(json.loads(match[2][len(MARKER):]))
    c4.demand(len(found) == 1, 'Missing or ambiguous actual VillageHostReady marker')
    item = found[0]
    expected_path = 'user://lumo_settlement_'+hashlib.sha256(child_key(prefs).encode()).hexdigest()+'_1_village.json'
    c4.demand(isinstance(item, dict) and item.get('scene') == SCENE
              and item.get('mode') == 'settlement' and item.get('living_village') is True
              and item.get('host_entry') is True and item.get('return_scene') == 'games'
              and item.get('save_blocked') is False and type(item.get('slot')) is int
              and item['slot'] == 1 and item.get('save_path') == expected_path,
              'Actual Village scene, owner, slot or direct host return differs')
    c4.demand(c4.integer(item.get('plots'), 9, 1089)
              and type(item.get('population')) is int and item['population'] >= 2
              and c4.integer(item.get('visible_residents'), 0, min(18, item['population']))
              and c4.integer(item.get('initialized_plot_nodes'), 1, item['plots']),
              'Village marker does not describe an initialized actual settlement')
    return item


def process(root: Path, row: dict, *, native: bool) -> tuple[int, int | None]:
    host_raw = original(root, row['host_pid'], ['shell', 'pidof', c4.PACKAGE])
    c4.demand(bool(re.fullmatch(r'[1-9]\d*\s*', host_raw)), 'Missing unique actual Flutter PID')
    host = int(host_raw)
    native_raw = original(root, row['native_pid'], ['shell', 'pidof', c4.PACKAGE+':lumo_game'], absent=not native)
    native_pid = None
    if native:
        c4.demand(bool(re.fullmatch(r'[1-9]\d*\s*', native_raw)), 'Missing unique actual native PID')
        native_pid = int(native_raw)
        c4.demand(host != native_pid, 'Flutter and Village are not separate real processes')
    activity = original(root, row['activity'], ['shell', 'dumpsys', 'activity', 'activities'])
    active = [line for line in activity.splitlines() if 'mResumedActivity' in line or 'topResumedActivity' in line]
    component = 'LumoGameActivity' if native else 'MainActivity'
    c4.demand(active and all(c4.PACKAGE in line and component in line for line in active),
              'Wrong actual foreground activity for Village roundtrip: '+component)
    return host, native_pid


def capture(root: Path, row: dict, *, native=False) -> Path:
    path = c4.safe_member(root, row['file'])
    c4.demand(c4.sha256(path) == row['sha256'], 'Original Village/Flutter screenshot changed')
    with Image.open(path) as image:
        image.load()
        c4.demand(image.format == 'PNG' and list(image.size) == [row['width'], row['height']],
                  'Missing original Village/Flutter PNG dimensions')
    if native:
        c4.demand(inspect_surface(path, orientation='responsive')['acceptable_for_target_sampling'],
                  'Actual Village surface is not fully rendered')
    return path


def caption(root: Path, image: Path, tag: str, wanted: str, *, bounds=None) -> list:
    """Validate observed OCR text/bounds against original Tesseract TSV words."""
    rows = json.loads(c4.safe_member(root, tag+'-ocr.json').read_text())
    c4.demand(isinstance(rows, list), 'Missing actual OCR observations')
    with Image.open(image) as frame:
        width, height = frame.size
    for row in rows:
        if not isinstance(row, dict) or normalized(str(row.get('text', ''))) != normalized(wanted):
            continue
        actual = row.get('bounds')
        if not isinstance(actual, list) or len(actual) != 4 or (bounds is not None and actual != bounds):
            continue
        x0, y0, x1, y1 = c4.vector(actual, 4, 'observed OCR caption')
        c4.demand(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height, 'OCR target escapes the original PNG')
        variant = row.get('variant')
        c4.demand(variant in ('contrast', 'raw', 'white-text', 'white-latin', 'navy-latin',
                              'navy-latin-1x', 'teal-text-1x'), 'Unknown original OCR variant')
        scale = 1 if variant.endswith('-1x') else 2
        groups = {}
        with c4.safe_member(root, tag+'-ocr-'+variant+'.tsv').open() as stream:
            for word in csv.DictReader(stream, delimiter='\t', quoting=csv.QUOTE_NONE):
                if word.get('text', '').strip() and float(word['conf']) >= 15:
                    key = tuple(word[k] for k in ('page_num', 'block_num', 'par_num', 'line_num'))
                    groups.setdefault(key, []).append(word)
        for words in groups.values():
            words.sort(key=lambda word: int(word['left']))
            spans = [words] + [words[start:end] for start in range(len(words))
                               for end in range(start+1, min(len(words), start+8)+1)]
            for span in spans:
                observed = [min(int(w['left']) for w in span)/scale,
                            min(int(w['top']) for w in span)/scale,
                            max(int(w['left'])+int(w['width']) for w in span)/scale,
                            max(int(w['top'])+int(w['height']) for w in span)/scale]
                if observed == actual and normalized(' '.join(w['text'] for w in span)) == normalized(wanted):
                    return actual
    raise ValueError('Actual original TSV/PNG does not establish caption: '+wanted)


def return_touch(root: Path, row: dict) -> None:
    journal = read(root, row['touch_journal'])
    c4.demand(journal.get('status') == 'TOUCH_SENT' and journal.get('label') == 'Spiele'
              and journal.get('exact_caption_required') is True
              and journal.get('orientation_policy') == 'responsive'
              and len(journal.get('frames', [])) >= 2, 'Missing visible direct Village return touch')
    previous = None
    last = journal['frames'][-2:]
    c4.demand(last[0]['source'] != last[1]['source']
              and last[0]['captured_after_seconds'] < last[1]['captured_after_seconds'],
              'Village return lacks two distinct current observations')
    for frame in last:
        path = c4.safe_member(root, frame['source'])
        observed = inspect_surface(path, orientation='responsive')
        c4.demand(observed['acceptable_for_target_sampling']
                  and all(frame.get(k) == v for k, v in observed.items()),
                  'Original native return surface replay differs')
        bounds = caption(root, path, path.stem, 'Spiele', bounds=frame['target']['bounds'])
        previous = target_observation(observed, bounds, previous)
        c4.demand(previous == frame['target'], 'Actual native return target differs')
    c4.demand(previous['stable_observed_target']
              and journal['final_observed_bounds'] == previous['bounds'], 'Village return target did not settle')
    x0, y0, x1, y1 = previous['bounds']
    point = [round((x0+x1)/2), round((y0+y1)/2)]
    c4.demand(journal.get('touch') == point, 'Village return touch misses its visible caption')
    c4.checked_dispatch(root, {'target': {'point': point}, 'command_original': row['command_original']})


def inventory(root: Path, rows: list[dict]) -> None:
    c4.demand(isinstance(rows, list) and rows and all(isinstance(row, dict) for row in rows),
              'Missing original Village inventory')
    names = [row.get('path') for row in rows]
    c4.demand(all(isinstance(name, str) for name in names) and len(set(names)) == len(names),
              'Duplicate/invalid original Village inventory')
    for row in rows:
        path = c4.safe_member(root, row['path'])
        c4.demand(path.stat().st_size == row.get('bytes') and c4.sha256(path) == row.get('sha256'),
                  'Original Village evidence bytes changed: '+row['path'])
    actual = set()
    for path in root.rglob('*'):
        c4.demand(not path.is_symlink(), 'Village evidence cannot contain symlinks')
        if path.is_file() and path != root/REPORT:
            actual.add(path.relative_to(root).as_posix())
    c4.demand(set(names) == actual, 'Village inventory does not cover all original files')


def verify_report(root: Path, binding: dict, identity: dict) -> dict:
    report = read(root, REPORT)
    c4.demand(report.get('schema') == 1 and report.get('status') == 'PASS'
              and report.get('binding') == binding and report.get('identity') == identity,
              'Village report is missing, failed or bound to another exact APK/source/run')
    inventory(root, report['originals'])
    c4.demand(original(root, report['android_sdk_original'], ['shell', 'getprop', 'ro.build.version.sdk']).strip() == '35',
              'Actual Village evidence is not from Android API35')
    before, native, returned = (report[name] for name in ('before', 'native', 'returned'))
    host, _ = process(root, before, native=False)
    active_host, pid = process(root, native, native=True)
    return_host, return_pid = process(root, returned['native_before_return'], native=True)
    returned_host, _ = process(root, returned, native=False)
    c4.demand(host == active_host == return_host == returned_host and pid == return_pid,
              'Village replaced or lost the actual Flutter/native process before return')
    prefs = [c4.preferences(original(root, row['preferences'], ['exec-out', 'cat', PREFS]))
             for row in (before, native, returned)]
    unchanged(prefs[0], prefs[1]); unchanged(prefs[0], prefs[2])
    c4.demand(child_key(prefs[1]) == child_key(prefs[2]), 'Village native child mapping changed on return')
    if prefs[0].get('flutter.lumo_3d_profile_keys_v1'):
        c4.demand(child_key(prefs[0]) == child_key(prefs[1]), 'Village launched another native child identity')
    c4.checked_flutter_touch(root, report['entry_touch'], PORTAL)
    raw = original(root, native['logcat'], ['logcat', '-b', 'all', '--pid', str(pid), '-d', '-v', 'threadtime'])
    marker = ready(raw, pid, prefs[1])
    c4.demand(marker == native['marker'], 'Reported Village marker differs from actual original logcat')
    frame = capture(root, native['frame'], native=True)
    c4.demand(len(native['hud_ocr']) == len(HUD), 'Missing actual Village HUD captions')
    for tag, wanted in zip(native['hud_ocr'], HUD):
        caption(root, frame, tag, wanted)
    return_touch(root, returned)
    flutter = capture(root, returned['frame'])
    caption(root, flutter, returned['visible_ocr'], 'Spielen')
    tree = ET.fromstring(c4.safe_member(root, returned['ui']).read_text())
    c4.demand(tree.tag == 'hierarchy' and any(node.get('package') == c4.PACKAGE
              and node.get('enabled') == 'true'
              and any('Spielen' == value or PORTAL in value for value in
                      (node.get('text', ''), node.get('content-desc', '')))
              for node in tree.iter('node')), 'Actual Flutter Spielewelt did not return')
    log = original(root, report['original_logcat'], ['logcat', '-b', 'all', '-d', '-v', 'threadtime'])
    c4.demand(not c4.runtime_errors(log) and not c4.runtime_errors(raw)
              and report.get('fatal_entries') == [], 'Actual Android/engine errors remain in Village evidence')
    return {'status': 'PASS', 'android_api': 35, 'host_pid': host, 'native_pid': pid,
            'native_process_ended': True, 'profile_and_learning_unchanged': True,
            'scene': marker['scene'], 'save_path': marker['save_path'],
            'return_scene': marker['return_scene'], 'frame_sha256': c4.sha256(frame),
            'raw_report_sha256': c4.sha256(root/REPORT)}
