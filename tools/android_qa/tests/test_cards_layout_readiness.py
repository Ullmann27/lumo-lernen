"""Replay an original missing-file reply inside the unchanged Cards capture gate.

The sequence/transport and clock are test doubles. Original pre-draw pixels,
layout, public state and recorded OCR are immutable historical observations;
the real geometry/pixel validators run. This is not a new Android draw PASS.
"""
import ast
import copy
import hashlib
import importlib.util
import inspect
import json
from pathlib import Path
import re
import sys
import tempfile
from types import SimpleNamespace
import unittest


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py'
FIXTURE = Path(__file__).with_name('fixtures') / 'cards_layout_readiness_a446'
sys.path.insert(0, str(ROOT / 'tools/android_qa'))


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


evidence = load(ROOT / 'tools/android_qa/nextgen_evidence.py', 'layout_readiness_evidence')
surfaces = load(ROOT / 'tools/android_qa/native_surface_readiness.py', 'layout_readiness_surface')


class CardsLayoutReadinessTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-cards-layout-readiness-')
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        manifest = json.loads((FIXTURE / 'manifest.json').read_text())
        for row in manifest['files']:
            raw = (FIXTURE / row['file']).read_bytes()
            self.assertEqual(len(raw), row['bytes'])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), row['sha256'])
        self.missing = (FIXTURE / 'missing-layout-original.txt').read_text()
        self.layout_raw = (FIXTURE / 'layout-original.json').read_text()
        self.layout = json.loads(self.layout_raw)
        recorded = json.loads((FIXTURE / 'face-evidence-original.json').read_text())
        self.state = recorded['frames'][-1]['public_before']
        self.ocr = recorded['frames'][-1]['observations']
        self.clock, self.reads, self.captures = 0.0, [], []

    def harness(self, *, missing_at=(), always_missing=False, layout_override=None, state_override=None):
        state = copy.deepcopy(self.state)
        state.update(state_override or {})

        def advance(seconds):
            self.clock += seconds

        def adb(*args, **kwargs):
            self.assertEqual(args, ('exec-out', 'cat',
                '/data/user/0/dev.ullmann.lumo.lumo_lernen.coachpreview/files/cards_layout_v1.json'))
            self.assertGreater(kwargs['timeout'], 0)
            self.assertLessEqual(kwargs['timeout'], 4)
            self.reads.append(args)
            advance(.025)
            if always_missing or len(self.reads) in missing_at:
                return self.missing
            return self.layout_raw if layout_override is None else json.dumps(layout_override)

        def capture(out, name, **kwargs):
            self.assertGreater(kwargs['timeout'], 0)
            self.captures.append(name)
            path = out / (name + '.png')
            path.write_bytes((FIXTURE / 'cards-before-original.png').read_bytes())
            advance(.1)
            return {'file': path.name}

        def image_lines(*_args, **_kwargs):
            advance(.025)
            return [copy.deepcopy(self.ocr[key]) for key in ('pause', 'page')]

        body = [node for node in ast.parse(SOURCE.read_text()).body
                if isinstance(node, ast.FunctionDef) and node.name in
                ('read_cards_layout', 'capture_cards_faces')]
        namespace = {'Path': Path, 'CardsMailbox': object, 'json': json, 're': re,
                     'PACKAGE': 'dev.ullmann.lumo.lumo_lernen.coachpreview',
                     'time': SimpleNamespace(monotonic=lambda: self.clock, sleep=advance),
                     'base': SimpleNamespace(adb=adb),
                     'probe': SimpleNamespace(capture=capture, image_lines=image_lines,
                         normalized=lambda text: text.lower(), inspect_surface=surfaces.inspect_surface,
                         digest=lambda path: hashlib.sha256(path.read_bytes()).hexdigest()),
                     'require_cards_layout': evidence.require_cards_layout,
                     'require_cards_face_pixels': evidence.require_cards_face_pixels}
        exec(compile(ast.Module(body=body, type_ignores=[]), str(SOURCE), 'exec'), namespace)
        box = SimpleNamespace(token=state['token'], read=lambda: copy.deepcopy(state))
        return namespace, box, state

    def test_original_missing_file_reply_is_saved_before_a_readiness_error(self):
        scope, box, _state = self.harness(always_missing=True)
        self.assertEqual(len(self.missing.encode()), 113)
        with self.assertRaisesRegex(RuntimeError, 'not yet available as complete JSON'):
            scope['read_cards_layout'](self.out, box, 'original', timeout=60)
        self.assertEqual((self.out / 'original-layout.json').read_bytes(),
                         (FIXTURE / 'missing-layout-original.txt').read_bytes())
        self.assertEqual(self.captures, [])

    def test_one_transient_missing_reply_still_requires_two_complete_stable_frames(self):
        scope, box, state = self.harness(missing_at=(1,))
        function = scope['capture_cards_faces']
        self.assertEqual(inspect.signature(function).parameters['timeout'].default, 60)
        returned, report = function(self.out, box, 'transient', state, self.layout['density'])
        self.assertEqual(returned, state)
        self.assertEqual(report['status'], 'PASS')
        self.assertEqual(report['consecutive_same_revision_frames'], 2)
        self.assertEqual([frame['status'] for frame in report['frames']],
                         ['REJECTED', 'VISIBLE_FRONT_ARTWORK', 'VISIBLE_FRONT_ARTWORK'])
        self.assertEqual(len(self.captures), 2)
        self.assertEqual(len(self.reads), 5)
        self.assertEqual((self.out / 'transient.png').read_bytes(),
                         (FIXTURE / 'cards-before-original.png').read_bytes())

    def test_missing_between_observations_resets_the_two_frame_requirement(self):
        scope, box, state = self.harness(missing_at=(3,))
        _, report = scope['capture_cards_faces'](self.out, box, 'gap', state, self.layout['density'])
        self.assertEqual([frame['status'] for frame in report['frames']],
                         ['VISIBLE_FRONT_ARTWORK', 'REJECTED',
                          'VISIBLE_FRONT_ARTWORK', 'VISIBLE_FRONT_ARTWORK'])
        self.assertEqual(len(self.captures), 3)
        self.assertEqual(report['consecutive_same_revision_frames'], 2)

    def test_persistent_missing_reply_expires_without_a_fallback_or_accepted_image(self):
        scope, box, state = self.harness(always_missing=True)
        with self.assertRaisesRegex(RuntimeError, 'before deadline'):
            scope['capture_cards_faces'](self.out, box, 'persistent', state,
                                         self.layout['density'], timeout=2)
        report = json.loads((self.out / 'persistent-face-evidence.json').read_text())
        self.assertEqual(report['status'], 'FAIL')
        self.assertGreater(len(report['frames']), 1)
        self.assertLessEqual(report['elapsed_seconds'], 2)
        self.assertTrue(all(frame['status'] == 'REJECTED' for frame in report['frames']))
        self.assertEqual(self.captures, [])
        self.assertFalse((self.out / 'persistent.png').exists())

    def test_valid_but_stale_layout_cannot_satisfy_the_current_public_revision(self):
        scope, box, state = self.harness(state_override={'revision': self.state['revision'] + 1})
        with self.assertRaisesRegex(RuntimeError, 'before deadline'):
            scope['capture_cards_faces'](self.out, box, 'stale', state,
                                         self.layout['density'], timeout=2)
        report = json.loads((self.out / 'stale-face-evidence.json').read_text())
        self.assertEqual(report['status'], 'FAIL')
        self.assertTrue(all('stale or changed public state' in frame['error']
                            for frame in report['frames']))
        self.assertFalse((self.out / 'stale.png').exists())

    def test_foreign_session_and_oversized_layout_remain_rejected(self):
        invalid = copy.deepcopy(self.layout)
        invalid['token'] = 'f' * 32
        scope, box, _ = self.harness(layout_override=invalid)
        with self.assertRaisesRegex(RuntimeError, 'another private session'):
            scope['read_cards_layout'](self.out, box, 'foreign', timeout=60)
        invalid['token'] = self.layout['token']
        invalid['oversized'] = 'x' * (128 * 1024)
        scope, box, _ = self.harness(layout_override=invalid)
        with self.assertRaisesRegex(RuntimeError, 'diagnostic bound'):
            scope['read_cards_layout'](self.out, box, 'oversized', timeout=60)
        self.assertEqual(self.captures, [])


if __name__ == '__main__':
    unittest.main()
