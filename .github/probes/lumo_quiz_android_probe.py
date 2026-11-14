#!/usr/bin/env python3
"""Exercise the real Quiz studio of an already installed, source-bound APK.

Only physical Android input changes the app. Private files are read, never
written. Correct choices for this bounded two-question probe are explicitly
read from the app's durable question set; they are not an educational score.
The complete 20-question/reward contract belongs to the separate Dart/Godot
authority test. Recorded native pixels still require a human visual review.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import hashlib
import json
import math
import os
import re
import signal
import subprocess
import sys
import time
import traceback
import unicodedata
from pathlib import Path

import lumo_connect_four_android_probe as shared

require = shared.require
parse_json = shared.parse_json
integer = shared.integer
number = shared.number
vector = shared.vector
rectangle = shared.rectangle
inside = shared.inside
write = shared.write
sha = shared.sha
PACKAGE, FILES = shared.PACKAGE, shared.FILES
SELF = '.github/probes/lumo_quiz_android_probe.py'
LAYOUT = FILES + '/quiz_layout_v1.json'
SESSION = FILES + '/lumo_table_games_session_v1/'
ROUND_PREFIX = 'flutter.lumo.quiz.round.v1.'
TITLE = 'Wer wird Lumo-Meister?'
NATIVE_TITLE = 'Lumos Quizshow'
SUBJECTS = ('alle', 'Deutsch', 'Mathe', 'Sachunterricht')
JOKERS = ('fiftyFifty', 'audience', 'callLumo')
CLIPS = ['idle', 'greeting_wave', 'celebrate', 'point_portal', 'agree_nod',
         'kart_seated', 'kart_steer_left', 'kart_steer_right', 'kart_jump']
BUTTONS = {'back', 'pause', 'reveal', 'next', 'resume', 'restart'} | {
    'answer_' + str(i) for i in range(4)} | {
    'subject_' + s for s in SUBJECTS} | {'joker_' + j for j in JOKERS}
SOURCE_FILES = tuple(dict.fromkeys((SELF, shared.SELF,
    '.github/probes/creative_android_probe.py',
    '.github/probes/modernization_android_tour.py',
    '.github/probes/lumo_studio_surfaces_android_probe.py',
    '.github/probes/studio_creative_android_probe.py',
    'scripts/probes/pr207_android_smoke.py',
    'scripts/probes/pr207_android_ui_probe.py',
    'tools/android_qa/native_surface_readiness.py',
    'tools/android_qa/native_ocr_tiles.py',
    'tools/android_qa/kart_tour_evidence.py',
    'tools/auto_install/TableGamesBridge.kt',
    'tools/auto_install/TableGameActivity.kt',
    'tools/auto_install/TableAuthorityService.kt',
    'tools/auto_install/TableGameIntent.java',
    'tools/auto_install/MainActivity.kt',
    'lib/features/quiz/quiz_show_content.dart',
    'lib/features/quiz/quiz_show_round.dart',
    'lib/features/quiz/quiz_show_repository.dart',
    'lib/features/quiz/quiz_table_session.dart',
    'lib/domain/quiz/quiz_show.dart',
    'lib/features/games/spielwelt/spielwelt_hub.dart',
    'lib/features/games/spielwelt/spielwelt_routes.dart')))
NATIVE_FILES = ('scripts/games/quiz/quiz_studio.gd',
                'scenes/games/quiz_studio.tscn',
                'scripts/characters/lumo/lumo_rigged_actor.gd',
                'scripts/app/mobile_runtime.gd',
                'scripts/app/android_safe_area.gd')
STATE_KEYS = frozenset('schema game token roundId owner revision ack rejected recordRevision '
    'paused exit reduceMotion subject grade number total questionSubject prompt options selected '
    'revealed gameOver won correctIndex explanation hidden usedJokers audience hint securedStars '
    'awardedStars rewarded error canSelect canReveal canNext'.split())
TOUR_STEPS = frozenset(('apk-identity', 'launch', 'onboarding', 'navigate-start', 'navigate-lernen',
    'atelier-roundtrip', 'navigate-spiele', 'open-kart', 'start-kart-race', 'race-running', 'race-hud',
    'race-drive', 'pause-menu', 'return-from-kart', 'learning-state-after-kart',
    'lernen-usable-after-kart', 'profile-after-kart', 'restart-keeps-learning-state',
    'display-fold_offen', 'display-fold_aussen', 'display-quer'))


class AuthorityChanged(RuntimeError):
    """A pre-input observation changed. No touch has been dispatched."""


def current(condition, message):
    if not condition:
        raise AuthorityChanged(message)


@contextmanager
def bounded_runtime(seconds=900):
    """Bound blocking helpers too; restore any caller's timer and handler."""
    require(hasattr(signal, 'setitimer'), 'Linux timer support required')
    previous_handler = signal.getsignal(signal.SIGALRM)
    previous_timer = signal.getitimer(signal.ITIMER_REAL)
    started = time.monotonic()
    def expired(_signum, _frame):
        raise TimeoutError('Quiz Android probe exceeded its 900-second runtime budget')
    signal.signal(signal.SIGALRM, expired)
    signal.setitimer(signal.ITIMER_REAL, seconds)
    try:
        yield
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        delay, interval = previous_timer
        if delay:
            delay = max(.001, delay - (time.monotonic() - started))
        signal.setitimer(signal.ITIMER_REAL, delay, interval)


def normalized(value):
    plain = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', plain.lower())


def allowed_read(path):
    return path == LAYOUT or re.fullmatch(
        re.escape(SESSION) + r'[a-f0-9]{32}/(state|request|lifecycle)\.json', path) is not None


def text_value(value, label, maximum, empty=False):
    require(type(value) is str and len(value) <= maximum and (empty or value.strip()),
            'Invalid text: ' + label)
    return value


