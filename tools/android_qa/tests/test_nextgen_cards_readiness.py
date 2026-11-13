"""Probe race regressions with synthetic clocks/mailboxes; no Android PASS.

The production screenshot/target geometry checks run on small synthetic images.
OCR and Android input are explicit test doubles. No fixture is game evidence.
"""
import ast
import copy
import json
from pathlib import Path
import re
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_surface_readiness import inspect_surface, target_observation


ROOT = Path(__file__).resolve().parents[3]
PROBE = ROOT / '.github/probes/lumo_nextgen_surfaces_android_probe.py'


class NextgenCardsReadinessTests(unittest.TestCase):
    def scenario(self, *, paused=True):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        out = Path(directory.name)
        clock = SimpleNamespace(now=0.0)

        def sleep(seconds):
            clock.now += seconds

        clock.sleep = sleep
        clock.monotonic = lambda: clock.now
        state = {'protocol': 1, 'token': 'a' * 32, 'roundId': 'cards-' + 'b' * 32,
                 'viewer': 0, 'current': 0, 'phase': 'playing', 'paused': paused,
                 'canDraw': not paused, 'revision': 2, 'ack': 0}
        box = SimpleNamespace(token=state['token'], state=state, request=None,
                              before_read=None, reads=0)

        def read(name='state'):
            if name == 'request':
                if box.request is None:
                    raise RuntimeError('No actual resume request was written')
                return copy.deepcopy(box.request)
            box.reads += 1
            if box.before_read is not None:
                box.before_read(box.reads)
            return copy.deepcopy(box.state)

        box.read = read
        surface = SimpleNamespace(partial=False)

        def capture(destination, tag, timeout):
            self.assertGreater(timeout, 0)
            clock.now += .1
            image = Image.new('RGB', (192, 108), (20, 40, 60))
            if surface.partial:
                image.paste('black', (100, 0, 192, 108))
            path = destination / (tag + '.png')
            image.save(path)
            return {'file': path.name}

        def ocr(*_args, **kwargs):
            self.assertTrue(kwargs['exact'])
            self.assertTrue(kwargs['source_path'].is_file())
            clock.now += .1
            return [{'text': 'Weiterspielen', 'bounds': [60, 35, 120, 50]}]

        def touch(*args, **kwargs):
            self.assertEqual(args, ('shell', 'input', 'swipe', '90', '42', '90', '42', '120'))
            self.assertGreater(kwargs['timeout'], 0)
            box.request = {'token': box.token, 'action': 'resume',
                           'revision': box.state['revision'], 'sequence': box.state['ack'] + 1}
            box.state.update(paused=False, canDraw=True,
                             revision=box.state['revision'] + 1, ack=box.request['sequence'])

        probe = SimpleNamespace(
            capture=Mock(side_effect=capture), inspect_surface=inspect_surface,
            image_lines=Mock(side_effect=ocr), target_observation=target_observation,
            normalized=lambda value: re.sub('[^a-z0-9]', '', value.lower()),
            digest=lambda path: inspect_surface(path)['source_sha256'])
        adb = Mock(side_effect=touch)
        scope = {'Path': Path, 'CardsMailbox': object, 'json': json, 're': re,
                 'time': clock, 'probe': probe, 'base': SimpleNamespace(adb=adb)}
        body = [node for node in ast.parse(PROBE.read_text()).body
                if isinstance(node, ast.FunctionDef) and
                node.name in {'cards_ready_to_draw', 'wait_for'}]
        exec(compile(ast.Module(body=body, type_ignores=[]), str(PROBE), 'exec'), scope)
        return SimpleNamespace(out=out, clock=clock, box=box, probe=probe, adb=adb,
                               surface=surface, run=scope['cards_ready_to_draw'])

    def test_already_active_child_turn_never_searches_for_or_touches_resume(self):
        env = self.scenario(paused=False)
        state, report = env.run(env.out, env.box)
        self.assertTrue(state['canDraw'])
        self.assertEqual(report['mode'], 'active_without_resume_touch')
        env.probe.capture.assert_not_called()
        env.probe.image_lines.assert_not_called()
        env.adb.assert_not_called()

    def test_heartbeat_resume_during_ocr_discards_even_a_found_old_button(self):
        env = self.scenario()
        original_ocr = env.probe.image_lines.side_effect

        def resume_during_ocr(*args, **kwargs):
            found = original_ocr(*args, **kwargs)
            env.box.state.update(paused=False, canDraw=True, revision=3)
            return found

        env.probe.image_lines.side_effect = resume_during_ocr
        _, report = env.run(env.out, env.box)
        self.assertTrue(report['frames'][0]['state_changed_during_ocr'])
        self.assertIsNone(report['touch'])
        self.assertEqual(report['mode'], 'active_without_resume_touch')
        env.adb.assert_not_called()

    def test_heartbeat_resume_without_caption_does_not_wait_for_vanished_modal(self):
        env = self.scenario()

        def gone(*_args, **_kwargs):
            env.box.state.update(paused=False, canDraw=True, revision=3)
            return []

        env.probe.image_lines.side_effect = gone
        state, report = env.run(env.out, env.box)
        self.assertFalse(state['paused'])
        self.assertLess(report['elapsed_seconds'], 1)
        env.adb.assert_not_called()

    def test_resume_between_second_observation_and_touch_discards_coordinates(self):
        env = self.scenario()

        def before_touch(read):
            if read == 5:
                env.box.state.update(paused=False, canDraw=True, revision=3)

        env.box.before_read = before_touch
        _, report = env.run(env.out, env.box)
        self.assertEqual(len(report['frames']), 2)
        self.assertTrue(report['frames'][-1]['state_changed_before_touch'])
        env.adb.assert_not_called()

    def test_still_paused_requires_two_current_targets_one_touch_and_real_ack(self):
        env = self.scenario()
        state, report = env.run(env.out, env.box)
        self.assertEqual(env.probe.capture.call_count, 2)
        self.assertEqual(env.adb.call_count, 1)
        self.assertEqual(report['mode'], 'native_resume_acknowledged')
        self.assertEqual(report['resume_request'],
                         {'token': env.box.token, 'action': 'resume', 'revision': 2, 'sequence': 1})
        self.assertEqual((state['revision'], state['ack'], state['paused']), (3, 1, False))
        saved = json.loads((env.out / 'cards-initial-readiness.json').read_text())
        self.assertEqual(saved, report)

    def test_revision_change_during_ocr_requires_two_new_targets(self):
        env = self.scenario()
        original_ocr = env.probe.image_lines.side_effect

        def revise_once(*args, **kwargs):
            found = original_ocr(*args, **kwargs)
            if env.probe.image_lines.call_count == 1:
                env.box.state['revision'] = 3
            return found

        env.probe.image_lines.side_effect = revise_once
        _, report = env.run(env.out, env.box)
        self.assertEqual(env.probe.capture.call_count, 3)
        self.assertEqual(report['resume_request']['revision'], 3)
        self.assertEqual(env.adb.call_count, 1)

    def test_unpaused_bot_turn_is_not_mistaken_for_a_drawable_child_turn(self):
        env = self.scenario(paused=False)
        env.box.state.update(current=1, canDraw=False)

        def bot_finished(read):
            if read == 3:
                env.box.state.update(current=0, canDraw=True, revision=3)

        env.box.before_read = bot_finished
        state, _ = env.run(env.out, env.box)
        self.assertEqual(env.box.reads, 3)
        self.assertEqual(state['current'], 0)
        env.adb.assert_not_called()

    def test_missing_caption_or_partial_surface_never_authorizes_a_touch(self):
        for partial in (False, True):
            with self.subTest(partial=partial):
                env = self.scenario()
                env.surface.partial = partial
                env.probe.image_lines.side_effect = lambda *_args, **_kwargs: []
                with self.assertRaisesRegex(TimeoutError, 'current resume control'):
                    env.run(env.out, env.box, timeout=2)
                env.adb.assert_not_called()
                if partial:
                    env.probe.image_lines.assert_not_called()
                saved = json.loads((env.out / 'cards-initial-readiness.json').read_text())
                self.assertEqual(saved['status'], 'FAIL')

    def test_touch_without_fresh_exact_resume_request_fails(self):
        for field, value in (('action', 'draw'), ('revision', 1), ('token', 'c' * 32),
                             ('sequence', 0), ('sequence', True)):
            with self.subTest(field=field, value=value):
                env = self.scenario()
                original_touch = env.adb.side_effect

                def invalid_request(*args, **kwargs):
                    original_touch(*args, **kwargs)
                    env.box.request[field] = value

                env.adb.side_effect = invalid_request
                with self.assertRaisesRegex(RuntimeError, 'fresh resume request'):
                    env.run(env.out, env.box)
                self.assertEqual(env.adb.call_count, 1)

    def test_unacknowledged_touch_or_unchanged_revision_cannot_pass(self):
        for field, value in (('ack', 0), ('revision', 2), ('paused', True)):
            with self.subTest(field=field):
                env = self.scenario()
                original_touch = env.adb.side_effect

                def missing_transition(*args, **kwargs):
                    original_touch(*args, **kwargs)
                    env.box.state[field] = value

                env.adb.side_effect = missing_transition
                with self.assertRaisesRegex(RuntimeError, 'acknowledged native resume'):
                    env.run(env.out, env.box, timeout=4)
                self.assertEqual(env.adb.call_count, 1)

    def test_session_replacement_during_ocr_is_a_failure_not_resume(self):
        env = self.scenario()

        def replaced(*_args, **_kwargs):
            env.box.state.update(roundId='cards-' + 'c' * 32, paused=False, canDraw=True)
            return []

        env.probe.image_lines.side_effect = replaced
        with self.assertRaisesRegex(RuntimeError, 'session changed'):
            env.run(env.out, env.box)
        env.adb.assert_not_called()

    def test_completed_round_is_reported_instead_of_an_ipc_timeout(self):
        env = self.scenario(paused=False)
        env.box.state.update(phase='gameOver', canDraw=False)
        with self.assertRaisesRegex(RuntimeError, 'round ended'):
            env.run(env.out, env.box)
        env.adb.assert_not_called()


if __name__ == '__main__':
    unittest.main()
