"""New reconstruction guards; synthetic PNGs are unit fixtures, not gameplay.

The RED/GREEN regression executes the actual Fullrace preparation function and
the actual creative native_tap. No captions, coordinates or state enter an app.
"""
from __future__ import annotations

import ast
import copy
import hashlib
import importlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
CREATIVE_PATH = ROOT / '.github/probes/creative_android_probe.py'
KART_PATH = ROOT / '.github/probes/kart_complete_android_probe.py'


def load_creative():
    spec = importlib.util.spec_from_file_location('gas_recovery_creative', CREATIVE_PATH)
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(ROOT / 'scripts/probes'))
    base = importlib.import_module('pr207_android_smoke')
    adapter = SimpleNamespace(live_nodes=lambda *_: [], live_tap_label=lambda *_: None)
    with patch.dict(sys.modules, {'pr207_android_ui_probe': adapter}), \
            patch.object(base, 'ui_nodes'), patch.object(base, 'tap_label'):
        spec.loader.exec_module(module)
    return module


def load_kart():
    spec = importlib.util.spec_from_file_location('gas_recovery_kart', KART_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def fullrace_tap_function(creative, out, clock):
    """Compile the unchanged nested function body from its real source file."""
    module = ast.parse(KART_PATH.read_text())
    node = next(node for node in ast.walk(module)
                if isinstance(node, ast.FunctionDef) and node.name == 'tap_native')
    kart = load_kart()
    def write_json(name, value):
        (out / name).write_text(json.dumps(value, indent=2) + '\n')
    scope = {'creative': creative, 'out': out, 'time': clock,
             'base': creative.base, 'write_json': write_json,
             'scroll_observation': kart.scroll_observation,
             'stable_scroll_observation': kart.stable_scroll_observation}
    exec(compile(ast.Module(body=[copy.deepcopy(node)], type_ignores=[]),
                 str(KART_PATH), 'exec'), scope)
    return scope['tap_native']


def modal_rows():
    return [{'text': 'Eine kleine Pause', 'bounds': [300, 120, 490, 145]},
            {'text': 'Grafik: Hoch', 'bounds': [330, 300, 470, 330]},
            {'text': 'Zur Spieleauswahl', 'bounds': [210, 400, 360, 425]},
            {'text': 'Zum Lernen', 'bounds': [440, 400, 580, 425]},
            {'text': 'RUNDE 1 / 2', 'bounds': [15, 20, 190, 40]}]


class GasCaptionRecoveryRegressionTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-gas-recovery-unit-')
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)

    def test_actual_fullrace_initial_gas_match_then_lost_caption_recovers_before_exact_touch(self):
        """Identical test must be RED on f6, GREEN on the reconstructed change."""
        creative = load_creative()
        now = [0.0]
        captures, missing_reads, observed_inputs = [], [], []
        gas = 'Gas: GAS-Taste halten'
        final_bounds = [320, 250, 480, 280]
        swipes = [0]

        def capture(out, tag, timeout=None):
            self.assertGreater(timeout, 0)
            now[0] += .2
            source = out / (tag + '.png')
            image = Image.new('RGB', (800, 480), (8, 27, 67))
            image.putpixel((0, 0), (len(captures) % 200 + 20, 90, 120))
            image.save(source)
            captures.append(tag)
            return {'file': source.name}

        def image_lines(out, tag, wanted, *, source_path, timeout, exact):
            self.assertTrue(exact)
            self.assertEqual(wanted, creative.normalized(gas))
            self.assertGreater(timeout, 0)
            now[0] += .1
            if '-stable-action-' not in tag:
                return [{'text': gas, 'bounds': [330, 350, 490, 380]}, *modal_rows()]
            if not swipes[0]:
                missing_reads.append(tag)
                return modal_rows()
            return [{'text': gas, 'bounds': final_bounds}, *modal_rows()]

        def adb(*arguments, **kwargs):
            observed_inputs.append((arguments, kwargs))
            if arguments[-1] == '450':
                swipes[0] += 1

        clock = SimpleNamespace(monotonic=lambda: now[0],
                                sleep=lambda seconds: now.__setitem__(0, now[0] + seconds))
        with patch.object(creative, 'capture', capture), \
                patch.object(creative, 'image_lines', image_lines), \
                patch.object(creative.base, 'adb', adb), \
                patch.object(creative.time, 'monotonic', clock.monotonic), \
                patch.object(creative.time, 'sleep', clock.sleep):
            fullrace_tap_function(creative, self.out, clock)(gas, 'gas-recovery', scroll='down')
        self.assertEqual(swipes[0], 1)
        self.assertGreaterEqual(len(missing_reads), 2)
        self.assertEqual(len(observed_inputs), 2)
        self.assertEqual(observed_inputs[0][0], ('shell', 'input', 'swipe', '400', '132', '400', '315', '450'))
        self.assertEqual(observed_inputs[1][0], ('shell', 'input', 'swipe', '400', '265', '400', '265', '120'))
        self.assertLess(now[0], 120)
        journal = json.loads((self.out / 'gas-recovery-stable-action-surface-readiness.json').read_text())
        self.assertEqual(journal['status'], 'TOUCH_SENT')
        self.assertEqual(journal['final_observed_bounds'], final_bounds)
        self.assertEqual(journal['timeout_seconds'], 120)


