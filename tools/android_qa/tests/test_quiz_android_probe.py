"""Pure Quiz-reader contracts; transport doubles are never Android evidence."""
from copy import deepcopy
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[3]
SHARED_PATH = Path(os.environ.get('LUMO_QUIZ_SHARED_SOURCE',
    str(ROOT/'.github/probes/studio_table_android_shared.py'))).resolve()
shared_spec = importlib.util.spec_from_file_location('studio_table_android_shared', SHARED_PATH)
SHARED = importlib.util.module_from_spec(shared_spec)
shared_spec.loader.exec_module(SHARED)
spec = importlib.util.spec_from_file_location('quiz_android_probe',
    ROOT/'.github/probes/lumo_quiz_android_probe.py')
PROBE = importlib.util.module_from_spec(spec)
with mock.patch.dict(sys.modules, {'studio_table_android_shared': SHARED}):
    spec.loader.exec_module(PROBE)
FIXTURES = Path(__file__).with_name('fixtures')/'quiz_native_layout'


def fixture(name='quiz-question-cutout.layout.json'):
    return PROBE.parse_json((FIXTURES/name).read_bytes())


def geometry(layout, **kwargs):
    return PROBE.check_layout(layout, layout['state'],
        layout['android_observation']['decor_size'], layout['density'], layout['pid'],
        allow_fixture=True, **kwargs)


def partial_round(actions=()):
    """Synthetic partial traces over the unchanged actual CI question roster."""
    saved = fixture('original-9f2e-durable-round.json')
    state = fixture('original-9f2e-public-state.json')
    saved.update(actions=[], revision=1)
    state.update(revision=2, ack=0, rejected=0, recordRevision=1, selected=None,
                 revealed=False, correctIndex=None, explanation=None, hidden=[],
                 usedJokers=[], audience=None, hint=None, canSelect=True,
                 canReveal=False, canNext=False)
    for action in actions:
        _, state, saved = synthetic_transition(state, saved, action)
    return state, saved


def synthetic_transition(before, old_save, action):
    """Explicit transport expectation, not a replacement quiz rules engine."""
    state, saved = deepcopy(before), deepcopy(old_save)
    request = {'token': state['token'], 'roundId': state['roundId'],
               'revision': state['revision'], 'sequence': state['ack']+1, **action}
    state.update(revision=state['revision']+1, ack=request['sequence'])
    if action['action'] in ('pause', 'resume'):
        state['paused'] = action['action'] == 'pause'
    else:
        saved['actions'].append(action)
        saved['revision'] += 1
        state['recordRevision'] += 1
        if action['action'] == 'select':
            state['selected'] = action['option']
        elif action['action'] == 'reveal':
            question = saved['questions'][state['number']-1]
            state.update(revealed=True, correctIndex=question['correctIndex'],
                         explanation=question['explanation'])
        elif action['action'] == 'next':
            question = saved['questions'][1]
            state.update(number=2, selected=None, revealed=False, correctIndex=None,
                         explanation=None, prompt=question['prompt'], options=question['options'],
                         questionSubject=question['subject'])
        else:
            raise AssertionError('Test case does not define this transport action')
    active = not state['paused']
    state.update(canSelect=active and not state['revealed'],
                 canReveal=active and not state['revealed'] and state['selected'] is not None,
                 canNext=active and state['revealed'])
    return request, state, saved