def check_state(state, owner=None):
    require(type(state) is dict and set(state) == STATE_KEYS and
            state.get('schema') == 1 and state.get('game') == 'quiz',
            'Wrong Quiz state')
    integer(state['schema'], 'state schema', 1, 1)
    for key, length in (('token', 32), ('roundId', 32), ('owner', 64)):
        require(type(state.get(key)) is str and re.fullmatch('[a-f0-9]{'+str(length)+'}', state[key]),
                'Invalid ' + key)
    if owner is not None:
        require(state['owner'] == owner, 'Quiz belongs to another child')
    for key in ('revision', 'recordRevision'):
        integer(state.get(key), key, 1)
    for key in ('ack', 'rejected'):
        integer(state.get(key), key)
    for key in ('paused', 'exit', 'reduceMotion', 'revealed', 'gameOver', 'won',
                'rewarded', 'canSelect', 'canReveal', 'canNext'):
        require(type(state.get(key)) is bool, 'Invalid boolean: ' + key)
    require(state.get('subject') in SUBJECTS, 'Unknown Quiz subject')
    integer(state.get('grade'), 'grade', 1, 4)
    integer(state.get('number'), 'number', 1, 20)
    integer(state.get('total'), 'twenty-question roster', 20, 20)
    text_value(state.get('questionSubject'), 'question subject', 100)
    text_value(state.get('prompt'), 'prompt', 1500)
    options = state.get('options')
    require(type(options) is list and len(options) == 4, 'Four actual options required')
    for option in options:
        text_value(option, 'option', 800)
    if state.get('selected') is not None:
        integer(state['selected'], 'selected', 0, 3)
    if state['revealed']:
        integer(state.get('correctIndex'), 'revealed correct index', 0, 3)
        if state['explanation'] is not None:
            text_value(state['explanation'], 'revealed explanation', 2000, empty=True)
    else:
        require(state.get('correctIndex') is None and state.get('explanation') is None,
                'Unrevealed correct answer leaked to native state')
    hidden = state.get('hidden')
    require(type(hidden) is list and len(hidden) <= 2, 'Invalid hidden options')
    require(len(set(integer(v, 'hidden option', 0, 3) for v in hidden)) == len(hidden),
            'Duplicate hidden option')
    jokers = state.get('usedJokers')
    require(type(jokers) is list and len(jokers) <= 3 and
            all(type(j) is str and j in JOKERS for j in jokers) and len(set(jokers)) == len(jokers),
            'Invalid used jokers')
    if state.get('audience') is not None:
        votes = state['audience']
        require(type(votes) is list and len(votes) == 4 and
                sum(integer(x, 'audience vote', 0, 100) for x in votes) == 100,
                'Invalid audience votes')
    for key in ('hint', 'error'):
        if state.get(key) is not None:
            text_value(state[key], key, 2000, empty=True)
    for key in ('securedStars', 'awardedStars'):
        integer(state.get(key), key, 0, 5000)
    interactive = not (state['paused'] or state['exit'] or state['gameOver'])
    require(state['canSelect'] == (interactive and not state['revealed']), 'Invalid select permission')
    require(state['canReveal'] == (interactive and not state['revealed'] and state['selected'] is not None),
            'Invalid reveal permission')
    require(state['canNext'] == (interactive and state['revealed']), 'Invalid next permission')
    require(not state['won'] or (state['gameOver'] and state['number'] == 20), 'Invalid won state')
    require(not state['rewarded'] or state['gameOver'], 'Reward on unfinished round')
    return state


def check_layout(layout, state, image_size, density, pid, *, allow_fixture=False):
    check_state(state)
    require(type(layout) is dict and layout.get('schema') == 1 and layout.get('game') == 'quiz', 'Wrong Quiz layout')
    integer(layout['schema'], 'layout schema', 1, 1)
    require(layout.get('settled') is True and layout.get('ui_visible') is True and layout.get('pending') == 0,
            'Quiz layout still transitioning')
    integer(layout['pending'], 'pending input', 0, 0)
    allowed = ('android_window_insets', 'platform_fixture') if allow_fixture else ('android_window_insets',)
    require(layout.get('observation_source') in allowed, 'No actual Android layout observation')
    require(layout.get('state') == state, 'Stale or different complete Quiz state')
    for key in ('token', 'owner', 'roundId', 'revision', 'recordRevision', 'ack', 'rejected'):
        require(layout.get(key) == state.get(key), 'Stale layout identity: ' + key)
    require(integer(layout.get('pid'), 'pid', 1) == pid, 'Layout process changed')
    integer(layout.get('layout_sequence'), 'layout sequence', 1)
    integer(layout.get('ticks_msec'), 'layout ticks', 0, 2**63-1)
    require(.5 <= density <= 6 and abs(number(layout.get('density'), 'density') - density) < .01,
            'Actual density differs')
    obs = layout['android_observation']
    decor = vector(obs['decor_size'], 2, 'decor')
    view = vector(obs['view_size'], 2, 'view')
    window = vector(layout['window_px'], 2, 'window')
    require(shared.same_numbers(decor, list(image_size)) and min(view + window) > 0,
            'Screenshot/decor dimensions differ')
    render = rectangle(obs['render_rect'], 'render view')
    require(inside(render, [0, 0, *decor]) and shared.same_numbers(render[2:], view, .1),
            'Render view is outside decor')
    bars = vector(obs['system_insets'], 4, 'system insets')
    insets = vector(obs['insets'], 4, 'view insets')
    require(min(bars + insets) >= 0, 'Negative actual inset')
    overlap = [max(0, bars[0]-render[0]), max(0, bars[1]-render[1]),
               max(0, render[0]+render[2]-(decor[0]-bars[2])),
               max(0, render[1]+render[3]-(decor[1]-bars[3]))]
    require(shared.same_numbers(insets, overlap, .15), 'Insets disagree with actual render overlap')
    safe = [insets[0]*window[0]/view[0], insets[1]*window[1]/view[1],
            (view[0]-insets[0]-insets[2])*window[0]/view[0],
            (view[1]-insets[1]-insets[3])*window[1]/view[1]]
    require(shared.same_numbers(rectangle(layout['safe_rect'], 'safe rect'), safe, .2),
            'Safe rect disagrees with actual insets')
    for key in ('stage_rect', 'content_clip_px'):
        require(inside(rectangle(layout[key], key), safe), 'Quiz region outside safe view: ' + key)
    geo = layout['geometry']
    require(geo.get('question_lights') == 20 and geo.get('lit_questions') == state['number'] and
            geo.get('original_lumo_usable') is True and geo.get('bones') == 65 and
            geo.get('clips') == CLIPS and geo.get('model_load_kind') == 'imported_packed_scene' and
            geo.get('audio_driven_mouth') is False, 'Original Lumo/studio geometry differs')
    buttons = layout['buttons']
    require(type(buttons) is list and len(buttons) == len(BUTTONS) and
            {b['id'] for b in buttons} == BUTTONS, 'Incomplete or duplicate Quiz controls')
    for button in buttons:
        for key in ('visible', 'enabled', 'clipped'):
            require(type(button.get(key)) is bool, 'Invalid control boolean')
        text_value(button.get('text'), 'control text', 1500)
    for hidden in state['hidden']:
        index = integer(hidden, 'hidden option', 0, 3)
        button = next(b for b in buttons if b['id'] == 'answer_'+str(index))
        require(button['enabled'] is False and button['text'] == 'ABCD'[index]+'  Ausgeblendet',
                'A hidden answer is exposed or actionable')
    exposed = [shared.button_target(layout, b['id'], density) for b in buttons
               if b['visible'] and b['enabled'] and not b['clipped']]
    require(exposed, 'No fully exposed actual controls')
    return {'safe_rect': safe, 'exposed_targets': exposed,
            'original_geometry_reported': geo, 'visual_review_required': True}


