"""Garage/Continue rejection cases and real probe wiring; synthetic observations.

These unit tests do not establish an Android or physical-device acceptance.
"""
from __future__ import annotations

import copy
import ast
import hashlib
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kart_garage_evidence as evidence
from test_modernization_tour_identity import TOUR_MODULE as tour


def race(**changes):
    return dict({'version': 3, 'result_id': 'new-race', 'mode': 'cup', 'track_id': 'sonnenhafen',
                 'selected_driver': 'fox', 'selected_kart': 'gecko_velo', 'finished': False,
                 'completed_race': False, 'distance': 20.0, 'elapsed': 5.0, 'countdown': 0.0,
                 'checkpoint_index': 0, 'lane': 0.0, 'speed': 12.0, 'difficulty': 'pro',
                 'reset_count': 0, 'player_heading': 0.0, 'previous_road_distance': 20.0,
                 'result_payload': {}}, **changes)


def config(state):
    return '[race]\n' + '\n'.join(key + '=' + json.dumps(value) for key, value in state.items()) + '\n'


def list_frame():
    return {'acceptable_for_target_sampling': True, 'pixels': [2400, 1080]}


def list_lines():
    return [{'text': 'Karts', 'bounds': [700, 160, 800, 200]},
            {'text': 'Comet', 'bounds': [100, 300, 250, 340]},
            {'text': 'Rennen starten', 'bounds': [1300, 950, 1500, 990]},
            {'text': 'Kart-Menü', 'bounds': [100, 950, 300, 990]}]


def driver_lines():
    # Source-confirmed layout, synthetic OCR: the brand precedes the driver
    # card and has the exact same caption. These are not Android observations.
    return [{'text': 'Lumo', 'bounds': [100, 40, 250, 90]},
            {'text': 'Fahrer', 'bounds': [400, 160, 550, 200]},
            {'text': 'Karts', 'bounds': [700, 160, 800, 200]},
            {'text': 'Lumo', 'bounds': [100, 300, 250, 340]},
            {'text': 'Rennen starten', 'bounds': [1300, 950, 1500, 990]},
            {'text': 'Kart-Menü', 'bounds': [100, 950, 300, 990]}]


class GarageSelectionEvidenceTests(unittest.TestCase):
    def test_only_the_requested_free_vehicle_in_a_new_real_race_is_accepted(self):
        for kart in evidence.KARTS:
            evidence.require_selected_race(race(selected_kart=kart), kart, previous_id='old-race')
        for changes in ({'selected_kart': 'comet'}, {'selected_driver': 'bear'},
                        {'track_id': 'other'}, {'mode': 'race'}, {'finished': True},
                        {'result_id': 'old-race'}, {'result_id': ''}, {'elapsed': float('nan')},
                        {'countdown': True}, {'distance': float('inf')}):
            with self.subTest(changes=changes), self.assertRaises(RuntimeError):
                evidence.require_selected_race(race(**changes), 'gecko_velo', previous_id='old-race')

    def test_only_the_previous_snapshot_can_wait_before_the_first_new_identity(self):
        old = race(result_id='old-race', selected_kart='comet', mode='race')
        self.assertEqual(evidence.selected_race_readiness(old, 'gecko_velo', 'old-race', None), (None, False))
        waiting = race(countdown=3.5, elapsed=0.0)
        self.assertEqual(evidence.selected_race_readiness(waiting, 'gecko_velo', 'old-race', None),
                         ('new-race', False))
        self.assertEqual(evidence.selected_race_readiness(race(), 'gecko_velo', 'old-race', 'new-race'),
                         ('new-race', True))
        for state, observed in ((old, 'new-race'), (race(result_id='third-race'), 'new-race'),
                                (race(selected_kart='comet'), None)):
            with self.subTest(state=state, observed=observed), self.assertRaises(RuntimeError):
                evidence.selected_race_readiness(state, 'gecko_velo', 'old-race', observed)

    def test_continue_requires_same_race_and_vehicle_plus_new_distance_and_time(self):
        paused = race()
        valid = race(distance=28.0, elapsed=7.5)
        report = evidence.require_resumed_progress(paused, valid, 'gecko_velo')
        self.assertEqual(report['distance_gain_after_continue'], 8.0)
        self.assertEqual(report['elapsed_gain_after_continue'], 2.5)
        for changes in ({'distance': 27.999}, {'elapsed': 7.499}, {'result_id': 'different'},
                        {'selected_kart': 'comet'}, {'selected_driver': 'owl'}, {'countdown': 3.5}):
            with self.subTest(changes=changes), self.assertRaises(RuntimeError):
                evidence.require_resumed_progress(paused, dict(valid, **changes), 'gecko_velo')


