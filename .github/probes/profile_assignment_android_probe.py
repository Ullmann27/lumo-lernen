#!/usr/bin/env python3
"""Actual 1919 -> 1920 Android learning migration, through visible Flutter UI.

The APK source is fixed at 554c2b6; the separately recorded QA commit may differ.
One disposable API-35 emulator, two real baseline Plus answers, two UI-created
children, an adult's explicit assignment, one real answer for B, and a restart.
Preferences are ONLY read. No app data, XML, answers or completion is injected.
This does not test the shared wallet, reading/writing stores or native games.
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
import subprocess
import sys
import time
import traceback
from urllib.parse import quote
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
APK_SOURCE = '554c2b6a0a12e36a2b5497c787acb14f6f6d85fd'
GODOT_SOURCE = '6b40153126171a5b3193c830855f42c9c597f0a1'
CERTIFICATE = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
BASELINE_SOURCE = 'd07b2b48593b939a2a0446fcb83a25a2b2a59db6'
BASELINE_GODOT = 'd140e5b05cb5afacfe675559b78da4254cb1daed'
BASELINE_SHA256 = '8e2ea31fed333fd8e89becd073b100c53ce9449017badb43ab4bc28022cc51aa'
BASELINE_BYTES = 205316096
BASELINE_RUN = 37975946198
BASELINE_ARTIFACT = 11639898022
SKILL = 'mathematik::plus bis 10'
LEGACY_KEYS = (
    'lumo_progress_skills', 'lumo_progress_daily', 'lumo_progress_last',
    'lumo_cosmos_items_v1', 'lumo_cosmos_meta_v1',
)
SCHOOL = 'flutter.lumo_school_v1'
ACTIVE = 'flutter.lumo_school_active_student_v1'
PROFILE = 'flutter.lumo_active_profile'
CLAIM = 'flutter.lumo_learning_legacy_claim_v1'
SNAPSHOT = 'flutter.lumo_learning_legacy_snapshot_v1'
SUCCESS_TEXT = (
    'Die bisherigen Lerndaten gehören jetzt zu Alina. '
    'Jedes Kind führt seinen Lernfortschritt und Lernkosmos '
    'im eigenen Profil weiter.'
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def strict_json(raw: str):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate JSON key: ' + key)
            result[key] = value
        return result

    def invalid(value):
        raise RuntimeError('Non-finite JSON value: ' + value)

    return json.loads(raw, object_pairs_hook=unique, parse_constant=invalid)


def digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def parse_preferences(raw: str) -> dict:
    root = ET.fromstring(raw)
    require(root.tag == 'map', 'Preferences are not an Android map')
    result = {}
    for node in root:
        name = node.get('name')
        require(isinstance(name, str) and name not in result,
                'Missing or duplicate Android preference name')
        result[name] = node.text if node.tag == 'string' else node.get('value')
    return result


def preference_json(prefs: dict, key: str, default=None):
    raw = prefs.get(key)
    return default if raw is None else strict_json(raw)


def namespace_key(base: str, owner: str) -> str:
    require(isinstance(owner, str) and bool(owner.strip()), 'Missing learning owner')
    return 'flutter.' + base + '::' + quote(owner, safe="-_.!~*'()")


def learning_value(prefs: dict, base: str, owner: str | None):
    """Read the actual namespace, or this owner's committed immutable snapshot."""
    if owner is None:
        return prefs.get('flutter.' + base)
    direct = prefs.get(namespace_key(base, owner))
    if direct is not None:
        return direct
    claim = preference_json(prefs, CLAIM, {})
    if claim.get('state') == 'committed' and claim.get('owner') == owner:
        snapshot = preference_json(prefs, SNAPSHOT, {})
        require(snapshot.get('owner') == owner and isinstance(snapshot.get('data'), dict),
                'Committed claim has no matching immutable snapshot')
        return snapshot['data'].get(base)
    # Never borrow the old global data or a different child's snapshot.
    return None


def learning_state(prefs: dict, owner: str | None) -> dict:
    def read(base, default):
        raw = learning_value(prefs, base, owner)
        return default if raw is None else strict_json(raw)

    cosmos = read('lumo_cosmos_v2', None) if owner is not None else None
    if cosmos is None:
        cosmos = {'items': read('lumo_cosmos_items_v1', []),
                  'meta': read('lumo_cosmos_meta_v1', {})}
    require(isinstance(cosmos, dict), 'Learning world is not an object')
    return {
        'skills': read('lumo_progress_skills', {}),
        'daily': read('lumo_progress_daily', {}),
        'last': read('lumo_progress_last', {}),
        'cosmos': cosmos,
    }