def check_saved(saved, state):
    """Bind the real durable question set to the observed public question.

    This validates the bounded no-joker partial trace used below, not a second
    production quiz engine. Correct answers are only a read-only test oracle.
    """
    check_state(state)
    require(type(saved) is dict and saved.get('schema') == 1 and saved.get('owner') == state['owner'] and
            saved.get('id') == state['roundId'] and saved.get('revision') == state['recordRevision'],
            'Durable Quiz identity/revision differs')
    integer(saved['schema'], 'saved schema', 1, 1)
    for key in ('subject', 'grade', 'rewarded'):
        require(saved.get(key) == state[key], 'Saved Quiz field differs: ' + key)
    integer(saved.get('seed'), 'saved seed', 0, 0x7fffffff)
    questions = saved.get('questions')
    require(type(questions) is list and len(questions) == 20, 'Saved question roster incomplete')
    ids = []
    for question in questions:
        ids.append(text_value(question.get('id'), 'question id', 160))
        text_value(question.get('prompt'), 'saved prompt', 1200)
        require(type(question.get('options')) is list and len(question['options']) == 4,
                'Saved question options incomplete')
        for option in question['options']:
            text_value(option, 'saved option', 400)
        integer(question.get('correctIndex'), 'saved correct index', 0, 3)
    require(len(set(ids)) == 20, 'Duplicate saved questions')
    actions = saved.get('actions')
    require(type(actions) is list and len(actions) <= 4, 'Probe requires an untouched or its own bounded partial round')
    index, selected, revealed = 0, None, False
    for action in actions:
        require(type(action) is dict, 'Invalid durable action')
        if action.get('action') == 'select':
            require(set(action) == {'action', 'option'} and not revealed, 'Invalid partial selection')
            selected = integer(action['option'], 'durable selected option', 0, 3)
        elif action.get('action') == 'reveal':
            require(set(action) == {'action'} and selected is not None and not revealed,
                    'Invalid partial reveal')
            require(selected == questions[index]['correctIndex'], 'Partial test did not select the actual correct option')
            revealed = True
        elif action.get('action') == 'next':
            require(set(action) == {'action'} and revealed and index == 0, 'Unexpected partial next')
            index, selected, revealed = index + 1, None, False
        else:
            raise RuntimeError('Unplanned durable Quiz action')
    question = questions[index]
    require(state['number'] == index+1 and state['selected'] == selected and state['revealed'] is revealed,
            'Public state disagrees with actual durable trace')
    for public, stored in (('prompt', 'prompt'), ('options', 'options'), ('questionSubject', 'subject')):
        require(state[public] == question[stored], 'Public question differs from durable content: ' + public)
    if revealed:
        require(state['correctIndex'] == question['correctIndex'] and
                state['explanation'] == question['explanation'], 'Revealed answer differs from durable question')
    require(not state['gameOver'] and not state['won'] and not state['rewarded'] and
            state['securedStars'] == 0 and state['awardedStars'] == 0 and
            state['usedJokers'] == [] and state['hidden'] == [] and
            state['audience'] is None and state['hint'] is None,
            'Partial probe unexpectedly changed rewards/jokers or finished the round')
    return question


def check_transition(before, request, after, action, extras, saved_before, saved_after):
    check_saved(saved_before, before)
    check_saved(saved_after, after)
    require(all(before[k] == after[k] for k in ('token', 'owner', 'roundId')),
            'Intent changed current session/owner/round')
    expected_keys = {'token', 'roundId', 'revision', 'sequence', 'action'} | set(extras)
    require(type(request) is dict and set(request) == expected_keys and
            request.get('token') == before['token'] and request.get('roundId') == before['roundId'] and
            request.get('revision') == before['revision'] and request.get('action') == action and
            all(request.get(k) == v for k, v in extras.items()), 'Observed request differs from actual intended touch')
    seq = integer(request['sequence'], 'request sequence', 1)
    require(seq > max(before['ack'], before['rejected']) and after['ack'] >= seq and
            after['rejected'] < seq and after['revision'] > before['revision'],
            'Intent lacks a new positive same-round acknowledgement')
    for key in ('owner', 'id', 'grade', 'seed', 'subject', 'questions', 'rewarded'):
        require(saved_before[key] == saved_after[key], 'Intent changed durable question/owner data: ' + key)
    if action in ('select', 'reveal', 'next'):
        require(saved_after['revision'] == saved_before['revision']+1 and
                saved_after['actions'] == saved_before['actions'] + [{'action': action, **extras}],
                'Intent was not durably appended exactly once')
    else:
        require(action in ('pause', 'resume') and saved_after == saved_before,
                'Pause/resume changed durable question history')
        require(after['paused'] is (action == 'pause'), 'Pause/resume did not reach requested state')
    require(after['error'] is None, 'Authority reported an error')
    return {'action': action, 'extras': extras, 'sequence': seq, 'ack': after['ack'],
            'record_revision_before': before['recordRevision'],
            'record_revision_after': after['recordRevision']}


def check_tour(prior, apk_sha256, api):
    require(type(prior) is dict and prior.get('status') == 'PASS' and
            prior.get('apk_sha256') == apk_sha256 and prior.get('android_sdk') == str(api),
            'Normal tour is not bound to this APK/API')
    steps = prior.get('steps')
    require(type(steps) is list and len(steps) == 21 and all(type(s) is dict and s.get('ok') is True for s in steps),
            'All twenty-one original tour gates required')
    names = [s.get('step') for s in steps]
    require(all(type(n) is str for n in names) and set(names) == TOUR_STEPS,
            'All exact original tour gates must be named and distinct')


def protected_prefs(before, after, owner):
    # The existing learning_preserved gate separately checks the stable profile
    # fields. Its lastActiveAt timestamp legitimately changes on real return.
    fixed = {'flutter.lumo_learning_local_student_id_v1',
             'flutter.lumo_reward_wallet_v1', 'flutter.lumo_legacy_stars', 'flutter.lumo_legacy_xp'}
    prefixes = ('flutter.lumo.connect_four.', 'flutter.lumo.memory.', ROUND_PREFIX)
    keys = fixed | {k for prefs in (before, after) for k in prefs
                    if k.startswith(prefixes) and k != ROUND_PREFIX+owner}
    missing = object()
    require(all(before.get(k, missing) == after.get(k, missing) for k in keys),
            'Profile, another game/owner, or wallet changed during partial Quiz probe')
    return sorted(keys)


