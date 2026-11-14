"""Original PR486 failures and local literal-writer contracts.

The local shell executes only the payload-writing fragment, never the Android
launcher or logger. It is not Android mksh and proves no console/root survival.
"""
from __future__ import annotations

import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).with_name('fixtures') / 'console_launch_pr486'
SPEC = importlib.util.spec_from_file_location('console_printf_framework', ROOT / 'scripts/android_framework_ready.py')
FRAMEWORK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(FRAMEWORK)
CASES = ('host', 'swiftshader', 'swangle')
REMOTE = '/data/local/tmp/lumo-runtime-' + 'a' * 32


class ConsoleLoggerPrintfTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        provenance = json.loads((FIXTURES / 'provenance.json').read_bytes())
        if (provenance['qa_source'], provenance['run_id'], provenance['run_attempt']) != (
                '6bf22513facf2292233e05914609089b759e0cd4', 43570856914, 1):
            raise AssertionError('Wrong original PR486 failure source')
        for entry in provenance['files']:
            raw = (FIXTURES / entry['path']).read_bytes()
            if len(raw) != entry['bytes'] or hashlib.sha256(raw).hexdigest() != entry['sha256']:
                raise AssertionError('Original fixture differs: ' + entry['path'])

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='console-printf-contract-')
        self.addCleanup(temporary.cleanup)
        self.temp = Path(temporary.name)
        self.recorded = 0

    def sections(self, program, remote):
        marker = "printf '%s\\n' \"$1\" > " + remote + '/console.pid\n'
        start = program.index(marker) + len(marker)
        end = program.index('/system/bin/toybox nohup ', start)
        return program[:start], program[start:end], program[end:]

    def writer(self, program, remote, payload):
        _, fragment, _ = self.sections(program, remote)
        self.assertTrue(fragment.startswith("printf '%s' "),
                        'The original here-document writer must be replaced before literal parsing')
        self.assertEqual(shlex.split(fragment), ['printf', '%s', payload, '>', remote + '/run.sh'])
        suffix = ' > ' + remote + '/run.sh\n'
        self.assertTrue(fragment.endswith(suffix))
        self.assertNotIn('<<', fragment.splitlines()[0])
        return fragment[:-len(suffix)]

    def run_writer(self, command, output):
        shell = shutil.which('sh')
        self.assertIsNotNone(shell, 'A local POSIX shell is required for the literal byte contract')
        # Deliberately unusable tempfile location. This is not an Android mksh
        # reproduction: the actual Android failures remain original fixtures.
        argv = [shell, '-c', command + ' > "$1"', 'literal-payload-contract', str(output)]
        result = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                timeout=5, env={**os.environ, 'TMPDIR': '/proc/lumo-printf-no-tempfiles'})
        if destination := os.environ.get('LUMO_PRINTF_CONTRACT_EVIDENCE'):
            self.recorded += 1
            folder = Path(destination) / f'{self._testMethodName}-{self.recorded:02d}'
            folder.mkdir(parents=True, exist_ok=False)
            (folder / 'stdout').write_bytes(result.stdout)
            (folder / 'stderr').write_bytes(result.stderr)
            written = output.read_bytes() if output.is_file() else None
            if written is not None:
                (folder / 'written.payload').write_bytes(written)
            (folder / 'execution.json').write_text(json.dumps({
                'command': argv, 'returncode': result.returncode, 'timeout_seconds': 5,
                'tmpdir': '/proc/lumo-printf-no-tempfiles',
                'written_bytes': None if written is None else len(written),
                'written_sha256': None if written is None else hashlib.sha256(written).hexdigest(),
                'scope': 'Local POSIX writer fragment only; no Android/mksh/logger execution',
            }, indent=2) + '\n')
        return result

    def test_three_original_tempfile_failures_and_nonzero_frames_remain_failures(self):
        for case in CASES:
            with self.subTest(original=case):
                folder = FIXTURES / case
                program = (folder / 'program.sh').read_text()
                stderr = (folder / 'launch-stderr.stdout').read_bytes()
                self.assertRegex(stderr, rb"^/system/bin/sh: <stdin>\[31\]: can't create temporary file /data/local/sh[a-z0-9]+\.tmp: Permission denied\n$")
                self.assertIn("<<'LUMO_LOGGER_SOURCE'", program)
                token = json.loads((folder / 'config.json').read_bytes())['token']
                transcript = (folder / 'transcript.stdout').read_bytes()
                self.assertIn(('LUMO_CONSOLE_END_' + token + ':1\r\n').encode(), transcript)
                with self.assertRaisesRegex(ValueError, 'Console logger launch failed'):
                    FRAMEWORK.CONSOLE.launch_frame(transcript, token)

    def test_each_original_payload_path_and_surrounding_launch_program_are_preserved(self):
        for case in CASES:
            with self.subTest(original=case):
                original = (FIXTURES / case / 'program.sh').read_text()
                remote = re.search(r'/data/local/tmp/lumo-runtime-[0-9a-f]{32}', original)[0]
                payload = FRAMEWORK.device_logger_script(remote)
                old_prefix, old_writer, old_suffix = self.sections(original, remote)
                self.assertEqual(old_writer, 'cat > ' + remote + "/run.sh <<'LUMO_LOGGER_SOURCE'\n" + payload + 'LUMO_LOGGER_SOURCE\n')
                current = FRAMEWORK.device_logger_launch(remote)
                new_prefix, _, new_suffix = self.sections(current, remote)
                self.assertEqual(new_prefix, old_prefix)
                self.assertEqual(new_suffix, old_suffix)
                command = self.writer(current, remote, payload)
                output = self.temp / (case + '.payload')
                result = self.run_writer(command, output)
                self.assertEqual((result.returncode, result.stdout, result.stderr), (0, b'', b''))
                self.assertEqual(output.read_bytes(), payload.encode())

    def test_quotes_substitutions_format_directives_and_newlines_are_literal_bytes(self):
        sentinel = self.temp / 'must-not-be-created'
        values = (
            "single ' and double \" quote; dollar $HOME and ${HOME}\n",
            '$(touch ' + shlex.quote(str(sentinel)) + ') `touch ' + shlex.quote(str(sentinel)) + '`\n',
            '-n %s %b \\n \\c $((1+2))',
            'Grüße\n\n',
        )
        for index, payload in enumerate(values):
            with self.subTest(payload=index), mock.patch.object(FRAMEWORK, 'device_logger_script', return_value=payload):
                command = self.writer(FRAMEWORK.device_logger_launch(REMOTE), REMOTE, payload)
                output = self.temp / f'literal-{index}'
                result = self.run_writer(command, output)
                self.assertEqual((result.returncode, result.stdout, result.stderr), (0, b'', b''))
                self.assertEqual(output.read_bytes(), payload.encode())
                self.assertFalse(sentinel.exists())

    def test_real_output_failure_is_nonzero_and_cannot_create_payload(self):
        command = self.writer(FRAMEWORK.device_logger_launch(REMOTE), REMOTE,
                              FRAMEWORK.device_logger_script(REMOTE))
        output = self.temp / 'missing-parent' / 'run.sh'
        result = self.run_writer(command, output)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(result.stderr)
        self.assertFalse(output.exists())

    def test_invalid_remote_paths_remain_rejected_before_any_shell_execution(self):
        for remote in ('/tmp/foreign', REMOTE + ';touch /tmp/foreign', REMOTE + '/../foreign',
                       REMOTE + "'", REMOTE + '\n', ''):
            with self.subTest(remote=remote), self.assertRaises(ValueError):
                FRAMEWORK.device_logger_launch(remote)

    def test_canonical_console_input_encodes_exact_program_with_unchanged_limits(self):
        program = FRAMEWORK.device_logger_launch(REMOTE).encode()
        command = FRAMEWORK.CONSOLE.command_bytes(program, 'a' * 32)
        self.assertEqual(command.count(b'\n'), 1)
        self.assertIn(base64.b64encode(program), command)
        self.assertIn(b'/system/bin/sh -s -- "$$"', command)
        self.assertLessEqual(len(command), 4096)
        self.assertIsNone(FRAMEWORK.CONSOLE.launch_frame(command, 'a' * 32))


if __name__ == '__main__':
    unittest.main()