class ReaderContracts(unittest.TestCase):
    def test_all_original_state_fixtures_validate_and_android_rejects_desktop(self):
        for path in FIXTURES.glob('*.layout.json'):
            with self.subTest(path=path.name):
                value = fixture(path.name)
                PROBE.check_state(value['state'])
                with self.assertRaisesRegex(RuntimeError, 'actual Android'):
                    PROBE.check_layout(value, value['state'], [2400, 1080], 2.625, value['pid'])
        self.assertEqual(len(geometry(fixture())['exposed_targets']), 6)

    def test_real_nullable_explanation_is_valid_but_missing_or_wrong_type_is_not(self):
        state = fixture('original-9f2e-public-state.json')
        self.assertTrue(state['revealed'])
        self.assertIsNone(state['explanation'])
        PROBE.check_state(state)
        for value in (False, 3, [], {}):
            changed = deepcopy(state)
            changed['explanation'] = value
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                PROBE.check_state(changed)
        del state['explanation']
        with self.assertRaises(RuntimeError):
            PROBE.check_state(state)

    def test_json_numeric_hidden_indices_accept_only_unique_whole_values(self):
        state = fixture('original-9f2e-public-state.json')
        state['hidden'] = [2.0, 3.0]
        PROBE.check_state(state)
        for hidden in ([2, 2.0], [1.5], ['2'], [True], [-1], [4]):
            with self.subTest(hidden=hidden), self.assertRaises(RuntimeError):
                PROBE.check_state({**state, 'hidden': hidden})

    def test_owner_schema_permissions_and_unrevealed_answer_leaks_fail(self):
        state, _ = partial_round()
        with self.assertRaisesRegex(RuntimeError, 'another child'):
            PROBE.check_state(state, 'f'*64)
        for patch in ({'game': 'memory'}, {'schema': 2}, {'schema': True}, {'canReveal': True},
                      {'correctIndex': 1}, {'extra': True}, {'total': 19}):
            with self.subTest(patch=patch), self.assertRaises(RuntimeError):
                PROBE.check_state({**state, **patch})

    def test_layout_rejects_stale_authority_pid_bounds_and_fake_original_model(self):
        mutations = [lambda x: x.__setitem__('settled', False),
                     lambda x: x.__setitem__('schema', True),
                     lambda x: x.__setitem__('pending', 1),
                     lambda x: x.__setitem__('pending', False),
                     lambda x: x.__setitem__('ack', x['ack']+1),
                     lambda x: x.__setitem__('pid', True),
                     lambda x: x.__setitem__('density', float('nan')),
                     lambda x: x['android_observation']['insets'].__setitem__(0, 0),
                     lambda x: x['android_observation']['decor_size'].__setitem__(0, 1080),
                     lambda x: x['safe_rect'].__setitem__(0, 0),
                     lambda x: x['geometry'].__setitem__('bones', 64),
                     lambda x: x['geometry'].__setitem__('original_lumo_usable', False),
                     lambda x: x['buttons'].pop(),
                     lambda x: x['buttons'].__setitem__(1, deepcopy(x['buttons'][0]))]
        for index, mutate in enumerate(mutations):
            changed = fixture()
            mutate(changed)
            with self.subTest(index=index), self.assertRaises(RuntimeError):
                geometry(changed)

    def test_exposed_targets_require_real_safe_48dp_extent(self):
        for mutate in (lambda b: b['hit_rect_px'].__setitem__(2, 47.9*2.625),
                       lambda b: b['hit_rect_px'].__setitem__(0, 0),
                       lambda b: b.__setitem__('clipped', True),
                       lambda b: b.__setitem__('enabled', False)):
            layout = fixture()
            mutate(layout['buttons'][0])
            with self.assertRaises(RuntimeError):
                SHARED.button_target(layout, 'back', layout['density'])

    def test_hidden_option_cannot_remain_enabled_or_expose_answer_text(self):
        layout = fixture()
        layout['state']['hidden'] = [2.0, 3.0]
        layout['state']['usedJokers'] = ['fiftyFifty']
        for button in layout['buttons']:
            if button['id'] in ('answer_2', 'answer_3'):
                button.update(enabled=False, text='ABCD'[int(button['id'][-1])]+'  Ausgeblendet')
        geometry(layout)
        for update in ({'enabled': True}, {'text': 'C  Vier'}):
            changed = deepcopy(layout)
            next(b for b in changed['buttons'] if b['id'] == 'answer_2').update(update)
            with self.subTest(update=update), self.assertRaisesRegex(RuntimeError, 'hidden answer'):
                geometry(changed)

    def test_json_duplicates_nonfinite_and_private_path_traversal_rejected(self):
        for raw in ('{"a":1,"a":2}', '{"a":NaN}', '{"a":Infinity}'):
            with self.subTest(raw=raw), self.assertRaises(RuntimeError):
                PROBE.parse_json(raw)
        self.assertTrue(PROBE.allowed_read(PROBE.LAYOUT))
        self.assertTrue(PROBE.allowed_read(PROBE.SESSION+'a'*32+'/state.json'))
        for path in (PROBE.SESSION+'../state.json', PROBE.SESSION+'a'*32+'/other.json',
                     '/sdcard/state.json', PROBE.SESSION+'G'*32+'/request.json'):
            self.assertFalse(PROBE.allowed_read(path))

    def test_all_twenty_one_actual_tour_step_names_and_same_apk_sdk_required(self):
        report = {'status': 'PASS', 'apk_sha256': 'a'*64, 'android_sdk': '35',
                  'steps': [{'step': name, 'ok': True} for name in sorted(PROBE.TOUR_STEPS)]}
        PROBE.check_tour(report, 'a'*64, 35)
        for patch in ({'android_sdk': 35}, {'android_sdk': '37'}, {'apk_sha256': 'b'*64},
                      {'status': 'FAIL'}, {'steps': report['steps'][:-1]},
                      {'steps': report['steps'][:-1]+[report['steps'][0]]}):
            with self.subTest(patch=patch), self.assertRaises(RuntimeError):
                PROBE.check_tour({**report, **patch}, 'a'*64, 35)

    def test_readonly_real_roster_supports_exact_partial_trace_and_nullable_reveal(self):
        state, saved = partial_round()
        self.assertEqual(PROBE.check_saved(saved, state)['id'], 'e_sk_body_3')
        for action in ({'action': 'select', 'option': 1}, {'action': 'reveal'},
                       {'action': 'next'}, {'action': 'select', 'option': 1},
                       {'action': 'pause'}, {'action': 'resume'}):
            request, after, later = synthetic_transition(state, saved, action)
            extras = {key: value for key, value in action.items() if key != 'action'}
            PROBE.check_transition(state, request, after, action['action'], extras, saved, later)
            state, saved = after, later
        self.assertEqual(len(saved['actions']), 4)
        self.assertEqual(state['number'], 2)
        self.assertIsNone(state['explanation'])

    def test_partial_save_rejects_extra_joker_reward_question_mutation_and_repeated_append(self):
        before, old = partial_round()
        request, after, saved = synthetic_transition(before, old, {'action': 'select', 'option': 1})
        cases = [lambda s, p: p['actions'].append({'action': 'select', 'option': 1}),
                 lambda s, p: p['questions'][2].__setitem__('prompt', 'Changed other question'),
                 lambda s, p: p.__setitem__('owner', 'b'*64),
                 lambda s, p: s.__setitem__('securedStars', 1),
                 lambda s, p: s.__setitem__('usedJokers', ['callLumo'])]
        for index, mutate in enumerate(cases):
            changed, changed_save = deepcopy(after), deepcopy(saved)
            mutate(changed, changed_save)
            with self.subTest(index=index), self.assertRaises(RuntimeError):
                PROBE.check_transition(before, request, changed, 'select', {'option': 1}, old, changed_save)

    def test_missing_negative_or_foreign_ack_never_counts_as_action(self):
        before, old = partial_round()
        request, after, saved = synthetic_transition(before, old, {'action': 'select', 'option': 1})
        for patch in ({'ack': 0}, {'rejected': request['sequence']}, {'revision': before['revision']},
                      {'roundId': 'e'*32}, {'error': 'Speichern noch nicht bestätigt'}):
            with self.subTest(patch=patch), self.assertRaises(RuntimeError):
                PROBE.check_transition(before, request, {**after, **patch}, 'select', {'option': 1}, old, saved)
        for patch in ({'token': 'e'*32}, {'revision': 999}, {'sequence': 0},
                      {'action': 'reveal'}, {'option': 2}, {'extra': True}):
            with self.subTest(request_patch=patch), self.assertRaises(RuntimeError):
                PROBE.check_transition(before, {**request, **patch}, after, 'select', {'option': 1}, old, saved)

    def test_reopen_needs_new_token_same_owner_round_and_unchanged_saved_content(self):
        before, saved = partial_round(({'action': 'select', 'option': 1},))
        after = {**before, 'token': 'c'*32, 'revision': 1, 'ack': 0}
        PROBE.check_reopen(before, after, saved, saved)
        for patch in ({'token': before['token']}, {'owner': 'd'*64},
                      {'roundId': 'd'*32}, {'selected': None}):
            with self.subTest(patch=patch), self.assertRaises(RuntimeError):
                PROBE.check_reopen(before, {**after, **patch}, saved, saved)

    def test_other_owner_games_wallet_and_student_must_remain_unchanged(self):
        before = {'flutter.lumo_learning_local_student_id_v1': 'local-'+'a'*32,
                  'flutter.lumo_reward_wallet_v1': '{"stars":9}',
                  'flutter.lumo.memory.round.v1.other': '{}',
                  PROBE.ROUND_PREFIX+'b'*64: '{}'}
        PROBE.protected_prefs(before, {**before, PROBE.ROUND_PREFIX+'a'*64: '{}'}, 'a'*64)
        for key in before:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                PROBE.protected_prefs(before, {**before, key: 'changed'}, 'a'*64)

    def test_actual_lifecycle_requires_fresh_active_timestamp_and_integer_epoch(self):
        PROBE.check_lease({'active': True, 'stamp': 9000, 'pauseEpoch': 1}, 10000, 10001, True)
        PROBE.check_lease({'active': False, 'stamp': 1000, 'pauseEpoch': 2}, 10000, 10001, False)
        for patch in ({'active': False}, {'stamp': 7501}, {'stamp': 10002}, {'pauseEpoch': True}):
            with self.subTest(patch=patch), self.assertRaises(RuntimeError):
                PROBE.check_lease({'active': True, 'stamp': 9000, 'pauseEpoch': 1, **patch}, 10000, 10001, True)

    def test_real_caption_requires_exact_ocr_and_in_bounds_full_label(self):
        lines = [{'text': 'B Mit der Nase', 'bounds': [2, 2, 150, 28], 'variant': 'contrast'}]
        self.assertEqual(PROBE.caption_witness(lines, 'B  Mit der Nase', [200, 60])['lines'], lines)
        wrapped = [{'text': 'B Mit der', 'bounds': [2, 2, 100, 22], 'variant': 'contrast'},
                   {'text': 'Nase', 'bounds': [2, 25, 75, 45], 'variant': 'contrast'}]
        self.assertEqual(len(PROBE.caption_witness(wrapped, 'B Mit der Nase', [200, 60])['lines']), 2)
        for bad in ([{**lines[0], 'text': 'Mit der Nase'}],
                    [{**lines[0], 'text': 'B Mit der Nase EXTRA'}],
                    [{**lines[0], 'bounds': [0, 0, 201, 30]}],
                    [wrapped[0], {**wrapped[1], 'variant': 'mask'}]):
            with self.subTest(bad=bad), self.assertRaises(RuntimeError):
                PROBE.caption_witness(bad, 'B Mit der Nase', [200, 60])

    def test_flutter_reopen_target_needs_unique_enabled_full_48dp_semantics(self):
        node = {'package': PROBE.PACKAGE, 'content-desc': '3D-Quizstudio öffnen',
                'clickable': 'true', 'enabled': 'true', 'bounds': '[0,0][126,126]'}
        self.assertIsNotNone(PROBE.flutter_target([node], node['content-desc'], [1080, 2400], 2.625))
        for patch in ({'clickable': 'false'}, {'enabled': 'false'}, {'package': 'foreign'},
                      {'bounds': '[0,0][125,126]'}, {'content-desc': 'Another route'}):
            self.assertIsNone(PROBE.flutter_target([{**node, **patch}], node['content-desc'], [1080, 2400], 2.625))
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous'):
            PROBE.flutter_target([node, {**node, 'bounds': '[130,0][256,126]'}],
                                 node['content-desc'], [1080, 2400], 2.625)

    def test_cards_showcase_uses_current_back_control_not_unseen_games_tab(self):
        nodes = [{'package': PROBE.PACKAGE, 'text': 'LUMO CARDS'},
                 {'package': PROBE.PACKAGE, 'content-desc': 'Zur Spielwelt zurück',
                  'clickable': 'true', 'enabled': 'true', 'bounds': '[0,0][126,126]'}]
        target = SHARED.flutter_hub_navigation_target(nodes, [1080, 2400], 2.625)
        self.assertEqual(target['action'], 'leave_cards_showcase')
        self.assertEqual(target['caption'], 'Zur Spielwelt zurück')


class InputAndDeadlineContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.probe = object.__new__(PROBE.QuizProbe)
        self.probe.out = Path(self.temp.name)
        self.probe.deadline = 1000
        self.probe.count = 0
        self.probe.events = []
        self.probe.density = 2.625
        self.probe.args = SimpleNamespace(serial='emulator-5554')
        self.clock = mock.patch.object(PROBE.time, 'monotonic', return_value=100)
        self.clock.start()
        self.addCleanup(self.clock.stop)

    def observations(self):
        layout = fixture()
        first = {'state': deepcopy(layout['state']), 'layout': layout, 'layout_sha256': 'a'*64,
                 'capture': {'file': 'first.png'}}
        second = deepcopy(first)
        second['capture']['file'] = 'second.png'
        return first, second

    def arrange_touch(self):
        p = self.probe
        first, second = self.observations()
        order = []
        p.seek = mock.Mock(side_effect=lambda *a: order.append('first_frame') or first)
        p.snapshot = mock.Mock(side_effect=lambda *a: order.append('second_frame') or second)
        p.observed_caption = mock.Mock(side_effect=lambda *a: order.append('actual_caption') or {'text': 'Zurück'})
        p.saved = mock.Mock(side_effect=lambda *a: order.append('save_before') or {'original': 1})
        p.revalidate = mock.Mock(side_effect=lambda *a: order.append('revalidate'))
        p.adb = mock.Mock(side_effect=lambda *a, **kw: order.append('touch'))
        return first, second, order

    def test_two_real_frame_calls_caption_checks_and_save_precede_single_input(self):
        _, _, order = self.arrange_touch()
        result = self.probe.touch_control('back', lambda s: not s['exit'])
        self.assertEqual(order, ['first_frame', 'actual_caption', 'second_frame', 'actual_caption',
                                 'save_before', 'revalidate', 'touch'])
        self.assertEqual(result['saved_before_touch'], {'original': 1})
        self.probe.adb.assert_called_once()
        self.assertEqual(self.probe.adb.call_args.args[:3], ('shell', 'input', 'tap'))
        self.assertEqual(len(self.probe.events[0]['observations']), 2)

    def test_reused_frame_changed_state_or_target_blocks_input(self):
        for case in ('same_file', 'changed_state', 'changed_target', 'pre_input_changed'):
            first, second, _ = self.arrange_touch()
            if case == 'same_file':
                second['capture']['file'] = first['capture']['file']
            elif case == 'changed_state':
                second['state']['revision'] += 1
            elif case == 'changed_target':
                second['layout']['buttons'][0]['rect_px'][0] += 1
                second['layout']['buttons'][0]['hit_rect_px'][0] += 1
            else:
                self.probe.revalidate.side_effect = PROBE.AuthorityChanged('state changed')
            with self.subTest(case=case), self.assertRaises(RuntimeError):
                self.probe.touch_control('back', lambda _: True)
            self.probe.adb.assert_not_called()

    def test_tenth_scroll_is_followed_by_actual_observation(self):
        p = self.probe
        first, final = self.observations()
        first['layout']['buttons'][0]['clipped'] = True
        p.snapshot = mock.Mock(side_effect=[first]*10+[final])
        p.revalidate = mock.Mock()
        p.adb = mock.Mock()
        with mock.patch.object(PROBE.time, 'sleep'):
            found = p.seek('back', lambda _: True, 999)
        self.assertIs(found, final)
        self.assertEqual(p.adb.call_count, 10)
        self.assertEqual(p.snapshot.call_count, 11)

    def test_ocr_crop_is_original_scale_and_wanted_is_normalized(self):
        from PIL import Image
        p = self.probe
        first, _ = self.observations()
        original = p.out/'first.png'
        Image.new('RGB', (2400, 1080), (35, 45, 65)).save(original)
        before_hash = PROBE.sha(original)
        def lines(out, tag, wanted, *, source_path, timeout, exact):
            with Image.open(source_path) as crop:
                self.assertEqual(crop.size, (224, 137))
                self.assertEqual(crop.getpixel((10, 10)), (35, 45, 65))
            self.assertEqual(wanted, 'zuruck')
            self.assertTrue(exact)
            return [{'text': 'Zurück', 'bounds': [20, 20, 100, 60], 'variant': 'contrast'}]
        p.probe = SimpleNamespace(image_lines=lines)
        result = p.observed_caption(first, 'back', 999)
        self.assertEqual(result['observed']['text'], 'Zurück')
        self.assertEqual(PROBE.sha(original), before_hash)

    def test_failed_original_read_is_preserved_before_json_error(self):
        p = self.probe
        raw = b'cat: quiz_layout_v1.json: No such file or directory\n'
        with mock.patch.object(PROBE.subprocess, 'run', return_value=SimpleNamespace(
                stdout=raw, stderr=b'', returncode=0)):
            with self.assertRaises(json.JSONDecodeError):
                p.raw(PROBE.LAYOUT, 'not-ready')
        self.assertEqual(next(p.out.glob('*.raw')).read_bytes(), raw)
        report = json.loads(next(p.out.glob('*-read.json')).read_text())
        self.assertEqual(report['bytes'], len(raw))
        self.assertEqual(report['path'], PROBE.LAYOUT)

    def test_snapshot_cannot_pass_if_post_capture_reads_exceed_deadline(self):
        from PIL import Image
        p = self.probe
        layout = fixture()
        layout['observation_source'] = 'android_window_insets'  # synthetic transport only
        Image.new('RGB', (2400, 1080), (35, 45, 65)).save(p.out/'frame.png')
        p.foreground = mock.Mock()
        p.pid = mock.Mock(return_value=layout['pid'])
        p.state = mock.Mock(return_value=layout['state'])
        now = [100.0]
        def raw(path, label):
            if label == 'layout-after':
                now[0] = 146
            return layout, 'a'*64
        p.raw = raw
        p.probe = SimpleNamespace(capture=lambda *a, **kw: {'file': 'frame.png'})
        with mock.patch.object(PROBE.time, 'monotonic', side_effect=lambda: now[0]), \
                mock.patch.object(PROBE.time, 'sleep', side_effect=lambda s: now.__setitem__(0, now[0]+s)):
            with self.assertRaisesRegex(RuntimeError, 'No stable actual Quiz'):
                p.snapshot('late')
        self.assertFalse(list(p.out.glob('*-observation.json')))
        self.assertTrue(list(p.out.glob('*-rejected.json')))

    def test_startup_natural_activation_does_not_send_resume(self):
        state, saved = partial_round()
        paused = {**state, 'paused': True, 'canSelect': False}
        p = self.probe
        p.saved = mock.Mock(return_value=saved)
        p.snapshot = mock.Mock(return_value={'state': state})
        p.intent = mock.Mock()
        _, report = p.activate({'state': paused}, 'startup')
        self.assertFalse(report['resume_sent'])
        p.intent.assert_not_called()

    def test_startup_revalidates_pause_change_and_never_hides_missing_ack(self):
        state, saved = partial_round()
        paused = {**state, 'paused': True, 'canSelect': False}
        p = self.probe
        p.saved = mock.Mock(return_value=saved)
        p.snapshot = mock.Mock(side_effect=[{'state': paused}, {'state': state}])
        p.intent = mock.Mock(side_effect=PROBE.AuthorityChanged('became active before input'))
        _, report = p.activate({'state': paused}, 'startup')
        self.assertFalse(report['resume_sent'])
        p.intent.assert_called_once()
        p.snapshot = mock.Mock(return_value={'state': paused})
        p.intent = mock.Mock(side_effect=RuntimeError('no positive ACK after actual input'))
        with self.assertRaisesRegex(RuntimeError, 'positive ACK'):
            p.activate({'state': paused}, 'startup')

    def test_startup_persistent_pause_needs_real_intent_and_positive_ack(self):
        state, saved = partial_round()
        paused = {**state, 'paused': True, 'canSelect': False}
        p = self.probe
        p.saved = mock.Mock(return_value=saved)
        p.snapshot = mock.Mock(return_value={'state': paused})
        p.intent = mock.Mock(return_value=({'state': state}, {'sequence': 1, 'ack': 1}))
        _, report = p.activate({'state': paused}, 'startup')
        self.assertTrue(report['resume_sent'])
        self.assertEqual(p.intent.call_args.args[:3], ('resume', 'resume', {}))
        self.assertEqual(report['transition']['ack'], 1)

    def test_last_durable_read_cannot_complete_intent_after_deadline(self):
        p = self.probe
        state, saved = partial_round()
        request, after, later = synthetic_transition(state, saved, {'action': 'select', 'option': 1})
        p.touch_control = mock.Mock(return_value={'state': state, 'saved_before_touch': saved})
        p.wait = mock.Mock(side_effect=[request, after])
        p.snapshot = mock.Mock(return_value={'state': after})
        now = [100.0]
        def late_save(_):
            now[0] = 191
            return later
        p.saved = late_save
        with mock.patch.object(PROBE.time, 'monotonic', side_effect=lambda: now[0]):
            with self.assertRaisesRegex(RuntimeError, 'deadline'):
                p.intent('answer_1', 'select', {'option': 1}, lambda _: True)
        self.assertFalse(list(p.out.glob('*-durable-intent.json')))

    def test_current_flutter_foreground_and_post_xml_deadline_block_tap(self):
        p = self.probe
        target = {'bounds': [0, 0, 126, 126]}
        p.live = SimpleNamespace(live_nodes=lambda *a: [])
        p.surfaces = SimpleNamespace(resumed_activity=lambda: 'foreign.Activity')
        p.adb = mock.Mock()
        observation = {'target': target, 'size_px': [1080, 2400], 'capture': {'file': 'frame.png'}}
        with self.assertRaisesRegex(RuntimeError, 'Activity changed'):
            p.flutter_touch(observation, lambda *a: target, 100, 'test')
        p.surfaces.resumed_activity = lambda: 'MainActivity'
        with self.assertRaisesRegex(RuntimeError, 'deadline'):
            p.flutter_touch(observation, lambda *a: target, 99, 'test')
        p.adb.assert_not_called()

    def test_global_alarm_restores_previous_timer_and_handler_on_failure(self):
        old_handler = object()
        with mock.patch.object(PROBE.signal, 'getsignal', return_value=old_handler), \
                mock.patch.object(PROBE.signal, 'getitimer', return_value=(20, 3)), \
                mock.patch.object(PROBE.signal, 'signal') as handler, \
                mock.patch.object(PROBE.signal, 'setitimer') as timer:
            with self.assertRaisesRegex(ValueError, 'test failure'):
                with PROBE.bounded_runtime():
                    raise ValueError('test failure')
            self.assertEqual(handler.call_args.args, (signal.SIGALRM, old_handler))
            self.assertEqual(timer.call_args.args, (signal.ITIMER_REAL, 20, 3))


if __name__ == '__main__':
    unittest.main()
