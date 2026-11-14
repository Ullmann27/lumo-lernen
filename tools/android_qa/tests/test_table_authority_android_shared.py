"""Isolated adapter/source/deadline contracts; no Android or acceptance claim."""
from contextlib import redirect_stderr
import hashlib
import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[3]
HELPER_PATH = ROOT / '.github/probes/lumo_table_authority_android_shared.py'


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


SHARED = load('table_authority_shared_contract', HELPER_PATH)


class CommittedSourceContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='table-shared-source-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.paths = (SHARED.SELF, 'fixture.txt')
        helper = self.root / SHARED.SELF
        helper.parent.mkdir(parents=True)
        helper.write_bytes(b'# Test-only committed bytes, never executed.\n')
        (self.root / 'fixture.txt').write_bytes(b'original\n')
        self.git('init', '-q')
        self.git('add', '--', *self.paths)
        self.git('-c', 'user.name=Adapter contract', '-c', 'user.email=contract@example.invalid',
                 '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Isolated source fixture')
        self.head = self.git('rev-parse', 'HEAD').decode().strip()
        self.tree = self.git('rev-parse', 'HEAD^{tree}').decode().strip()

    def git(self, *arguments):
        result = subprocess.run(['git', '-C', str(self.root), *arguments],
                                capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        return result.stdout

    def binding(self, **changes):
        args = dict(root=self.root, expected=self.head, paths=self.paths,
                    deadline=time.monotonic() + 30, executing_file=self.root / SHARED.SELF)
        args.update(changes)
        return SHARED.checked_source_binding(**args)

    def test_actual_commit_tree_and_each_original_byte_are_bound(self):
        before_index = (self.root / '.git/index').read_bytes()
        result = self.binding()
        self.assertEqual((result['host'], result['tree']), (self.head, self.tree))
        self.assertEqual(result['source_sha256'], {
            path: hashlib.sha256((self.root / path).read_bytes()).hexdigest()
            for path in self.paths})
        self.assertEqual((self.root / '.git/index').read_bytes(), before_index)
        self.assertEqual(self.git('status', '--porcelain'), b'')

    def test_wrong_expected_commit_rejects_the_real_checkout(self):
        with self.assertRaisesRegex(RuntimeError, 'HEAD differs'):
            self.binding(expected='0' * 40)

    def test_tracked_source_mutation_is_rejected(self):
        (self.root / 'fixture.txt').write_bytes(b'changed\n')
        with self.assertRaisesRegex(RuntimeError, 'dirty'):
            self.binding()

    def test_index_hidden_working_mutation_still_fails_original_byte_check(self):
        self.git('update-index', '--assume-unchanged', 'fixture.txt')
        (self.root / 'fixture.txt').write_bytes(b'changed\n')
        self.assertEqual(self.git('status', '--porcelain'), b'')
        with self.assertRaisesRegex(RuntimeError, 'Working shared source differs'):
            self.binding()

    def test_helper_loaded_from_other_checkout_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'another checkout'):
            self.binding(executing_file=self.root / 'another-helper.py')

    def test_symlink_duplicate_and_traversal_inputs_are_rejected(self):
        (self.root / 'linked.txt').symlink_to(self.root / 'fixture.txt')
        for paths in [('linked.txt',), ('fixture.txt', 'fixture.txt'), ('../fixture.txt',)]:
            with self.subTest(paths=paths), self.assertRaises(RuntimeError):
                self.binding(paths=paths)

    def test_successful_git_read_at_or_after_deadline_is_not_accepted(self):
        for arrived in (1.0, 1.001):
            now = [0.0]
            def finished(*args, **kwargs):
                now[0] = arrived
                return subprocess.CompletedProcess(args[0], 0, (self.head + '\n').encode(), b'')
            with self.subTest(arrived=arrived), \
                    mock.patch.object(SHARED.time, 'monotonic', side_effect=lambda: now[0]), \
                    mock.patch.object(SHARED.subprocess, 'run', side_effect=finished), \
                    self.assertRaisesRegex(RuntimeError, 'deadline'):
                self.binding(deadline=1.0)


class RuntimeBoundaryContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='table-shared-observe-')
        self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        self.probe = object.__new__(SHARED.AndroidProbe)
        self.probe.out, self.probe.count = self.out, 0
        self.probe.deadline = 10.0

    def clock(self, now):
        return mock.patch.object(SHARED.time, 'monotonic', side_effect=lambda: now[0])

    def test_wait_accepts_only_observation_before_local_and_global_deadlines(self):
        now = [0.0]
        def observe():
            now[0] = .999
            return {'actual': 'synthetic observation'}
        with self.clock(now):
            self.assertEqual(self.probe.wait('on-time', observe, bool, timeout=1),
                             {'actual': 'synthetic observation'})
        self.assertEqual(list(self.out.iterdir()), [])

    def test_late_positive_observation_cannot_pass_either_deadline(self):
        for global_limit, local_limit, arrived in [(10, 1, 1), (10, 1, 1.001), (1, 8, 1)]:
            now = [0.0]
            self.probe.deadline = global_limit
            def observe():
                now[0] = arrived
                return True
            with self.subTest(global_limit=global_limit, local_limit=local_limit, arrived=arrived), \
                    self.clock(now), mock.patch.object(SHARED.time, 'sleep'), \
                    self.assertRaisesRegex(RuntimeError, 'before deadline'):
                self.probe.wait('late', observe, bool, timeout=local_limit)
        self.assertEqual(len(list(self.out.glob('*-failure.json'))), 3)

    def test_expired_init_performs_no_import_or_device_call(self):
        self.probe.deadline = 0.0
        with mock.patch.object(SHARED.time, 'monotonic', return_value=1), \
                mock.patch.object(SHARED.importlib, 'import_module') as imports, \
                mock.patch.object(SHARED.subprocess, 'run') as commands, \
                self.assertRaisesRegex(RuntimeError, 'deadline'):
            SHARED.AndroidProbe.__init__(self.probe, SimpleNamespace())
        imports.assert_not_called()
        commands.assert_not_called()
        self.assertEqual(list(self.out.iterdir()), [])

    def test_runtime_module_path_must_be_the_bound_candidate_path(self):
        expected = self.out / 'probe.py'
        module = SimpleNamespace(__file__=str(expected))
        self.assertIs(SHARED.bound_module(module, self.out, 'probe.py'), module)
        with self.assertRaisesRegex(RuntimeError, 'another checkout'):
            SHARED.bound_module(module, self.out, 'different.py')

    def test_single_positive_native_pid_is_required(self):
        for value in ('0', '23 24', '', '-1', '12\n13'):
            self.probe.adb = mock.Mock(return_value=value)
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                self.probe.pid()
        self.probe.adb = mock.Mock(return_value='123\n')
        self.assertEqual(self.probe.pid(), 123)
        self.probe.adb.assert_called_once_with('shell', 'pidof', SHARED.PACKAGE + ':lumo_game', check=False)

    def test_real_pck_stream_digest_is_required_and_duplicates_fail(self):
        path = self.out / 'test-only.apk'
        payload = b'test-only PCK bytes'
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr(SHARED.PCK_PATH, payload)
        digest = hashlib.sha256(payload).hexdigest()
        self.assertEqual(SHARED.verified_pck(path, digest), digest)
        with self.assertRaisesRegex(RuntimeError, 'differs'):
            SHARED.verified_pck(path, '0' * 64)
        with zipfile.ZipFile(path, 'a') as archive:
            archive.writestr(SHARED.PCK_PATH, payload)
        with self.assertRaisesRegex(RuntimeError, 'ambiguous'):
            SHARED.verified_pck(path, digest)

    def test_current_root_hub_semantics_and_ambiguous_controls_are_distinct(self):
        hub = [{'package': SHARED.PACKAGE, 'content-desc': 'Lumo Spielewelt'}]
        self.assertEqual(SHARED.flutter_hub_navigation_target(hub, [1080, 2400], 1),
                         {'action': 'hub_ready'})
        base = {'package': SHARED.PACKAGE, 'text': 'Spielen', 'clickable': 'true',
                'enabled': 'true', 'bounds': '[0,0][100,100]'}
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous'):
            SHARED.flutter_hub_navigation_target([base, {**base, 'bounds': '[100,0][200,100]'}],
                                                [1080, 2400], 1)

    def test_both_real_probe_modules_use_new_helper_without_loading_c4(self):
        c4_before = sys.modules.get('lumo_connect_four_android_probe')
        memory = load('new_shared_memory_import', ROOT / '.github/probes/lumo_memory_android_probe.py')
        with mock.patch.dict(sys.modules, {'lumo_table_authority_android_shared': SHARED}):
            quiz = load('new_shared_quiz_import', ROOT / '.github/probes/lumo_quiz_android_probe.py')
        self.assertEqual(Path(memory.common.__file__).resolve(), HELPER_PATH.resolve())
        self.assertIs(quiz.shared, SHARED)
        self.assertIs(quiz.QuizProbe.__mro__[1], SHARED.AndroidProbe)
        self.assertIs(sys.modules.get('lumo_connect_four_android_probe'), c4_before)
        self.assertTrue(callable(memory.common.project))
        self.assertTrue(callable(quiz.shared.button_target))

    def test_existing_output_is_rejected_before_any_runtime_construction(self):
        marker = self.out / 'original.txt'
        marker.write_bytes(b'original evidence')
        memory = load('new_shared_memory_output', ROOT / '.github/probes/lumo_memory_android_probe.py')
        with mock.patch.dict(sys.modules, {'lumo_table_authority_android_shared': SHARED}):
            quiz = load('new_shared_quiz_output', ROOT / '.github/probes/lumo_quiz_android_probe.py')
        arguments = []
        for key in ('candidate-source', 'native-source', 'apk', 'provenance', 'sums', 'tour-result'):
            arguments.extend(['--' + key, str(self.out / key)])
        arguments.extend(['--out', str(self.out), '--expected-source', 'a' * 40,
                          '--expected-native', 'b' * 40, '--expected-api', '35',
                          '--serial', 'emulator-5554'])
        for module, cls in ((memory, 'AndroidProbe'), (quiz, 'QuizProbe')):
            with self.subTest(probe=cls), mock.patch.object(module, cls) as construct, redirect_stderr(io.StringIO()):
                self.assertEqual(module.main(arguments), 2)
                construct.assert_not_called()
        self.assertEqual(marker.read_bytes(), b'original evidence')
        self.assertEqual(list(self.out.iterdir()), [marker])


if __name__ == '__main__':
    unittest.main()
