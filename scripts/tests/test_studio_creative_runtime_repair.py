"""Replay failed d2c Android observations; synthetic transitions are labelled."""
import ast
import copy
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re
import sys
import tempfile
import time
from types import ModuleType, SimpleNamespace
import unicodedata
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'tools/android_qa/tests/fixtures/studio_creative_d2c'
for relative in ('.github/probes', 'tools/android_qa', 'scripts/probes'):
    sys.path.insert(0, str(ROOT / relative))


def load(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


probe = load('studio_creative_runtime_repair', '.github/probes/studio_creative_android_probe.py')
# Compile the actual two helper bodies without importing a live-device client.
# Their native text/ADB dependencies are explicitly mocked below; this is an
# offline source-function replay, not an emulator execution.
candidate = ModuleType('candidate_creative_runtime_repair')
candidate.__dict__.update(Path=Path, re=re, time=time, unicodedata=unicodedata,
    PACKAGE=probe.PACKAGE, base=SimpleNamespace(adb=Mock(), foreground=Mock()),
    native_text=Mock(), capture=Mock())
helper_tree = ast.parse((ROOT / '.github/probes/creative_android_probe.py').read_text())
helper_functions = [node for node in helper_tree.body if isinstance(node, ast.FunctionDef)
                    and node.name in ('normalized', 'leave')]
assert len(helper_functions) == 2
exec(compile(ast.Module(body=helper_functions, type_ignores=[]),
             '.github/probes/creative_android_probe.py', 'exec'), candidate.__dict__)
surface = load('creative_runtime_surface', 'tools/android_qa/native_surface_readiness.py')
candidate.inspect_surface = surface.inspect_surface
candidate.target_observation = surface.target_observation


class ActualCreativeObservations(unittest.TestCase):
    def tour(self, image_name, ocr_name):
        tour = probe.Tour.__new__(probe.Tour)
        tour.counter, tour.out, tour.events = 0, FIXTURE, []
        image = FIXTURE / image_name
        with probe.Image.open(image) as original:
            width, height = original.size
        shot = {'file': image.name, 'width': width, 'height': height,
                'sha256': hashlib.sha256(image.read_bytes()).hexdigest()}
        lines = json.loads((FIXTURE / ocr_name).read_text())
        tour.shot = Mock(return_value=(image, shot))
        tour.portal = Mock()
        tour.base = SimpleNamespace(foreground=lambda: 'LumoGameActivity', adb=lambda *a, **k: '991')

        def native_text(out, label, tag, *, tap=False, exact=False, orientation='landscape'):
            if tap:
                frame = candidate.inspect_surface(image, orientation=orientation)
                probe.require(frame['acceptable_for_target_sampling'], str(frame['reasons']))

        tour.probe = SimpleNamespace(normalized=candidate.normalized,
            native_text=Mock(side_effect=native_text),
            image_lines=Mock(return_value=lines), inspect_surface=candidate.inspect_surface,
            target_observation=candidate.target_observation)
        return tour

    def test_original_fixture_bytes_and_failure_identity_remain_exact(self):
        manifest = json.loads((FIXTURE / 'provenance.json').read_text())
        self.assertEqual(manifest['original_run'], 43519068565)
        self.assertEqual(manifest['original_artifact'], 14083963783)
        for item in manifest['files']:
            with self.subTest(path=item['path']):
                data = (FIXTURE / item['path']).read_bytes()
                self.assertEqual(len(data), item['bytes'])
                self.assertEqual(hashlib.sha256(data).hexdigest(), item['sha256'])
        old = json.loads((FIXTURE / '0013-native-pause-surface-readiness.json').read_text())
        self.assertEqual(old['status'], 'FAIL')
        self.assertEqual(len(old['frames']), 31)
        self.assertTrue(all(frame['pixels'] == [1080, 1920] and frame['reasons'] ==
                            ['native landscape surface has not arrived'] for frame in old['frames']))

    def test_jump_uses_portrait_policy_and_can_sample_original_action_caption(self):
        tour = self.tour('0011-native-haltenhoherspringen-3.png',
                         '0011-native-haltenhoherspringen-3-ocr.json')
        with patch.object(probe.time, 'sleep'):
            tour.enter('Jump & Run', 'Halten = höher springen')
            tour.native('Pause', tap=True, exact=True)
            observed = tour.observe('SPRINGEN', exact=True)
        self.assertEqual(tour.probe.native_text.call_args.kwargs['orientation'], 'responsive')
        self.assertTrue(observed['stable']['stable_observed_target'])
        self.assertEqual(observed['capture']['width'], 1080)

    def test_actual_jump_ocr_selects_action_not_the_same_word_in_instructions(self):
        tour = self.tour('0014-jump-failure.png', 'local-replay/actual-original-springen-ocr.json')
        tour.enter('Jump & Run', 'Halten = höher springen')
        with patch.object(probe.time, 'sleep'):
            observed = tour.observe('SPRINGEN', exact=True, control='jump-action')
        self.assertEqual(observed['bounds'], [895.0, 1777.5, 1010.0, 1793.0])
        self.assertEqual(observed['source_control'], 'jump-action')
        manifest = json.loads((FIXTURE / 'provenance.json').read_text())
        for item in manifest['local_ocr_replay']:
            self.assertEqual(hashlib.sha256((FIXTURE / item['path']).read_bytes()).hexdigest(), item['sha256'])
        replay = json.loads((FIXTURE / 'local-replay/replay.json').read_text())
        self.assertEqual(replay['results']['Pause']['status'], 'MISSING')

    def test_jump_action_rejects_instruction_only_or_two_separate_lower_controls(self):
        rows = json.loads((FIXTURE / 'local-replay/actual-original-springen-ocr.json').read_text())
        instruction = next(row for row in rows if row['text'] == 'springen')
        action = next(row for row in rows if row['text'] == 'SPRINGEN')
        for lines in ([instruction], [action, {**action, 'bounds': [730, 1400, 850, 1430]}]):
            with self.subTest(lines=lines), self.assertRaises(RuntimeError):
                probe.jump_action_choice(lines, [1080, 1920], candidate.normalized)

    def test_following_companion_game_keeps_landscape_handoff_requirement(self):
        tour = self.tour('0014-jump-failure.png', '0011-native-haltenhoherspringen-1-ocr.json')
        tour.enter('Jump & Run', 'Halten = höher springen')
        tour.enter('Bauwelt', 'LUMO BAUWELT')
        with self.assertRaisesRegex(RuntimeError, 'landscape'):
            tour.native('Pause', tap=True, exact=True)
        self.assertEqual(tour.probe.native_text.call_args.kwargs.get('orientation', 'landscape'), 'landscape')

    def test_common_return_propagates_jump_policy_without_skipping_process_exit(self):
        with patch.object(candidate, 'native_text') as touch, \
                patch.object(candidate.base, 'adb', return_value='') as adb, \
                patch.object(candidate.base, 'foreground', return_value='MainActivity'), \
                patch.object(candidate, 'capture'):
            candidate.leave(FIXTURE, 'replay-return', already_menu=True,
                            return_label='Zur Spieleauswahl · Abenteuer behalten',
                            orientation='responsive')
        self.assertEqual(touch.call_args.kwargs['orientation'], 'responsive')
        self.assertTrue(touch.call_args.kwargs['exact'])
        self.assertIn(('shell', 'pidof', candidate.PACKAGE + ':lumo_game'),
                      [call.args for call in adb.call_args_list])

    def test_actual_motif_observation_never_touches_the_short_toolbar_word(self):
        tour = self.tour('0100-observe-bild.png', '0100-observe-bild-ocr.json')

        class ObservedFirstSelection(Exception):
            pass

        def touch(point, observed):
            self.assertEqual(observed['text'], 'Bild: Leuchtturm-Bucht')
            self.assertEqual(point, [905.0, 367.0])
            raise ObservedFirstSelection

        tour.touch = touch
        with patch.object(probe.time, 'sleep'), self.assertRaises(ObservedFirstSelection):
            tour.select_puzzle_motif()

    def test_full_caption_selector_rejects_fragments_unknown_titles_and_two_controls(self):
        line = {'text': 'Bild: Leuchtturm-Bucht', 'bounds': [772, 358, 1038, 376]}
        for text in ('Bild', 'Bild:', 'Bild ansehen', 'Bild: Candy Cloud Circuit Extra'):
            with self.subTest(text=text), self.assertRaises(RuntimeError):
                probe.full_caption_choice([{**line, 'text': text}], probe.PUZZLE_MOTIF_CAPTIONS,
                                          candidate.normalized)
        for second in ({**line, 'bounds': [772, 700, 1038, 718]},
                       {**line, 'text': 'Bild: Candy Cloud Circuit'}):
            with self.subTest(second=second), self.assertRaises(RuntimeError):
                probe.full_caption_choice([line, second], probe.PUZZLE_MOTIF_CAPTIONS,
                                          candidate.normalized)

    def test_full_caption_variants_must_identify_the_same_actual_control(self):
        lines = json.loads((FIXTURE / '0100-observe-bild-ocr.json').read_text())
        full = next(x for x in lines if x['text'] == 'Bild: Leuchtturm-Bucht')
        selected = probe.full_caption_choice(lines + [{**full, 'variant': 'second-reader'}],
                                            probe.PUZZLE_MOTIF_CAPTIONS, candidate.normalized)
        self.assertEqual(selected['bounds'], [772.0, 358.0, 1038.0, 376.0])
        for title in probe.PUZZLE_MOTIF_CAPTIONS:
            self.assertEqual(probe.full_caption_choice([{**full, 'text': title}],
                probe.PUZZLE_MOTIF_CAPTIONS, candidate.normalized)['text'], title)


class TreasureObservedProgress(unittest.TestCase):
    def originals(self):
        return [json.loads(path.read_text()) for path in sorted(FIXTURE.glob('*treasure-save-*.json'))]

    def test_actual_slow_progress_does_not_use_six_world_units_per_wall_second(self):
        saves = self.originals()
        events = json.loads((FIXTURE / 'real-input-events.json').read_text())
        gestures = [e for e in events if 'axis_direction' in e.get('context', {})]
        self.assertEqual(len(saves), 13)
        self.assertEqual(len(gestures), 12)
        history = []
        distance = lambda s: math.hypot(-12 - s['position'][0], -8 - s['position'][2])
        for before, after, event in zip(saves, saves[1:], gestures):
            history.append({'distance_before': distance(before), 'distance_after': distance(after),
                            'milliseconds': int(event['arguments'][-1])})
        self.assertGreater(distance(saves[-1]), 5.6)
        self.assertEqual(gestures[-1]['arguments'][-1], '509')
        duration = probe.treasure_movement_duration(distance(saves[-1]), history)
        self.assertGreater(duration, 509)
        self.assertLessEqual(duration, 1800)

    def scripted_tour(self, saves):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        tour = probe.Tour.__new__(probe.Tour)
        tour.out, tour.events = Path(temporary.name), []
        tour.enter = Mock()
        remaining = iter(saves)

        def saved(kind):
            self.assertEqual(kind, 'treasure')
            try:
                return copy.deepcopy(next(remaining))
            except StopIteration:
                raise RuntimeError('Captured original sequence ended before the target')

        def move(axis, milliseconds):
            self.assertTrue(100 <= milliseconds <= 1800)
            tour.events.append({'context': {'axis_direction': axis}, 'milliseconds': milliseconds})

        class ActualQuestionRequired(Exception):
            pass

        def native(label, tap=False, exact=False):
            self.assertEqual((label, tap, exact), ('ANSEHEN', True, True))
            raise ActualQuestionRequired

        tour.pause_save, tour.move_stick = saved, move
        tour.native = Mock(side_effect=native)
        return tour, ActualQuestionRequired

    def test_last_permitted_synthetic_step_is_observed_before_arrival_decision(self):
        # Only the control boundary is synthetic. These positions are never
        # presented as captured Android results or a successful clue answer.
        states = [{'position': [-10.2 * i / 18, 0, 6 - 12 * i / 18],
                   'result_id': 'synthetic-final-boundary'} for i in range(19)]
        tour, boundary = self.scripted_tour(states)
        with patch.object(probe.time, 'sleep'), self.assertRaises(boundary):
            tour.treasure()
        self.assertEqual(len(tour.events), 18)

    def test_incomplete_original_position_series_cannot_claim_arrival_or_answer(self):
        tour, _ = self.scripted_tour(self.originals())
        with patch.object(probe.time, 'sleep'), self.assertRaisesRegex(RuntimeError, 'before the target'):
            tour.treasure()
        tour.native.assert_not_called()

    def test_wrong_direction_stall_or_changed_result_identity_stops_before_another_input(self):
        initial = self.originals()[0]
        for after in (copy.deepcopy(initial),
                      {**initial, 'position': [1, 0, 7]},
                      {**initial, 'position': [-1, 0, 5], 'result_id': 'another-session'}):
            tour, _ = self.scripted_tour([initial, after])
            with self.subTest(after=after), patch.object(probe.time, 'sleep'), self.assertRaises(RuntimeError):
                tour.treasure()
            self.assertEqual(len(tour.events), 1)
            tour.native.assert_not_called()

    def test_duration_rejects_nonfinite_positions_and_fabricated_progress(self):
        for distance in (True, float('nan'), float('inf'), -1, 3.3):
            with self.subTest(distance=distance), self.assertRaises(RuntimeError):
                probe.treasure_movement_duration(distance, [])
        for item in ({'distance_before': 5, 'distance_after': 5, 'milliseconds': 1500},
                     {'distance_before': 5, 'distance_after': 6, 'milliseconds': 1500},
                     {'distance_before': 6, 'distance_after': 5, 'milliseconds': True},
                     {'distance_before': 6, 'distance_after': float('nan'), 'milliseconds': 1500}):
            with self.subTest(item=item), self.assertRaises(RuntimeError):
                probe.treasure_movement_duration(5, [item])


class TreasureDeadlineGuards(unittest.TestCase):
    originals = TreasureObservedProgress.originals
    scripted_tour = TreasureObservedProgress.scripted_tour

    def audit_tour(self, clock, after_shot=None):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        tour = probe.Tour.__new__(probe.Tour)
        tour.out = Path(temporary.name)
        tour.events, tour.context = [], {'basis': 'Synthetic deadline boundary only'}
        tour.input_deadline = 10.0
        tour.raw_adb = Mock(return_value='OK')
        path = FIXTURE / '0014-jump-failure.png'

        def shot(label):
            if after_shot is not None:
                clock[0] = after_shot
            return path, {'file': path.name, 'width': 1080, 'height': 1920,
                          'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}

        tour.shot = shot
        return tour

    def test_late_saved_arrival_never_reaches_the_question(self):
        initial = self.originals()[0]
        tour, _ = self.scripted_tour([initial, {**initial, 'position': [-10.2, 0, -6]}])
        clock, reads = [0.0], [0]
        original = tour.pause_save

        def delayed_save(kind):
            value = original(kind)
            reads[0] += 1
            if reads[0] == 2:
                clock[0] = 1201.0
            return value

        tour.pause_save = delayed_save
        with patch.object(probe.time, 'monotonic', side_effect=lambda: clock[0]), \
                patch.object(probe.time, 'sleep'), self.assertRaisesRegex(RuntimeError, 'deadline'):
            tour.treasure()
        tour.native.assert_not_called()
        self.assertIsNone(getattr(tour, 'input_deadline', None))

    def test_screenshot_crossing_deadline_never_dispatches_input(self):
        clock = [1.0]
        tour = self.audit_tour(clock, after_shot=11.0)
        with patch.object(probe.time, 'monotonic', side_effect=lambda: clock[0]), \
                self.assertRaisesRegex(RuntimeError, 'deadline'):
            tour.audit_adb('shell', 'input', 'swipe', '100', '100', '100', '100', '120')
        tour.raw_adb.assert_not_called()

    def test_journal_crossing_deadline_never_dispatches_input(self):
        clock = [1.0]
        tour = self.audit_tour(clock)

        def slow_write(*args):
            clock[0] = 11.0

        with patch.object(probe.time, 'monotonic', side_effect=lambda: clock[0]), \
                patch.object(probe, 'write', side_effect=slow_write), \
                self.assertRaisesRegex(RuntimeError, 'deadline'):
            tour.audit_adb('shell', 'input', 'swipe', '100', '100', '100', '100', '120')
        tour.raw_adb.assert_not_called()

    def test_entire_requested_hold_must_fit_remaining_budget(self):
        clock = [9.5]
        tour = self.audit_tour(clock)
        with patch.object(probe.time, 'monotonic', side_effect=lambda: clock[0]), \
                self.assertRaisesRegex(RuntimeError, 'deadline'):
            tour.audit_adb('shell', 'input', 'swipe', '100', '100', '100', '100', '650')
        tour.raw_adb.assert_not_called()

    def test_actual_read_and_input_timeouts_are_clamped_to_same_remaining_budget(self):
        for arguments in (('shell', 'dumpsys', 'window', 'windows'),
                          ('shell', 'input', 'swipe', '100', '100', '100', '100', '120')):
            clock = [1.0]
            tour = self.audit_tour(clock)
            with self.subTest(arguments=arguments), \
                    patch.object(probe.time, 'monotonic', side_effect=lambda: clock[0]):
                self.assertEqual(tour.audit_adb(*arguments, timeout=60), 'OK')
                self.assertEqual(tour.raw_adb.call_args.kwargs['timeout'], 9.0)


if __name__ == '__main__':
    unittest.main()
