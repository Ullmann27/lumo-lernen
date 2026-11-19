"""Mesa course probe: the adbd root restart of run 44476731175 must not end the run.

The Mesa workflow failed with ``adb: unable to connect for root: closed`` right
after boot, before a single course was checked. That response is the documented
adbd restart; the shared helper recovers from exactly that response and still
requires a real UID 0 shell on a booted emulator.
"""
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
spec = importlib.util.spec_from_file_location('run_course_android_probe_under_test',
                                              HERE / 'run_course_android_probe.py')
course = importlib.util.module_from_spec(spec)
spec.loader.exec_module(course)
from rooted_emulator import ROOT_CLOSED, ensure_rooted_emulator  # noqa: E402


class FakeAdb:
    """Plays the adb answers observed in the failed Mesa run, then a real root shell."""

    def __init__(self, root_answer=(1, ROOT_CLOSED), uid='0'):
        self.root_answer = root_answer
        self.uid = uid
        self.calls = []

    def __call__(self, command, *, capture_output, text, timeout):
        self.calls.append(tuple(command))
        args = tuple(command[1:])
        if args == ('get-serialno',):
            return SimpleNamespace(returncode=0, stdout='emulator-5554\n', stderr='')
        if args == ('-s', 'emulator-5554', 'root'):
            code, message = self.root_answer
            return SimpleNamespace(returncode=code, stdout='', stderr=message + '\n')
        if args == ('-s', 'emulator-5554', 'wait-for-device'):
            return SimpleNamespace(returncode=0, stdout='', stderr='')
        if args == ('-s', 'emulator-5554', 'shell', 'id', '-u'):
            return SimpleNamespace(returncode=0, stdout=self.uid + '\n', stderr='')
        if args == ('-s', 'emulator-5554', 'shell', 'getprop', 'sys.boot_completed'):
            return SimpleNamespace(returncode=0, stdout='1\n', stderr='')
        raise AssertionError('unexpected adb call ' + repr(command))


class CourseProbeRootTests(unittest.TestCase):
    def ready(self, fake):
        adb = lambda *args, timeout: course.strict_adb(*args, timeout=timeout, run=fake)  # noqa: E731
        with tempfile.TemporaryDirectory() as folder:
            return ensure_rooted_emulator(adb, Path(folder), timeout=60,
                                          clock=iter(range(0, 10000)).__next__,
                                          sleep=lambda s: None)

    def test_observed_root_disconnect_is_recovered_with_real_uid0(self):
        state = self.ready(FakeAdb())
        self.assertEqual(state['status'], 'PASS')
        self.assertTrue(state['root_transport_recovered'])
        self.assertEqual(state['shell_uid'], 0)

    def test_production_image_refusal_still_fails(self):
        fake = FakeAdb(root_answer=(0, 'adbd cannot run as root in production builds'))
        with self.assertRaises(RuntimeError):
            self.ready(fake)

    def test_non_root_shell_is_never_reported_ready(self):
        with self.assertRaises(TimeoutError):
            self.ready(FakeAdb(uid='2000'))

    def test_error_text_matches_the_helper_format(self):
        fake = FakeAdb()
        with self.assertRaises(RuntimeError) as caught:
            course.strict_adb('-s', 'emulator-5554', 'root', run=fake)
        self.assertEqual(str(caught.exception).strip(),
                         "Command failed (1): ('adb', '-s', 'emulator-5554', 'root')\n" + ROOT_CLOSED)

    def test_main_no_longer_calls_bare_adb_root(self):
        source = (HERE / 'run_course_android_probe.py').read_text()
        self.assertNotIn('adb("root")', source)
        self.assertIn('ensure_rooted_emulator(strict_adb, OUT)', source)


if __name__ == '__main__':
    unittest.main()
