"""Logcat resilience: a failed transport is not evidence of speech success."""
from __future__ import annotations

import ast
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
from nextgen_evidence import require_learning_voice

PROBE = ROOT / '.github/probes/lumo_nextgen_surfaces_android_probe.py'
START = 'I/LumoLearningSpeech( 1234): started id=4 profile=lumo-free-supertonic-de-v1\n'
DONE = 'I/LumoLearningSpeech( 1234): completed id=4\n'
MOVE = 'I/godot( 1234): [LearningWorld] move kind=bridge_ten token=5 target=12 placed=5 complete=true\n'


class SpeechLogcatRecoveryTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.out = Path(folder.name)

    def capture(self, adb, *, after_final_move=False):
        body = [node for node in ast.parse(PROBE.read_text()).body
                if isinstance(node, ast.FunctionDef)
                and node.name in ('_speech_logcat', 'completed_native_speech')]
        scope = {'base': SimpleNamespace(adb=adb), 'time': SimpleNamespace(sleep=lambda _: None),
                 'Path': Path, 'require_learning_voice': require_learning_voice}

        def wait_for(description, observe, accept, *, timeout):
            self.assertEqual(timeout, 180)
            for _ in range(4):
                value = observe()
                if accept(value):
                    return value
            raise RuntimeError(description + ' not observed')

        scope['wait_for'] = wait_for
        exec(compile(ast.Module(body=body, type_ignores=[]), str(PROBE), 'exec'), scope)
        return scope['completed_native_speech'](self.out, after_final_move=after_final_move)

    def test_transient_adb_255_is_retried_without_approving_empty_speech(self):
        calls = []
        def adb(*args, timeout):
            calls.append((args, timeout))
            if len(calls) == 1:
                raise RuntimeError("Command failed (255): ('adb', 'logcat', '-d', '-v', 'brief')\nlogd broken pipe")
            return START + DONE
        report = self.capture(adb)
        self.assertEqual(report['completed_utterance_ids'], [4])
        self.assertEqual(report['native_process_pid'], 1234)
        self.assertEqual(len(calls), 2)
        self.assertTrue((self.out / 'learning-speech-logcat.txt').read_text().endswith(DONE))

    def test_only_relevant_speech_and_godot_tags_are_requested(self):
        seen = []
        def adb(*args, timeout):
            seen.append(args)
            return START + DONE
        self.capture(adb)
        self.assertEqual(len(seen), 1)
        self.assertEqual(seen[0][:4], ('logcat', '-d', '-v', 'brief'))
        self.assertIn('-s', seen[0])
        self.assertIn('LumoLearningSpeech:I', seen[0])
        self.assertIn('godot:I', seen[0])
        self.assertIn('*:S', seen[0])

    def test_final_speech_requires_move_then_new_started_and_completed_id(self):
        def adb(*args, timeout):
            return START + DONE + MOVE + START.replace('id=4', 'id=5') + DONE.replace('id=4', 'id=5')
        report = self.capture(adb, after_final_move=True)
        self.assertEqual(report['completed_utterance_ids'], [5])

    def test_native_movement_log_uses_same_bounded_transport_evidence(self):
        source = ast.parse(PROBE.read_text())
        roundtrip = next(node for node in source.body
                         if isinstance(node, ast.FunctionDef) and node.name == 'learning_roundtrip')
        movement = [node for node in ast.walk(roundtrip)
                    if isinstance(node, ast.Assign) and any(
                        isinstance(target, ast.Name) and target.id == 'movement_log'
                        for target in node.targets)]
        self.assertEqual(len(movement), 1)
        self.assertIsInstance(movement[0].value, ast.Call)
        self.assertIsInstance(movement[0].value.func, ast.Name)
        self.assertEqual(movement[0].value.func.id, '_speech_logcat')
        self.assertTrue(any(isinstance(node, ast.Call)
                            and isinstance(node.func, ast.Name)
                            and node.func.id == 'require_learning_bridge_moves'
                            for node in ast.walk(roundtrip)))

    def test_nontransport_failure_is_not_silently_retried(self):
        calls = []
        def adb(*args, timeout):
            calls.append(args)
            raise RuntimeError("Command failed (1): ('adb', 'logcat')")
        with self.assertRaisesRegex(RuntimeError, 'Command failed \(1\)'):
            self.capture(adb)
        self.assertEqual(len(calls), 1)

    def test_no_start_completion_or_repeated_transport_failure_is_not_a_pass(self):
        for response in ('', START):
            with self.subTest(response=response), self.assertRaises(RuntimeError):
                self.capture(lambda *args, **kwargs: response)
        calls = []
        def broken(*args, **kwargs):
            calls.append(1)
            raise RuntimeError("Command failed (255): ('adb', 'logcat')\ntransport lost")
        with self.assertRaises(RuntimeError):
            self.capture(broken)
        self.assertEqual(len(calls), 3)


if __name__ == '__main__':
    unittest.main()
