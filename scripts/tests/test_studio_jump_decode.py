"""Actual PR483 screenrecord and corruption checks for the production decode block.

Only the three executable statements that decode, retain stderr, and enforce the
result are extracted from the real Jump method. No Android action is simulated
or claimed. FFmpeg and ffprobe are required; an absent binary is a hard error.
"""
from __future__ import annotations

import ast
import copy
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest


ROOT = Path(__file__).resolve().parents[2]
PROBE = ROOT / '.github/probes/studio_creative_android_probe.py'
FIXTURES = ROOT / 'scripts/tests/fixtures/studio_jump_decode_pr483'
MOVIE = FIXTURES / 'jump-actual-android.mp4'
MOVIE_SHA256 = '0ad7becc5b6572f74968aa99a5b6533219cb5a661b4458e13a984fb2c97236c8'


def actual_decode_block():
    """Compile the unchanged production guard along with its actual command."""
    tree = ast.parse(PROBE.read_text())
    jump = next(node for node in ast.walk(tree)
                if isinstance(node, ast.FunctionDef) and node.name == 'jump')
    index = next(i for i, node in enumerate(jump.body)
                 if isinstance(node, ast.Assign)
                 and any(isinstance(target, ast.Name) and target.id == 'decode'
                         for target in node.targets))
    body = copy.deepcopy(jump.body[index:index + 3])
    if not (isinstance(body[-1], ast.Expr)
            and isinstance(body[-1].value, ast.Call)
            and isinstance(body[-1].value.func, ast.Name)
            and body[-1].value.func.id == 'require'):
        raise AssertionError('The actual decode result guard must be included')
    require = copy.deepcopy(next(node for node in tree.body
                                 if isinstance(node, ast.FunctionDef)
                                 and node.name == 'require'))
    wrapper = ast.parse('def decode_original(self, movie):\n    pass\n').body[0]
    wrapper.body = body + [ast.Return(value=ast.Name(id='decode', ctx=ast.Load()))]
    module = ast.fix_missing_locations(ast.Module(body=[require, wrapper], type_ignores=[]))
    namespace = {'subprocess': subprocess}
    exec(compile(module, str(PROBE), 'exec'), namespace)
    return namespace['decode_original']


def video_packets(path: Path) -> dict:
    result = subprocess.run([
        'ffprobe', '-v', 'error', '-select_streams', 'v:0', '-count_frames',
        '-show_packets', '-show_streams', '-of', 'json', str(path),
    ], capture_output=True, timeout=120, check=True)
    if result.stderr.strip():
        raise AssertionError(result.stderr.decode(errors='replace'))
    return json.loads(result.stdout)


class StudioJumpDecodeOriginalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        for executable in ('ffmpeg', 'ffprobe'):
            if shutil.which(executable) is None:
                raise RuntimeError(f'{executable} is required for the original MP4 regression')
        if hashlib.sha256(MOVIE.read_bytes()).hexdigest() != MOVIE_SHA256:
            raise AssertionError('The actual PR483 MP4 must remain byte-identical')
        cls.decode = staticmethod(actual_decode_block())

    def test_actual_original_full_decode_has_no_error_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            out = Path(temporary)
            result = self.decode(SimpleNamespace(out=out), MOVIE)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stderr, b'')
            self.assertEqual((out / 'jump-full-decode.log').read_bytes(), b'')
        self.assertEqual(hashlib.sha256(MOVIE.read_bytes()).hexdigest(), MOVIE_SHA256)

    def test_all_original_packets_frames_and_action_coverage_are_present(self):
        evidence = video_packets(MOVIE)
        self.assertEqual(len(evidence['streams']), 1)
        stream = evidence['streams'][0]
        self.assertEqual((stream['width'], stream['height']), (540, 960))
        self.assertEqual(stream['time_base'], '1/90000')
        self.assertEqual(int(stream['nb_frames']), 144)
        self.assertEqual(int(stream['nb_read_frames']), 144)
        self.assertEqual(len(evidence['packets']), 144)
        for key in ('pts', 'dts'):
            stamps = [int(packet[key]) for packet in evidence['packets']]
            self.assertTrue(all(left < right for left, right in zip(stamps, stamps[1:])), key)
        recording = json.loads((FIXTURES / 'jump-recording.json').read_text())
        self.assertEqual([action['type'] for action in recording['actions']],
                         ['separate-stick', 'separate-stick', 'short-jump', 'held-jump'])
        required_end = max(action['start_seconds'] + action['duration_ms'] / 1000 + 1.2
                           for action in recording['actions'])
        self.assertGreaterEqual(float(stream['duration']), max(5, required_end))

    def test_corrupt_h264_packet_still_fails_the_production_guard(self):
        packet = video_packets(MOVIE)['packets'][0]
        start, length = int(packet['pos']), int(packet['size'])
        data = bytearray(MOVIE.read_bytes())
        self.assertGreater(length, 32)
        data[start:start + length] = b'\x00' * length
        with tempfile.TemporaryDirectory() as temporary:
            out = Path(temporary)
            bad = out / 'synthetic-corrupt-packet.mp4'
            bad.write_bytes(data)
            with self.assertRaisesRegex(RuntimeError, 'Actual Jump MP4 failed full decode'):
                self.decode(SimpleNamespace(out=out), bad)
            self.assertTrue((out / 'jump-full-decode.log').read_bytes().strip())
        self.assertEqual(hashlib.sha256(MOVIE.read_bytes()).hexdigest(), MOVIE_SHA256)

    def test_truncated_container_still_fails_the_production_guard(self):
        with tempfile.TemporaryDirectory() as temporary:
            out = Path(temporary)
            bad = out / 'synthetic-truncated.mp4'
            data = MOVIE.read_bytes()
            bad.write_bytes(data[:len(data) // 2])
            with self.assertRaisesRegex(RuntimeError, 'Actual Jump MP4 failed full decode'):
                self.decode(SimpleNamespace(out=out), bad)
            self.assertTrue((out / 'jump-full-decode.log').read_bytes().strip())


if __name__ == '__main__':
    unittest.main()