def caption_witness(lines, caption, size):
    """Only actual OCR text/bounds in the current unscaled control crop count."""
    wanted = normalized(caption)
    require(wanted, 'Empty target caption')
    valid = []
    for line in lines:
        bounds = vector(line.get('bounds'), 4, 'OCR bounds')
        if 0 <= bounds[0] < bounds[2] <= size[0] and 0 <= bounds[1] < bounds[3] <= size[1]:
            text_value(line.get('text'), 'OCR text', 3000)
            valid.append(line)
    for line in valid:
        if normalized(line['text']) == wanted:
            return {'text': line['text'], 'bounds': line['bounds'], 'variant': line.get('variant'), 'lines': [line]}
    # Wrapped labels can be multiple actual OCR lines of the same variant.
    for variant in {line.get('variant') for line in valid}:
        rows = sorted((line for line in valid if line.get('variant') == variant),
                      key=lambda line: (line['bounds'][1], line['bounds'][0]))
        unique = []
        for row in rows:
            if not any(row['text'] == old['text'] and row['bounds'] == old['bounds'] for old in unique):
                unique.append(row)
        observed = ' '.join(line['text'] for line in unique)
        if normalized(observed) == wanted:
            return {'text': observed, 'bounds': [min(x['bounds'][0] for x in unique),
                    min(x['bounds'][1] for x in unique), max(x['bounds'][2] for x in unique),
                    max(x['bounds'][3] for x in unique)], 'variant': variant, 'lines': unique}
    raise RuntimeError('Current actual control pixels do not expose the exact caption: ' + caption)


def flutter_target(nodes, caption, size, density):
    candidates = {}
    for node in nodes:
        labels = {line.strip() for key in ('text', 'content-desc')
                  for line in node.get(key, '').splitlines() if line.strip()}
        if (node.get('package') != PACKAGE or caption not in labels or
                node.get('clickable') != 'true' or node.get('enabled', 'true') != 'true'):
            continue
        match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
        if not match:
            continue
        r = tuple(map(int, match.groups()))
        if (0 <= r[0] < r[2] <= size[0] and 0 <= r[1] < r[3] <= size[1] and
                min(r[2]-r[0], r[3]-r[1]) >= 48*density):
            candidates[r] = {'caption': caption, 'bounds': list(r)}
    require(len(candidates) <= 1, 'Ambiguous actual Flutter control: '+caption)
    return next(iter(candidates.values()), None)


def check_lease(value, before_ms, after_ms, active):
    require(type(value) is dict and type(value.get('active')) is bool and
            value['active'] is active, 'Wrong actual Activity lease state')
    epoch = integer(value.get('pauseEpoch'), 'pause epoch')
    stamp = integer(value.get('stamp'), 'lease timestamp', 1, 2**63-1)
    require(0 < before_ms <= after_ms and stamp <= after_ms and
            (not active or after_ms-stamp < 2500), 'Actual Activity lease is stale or future-dated')
    return {'device_before_ms': before_ms, 'device_after_ms': after_ms,
            'pause_epoch': epoch, 'lifecycle': value}


def check_reopen(before, after, saved_before, saved_after):
    check_saved(saved_before, before)
    check_saved(saved_after, after)
    require(before['token'] != after['token'] and
            all(before[k] == after[k] for k in ('owner', 'roundId', 'recordRevision',
                'number', 'selected', 'revealed', 'prompt', 'options')),
            'Reopened Quiz reused a mailbox or lost its actual question')
    require(saved_before == saved_after, 'Reopening changed the durable Quiz round')
    return {'same_round_id': after['roundId'], 'new_token': True,
            'same_durable_round': True, 'question': after['number']}


