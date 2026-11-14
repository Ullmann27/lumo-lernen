"""UI-only Kart preview countercheck and preservation of the078 race gates.

Only screenshot/OCR/ADB/clock boundaries are doubled. These tests run the real
new controller functions and the unchanged persisted-race predicate, without
Flutter, an emulator, Tesseract or an image library. They are not Android proof.
"""
from __future__ import annotations

import ast
import copy
import csv
import hashlib
import inspect
import json
import math
import os
from pathlib import Path
import re
import tempfile
from types import ModuleType, SimpleNamespace
import unittest
import unicodedata
from unittest.mock import Mock, patch


ROOT = Path(__file__).resolve().parents[3]
TOUR = Path(os.environ.get('LUMO_KART_TOUR_SOURCE',
                          ROOT / '.github/probes/modernization_android_tour.py'))
EVIDENCE = Path(os.environ.get('LUMO_KART_EVIDENCE_SOURCE',
                              ROOT / 'tools/android_qa/kart_tour_evidence.py'))
HELPER = Path(os.environ.get('LUMO_KART_CREATIVE_SOURCE',
                           ROOT / '.github/probes/creative_android_probe.py'))
SURFACE = Path(os.environ.get('LUMO_KART_SURFACE_SOURCE',
                            ROOT / 'tools/android_qa/native_surface_readiness.py'))
CAPTION = 'Tippen zum Überspringen'


def definitions(path: Path, namespace: dict) -> ModuleType:
    """Load actual functions without optional device-driver import side effects."""
    tree = ast.parse(path.read_text())
    nodes = [ast.ImportFrom(module='__future__',
                            names=[ast.alias(name='annotations')], level=0)]
    nodes.extend(node for node in tree.body
                 if isinstance(node, (ast.FunctionDef, ast.ClassDef)))
    module = ModuleType('real_probe_functions')
    module.__dict__.update(namespace)
    exec(compile(ast.fix_missing_locations(ast.Module(body=nodes, type_ignores=[])),
                 str(path), 'exec'), module.__dict__)
    return module