def require_progress(prefs: dict, owner: str | None, correct: int, day: str,
                     *, require_scoped: bool = False) -> dict:
    state = learning_state(prefs, owner)
    for field in ('skills', 'daily', 'last'):
        require(isinstance(state[field], dict), 'Invalid learning field: ' + field)
    expected_daily = {day: correct} if correct else {}
    require(state['daily'] == expected_daily and
            all(type(value) is int for value in state['daily'].values()),
            f'Wrong durable daily count for {owner}: {state["daily"]}')
    if correct:
        require(set(state['skills']) == {SKILL}, 'Expected only the actually played Plus skill')
        skill = state['skills'][SKILL]
        require(isinstance(skill, dict) and skill.get('skillId') == SKILL and
                skill.get('subject') == 'Mathematik' and skill.get('unit') == 'Plus bis 10',
                'Wrong persisted Plus skill identity')
        for field, wanted in (('correct', correct), ('wrong', 0), ('hintCount', 0)):
            require(type(skill.get(field)) is int and skill[field] == wanted,
                    f'Wrong durable Plus {field} for {owner}')
        require(state['last'] == {'Mathematik': 'Plus bis 10'}, 'Wrong last learning topic')
    else:
        require(state['skills'] == {} and state['last'] == {}, 'Untouched child borrowed learning history')
    cosmos = state['cosmos']
    require(isinstance(cosmos.get('items'), list) and isinstance(cosmos.get('meta'), dict),
            'Invalid persisted learning world')
    count = cosmos['meta'].get('c', 0)
    require(type(count) is int and count == correct, 'Wrong durable Cosmos correct count')
    # This probe plays only one/two non-perfect Plus answers. Each creates one
    # tree (enum index 1); none of the 5/20/25/etc. bonuses can apply.
    require(len(cosmos['items']) == correct, 'Wrong number of durable Plus trees')
    for item in cosmos['items']:
        require(isinstance(item, dict) and type(item.get('t')) is int and item['t'] == 1 and
                all(type(item.get(key)) in (int, float) and math.isfinite(item[key])
                    for key in ('x', 'y', 's', 'r')) and
                0 <= item['x'] <= 1 and 0 <= item['y'] <= 1 and item['s'] > 0,
                'Invalid durable Plus tree object')
    if require_scoped:
        require(owner is not None and all(namespace_key(key, owner) in prefs
                                          for key in LEGACY_KEYS[:3]),
                'Learning profile was not persisted in its actual Android namespace')
    return state


def learning_signature(state: dict) -> dict:
    # Loading a world may legitimately update its visit date/streak. Learning
    # counters and objects must stay with their owner throughout those visits.
    return {**{key: state[key] for key in ('skills', 'daily', 'last')},
            'cosmos_items': state['cosmos']['items'],
            'cosmos_correct': state['cosmos']['meta'].get('c', 0)}


def school_children(prefs: dict) -> dict:
    school = preference_json(prefs, SCHOOL, {})
    require(isinstance(school, dict), 'Missing actual UI-created school')
    classes, children = school.get('classes'), school.get('students')
    require(isinstance(classes, list) and len(classes) == 1 and
            isinstance(classes[0], dict) and classes[0].get('name') == '1a' and
            type(classes[0].get('grade')) is int and classes[0]['grade'] == 1,
            'Expected exactly the UI-created class 1a')
    require(isinstance(children, list) and len(children) == 2, 'Expected two UI-created children')
    result = {}
    for child in children:
        require(isinstance(child, dict) and child.get('cls') == classes[0].get('id') and
                child.get('name') in ('Alina', 'Boris') and child['name'] not in result,
                'Ambiguous UI-created child or class')
        identity = child.get('id')
        require(isinstance(identity, str) and re.fullmatch(r'stud-[0-9]+-[0-9]+', identity),
                'Missing real opaque school ID')
        result[child['name']] = identity
    require(len(set(result.values())) == 2, 'Children share the same stored ID')
    return result


def require_claim(prefs: dict, owner: str, originals: dict) -> None:
    claim = preference_json(prefs, CLAIM, {})
    snapshot = preference_json(prefs, SNAPSHOT, {})
    require(claim == {'version': 1, 'owner': owner, 'state': 'committed'} and
            type(claim['version']) is int, 'Adult assignment was not committed to A alone')
    require(snapshot == {'owner': owner, 'data': originals},
            'Assigned snapshot differs from the exact pre-update legacy values')
    require(all(prefs.get('flutter.' + key) == value for key, value in originals.items()),
            'Preserved legacy originals were changed')


def installed_bytes(path_output: str, hash_output: str, size_output: str,
                    expected_hash: str, expected_size: int) -> dict:
    paths = path_output.strip().splitlines()
    require(len(paths) == 1 and re.fullmatch(r'package:/data/app/[^ \r\n]+/base\.apk', paths[0]),
            'Expected one actual installed base.apk and no splits')
    path = paths[0].removeprefix('package:')
    match = re.fullmatch(r'([a-f0-9]{64})[ \t]+\*?([^\r\n]+)', hash_output.strip())
    require(match is not None and match[2] == path, 'Malformed installed APK sha256sum')
    require(re.fullmatch(r'[0-9]+', size_output.strip()) is not None, 'Malformed installed APK stat')
    size = int(size_output)
    require(match[1] == expected_hash and size == expected_size, 'Installed APK differs from supplied bytes')
    return {'remote_path': path, 'sha256': match[1], 'bytes': size, 'matches_input': True,
            'verification_method': 'android-toybox-sha256sum-stat',
            'scope': 'Device measurement with retained raw stdout; installed APK itself is not exported'}


def node_bounds(node, width: int, height: int):
    match = re.fullmatch(r'\[(-?[0-9]+),(-?[0-9]+)\]\[(-?[0-9]+),(-?[0-9]+)\]',
                         node.get('bounds', ''))
    if not match or node.get('enabled') == 'false' or node.get('visible-to-user') == 'false':
        return None
    x0, y0, x1, y1 = map(int, match.groups())
    return (x0, y0, x1, y1) if 0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height else None


def labels(node) -> list[str]:
    return list(dict.fromkeys(
        value.strip() for key in ('text', 'content-desc')
        for value in node.get(key, '').split('\n') if value.strip()
    ))


def matching(nodes, label: str, width: int, height: int):
    return [node for node in nodes if node.get('package') == PACKAGE and
            (label in labels(node) or any(node.get(key, '').strip() == label
                                         for key in ('text', 'content-desc'))) and
            node_bounds(node, width, height)]


