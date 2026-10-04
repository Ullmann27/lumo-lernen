"""Failed UIAutomator requests must never drive touches using a previous file."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from fresh_ui_hierarchy import read_fresh_hierarchy

XML = '<?xml version="1.0"?><hierarchy><node content-desc="Lumo Cards" bounds="[16,230][464,322]"/></hierarchy>'


class FreshHierarchyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name)
        self.paths = []
        self.requests = 0

    def device(self, outputs=None, documents=None):
        outputs = list(outputs or ['success'])
        documents = list(documents or [XML])
        def respond(*args, **kwargs):
            if args[1] == 'rm':
                return ''
            if args[1] == 'uiautomator':
                self.requests += 1
                self.paths.append(args[-1])
                value = outputs[min(self.requests-1, len(outputs)-1)]
                if isinstance(value, Exception):
                    raise value
                return ('UI hierchary dumped to: '+args[-1]+'\n'
                        if value == 'success' else value)
            if args[1] == 'cat':
                return documents[min(self.requests-1, len(documents)-1)]
            raise AssertionError(f'An observation sent a non-read action: {args}')
        return Mock(side_effect=respond)

    def records(self):
        return [json.loads(line) for line in
                (self.out/'ui-dump-observations.jsonl').read_text().splitlines()]

    def test_confirmed_current_dump_is_read_and_fingerprinted(self):
        adb = self.device()
        root = read_fresh_hierarchy(adb, self.out)
        self.assertEqual(root.find('node').get('content-desc'), 'Lumo Cards')
        record, = self.records()
        self.assertTrue(record['fresh'])
        self.assertEqual(len(record['xml_sha256']), 64)
        self.assertEqual([call.args[1] for call in adb.call_args_list],
                         ['rm', 'uiautomator', 'cat', 'rm'])
        self.assertIn('--compressed', adb.call_args_list[1].args)

    def test_exit_zero_idle_error_cannot_return_a_preexisting_good_xml(self):
        adb = self.device(['ERROR: could not get idle state.\n'])
        with patch('fresh_ui_hierarchy.time.sleep'), self.assertRaisesRegex(RuntimeError, 'No fresh'):
            read_fresh_hierarchy(adb, self.out)
        self.assertFalse(any(call.args[1] == 'cat' for call in adb.call_args_list))
        self.assertEqual(len(set(self.paths)), 3)
        self.assertTrue(all(not record['fresh'] for record in self.records()))

    def test_retry_uses_new_path_without_scroll_tap_or_app_restart(self):
        adb = self.device(['', 'success'])
        with patch('fresh_ui_hierarchy.time.sleep'):
            root = read_fresh_hierarchy(adb, self.out)
        self.assertEqual(root.find('node').get('content-desc'), 'Lumo Cards')
        self.assertNotEqual(*self.paths)
        self.assertEqual([record['fresh'] for record in self.records()], [False, True])
        self.assertTrue(all(call.args[1] in {'rm', 'cat', 'uiautomator'}
                            for call in adb.call_args_list))

    def test_success_for_wrong_remote_path_is_rejected(self):
        adb = self.device(['UI hierchary dumped to: /sdcard/previous.xml\n'])
        with self.assertRaisesRegex(RuntimeError, 'did not confirm'):
            read_fresh_hierarchy(adb, self.out, attempts=1)
        self.assertFalse(any(call.args[1] == 'cat' for call in adb.call_args_list))

    def test_malformed_xml_empty_root_and_wrong_root_fail_closed(self):
        for xml in ['<hierarchy><node>', '<hierarchy/>', '<other><node/></other>', 'not XML']:
            with self.subTest(xml=xml), self.assertRaises(RuntimeError):
                read_fresh_hierarchy(self.device(documents=[xml]), self.out, attempts=1)

    def test_timeout_can_retry_but_cannot_read_an_old_path(self):
        adb = self.device([subprocess.TimeoutExpired('uiautomator', 20), 'success'])
        with patch('fresh_ui_hierarchy.time.sleep'):
            read_fresh_hierarchy(adb, self.out)
        self.assertEqual([r['fresh'] for r in self.records()], [False, True])

    def test_cleanup_device_loss_does_not_pass_a_successful_read(self):
        adb = self.device()
        wrapped = adb.side_effect
        def respond(*args, **kwargs):
            if args[1] == 'rm' and self.requests:
                raise RuntimeError('device offline')
            return wrapped(*args, **kwargs)
        adb.side_effect = respond
        with self.assertRaisesRegex(RuntimeError, 'device offline'):
            read_fresh_hierarchy(adb, self.out, attempts=1)
        self.assertFalse(self.records()[0]['fresh'])

    def test_unexpected_remote_error_is_not_replaced_by_cleanup_error(self):
        adb = self.device([RuntimeError('original dump failure')])
        wrapped = adb.side_effect
        def respond(*args, **kwargs):
            if args[1] == 'rm' and self.requests:
                raise RuntimeError('cleanup failure')
            return wrapped(*args, **kwargs)
        adb.side_effect = respond
        with self.assertRaisesRegex(RuntimeError, 'original dump failure'):
            read_fresh_hierarchy(adb, self.out, attempts=1)
        self.assertIn('cleanup failure', self.records()[0]['cleanup_error'])

    def test_invalid_attempt_limits_are_rejected_before_any_device_access(self):
        for attempts in [0, 6]:
            adb = self.device()
            with self.subTest(attempts=attempts), self.assertRaises(ValueError):
                read_fresh_hierarchy(adb, self.out, attempts=attempts)
            adb.assert_not_called()


if __name__ == '__main__':
    unittest.main()
