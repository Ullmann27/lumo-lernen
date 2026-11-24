"""Recorded Android failures and immutable native CI positives, not a device PASS."""
import ast
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from nextgen_evidence import cards_projected_faces, require_cards_face_pixels
from native_surface_readiness import inspect_surface

ROOT = Path(__file__).resolve().parents[3]
FIXTURES = Path(__file__).with_name('fixtures') / 'cards_faces_2018'
NATIVE = 'ada5ed81ad62339f15289da62670c0a4f9f7f2b9'


class NextgenCardsFaceTests(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads((FIXTURES / 'manifest.json').read_text())
        self.observations = json.loads((FIXTURES / 'observations.json').read_text())
        self.cases = {case['name']: case for case in self.manifest['cases']}
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)

    def image(self, case):
        path = FIXTURES / case['image']
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), case['sha256'])
        return path

    def check(self, case):
        return require_cards_face_pixels(self.image(case), case['public'], density=case['density'],
                                         observations=self.observations[case['name']])

    def test_independent_projection_matches_actual_godot_mesh_readbacks(self):
        raw = (FIXTURES / 'production_geometry.json').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(), self.manifest['production_geometry_sha256'])
        geometry = json.loads(raw)
        self.assertEqual(geometry['kind'], 'headless_production_geometry_not_renderer_capture')
        self.assertEqual(len(geometry['views']), 5)
        for view in geometry['views']:
            with self.subTest(size=[view['width'], view['height']]):
                count = 8 if view['card_source'] == 'actual_android_mailbox_009' else 7
                actual = cards_projected_faces(view['width'], view['height'], view['density'], count)
                pairs = [(actual['discard'], view['discard']['quad'])]
                pairs += [(quad, record['quad']) for quad, record in zip(actual['hand'], view['hand'])]
                for calculated, recorded in pairs:
                    for point, original in zip(calculated, recorded):
                        for value, expected in zip(point, original):
                            self.assertAlmostEqual(value, expected, delta=.002)

    def test_actual_android_blank_fronts_are_rejected_from_original_pixels(self):
        for name in ('android_before', 'android_after'):
            with self.subTest(name=name):
                case = self.cases[name]
                self.assertEqual(case['workflow_run'], 43395154888)
                with self.assertRaisesRegex(RuntimeError, 'blank or lacks visible artwork'):
                    self.check(case)

    def test_all_four_new_native_json_renderer_images_have_actual_front_artwork(self):
        positives = [case for case in self.cases.values() if case['expected'] == 'accept']
        self.assertEqual(len(positives), 4, 'Four actual new native CI images are mandatory')
        for case in positives:
            with self.subTest(name=case['name']):
                self.assertEqual(case['native_source'], NATIVE)
                self.assertTrue(case['json_mailbox_roundtrip'])
                report = self.check(case)
                self.assertEqual(report['source_sha256'], case['sha256'])
                self.assertGreaterEqual(len(report['faces']), 4)
                self.assertEqual(report['faces'][-1]['card_id'], case['public']['top']['id'])

    def test_unknown_layout_or_incomplete_first_page_is_not_guessed(self):
        for arguments in ((1080, 2340, 2.625, 7), (1080, 2400, 1, 7),
                          (412, 915, 1, 2), (1280, 720, True, 7),
                          (1080, 2400, float('nan'), 7)):
            with self.subTest(arguments=arguments), self.assertRaises(RuntimeError):
                cards_projected_faces(*arguments)

    def test_stale_ui_wrong_page_or_paused_public_state_cannot_pass_pixels(self):
        case = self.cases['native_412x915']
        for field, value in (('source_sha256', '0' * 64),
                             ('pause', {'text': 'Weiter', 'bounds': [1, 1, 40, 20]}),
                             ('page', {'text': '2/3', 'bounds': [180, 800, 230, 820]})):
            with self.subTest(field=field):
                observation = copy.deepcopy(self.observations[case['name']])
                observation[field] = value
                with self.assertRaises(RuntimeError):
                    require_cards_face_pixels(self.image(case), case['public'], density=1,
                                              observations=observation)
        paused = dict(case['public'], paused=True, canDraw=False)
        with self.assertRaisesRegex(RuntimeError, 'unpaused child turn'):
            require_cards_face_pixels(self.image(case), paused, density=1,
                                      observations=self.observations[case['name']])

    def test_every_single_blank_hand_or_discard_face_is_rejected(self):
        case = self.cases['native_412x915']
        original = self.image(case)
        geometry = cards_projected_faces(412, 915, 1, len(case['public']['hand']))
        for index, quad in enumerate(geometry['hand'] + [geometry['discard']]):
            with self.subTest(front=index):
                # Explicitly synthetic NEGATIVES made from real CI pixels.
                # Original positive files remain immutable and hash checked.
                image = Image.open(original).convert('RGB')
                ImageDraw.Draw(image).polygon([tuple(point) for point in quad], fill='white')
                path = self.out / f'negative-blank-front-{index}.png'
                image.save(path)
                observation = copy.deepcopy(self.observations[case['name']])
                observation['source_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
                with self.assertRaisesRegex(RuntimeError, 'blank or lacks visible artwork'):
                    require_cards_face_pixels(path, case['public'], density=1, observations=observation)
        self.image(case)

    def replay_capture(self, case, *, change_first_revision=False, start_paused=False, timeout=8):
        # Input and Android transport are doubles; every positive image is an
        # unchanged real CI frame, and the real pixel checks execute here.
        state = copy.deepcopy(case['public'])
        if start_paused:
            state.update(paused=True, canDraw=False)
        clock = [0.0]
        captures = []
        reads = [0]

        def read():
            reads[0] += 1
            if start_paused and reads[0] == 2:
                state.update(paused=False, canDraw=True)
            return copy.deepcopy(state)

        def capture(out, tag, timeout):
            self.assertGreater(timeout, 0)
            captures.append(tag)
            path = out / (tag + '.png')
            path.write_bytes(self.image(case).read_bytes())
            clock[0] += .1
            return {'file': path.name}

        def image_lines(*_args, **_kwargs):
            if change_first_revision and len(captures) == 1:
                state['revision'] += 1
            return [copy.deepcopy(value) for key, value in self.observations[case['name']].items()
                    if key in ('pause', 'page')]

        source = ROOT / '.github/probes/lumo_nextgen_surfaces_android_probe.py'
        body = [node for node in ast.parse(source.read_text()).body
                if isinstance(node, ast.FunctionDef) and node.name == 'capture_cards_faces']
        scope = {'Path': Path, 'CardsMailbox': object, 'json': json,
                 'time': SimpleNamespace(monotonic=lambda: clock[0],
                                         sleep=lambda seconds: clock.__setitem__(0, clock[0] + seconds)),
                 'probe': SimpleNamespace(capture=capture, image_lines=image_lines,
                                          normalized=lambda value: value.lower(), inspect_surface=inspect_surface,
                                          digest=lambda path: hashlib.sha256(path.read_bytes()).hexdigest()),
                 'cards_projected_faces': cards_projected_faces,
                 'require_cards_face_pixels': require_cards_face_pixels}
        exec(compile(ast.Module(body=body, type_ignores=[]), str(source), 'exec'), scope)
        return scope['capture_cards_faces'](self.out, SimpleNamespace(read=read), 'replay',
                                            case['public'], case['density'], timeout=timeout), captures

    def test_capture_waits_for_unpaused_state_and_two_actual_frames_of_same_revision(self):
        case = self.cases['native_412x915']
        (state, report), captures = self.replay_capture(case, change_first_revision=True, start_paused=True)
        self.assertFalse(state['paused'])
        self.assertEqual(len(captures), 3)
        self.assertEqual(report['status'], 'PASS')
        self.assertEqual(report['consecutive_same_revision_frames'], 2)
        self.assertEqual(report['frames'][0]['status'], 'REJECTED')
        final_frames = report['frames'][-2:]
        self.assertNotEqual(final_frames[0]['source'], final_frames[1]['source'])
        for frame in final_frames:
            self.assertEqual(frame['public_before'], state)
            self.assertEqual(frame['public_after'], state)
            self.assertEqual(frame['source_sha256'], report['source_sha256'])
        self.assertEqual(report['roundId'], state['roundId'])
        self.assertEqual((self.out / 'replay.png').read_bytes(), self.image(case).read_bytes())

    def test_capture_persistent_actual_blank_frames_fail_within_the_deadline(self):
        with self.assertRaisesRegex(RuntimeError, 'before deadline'):
            self.replay_capture(self.cases['android_after'], timeout=2)
        report = json.loads((self.out / 'replay-face-evidence.json').read_text())
        self.assertEqual(report['status'], 'FAIL')
        self.assertLessEqual(report['elapsed_seconds'], 2.1)
        self.assertTrue(all(frame['status'] == 'REJECTED' for frame in report['frames']))


if __name__ == '__main__':
    unittest.main()
