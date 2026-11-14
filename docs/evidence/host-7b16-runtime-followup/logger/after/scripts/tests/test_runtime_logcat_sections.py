"""Actual probe functions with synthetic log records, never Android acceptance.

The old source can be selected explicitly to demonstrate that an un-cleared
earlier lesson was accepted. Both paths execute the original parser/functions;
no fixture is presented as newly recorded device speech.
"""
from __future__ import annotations

import ast
import hashlib
import inspect
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = Path(os.environ.get('LUMO_SPEECH_SECTION_SOURCE_ROOT', str(ROOT)))
STUDIO = SOURCE_ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py'
TOUR = SOURCE_ROOT / '.github/probes/modernization_android_tour.py'
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
from nextgen_evidence import require_learning_bridge_moves, require_learning_voice

TOKEN = 'a' * 32
MARKER = 'lumo-' + TOKEN + '-speech-' + 'b' * 32
BOUNDARY = 'I/LumoSpeechSection( 2310): ' + MARKER + '\n'
START = 'I/LumoLearningSpeech( 1234): started id=4 profile=lumo-free-supertonic-de-v1\n'
DONE = 'I/LumoLearningSpeech( 1234): completed id=4\n'
MOVES = ''.join(
    f'I/godot( 1234): [LearningWorld] move kind=bridge_ten token={index} '
    f'target={7 + index} placed={index} complete={str(index == 5).lower()}\n'
    for index in range(1, 6))


def functions(path, names, scope):
    selected = [node for node in ast.parse(path.read_text()).body
                if isinstance(node, ast.FunctionDef) and node.name in names]
    exec(compile(ast.Module(body=selected, type_ignores=[]), str(path), 'exec'), scope)
    return scope


class RuntimeLogcatSectionTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.raw = START + DONE + MOVES + BOUNDARY
        self.adb = Mock(side_effect=lambda *args, **kwargs: self.raw if args[0] == 'logcat' else '')
        self.scope = functions(STUDIO, {'_speech_logcat', 'completed_native_speech',
                                        '_start_learning_speech_section'}, {
            'Path': Path, 're': re, 'json': json,
            'base': SimpleNamespace(adb=self.adb),
            'time': SimpleNamespace(sleep=lambda _: None),
            'require_learning_voice': require_learning_voice,
            'wait_for': self.wait_for,
        })

    def wait_for(self, description, observe, accept, *, timeout):
        self.assertEqual(timeout, 180)
        for _ in range(2):
            value = observe()
            if accept(value):
                return value
        raise RuntimeError(description + ' not observed')

    def boundary(self):
        directory = self.out / 'reads'
        directory.mkdir(exist_ok=True)
        return {'marker': MARKER, 'out': directory, 'reads': 0}

    def speech(self, boundary, *, after_final_move=False):
        function = self.scope['completed_native_speech']
        # Before/after harness only: the original function has no boundary
        # parameter. It still executes unchanged and must reject old evidence.
        options = {'after_final_move': after_final_move}
        if 'boundary' in inspect.signature(function).parameters:
            options['boundary'] = boundary
        return function(self.out, **options)

    def test_earlier_completed_speech_is_not_current_evidence(self):
        with self.assertRaises(RuntimeError):
            self.speech(self.boundary())

    def test_earlier_movement_and_final_speech_cannot_satisfy_current_result(self):
        self.raw = MOVES + START + DONE + BOUNDARY
        with self.assertRaises(RuntimeError):
            self.speech(self.boundary(), after_final_move=True)

    def test_direct_movement_read_uses_only_the_same_fresh_section(self):
        result = self.scope['_speech_logcat'](boundary=self.boundary())
        with self.assertRaisesRegex(RuntimeError, 'observed 0'):
            require_learning_bridge_moves(result)

    def test_new_initial_moves_and_final_voice_pass_with_original_pid_and_ids(self):
        boundary = self.boundary()
        old = START + DONE + MOVES
        self.raw = old + BOUNDARY + START + DONE
        initial = self.speech(boundary)
        self.raw += MOVES + START.replace('id=4', 'id=5') + DONE.replace('id=4', 'id=5')
        movement = self.scope['_speech_logcat'](boundary=boundary)
        self.assertEqual(require_learning_bridge_moves(movement)['moved_objects'], 5)
        final = self.speech(boundary, after_final_move=True)
        self.assertEqual(initial['native_process_pid'], final['native_process_pid'])
        self.assertEqual(initial['completed_utterance_ids'], [4])
        self.assertEqual(final['completed_utterance_ids'], [5])
        raw_reads = sorted((self.out / 'reads').glob('*-full-filtered-logcat.txt'))
        self.assertEqual(len(raw_reads), 3)
        self.assertEqual(raw_reads[-1].read_text(), self.raw)
        self.assertTrue(raw_reads[-1].read_text().startswith(old))
        self.assertNotIn(('logcat', '-c'), [call.args for call in self.adb.call_args_list])

    def test_missing_duplicate_or_changed_marker_fails_closed(self):
        for raw in (START + DONE, BOUNDARY + START + DONE + BOUNDARY):
            with self.subTest(raw=raw):
                self.raw = raw
                boundary = self.boundary()
                boundary['reads'] = len(list(boundary['out'].glob('*.txt')))
                with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous'):
                    self.scope['_speech_logcat'](boundary=boundary)
        self.raw = BOUNDARY + START + DONE
        boundary = self.boundary()
        boundary['reads'] = len(list(boundary['out'].glob('*.txt')))
        self.scope['_speech_logcat'](boundary=boundary)
        self.raw = self.raw.replace('( 2310)', '( 2311)')
        with self.assertRaisesRegex(RuntimeError, 'boundary changed'):
            self.scope['_speech_logcat'](boundary=boundary)

    def test_section_is_positively_observed_before_return_and_raw_read_preserved(self):
        with patch('secrets.token_hex', return_value='b' * 32):
            boundary = self.scope['_start_learning_speech_section'](
                self.out, {'token': TOKEN, 'runtime_start_sha256': 'c' * 64})
        self.assertEqual(self.adb.call_args_list[0].args,
                         ('shell', 'log', '-p', 'i', '-t', 'LumoSpeechSection', MARKER))
        self.assertEqual(boundary['observed_line'], BOUNDARY)
        self.assertEqual((boundary['out'] / '0001-full-filtered-logcat.txt').read_text(), self.raw)
        proof = json.loads((boundary['out'] / 'observed-start.json').read_text())
        self.assertEqual(proof['observed_line'], BOUNDARY)

    def test_successful_marker_write_without_actual_readback_is_rejected(self):
        self.raw = START + DONE
        with patch('secrets.token_hex', return_value='b' * 32):
            with self.assertRaisesRegex(RuntimeError, 'boundary.*missing'):
                self.scope['_start_learning_speech_section'](self.out, {'token': TOKEN})
        self.assertFalse((self.out / 'learning-speech-section/observed-start.json').exists())

    def test_all_three_production_readers_receive_the_same_boundary(self):
        tree = ast.parse(STUDIO.read_text())
        lesson = next(node for node in tree.body
                      if isinstance(node, ast.FunctionDef) and node.name == 'learning_roundtrip')
        calls = [node for node in ast.walk(lesson) if isinstance(node, ast.Call)
                 and isinstance(node.func, ast.Name)
                 and node.func.id in ('completed_native_speech', '_speech_logcat')]
        self.assertEqual(len(calls), 3)
        for call in calls:
            keywords = {item.arg: item.value for item in call.keywords}
            self.assertEqual(ast.dump(keywords['boundary']), "Name(id='boundary', ctx=Load())")
        self.assertIn("initial_voice['native_process_pid'] != final_voice['native_process_pid']",
                      ast.unparse(lesson))
        self.assertIn("min(final_voice['completed_utterance_ids']) <= max(initial_voice['completed_utterance_ids'])",
                      ast.unparse(lesson))

    def context_fixture(self):
        path = self.out / 'runtime-anr/runtime-start.json'
        device_path = path.parent / 'device-logger/start.json'
        device_path.parent.mkdir(parents=True)
        device = {'status': 'PASS', 'errors': [], 'token': TOKEN, 'serial': 'emulator-5554',
                  'root': {'uid_after': '0', 'boot_completed': '1'}}
        device_path.write_text(json.dumps(device))
        raw = device_path.read_bytes()
        start = {'recording_protocol': 'independent-device-session-v1',
                 'root_prepared_before_installation': True, 'serial': 'emulator-5554',
                 'device_start': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}}
        path.write_text(json.dumps(start))
        adb = Mock(side_effect=lambda *args: 'emulator-5554' if args == ('get-serialno',) else '37')
        scope = functions(TOUR, {'diagnostic_logcat_context'}, {
            'Path': Path, 'os': os, 'json': json, 're': re, 'base': SimpleNamespace(adb=adb)})
        return path, start, adb, scope['diagnostic_logcat_context']

    def test_preservation_requires_own_positive_source_bound_api37_context(self):
        path, start, adb, context = self.context_fixture()
        with patch.dict(os.environ, {}, clear=True):
            self.assertIsNone(context(self.out))
            adb.assert_not_called()
        with patch.dict(os.environ, {'LUMO_RUNTIME_ANR_START': str(path)}, clear=True):
            proof = context(self.out)
            self.assertEqual(proof['token'], TOKEN)
            self.assertEqual(proof['runtime_start_sha256'], hashlib.sha256(path.read_bytes()).hexdigest())
            adb.side_effect = lambda *args: 'emulator-5554' if args == ('get-serialno',) else '35'
            with self.assertRaisesRegex(RuntimeError, 'same actual API37'):
                context(self.out)
            adb.side_effect = lambda *args: 'emulator-5556' if args == ('get-serialno',) else '37'
            with self.assertRaisesRegex(RuntimeError, 'same actual API37'):
                context(self.out)
            start['device_start']['sha256'] = '0' * 64
            path.write_text(json.dumps(start))
            with self.assertRaisesRegex(RuntimeError, 'bound active interval'):
                context(self.out)

    def test_completed_or_foreign_interval_never_silently_selects_preservation(self):
        path, _, _, context = self.context_fixture()
        with patch.dict(os.environ, {'LUMO_RUNTIME_ANR_START': str(path)}, clear=True):
            (path.parent / 'runtime-end.json').write_text('{}')
            with self.assertRaisesRegex(RuntimeError, 'bound active interval'):
                context(self.out)
            with self.assertRaises((RuntimeError, FileNotFoundError)):
                context(self.out / 'other-tour')

    def test_existing_clear_calls_are_conditional_and_runner_enables_only_api37(self):
        for path, condition in ((TOUR, 'diagnostic_logcat_context(out) is None'),
                                (STUDIO, 'context is None')):
            tree = ast.parse(path.read_text())
            clear_nodes = [node for node in ast.walk(tree) if isinstance(node, ast.If)
                           and ast.unparse(node.test) == condition
                           and any(isinstance(child, ast.Call) and isinstance(child.func, ast.Attribute)
                                   and child.func.attr == 'adb' and len(child.args) >= 2
                                   and all(isinstance(arg, ast.Constant) for arg in child.args[:2])
                                   and [arg.value for arg in child.args[:2]] == ['logcat', '-c']
                                   for block in node.body for child in ast.walk(block))]
            self.assertEqual(len(clear_nodes), 1, str(path))
        runner = (ROOT / 'scripts/run_unchanged_apk_diagnostic.sh').read_text()
        branch = runner[runner.index('if [[ "$diagnostic_case" == api37-* ]]; then'):]
        self.assertIn('export LUMO_RUNTIME_ANR_START="$diagnostic_out/runtime-anr/runtime-start.json"', branch)
        self.assertLess(branch.index('--preserve-through-adb-root'), branch.index('export LUMO_RUNTIME_ANR_START='))


if __name__ == '__main__':
    unittest.main()