class GarageObservedScrollTests(unittest.TestCase):
    def test_current_hidden_title_layout_uses_only_the_tab_footer_and_left_card(self):
        proof = evidence.stage_garage_scroll_observation(list_frame(), list_lines())
        self.assertEqual(proof['gesture'], [175, 320, 175, 208])

    def test_missing_anchors_incomplete_frames_and_right_preview_are_rejected(self):
        bad_preview = copy.deepcopy(list_lines())
        bad_preview[1]['bounds'] = [1500, 300, 1650, 340]
        for frame, lines in ((dict(list_frame(), acceptable_for_target_sampling=False), list_lines()),
                             (list_frame(), list_lines()[1:]),
                             (list_frame(), list_lines()[:2]),
                             (list_frame(), bad_preview)):
            with self.subTest(frame=frame, lines=lines), self.assertRaises(RuntimeError):
                evidence.stage_garage_scroll_observation(frame, lines)

    def test_actual_scroll_needs_two_stable_frames_and_unchanged_screenshot(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / 'synthetic-observation.png'
            source.write_bytes(b'synthetic screenshot observation')
            frame = dict(list_frame(), source_sha256=hashlib.sha256(source.read_bytes()).hexdigest())
            callback = tour._stage_kart_scroll_recovery()
            with patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'monotonic', return_value=0):
                first = callback(frame, list_lines(), source, deadline=10, previous_missing_frame=None)
                self.assertEqual(first['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
                adb.assert_not_called()
                second = callback(frame, list_lines(), source, deadline=10, previous_missing_frame=frame)
                self.assertEqual(second['status'], 'SWIPE_SENT')
                self.assertEqual(adb.call_args.args, ('shell', 'input', 'swipe', '175', '320', '175', '208', '650'))
                callback(frame, list_lines(), source, deadline=10, previous_missing_frame=None)
                source.write_bytes(b'changed after sampling')
                with self.assertRaisesRegex(RuntimeError, 'screenshot changed'):
                    callback(frame, list_lines(), source, deadline=10, previous_missing_frame=frame)
                self.assertEqual(adb.call_count, 1)


class DriverObservedTargetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        self.capture_count = 0

    def capture(self, _out, tag, **_kwargs):
        self.capture_count += 1
        target = self.out / (tag + '.png')
        Image.new('RGB', (2400, 1080), (30, 50, 70)).save(target)
        return {'file': target.name}

    def test_logo_first_reader_reproduces_old_mistouch_but_driver_card_is_selected(self):
        with patch.object(tour.probe, 'capture', side_effect=self.capture), \
                patch.object(tour.probe, 'image_lines', side_effect=lambda *_a, **_k: driver_lines()), \
                patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'):
            # Exercise the unchanged old reader, including its two-frame guard:
            # equal exact captions previously selected the top logo.
            tour.probe.native_tap(self.out, 'Lumo', 'old-unscoped-reader', exact=True)
            self.assertEqual(adb.call_args.args,
                             ('shell', 'input', 'swipe', '175', '65', '175', '65', '120'))
            adb.reset_mock()
            self.capture_count = 0
            result = tour._select_stage_driver(self.out)
        self.assertEqual(self.capture_count, 2)
        adb.assert_called_once()
        self.assertEqual(adb.call_args.args,
                         ('shell', 'input', 'swipe', '175', '320', '175', '320', '120'))
        self.assertEqual(result['driver'], 'fox')
        journal = json.loads((self.out / result['readiness']).read_text())
        self.assertEqual(journal['status'], 'TOUCH_SENT')
        self.assertEqual(journal['final_observed_bounds'], [100, 300, 250, 340])
        self.assertEqual([frame['target']['stable_observed_target'] for frame in journal['frames']],
                         [False, True])
        for frame in journal['frames']:
            self.assertEqual(frame['source_sha256'],
                             hashlib.sha256((self.out / frame['source']).read_bytes()).hexdigest())

    def test_driver_requires_current_tabs_footer_and_one_exact_left_card(self):
        wrong_side = driver_lines()
        wrong_side[3]['bounds'] = [1500, 300, 1650, 340]
        ambiguous = driver_lines() + [{'text': 'Lumo', 'bounds': [100, 500, 250, 540]}]
        invalid = driver_lines()
        invalid[3]['bounds'] = [100, 300, float('nan'), 340]
        wrong_caption = driver_lines()
        wrong_caption[3]['text'] = 'Lumo Kart'
        cases = [
            (list_frame(), driver_lines()[:3] + driver_lines()[4:]),
            (list_frame(), wrong_side), (list_frame(), ambiguous),
            (list_frame(), invalid), (list_frame(), wrong_caption),
            (list_frame(), driver_lines()[2:]),
            (list_frame(), driver_lines()[:4]),
            (dict(list_frame(), pixels=[1080, 2400]), driver_lines()),
            (dict(list_frame(), acceptable_for_target_sampling=False), driver_lines()),
        ]
        for frame, lines in cases:
            with self.subTest(frame=frame, lines=lines), self.assertRaises(RuntimeError):
                evidence.stage_driver_target_observation(frame, lines)

    def test_ocr_variants_of_one_card_and_merged_tab_text_remain_one_observed_target(self):
        lines = driver_lines()
        lines[1:3] = [{'text': 'Rennen Fahrer Karts Strecken Tempo',
                       'bounds': [100, 160, 1800, 200]}]
        lines.append({'text': 'Lumo', 'bounds': [102, 301, 249, 340], 'variant': 'raw'})
        target = evidence.stage_driver_target_observation(list_frame(), lines)
        self.assertEqual(target['target']['bounds'], [100, 300, 250, 340])
        self.assertEqual(target['matching_observations'], 2)
        self.assertEqual((target['header_bottom'], target['footer_top']), (200, 950))

    def test_missing_wrong_or_ambiguous_driver_never_sends_a_touch(self):
        missing = driver_lines()[:3] + driver_lines()[4:]
        wrong = driver_lines()
        wrong[3]['bounds'] = [1500, 300, 1650, 340]
        ambiguous = driver_lines() + [{'text': 'Lumo', 'bounds': [100, 500, 250, 540]}]
        for lines in (missing, wrong, ambiguous):
            with self.subTest(lines=lines), \
                    patch.object(tour.probe, 'capture', side_effect=self.capture), \
                    patch.object(tour.probe, 'image_lines', return_value=lines), \
                    patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'), \
                    self.assertRaises(RuntimeError):
                tour._select_stage_driver(self.out)
            adb.assert_not_called()
            journal = json.loads((self.out / '21_stage_driver-select-original-lumo-surface-readiness.json').read_text())
            self.assertEqual(journal['status'], 'FAIL')

    def test_driver_touch_refuses_screenshot_replacement_after_ocr(self):
        def ocr(*_args, source_path, **_kwargs):
            if self.capture_count == 2:
                source_path.write_bytes(b'changed after native surface inspection')
            return driver_lines()
        with patch.object(tour.probe, 'capture', side_effect=self.capture), \
                patch.object(tour.probe, 'image_lines', side_effect=ocr), \
                patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'), \
                self.assertRaisesRegex(RuntimeError, 'screenshot changed'):
            tour._select_stage_driver(self.out)
        adb.assert_not_called()
        journal = json.loads((self.out / '21_stage_driver-select-original-lumo-surface-readiness.json').read_text())
        self.assertEqual(journal['status'], 'FAIL')

    def test_moved_driver_needs_two_new_stable_bounds(self):
        def ocr(*_args, **_kwargs):
            lines = driver_lines()
            if self.capture_count >= 2:
                lines[3]['bounds'] = [150, 300, 300, 340]
            return lines
        with patch.object(tour.probe, 'capture', side_effect=self.capture), \
                patch.object(tour.probe, 'image_lines', side_effect=ocr), \
                patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'):
            tour._select_stage_driver(self.out)
        self.assertEqual(self.capture_count, 3)
        adb.assert_called_once()
        self.assertEqual(adb.call_args.args,
                         ('shell', 'input', 'swipe', '225', '320', '225', '320', '120'))

    def test_unsettled_driver_target_times_out_without_touch(self):
        clock = iter(range(1000))
        def ocr(*_args, **_kwargs):
            lines = driver_lines()
            if self.capture_count % 2:
                lines[3]['bounds'] = [150, 300, 300, 340]
            return lines
        with patch.object(tour.probe, 'capture', side_effect=self.capture), \
                patch.object(tour.probe, 'image_lines', side_effect=ocr), \
                patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'), \
                patch.object(tour.time, 'monotonic', side_effect=lambda: next(clock)), \
                self.assertRaises(TimeoutError):
            tour._select_stage_driver(self.out, timeout=40)
        adb.assert_not_called()


class CupObservedLabelTests(unittest.TestCase):
    """Synthetic OCR for the actual 01cf063 landing's wide/narrow cup labels.

    kart_spatial_landing.gd retains mode=cup and changes its visible title to
    Pokal below 520dp; no screen width is used to guess a caption in the probe.
    """
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        self.capture_count = 0
        self.dimensions = (2400, 1080)

    def lines(self, caption='Grand Prix'):
        if self.dimensions == (640, 320):
            return [{'text': caption, 'bounds': [210, 100, 290, 125]},
                    {'text': 'Fahrer', 'bounds': [20, 190, 90, 210]},
                    {'text': 'Garage', 'bounds': [210, 190, 300, 210]}]
        return [{'text': caption, 'bounds': [100, 300, 350, 340]},
                {'text': 'Fahrer', 'bounds': [100, 800, 250, 840]},
                {'text': 'Garage', 'bounds': [400, 800, 550, 840]}]

    def capture(self, _out, tag, **_kwargs):
        self.capture_count += 1
        target = self.out / (tag + '.png')
        Image.new('RGB', self.dimensions, (30, 50, 70)).save(target)
        return {'file': target.name}

    def test_actual_wide_and_compact_cup_captions_both_require_two_observed_targets(self):
        for caption, dimensions in (('Grand Prix', (2400, 1080)), ('Pokal', (640, 320))):
            with self.subTest(caption=caption):
                self.dimensions = dimensions
                self.capture_count = 0
                with patch.object(tour.probe, 'capture', side_effect=self.capture), \
                        patch.object(tour.probe, 'image_lines', return_value=self.lines(caption)), \
                        patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'):
                    result = tour._stage_cup_text(self.out, 'current-cup', tap=True)
                self.assertEqual(result['caption'], caption)
                self.assertEqual(self.capture_count, 2)
                adb.assert_called_once()
                x0, y0, x1, y1 = self.lines(caption)[0]['bounds']
                x, y = str(round((x0 + x1) / 2)), str(round((y0 + y1) / 2))
                self.assertEqual(adb.call_args.args, ('shell', 'input', 'swipe', x, y, x, y, '120'))
                journal = json.loads((self.out / result['readiness']).read_text())
                self.assertEqual(journal['status'], 'TOUCH_SENT')
                self.assertEqual([frame['target']['stable_observed_target'] for frame in journal['frames']],
                                 [False, True])

    def test_missing_wrong_or_conflicting_cup_captions_never_trigger_a_fallback_touch(self):
        wrong_region = self.lines()
        wrong_region[0]['bounds'] = [100, 900, 350, 940]
        missing_navigation = self.lines()[:1]
        cases = [self.lines()[1:], self.lines('Zeit'), wrong_region, missing_navigation,
                 self.lines() + [{'text': 'Pokal', 'bounds': [100, 400, 250, 440]}],
                 self.lines() + [{'text': 'Grand Prix', 'bounds': [100, 400, 350, 440]}]]
        for lines in cases:
            with self.subTest(lines=lines), \
                    patch.object(tour.probe, 'capture', side_effect=self.capture), \
                    patch.object(tour.probe, 'image_lines', return_value=lines), \
                    patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'), \
                    self.assertRaises(RuntimeError):
                tour._stage_cup_text(self.out, 'bad-cup', tap=True)
            adb.assert_not_called()
            journal = json.loads((self.out / 'bad-cup-surface-readiness.json').read_text())
            self.assertEqual(journal['status'], 'FAIL')

    def test_caption_change_needs_two_new_observations_even_at_identical_bounds(self):
        captions = iter(['Grand Prix', 'Pokal', 'Pokal'])
        with patch.object(tour.probe, 'capture', side_effect=self.capture), \
                patch.object(tour.probe, 'image_lines', side_effect=lambda *_a, **_k: self.lines(next(captions))), \
                patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'):
            result = tour._stage_cup_text(self.out, 'changed-cup', tap=True)
        self.assertEqual(self.capture_count, 3)
        self.assertEqual(result['caption'], 'Pokal')
        adb.assert_called_once()
        journal = json.loads((self.out / result['readiness']).read_text())
        self.assertEqual([frame['target']['stable_observed_target'] for frame in journal['frames']],
                         [False, False, True])

    def test_landing_return_accepts_only_the_observed_caption_without_an_extra_touch(self):
        for caption in ('Grand Prix', 'Pokal'):
            with self.subTest(caption=caption), \
                    patch.object(tour.probe, 'capture', side_effect=self.capture), \
                    patch.object(tour.probe, 'image_lines', return_value=self.lines(caption)), \
                    patch.object(tour.base, 'adb') as adb:
                result = tour._stage_cup_text(self.out, 'restored-cup')
            self.assertEqual(result['caption'], caption)
            adb.assert_not_called()
            journal = json.loads((self.out / result['readiness']).read_text())
            self.assertEqual(journal['status'], 'OBSERVED')
            self.assertEqual(len(journal['frames']), 1)

    def test_replaced_cup_screenshot_prevents_the_touch(self):
        def ocr(*_args, source_path, **_kwargs):
            if self.capture_count == 2:
                source_path.write_bytes(b'changed after observation')
            return self.lines()
        with patch.object(tour.probe, 'capture', side_effect=self.capture), \
                patch.object(tour.probe, 'image_lines', side_effect=ocr), \
                patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'), \
                self.assertRaisesRegex(RuntimeError, 'cup screenshot changed'):
            tour._stage_cup_text(self.out, 'replaced-cup', tap=True)
        adb.assert_not_called()


class CurrentGarageProbeWiringTests(unittest.TestCase):
    def test_current_mandatory_pause_phase_requires_continue_and_a_second_real_pause(self):
        main = next(node for node in ast.parse(Path(tour.__file__).read_text()).body
                    if isinstance(node, ast.FunctionDef) and node.name == 'main')
        pause = next(node for node in ast.walk(main)
                     if isinstance(node, ast.FunctionDef) and node.name == 'pause')
        calls = [node for node in ast.walk(main) if isinstance(node, ast.Call)
                 and isinstance(node.func, ast.Name) and node.func.id == 'attempt']
        self.assertTrue(any(len(node.args) == 2 and isinstance(node.args[0], ast.Constant)
                            and node.args[0].value == 'pause-menu'
                            and isinstance(node.args[1], ast.Name) and node.args[1].id == 'pause'
                            for node in calls))
        self.assertIn('pause-menu', tour.HARD_STEPS)
        events = []
        def pause_race(out, _session, identity):
            events.append(('pause', out, identity))
            return {'state': race(), 'frozen_while_paused': {'result_id': identity}}
        def continue_race(out, _session, state):
            events.append(('continue', out, state['result_id']))
            return {'progress': {'result_id': state['result_id']}}
        out = Path('/synthetic-evidence')
        scope = {'out': out, 'session': SimpleNamespace(expected_kart='gecko_velo'),
                 'start_state': race(), '_pause_actual_race': pause_race,
                 '_continue_actual_race': continue_race, 'Path': Path}
        exec(compile(ast.Module(body=[pause], type_ignores=[]), str(tour.__file__), 'exec'), scope)
        report = scope['pause']()
        self.assertEqual(events, [('pause', out, 'new-race'),
                                  ('continue', out / '21_continue', 'new-race'),
                                  ('pause', out / '21_pause_after_continue', 'new-race')])
        self.assertIn('paused_after_continue', report)
        def failed_continue(*_args):
            raise RuntimeError('No physical progress after Continue')
        scope['_continue_actual_race'] = failed_continue
        with self.assertRaisesRegex(RuntimeError, 'No physical progress'):
            scope['pause']()

    def test_selection_needs_a_successful_observed_native_touch_receipt(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            def tap(path, label, tag, **kwargs):
                self.assertEqual(label, 'Gecko Velo')
                self.assertTrue(kwargs['exact'])
                self.assertTrue(callable(kwargs['missing_caption']))
                (path / (tag + '-surface-readiness.json')).write_text(json.dumps(
                    {'status': 'TOUCH_SENT', 'touch': [101, 202]}))
            with patch.object(tour.probe, 'native_tap', side_effect=tap):
                report = tour._select_stage_kart(out, 'gecko_velo')
            self.assertEqual(report['touch'], [101, 202])
            (out / '21_stage_select_gecko_velo-surface-readiness.json').write_text('{"status":"FAIL"}')
            with patch.object(tour.probe, 'native_tap'), self.assertRaisesRegex(RuntimeError, 'No observed'):
                tour._select_stage_kart(out, 'gecko_velo')

    def test_selection_wait_reads_old_and_new_snapshots_without_accepting_wrong_new_car(self):
        states = iter([race(result_id='old', selected_kart='comet', mode='race'),
                       race(countdown=3.5, elapsed=0), race()])
        def read(_tag, *, validate):
            self.assertFalse(validate)
            return next(states)
        session = SimpleNamespace(expected_mode='cup', expected_track='sonnenhafen', read=read)
        with patch.object(tour, 'godot_alive', return_value=True), \
                patch.object(tour.time, 'sleep'), patch.object(tour.time, 'monotonic', return_value=0):
            self.assertEqual(tour.wait_race_running(session, selected_kart='gecko_velo', previous_id='old'), race())
            session.read = lambda *_args, **_kwargs: race(selected_kart='comet')
            with self.assertRaisesRegex(RuntimeError, 'Actual race selected'):
                tour.wait_race_running(session, selected_kart='gecko_velo', previous_id='old')

    def test_raw_session_is_read_only_and_later_selection_or_identity_changes_fail(self):
        with tempfile.TemporaryDirectory() as folder:
            session = tour.RaceSession(Path(folder), expected_mode='cup', expected_kart='gecko_velo',
                                       expected_result_id='new-race')
            session.path = '/observed/game/kart_sonnenhafen_session.cfg'
            for state in (race(selected_kart='comet'), race(result_id='different')):
                with patch.object(tour.base, 'adb', return_value=config(state)) as adb, self.assertRaises(RuntimeError):
                    session.read('actual-read')
                self.assertEqual(adb.call_args.args, ('exec-out', 'cat', session.path))
                with patch.object(tour.base, 'adb', return_value=config(state)) as adb, \
                        patch.object(tour, 'godot_alive', return_value=True), self.assertRaises(RuntimeError):
                    tour.wait_race_running(session)
                self.assertEqual(adb.call_count, 1, 'A changed confirmed race must not be retried as loading')

    def test_previous_race_identity_comes_only_from_an_existing_read_only_save(self):
        with tempfile.TemporaryDirectory() as folder:
            with patch.object(tour.base, 'adb', return_value=''):
                self.assertIsNone(tour._previous_kart_race_id(Path(folder)))
            path = '/observed/kart_sonnenhafen_session.cfg'
            with patch.object(tour.base, 'adb', side_effect=[path, config(race(result_id='old'))]) as adb:
                self.assertEqual(tour._previous_kart_race_id(Path(folder)), 'old')
                self.assertEqual(adb.call_args.args, ('exec-out', 'cat', path))
            with patch.object(tour.base, 'adb', return_value=path + '\n/other' + path), self.assertRaises(RuntimeError):
                tour._previous_kart_race_id(Path(folder))

    def test_continue_requires_touch_then_physical_drive_and_retains_original_evidence(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            original = root / '21_race_after_gas_pulse_0-session.cfg'
            original.write_text('original first drive')
            session = tour.RaceSession(root, expected_mode='cup', expected_kart='gecko_velo',
                                       expected_result_id='new-race')
            session.path = '/observed/kart_sonnenhafen_session.cfg'
            order = []
            def touch(out, label, tag, **kwargs):
                self.assertEqual((label, kwargs), ('Weiterfahren', {'tap': True, 'exact': True}))
                order.append('touch')
                (out / (tag + '-surface-readiness.json')).write_text(
                    '{"status":"TOUCH_SENT","touch":[123,456]}')
            def drive(out, point, scoped, paused):
                self.assertEqual(order, ['touch'])
                self.assertEqual(scoped.out, root / 'continue')
                self.assertEqual((point, paused), ((321, 654), race()))
                order.append('physical-drive')
                return {'native_progress': {'distance_gain': 8, 'elapsed_gain': 2.5}}
            with patch.object(tour.probe, 'native_text', side_effect=touch), \
                    patch.object(tour, 'wait_race_hud', return_value={'capture': 'live-hud'}), \
                    patch.object(tour, 'find_gas', return_value=(321, 654)), \
                    patch.object(tour, 'drive_with_gas', side_effect=drive), \
                    patch.object(tour.base, 'adb', return_value=config(race(distance=28, elapsed=7.5))):
                result = tour._continue_actual_race(root / 'continue', session, race())
            self.assertEqual(order, ['touch', 'physical-drive'])
            self.assertEqual(result['progress']['result_id'], 'new-race')
            self.assertEqual(original.read_text(), 'original first drive')
            self.assertTrue((root / 'continue/21_after_continue-session.cfg').exists())

    def test_continue_does_not_pass_for_a_static_or_replaced_saved_race(self):
        for state in (race(), race(result_id='other', distance=28, elapsed=7.5)):
            with self.subTest(state=state), tempfile.TemporaryDirectory() as folder:
                out = Path(folder)
                session = tour.RaceSession(out, expected_mode='cup', expected_kart='gecko_velo',
                                           expected_result_id='new-race')
                session.path = '/observed/kart_sonnenhafen_session.cfg'
                def touch(path, _label, tag, **_kwargs):
                    (path / (tag + '-surface-readiness.json')).write_text(
                        '{"status":"TOUCH_SENT","touch":[1,2]}')
                with patch.object(tour.probe, 'native_text', side_effect=touch), \
                        patch.object(tour, 'wait_race_hud', return_value={'capture': 'live'}), \
                        patch.object(tour, 'find_gas', return_value=(1, 2)), \
                        patch.object(tour, 'drive_with_gas', return_value={}), \
                        patch.object(tour.base, 'adb', return_value=config(state)), \
                        self.assertRaises(RuntimeError):
                    tour._continue_actual_race(out / 'continue', session, race())
                self.assertFalse((out / 'continue/21_continue-result.json').exists())


if __name__ == '__main__':
    unittest.main()
