"""Actual PR483 launch failures and explicitly synthetic framing neighbors.

The original transcripts all contain END:1 and must remain rejected. Changing
that byte in a parser-only case is not an emulator, logger or Android success.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).with_name('fixtures') / 'console_launch_pr483'
SPEC = importlib.util.spec_from_file_location('console_launch_originals', ROOT / 'scripts/android_console_transport.py')
CONSOLE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONSOLE)
CASES = ('host', 'swiftshader', 'swangle')


class OriginalConsoleLaunchTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        provenance = json.loads((FIXTURES / 'provenance.json').read_bytes())
        if provenance['qa_head'] != '7e2ab20f6f323c66a1e02de3550d73ef31b2037e':
            raise AssertionError('Wrong actual PR483 source')
        for entry in provenance['files']:
            raw = (FIXTURES / entry['path']).read_bytes()
            if len(raw) != entry['bytes'] or hashlib.sha256(raw).hexdigest() != entry['sha256']:
                raise AssertionError('Original PR483 fixture differs: ' + entry['path'])

    def observation(self, name):
        folder = FIXTURES / name
        raw = (folder / 'transcript.stdout').read_bytes()
        token = json.loads((folder / 'config.json').read_bytes())['token']
        return raw, token

    def synthetic_success(self, name):
        raw, token = self.observation(name)
        original_end = f'\nLUMO_CONSOLE_END_{token}:1\r\n'.encode()
        self.assertEqual(raw.count(original_end), 1)
        changed_end = f'\nLUMO_CONSOLE_END_{token}:0\r\n'.encode()
        return raw.replace(original_end, changed_end), token

    def test_all_three_original_nonzero_launches_are_rejected_without_a_false_timeout(self):
        for name in CASES:
            with self.subTest(original=name):
                raw, token = self.observation(name)
                self.assertLess(raw.index(b'\r'), raw.index(b'\n'))
                self.assertIn(f'\nLUMO_CONSOLE_END_{token}:1\r\n'.encode(), raw)
                with self.assertRaisesRegex(ValueError, 'Console logger launch failed'):
                    CONSOLE.launch_frame(raw, token)

    def test_original_echo_and_input_never_count_as_an_acknowledgement(self):
        for name in CASES:
            with self.subTest(original=name):
                raw, token = self.observation(name)
                begin = f'\nLUMO_CONSOLE_BEGIN_{token}\r\n'.encode()
                self.assertIsNone(CONSOLE.launch_frame(raw[:raw.index(begin)], token))
                self.assertIsNone(CONSOLE.launch_frame((FIXTURES / name / 'command.stdin').read_bytes(), token))

    def test_synthetic_zero_frames_after_original_echo_preserve_exact_prefix_and_body(self):
        for name in CASES:
            with self.subTest(synthetic_from=name):
                raw, token = self.synthetic_success(name)
                begin = f'LUMO_CONSOLE_BEGIN_{token}\r\n'.encode()
                end = f'LUMO_CONSOLE_END_{token}:0\r\n'.encode()
                start = raw.index(b'\n' + begin) + 1
                end_start = raw.index(b'\n' + end) + 1
                frame = CONSOLE.launch_frame(raw, token)
                self.assertEqual(frame['returncode'], 0)
                self.assertEqual(frame['begin_offset'], start)
                self.assertEqual(frame['end_offset'], end_start + len(end))
                self.assertEqual(frame['interleaved_output'], CONSOLE.identity(raw[start + len(begin):end_start]))
                self.assertEqual(frame['acknowledged_prefix'], CONSOLE.identity(raw[:end_start + len(end)]))

    def test_incomplete_final_line_waits_for_its_actual_lf(self):
        raw, token = self.synthetic_success('swangle')
        end = f'LUMO_CONSOLE_END_{token}:0\r\n'.encode()
        stop = raw.index(b'\n' + end) + 1 + len(end)
        self.assertIsNone(CONSOLE.launch_frame(raw[:stop - 1], token))
        self.assertEqual(CONSOLE.launch_frame(raw[:stop], token)['end_offset'], stop)

    def test_bare_cr_does_not_create_a_new_marker_line(self):
        token = self.observation('host')[1]
        raw = f'echo-redraw\rLUMO_CONSOLE_BEGIN_{token}\r\nLUMO_CONSOLE_END_{token}:0\r\n'.encode()
        self.assertIsNone(CONSOLE.launch_frame(raw, token))

    def test_original_echo_does_not_hide_duplicate_or_reordered_frames(self):
        raw, token = self.synthetic_success('host')
        begin = f'LUMO_CONSOLE_BEGIN_{token}\r\n'.encode()
        end = f'LUMO_CONSOLE_END_{token}:0\r\n'.encode()
        echo = raw[:raw.index(b'\n' + begin) + 1]
        for case in (raw + begin, raw + end, echo + end + begin):
            with self.subTest(case=case[-100:]), self.assertRaises(ValueError):
                CONSOLE.launch_frame(case, token)

    def test_foreign_nonce_does_not_satisfy_the_actual_session(self):
        raw, token = self.synthetic_success('host')
        foreign = '0' * 32
        self.assertNotEqual(foreign, token)
        self.assertIsNone(CONSOLE.launch_frame(raw, foreign))


if __name__ == '__main__':
    unittest.main()
