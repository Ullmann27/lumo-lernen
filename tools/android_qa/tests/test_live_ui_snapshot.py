"""The live hierarchy reader observes real UI and cannot target a physical device."""
from pathlib import Path
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from fresh_ui_hierarchy import read_fresh_hierarchy
from prepare_ui_snapshot import REMOTE, check_emulator_identity, checked_remote_hash, install, build

XML = '<hierarchy><node content-desc="Lumo Cards" bounds="[1,2][90,40]"/></hierarchy>'


class LiveUiSnapshotTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)

    def test_live_snapshot_uses_unique_confirmed_file_without_global_idle(self):
        def reply(*args, **kwargs):
            if args[1] == 'rm': return ''
            if args[1] == 'cat': return XML
            self.assertEqual(args[1:5], ('CLASSPATH=/system/framework/uiautomator.jar:'+REMOTE,
                                         'app_process', '/system/bin', 'LumoUiSnapshot'))
            return 'LUMO_UI_SNAPSHOT schema=1 idle_wait=none\nUI hierchary dumped to: '+args[-1]+'\n'
        adb = Mock(side_effect=reply)
        root = read_fresh_hierarchy(adb, self.out, snapshot_remote=REMOTE)
        self.assertEqual(root.find('node').get('content-desc'), 'Lumo Cards')
        record = json.loads((self.out/'ui-dump-observations.jsonl').read_text())
        self.assertEqual(record['method'], 'live-accessibility-without-idle')
        self.assertTrue(record['fresh'])
        self.assertFalse(any('input' in call.args or 'uiautomator' in call.args for call in adb.call_args_list))

    def test_environment_selects_the_same_fixed_snapshot_helper(self):
        def reply(*args, **kwargs):
            if args[1] == 'rm': return ''
            if args[1] == 'cat': return XML
            self.assertIn('app_process', args)
            return 'UI hierchary dumped to: '+args[-1]+'\n'
        with patch.dict(os.environ, {'LUMO_UI_SNAPSHOT_REMOTE': REMOTE}):
            root = read_fresh_hierarchy(Mock(side_effect=reply), self.out)
        self.assertEqual(root.find('node').get('content-desc'), 'Lumo Cards')

    def test_unapproved_or_injected_helper_path_is_rejected_before_adb(self):
        for path in ['/tmp/other.jar', REMOTE+';echo bad', '']:
            adb = Mock()
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, 'helper path'):
                read_fresh_hierarchy(adb, self.out, snapshot_remote=path)
            adb.assert_not_called()

    def test_live_helper_without_completion_marker_cannot_reuse_old_xml(self):
        adb = Mock(return_value='')
        with self.assertRaisesRegex(RuntimeError, 'did not confirm'):
            read_fresh_hierarchy(adb, self.out, attempts=1, snapshot_remote=REMOTE)
        self.assertFalse(any('cat' in call.args for call in adb.call_args_list))

    def test_emulator_identity_is_explicit(self):
        check_emulator_identity('emulator-5554', '1\n', '35\n')
        for identity in [('phone123', '1', '35'), ('emulator-5554', '0', '35'),
                         ('emulator-5554', '1', '36'), ('emulator-5554;echo', '1', '35')]:
            with self.subTest(identity=identity), self.assertRaises(ValueError):
                check_emulator_identity(*identity)

    def test_remote_hash_and_path_must_both_match(self):
        checksum = 'a'*64
        checked_remote_hash(checksum+'  '+REMOTE+'\n', checksum)
        for value in ['b'*64+'  '+REMOTE, checksum+'  /tmp/other.jar', checksum,
                      checksum+'  '+REMOTE+'\nextra']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                checked_remote_hash(value, checksum)

    def test_install_rejects_physical_device_before_reading_or_pushing_jar(self):
        replies = [subprocess.CompletedProcess([], 0, '0\n', ''),
                   subprocess.CompletedProcess([], 0, '35\n', '')]
        with patch('prepare_ui_snapshot.subprocess.run', side_effect=replies) as run:
            with self.assertRaisesRegex(ValueError, 'emulator'):
                install(self.out/'never-read.jar', self.out, 'phone123', 'adb')
            self.assertTrue(all('getprop' in call.args[0] for call in run.call_args_list))

    def test_build_requires_existing_android_tools_without_overwriting_jar(self):
        with self.assertRaisesRegex(ValueError, 'build-tools'):
            build(self.out, self.out/'missing-sdk')
        (self.out/'lumo-ui-snapshot.jar').write_bytes(b'existing')
        with self.assertRaisesRegex(ValueError, 'overwrite'):
            build(self.out, self.out/'missing-sdk')
        self.assertEqual((self.out/'lumo-ui-snapshot.jar').read_bytes(), b'existing')


if __name__ == '__main__':
    unittest.main()
