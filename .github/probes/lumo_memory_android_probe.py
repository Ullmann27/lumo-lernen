#!/usr/bin/env python3
"""Exercise actual Android Memory controls and read their authoritative receipts.

The private deck is read only as an explicitly recorded QA selection oracle.
No save, request, lifecycle, preference, rule or reward value is written. The
normal tour must already have passed on the same installed APK and runtime.
Desktop fixtures are accepted only by the explicit pure-validator test option.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback

_COMMON_PATH = Path(__file__).with_name('lumo_table_authority_android_shared.py')
_SPEC = importlib.util.spec_from_file_location('memory_table_authority_shared', _COMMON_PATH)
common = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(common)

PACKAGE = common.PACKAGE
FILES = common.FILES
SELF = '.github/probes/lumo_memory_android_probe.py'
LAYOUT = FILES + '/memory_layout_v1.json'
SESSION = FILES + '/lumo_table_games_session_v1/'
ROUND_PREFIX = 'flutter.lumo.memory.round.v1.'
COUNTS = {'leicht': 8, 'mittel': 12, 'schwer': 16, 'knifflig': 20, 'profi': 24}
MOTIFS = frozenset(('panda', 'giraffe', 'lumo', 'hase', 'pinguin', 'stern',
                    'laterne', 'truhe', 'note', 'fahne', 'pilz', 'stein'))
TOUR_STEPS = frozenset(('apk-identity', 'launch', 'onboarding', 'navigate-start', 'navigate-lernen',
    'atelier-roundtrip', 'navigate-spiele', 'open-kart', 'start-kart-race', 'race-running', 'race-hud',
    'race-drive', 'pause-menu', 'return-from-kart', 'learning-state-after-kart',
    'lernen-usable-after-kart', 'profile-after-kart', 'restart-keeps-learning-state',
    'display-fold_offen', 'display-fold_aussen', 'display-quer'))
require, write, sha, parse_json = common.require, common.write, common.sha, common.parse_json
vector, rectangle, inside = common.vector, common.rectangle, common.inside
project, to_decor, same_numbers = common.project, common.to_decor, common.same_numbers
SOURCE_FILES = (
    SELF, '.github/probes/lumo_table_authority_android_shared.py',
    '.github/probes/creative_android_probe.py', '.github/probes/modernization_android_tour.py',
    '.github/probes/lumo_studio_surfaces_android_probe.py',
    '.github/probes/studio_creative_android_probe.py',
    'scripts/probes/pr207_android_smoke.py', 'scripts/probes/pr207_android_ui_probe.py',
    'tools/android_qa/kart_tour_evidence.py',
    'tools/auto_install/TableGamesBridge.kt', 'tools/auto_install/TableGameActivity.kt',
    'tools/auto_install/TableAuthorityService.kt', 'tools/auto_install/TableGameIntent.java',
    'lib/features/lumo3d/native_table_transport.dart',
    'lib/features/lumo3d/native_method_table_transport.dart',
    'lib/features/games/memory/memory_rules.dart',
    'lib/features/games/memory/memory_round.dart',
    'lib/features/games/memory/memory_table_session.dart',
    'lib/features/games/memory/memory_flutter_adapter.dart',
    'lib/features/games/memory/lumo_memory_game.dart',
    'lib/domain/games/memory_board.dart',
)


def integer(value, name, minimum=0, maximum=1_000_000_000):
    require(type(value) is int and minimum <= value <= maximum, 'Invalid integer: ' + name)
    return value


def allowed_read(path):
    return path == LAYOUT or re.fullmatch(
        re.escape(SESSION) + r'[a-f0-9]{32}/(state|request|lifecycle)\.json', path) is not None


def check_tour(prior, apk_sha256, api):
    require(type(prior) is dict and prior.get('status') == 'PASS' and
            prior.get('apk_sha256') == apk_sha256 and prior.get('android_sdk') == str(api),
            'Normal real tour not passed on this binary/runtime')
    steps = prior.get('steps')
    require(type(steps) is list and len(steps) == 21 and
            all(type(s) is dict and s.get('ok') is True for s in steps),
            'Every actual tour step must have passed')
    names = [s.get('step') for s in steps]
    require(all(type(name) is str for name in names) and set(names) == TOUR_STEPS,
            'Actual tour steps are missing, duplicated or unknown')


def check_state(state, owner=None):
    require(type(state) is dict and type(state.get('schema')) is int and
            state['schema'] == 1 and state.get('game') == 'memory', 'Wrong Memory state')
    for key, length in (('token', 32), ('roundId', 32), ('owner', 64)):
        require(type(state.get(key)) is str and
                re.fullmatch('[a-f0-9]{' + str(length) + '}', state[key]), 'Invalid ' + key)
    require(owner is None or state['owner'] == owner, 'Memory belongs to a different child')
    for key in ('revision', 'recordRevision'):
        integer(state.get(key), key, 1)
    for key in ('ack', 'rejected', 'kindPairs', 'lumoPairs', 'kindMoves', 'kindStreak'):
        integer(state.get(key), key)
    for key in ('paused', 'exit', 'reduceMotion', 'rewarded', 'canFlip', 'complete'):
        require(type(state.get(key)) is bool, 'Invalid boolean: ' + key)
    require(state.get('difficulty') in COUNTS and state.get('pack') in
            ('alle', 'tiere', 'weltall', 'garten'), 'Unknown original Memory settings')
    count = integer(state.get('count'), 'count', 8, 24)
    require(count == COUNTS[state['difficulty']], 'Card count differs from original difficulty')
    require(state.get('turn') in ('kind', 'lumo') and state.get('phase') in
            ('select', 'resolve', 'botFirst', 'botSecond', 'complete'), 'Unknown turn phase')
    integer(state.get('remainingMs'), 'remainingMs', 0, 900)
    cards = state.get('cards')
    require(type(cards) is list and len(cards) == count, 'Missing public cards')
    for index, card in enumerate(cards):
        require(type(card) is dict and type(card.get('index')) is int and card['index'] == index,
                'Public card indices changed')
        require(type(card.get('faceUp')) is bool and type(card.get('matched')) is bool,
                'Invalid public face state')
        require(not card['matched'] or card['faceUp'], 'A matched card is concealed')
        require((type(card.get('motif')) is str and card['motif'] in MOTIFS)
                if card['faceUp'] else card.get('motif') is None,
                'Hidden deck disclosed or unknown visible motif')
    require(sum(c['matched'] for c in cards) == 2 * (state['kindPairs'] + state['lumoPairs']),
            'Scores disagree with actual matched cards')
    require(state['kindPairs'] <= state['kindMoves'] and state['kindStreak'] <= state['kindPairs'],
            'Public move counters disagree')
    require(state['complete'] == (state['phase'] == 'complete') and
            state['complete'] == all(c['matched'] for c in cards), 'Invalid completion')
    require(not state['rewarded'] or state['complete'], 'Unfinished round paid')
    require(not state['canFlip'] or (not state['paused'] and not state['exit'] and
            state['phase'] == 'select' and state['turn'] == 'kind'), 'Invalid flip permission')
    exposed = sum(c['faceUp'] and not c['matched'] for c in cards)
    require(exposed <= 2, 'More than two unmatched cards exposed')
    require((state['remainingMs'] == 0) == (state['phase'] in ('select', 'complete')),
            'Public clock does not match its turn phase')
    require(state.get('error') is None, 'Authority reports an unconfirmed save')
    return state


def check_saved(saved, state):
    check_state(state)
    require(type(saved) is dict and type(saved.get('schema')) is int and saved['schema'] == 1 and
            saved.get('game') == 'memory' and type(saved.get('revision')) is int and
            saved.get('owner') == state['owner'] and saved.get('id') == state['roundId'] and
            saved.get('revision') == state['recordRevision'], 'Private saved identity differs')
    require(type(saved.get('paused')) is bool and type(saved.get('rewarded')) is bool and
            saved['rewarded'] == state['rewarded'], 'Private result receipt differs')
    rules = saved.get('rules')
    require(type(rules) is dict, 'Private round rules absent')
    for key in ('difficulty', 'pack', 'turn', 'phase', 'remainingMs', 'kindPairs',
                'lumoPairs', 'kindMoves', 'kindStreak', 'line'):
        require(rules.get(key) == state.get(key), 'Saved/public field differs: ' + key)
    deck = rules.get('cards')
    require(type(deck) is list and len(deck) == state['count'] and
            all(type(c) is str and c in MOTIFS for c in deck) and
            all(n == 2 for n in Counter(deck).values()), 'Private QA oracle is not a paired deck')
    for key in ('faceUp', 'matched'):
        require(type(rules.get(key)) is list and all(type(v) is bool for v in rules[key]) and
                rules[key] == [c[key] for c in state['cards']], 'Saved/public faces differ')
    for index, card in enumerate(state['cards']):
        require(card['motif'] == (deck[index] if card['faceUp'] else None),
                'Visible motif differs from the read-only saved deck')
    return rules


def check_ack(before, request, after, action, fields=None):
    check_state(before); check_state(after, before['owner'])
    fields = {} if fields is None else fields
    expected = {'token': before['token'], 'roundId': before['roundId'],
                'revision': before['revision'], 'action': action, **fields}
    require(type(request) is dict and set(request) == set(expected) | {'sequence'},
            'Unexpected request fields')
    require(all(request.get(k) == v and type(request.get(k)) is type(v)
                for k, v in expected.items()), 'Actual request does not match the observed control')
    sequence = integer(request.get('sequence'), 'sequence', 1)
    require(sequence > max(before['ack'], before['rejected']), 'Old request reused')
    require(after['token'] == before['token'] and after['roundId'] == before['roundId'] and
            after['revision'] > before['revision'] and after['ack'] == sequence and
            after['rejected'] < sequence, 'No positive current-session acknowledgement')
    if action == 'flip':
        index = integer(fields.get('index'), 'flip index', 0, before['count'] - 1)
        require(before['canFlip'] and not before['cards'][index]['faceUp'] and
                not before['cards'][index]['matched'] and
                after['recordRevision'] > before['recordRevision'], 'Invalid real card selection')
    if action in ('pause', 'resume'):
        require(after['paused'] == (action == 'pause'), 'Pause/resume state not acknowledged')
    return {'action': action, 'fields': fields, 'sequence': sequence,
            'revision_before': before['revision'], 'revision_after': after['revision']}


def check_bot_reply(before, after, saved_deck, second_index, sequence):
    """Bind a real Dart opponent reveal to the preceding child mismatch.

    The deck comes from the previously verified read-only save. Reading a new
    private save during a subsecond bot phase would race the live controller;
    the stable background pause is checked against disk separately.
    """
    check_state(before); check_state(after, before['owner'])
    require(before['turn'] == 'kind' and before['phase'] == 'select' and
            before['canFlip'], 'No preceding child selection')
    exposed = [c['index'] for c in before['cards'] if c['faceUp'] and not c['matched']]
    integer(second_index, 'second child index', 0, before['count'] - 1)
    integer(sequence, 'second child sequence', 1)
    require(type(saved_deck) is list and len(saved_deck) == before['count'] and
            len(exposed) == 1 and not before['cards'][second_index]['faceUp'] and
            not before['cards'][second_index]['matched'] and
            saved_deck[exposed[0]] != saved_deck[second_index],
            'The actual child cards were not a mismatch')
    require(after['token'] == before['token'] and after['roundId'] == before['roundId'] and
            after['revision'] > before['revision'] and after['recordRevision'] > before['recordRevision'] and
            sequence > max(before['ack'], before['rejected']) and after['ack'] == sequence and
            after['rejected'] == before['rejected'],
            'Bot observation crossed a session or another input')
    require(after['turn'] == 'lumo' and after['phase'] in ('botSecond', 'resolve') and
            not after['paused'] and not after['exit'] and not after['complete'] and
            after['kindPairs'] == before['kindPairs'] and after['kindMoves'] == before['kindMoves'] + 1,
            'No actual unfinished Dart opponent response')
    visible = [c for c in after['cards'] if c['faceUp'] and not c['matched']]
    require(1 <= len(visible) <= 2 and
            all(c['motif'] == saved_deck[c['index']] for c in visible),
            'Bot face differs from the unchanged saved deck')
    return {'visible_indices': [c['index'] for c in visible], 'phase': after['phase'],
            'record_revision': after['recordRevision'], 'scope': 'actual public Dart bot reveal'}


def frozen_round_equal(before, after):
    require(type(before) is dict and type(after) is dict, 'Saved rounds required')
    for key in ('schema', 'game', 'owner', 'id', 'rules', 'rewarded'):
        require(before.get(key) == after.get(key), 'Persisted round changed: ' + key)


def check_preservation(before, after, owner):
    require(type(before) is dict and type(after) is dict, 'Original preferences required')
    allowed = ROUND_PREFIX + owner
    left = {k: v for k, v in before.items() if k != allowed}
    right = {k: v for k, v in after.items() if k != allowed}
    require(left == right, 'A preference outside this child Memory round changed')
    return {'unchanged_keys': len(left), 'only_allowed_key': allowed,
            'unowned_legacy_memory_unchanged': True, 'other_profiles_and_wallet_unchanged': True}


def control_target(layout, identifier, density):
    rows = layout['cards'] if identifier.startswith('card_') else layout['buttons']
    view = {**layout, 'buttons': rows}
    target = common.button_target(view, identifier, density)
    if identifier.startswith('card_'):
        require(layout['canFlip'] and not layout['paused'], 'Card is blocked by current game state')
    return target


def check_layout(layout, state, image_size, density, pid, *, allow_fixture=False):
    check_state(state)
    require(type(layout) is dict and type(layout.get('schema')) is int and
            layout['schema'] == 1 and layout.get('game') == 'memory', 'Wrong Memory layout')
    require(layout.get('settled') is True and type(layout.get('pending')) is int and
            layout['pending'] == 0, 'Layout still transitioning')
    sources = ('android_window_insets', 'platform_fixture') if allow_fixture else ('android_window_insets',)
    require(layout.get('observation_source') in sources, 'Actual Android inset observation required')
    for key in ('token', 'owner', 'roundId', 'revision', 'recordRevision', 'ack', 'rejected',
                'paused', 'canFlip', 'turn', 'phase', 'difficulty', 'pack'):
        require(layout.get(key) == state.get(key) and type(layout.get(key)) is type(state.get(key)),
                'Stale/different Memory layout: ' + key)
    require(integer(layout.get('pid'), 'pid', 1) == pid, 'Native process changed')
    integer(layout.get('layout_sequence'), 'layout_sequence', 1)
    integer(layout.get('ticks_msec'), 'ticks_msec', 0, 2**63 - 1)
    require(abs(common.number(layout.get('density'), 'density') - density) < .01 and
            .5 <= density <= 6, 'Measured Android density differs')
    obs = layout['android_observation']
    decor = vector(obs['decor_size'], 2, 'decor_size')
    view = vector(obs['view_size'], 2, 'view_size')
    window = vector(layout['window_px'], 2, 'window_px')
    viewport = vector(layout['viewport_px'], 2, 'viewport_px')
    require(min(view + window + viewport) > 0 and same_numbers(decor, list(image_size)),
            'Screenshot size/rotation differs from actual decor')
    render = rectangle(obs['render_rect'], 'render_rect')
    require(inside(render, [0, 0, *decor]) and same_numbers(render[2:], view, .1),
            'Render view outside current decor')
    bars = vector(obs['system_insets'], 4, 'system_insets')
    insets = vector(obs['insets'], 4, 'insets')
    require(min(bars + insets) >= 0, 'Negative Android inset')
    expected = [max(0, bars[0] - render[0]), max(0, bars[1] - render[1]),
                max(0, render[0] + render[2] - (decor[0] - bars[2])),
                max(0, render[1] + render[3] - (decor[1] - bars[3]))]
    require(same_numbers(insets, expected, .15), 'Insets do not match actual render overlap')
    safe = [insets[0] * window[0] / view[0], insets[1] * window[1] / view[1],
            (view[0] - insets[0] - insets[2]) * window[0] / view[0],
            (view[1] - insets[1] - insets[3]) * window[1] / view[1]]
    require(same_numbers(rectangle(layout['safe_rect'], 'safe_rect'), safe, .2),
            'Safe rectangle differs from actual insets')
    page = integer(layout.get('page'), 'page', 0, 23)
    page_size = integer(layout.get('page_size'), 'page_size', 1, state['count'])
    require(page * page_size < state['count'], 'Page outside actual deck')
    rows = layout.get('cards')
    require(type(rows) is list and len(rows) == state['count'], 'Missing card geometry')
    projected = []
    for index, row in enumerate(rows):
        require(type(row) is dict and row.get('id') == 'card_' + str(index) and
                type(row.get('index')) is int and row['index'] == index, 'Ambiguous card geometry')
        for key in ('faceUp', 'matched', 'motif'):
            require(row.get(key) == state['cards'][index][key], 'Geometry has another public card')
        visible = page * page_size <= index < min((page + 1) * page_size, state['count'])
        require(row.get('visible') is visible, 'Reported page/card visibility differs')
        if not visible:
            continue
        center = vector(row['world_center'], 3, 'card world center')
        width, height = vector(row['world_size'], 2, 'card world size')
        require(width > 0 and height > 0, 'Empty physical card')
        # Exact production rest face depth, independent camera matrix math.
        quad = [project(layout, [center[0] + x * width, center[1] + y * height, center[2] + .057])
                for x, y in ((-.5, .5), (.5, .5), (.5, -.5), (-.5, -.5))]
        require(type(row.get('quad')) is list and len(row['quad']) == 4 and
                all(math.dist(a, vector(b, 2, 'reported corner')) <= 1
                    for a, b in zip(quad, row['quad'])), 'Native card differs from independent projection')
        rect = [min(p[0] for p in quad), min(p[1] for p in quad),
                max(p[0] for p in quad) - min(p[0] for p in quad),
                max(p[1] for p in quad) - min(p[1] for p in quad)]
        require(same_numbers(rectangle(row['rect_px'], 'card rect'), rect, 1) and inside(rect, safe),
                'Card touch surface differs from projected physical card')
        first, last = to_decor(layout, rect[:2]), to_decor(layout, [rect[0] + rect[2], rect[1] + rect[3]])
        require(min((last[k] - first[k]) / density for k in (0, 1)) >= 48 - .01,
                'Projected card is smaller than 48dp')
        if row.get('enabled') is True:
            control_target(layout, row['id'], density)
        projected.append({'index': index, 'world_center': center, 'world_size': [width, height],
                          'quad': [to_decor(layout, p) for p in quad]})
    buttons = layout.get('buttons')
    require(type(buttons) is list and len({b.get('id') for b in buttons}) == len(buttons),
            'Ambiguous actual buttons')
    for button in buttons:
        if button.get('visible') is True and button.get('enabled') is True and button.get('clipped') is False:
            control_target(layout, button['id'], density)
    require(bool(projected), 'No visible actual cards')
    return {'cards': projected, 'safe_rect': safe, 'page': page, 'page_size': page_size}


def face_pixel_change(before_image, after_image, before_layout, after_layout, index):
    """Check actual face change inside independently projected card interiors.

    This proves visible change, not image recognition of the motif. Motif
    identity is independently checked against the Dart public/private receipt.
    """
    require(before_image.size == after_image.size, 'Capture rotated during flip comparison')
    samples = []
    for layout, image in ((before_layout, before_image), (after_layout, after_image)):
        row = layout['cards'][index]
        require(row['visible'] is True, 'Pixel comparison requires the same visible card')
        center = vector(row['world_center'], 3, 'pixel card center')
        width, height = vector(row['world_size'], 2, 'pixel card size')
        values = []
        for x in range(-3, 4):
            for y in range(-4, 5):
                point = to_decor(layout, project(layout, [center[0] + x * width / 10,
                                  center[1] + y * height / 12, center[2] + .057]))
                px, py = map(round, point)
                require(0 <= px < image.width and 0 <= py < image.height, 'Card sample outside screenshot')
                values.append(image.getpixel((px, py))[:3])
        samples.append(values)
    differences = [sum(abs(a[k] - b[k]) for k in range(3)) / 3
                   for a, b in zip(samples[0], samples[1])]
    fraction = sum(d > 18 for d in differences) / len(differences)
    mean = sum(differences) / len(differences)
    require(fraction >= .22 and mean >= 16, 'Actual projected card has no verified face change')
    require(len(set(samples[1])) >= 8, 'Flat/blank image cannot prove a rendered card')
    return {'index': index, 'samples': len(differences), 'changed_fraction': fraction,
            'mean_channel_difference': mean, 'scope': 'visible change; no motif recognition claim'}


class AndroidProbe(common.AndroidProbe):
    def __init__(self, args):
        self.deadline = time.monotonic() + 600
        super().__init__(args)

    def adb(self, *args, timeout=60, check=True):
        value = self.base.command('adb', '-s', self.args.serial, *args,
                                  timeout=self.budget(timeout), check=check)
        require(time.monotonic() < self.deadline, 'Device command completed after the fixed total deadline')
        return value

    def budget(self, limit):
        remaining = min(limit, self.deadline - time.monotonic())
        require(remaining > 0, 'Fixed 600s Memory probe budget exhausted')
        return remaining

    def raw(self, path, label, limit=131072):
        require(allowed_read(path), 'Unapproved private read')
        started = time.time()
        result = subprocess.run(['adb', '-s', self.args.serial, 'exec-out', 'cat', path],
                                capture_output=True, timeout=self.budget(10))
        tag = self.tag(label)
        (self.out / (tag + '.raw')).write_bytes(result.stdout)
        (self.out / (tag + '.stderr')).write_bytes(result.stderr)
        write(self.out / (tag + '-read.json'), {'path': path, 'serial': self.args.serial,
              'started_unix_seconds': started, 'finished_unix_seconds': time.time(),
              'returncode': result.returncode, 'bytes': len(result.stdout),
              'sha256': hashlib.sha256(result.stdout).hexdigest()})
        require(result.returncode == 0 and 0 < len(result.stdout) <= limit, 'Missing/bounded read: ' + path)
        return parse_json(result.stdout), hashlib.sha256(result.stdout).hexdigest()

    def foreground(self):
        require('TableGameActivity' in self.base.foreground(), 'Memory table is not foreground')

    def state(self, token):
        value, _ = self.raw(SESSION + token + '/state.json', 'state')
        check_state(value, self.owner)
        require(value['token'] == token, 'Another table session is current')
        return value

    def wait(self, name, observe, accept, timeout=45):
        deadline = time.monotonic() + self.budget(timeout)
        errors = []
        while time.monotonic() < deadline:
            try:
                value = observe()
                if accept(value):
                    require(time.monotonic() < deadline, 'Observation exceeded deadline: ' + name)
                    return value
            except (RuntimeError, json.JSONDecodeError, KeyError, TypeError) as error:
                errors.append(str(error))
            time.sleep(.15)
        write(self.out / (self.tag(name) + '-failure.json'), {'last_errors': errors[-12:],
              'budget_seconds': timeout})
        raise RuntimeError(name + ' not observed within its unchanged budget')

    def saved(self, state):
        prefs = self.probe.prefs(self.out, self.tag('read-only-qa-save'))
        raw = prefs.get(ROUND_PREFIX + self.owner)
        require(type(raw) is str, 'Actual owner Memory round is absent')
        value = parse_json(raw)
        check_saved(value, state)
        return value

    def snapshot(self, name, *, expected_page=None):
        from PIL import Image
        deadline = time.monotonic() + self.budget(45)
        while time.monotonic() < deadline:
            try:
                self.foreground(); pid = self.pid()
                layout, digest = self.raw(LAYOUT, 'layout-before')
                require(expected_page is None or layout.get('page') == expected_page,
                        'Actual requested page has not settled yet')
                state = self.state(layout['token'])
                shot = self.probe.capture(self.out, self.tag(name), timeout=max(.01, deadline - time.monotonic()))
                with Image.open(self.out / shot['file']) as source:
                    geometry = check_layout(layout, state, source.size, self.density, pid)
                later_state = self.state(layout['token'])
                _, later_digest = self.raw(LAYOUT, 'layout-after')
                require(state == later_state and digest == later_digest, 'Capture crossed a state/layout transition')
                self.foreground(); require(pid == self.pid(), 'Capture crossed a native process transition')
                require(time.monotonic() < deadline, 'Capture/readbacks completed after their deadline')
                report = {'capture': shot, 'layout_sha256': digest, 'layout': layout,
                          'state': state, 'geometry': geometry}
                write(self.out / (self.tag(name) + '-observation.json'), report)
                return report
            except (RuntimeError, json.JSONDecodeError, KeyError, TypeError) as error:
                write(self.out / (self.tag(name) + '-rejected.json'), {'error': str(error)})
                time.sleep(.2)
        raise RuntimeError('No stable actual Memory geometry for ' + name)

    def touch(self, observation, identifier):
        target = control_target(observation['layout'], identifier, self.density)
        _, digest = self.raw(LAYOUT, 'touch-layout')
        self.foreground()
        require(digest == observation['layout_sha256'] and
                self.state(observation['state']['token']) == observation['state'] and
                self.pid() == observation['layout']['pid'], 'Observed target/session changed before touch')
        point = [round(v) for v in target['point']]
        self.events.append({'kind': 'actual_adb_touch', 'target': target, 'point': point,
                            'capture': observation['capture'], 'layout_sha256': digest,
                            'state': observation['state'], 'time_monotonic': time.monotonic()})
        write(self.out / 'input-events.json', self.events)
        self.adb('shell', 'input', 'tap', *map(str, point), timeout=self.budget(10))

    def action(self, observation, identifier, action, fields=None):
        before = observation['state']; token = before['token']
        self.touch(observation, identifier)
        request = self.wait('actual-' + action + '-request',
                            lambda: self.raw(SESSION + token + '/request.json', 'request')[0],
                            lambda x: x.get('sequence', 0) > max(before['ack'], before['rejected']))
        sequence = integer(request.get('sequence'), 'sequence', 1)
        after = self.wait('positive-' + action + '-ack', lambda: self.state(token),
                          lambda x: x['ack'] >= sequence or x['rejected'] >= sequence)
        receipt = check_ack(before, request, after, action, fields)
        write(self.out / (self.tag(action) + '-ack.json'),
              {'before': before, 'actual_request': request, 'after': after, 'receipt': receipt})
        return after, receipt

    def show_card(self, observation, index):
        for _ in range(24):
            if observation['layout']['cards'][index]['visible']:
                return observation
            target_page = index // observation['layout']['page_size']
            current_page = observation['layout']['page']
            identifier = 'next_page' if target_page > current_page else 'previous_page'
            self.touch(observation, identifier)
            next_page = current_page + (1 if target_page > current_page else -1)
            after = self.snapshot('actual-card-page', expected_page=next_page)
            require(after['layout']['page'] == next_page and after['state'] == observation['state'],
                    'Page input changed game state or did not change page')
            observation = after
        raise RuntimeError('Actual requested card page never appeared')

    def navigate(self):
        from PIL import Image
        deadline = time.monotonic() + self.budget(60)
        scrolls = 0
        while time.monotonic() < deadline:
            require('MainActivity' in self.surfaces.resumed_activity(), 'Flutter navigation is not foreground')
            tag = self.tag('actual-memory-navigation')
            nodes = self.live.live_nodes(self.out, tag)
            shot = self.probe.capture(self.out, tag, timeout=max(.01, deadline - time.monotonic()))
            with Image.open(self.out / shot['file']) as image:
                size = image.size
            route = common.flutter_hub_navigation_target(nodes, size, self.density)
            tile = self.creative.hub_choice(nodes, 'Memory', size, 48 * self.density) if route and route['action'] == 'hub_ready' else None
            confirmed = self.live.live_nodes(self.out, tag + '-confirmed')
            require('MainActivity' in self.surfaces.resumed_activity(), 'Navigation activity changed during read')
            require(time.monotonic() < deadline, 'Navigation observation exceeded its deadline')
            if route != common.flutter_hub_navigation_target(confirmed, size, self.density):
                continue
            if tile != (self.creative.hub_choice(confirmed, 'Memory', size, 48 * self.density)
                        if route and route['action'] == 'hub_ready' else None):
                continue
            target = tile if tile else route
            write(self.out / (tag + '-target.json'), {'route': route, 'tile': tile, 'capture': shot})
            if target and 'bounds' in target:
                r = target['bounds']; point = [round((r[0] + r[2]) / 2), round((r[1] + r[3]) / 2)]
                self.events.append({'kind': 'actual_flutter_navigation_touch', 'target': target,
                                    'capture': shot, 'point': point})
                write(self.out / 'input-events.json', self.events)
                self.adb('shell', 'input', 'tap', *map(str, point), timeout=max(.01, deadline - time.monotonic()))
                if tile:
                    require(time.monotonic() < deadline, 'Memory hub touch completed after its navigation deadline')
                    return
            elif route and route['action'] == 'hub_ready':
                require(scrolls < 20, 'Memory tile absent within bounded actual hub scrolling')
                rects = [self.creative.bounds(n.get('bounds', '')) for n in confirmed
                         if n.get('package') == PACKAGE and n.get('scrollable') == 'true']
                rects = [r for r in rects if r and 0 <= r[0] < r[2] <= size[0] and 0 <= r[1] < r[3] <= size[1]]
                require(rects, 'No actual Memory hub scroll viewport')
                r = max(rects, key=lambda x: (x[2] - x[0]) * (x[3] - x[1]))
                x = round((r[0] + r[2]) / 2)
                lo, hi = round(r[1] + .25 * (r[3] - r[1])), round(r[1] + .75 * (r[3] - r[1]))
                start, end = (hi, lo) if scrolls < 10 else (lo, hi)
                self.events.append({'kind': 'actual_flutter_scroll', 'viewport': r,
                                    'start': [x, start], 'end': [x, end], 'capture': shot})
                write(self.out / 'input-events.json', self.events)
                self.adb('shell', 'input', 'swipe', str(x), str(start), str(x), str(end), '450',
                         timeout=max(.01, deadline - time.monotonic()))
                scrolls += 1
            time.sleep(.3)
        raise RuntimeError('Actual Memory hub entry did not settle before its deadline')

    def lease(self, token, active):
        before = int(self.adb('shell', 'date', '+%s%3N', timeout=self.budget(10)).strip())
        value, _ = self.raw(SESSION + token + '/lifecycle.json', 'lifecycle')
        after = int(self.adb('shell', 'date', '+%s%3N', timeout=self.budget(10)).strip())
        stamp = integer(value.get('stamp'), 'stamp', 1, 2**63 - 1)
        integer(value.get('pauseEpoch'), 'pauseEpoch')
        require(value.get('active') is active and stamp <= after + 500 and
                (not active or before - stamp < 2500), 'Wrong or stale actual Activity lease')
        return {'device_before_ms': before, 'device_after_ms': after, 'lifecycle': value}

    def binding(self):
        a = self.args
        hashes = {}
        for root, expected in ((a.candidate_source, a.expected_source), (a.native_source, a.expected_native)):
            require(re.fullmatch('[a-f0-9]{40}', expected), 'Immutable full source SHA required')
            require(subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip() == expected,
                    'Candidate checkout identity differs')
            require(not subprocess.check_output(['git', '-C', str(root), 'status', '--porcelain', '--untracked-files=no'],
                                                text=True).strip(), 'Tracked candidate checkout changed')
        require(Path.cwd().resolve() == a.candidate_source and Path(__file__).resolve() == a.candidate_source / SELF,
                'Execute the actual candidate probe from its unchanged source CWD')
        for relative in SOURCE_FILES:
            file = a.candidate_source / relative
            require(file.read_bytes() == subprocess.check_output(['git', '-C', str(a.candidate_source), 'show', 'HEAD:' + relative]),
                    'Working source differs: ' + relative)
            hashes[relative] = sha(file)
        for relative in ('scripts/games/memory/memory_table.gd', 'scenes/games/memory_table.tscn'):
            file = a.native_source / relative
            require(file.read_bytes() == subprocess.check_output(['git', '-C', str(a.native_source), 'show', 'HEAD:' + relative]),
                    'Native Memory source differs')
            hashes['native/' + relative] = sha(file)
        identity = self.tour.verify_apk_identity(a.apk, a.provenance, a.sums)
        require(identity['flutter_source_commit'] == a.expected_source and identity['godot_revision'] == a.expected_native,
                'APK/source identity mismatch')
        common.verified_pck(a.apk, identity['godot_pck_sha256'])
        installed = self.adb('shell', 'pm', 'path', PACKAGE, timeout=self.budget(10)).strip().splitlines()
        require(len(installed) == 1 and installed[0].startswith('package:/data/app/') and installed[0].endswith('/base.apk'),
                'Installed APK path is absent/ambiguous')
        actual = self.adb('shell', 'sha256sum', installed[0][8:], timeout=self.budget(30)).split()[0]
        require(actual == identity['apk_sha256'], 'Installed APK changed')
        return {'host': a.expected_source, 'native': a.expected_native, 'apk': identity,
                'actual_installed_apk_sha256': actual, 'source_hashes': hashes,
                'shared_source_binding': self.bind_shared_sources()}

    def closed_session(self, token):
        result = subprocess.run(['adb', '-s', self.args.serial, 'shell', 'test', '-e', SESSION + token],
                                capture_output=True, timeout=self.budget(10))
        write(self.out / (self.tag('closed-session') + '.json'), {'path': SESSION + token,
              'returncode': result.returncode, 'stdout': result.stdout.decode(errors='replace'),
              'stderr': result.stderr.decode(errors='replace')})
        require(result.returncode == 1 and not result.stderr, 'Old Memory session still exists or read failed')

    def run(self):
        from PIL import Image
        a = self.args
        require(re.fullmatch(r'emulator-\d+', a.serial), 'Disposable emulator required')
        require(self.adb('get-serialno').strip() == a.serial and
                self.adb('shell', 'getprop', 'ro.kernel.qemu').strip() == '1' and
                self.adb('shell', 'id', '-u').strip() == '0', 'Wrong/pre-unrooted runtime; this probe never roots a device')
        runtime = {'sdk': int(self.adb('shell', 'getprop', 'ro.build.version.sdk').strip()),
                   'release': self.adb('shell', 'getprop', 'ro.build.version.release').strip(),
                   'fingerprint': self.adb('shell', 'getprop', 'ro.build.fingerprint').strip()}
        require(runtime['sdk'] == a.expected_api and runtime['release'] == {35: '15', 37: '17'}[a.expected_api] and
                runtime['fingerprint'], 'Actual Android runtime differs')
        before_binding = self.binding()
        prior = parse_json(a.tour_result.read_text())
        check_tour(prior, before_binding['apk']['apk_sha256'], a.expected_api)
        density_raw = self.adb('shell', 'wm', 'density')
        (self.out / 'actual-density.txt').write_text(density_raw)
        densities = re.findall(r'(?:Override|Physical) density:\s*(\d+)', density_raw)
        require(densities, 'Actual Android density missing')
        self.density = int(densities[-1]) / 160
        self.before_prefs = self.probe.prefs(self.out, 'before-memory')
        child = self.before_prefs.get('flutter.lumo_learning_local_student_id_v1')
        require(type(child) is str and re.fullmatch('local-[a-f0-9]{32}', child), 'Existing local test child required')
        self.owner = hashlib.sha256(child.encode()).hexdigest()
        write(self.out / 'binding-before.json', before_binding)
        self.navigate()
        self.wait('native-memory-activity', lambda: 'TableGameActivity' in self.surfaces.resumed_activity(), bool, 60)
        current = self.snapshot('initial-memory')
        token = current['state']['token']; initial_pid = self.pid()
        self.wait('active-memory-lease', lambda: self.lease(token, True), bool)
        state = self.wait('initial-current-state', lambda: self.state(token),
                          lambda x: x['canFlip'] or self.saved(x)['paused'])
        current = self.snapshot('initial-active-memory')
        if current['state']['paused']:
            require(self.saved(current['state'])['paused'], 'Transient inactive lease cannot be assumed a Resume target')
            self.action(current, 'resume', 'resume')
            current = self.snapshot('initial-explicit-resume')
        state = current['state']; initial = self.saved(state)
        require(state['canFlip'] and state['kindMoves'] == 0 and state['kindPairs'] == 0 and state['lumoPairs'] == 0 and
                all(not c['faceUp'] and not c['matched'] for c in state['cards']),
                'Fixture must contain an actual fresh round; existing rounds are never replaced')
        deck = initial['rules']['cards']
        first = 0; partner = deck.index(deck[first], first + 1)
        write(self.out / 'qa-deck-selection-oracle.json', {'scope': 'read-only private deck used only to select real inputs',
              'source_key': ROUND_PREFIX + self.owner, 'roundId': state['roundId'],
              'saved_round_sha256': hashlib.sha256(json.dumps(initial, sort_keys=True).encode()).hexdigest(),
              'first_pair': [first, partner], 'deck_written': False, 'requests_injected': False})
        current = self.show_card(current, first)
        hidden = current
        _, first_receipt = self.action(current, 'card_' + str(first), 'flip', {'index': first})
        current = self.snapshot('first-actual-face')
        require(current['state']['cards'][first]['faceUp'] and current['state']['cards'][first]['motif'] == deck[first],
                'First real touch did not expose its actual saved motif')
        self.saved(current['state'])
        with Image.open(self.out / hidden['capture']['file']) as aimage, Image.open(self.out / current['capture']['file']) as bimage:
            pixels = face_pixel_change(aimage.convert('RGB'), bimage.convert('RGB'), hidden['layout'], current['layout'], first)
        current = self.show_card(current, partner)
        _, pair_receipt = self.action(current, 'card_' + str(partner), 'flip', {'index': partner})
        self.wait('actual-matched-pair', lambda: self.state(token),
                  lambda x: x['kindPairs'] == 1 and x['canFlip'] and x['cards'][first]['matched'] and x['cards'][partner]['matched'])
        current = self.snapshot('one-real-matched-pair'); saved = self.saved(current['state'])
        _, pause_receipt = self.action(current, 'pause', 'pause')
        paused = self.snapshot('actual-pause'); paused_save = self.saved(paused['state'])
        frozen_round_equal(saved, paused_save)
        require(paused_save['paused'], 'Pause was not durable')
        time.sleep(2)
        require(self.saved(self.state(token)) == paused_save, 'Paused round advanced')
        _, resume_receipt = self.action(paused, 'resume', 'resume')
        current = self.snapshot('actual-resume')
        frozen_round_equal(paused_save, self.saved(current['state']))
        lease_before = self.lease(token, True)
        rest = [i for i, c in enumerate(current['state']['cards']) if not c['matched']]
        left = rest[0]; right = next(i for i in rest if deck[i] != deck[left])
        current = self.show_card(current, left)
        _, mismatch_first = self.action(current, 'card_' + str(left), 'flip', {'index': left})
        current = self.snapshot('mismatch-first-face')
        current = self.show_card(current, right)
        before_mismatch = current['state']
        _, mismatch_second = self.action(current, 'card_' + str(right), 'flip', {'index': right})
        bot = self.wait('actual-Dart-bot-face', lambda: self.state(token),
                        lambda x: x['turn'] == 'lumo' and x['phase'] in ('botSecond', 'resolve') and
                        any(c['faceUp'] and not c['matched'] for c in x['cards']))
        bot_receipt = check_bot_reply(before_mismatch, bot, deck, right, mismatch_second['sequence'])
        self.events.append({'kind': 'actual_adb_home', 'observed_bot_state': bot})
        write(self.out / 'input-events.json', self.events)
        self.adb('shell', 'input', 'keyevent', '3', timeout=self.budget(10))
        inactive = self.wait('actual-Home-inactive-lease', lambda: self.lease(token, False), bool)
        home = self.wait('durable-Home-pause', lambda: self.state(token),
                         lambda x: x['paused'] and self.saved(x)['paused'])
        home_save = self.saved(home)
        require(not home['complete'], 'Bot finished before the intended unfinished-round lifecycle check')
        time.sleep(3)
        require(self.saved(self.state(token)) == home_save, 'Background Memory turn advanced')
        self.base.launch(self.out, 'actual-return-from-home')
        self.wait('same-memory-activity-after-home', lambda: 'TableGameActivity' in self.surfaces.resumed_activity(), bool)
        require(self.pid() == initial_pid, 'Home return replaced the native process')
        lease_after = self.lease(token, True)
        require(lease_after['lifecycle']['pauseEpoch'] >= inactive['lifecycle']['pauseEpoch'] > lease_before['lifecycle']['pauseEpoch'],
                'Home pause epoch is not bound to the actual current Activity')
        after_home = self.snapshot('actual-home-return-paused')
        require(after_home['state']['paused'] and self.saved(after_home['state']) == home_save,
                'Home silently resumed or changed the unfinished round')
        self.touch(after_home, 'back')
        self.surfaces.returned_to_flutter(self.out, 'Spiel pausiert', 'memory-return-flutter')
        self.closed_session(token)
        exit_prefs = self.probe.prefs(self.out, 'after-native-exit')
        frozen_round_equal(home_save, parse_json(exit_prefs[ROUND_PREFIX + self.owner]))
        # The actual Memory screen has automatic native entry. Its real
        # paused-screen Leave action returns to the hub for another entry.
        self.navigate()
        self.wait('actual-reopened-memory', lambda: 'TableGameActivity' in self.surfaces.resumed_activity(), bool, 60)
        reopened = self.snapshot('actual-reopened-round')
        require(reopened['state']['token'] != token and reopened['state']['roundId'] == state['roundId'] and
                reopened['state']['paused'], 'Reopen changed round, reused token or silently resumed')
        reopened_save = self.saved(reopened['state'])
        frozen_round_equal(home_save, reopened_save)
        require(reopened_save['paused'], 'Reopened pause not saved')
        self.touch(reopened, 'back')
        self.surfaces.returned_to_flutter(self.out, 'Spiel pausiert', 'memory-final-return-flutter')
        self.closed_session(reopened['state']['token'])
        after_prefs = self.probe.prefs(self.out, 'after-memory')
        frozen_round_equal(home_save, parse_json(after_prefs[ROUND_PREFIX + self.owner]))
        preservation = check_preservation(self.before_prefs, after_prefs, self.owner)
        learning = self.tour.evidence.learning_preserved(self.before_prefs, after_prefs)
        after_binding = self.binding()
        require(before_binding == after_binding, 'Source, installed APK or PCK changed during Memory probe')
        fatal = self.tour.logcat_fatal(); require(not fatal, 'Actual app crash observed: ' + str(fatal))
        require(time.monotonic() < self.deadline, 'Completed Memory evidence exceeded the fixed total deadline')
        write(self.out / 'binding-after.json', after_binding)
        return {'status': 'PASS', 'source_binding': before_binding, 'android_runtime': runtime,
                'child_actions': [first_receipt, pair_receipt, mismatch_first, mismatch_second],
                'pause': pause_receipt, 'resume': resume_receipt, 'actual_bot_state': bot,
                'bot_receipt': bot_receipt,
                'face_pixels': pixels, 'owner': self.owner, 'same_round_id': state['roundId'],
                'old_token': token, 'new_token': reopened['state']['token'],
                'active_lease_before_home': lease_before, 'inactive_lease': inactive,
                'active_lease_after_home': lease_after, 'frozen_home_round': home_save,
                'preference_preservation': preservation, 'learning_preservation': learning,
                'qa_oracle': 'Private deck read only for pair/mismatch selection; no product state or IPC writes',
                'scope': 'Actual Android hub/touches/ACK, one pair, a Dart bot face, pause/resume, Home lease, same unfinished round reopened with new token',
                'not_tested': ['Full reward round (separate actual Dart/Godot pair)', 'Other child switching',
                               'Every difficulty or motif pack', 'Physical device FPS/thermal/input latency']}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('candidate-source', 'native-source', 'apk', 'provenance', 'sums', 'tour-result', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    for name in ('expected-source', 'expected-native', 'serial'):
        parser.add_argument('--' + name, required=True)
    parser.add_argument('--expected-api', type=int, choices=(35, 37), required=True)
    args = parser.parse_args(argv)
    for name in ('candidate_source', 'native_source', 'apk', 'provenance', 'sums', 'tour_result', 'out'):
        setattr(args, name, getattr(args, name).resolve())
    if args.out.exists() and any(args.out.iterdir()):
        print('Refusing to overwrite previous Memory result', file=sys.stderr)
        return 2
    probe = None
    try:
        probe = AndroidProbe(args)
        result = probe.run(); write(args.out / 'result.json', result)
        return 0
    except Exception as error:
        args.out.mkdir(parents=True, exist_ok=True)
        write(args.out / 'result.json', {'status': 'FAIL', 'error': f'{type(error).__name__}: {error}',
              'expected_host': args.expected_source, 'expected_native': args.expected_native})
        (args.out / 'failure-traceback.txt').write_text(traceback.format_exc())
        if probe:
            try:
                probe.probe.capture(args.out, 'failure-actual-memory-screen', timeout=15)
            except Exception as capture_error:
                (args.out / 'failure-capture-error.txt').write_text(str(capture_error))
        return 1
    finally:
        if probe:
            probe.base.adb = probe.old_adb


if __name__ == '__main__':
    raise SystemExit(main())