class GasCaptionCallbackGuards(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-gas-callback-unit-')
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.now = 0.0
        self.inputs = []
        self.kart = load_kart()
        self.creative = load_creative()
        self.factory = importlib.import_module('caption_scroll_recovery').make_gas_caption_recovery
        self.recovery = self.make_recovery()

    def make_recovery(self, **overrides):
        options = dict(scroll='down', context='pause',
                       scroll_observation=self.kart.scroll_observation,
                       stable_scroll_observation=self.kart.stable_scroll_observation,
                       digest=self.creative.digest, swipe=lambda *args, **kwargs: self.inputs.append((args, kwargs)),
                       clock=lambda: self.now)
        options.update(overrides)
        return self.factory('Gas: GAS-Taste halten', **options)

    def frame(self, number, *, size=(800, 480), partial=False):
        source = self.out / f'frame-{number}.png'
        image = Image.new('RGB', size, (8, 27, 67))
        image.putpixel((0, 0), (20 + number, 80, 120))
        if partial:
            image.paste('black', (size[0] // 2, 0, size[0], size[1]))
        image.save(source)
        frame = self.creative.inspect_surface(source)
        frame['captured_after_seconds'] = float(number)
        return frame, source

    def call(self, number, *, previous=None, rows=None, recovery=None, deadline=30, **frame_options):
        frame, source = self.frame(number, **frame_options)
        result = (recovery or self.recovery)(frame, modal_rows() if rows is None else rows,
                                           source, deadline=deadline, previous_missing_frame=previous)
        return frame, source, result

    def test_factory_only_enables_exact_gas_pause_and_original_down_scroll(self):
        options = dict(scroll='down', context='pause', scroll_observation=self.kart.scroll_observation,
                       stable_scroll_observation=self.kart.stable_scroll_observation,
                       digest=self.creative.digest, swipe=None)
        for label in ('GAS', 'Gas: automatisch', 'Rucksack', 'Neues Puzzle beginnen',
                      'Gas: GAS-Taste halten ', 'gas: GAS-Taste halten', 'Weiterfahren'):
            with self.subTest(label=label):
                self.assertIsNone(self.factory(label, **options))
        for scroll, context in (('up', 'pause'), (None, 'pause'), ('down', 'finished'), ('down', 'garage')):
            with self.subTest(scroll=scroll, context=context):
                self.assertIsNone(self.make_recovery(scroll=scroll, context=context))

    def test_first_full_missing_frame_cannot_authorize_swipe(self):
        _, _, evidence = self.call(1)
        self.assertEqual(evidence['status'], 'WAITING_FOR_SECOND_FRESH_MODAL_FRAME')
        self.assertEqual(self.inputs, [])

    def test_two_distinct_fresh_full_frames_use_observed_upward_recovery(self):
        first, _, _ = self.call(1)
        _, _, evidence = self.call(2, previous=first)
        self.assertEqual(evidence['status'], 'SWIPE_SENT')
        self.assertEqual(evidence['direction'], 'up')
        self.assertEqual(self.inputs[0][0], ('shell', 'input', 'swipe', '400', '132', '400', '315', '450'))
        self.assertEqual(evidence['current']['observation']['footer_bounds'],
                         [[210, 400, 360, 425], [440, 400, 580, 425]])

    def test_shifted_modal_requires_new_pair(self):
        first, _, _ = self.call(1)
        rows = copy.deepcopy(modal_rows())
        for row in rows:
            row['bounds'] = [value + 25 if index % 2 == 0 else value
                             for index, value in enumerate(row['bounds'])]
        second, _, evidence = self.call(2, previous=first, rows=rows)
        self.assertFalse(evidence['current']['stable'])
        self.assertEqual(self.inputs, [])
        _, _, evidence = self.call(3, previous=second, rows=rows)
        self.assertEqual(evidence['status'], 'SWIPE_SENT')
        self.assertEqual(self.inputs[0][0][3], '425')

    def test_resized_surface_cannot_reuse_old_modal_pair(self):
        first, _, _ = self.call(1)
        _, _, evidence = self.call(2, previous=first, size=(900, 480))
        self.assertFalse(evidence['current']['stable'])
        self.assertEqual(self.inputs, [])

    def test_reused_source_name_is_stale_even_if_pixels_are_complete(self):
        first, source, _ = self.call(1)
        repeated = dict(first, captured_after_seconds=2.0)
        evidence = self.recovery(repeated, modal_rows(), source, deadline=30, previous_missing_frame=first)
        self.assertEqual(evidence['status'], 'STALE_FRAME_REJECTED')
        self.assertEqual(self.inputs, [])

    def test_equal_or_older_capture_time_is_not_fresh(self):
        for captured in (1.0, .5):
            with self.subTest(captured=captured):
                recovery = self.make_recovery()
                first, _, _ = self.call(1, recovery=recovery)
                second, source = self.frame(2)
                second['captured_after_seconds'] = captured
                evidence = recovery(second, modal_rows(), source, deadline=30, previous_missing_frame=first)
                self.assertEqual(evidence['status'], 'STALE_FRAME_REJECTED')
                self.assertEqual(self.inputs, [])

    def test_intervening_native_reset_cannot_reuse_prior_missing_frame(self):
        self.call(1)
        _, _, evidence = self.call(2, previous=None)
        self.assertFalse(evidence['current']['stable'])
        self.assertEqual(self.inputs, [])

    def test_partial_frame_resets_callback_pair_without_input(self):
        first, _, _ = self.call(1)
        partial, _, evidence = self.call(2, previous=first, partial=True)
        self.assertEqual(evidence['status'], 'SURFACE_REJECTED')
        _, _, evidence = self.call(3, previous=partial)
        self.assertFalse(evidence['current']['stable'])
        self.assertEqual(self.inputs, [])

    def test_frame_source_and_finite_capture_time_are_required(self):
        for key, bad in (('source', 'old.png'), ('captured_after_seconds', None),
                         ('captured_after_seconds', float('nan')), ('captured_after_seconds', True)):
            with self.subTest(key=key, bad=bad):
                frame, source = self.frame(1)
                frame[key] = bad
                with self.assertRaises(RuntimeError):
                    self.recovery(frame, modal_rows(), source, deadline=30)
        self.assertEqual(self.inputs, [])

    def test_changed_current_source_bytes_abort_before_swipe(self):
        first, _, _ = self.call(1)
        second, source = self.frame(2)
        source.write_bytes(source.read_bytes() + b'changed')
        with self.assertRaisesRegex(RuntimeError, 'Current Gas recovery screenshot changed'):
            self.recovery(second, modal_rows(), source, deadline=30, previous_missing_frame=first)
        self.assertEqual(self.inputs, [])

    def test_changed_previous_source_bytes_abort_before_swipe(self):
        first, source, _ = self.call(1)
        source.write_bytes(source.read_bytes() + b'changed')
        second, current = self.frame(2)
        with self.assertRaisesRegex(RuntimeError, 'Previous Gas recovery screenshot changed'):
            self.recovery(second, modal_rows(), current, deadline=30, previous_missing_frame=first)
        self.assertEqual(self.inputs, [])

    def test_current_digest_is_checked_after_previous_digest_immediately_before_input(self):
        first, previous_source, _ = self.call(1)
        second, current_source = self.frame(2)
        original = self.recovery.digest
        calls = []
        def digest(source):
            calls.append(source)
            value = original(source)
            if source == previous_source:
                current_source.write_bytes(current_source.read_bytes() + b'changed-during-previous-read')
            return value
        self.recovery.digest = digest
        with self.assertRaisesRegex(RuntimeError, 'Current Gas recovery screenshot changed'):
            self.recovery(second, modal_rows(), current_source, deadline=30, previous_missing_frame=first)
        self.assertEqual(calls, [previous_source, current_source])
        self.assertEqual(self.inputs, [])

    def test_missing_or_ambiguous_footer_aborts_without_scroll(self):
        variants = [modal_rows()[:2], modal_rows() + [
            {'text': 'Zum Lernen', 'bounds': [600, 400, 730, 425]}]]
        for rows in variants:
            with self.subTest(rows=rows), self.assertRaisesRegex(RuntimeError, 'footer'):
                self.call(1, rows=rows, recovery=self.make_recovery())
        self.assertEqual(self.inputs, [])

    def test_disordered_footer_aborts_without_scroll(self):
        rows = modal_rows()
        rows[3]['bounds'] = [190, 400, 300, 425]
        with self.assertRaisesRegex(RuntimeError, 'ordered navigation row'):
            self.call(1, rows=rows)
        self.assertEqual(self.inputs, [])

    def test_outside_footer_content_cannot_supply_recovery_gesture(self):
        rows = modal_rows()
        rows[0]['bounds'] = [10, 120, 190, 145]
        rows[1]['bounds'] = [330, 430, 470, 455]
        with self.assertRaisesRegex(RuntimeError, 'safe scrolling gesture'):
            self.call(1, rows=rows)
        self.assertEqual(self.inputs, [])

    def test_only_hud_or_world_captions_never_supply_recovery(self):
        with self.assertRaises(RuntimeError):
            self.call(1, rows=[{'text': 'GAS', 'bounds': [10, 20, 100, 50]},
                               {'text': 'Sonnenhafen', 'bounds': [250, 20, 400, 50]}])
        self.assertEqual(self.inputs, [])

    def test_clipped_footer_fails_current_screenshot_bounds(self):
        rows = modal_rows()
        rows[3]['bounds'] = [440, 400, 850, 425]
        with self.assertRaisesRegex(RuntimeError, 'exceeds the current screenshot'):
            self.call(1, rows=rows)
        self.assertEqual(self.inputs, [])

    def test_invalid_caption_bounds_are_not_input_coordinates(self):
        rows = modal_rows()
        rows[1]['bounds'][0] = True
        with self.assertRaisesRegex(RuntimeError, 'Invalid observed modal caption bounds'):
            self.call(1, rows=rows)
        self.assertEqual(self.inputs, [])

    def test_existing_deadline_exhaustion_prevents_all_input(self):
        self.now = 30
        with self.assertRaises(TimeoutError):
            self.call(1, deadline=30)
        self.assertEqual(self.inputs, [])

    def test_nonfinite_or_boolean_deadline_cannot_create_a_new_budget(self):
        for deadline in (float('inf'), float('nan'), True, None):
            with self.subTest(deadline=deadline), self.assertRaises(ValueError):
                self.call(1, deadline=deadline)
        self.assertEqual(self.inputs, [])

    def test_expiry_during_source_verification_prevents_swipe(self):
        first, _, _ = self.call(1)
        original = self.recovery.digest
        def digest(source):
            self.now = 30
            return original(source)
        self.recovery.digest = digest
        with self.assertRaises(TimeoutError):
            self.call(2, previous=first, deadline=30)
        self.assertEqual(self.inputs, [])

    def test_swipe_timeout_uses_only_remaining_native_budget(self):
        first, _, _ = self.call(1)
        self.now = 28
        self.call(2, previous=first, deadline=30)
        self.assertEqual(self.inputs[0][1]['timeout'], 2)

    def test_maximum_two_recovery_swipes_and_no_reused_pair_after_input(self):
        first, _, _ = self.call(1)
        second, _, evidence = self.call(2, previous=first)
        self.assertEqual(evidence['swipes_sent'], 1)
        third, _, evidence = self.call(3, previous=second)
        self.assertFalse(evidence['current']['stable'])
        _, _, evidence = self.call(4, previous=third)
        self.assertEqual(evidence['swipes_sent'], 2)
        _, _, evidence = self.call(5)
        self.assertEqual(evidence['status'], 'RECOVERY_SWIPE_LIMIT_REACHED')
        self.assertEqual(len(self.inputs), 2)


class NativeMissingCaptionHookGuards(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-native-missing-unit-')
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.creative = load_creative()
        self.now = 0.0
        self.captures = 0

    def sleep(self, seconds):
        self.now += seconds

    def capture(self, out, tag, timeout=None, *, partial=False):
        self.captures += 1
        source = out / (tag + '.png')
        image = Image.new('RGB', (800, 480), (8, 27, 67))
        if partial:
            image.paste('black', (400, 0, 800, 480))
        image.save(source)
        return {'file': source.name}

    def invoke(self, *, timeout=6, label='Gas: GAS-Taste halten', rows=None, hook=None,
               capture=None, exact=True):
        with patch.object(self.creative, 'capture', capture or self.capture), \
                patch.object(self.creative, 'image_lines', return_value=[] if rows is None else rows) as ocr, \
                patch.object(self.creative.base, 'adb') as adb, \
                patch.object(self.creative.time, 'monotonic', side_effect=lambda: self.now), \
                patch.object(self.creative.time, 'sleep', side_effect=self.sleep):
            error = None
            try:
                self.creative.native_tap(self.out, label, 'hook', timeout=timeout, exact=exact,
                                         missing_caption=hook)
            except Exception as caught:
                error = caught
        return error, ocr, adb

    def test_default_missing_caption_remains_bounded_and_never_clicks(self):
        error, _, adb = self.invoke()
        self.assertIsInstance(error, TimeoutError)
        self.assertEqual(self.now, 6)
        adb.assert_not_called()

    def test_callback_is_never_called_for_partial_surface_or_without_ready_ocr(self):
        calls = []
        def hook(*args, **kwargs):
            calls.append((args, kwargs))
            return {'status': 'WAITING'}
        error, ocr, adb = self.invoke(hook=hook, capture=lambda *args, **kwargs:
                                      self.capture(*args, **kwargs, partial=True))
        self.assertIsInstance(error, TimeoutError)
        self.assertEqual(calls, [])
        ocr.assert_not_called()
        adb.assert_not_called()

    def test_callback_only_sees_empty_exact_target_and_same_deadline(self):
        calls = []
        def hook(frame, lines, source, **kwargs):
            calls.append((frame, lines, source, kwargs))
            return {'status': 'WAITING'}
        error, _, adb = self.invoke(hook=hook, rows=[
            {'text': 'Gas: automatisch', 'bounds': [300, 200, 500, 225]}])
        self.assertIsInstance(error, TimeoutError)
        self.assertGreaterEqual(len(calls), 2)
        self.assertTrue(all(call[3]['deadline'] == 6 for call in calls))
        self.assertIsNone(calls[0][3]['previous_missing_frame'])
        self.assertEqual(calls[1][3]['previous_missing_frame']['source'], calls[0][0]['source'])
        adb.assert_not_called()

    def test_observed_exact_target_bypasses_callback_and_keeps_original_two_frame_touch(self):
        def hook(*args, **kwargs):
            self.fail('Hook must not run while the exact requested caption is observed')
        error, ocr, adb = self.invoke(hook=hook, rows=[
            {'text': 'Gas: GAS-Taste halten', 'bounds': [300, 200, 500, 225]}])
        self.assertIsNone(error)
        self.assertEqual(ocr.call_count, 2)
        adb.assert_called_once()
        self.assertEqual(adb.call_args.args[3:8], ('400', '212', '400', '212', '120'))

    def test_partial_interruption_resets_the_previous_missing_frame_chain(self):
        frames = iter((False, True, False))
        def capture(*args, **kwargs):
            return self.capture(*args, **kwargs, partial=next(frames))
        calls = []
        def hook(frame, lines, source, **kwargs):
            calls.append(kwargs['previous_missing_frame'])
            return {'status': 'WAITING'}
        error, _, adb = self.invoke(timeout=4, capture=capture, hook=hook)
        self.assertIsInstance(error, TimeoutError)
        self.assertEqual(calls, [None, None])
        adb.assert_not_called()

    def test_late_ocr_result_does_not_invoke_recovery_or_send_input(self):
        calls = []
        def image_lines(*args, **kwargs):
            self.now = 10
            return []
        with patch.object(self.creative, 'capture', self.capture), \
                patch.object(self.creative, 'image_lines', image_lines), \
                patch.object(self.creative.base, 'adb') as adb, \
                patch.object(self.creative.time, 'monotonic', side_effect=lambda: self.now), \
                patch.object(self.creative.time, 'sleep', side_effect=self.sleep):
            with self.assertRaises(TimeoutError):
                self.creative.native_tap(self.out, 'Gas: GAS-Taste halten', 'late', timeout=6,
                                         exact=True, missing_caption=lambda *args, **kwargs: calls.append(args))
        self.assertEqual(calls, [])
        adb.assert_not_called()

    def test_fullrace_gas_uses_minimum_of_120_and_outer_remaining_deadline(self):
        clock = SimpleNamespace(monotonic=lambda: self.now, sleep=self.sleep)
        def image_lines(*args, **kwargs):
            self.now = 100
            return [{'text': 'Gas: GAS-Taste halten', 'bounds': [300, 200, 500, 225]}]
        with patch.object(self.creative, 'capture', self.capture), \
                patch.object(self.creative, 'image_lines', image_lines), \
                patch.object(self.creative, 'native_tap') as tap, \
                patch.object(self.creative, 'native_text') as text:
            fullrace_tap_function(self.creative, self.out, clock)(
                'Gas: GAS-Taste halten', 'bounded', scroll='down')
        text.assert_not_called()
        tap.assert_called_once()
        self.assertEqual(tap.call_args.kwargs['timeout'], 80)
        self.assertTrue(tap.call_args.kwargs['exact'])
        self.assertIsNotNone(tap.call_args.kwargs['missing_caption'])

    def test_fullrace_other_labels_and_contexts_keep_original_native_text_path(self):
        cases = [('Rucksack', 'down', 'pause'), ('Neues Puzzle beginnen', 'down', 'pause'),
                 ('Weiterfahren', 'up', 'pause'), ('Gas: GAS-Taste halten', 'down', 'finished'),
                 ('Gas: GAS-Taste halten', None, 'pause'), ('Gas: automatisch', 'down', 'pause')]
        for label, scroll, context in cases:
            with self.subTest(label=label, scroll=scroll, context=context):
                clock = SimpleNamespace(monotonic=lambda: self.now, sleep=self.sleep)
                with patch.object(self.creative, 'capture', self.capture), \
                        patch.object(self.creative, 'image_lines', return_value=[
                            {'text': label, 'bounds': [300, 200, 500, 225]}]), \
                        patch.object(self.creative, 'native_tap') as tap, \
                        patch.object(self.creative, 'native_text') as text:
                    fullrace_tap_function(self.creative, self.out, clock)(
                        label, 'other', scroll=scroll, context=context)
                tap.assert_not_called()
                text.assert_called_once_with(self.out, label, 'other-stable-action', tap=True, exact=True)


if __name__ == '__main__':
    unittest.main(verbosity=2)
