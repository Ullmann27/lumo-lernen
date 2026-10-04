"""Executable identity must survive renamed threads without weakening rejection."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from emulator_diagnostics import verify_emulator


class EmulatorIdentityTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.sdk = self.out/'sdk'
        root = self.sdk/'emulator'
        self.qemu = root/'qemu/linux-x86_64/qemu-system-x86_64'
        self.qemu.parent.mkdir(parents=True)
        self.qemu.write_text('pinned executable fixture')
        (root/'source.properties').write_text('Pkg.Revision=36.3.10\nPkg.BuildId=14472402\n')
        self.proc = self.out/'proc'
        self.proc.mkdir()
        self.add_process(42, self.qemu, 'MainLoop')
        self.results = [
            subprocess.CompletedProcess([], 0, 'libpulse.so.0 => /usr/lib/libpulse.so.0\n', ''),
            subprocess.CompletedProcess([], 0, 'Android emulator version 36.3.10.0 (build_id 14472402)\n', ''),
        ]

    def add_process(self, pid, executable, name):
        directory = self.proc/str(pid)
        directory.mkdir()
        (directory/'comm').write_text(name+'\n')
        (directory/'exe').symlink_to(executable)

    def verify(self):
        self.console = io.StringIO()
        with patch('emulator_diagnostics.subprocess.run', side_effect=self.results), contextlib.redirect_stdout(self.console):
            return verify_emulator(self.out, self.sdk, self.proc)

    def assert_rejected(self, count):
        with self.assertRaisesRegex(RuntimeError, 'Running QEMU'):
            self.verify()
        proof = json.loads((self.out/'emulator-version-proof.json').read_text())
        self.assertFalse(proof['passed'])
        self.assertEqual(len(proof['running_qemu']), count)
        self.assertEqual(json.loads(self.console.getvalue()), proof)

    def test_renamed_main_thread_matches_the_exact_pinned_executable(self):
        proof = self.verify()
        self.assertTrue(proof['passed'])
        self.assertEqual(proof['running_qemu'][0]['pid'], 42)
        self.assertEqual(proof['running_qemu'][0]['executable'], str(self.qemu))
        self.assertEqual(proof['running_qemu'][0]['name'], 'MainLoop')

    def test_same_basename_in_another_sdk_is_rejected_even_when_renamed(self):
        wrong = self.out/'other-sdk/qemu-system-x86_64'
        wrong.parent.mkdir()
        wrong.write_text('different executable')
        (self.proc/'42/exe').unlink()
        (self.proc/'42/exe').symlink_to(wrong)
        self.assert_rejected(1)

    def test_two_processes_using_the_pinned_binary_are_rejected(self):
        self.add_process(43, self.qemu, 'AnotherLoop')
        self.assert_rejected(2)

    def test_second_renamed_qemu_from_another_sdk_is_rejected(self):
        wrong = self.out/'qemu-system-aarch64'
        wrong.write_text('different emulator')
        self.add_process(43, wrong, 'OtherMainLoop')
        self.assert_rejected(2)

    def test_unrelated_process_is_not_counted_as_an_emulator(self):
        adb = self.out/'adb'
        adb.write_text('unrelated process fixture')
        self.add_process(43, adb, 'adb')
        proof = self.verify()
        self.assertTrue(proof['passed'])
        self.assertEqual([item['pid'] for item in proof['running_qemu']], [42])

    def test_spoofed_qemu_thread_name_cannot_hide_a_second_candidate(self):
        other = self.out/'not-the-pinned-binary'
        other.write_text('unrelated executable')
        self.add_process(43, other, 'qemu-system-x86')
        self.assert_rejected(2)

    def test_disappeared_only_emulator_is_rejected_with_visible_proof(self):
        (self.proc/'42/exe').unlink()
        self.assert_rejected(0)


if __name__ == '__main__':
    unittest.main()