class QuizProbe(shared.AndroidProbe):
    def __init__(self, args):
        self.deadline = time.monotonic()+900
        super().__init__(args)

    def remaining(self, limit=45, deadline=None):
        left = min(self.deadline, deadline or self.deadline)-time.monotonic()
        require(left > 0, 'Quiz probe deadline exhausted')
        return min(limit, left)

    def adb(self, *args, timeout=45, check=True):
        return self.base.command('adb', '-s', self.args.serial, *args,
                                 timeout=self.remaining(timeout), check=check)

    def raw(self, path, label, limit=131072):
        require(allowed_read(path), 'Unapproved private Quiz read')
        started = time.time()
        result = subprocess.run(['adb', '-s', self.args.serial, 'exec-out', 'cat', path],
                                capture_output=True, timeout=self.remaining(10))
        tag = self.tag(label)
        (self.out/(tag+'.raw')).write_bytes(result.stdout)
        (self.out/(tag+'.stderr')).write_bytes(result.stderr)
        digest = hashlib.sha256(result.stdout).hexdigest()
        write(self.out/(tag+'-read.json'), {'path': path, 'serial': self.args.serial,
              'started_unix_seconds': started, 'finished_unix_seconds': time.time(),
              'returncode': result.returncode, 'bytes': len(result.stdout), 'sha256': digest})
        require(result.returncode == 0 and 0 < len(result.stdout) <= limit, 'Missing/bounded Quiz read: '+path)
        return parse_json(result.stdout), digest

    def foreground(self):
        require('TableGameActivity' in self.surfaces.resumed_activity(), 'Quiz table is not the actual foreground Activity')

    def state(self, token):
        value, _ = self.raw(SESSION+token+'/state.json', 'state')
        check_state(value, self.owner)
        require(value['token'] == token, 'Wrong Quiz mailbox token')
        return value

    def wait(self, name, observe, accept, timeout=45):
        return super().wait(name, observe, accept, timeout=self.remaining(timeout))

    def saved(self, state):
        prefs = self.probe.prefs(self.out, self.tag('durable-quiz'))
        require(ROUND_PREFIX+self.owner in prefs, 'Durable Quiz round absent')
        value = parse_json(prefs[ROUND_PREFIX+self.owner])
        check_saved(value, state)
        return value

    def snapshot(self, name, deadline=None):
        from PIL import Image
        deadline = min(deadline or self.deadline, time.monotonic()+45, self.deadline)
        while time.monotonic() < deadline:
            try:
                self.foreground()
                pid = self.pid()
                layout, digest = self.raw(LAYOUT, 'layout-before')
                state = self.state(layout['token'])
                capture = self.probe.capture(self.out, self.tag(name), timeout=self.remaining(30, deadline))
                with Image.open(self.out/capture['file']) as image:
                    image.load()
                    geometry = check_layout(layout, state, image.size, self.density, pid)
                later_state = self.state(layout['token'])
                later, later_digest = self.raw(LAYOUT, 'layout-after')
                require(state == later_state and digest == later_digest, 'Quiz changed during actual capture')
                self.foreground()
                require(pid == self.pid(), 'Quiz process changed during capture')
                self.remaining(1, deadline)
                observation = {'capture': capture, 'layout_sha256': digest, 'layout': layout,
                               'state': state, 'geometry': geometry}
                write(self.out/(self.tag(name)+'-observation.json'), observation)
                return observation
            except (RuntimeError, json.JSONDecodeError, KeyError, TypeError) as error:
                write(self.out/(self.tag(name)+'-rejected.json'), {'error': str(error)})
                time.sleep(.25)
        raise RuntimeError('No stable actual Quiz geometry before deadline: '+name)

    def seek(self, identifier, predicate, deadline):
        """At most ten real swipes each way, including observation after the last."""
        for direction in (1, -1):
            for attempt in range(11):
                observation = self.snapshot('find-'+identifier, deadline)
                current(predicate(observation['state']), 'Authority changed while finding '+identifier)
                button = next(b for b in observation['layout']['buttons'] if b['id'] == identifier)
                if button['visible'] and button['enabled'] and not button['clipped']:
                    shared.button_target(observation['layout'], identifier, self.density)
                    return observation
                if attempt == 10:
                    break
                layout = observation['layout']
                clip = rectangle(layout['content_clip_px'], 'actual content viewport')
                p1 = shared.to_decor(layout, [clip[0]+clip[2]*.5, clip[1]+clip[3]*(.75 if direction == 1 else .25)])
                p2 = shared.to_decor(layout, [clip[0]+clip[2]*.5, clip[1]+clip[3]*(.25 if direction == 1 else .75)])
                self.revalidate(observation, predicate, deadline)
                event = {'kind': 'actual_quiz_scroll', 'target': identifier, 'direction': direction,
                         'capture': observation['capture'], 'layout_sha256': observation['layout_sha256'],
                         'content_clip_px': clip, 'from': p1, 'to': p2}
                self.events.append(event)
                write(self.out/'input-events.json', self.events)
                self.adb('shell', 'input', 'swipe', *(str(round(x)) for x in p1+p2), '450',
                         timeout=self.remaining(10, deadline))
                time.sleep(.35)
        raise RuntimeError('Actual Quiz control never became fully exposed: '+identifier)

    def revalidate(self, observation, predicate, deadline):
        self.foreground()
        _, digest = self.raw(LAYOUT, 'pre-input-layout')
        state = self.state(observation['state']['token'])
        current(digest == observation['layout_sha256'] and state == observation['state'] and predicate(state),
                'Current Quiz target/state changed before input')
        require(self.pid() == observation['layout']['pid'], 'Input process changed')
        self.remaining(1, deadline)

    def observed_caption(self, observation, identifier, deadline):
        from PIL import Image
        target = shared.button_target(observation['layout'], identifier, self.density)
        x0, y0, x1, y1 = target['decor_bounds']
        crop_rect = [math.floor(x0), math.floor(y0), math.ceil(x1), math.ceil(y1)]
        path = self.out/(self.tag(identifier)+'-actual-control-crop.png')
        with Image.open(self.out/observation['capture']['file']) as image:
            require(0 <= crop_rect[0] < crop_rect[2] <= image.width and
                    0 <= crop_rect[1] < crop_rect[3] <= image.height, 'OCR crop outside original frame')
            crop = image.convert('RGB').crop(crop_rect)
            crop.save(path)
        # No resize, repaint or invented label: this is the exact current control.
        caption = target['text']
        lines = self.probe.image_lines(self.out, self.tag('control-ocr'), normalized(caption),
                                      source_path=path, timeout=self.remaining(30, deadline), exact=True)
        witness = caption_witness(lines, caption, crop.size)
        record = {'source': observation['capture'], 'crop': path.name, 'crop_sha256': sha(path),
                  'crop_rect': crop_rect, 'target': target, 'observed': witness}
        write(self.out/(self.tag(identifier)+'-caption-witness.json'), record)
        return record

    def touch_control(self, identifier, predicate, timeout=90, deadline=None):
        deadline = min(deadline or self.deadline, self.deadline, time.monotonic()+timeout)
        first = self.seek(identifier, predicate, deadline)
        first_witness = self.observed_caption(first, identifier, deadline)
        second = self.snapshot('confirmed-'+identifier, deadline)
        current(first['state'] == second['state'] and predicate(second['state']),
                'Quiz state changed between two actual target frames')
        one = shared.button_target(first['layout'], identifier, self.density)
        two = shared.button_target(second['layout'], identifier, self.density)
        require(one == two and first['capture']['file'] != second['capture']['file'],
                'Quiz target moved or reused the same capture')
        second_witness = self.observed_caption(second, identifier, deadline)
        saved_before = self.saved(second['state'])
        self.revalidate(second, predicate, deadline)
        point = [round(x) for x in two['point']]
        require(two['decor_bounds'][0] < point[0] < two['decor_bounds'][2] and
                two['decor_bounds'][1] < point[1] < two['decor_bounds'][3], 'Rounded touch outside actual target')
        self.events.append({'kind': 'actual_quiz_touch', 'point': point, 'target': two,
                            'observations': [first_witness, second_witness],
                            'layout_sha256': second['layout_sha256'], 'state': second['state']})
        write(self.out/'input-events.json', self.events)
        self.adb('shell', 'input', 'tap', *(str(x) for x in point), timeout=self.remaining(10, deadline))
        return {**second, 'saved_before_touch': saved_before}

    def intent(self, identifier, action, extras, predicate, deadline=None):
        deadline = min(deadline or self.deadline, self.deadline, time.monotonic()+90)
        before = self.touch_control(identifier, predicate, deadline=deadline)
        state = before['state']
        saved_before = before['saved_before_touch']
        request = self.wait('new-'+action+'-request',
                            lambda: self.raw(SESSION+state['token']+'/request.json', 'actual-request')[0],
                            lambda r: r.get('sequence', 0) > max(state['ack'], state['rejected']),
                            timeout=self.remaining(45, deadline))
        seq = integer(request.get('sequence'), 'request sequence', 1)
        self.wait(action+'-ack', lambda: self.state(state['token']),
                  lambda s: s['ack'] >= seq or s['rejected'] >= seq,
                  timeout=self.remaining(45, deadline))
        after = self.snapshot('after-'+action, deadline)
        saved_after = self.saved(after['state'])
        self.remaining(1, deadline)
        result = check_transition(state, request, after['state'], action, extras, saved_before, saved_after)
        write(self.out/(self.tag(action)+'-durable-intent.json'),
              {'transition': result, 'request': request, 'before': state, 'after': after['state'],
               'saved_before': saved_before, 'saved_after': saved_after})
        return after, result

    def flutter_observation(self, name, resolver, deadline):
        from PIL import Image
        require('MainActivity' in self.surfaces.resumed_activity(), 'Flutter is not foreground')
        tag = self.tag(name)
        nodes = self.live.live_nodes(self.out, tag)
        shot = self.probe.capture(self.out, tag, timeout=self.remaining(30, deadline))
        with Image.open(self.out/shot['file']) as image:
            image.load()
            size = image.size
        target = resolver(nodes, size)
        confirmed = self.live.live_nodes(self.out, tag+'-confirmed')
        current(target == resolver(confirmed, size), 'Flutter route/target changed during observation')
        require('MainActivity' in self.surfaces.resumed_activity(), 'Flutter Activity changed')
        self.remaining(1, deadline)
        observation = {'target': target, 'capture': shot, 'size_px': list(size),
                       'nodes': confirmed, 'density': self.density}
        write(self.out/(tag+'-target.json'), observation)
        return observation

    def flutter_touch(self, observation, resolver, deadline, kind):
        confirmed = self.live.live_nodes(self.out, self.tag('pre-input-flutter'))
        current(resolver(confirmed, observation['size_px']) == observation['target'],
                'Flutter target changed immediately before input')
        require('MainActivity' in self.surfaces.resumed_activity(), 'Flutter Activity changed before input')
        self.remaining(1, deadline)
        r = observation['target']['bounds']
        point = [round((r[0]+r[2])/2), round((r[1]+r[3])/2)]
        require(r[0] < point[0] < r[2] and r[1] < point[1] < r[3], 'Flutter tap outside bounds')
        self.events.append({'kind': kind, 'target': observation['target'],
                            'capture': observation['capture'], 'point': point})
        write(self.out/'input-events.json', self.events)
        self.adb('shell', 'input', 'tap', *(str(x) for x in point), timeout=self.remaining(10, deadline))

    def navigate(self):
        deadline = min(self.deadline, time.monotonic()+30)
        resolver = lambda nodes, size: shared.flutter_hub_navigation_target(nodes, size, self.density)
        ready = False
        while time.monotonic() < deadline:
            try:
                observation = self.flutter_observation('flutter-route', resolver, deadline)
                target = observation['target']
                if target and target['action'] == 'hub_ready':
                    ready = True
                    break
                if target:
                    self.flutter_touch(observation, resolver, deadline, 'actual_flutter_route_touch')
            except AuthorityChanged as error:
                write(self.out/(self.tag('route-changed')+'.json'), {'error': str(error)})
            time.sleep(.3)
        require(ready, 'Actual Flutter game hub was not reached')
        deadline = min(self.deadline, time.monotonic()+120)
        resolver = lambda nodes, size: self.creative.hub_choice(nodes, TITLE, size, 48*self.density)
        for direction in (1, -1):
            for attempt in range(11):
                observation = self.flutter_observation('quiz-hub', resolver, deadline)
                if observation['target']:
                    self.flutter_touch(observation, resolver, deadline, 'actual_quiz_hub_touch')
                    return
                if attempt == 10:
                    break
                size = observation['size_px']
                rects = [self.creative.bounds(n.get('bounds', '')) for n in observation['nodes']
                         if n.get('package') == PACKAGE and n.get('scrollable') == 'true']
                rects = [r for r in rects if r and 0 <= r[0] < r[2] <= size[0] and
                         0 <= r[1] < r[3] <= size[1]]
                require(rects, 'No actual Flutter hub scroll viewport')
                rect = max(rects, key=lambda r: (r[2]-r[0])*(r[3]-r[1]))
                latest = self.live.live_nodes(self.out, self.tag('pre-hub-swipe'))
                current(resolver(latest, size) is None and any(
                    n.get('package') == PACKAGE and n.get('scrollable') == 'true' and
                    self.creative.bounds(n.get('bounds', '')) == rect for n in latest),
                    'Hub scroll geometry changed')
                require('MainActivity' in self.surfaces.resumed_activity(), 'Hub Activity changed')
                self.remaining(1, deadline)
                x = round((rect[0]+rect[2])/2)
                lo, hi = (round(rect[1]+(rect[3]-rect[1])*f) for f in (.25, .75))
                start, end = (hi, lo) if direction == 1 else (lo, hi)
                self.events.append({'kind': 'actual_quiz_hub_scroll', 'capture': observation['capture'],
                                    'viewport': rect, 'from': [x, start], 'to': [x, end]})
                write(self.out/'input-events.json', self.events)
                self.adb('shell', 'input', 'swipe', str(x), str(start), str(x), str(end), '450',
                         timeout=self.remaining(10, deadline))
                time.sleep(.4)
        raise RuntimeError('Actual Quiz portal never became exposed after bounded real scrolling')

    def open_native_button(self):
        deadline = min(self.deadline, time.monotonic()+45)
        resolver = lambda nodes, size: flutter_target(nodes, '3D-Quizstudio öffnen', size, self.density)
        while time.monotonic() < deadline:
            observation = self.flutter_observation('reopen-quiz', resolver, deadline)
            if observation['target']:
                self.flutter_touch(observation, resolver, deadline, 'actual_quiz_reopen_touch')
                return
            time.sleep(.3)
        raise RuntimeError('Current Flutter Quiz has no enabled 48dp native launch control')

    def lease(self, token, active):
        before = int(self.adb('shell', 'date', '+%s%3N').strip())
        value, _ = self.raw(SESSION+token+'/lifecycle.json', 'lifecycle')
        after = int(self.adb('shell', 'date', '+%s%3N').strip())
        record = check_lease(value, before, after, active)
        write(self.out/(self.tag('lease')+'.json'), record)
        return record

    def activate(self, initial, label):
        """Observe current settled authority; never turn a stale pause into a tap."""
        deadline = min(self.deadline, time.monotonic()+60)
        expected = tuple(initial['state'][k] for k in ('token', 'owner', 'roundId'))
        original_save = self.saved(initial['state'])
        while time.monotonic() < deadline:
            observation = self.snapshot(label+'-current', deadline)
            state = observation['state']
            require(tuple(state[k] for k in ('token', 'owner', 'roundId')) == expected and
                    self.saved(state) == original_save, 'Startup changed round identity/history')
            self.remaining(1, deadline)
            if not state['paused'] and state['canSelect']:
                return observation, {'mode': 'actual_current_active', 'resume_sent': False}
            require(state['paused'] and not state['exit'], 'Quiz is not in an actionable partial state')
            try:
                after, result = self.intent('resume', 'resume', {}, lambda s: s['paused'] and not s['exit'], deadline)
                require(after['state']['canSelect'], 'Resume did not restore partial question input')
                return after, {'mode': 'actual_resume_and_positive_ack', 'resume_sent': True, 'transition': result}
            except AuthorityChanged as error:
                write(self.out/(self.tag(label+'-state-changed')+'.json'), {'error': str(error)})
        raise RuntimeError('Quiz did not reach real active authority before deadline')

    def exit_to_flutter(self, observation, saved, label):
        state = observation['state']
        before = self.touch_control('back', lambda s: s['roundId'] == state['roundId'] and not s['exit'])
        require(before['saved_before_touch'] == saved, 'Round changed before actual exit touch')
        self.surfaces.returned_to_flutter(self.out, TITLE, label)
        require(self.saved(state) == saved, 'Flutter return changed the durable Quiz history')
        def closed():
            result = subprocess.run(['adb', '-s', self.args.serial, 'shell', 'test', '-e', SESSION+state['token']],
                                    capture_output=True, timeout=self.remaining(10))
            record = {'path': SESSION+state['token'], 'returncode': result.returncode,
                      'stdout': result.stdout.decode(errors='replace'),
                      'stderr': result.stderr.decode(errors='replace')}
            write(self.out/(self.tag('closed-mailbox')+'.json'), record)
            require(result.returncode in (0, 1) and not result.stderr, 'Mailbox existence read failed')
            return result.returncode == 1
        self.wait('closed Quiz mailbox', closed, bool)
        return {'actual_flutter_pixels': label+'-return-pixels.json', 'old_mailbox_removed': True,
                'saved_round_unchanged': True,
                'scope': 'Actual Back input, native process exit, two real Flutter frames and closed mailbox; final exit ACK file may already be removed'}

    def binding(self):
        a = self.args
        for root, expected in ((a.candidate_source, a.expected_source), (a.native_source, a.expected_native)):
            require(re.fullmatch('[a-f0-9]{40}', expected), 'Full immutable source SHA required')
            def git(*parts):
                return subprocess.check_output(['git', '-C', str(root), *parts], timeout=self.remaining(30))
            require(git('rev-parse', 'HEAD').decode().strip() == expected, 'Checkout source differs')
            require(not git('status', '--porcelain', '--untracked-files=no').strip(), 'Tracked checkout is dirty')
        require(Path.cwd().resolve() == a.candidate_source and
                Path(__file__).resolve() == a.candidate_source/SELF and
                Path(shared.__file__).resolve() == a.candidate_source/shared.SELF,
                'Execute the actual candidate Quiz/shared reader from its clean CWD')
        hashes = {}
        for root, prefix, paths in ((a.candidate_source, '', SOURCE_FILES),
                                    (a.native_source, 'native/', NATIVE_FILES)):
            for relative in paths:
                file = root/relative
                original = subprocess.check_output(['git', '-C', str(root), 'show', 'HEAD:'+relative],
                                                   timeout=self.remaining(30))
                require(file.read_bytes() == original, 'Working source differs: '+prefix+relative)
                hashes[prefix+relative] = sha(file)
        identity = self.tour.verify_apk_identity(a.apk, a.provenance, a.sums)
        require(identity['flutter_source_commit'] == a.expected_source and
                identity['godot_revision'] == a.expected_native, 'APK/source mismatch')
        shared.verified_pck(a.apk, identity['godot_pck_sha256'])
        installed = self.adb('shell', 'pm', 'path', PACKAGE).strip().splitlines()
        require(len(installed) == 1 and installed[0].startswith('package:/data/app/') and
                installed[0].endswith('/base.apk'), 'Installed APK path ambiguous')
        installed_sha = self.adb('shell', 'sha256sum', installed[0][8:]).split()[0]
        require(installed_sha == identity['apk_sha256'], 'Installed APK differs from the verified candidate')
        return {'host': a.expected_source, 'native': a.expected_native, 'apk': identity,
                'actual_installed_apk_sha256': installed_sha, 'source_hashes': hashes}

    def run(self):
        a = self.args
        require(re.fullmatch(r'emulator-\d+', a.serial), 'Disposable emulator serial required')
        require(self.adb('get-serialno').strip() == a.serial, 'Wrong actual device')
        require(self.adb('shell', 'getprop', 'ro.kernel.qemu').strip() == '1' and
                self.adb('shell', 'id', '-u').strip() == '0',
                'Already rooted disposable emulator required; this probe never requests root')
        runtime = {'sdk': int(self.adb('shell', 'getprop', 'ro.build.version.sdk').strip()),
                   'release': self.adb('shell', 'getprop', 'ro.build.version.release').strip(),
                   'fingerprint': self.adb('shell', 'getprop', 'ro.build.fingerprint').strip(),
                   'model': self.adb('shell', 'getprop', 'ro.product.model').strip()}
        require(runtime['sdk'] == a.expected_api and runtime['release'] == {35: '15', 37: '17'}[a.expected_api]
                and runtime['fingerprint'], 'Actual requested Android runtime differs')
        before = self.binding()
        check_tour(parse_json(a.tour_result.read_bytes()), before['apk']['apk_sha256'], a.expected_api)
        density = self.adb('shell', 'wm', 'density')
        (self.out/'actual-density.txt').write_text(density)
        values = re.findall(r'(?:Override|Physical) density:\s*(\d+)', density)
        require(values, 'No actual Android density')
        self.density = int(values[-1])/160
        self.before_prefs = self.probe.prefs(self.out, self.tag('before-quiz'))
        student = self.before_prefs.get('flutter.lumo_learning_local_student_id_v1')
        require(type(student) is str and re.fullmatch('local-[a-f0-9]{32}', student),
                'Existing local test child required')
        self.owner = hashlib.sha256(student.encode()).hexdigest()
        write(self.out/'binding-before.json', before)
        self.navigate()
        self.wait('native Quiz Activity', lambda: 'TableGameActivity' in self.surfaces.resumed_activity(), bool, 60)
        initial = self.snapshot('initial-quiz')
        initial_saved = self.saved(initial['state'])
        require(initial_saved['actions'] == [] and initial['state']['number'] == 1 and
                initial['state']['selected'] is None and not initial['state']['revealed'],
                'This probe requires the actual untouched Quiz round; it will not clear or replace a save')
        active, startup = self.activate(initial, 'startup')
        token, first_pid = active['state']['token'], self.pid()
        leases = [self.lease(token, True)]
        transitions = []
        first_question = check_saved(self.saved(active['state']), active['state'])
        correct = integer(first_question['correctIndex'], 'read-only actual question oracle', 0, 3)
        active, result = self.intent('answer_'+str(correct), 'select', {'option': correct},
                                    lambda s: s['canSelect'] and s['number'] == 1 and s['selected'] is None)
        transitions.append(result)
        active, result = self.intent('reveal', 'reveal', {}, lambda s: s['canReveal'] and s['number'] == 1)
        transitions.append(result)
        active, result = self.intent('next', 'next', {}, lambda s: s['canNext'] and s['number'] == 1)
        transitions.append(result)
        second_question = check_saved(self.saved(active['state']), active['state'])
        correct = integer(second_question['correctIndex'], 'read-only second question oracle', 0, 3)
        active, result = self.intent('answer_'+str(correct), 'select', {'option': correct},
                                    lambda s: s['canSelect'] and s['number'] == 2 and s['selected'] is None)
        transitions.append(result)
        saved = self.saved(active['state'])
        paused, result = self.intent('pause', 'pause', {}, lambda s: not s['paused'] and s['number'] == 2)
        transitions.append(result)
        time.sleep(2)
        require(self.saved(self.state(token)) == saved, 'Paused Quiz changed its durable question history')
        active, result = self.intent('resume', 'resume', {}, lambda s: s['paused'] and s['number'] == 2)
        transitions.append(result)
        home = self.snapshot('before-home')
        self.revalidate(home, lambda s: not s['paused'], self.deadline)
        self.events.append({'kind': 'actual_home_key', 'keycode': 3, 'capture': home['capture'],
                            'layout_sha256': home['layout_sha256']})
        write(self.out/'input-events.json', self.events)
        self.adb('shell', 'input', 'keyevent', '3')
        inactive = self.wait('actual Home onPause lease', lambda: self.lease(token, False), lambda _: True)
        time.sleep(3)
        require(self.saved(self.state(token)) == saved, 'Background Quiz changed the durable round')
        self.base.launch(self.out, 'quiz-return-from-home')
        self.wait('same native Quiz after Home', lambda: 'TableGameActivity' in self.surfaces.resumed_activity(), bool)
        require(self.pid() == first_pid, 'Home return unexpectedly recreated native process')
        leases.append(self.wait('fresh active Home return lease', lambda: self.lease(token, True), lambda _: True))
        require(leases[-1]['pause_epoch'] >= inactive['pause_epoch'] > leases[0]['pause_epoch'],
                'Actual Activity pause epoch did not advance')
        active, home_resume = self.activate(self.snapshot('after-home'), 'home-return')
        require(self.saved(active['state']) == saved, 'Home return changed saved history')
        first_exit = self.exit_to_flutter(active, saved, 'quiz-first-flutter-return')
        self.open_native_button()
        self.wait('reopened native Quiz Activity', lambda: 'TableGameActivity' in self.surfaces.resumed_activity(), bool, 60)
        reopened = self.snapshot('reopened-quiz')
        reopen = check_reopen(active['state'], reopened['state'], saved, self.saved(reopened['state']))
        reopened, second_startup = self.activate(reopened, 'reopened')
        final_exit = self.exit_to_flutter(reopened, saved, 'quiz-final-flutter-return')
        after_prefs = self.probe.prefs(self.out, self.tag('after-quiz'))
        preserved_keys = protected_prefs(self.before_prefs, after_prefs, self.owner)
        learning = self.tour.evidence.learning_preserved(self.before_prefs, after_prefs)
        after = self.binding()
        require(before == after, 'Source or binary changed during Quiz probe')
        fatal = self.tour.logcat_fatal()
        require(not fatal, 'Actual app crash recorded: '+str(fatal))
        write(self.out/'binding-after.json', after)
        return {'status': 'PASS', 'source_binding': before, 'android_runtime': runtime,
                'actual_transitions': transitions, 'startup': startup, 'home_resume': home_resume,
                'reopen_startup': second_startup, 'leases': leases, 'home_inactive_lease': inactive,
                'reopen': reopen, 'returns': [first_exit, final_exit], 'protected_pref_keys': preserved_keys,
                'learning_preservation': learning, 'fatal_crashes': 0, 'visual_review': 'RECORDED_REVIEW_REQUIRED',
                'physical_fold7_performance_measured': False,
                'scope': 'Real hub/Quiz entry; first correct selection, reveal and next, second selection; durable trace and positive ACKs; pause, Home, real Flutter return and same-round reopen. Private answer data is a read-only QA oracle.',
                'not_tested': ['Complete twenty-question run, all jokers and reward payout',
                               'Switching to a second child', 'Physical Fold7/FPS/thermal/touch latency',
                               'Spoken audio or lip synchronization', 'Human visual approval of recorded Android images']}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('candidate-source', 'native-source', 'apk', 'provenance', 'sums', 'tour-result', 'out'):
        parser.add_argument('--'+name, type=Path, required=True)
    for name in ('expected-source', 'expected-native', 'serial'):
        parser.add_argument('--'+name, required=True)
    parser.add_argument('--expected-api', type=int, choices=(35, 37), required=True)
    args = parser.parse_args(argv)
    for name in ('candidate_source', 'native_source', 'apk', 'provenance', 'sums', 'tour_result', 'out'):
        setattr(args, name, getattr(args, name).resolve())
    if args.out.exists() and any(args.out.iterdir()):
        print('Refusing to overwrite previous Quiz evidence', file=sys.stderr)
        return 2
    previous_serial = os.environ.get('ANDROID_SERIAL')
    probe = None
    try:
        with bounded_runtime():
            probe = QuizProbe(args)
            result = probe.run()
            write(args.out/'result.json', result)
        return 0
    except Exception as error:
        args.out.mkdir(parents=True, exist_ok=True)
        write(args.out/'result.json', {'status': 'FAIL', 'error': f'{type(error).__name__}: {error}',
              'expected_host': args.expected_source, 'expected_native': args.expected_native,
              'physical_fold7_performance_measured': False})
        (args.out/'failure-traceback.txt').write_text(traceback.format_exc())
        if probe:
            try:
                probe.probe.capture(args.out, 'failure-actual-screen', timeout=10)
            except Exception as capture_error:
                (args.out/'failure-capture-error.txt').write_text(str(capture_error))
        return 1
    finally:
        if probe:
            probe.base.adb = probe.old_adb
        if previous_serial is None:
            os.environ.pop('ANDROID_SERIAL', None)
        else:
            os.environ['ANDROID_SERIAL'] = previous_serial


if __name__ == '__main__':
    raise SystemExit(main())