def plus_question(nodes, width: int, height: int):
    """A visible prompt plus four distinct clickable options, below that prompt."""
    prompts, indexes = {}, set()
    parents = {child: parent for parent in nodes for child in parent}
    for node in nodes:
        if node.get('package') != PACKAGE or not node_bounds(node, width, height):
            continue
        for label in labels(node):
            prompt = re.fullmatch(r'([0-9]+)\s*\+\s*([0-9]+)\s*=\s*\?', label)
            index = re.fullmatch(r'Aufgabe ([0-9]+) / 30', label)
            if prompt:
                bounds = node_bounds(node, width, height)
                area = (bounds[2] - bounds[0]) * (bounds[3] - bounds[1])
                operands = tuple(map(int, prompt.groups()))
                if operands not in prompts or area < prompts[operands][0]:
                    prompts[operands] = (area, bounds, label)
            if index:
                indexes.add(int(index[1]))
    require(len(prompts) <= 1 and len(indexes) <= 1, 'Ambiguous live Plus task')
    if not prompts or not indexes:
        return None
    (a, b), (_, prompt_bounds, prompt_text) = next(iter(prompts.items()))
    require(1 <= a <= 5 and 1 <= b <= 10 - a, 'Observed task is outside Plus bis 10')
    options = {}
    for node in nodes:
        values = labels(node)
        if (node.get('package') != PACKAGE or len(values) != 1 or
                re.fullmatch(r'[0-9]+', values[0]) is None or
                not node_bounds(node, width, height)):
            continue
        value = int(values[0])
        target = node
        while target.get('clickable') != 'true' and target in parents:
            target = parents[target]
        bounds = node_bounds(target, width, height)
        if (target.get('clickable') != 'true' or target.get('enabled') != 'true' or not bounds or
                bounds[1] < prompt_bounds[3] or not 0 <= value <= 10):
            continue
        # An enclosing panel containing several answers is not an answer button.
        descendant_numbers = {label for child in target.iter('node') for label in labels(child)
                              if re.fullmatch(r'[0-9]+', label)}
        if descendant_numbers != {str(value)}:
            continue
        if value in options:
            require(options[value] == bounds, 'Ambiguous live numeric answer')
        options[value] = bounds
    if len(options) != 4:
        return None
    rectangles = list(options.values())
    ordered = sorted(rectangles)
    require(max(box[1] for box in rectangles) - min(box[1] for box in rectangles) <= 8 and
            len({box for box in rectangles}) == 4 and
            all(left[2] <= right[0] for left, right in zip(ordered, ordered[1:])),
            'Observed numbers are not the four answer buttons')
    require(a + b in options, 'Correct answer is absent from live options')
    return {'prompt': prompt_text, 'operands': [a, b], 'answer': a + b,
            'task_index': next(iter(indexes)),
            'options': {str(key): list(value) for key, value in sorted(options.items())},
            'target_bounds': list(options[a + b])}


