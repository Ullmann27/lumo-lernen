"""Read-only diagnostic contracts with explicit synthetic adb boundaries.

These tests do not establish Android readiness or pass the Cards pixel guards.
The real shell case verifies only the generated observation command on Linux.
"""
import ast
import contextlib
import io
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


ROOT = Path(__file__).resolve().parents[3]
PROBE = ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py'


class CardsLifecycleObservationTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-lifecycle-observation-')
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.token = 'a' * 32
        self.state = {'token': self.token, 'revision': 5, 'ack': 1, 'paused': False}
        self.lifecycle = {'active': True, 'stamp': 1794594678500, 'pauseEpoch': 2}
        self.raw = '1794594679000\n' + json.dumps(self.lifecycle) + '\n1794594679010\n'
        self.adb = Mock(side_effect=self.transport)
        scope = {'Path': Path, 'json': json, 're': re, 'shlex': shlex,
                 'time': time, 'sys': sys, 'PACKAGE': 'fictional.test',
                 'base': SimpleNamespace(adb=self.adb)}
        source = ast.parse(PROBE.read_text())
        node = next(node for node in source.body if isinstance(node, ast.ClassDef)
                    and node.name == 'CardsMailbox')
        exec(compile(ast.Module(body=[node], type_ignores=[]), str(PROBE), 'exec'), scope)
        self.box = scope['CardsMailbox'](self.out)
        self.box.token = self.token
        self.box.path = self.box.root + '/' + self.token

    def transport(self, *arguments, **kwargs):
        if arguments[:2] == ('exec-out', 'cat'):
            return json.dumps(self.state)
        self.assertEqual(arguments[0], 'exec-out')
        self.assertEqual(len(arguments), 2, 'One remote command, no nested argument splitting')
        self.assertGreater(kwargs['timeout'], 0)
        self.assertLessEqual(kwargs['timeout'], .75)
        self.assertEqual(arguments[1], "date '+%s%3N'; cat " +
                         shlex.quote(self.box.path + '/lifecycle.json') +
                         "; printf '\\n'; date '+%s%3N'")
        return self.raw

    def report(self):
        return json.loads((self.out / 'cards-lifecycle-001.json').read_text())

    def test_actual_state_read_remains_unchanged_and_observation_is_afterward(self):
        result = self.box.read()
        self.assertEqual(result, self.state)
        self.assertEqual(self.adb.call_args_list[0].args,
                         ('exec-out', 'cat', self.box.path + '/state.json'))
        report = self.report()
        self.assertEqual(report['status'], 'OBSERVED')
        self.assertTrue(report['sampled_after_state_read'])
        self.assertEqual(report['state_file'], 'cards-mailbox-001-state.json')
        self.assertEqual(report['lifecycle'], self.lifecycle)
        self.assertEqual((report['stamp_age_lower_ms'], report['stamp_age_upper_ms']), (500, 510))
        self.assertEqual((self.out / report['raw_source']).read_text(), self.raw)

    def test_pause_epoch_and_stale_timestamp_are_observed_never_repaired(self):
        self.lifecycle.update(active=False, stamp=1794594670000, pauseEpoch=7)
        self.raw = '1794594679000\n' + json.dumps(self.lifecycle) + '\n1794594679010\n'
        self.assertEqual(self.box.read(), self.state)
        self.assertEqual(self.report()['lifecycle'], self.lifecycle)
        self.assertEqual(self.report()['stamp_age_lower_ms'], 9000)
        self.assertEqual(len(self.adb.call_args_list), 2)
        self.assertTrue(all(call.args[0] == 'exec-out' for call in self.adb.call_args_list))

    def test_optional_adb_timeout_records_missing_without_masking_state(self):
        self.adb.side_effect = [json.dumps(self.state), TimeoutError('diagnostic adb deadline')]
        self.assertEqual(self.box.read(), self.state)
        self.assertEqual(self.report()['status'], 'MISSING')
        self.assertIn('diagnostic adb deadline', self.report()['error'])

    def test_malformed_lifecycle_keeps_raw_observation_and_original_state(self):
        for raw in ('missing\n', '1794594679000\n{}\n1794594679010\n',
                    '1794594679000\n{broken\n1794594679010\n'):
            with self.subTest(raw=raw):
                self.box.lifecycle_counter = 0
                self.raw = raw
                self.assertEqual(self.box.read(), self.state)
                self.assertEqual(self.report()['status'], 'MISSING')
                self.assertEqual((self.out / 'cards-lifecycle-001.txt').read_text(), raw)

    def test_original_state_transport_error_remains_the_raised_failure(self):
        original = RuntimeError('authoritative state read failed')
        self.adb.side_effect = [original, TimeoutError('optional lifecycle unavailable')]
        with self.assertRaises(RuntimeError) as caught:
            self.box.read()
        self.assertIs(caught.exception, original)
        self.assertIn('authoritative state read failed', self.report()['state_read_error'])
        self.assertIsNone(self.report()['state_file'])
        self.assertEqual(self.report()['status'], 'MISSING')

    def test_foreign_state_token_remains_rejected_with_available_diagnostics(self):
        self.state['token'] = 'b' * 32
        with self.assertRaisesRegex(RuntimeError, 'Cards mailbox identity changed'):
            self.box.read()
        self.assertEqual(self.report()['status'], 'OBSERVED')
        self.assertIn('Cards mailbox identity changed', self.report()['state_read_error'])

    def test_diagnostic_write_failure_is_logged_and_does_not_replace_state_error(self):
        original = RuntimeError('original state failure')
        self.adb.side_effect = [original, self.raw]
        real_write = Path.write_text

        def write(path, *args, **kwargs):
            if path.name == 'cards-lifecycle-001.json':
                raise OSError('diagnostic disk full')
            return real_write(path, *args, **kwargs)

        stderr = io.StringIO()
        with patch.object(Path, 'write_text', write), contextlib.redirect_stderr(stderr):
            with self.assertRaises(RuntimeError) as caught:
                self.box.read()
        self.assertIs(caught.exception, original)
        self.assertIn('diagnostic disk full', stderr.getvalue())
        self.assertIn('original state failure', stderr.getvalue())

    def test_request_reads_do_not_start_recursive_or_extra_observations(self):
        self.assertEqual(self.box.read('request'), self.state)
        self.assertEqual(self.adb.call_count, 1)
        self.assertFalse(list(self.out.glob('cards-lifecycle-*')))

    def test_unobserved_session_path_cannot_be_used_for_optional_shell_read(self):
        self.box.path += '; other-command'
        self.box._observe_lifecycle(None, None, 'synthetic invalid path')
        self.adb.assert_not_called()
        self.assertEqual(self.report()['status'], 'MISSING')

    def test_clock_reversal_is_saved_as_an_observation_not_hidden(self):
        self.raw = '1794594679010\n' + json.dumps(self.lifecycle) + '\n1794594679000\n'
        self.assertEqual(self.box.read(), self.state)
        self.assertFalse(self.report()['device_clock_ordered'])

    def test_generated_read_only_shell_command_executes_with_quoted_paths(self):
        self.box.root = str(self.out / "private session's files")
        self.box.path = self.box.root + '/' + self.token
        directory = Path(self.box.path)
        directory.mkdir(parents=True)
        lifecycle_file = directory / 'lifecycle.json'
        original = json.dumps(self.lifecycle).encode()
        lifecycle_file.write_bytes(original)
        commands = []

        def transport(*args, **kwargs):
            if args[:2] == ('exec-out', 'cat'):
                return json.dumps(self.state)
            commands.append(args[1])
            result = subprocess.run(['/bin/sh', '-c', args[1]], capture_output=True,
                                    text=True, check=True, timeout=kwargs['timeout'])
            return result.stdout

        self.adb.side_effect = transport
        self.assertEqual(self.box.read(), self.state)
        self.assertEqual(self.report()['status'], 'OBSERVED')
        self.assertEqual(lifecycle_file.read_bytes(), original)
        self.assertEqual(len(commands), 1)

    def test_established_cards_actions_and_deadline_pixel_guards_survive_layout_binding(self):
        original = ast.parse((ROOT / '.github/probes/lumo_nextgen_surfaces_android_probe.py').read_text())
        current = ast.parse(PROBE.read_text())
        names = {'cards_ready_to_draw', 'cards_display_density', 'cards_roundtrip'}
        functions = lambda tree: {node.name: ast.dump(node, include_attributes=False)
                                  for node in tree.body if isinstance(node, ast.FunctionDef)
                                  and node.name in names}
        self.assertEqual(set(functions(current)), names)
        self.assertEqual(functions(current), functions(original))
        capture = lambda tree: next(node for node in tree.body if isinstance(node, ast.FunctionDef)
                                    and node.name == 'capture_cards_faces')
        before, after = capture(original), capture(current)
        dump = lambda node: ast.dump(node, include_attributes=False)
        # The new layout binding is additive. Keep the original 60-second
        # budget, public-state/identity guards, exact OCR, viewport gate and
        # original pixel check. Do not silently replace this with a new oracle.
        self.assertEqual(dump(before.args), dump(after.args))
        current_nodes = {dump(node) for node in ast.walk(after)}
        for node in ast.walk(before):
            if isinstance(node, ast.If):
                # The original same-state comparison must remain even though
                # a same-layout comparison is now required alongside it.
                self.assertIn(dump(node.test), current_nodes)
            elif isinstance(node, ast.Raise):
                self.assertIn(dump(node), current_nodes)
        critical = {'probe.capture', 'probe.inspect_surface', 'probe.image_lines',
                    'time.sleep', 'require_cards_face_pixels'}

        def critical_calls(function):
            calls = set()
            for node in ast.walk(function):
                if isinstance(node, ast.Call) and ast.unparse(node.func) in critical:
                    # Only the new actual layout input is stripped here; every
                    # old positional/keyword parameter must stay identical.
                    normalized = ast.Call(func=node.func, args=node.args,
                        keywords=[value for value in node.keywords if value.arg != 'layout'])
                    calls.add(dump(normalized))
            return calls

        self.assertTrue(critical_calls(before) <= critical_calls(after))
        readbacks = [node for node in ast.walk(after) if isinstance(node, ast.Call)
                     and isinstance(node.func, ast.Name) and node.func.id == 'read_cards_layout']
        self.assertEqual(len(readbacks), 2, 'Both sides of the actual capture must read the layout')
        self.assertIn("previous_layout == binding['layout_sha256']", ast.unparse(after))
        self.assertIn("layout_before['source_sha256'] != layout_after['source_sha256']",
                      ast.unparse(after))


if __name__ == '__main__':
    unittest.main()
