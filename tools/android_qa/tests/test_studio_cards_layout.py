"""Actual Godot projected mesh readbacks, plus explicitly synthetic negatives.

The historical fallback executes the exact old projection for the red replay;
it cannot satisfy the valid measured geometry or any mandatory rejection case.
"""
import ast
import copy
import hashlib
import json
from pathlib import Path
import re
import sys
import tempfile
from types import SimpleNamespace
import unittest

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
import nextgen_evidence as evidence
from native_surface_readiness import inspect_surface

FIXTURES = Path(__file__).with_name('fixtures') / 'cards_safe_area_2019'
PROBE = ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py'


class StudioCardsLayoutTests(unittest.TestCase):
    def setUp(self):
        manifest = json.loads((FIXTURES / 'manifest.json').read_text())
        for item in manifest['files']:
            self.assertEqual(hashlib.sha256((FIXTURES / item['file']).read_bytes()).hexdigest(),
                             item['sha256'])
        self.layout = json.loads((FIXTURES / 'android35_portrait-playing.layout.json').read_text())
        self.public = json.loads((FIXTURES / 'public-fixture.json').read_text())
        self.observations = json.loads((FIXTURES / 'observations.json').read_text())
        temporary = tempfile.TemporaryDirectory(prefix='lumo-cards-layout-')
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)

    def verify(self, layout=None, public=None, *, width=1080, height=2400,
               density=2.625, allow_fixture=True):
        layout = self.layout if layout is None else layout
        public = self.public if public is None else public
        if hasattr(evidence, 'require_cards_layout'):
            return evidence.require_cards_layout(layout, public, width=width, height=height,
                                                 density=density, allow_fixture=allow_fixture)
        # Record why the historical oracle cannot accept the new production
        # layout: it has no measurement or layout-state input at all.
        return {'geometry': evidence.cards_projected_faces(width, height, density,
                                                           len(public['hand']))}

    def test_new_projection_matches_actual_godot_unproject_readback(self):
        for name, size in (('android35_portrait-playing', (1080, 2400)),
                           ('landscape_cutout_fixture-playing', (2400, 1080))):
            layout = json.loads((FIXTURES / (name + '.layout.json')).read_text())
            result = self.verify(layout, width=size[0], height=size[1])
            pairs = list(zip(result['geometry']['hand'], [item['quad'] for item in layout['hand']]))
            pairs.append((result['geometry']['discard'], layout['discard']['quad']))
            for projected, actual in pairs:
                for point, original in zip(projected, actual):
                    for value, expected in zip(point, original):
                        self.assertAlmostEqual(value, expected, delta=.002)

    def test_original_runtime_pixels_and_actual_ocr_pass_without_lowered_thresholds(self):
        for name in self.observations:
            with self.subTest(name=name):
                layout = json.loads((FIXTURES / (name + '.layout.json')).read_text())
                report = evidence.require_cards_face_pixels(FIXTURES / (name + '.png'),
                    self.public, density=2.625, observations=self.observations[name],
                    layout=layout, allow_fixture_layout=True)
                self.assertEqual(report['source_sha256'], self.observations[name]['source_sha256'])
                self.assertEqual(report['layout_binding']['observation_source'], 'fixture')
                self.assertEqual(len(report['faces']), len(layout['hand']) + 1)

    def test_blank_individual_fronts_still_fail_in_new_measured_coordinates(self):
        name = 'android35_portrait-playing'
        geometry = self.verify()['geometry']
        for index, quad in enumerate(geometry['hand'] + [geometry['discard']]):
            # Explicit negative images only; original PNG/sidecar stay immutable.
            with Image.open(FIXTURES / (name + '.png')) as original:
                image = original.convert('RGB')
            ImageDraw.Draw(image).polygon([tuple(point) for point in quad], fill='white')
            path = self.out / f'synthetic-blank-{index}.png'
            image.save(path)
            image.close()
            observation = copy.deepcopy(self.observations[name])
            observation['source_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
            with self.subTest(front=index), self.assertRaisesRegex(RuntimeError, 'blank or lacks visible artwork'):
                evidence.require_cards_face_pixels(path, self.public, density=2.625,
                    observations=observation, layout=self.layout, allow_fixture_layout=True)

    def test_original_projection_misses_the_actual_safe_area_hand_by_more_than_63_pixels(self):
        old = evidence.cards_projected_faces(1080, 2400, 2.625, len(self.public['hand']))
        error = max(abs(a-b) for quad, actual in zip(old['hand'], self.layout['hand'])
                    for point, original in zip(quad, actual['quad']) for a,b in zip(point, original))
        self.assertGreater(error, 63)

    def test_wrong_insets_and_wrong_ui_rect_are_not_trusted(self):
        for modify in (
            lambda x: x['android_observation']['system_insets'].__setitem__(1, 32),
            lambda x: x['android_observation']['insets'].__setitem__(3, 0),
            lambda x: x['ui_rect'].__setitem__(1, 32),
            lambda x: x['android_observation']['render_rect'].__setitem__(1, 136),
        ):
            layout = copy.deepcopy(self.layout)
            modify(layout)
            with self.assertRaises(RuntimeError):
                self.verify(layout)

    def test_rotated_or_mismatched_screen_cannot_reuse_portrait_measurements(self):
        with self.assertRaises(RuntimeError):
            self.verify(width=2400, height=1080)
        layout = copy.deepcopy(self.layout)
        layout['window_px'] = [2400, 1080]
        with self.assertRaises(RuntimeError):
            self.verify(layout)

    def test_already_offset_view_is_mapped_once_into_the_captured_screen(self):
        # Retain the genuine native mesh readback and its136/63 overlap. The
        # explicit synthetic Android boundary adds100px above/below the same
        # RenderView; the independent expected result is a100px translation.
        layout = copy.deepcopy(self.layout)
        layout['android_observation'].update(decor_size=[1080, 2600],
            render_rect=[0, 100, 1080, 2400], system_insets=[0, 236, 0, 163])
        result = self.verify(layout, width=1080, height=2600)
        self.assertEqual(result['safe_ui_rect'], [0, 236, 1080, 2201])
        for calculated, observed in zip(result['geometry']['hand'], self.layout['hand']):
            for point, native in zip(calculated, observed['quad']):
                self.assertAlmostEqual(point[0], native[0], delta=.002)
                self.assertAlmostEqual(point[1], native[1] + 100, delta=.002)

    def test_another_session_or_changed_public_revision_cannot_supply_geometry(self):
        for key, value in (('token', 'b'*32), ('roundId', 'another-round'),
                           ('revision', 5), ('ack', 1), ('viewer', 1),
                           ('paused', True), ('phase', 'learningQuestion')):
            with self.subTest(key=key):
                layout = copy.deepcopy(self.layout)
                layout[key] = value
                with self.assertRaises(RuntimeError):
                    self.verify(layout)

    def test_unsettled_pending_hidden_or_selected_layout_is_rejected(self):
        for key, value in (('settled', False), ('pending', 1), ('ui_visible', False),
                           ('selected_card_id', 'r1'), ('page', 1), ('page_size', 5),
                           ('layout_sequence', 0), ('ticks_msec', -1)):
            with self.subTest(key=key):
                layout = copy.deepcopy(self.layout)
                layout[key] = value
                with self.assertRaises(RuntimeError):
                    self.verify(layout)

    def test_swapped_ids_and_fabricated_or_nonfinite_polygons_are_rejected(self):
        for modify in (
            lambda x: x['hand'][0].__setitem__('id', 'different'),
            lambda x: x['discard'].__setitem__('id', 'other-top'),
            lambda x: x['hand'][0]['quad'][0].__setitem__(1, x['hand'][0]['quad'][0][1]+10),
            lambda x: x['hand'][0]['quad'][0].__setitem__(0, float('nan')),
            lambda x: x['hand'][0]['quad'][0].__setitem__(0, True),
        ):
            layout = copy.deepcopy(self.layout)
            modify(layout)
            with self.assertRaises(RuntimeError):
                self.verify(layout)

    def test_fixture_never_masquerades_as_actual_android_observation(self):
        with self.assertRaises(RuntimeError):
            self.verify(allow_fixture=False)

    def test_missing_and_malformed_measurements_are_rejected(self):
        for key in ('android_observation', 'viewport_px', 'ui_rect', 'hand', 'discard'):
            layout = copy.deepcopy(self.layout)
            del layout[key]
            with self.assertRaises(RuntimeError):
                self.verify(layout)
        for invalid in (None, {}, [], 'layout', True):
            with self.assertRaises(RuntimeError):
                self.verify(invalid if invalid is not None else {})

    def replay_capture(self, *, missing_reads=0, change_during_first_ocr=None,
                       different_second_layout=False, wrong_revision=False,
                       rotated_image=False, wrong_caption=False, late_second_ocr=False,
                       timeout=6):
        """Real original pixels/measurements; only Android/clock transport is isolated.

        Fixture permission is confined to these test adapters. The production
        capture always calls both validators with their default Android-only
        observation requirement; no input/Resume/action API is provided here.
        """
        state = copy.deepcopy(self.public)
        layout = copy.deepcopy(self.layout)
        if wrong_revision:
            layout['revision'] += 1
        clock = [0.0]
        captures, reads = [], []
        changed = [False]
        name = 'landscape_cutout_fixture-playing' if rotated_image else 'android35_portrait-playing'
        image = (FIXTURES / (name + '.png')).read_bytes()

        def advance(seconds):
            clock[0] += seconds

        def adb(*arguments, **kwargs):
            self.assertEqual(arguments, ('exec-out', 'cat',
                '/data/user/0/fictional.test/files/cards_layout_v1.json'))
            self.assertGreater(kwargs['timeout'], 0)
            self.assertLessEqual(kwargs['timeout'], 4)
            reads.append(arguments)
            advance(.025)
            if len(reads) <= missing_reads:
                raise RuntimeError('cat: current native layout is not settled yet')
            if different_second_layout and len(captures) == 1 and len(reads) == 3:
                layout['layout_sequence'] += 1
                layout['ticks_msec'] += 100
            return json.dumps(layout, separators=(',', ':'))

        def capture(out, tag, **kwargs):
            self.assertGreater(kwargs['timeout'], 0)
            target = out / (tag + '.png')
            target.write_bytes(image)
            captures.append(target)
            advance(.1)
            return {'file': target.name}

        def image_lines(out, tag, wanted, *, source_path, **kwargs):
            self.assertEqual(source_path.read_bytes(), image)
            self.assertTrue(kwargs['exact'])
            advance(timeout + .1 if late_second_ocr and len(captures) == 2 else .1)
            if change_during_first_ocr and not changed[0]:
                changed[0] = True
                layout['layout_sequence'] += 1
                layout['ticks_msec'] += 100
                if change_during_first_ocr == 'state':
                    state['revision'] += 1
                    layout['revision'] += 1
            values = [copy.deepcopy(self.observations[name][key]) for key in ('pause', 'page')]
            if wrong_caption:
                values[0]['text'] = 'Weiter'
            return values

        def layout_check(*args, **kwargs):
            self.assertNotIn('allow_fixture', kwargs)
            return evidence.require_cards_layout(*args, **kwargs, allow_fixture=True)

        def pixel_check(*args, **kwargs):
            self.assertNotIn('allow_fixture_layout', kwargs)
            return evidence.require_cards_face_pixels(*args, **kwargs, allow_fixture_layout=True)

        scope = {'Path': Path, 'json': json, 're': re, 'CardsMailbox': object,
            'PACKAGE': 'fictional.test', 'base': SimpleNamespace(adb=adb),
            'time': SimpleNamespace(monotonic=lambda: clock[0], sleep=advance),
            'probe': SimpleNamespace(capture=capture, image_lines=image_lines,
                normalized=lambda text: re.sub('[^a-z0-9]', '', text.lower()),
                inspect_surface=inspect_surface,
                digest=lambda path: hashlib.sha256(path.read_bytes()).hexdigest()),
            'require_cards_layout': layout_check, 'require_cards_face_pixels': pixel_check,
            'cards_projected_faces': evidence.cards_projected_faces}
        functions = [node for node in ast.parse(PROBE.read_text()).body
                     if isinstance(node, ast.FunctionDef) and node.name in
                     ('read_cards_layout', 'capture_cards_faces')]
        exec(compile(ast.Module(body=functions, type_ignores=[]), str(PROBE), 'exec'), scope)
        box = SimpleNamespace(read=lambda: copy.deepcopy(state), token=self.public['token'])
        result = scope['capture_cards_faces'](self.out, box, 'capture-replay', self.public,
                                              2.625, timeout=timeout)
        return result, captures, reads

    def test_capture_requires_two_real_frames_and_layout_reads_on_both_sides(self):
        (state, report), captures, reads = self.replay_capture()
        self.assertEqual(state, self.public)
        self.assertEqual((len(captures), len(reads)), (2, 4))
        self.assertEqual(report['status'], 'PASS')
        self.assertEqual(report['layout_sequence'], self.layout['layout_sequence'])
        self.assertEqual(report['consecutive_same_revision_frames'], 2)
        for frame in report['frames']:
            self.assertEqual(frame['layout_before']['source_sha256'], frame['layout_after']['source_sha256'])
            self.assertEqual(frame['public_before'], frame['public_after'])
        self.assertEqual((self.out / 'capture-replay.png').read_bytes(), captures[-1].read_bytes())

    def test_initial_missing_layout_is_observed_again_without_any_input(self):
        (_state, report), captures, reads = self.replay_capture(missing_reads=1)
        self.assertEqual((len(captures), len(reads)), (2, 5))
        self.assertEqual(report['frames'][0]['status'], 'REJECTED')
        self.assertIn('not settled yet', report['frames'][0]['error'])

    def test_layout_or_state_change_during_capture_resets_consecutive_frames(self):
        for kind in ('layout', 'state'):
            with self.subTest(kind=kind):
                (_state, report), captures, _reads = self.replay_capture(change_during_first_ocr=kind)
                self.assertEqual(len(captures), 3)
                self.assertEqual(report['frames'][0]['status'], 'REJECTED')
                self.assertEqual(report['layout_sequence'], self.layout['layout_sequence'] + 1)

    def test_layout_change_between_frames_requires_two_frames_of_the_new_layout(self):
        (_state, report), captures, _reads = self.replay_capture(different_second_layout=True)
        self.assertEqual(len(captures), 3)
        self.assertEqual(report['layout_sequence'], self.layout['layout_sequence'] + 1)

    def test_missing_stale_rotated_or_wrong_caption_never_publish_a_pass_image(self):
        for arguments, text in (({'missing_reads': 100}, 'not settled yet'),
                                ({'wrong_revision': True}, 'stale or changed public state'),
                                ({'rotated_image': True}, 'current screenshot size'),
                                ({'wrong_caption': True}, 'paused/modal transition')):
            with self.subTest(arguments=arguments), self.assertRaisesRegex(RuntimeError, 'before deadline'):
                self.replay_capture(**arguments, timeout=2)
            report = json.loads((self.out / 'capture-replay-face-evidence.json').read_text())
            self.assertEqual(report['status'], 'FAIL')
            self.assertTrue(any(text in frame.get('error', '') for frame in report['frames']))
            self.assertFalse((self.out / 'capture-replay.png').exists())

    def test_late_ocr_cannot_deliver_evidence_after_the_existing_deadline(self):
        with self.assertRaisesRegex(RuntimeError, 'before deadline'):
            self.replay_capture(late_second_ocr=True, timeout=2)
        self.assertFalse((self.out / 'capture-replay.png').exists())


if __name__ == '__main__':
    unittest.main()