class Clock:
    def __init__(self):
        self.now = 0.0

    def monotonic(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


class PreviewSkipTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.out = Path(folder.name)
        self.clock = Clock()
        self.caption_lines = [{'text': CAPTION, 'bounds': [920, 240, 1480, 282]}]
        self.read_cost = 1.0
        self.touch_cost = 2.0
        self.capture_cost = 1.0
        self.cue_mutation = False
        self.touch_status = 'TOUCH_SENT'
        self.touch_frames = 2
        self.adb_calls = []
        self.base = SimpleNamespace(adb=Mock(side_effect=self.adb),
                                    foreground=Mock(return_value='app/LumoGameActivity'))
        helper = definitions(HELPER, {'re': re, 'unicodedata': unicodedata,
                                     'time': self.clock})
        self.probe = SimpleNamespace(
            digest=lambda p: hashlib.sha256(p.read_bytes()).hexdigest(),
            normalized=helper.normalized,
            image_lines=Mock(side_effect=self.ocr),
            native_tap=Mock(side_effect=self.touch),
            capture=Mock(side_effect=self.capture),
        )
        evidence = definitions(EVIDENCE, {'math': math})
        evidence.garage_replaced = Mock(return_value={'changed_fraction': .91})
        evidence.rendered_race_frame = Mock(return_value={'size': [2400, 1080]})
        self.module = definitions(TOUR, {
            'Path': Path, 'json': json, 'os': os, 're': re, 'time': self.clock,
            'probe': self.probe, 'base': self.base, 'evidence': evidence,
        })
        self.module.godot_alive = Mock(return_value=True)
        self.module._screencap = Mock(return_value=b'synthetic raster transport boundary')
        self.module._read_garage_footer = Mock(return_value=(1791, 916))
        self.source = self.out / '21_lumo_kart_real_race.png'
        self.source.write_bytes(b'synthetic raster transport boundary')
        environment = patch.dict(os.environ, {'LUMO_NATIVE_STAGE_MENU': '0'})
        environment.start()
        self.addCleanup(environment.stop)

    def adb(self, *args, **kwargs):
        self.adb_calls.append((args, kwargs))
        if args[:1] == ('logcat',):
            return '[Kart] race_world_ready: sonnenhafen mode=cup'
        return ''

    def ocr(self, out, tag, wanted, *, source_path, timeout, exact):
        self.assertEqual(wanted, self.probe.normalized(CAPTION))
        self.assertTrue(exact)
        self.clock.sleep(self.read_cost)
        if self.cue_mutation:
            source_path.write_bytes(b'changed after OCR')
        return copy.deepcopy(self.caption_lines)

    def touch(self, out, label, tag, *, timeout, exact, orientation):
        # Model only the unchanged native_tap transport boundary. Its actual
        # production implementation performs the screenshot/geometry checks.
        self.assertEqual(label, CAPTION)
        self.assertIs(exact, True)
        self.assertEqual(orientation, 'landscape')
        self.clock.sleep(self.touch_cost)
        frames = []
        has_caption = any(self.probe.normalized(row['text']) ==
                          self.probe.normalized(label) for row in self.caption_lines)
        for index in range(self.touch_frames):
            path = out / f'{tag}-{index}.png'
            path.write_bytes(f'synthetic current raster{index}'.encode())
            digest = self.probe.digest(path)
            frames.append({
                'source': path.name, 'source_sha256': digest,
                'source_bytes': path.stat().st_size, 'pixels': [2400, 1080],
                'acceptable_for_target_sampling': True,
                'target': {'surface_sha256': digest, 'pixels': [2400, 1080],
                           'bounds': [920, 240, 1480, 282],
                           'target_geometry_valid': True,
                           'stable_observed_target': index > 0},
            })
            (out / (path.stem + '-ocr.json')).write_text(
                json.dumps(self.caption_lines, ensure_ascii=False))
            if not has_caption:
                frames[-1].pop('target')
        readiness = {'status': self.touch_status if has_caption else 'FAIL', 'label': label,
                     'exact_caption_required': exact, 'orientation_policy': orientation,
                     'timeout_seconds': timeout, 'frames': frames,
                     'touch': [1200, 261], 'final_observed_bounds': [920, 240, 1480, 282]}
        (out / (tag + '-surface-readiness.json')).write_text(json.dumps(readiness))
        if not has_caption:
            raise TimeoutError('Current native surface/target did not settle before touch')
        if self.cue_mutation:
            path.write_bytes(b'changed after guarded OCR')
        self.base.adb('shell', 'input', 'swipe', '1200', '261',
                      '1200', '261', '120', timeout=min(15, timeout))

    def capture(self, out, name, *, timeout):
        self.clock.sleep(self.capture_cost)
        path = out / (name + '.png')
        path.write_bytes(b'synthetic after-capture transport boundary')
        return {'file': path.name, 'sha256': self.probe.digest(path),
                'width': 2400, 'height': 1080}

    def skip(self, deadline=55):
        return self.module._skip_observed_kart_preview(self.out, self.source, deadline)

    def journal(self):
        return json.loads((self.out / '21_kart_preview_skip.json').read_text())

    def test_opt_in_skips_actual_observed_cue_before_reporting_start(self):
        # The identical assertion runs against078 for the red control. It calls
        # the available original start interface, so red means missing action,
        # not merely an unsupported newly introduced keyword.
        kwargs = ({'skip_preview': True}
                  if 'skip_preview' in inspect.signature(
                      self.module._start_actual_embedded_race).parameters else {})
        report = self.module._start_actual_embedded_race(self.out, **kwargs)
        self.probe.native_tap.assert_called_once()
        self.assertEqual(report['expected_mode'], 'cup')
        self.assertEqual(report['expected_track'], 'sonnenhafen')
        skip = report['preview_skip']
        self.assertEqual(skip['status'], 'TOUCH_SENT')
        self.assertEqual(skip['countercheck_scope'], 'OBSERVED_UI_TOUCH_ONLY')
        self.assertEqual(len(skip['readiness']['frames']), 2)
        self.assertEqual(skip['touch'], [1200, 261])
        self.assertEqual(skip['cue'], skip['cue_witnesses'][-1])
        self.assertNotEqual(skip['cue']['source'], self.source.name)
        self.assertEqual(skip, self.journal())
        touches = json.loads((self.out / '21_kart_real_touches.json').read_text())
        self.assertEqual([row['step'] for row in touches], ['premium-start', 'preview-skip'])
        self.assertEqual(touches[-1]['tap'], [1200, 261])
        self.assertEqual([call[0][:3] for call in self.adb_calls if call[0][:1] == ('shell',)],
                         [('shell', 'input', 'tap'), ('shell', 'input', 'swipe')])

    def test_legacy_default_sends_no_added_touch_or_ocr(self):
        report = self.module._start_actual_embedded_race(self.out)
        self.assertNotIn('preview_skip', report)
        self.probe.native_tap.assert_not_called()
        self.probe.image_lines.assert_not_called()
        self.assertEqual(len(report['touches']), 1)

    def test_missing_cue_is_explicitly_not_isolated_and_sends_no_touch(self):
        self.caption_lines = []
        with self.assertRaises(TimeoutError):
            self.skip()
        report = self.journal()
        self.assertEqual(report['status'], 'FAIL')
        self.assertEqual(report['countercheck_scope'], 'NOT_ISOLATED')
        self.assertEqual(report['readiness']['status'], 'FAIL')
        self.assertFalse(self.adb_calls)

    def test_partial_or_different_caption_never_authorizes_skip(self):
        for caption in ('Überspringen', 'Nicht tippen zum Überspringen', 'Tippen zum Starten'):
            with self.subTest(caption=caption):
                self.caption_lines = [{'text': caption, 'bounds': [1, 2, 3, 4]}]
                with self.assertRaises(TimeoutError):
                    self.skip()
                self.assertEqual(self.journal()['countercheck_scope'], 'NOT_ISOLATED')
        self.assertFalse(self.adb_calls)

    def test_existing55s_deadline_is_not_restarted_after_slow_race_capture(self):
        count = 0

        def slow_current_capture():
            nonlocal count
            count += 1
            if count == 2:
                self.clock.sleep(54)
            return b'synthetic raster transport boundary'

        self.module._screencap = slow_current_capture
        self.touch_cost = 2
        with self.assertRaisesRegex(TimeoutError, 'Original55s'):
            self.module._start_actual_embedded_race(self.out, skip_preview=True)
        self.assertEqual(self.journal()['initial_remaining_seconds'], 1)
        self.probe.native_tap.assert_called_once_with(
            self.out, CAPTION, '21_kart_preview_skip_touch',
            timeout=1, exact=True, orientation='landscape')

    def test_remaining_budget_is_passed_to_unmodified_two_frame_touch_helper(self):
        self.clock.now = 12
        report = self.skip(deadline=55)
        self.assertEqual(report['status'], 'TOUCH_SENT')
        self.probe.image_lines.assert_not_called()
        self.probe.native_tap.assert_called_once_with(
            self.out, CAPTION, '21_kart_preview_skip_touch',
            timeout=43, exact=True, orientation='landscape')

    def test_expired_initial_budget_cannot_sample_or_touch(self):
        self.clock.now = 55
        with self.assertRaises(TimeoutError):
            self.skip()
        self.probe.image_lines.assert_not_called()
        self.probe.native_tap.assert_not_called()

    def test_missing_original_ocr_journal_cannot_report_success(self):
        original_touch = self.touch

        def without_ocr(*args, **kwargs):
            original_touch(*args, **kwargs)
            (self.out / '21_kart_preview_skip_touch-1-ocr.json').unlink()

        self.probe.native_tap.side_effect = without_ocr
        with self.assertRaises(FileNotFoundError):
            self.skip()
        self.probe.capture.assert_not_called()
        self.assertEqual(self.journal()['status'], 'FAIL')

    def test_late_touch_helper_result_cannot_report_success(self):
        self.touch_cost = 55
        with self.assertRaises(TimeoutError):
            self.skip()
        self.assertEqual(self.journal()['status'], 'FAIL')
        self.probe.capture.assert_not_called()

    def test_late_after_capture_cannot_report_success(self):
        self.capture_cost = 55
        with self.assertRaises(TimeoutError):
            self.skip()
        self.assertEqual(self.journal()['status'], 'FAIL')

    def test_changed_touch_witness_cannot_report_success(self):
        self.cue_mutation = True
        with self.assertRaisesRegex(RuntimeError, 'changed'):
            self.skip()
        self.probe.capture.assert_not_called()

    def test_wrong_foreground_is_rejected_before_input(self):
        self.base.foreground.return_value = 'app/MainActivity'
        with self.assertRaisesRegex(RuntimeError, 'not foreground'):
            self.skip()
        self.probe.native_tap.assert_not_called()

    def test_one_frame_or_failed_touch_journal_never_reports_success(self):
        for count, status in [(1, 'TOUCH_SENT'), (2, 'FAIL')]:
            with self.subTest(count=count, status=status):
                self.clock.now = 0
                self.touch_frames, self.touch_status = count, status
                with self.assertRaisesRegex(RuntimeError, 'two-frame'):
                    self.skip()
                self.assertEqual(self.journal()['status'], 'FAIL')

    def test_wrong_actual_ocr_words_or_bounds_cannot_report_success(self):
        original_touch = self.touch
        for row in ({'text': 'Tippen zum Starten', 'bounds': [920, 240, 1480, 282]},
                    {'text': CAPTION, 'bounds': [1, 2, 3, 4]}):
            with self.subTest(row=row):
                self.clock.now = 0

                def wrong_ocr(*args, **kwargs):
                    original_touch(*args, **kwargs)
                    (self.out / '21_kart_preview_skip_touch-1-ocr.json').write_text(
                        json.dumps([row]))

                self.probe.native_tap.side_effect = wrong_ocr
                with self.assertRaisesRegex(RuntimeError, 'exact observed OCR'):
                    self.skip()
                self.assertEqual(self.journal()['status'], 'FAIL')
        self.probe.capture.assert_not_called()

    def use_actual_helper(self, *, first_fresh_frame_faded=False):
        """Execute real native_tap/image_lines/target math; double only I/O.

        Synthetic TSV words are deliberately surrounded by other words in one
        line. Only the real normalized-wanted span extractor can recover their
        exact bounds. This is a protocol test, never an original-image replay.
        """
        class RasterTransport:
            width, height = 2400, 1080

            def convert(self, *_):
                return self

            def point(self, *_):
                return self

            def split(self):
                return self, self, self

            def getbbox(self):
                return None

            def resize(self, *_):
                return self

            def save(self, path):
                Path(path).write_bytes(b'synthetic mask transport, not pixel evidence')

        raster = RasterTransport()
        commands = []

        def command(*args, **kwargs):
            self.clock.sleep(.1)
            commands.append((args, kwargs))
            prefix = Path(args[2])
            faded = (first_fresh_frame_faded and
                     ('preview_cue' in prefix.name or 'touch-0-ocr-' in prefix.name))
            words = ['SONNENHAFEN'] if faded else ['Hinweis', 'Tippen', 'zum', 'Überspringen', 'Pause']
            columns = ['level', 'page_num', 'block_num', 'par_num', 'line_num',
                       'word_num', 'left', 'top', 'width', 'height', 'conf', 'text']
            with prefix.with_suffix('.tsv').open('w', newline='') as stream:
                writer = csv.DictWriter(stream, fieldnames=columns, delimiter='\t',
                                        quoting=csv.QUOTE_NONE)
                writer.writeheader()
                for index, word in enumerate(words):
                    writer.writerow(dict(level=5, page_num=1, block_num=1, par_num=1,
                                         line_num=1, word_num=index+1, left=200+index*160,
                                         top=300, width=140, height=70, conf=91, text=word))

        def inspect_surface(source, *, orientation):
            return {'source': source.name, 'source_sha256': self.probe.digest(source),
                    'source_bytes': source.stat().st_size, 'pixels': [2400, 1080],
                    'acceptable_for_target_sampling': True, 'reasons': [],
                    'orientation_policy': orientation}

        chops = SimpleNamespace(**{name: lambda *_: raster for name in
                                  ('darker', 'lighter', 'subtract', 'invert',
                                   'difference', 'multiply')})
        geometry = definitions(SURFACE, {'math': math})
        helper = definitions(HELPER, {
            'Path': Path, 'json': json, 'csv': csv, 're': re,
            'unicodedata': unicodedata, 'time': self.clock,
            'Image': SimpleNamespace(open=lambda _: raster), 'ImageChops': chops,
            'base': SimpleNamespace(command=command, adb=self.base.adb),
            'inspect_surface': inspect_surface,
            'target_observation': geometry.target_observation,
            'read_tiled_word': Mock(return_value=[]),
        })
        helper.capture = self.capture
        helper.digest = self.probe.digest
        helper.read_component_caption = Mock(return_value=[])
        helper.image_lines = Mock(wraps=helper.image_lines)
        self.probe.normalized = helper.normalized
        self.probe.image_lines = helper.image_lines
        self.probe.native_tap = Mock(wraps=helper.native_tap)
        return helper, commands

    def test_actual_helper_normalizes_wanted_and_keeps_exact_observed_span(self):
        helper, commands = self.use_actual_helper()
        report = self.skip()
        self.assertEqual(report['status'], 'TOUCH_SENT')
        self.assertEqual(len(commands), 2)
        self.assertEqual(helper.image_lines.call_count, 2)
        for call in helper.image_lines.call_args_list:
            self.assertEqual(call.args[2], 'tippenzumuberspringen')
        self.assertEqual(report['cue']['observed_matches'][0]['text'], CAPTION)
        self.assertEqual(report['cue']['observed_matches'][0]['bounds'], [180, 150, 410, 185])
        helper.read_component_caption.assert_not_called()
        helper.read_tiled_word.assert_not_called()

    def test_actual_helper_observes_fade_then_two_fresh_exact_frames(self):
        helper, commands = self.use_actual_helper(first_fresh_frame_faded=True)
        report = self.skip()
        self.assertEqual(report['status'], 'TOUCH_SENT')
        frames = report['readiness']['frames']
        self.assertEqual(len(frames), 3)
        self.assertNotIn('target', frames[0])
        self.assertEqual(report['cue']['source'], frames[-1]['source'])
        self.assertEqual([row['source'] for row in report['cue_witnesses']],
                         [frame['source'] for frame in frames[-2:]])
        self.assertTrue(all(call.kwargs['source_path'] != self.source
                            for call in helper.image_lines.call_args_list))
        inputs = [args for args, _ in self.adb_calls if args[:3] == ('shell', 'input', 'swipe')]
        self.assertEqual(len(inputs), 1)
        self.assertLess(self.clock.now, 55)

    def test_actual_helper_cannot_touch_after_original_deadline(self):
        self.use_actual_helper()
        self.clock.now = 54
        with self.assertRaises(TimeoutError):
            self.skip(deadline=55)
        self.assertFalse(self.adb_calls)
        self.assertEqual(self.journal()['countercheck_scope'], 'NOT_ISOLATED')

    def test_running_clock_still_requires_countdown_over_and_full_elapsed_second(self):
        original = {'mode': 'cup', 'track_id': 'sonnenhafen', 'finished': False,
                    'completed_race': False, 'countdown': 3.5, 'elapsed': 0,
                    'distance': 0, 'result_id': 'same-race'}
        states = [original, dict(original, countdown=0, elapsed=.99),
                  dict(original, countdown=0, elapsed=1.0)]
        session = SimpleNamespace(out=self.out, expected_mode='cup',
                                  expected_track='sonnenhafen', read=Mock(side_effect=states))
        self.assertEqual(self.module.wait_race_running(session), states[-1])
        self.assertEqual(session.read.call_count, 3)
        self.probe.capture.assert_not_called()

    def test_timeout_captures_current_frame_after_failure_without_new_state_acceptance(self):
        state = {'mode': 'cup', 'track_id': 'sonnenhafen', 'finished': False,
                 'completed_race': False, 'countdown': 3.5, 'elapsed': 0,
                 'distance': 0, 'result_id': 'same-race'}
        session = SimpleNamespace(out=self.out, expected_mode='cup',
                                  expected_track='sonnenhafen', read=Mock(return_value=state))

        def late_capture(out, name, *, timeout):
            self.assertEqual(self.clock.now, 150)
            state.update(countdown=0, elapsed=2)
            return self.capture(out, name, timeout=timeout)

        self.probe.capture.side_effect = late_capture
        with self.assertRaisesRegex(RuntimeError, 'Saved race never showed a running race clock'):
            self.module.wait_race_running(session)
        self.assertEqual(session.read.call_count, 75)
        self.probe.capture.assert_called_once_with(
            self.out, '21_race_running_timeout', timeout=10)
        report = json.loads((self.out / '21_race_running_timeout.json').read_text())
        self.assertEqual(report['status'], 'GATE_ALREADY_FAILED')
        self.assertEqual(report['timeout_seconds'], 150)
        self.assertEqual(report['last_persisted_observation']['countdown'], 3.5)

    def test_failed_timeout_capture_preserves_original_clock_failure(self):
        state = {'mode': 'cup', 'track_id': 'sonnenhafen', 'finished': False,
                 'completed_race': False, 'countdown': 3.5, 'elapsed': 0, 'distance': 0}
        session = SimpleNamespace(out=self.out, expected_mode='cup',
                                  expected_track='sonnenhafen', read=lambda _: state)
        self.probe.capture.side_effect = OSError('capture transport unavailable')
        with self.assertRaisesRegex(RuntimeError, 'Saved race never showed a running race clock'):
            self.module.wait_race_running(session)
        report = json.loads((self.out / '21_race_running_timeout.json').read_text())
        self.assertIn('capture transport unavailable', report['capture_error'])


class OriginalGatePreservationTests(unittest.TestCase):
    def test_exact078_identity_session_hud_and_driving_contracts_are_unchanged(self):
        expected = {
            'verify_apk_identity': '765f3459b10390f55496247980cb3b16b66ca95ad22a0cf14d7c657c6b60ecf6',
            'RaceSession': '6fe45bf74aec10c318f0c8161ce2ea97c1544ff2442c00f1e47b45d545090ca6',
            'wait_race_hud': '5d7484ab84e57308f271070b63443945afc3aca628dbdb45a81d30a812f9d21e',
            'find_gas': 'b488c01ea51b67294a2892ca956efdef0b22c7fd0d6a1132e9e1549d1ca648c2',
            'drive_with_gas': '0994348eefb4da2b68e7a7a63777c7fa2bf166d60e4d0775db337c3f981c1f5e',
        }
        functions = {node.name: node for node in ast.parse(TOUR.read_text()).body
                     if isinstance(node, (ast.FunctionDef, ast.ClassDef))}
        for name, digest in expected.items():
            with self.subTest(name=name):
                self.assertEqual(hashlib.sha256(ast.dump(
                    functions[name], include_attributes=False).encode()).hexdigest(), digest)

    def test_main_preserves_all_original_pause_save_return_and_learning_checks(self):
        tree = ast.parse(TOUR.read_text())
        main = next(node for node in tree.body if isinstance(node, ast.FunctionDef)
                    and node.name == 'main')

        class RemoveOnlyOptInPlumbing(ast.NodeTransformer):
            def visit_Expr(self, node):
                value = node.value
                if (isinstance(value, ast.Call) and isinstance(value.func, ast.Attribute)
                        and value.func.attr == 'add_argument' and value.args
                        and isinstance(value.args[0], ast.Constant)
                        and value.args[0].value == '--skip-observed-kart-preview'):
                    return None
                return self.generic_visit(node)

            def visit_Call(self, node):
                if isinstance(node.func, ast.Name) and node.func.id == '_start_actual_embedded_race':
                    self.assert_only_skip_keyword(node)
                    node.keywords = []
                return self.generic_visit(node)

            @staticmethod
            def assert_only_skip_keyword(node):
                if node.keywords:
                    assert len(node.keywords) == 1 and node.keywords[0].arg == 'skip_preview'
                    value = node.keywords[0].value
                    assert isinstance(value, ast.Attribute) and value.attr == 'skip_observed_kart_preview'
                    assert isinstance(value.value, ast.Name) and value.value.id == 'args'

        main = RemoveOnlyOptInPlumbing().visit(main)
        self.assertEqual(hashlib.sha256(ast.dump(main, include_attributes=False).encode()).hexdigest(),
                         '79decb17fb1d0b42841f87f4a11c7c166c4c00670b02798631cc5d6b09313f85')

    def test_running_gate_only_adds_diagnostic_after_its_original_terminal_condition(self):
        tree = ast.parse(TOUR.read_text())
        node = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
                    and n.name == 'wait_race_running')
        index = next(i for i, statement in enumerate(node.body)
                     if isinstance(statement, ast.Assign)
                     and isinstance(statement.targets[0], ast.Name)
                     and statement.targets[0].id == 'diagnostic')
        node.body = node.body[:index] + [node.body[-1]]
        self.assertEqual(hashlib.sha256(ast.dump(node, include_attributes=False).encode()).hexdigest(),
                         'b17c35e5db06e28ffcb06f1c82770d957fabf3b3917f9ee048ed933805bf498b')


if __name__ == '__main__':
    unittest.main()