class AndroidProbe:
    def __init__(self, out: Path, result: dict):
        sys.path.insert(0, str(ROOT / '.github/probes'))
        self.creative = importlib.import_module('creative_android_probe')
        self.base, self.live = self.creative.base, self.creative.live
        self.out, self.result = out, result
        self.command_serial = 0
        self.ui_serial = 0
        self.width, self.height = 0, 0
        self.base.adb = self.adb
        self.day = ''
        self.profile = None
        self.school = None
        self.children = {}
        self.originals = {}

    def ref(self, path: Path) -> dict:
        return {'file': path.relative_to(self.out).as_posix(),
                'bytes': path.stat().st_size, 'sha256': digest(path)}

    def command(self, *arguments: str, timeout=60, check=True) -> str:
        self.command_serial += 1
        name = f'command-{self.command_serial:04d}'
        began = time.monotonic()
        row = {'arguments': list(arguments)}
        try:
            completed = subprocess.run(arguments, capture_output=True, timeout=timeout, cwd=ROOT)
            stdout, stderr = completed.stdout, completed.stderr
            row['return_code'] = completed.returncode
        except subprocess.TimeoutExpired as error:
            stdout, stderr = error.stdout or b'', error.stderr or b''
            row.update(error='timeout', timeout_seconds=timeout)
            raise
        finally:
            for kind, data in (('stdout', locals().get('stdout', b'')),
                               ('stderr', locals().get('stderr', b''))):
                path = self.out / f'{name}-{kind}.txt'
                path.write_bytes(data)
                row[kind] = self.ref(path)
            row['wall_seconds'] = round(time.monotonic() - began, 3)
            with (self.out / 'android-actions.jsonl').open('a') as stream:
                stream.write(json.dumps(row, ensure_ascii=False) + '\n')
        text = stdout.decode('utf-8', errors='replace')
        combined = text + stderr.decode('utf-8', errors='replace')
        if check and completed.returncode:
            raise RuntimeError(f'Command failed ({completed.returncode}): {arguments}\n{combined.strip()}')
        return text.strip()

    def adb(self, *args: str, timeout=60, check=True) -> str:
        return self.command('adb', *args, timeout=timeout, check=check)

    def write_text(self, name: str, value: str) -> dict:
        path = self.out / name
        path.write_text(value)
        return self.ref(path)

    def nodes(self, tag: str):
        self.ui_serial += 1
        name = f'{tag}-ui-{self.ui_serial:04d}'
        nodes = self.live.live_nodes(self.out, name)
        return nodes, self.ref(self.out / (name + '.xml'))

    def preferences(self, tag: str):
        raw = self.adb('exec-out', 'cat',
                       f'/data/user/0/{PACKAGE}/shared_prefs/FlutterSharedPreferences.xml')
        return parse_preferences(raw), self.write_text(tag + '-preferences.xml', raw)

    def scroll(self, nodes, direction: str, fraction: float) -> bool:
        views = [node_bounds(node, self.width, self.height) for node in nodes
                 if node.get('package') == PACKAGE and node.get('scrollable') == 'true']
        views = [box for box in views if box and box[3] - box[1] > box[2] - box[0]]
        if not views:
            return False
        x0, y0, x1, y1 = max(views, key=lambda box: (box[2]-box[0])*(box[3]-box[1]))
        low = round(y0 + (y1-y0)*(1-fraction)/2)
        high = round(y1 - (y1-y0)*(1-fraction)/2)
        start, end = (low, high) if direction == 'up' else (high, low)
        x = str((x0+x1)//2)
        self.adb('shell', 'input', 'swipe', x, str(start), x, str(end), '400')
        time.sleep(.7)
        return True

    def seek(self, tag: str, select, *, scroll=False, timeout=150, scroll_fraction=.55):
        """Return two fresh stable observations; scroll only when explicitly allowed."""
        deadline = time.monotonic() + timeout
        previous = None
        for direction in (('up', 'down') if scroll else ('none',)):
            edge_signature, edge_repeats = None, 0
            for _ in range(40 if scroll else 80):
                require(time.monotonic() < deadline, 'Live UI deadline: ' + tag)
                nodes, xml = self.nodes(tag)
                if self.creative.recover_launcher_dialog(self.out, nodes, tag):
                    previous = None
                    continue
                selected = select(nodes)
                if selected is not None:
                    if previous is not None and selected == previous['selected']:
                        return selected, nodes, [previous['xml'], xml]
                    previous = {'selected': selected, 'xml': xml}
                    time.sleep(.65)
                    continue
                previous = None
                if direction != 'none':
                    signature = tuple((node.get('bounds'), tuple(labels(node))) for node in nodes
                                      if node.get('package') == PACKAGE)
                    edge_repeats = edge_repeats + 1 if signature == edge_signature else 0
                    edge_signature = signature
                    # Two repeated post-swipe hierarchies identify the edge.
                    # Avoid repeatedly dragging the same settled end for minutes.
                    if edge_repeats >= 2:
                        break
                    self.scroll(nodes, direction, scroll_fraction)
                time.sleep(.4)
        raise RuntimeError('Required live UI state missing: ' + tag)

    def target(self, nodes, label: str, *, navigation=False):
        candidates = matching(nodes, label, self.width, self.height)
        if navigation:
            candidates = [node for node in candidates if set(labels(node)) == {label}]
        if not candidates:
            return None
        node = min(candidates, key=lambda item: (
            item.get('clickable') != 'true',
            (node_bounds(item, self.width, self.height)[2] -
             node_bounds(item, self.width, self.height)[0]) *
            (node_bounds(item, self.width, self.height)[3] -
             node_bounds(item, self.width, self.height)[1])))
        return {'label': label, 'bounds': list(node_bounds(node, self.width, self.height))}

    def touch(self, target: dict, tag: str, observations: list) -> None:
        bounds = target.get('bounds', target.get('target_bounds'))
        x0, y0, x1, y1 = bounds
        event = {'tag': tag, 'target': target, 'fresh_observations': observations,
                 'input': 'real 120 ms finger press at the observed bounds center'}
        with (self.out / 'ui-actions.jsonl').open('a') as stream:
            stream.write(json.dumps(event, ensure_ascii=False) + '\n')
        x, y = str((x0+x1)//2), str((y0+y1)//2)
        self.adb('shell', 'input', 'swipe', x, y, x, y, '120')
        time.sleep(2)

    def tap(self, label: str, tag: str, *, scroll=True, navigation=False) -> None:
        target, _, observations = self.seek(
            tag, lambda nodes: self.target(nodes, label, navigation=navigation), scroll=scroll)
        self.touch(target, tag, observations)

    def see(self, label: str, tag: str, *, scroll=False):
        return self.seek(tag, lambda nodes: self.target(nodes, label), scroll=scroll)

    def checkpoint(self, tag: str, *, expected_labels=()) -> dict:
        """Read/capture only: in particular, never scroll to make a checkpoint pass."""
        nodes, xml = self.nodes(tag)
        for label in expected_labels:
            require(self.target(nodes, label) is not None, 'Checkpoint label absent: ' + label)
        capture = self.creative.capture(self.out, tag)
        self.width, self.height = capture['width'], capture['height']
        prefs, stored = self.preferences(tag)
        foreground = self.write_text(tag + '-foreground.txt', self.base.foreground())
        row = {'tag': tag, 'xml': xml, 'capture': capture,
               'preferences': stored, 'foreground': foreground,
               'expected_visible_labels': list(expected_labels)}
        self.result['checkpoints'].append(row)
        print('[ProfileAndroid] checkpoint:', tag, flush=True)
        return prefs

    def type_text(self, value: str, tag: str) -> None:
        require(re.fullmatch(r'[A-Za-z0-9]+', value) is not None, 'Only fictional simple probe names')

        def field(nodes):
            candidates = [node for node in nodes if node.get('package') == PACKAGE and
                          node.get('class') == 'android.widget.EditText' and
                          node_bounds(node, self.width, self.height)]
            require(len(candidates) <= 1, 'Ambiguous text input')
            return None if not candidates else {
                'bounds': list(node_bounds(candidates[0], self.width, self.height)),
                'text': candidates[0].get('text', ''),
            }

        target, _, seen = self.seek(tag + '-field', field, timeout=45)
        self.touch(target, tag + '-field-focus', seen)
        prefix = ''
        for character in value:
            self.adb('shell', 'input', 'text', character)
            prefix += character
            self.seek(tag + '-typed-' + str(len(prefix)),
                      lambda nodes: prefix if (field(nodes) or {}).get('text') == prefix else None,
                      timeout=30)
        self.checkpoint(tag + '-typed')
        ime = self.adb('shell', 'settings', 'get', 'secure', 'default_input_method').split('/', 1)[0]
        nodes, _ = self.nodes(tag + '-ime')
        if any(node.get('package') == ime for node in nodes):
            self.adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
            time.sleep(1)
        self.tap('Speichern', tag + '-save', scroll=False)

    def parent(self, tag: str) -> None:
        self.tap('Profil', tag + '-profile', navigation=True)
        self.tap('Profil\nbearbeiten', tag + '-edit')
        self.see('Lehrerbereich öffnen', tag + '-teacher-entry', scroll=True)

    def teacher(self, tag: str) -> None:
        self.parent(tag)
        self.tap('Lehrerbereich öffnen', tag + '-teacher')
        self.see('Lehrerbereich', tag + '-dashboard')

    def academy(self, tag: str, expected: int) -> dict:
        self.tap('Lernen', tag + '-learn', navigation=True)
        label = f'{expected} von 3 Aufgaben geschafft'
        self.see(label, tag + '-daily', scroll=True)
        prefs = self.checkpoint(tag, expected_labels=(label,))
        owner = prefs.get(ACTIVE) or None
        require_progress(prefs, owner, expected, self.day,
                         require_scoped=bool(owner and expected))
        return prefs

    def open_plus(self, tag: str) -> None:
        self.tap('1. Klasse, 6-7 Jahre', tag + '-grade')
        self.tap('Plus bis 10', tag + '-topic')
        self.see('Mathe-Abenteuer', tag + '-title', scroll=True)

    def answer(self, tag: str, index: int, correct: int, owner: str | None) -> None:
        def question(nodes):
            current = plus_question(nodes, self.width, self.height)
            if current is not None:
                require(current['task_index'] == index, 'Unexpected task index before actual answer')
            return current

        target, _, observations = self.seek(
            tag + '-question', question, scroll=True, scroll_fraction=.18)
        self.checkpoint(tag + '-before')
        # The checkpoint may take time: authorize the touch using a new stable pair.
        refreshed, _, fresh = self.seek(tag + '-answer-fresh', question, timeout=45)
        require(target == refreshed, 'Plus task or options moved before the real answer')
        self.touch(refreshed, tag + '-answer', fresh)
        self.see(f'Aufgabe {index + 1} / 30', tag + '-saved-next', scroll=True)
        last_error = None
        for attempt in range(40):
            prefs, stored = self.preferences(f'{tag}-save-{attempt:02d}')
            try:
                state = require_progress(prefs, owner, correct, self.day,
                                         require_scoped=owner is not None)
                break
            except RuntimeError as error:
                last_error = error
                time.sleep(.5)
        else:
            raise RuntimeError('Real Plus answer did not reach Android storage: ' + str(last_error))
        self.result['answers'].append({
            'tag': tag, 'owner': owner, 'observed_question': refreshed,
            'before_question_observations': observations, 'touch_observations': fresh,
            'saved_preferences': stored, 'saved_state': state,
            'next_task_index': index + 1,
        })
        self.checkpoint(tag + '-saved', expected_labels=(f'Aufgabe {index + 1} / 30',))

    def select_child(self, name: str, tag: str) -> None:
        self.teacher(tag)
        self.tap(name, tag + '-child')
        self.see(name, tag + '-child-title')
        prefs, _ = self.preferences(tag + '-before-link')
        require(prefs.get(ACTIVE) != self.children[name], 'Expected an actual A/B switching action')
        self.tap('Gerät zuordnen', tag + '-link')
        self.see('Zuordnung lösen', tag + '-linked')
        caption = f'{name} nutzt dieses Gerät. Neue Aufgaben landen im Lernbericht von {name}.'
        self.see(caption, tag + '-device-caption', scroll=True)
        prefs = self.checkpoint(tag + '-linked', expected_labels=(caption, 'Zuordnung lösen'))
        require(prefs.get(ACTIVE) == self.children[name], 'UI device link did not persist the selected child')
        self.preserved(prefs)
        self.tap('Zurück', tag + '-back-child', scroll=False)
        self.tap('Zurück', tag + '-back-teacher', scroll=False)

    def preserved(self, prefs: dict) -> None:
        require(prefs.get(PROFILE) == self.profile, 'Onboarding profile changed during migration/switch')
        require(prefs.get(SCHOOL) == self.school and school_children(prefs) == self.children,
                'Actual UI-created school identities changed')
        require_claim(prefs, self.children['Alina'], self.originals)

    def success_without_scroll(self) -> None:
        # No seek(scroll=True), navigation or swipe is permitted in this method.
        self.see('Lernstand zugeordnet', 'assignment-success-visible', scroll=False)
        self.see(SUCCESS_TEXT, 'assignment-success-body-visible', scroll=False)
        nodes, xml = self.nodes('assignment-success-bounds')
        title = self.target(nodes, 'Lernstand zugeordnet')
        body = self.target(nodes, SUCCESS_TEXT)
        require(title is not None and body is not None, 'Assignment confirmation left the visible surface')
        content = [min(title['bounds'][0], body['bounds'][0]),
                   min(title['bounds'][1], body['bounds'][1]),
                   max(title['bounds'][2], body['bounds'][2]),
                   max(title['bounds'][3], body['bounds'][3])]
        viewports = [node_bounds(node, self.width, self.height) for node in nodes
                     if node.get('package') == PACKAGE and node.get('scrollable') == 'true']
        viewports = [box for box in viewports if box and
                     box[0] <= content[0] < content[2] <= box[2] and
                     box[1] < content[1] < content[3] < box[3]]
        require(bool(viewports), 'Whole confirmation text is not inside the live scroll viewport')
        prefs = self.checkpoint('assignment-success-no-test-scroll',
                                expected_labels=('Lernstand zugeordnet', SUCCESS_TEXT))
        self.preserved(prefs)
        self.result['assignment_success_visibility'] = {
            'no_test_scroll_after_confirmation': True, 'xml': xml,
            'heading_bounds': title['bounds'], 'body_bounds': body['bounds'],
            'content_bounds': content,
            'scroll_viewport': list(min(viewports, key=lambda box: (box[2]-box[0])*(box[3]-box[1]))),
            'scope': 'Complete semantic heading/body bounds; original PNG retained for visual card review',
        }

    def apk_identity(self, path: Path, tag: str, source: str, version: int,
                     version_name: str, expected_hash: str, expected_size: int | None = None) -> dict:
        actual_hash, actual_size = digest(path), path.stat().st_size
        require(actual_hash == expected_hash and
                (expected_size is None or actual_size == expected_size), tag + ' APK bytes mismatch')
        sys.path.insert(0, str(ROOT / 'scripts'))
        verifier = importlib.import_module('verify_android_apk')
        tool = Path(verifier.find_apksigner()).resolve()
        badging = self.command(str(tool.parent / 'aapt'), 'dump', 'badging', str(path), timeout=120)
        manifest = re.findall(r"^package: name='([^']+)' versionCode='([0-9]+)' versionName='([^']+)'",
                              badging, re.M)
        require(manifest == [(PACKAGE, str(version), version_name)], tag + ' actual APK manifest mismatch')
        # The existing verifier checks every actual signer against the stable certificate.
        verified = self.command(sys.executable, str(ROOT / 'scripts/verify_android_apk.py'),
                                str(path), timeout=180)
        require(verified == 'Verified stable APK signing certificate (SHA-256): ' + CERTIFICATE,
                tag + ' actual APK signing certificate mismatch')
        self.write_text(tag + '-aapt.txt', badging)
        self.write_text(tag + '-certificate.txt', verified)
        return {'apk_source_commit': source, 'versionCode': version, 'versionName': version_name,
                'sha256': actual_hash, 'bytes': actual_size, 'package': PACKAGE,
                'signingCertificateSha256': CERTIFICATE}

    def installed(self, tag: str, identity: dict) -> dict:
        package = self.creative.package_identity(self.out, tag)
        require(re.match(r'^' + str(identity['versionCode']) + r'(?:\s|$)', package['versionCode']) and
                package['versionName'] == identity['versionName'], tag + ' PackageManager version mismatch')
        paths = self.adb('shell', 'pm', 'path', PACKAGE)
        path_lines = paths.splitlines()
        require(len(path_lines) == 1 and path_lines[0].startswith('package:') and
                path_lines[0].endswith('/base.apk'), 'Installed APK path is not unique')
        remote = path_lines[0].removeprefix('package:')
        hashed = self.adb('shell', 'toybox', 'sha256sum', remote, timeout=180)
        size = self.adb('shell', 'toybox', 'stat', '-c', '%s', remote)
        proof = installed_bytes(paths, hashed, size, identity['sha256'], identity['bytes'])
        proof['raw'] = {
            'pm_path': self.write_text(tag + '-pm-path.txt', paths),
            'sha256sum': self.write_text(tag + '-installed-sha256.txt', hashed),
            'stat': self.write_text(tag + '-installed-stat.txt', size),
            'package': self.ref(self.out / (tag + '-package.txt')),
            'uid': self.ref(self.out / (tag + '-package-uid.txt')),
        }
        return {'package_manager': package, 'installed_apk': proof}

    def execute(self, baseline: Path, candidate: Path, expected_hash: str) -> None:
        proof_path = candidate.parent / 'BUILD-PROVENANCE.json'
        proof = strict_json(proof_path.read_text())
        require(proof.get('flutter_source_commit') == APK_SOURCE and
                proof.get('tracked_source_clean') is True and
                proof.get('godot', {}).get('revision') == GODOT_SOURCE and
                proof.get('signingCertificateSha256') == CERTIFICATE and
                proof.get('package') == PACKAGE and type(proof.get('versionCode')) is int and
                proof['versionCode'] == 1920 and proof.get('versionName') == '0.12.13' and
                proof.get('sha256') == expected_hash and
                type(proof.get('bytes')) is int and proof['bytes'] == candidate.stat().st_size,
                'Candidate BUILD-PROVENANCE does not bind exact APK 1920')
        copied = self.out / 'candidate-BUILD-PROVENANCE.json'
        copied.write_bytes(proof_path.read_bytes())
        self.result['candidate_provenance'] = self.ref(copied)
        self.result['baseline'] = self.apk_identity(
            baseline, 'baseline', BASELINE_SOURCE, 1919, '0.12.12', BASELINE_SHA256, BASELINE_BYTES)
        self.result['baseline'].update(godot=BASELINE_GODOT,
                                       source_run=BASELINE_RUN, artifact_id=BASELINE_ARTIFACT)
        self.result['candidate'] = self.apk_identity(
            candidate, 'candidate', APK_SOURCE, 1920, '0.12.13', expected_hash)
        self.result['emulator_root_readiness'] = self.creative.ensure_rooted_emulator(self.adb, self.out)
        self.result['serial'] = self.result['emulator_root_readiness']['serial']
        self.result['android_sdk'] = int(self.adb('shell', 'getprop', 'ro.build.version.sdk'))
        require(self.result['android_sdk'] == 35, 'This narrowly scoped probe requires API 35')
        require(not self.adb('shell', 'pm', 'path', PACKAGE, check=False),
                'Use a fresh disposable emulator; existing application data must not be cleared')
        self.base.display(1080, 2400, 480)
        self.creative.device_rotation(self.out, 'phone-upright', 0)
        initial = self.creative.capture(self.out, 'emulator-surface')
        self.width, self.height = initial['width'], initial['height']
        require((self.width, self.height) == (1080, 2400), 'Unexpected actual portrait surface')
        self.adb('shell', 'svc', 'wifi', 'disable')
        self.adb('shell', 'svc', 'data', 'disable')
        self.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        require(self.adb('shell', 'settings', 'get', 'global', 'airplane_mode_on') == '1',
                'Offline mode was not confirmed')
        self.day = self.adb('shell', 'date', '+%F')
        require(re.fullmatch(r'[0-9]{4}-[0-9]{2}-[0-9]{2}', self.day), 'Missing actual device day')
        self.result.update(device_day=self.day, offline=True)
        self.adb('logcat', '-c')
        installed = self.adb('install', '-r', '--no-streaming', str(baseline), timeout=240)
        require('Success' in installed.splitlines(), 'Actual baseline install failed')
        self.result['baseline_install'] = self.installed('baseline-installed', self.result['baseline'])
        self.base.launch(self.out, 'baseline-launch')
        onboarding = self.creative.onboard(self.out)
        require(onboarding.get('profile_name') == 'LumoTest', 'Real onboarding profile missing')
        self.result['onboarding'] = onboarding
        prefs = self.checkpoint('baseline-onboarded')
        self.profile = prefs.get(PROFILE)
        require(isinstance(self.profile, str) and
                strict_json(self.profile).get('name') == 'LumoTest', 'Onboarding did not persist the real name')
        require(not prefs.get(ACTIVE), 'Baseline unexpectedly has an active school child')
        self.academy('baseline-learning-empty', 0)
        self.open_plus('baseline-plus')
        self.answer('baseline-answer-one', 1, 1, None)
        self.answer('baseline-answer-two', 2, 2, None)
        self.academy('baseline-learning-two', 2)
        self.teacher('baseline-school')
        self.tap('Klasse anlegen', 'baseline-create-class', scroll=False)
        self.type_text('1a', 'baseline-class-name')
        self.tap('1. Klasse', 'baseline-class-grade', scroll=False)
        self.see('1a · 1. Kl.', 'baseline-class-visible', scroll=True)
        self.checkpoint('baseline-class-created')
        for name in ('Alina', 'Boris'):
            self.tap('Kind', 'baseline-add-' + name)
            self.type_text(name, 'baseline-name-' + name)
            self.see(name, 'baseline-created-' + name, scroll=True)
            self.checkpoint('baseline-child-' + name)
        prefs = self.checkpoint('baseline-two-children')
        self.children = school_children(prefs)
        self.school = prefs[SCHOOL]
        require(not prefs.get(ACTIVE), 'Creating children unexpectedly assigned the device')
        require_progress(prefs, None, 2, self.day)
        self.originals = {key: prefs['flutter.' + key] for key in LEGACY_KEYS}
        require(all(isinstance(value, str) for value in self.originals.values()), 'Missing real legacy values')
        self.result.update(children=self.children, preserved_legacy_values=self.originals)
        self.adb('shell', 'am', 'force-stop', PACKAGE)
        update = self.adb('install', '-r', '--no-streaming', str(candidate), timeout=240)
        require('Success' in update.splitlines(), 'Actual in-place update failed')
        self.result['candidate_install'] = self.installed('candidate-installed', self.result['candidate'])
        before = self.result['baseline_install']['package_manager']
        after = self.result['candidate_install']['package_manager']
        require(all(before[key] == after[key] for key in ('userId', 'firstInstallTime')),
                'Update did not preserve installation identity')
        self.base.launch(self.out, 'candidate-offline-launch')
        prefs = self.checkpoint('candidate-before-assignment')
        require(prefs.get(PROFILE) == self.profile and prefs.get(SCHOOL) == self.school and
                school_children(prefs) == self.children and not prefs.get(ACTIVE) and
                not prefs.get(CLAIM), 'Update changed the identities or automatically claimed ambiguous history')
        require(all(prefs.get('flutter.' + key) == value for key, value in self.originals.items()),
                'Update changed the genuine legacy values before assignment')
        self.parent('adult-assignment')
        self.see('Vorhandenen Lernstand zuordnen', 'assignment-card', scroll=True)
        self.tap('Kind auswählen', 'assignment-choose')
        self.tap('Alina · 1a', 'assignment-alina')
        self.tap('Lernstand zuordnen', 'assignment-request')
        self.see('Lernstand für Alina übernehmen?', 'assignment-dialog', scroll=False)
        self.checkpoint('assignment-adult-dialog',
                        expected_labels=('Lernstand für Alina übernehmen?', 'Als Erwachsene:r zuordnen'))
        self.tap('Als Erwachsene:r zuordnen', 'assignment-adult-confirm', scroll=False)
        self.success_without_scroll()
        self.select_child('Alina', 'first-A')
        first_a = self.academy('A-has-two', 2)
        self.preserved(first_a)
        a_state = require_progress(first_a, self.children['Alina'], 2, self.day, require_scoped=True)
        self.select_child('Boris', 'first-B')
        empty_b = self.academy('B-is-empty', 0)
        self.preserved(empty_b)
        require(learning_signature(learning_state(empty_b, self.children['Alina'])) ==
                learning_signature(a_state), 'Switch to B changed A')
        self.open_plus('B-plus')
        self.answer('B-answer-one', 1, 1, self.children['Boris'])
        stored_b = self.academy('B-has-one', 1)
        self.preserved(stored_b)
        require(learning_signature(learning_state(stored_b, self.children['Alina'])) ==
                learning_signature(a_state), 'B answer changed A')
        b_state = require_progress(stored_b, self.children['Boris'], 1, self.day, require_scoped=True)
        self.adb('shell', 'am', 'force-stop', PACKAGE)
        self.base.launch(self.out, 'candidate-restart')
        restarted = self.checkpoint('candidate-restarted')
        self.preserved(restarted)
        require(restarted.get(ACTIVE) == self.children['Boris'], 'Restart lost the active B selection')
        self.academy('restart-B-has-one', 1)
        self.select_child('Alina', 'restart-A')
        self.academy('restart-A-has-two', 2)
        self.select_child('Boris', 'restart-B')
        final = self.academy('final-B-has-one', 1)
        self.preserved(final)
        require(learning_signature(learning_state(final, self.children['Alina'])) ==
                learning_signature(a_state) and
                learning_signature(learning_state(final, self.children['Boris'])) ==
                learning_signature(b_state),
                'A/B durable learning state changed across restart and switching')
        require(self.adb('shell', 'date', '+%F') == self.day, 'Device day changed during daily-count proof')
        require(self.adb('shell', 'settings', 'get', 'global', 'airplane_mode_on') == '1',
                'Offline state changed during probe')
        self.result['final_installed_apk'] = self.installed('final-installed', self.result['candidate'])
        self.result['final_learning_states'] = {
            name: learning_state(final, owner) for name, owner in self.children.items()
        }
        self.result['ui_count_sequence'] = [
            ['A', 2], ['B', 0], ['B', 1], ['restart-B', 1], ['restart-A', 2], ['final-B', 1],
        ]
        crashes = self.adb('logcat', '-d', '-b', 'crash')
        self.write_text('crash-buffer.txt', crashes)
        require(PACKAGE not in crashes, 'App appears in the actual Android crash buffer')
        require(len(self.result['answers']) == 3, 'Not all three actual UI answers were observed')

    def diagnostics(self) -> None:
        errors = []
        for name, action in (
            ('failure-ui', lambda: self.nodes('failure')),
            ('failure-png', lambda: self.creative.capture(self.out, 'failure')),
            ('failure-preferences', lambda: self.preferences('failure')),
            ('failure-foreground', lambda: self.write_text('failure-foreground.txt', self.base.foreground())),
        ):
            try:
                action()
            except Exception as error:
                errors.append({'diagnostic': name, 'error': str(error)})
        self.result['diagnostic_errors'] = errors


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args(argv)
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    if (out / 'result.json').exists():
        print('[ProfileAndroid] FAIL: existing result.json is preserved; use a fresh evidence directory',
              file=sys.stderr, flush=True)
        return 1
    result = {
        'schema_version': 1, 'status': 'RUNNING', 'apk_source_commit': APK_SOURCE,
        'godot_source_commit': GODOT_SOURCE, 'qa_commit': None,
        'qa_probe_sha256': digest(Path(__file__)), 'checkpoints': [], 'answers': [],
        'scope': 'Real Android 1919-to-1920 adult legacy assignment and per-child Plus storage',
        'not_tested': ['wallet ownership', 'separate reading/writing storage', 'native game saves',
                       'physical Samsung/Fold', 'FPS', 'teacher assignment completion',
                       'unrelated full CI gates'],
    }
    probe = None
    exit_code = 1
    try:
        expected = os.environ.get('LUMO_CANDIDATE_SHA256', '')
        require(re.fullmatch(r'[a-f0-9]{64}', expected) is not None,
                'LUMO_CANDIDATE_SHA256 must bind the exact built APK before any Android action')
        probe = AndroidProbe(out, result)
        result['qa_commit'] = probe.command('git', 'rev-parse', 'HEAD')
        require(re.fullmatch(r'[a-f0-9]{40}', result['qa_commit']) is not None, 'Missing actual QA commit')
        result['qa_tracked_source_clean'] = not probe.command(
            'git', 'status', '--porcelain', '--untracked-files=no')
        require(result['qa_tracked_source_clean'], 'Tracked QA sources changed before execution')
        probe.execute(args.baseline.resolve(), args.candidate.resolve(), expected)
        # Required final diagnostic reads happen before PASS is possible.
        probe.write_text('logcat.txt', probe.adb('logcat', '-d'))
        result['status'] = 'PASS'
        exit_code = 0
    except Exception as error:
        result.update(status='FAIL', error=str(error), traceback=traceback.format_exc())
        if probe is not None:
            probe.diagnostics()
            try:
                probe.write_text('logcat.txt', probe.adb('logcat', '-d', check=False))
            except Exception as diagnostic_error:
                result.setdefault('diagnostic_errors', []).append(
                    {'diagnostic': 'logcat', 'error': str(diagnostic_error)})
    finally:
        (out / 'result.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    print('[ProfileAndroid]', result['status'], result.get('error', result['scope']), flush=True)
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
