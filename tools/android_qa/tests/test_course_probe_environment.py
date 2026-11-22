"""Synthetic guarded recovery/failure replays, not an Android device PASS.

The real 45069535268 screenshots/log show the Pixel Launcher ANR. XML below
models system resources; only a future run can provide the required fresh XML.
"""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

from PIL import Image

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
spec = importlib.util.spec_from_file_location('course_probe_environment_under_test',
                                              HERE / 'run_course_android_probe.py')
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)

LAUNCHER_ANR = ('11-22 21:02:48.038 553 2144 I am_anr  : '
                '[0,1226,com.google.android.apps.nexuslauncher,885767749,'
                'Input dispatching timed out (Application does not have a focused window).]\n')


def dialog(title="Pixel Launcher isn't responding", bounds='[48,360][432,420]'):
    root = ET.fromstring('''<hierarchy rotation="0">
      <node package="android" enabled="true" bounds="[0,0][480,800]">
        <node package="android" enabled="true" bounds="[24,260][456,540]">
          <node resource-id="android:id/alertTitle" package="android" enabled="true"
            clickable="false" bounds="[48,280][432,330]"/>
          <node text="Close app" resource-id="android:id/aerr_close" package="android"
            enabled="true" clickable="true" bounds="[48,360][432,420]"/>
          <node text="Wait" resource-id="android:id/aerr_wait" package="android"
            enabled="true" clickable="true" bounds="[48,440][432,500]"/>
        </node>
      </node></hierarchy>''')
    root.find(".//node[@resource-id='android:id/alertTitle']").set('text', title)
    root.find(".//node[@text='Close app']").set('bounds', bounds)
    return root


def clear():
    return ET.fromstring('<hierarchy><node package="dev.ullmann.lumo.lumo_lernen.coachpreview" '
                         'enabled="true" bounds="[0,0][480,800]"/></hierarchy>')


class CourseEnvironmentTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.out = Path(folder.name)
        self.addCleanup(patch.stopall)
        patch.object(probe, 'OUT', self.out).start()
        patch.object(probe.time, 'monotonic', return_value=0).start()
        patch.object(probe.time, 'sleep', lambda _: None).start()
        self.env = probe.course_environment()
        self.read = patch.object(probe, 'read_fresh_hierarchy').start()
        self.read.side_effect = [dialog(), dialog(), clear()]
        self.inputs = patch.object(probe, 'adb', return_value='').start()
        self.logs = patch.object(probe, 'captured_adb', return_value=SimpleNamespace(
            stdout=LAUNCHER_ANR, stderr='', returncode=0)).start()
        self.capture = patch.object(probe, 'capture', side_effect=self.picture).start()

    def picture(self, path, *, timeout):
        image = Image.new('RGB', (480, 800), color='navy')
        image.save(path)
        return image

    def inspect(self, *, name='dschungelherz', allow=True, deadline=100):
        return probe.inspect_course_system_ui(name, self.env, deadline=deadline,
                                               allow_recovery=allow)

    def assert_no_input(self):
        self.inputs.assert_not_called()
        self.assertEqual(self.env['pixel_launcher_recovery_attempts'], 0)

    def test_exact_fresh_dialog_closes_once_and_keeps_before_confirm_after_and_original_log(self):
        self.assertTrue(self.inspect())
        self.inputs.assert_called_once_with('shell', 'input', 'tap', '240', '390', timeout=35)
        self.assertEqual(self.env['pixel_launcher_recovery_attempts'], 1)
        event = json.loads((self.out / 'COURSE-ENVIRONMENT.json').read_text())['observations'][0]
        self.assertEqual(event['status'], 'RECOVERED')
        self.assertEqual(event['original_anr_lines'], [LAUNCHER_ANR.strip()])
        self.assertEqual(event['touch']['bounds'], [48, 360, 432, 420])
        self.assertEqual(event['touch']['status'], 'COMPLETED')
        for field in ('before_xml', 'confirm_xml', 'after_xml', 'before_screenshot', 'after_screenshot'):
            self.assertTrue((self.out / event[field]['file']).is_file())
        self.assertEqual((self.out / event['original_anr_log']['file']).read_text(), LAUNCHER_ANR)
        self.assertEqual(self.read.call_count, 3)
        self.assertTrue(all(call.kwargs['attempts'] == 1 for call in self.read.call_args_list))
        self.assertFalse(self.env['lumo_errors_suppressed'])

    def test_current_changed_valid_layout_uses_its_actual_center(self):
        self.read.side_effect = [dialog(bounds='[60,365][400,415]'),
                                 dialog(bounds='[60,365][400,415]'), clear()]
        self.assertTrue(self.inspect())
        self.inputs.assert_called_once_with('shell', 'input', 'tap', '230', '390', timeout=35)
        self.assertEqual(self.env['observations'][0]['touch']['bounds'], [60, 365, 400, 415])

    def test_healthy_surface_is_read_only(self):
        self.read.side_effect = [clear()]
        self.assertFalse(self.inspect())
        self.assert_no_input()
        self.logs.assert_not_called()
        self.capture.assert_not_called()

    def test_other_app_and_near_launcher_titles_are_never_dismissed(self):
        for title in ("Lumo Lernen isn't responding", "System UI isn't responding",
                      'Pixel Launcher keeps stopping', 'Pixel Launcher isn’t responding'):
            with self.subTest(title=title):
                self.read.side_effect = [dialog(title)]
                with self.assertRaisesRegex(RuntimeError, 'Unrecognised'):
                    self.inspect()
                self.assert_no_input()

    def test_invalid_target_package_or_disabled_button_is_not_used(self):
        for attr, value in (('package', probe.PACKAGE), ('enabled', 'false')):
            with self.subTest(attribute=attr):
                root = dialog()
                root.find(".//node[@text='Close app']").set(attr, value)
                self.read.side_effect = [root]
                with self.assertRaisesRegex(RuntimeError, 'Unrecognised'):
                    self.inspect()
                self.assert_no_input()

    def test_second_fresh_bounds_must_match_before_any_touch(self):
        self.read.side_effect = [dialog(), dialog(bounds='[60,365][420,415]')]
        with self.assertRaisesRegex(RuntimeError, 'target changed'):
            self.inspect()
        self.assert_no_input()
        self.assertTrue((self.out / 'dschungelherz-environment-1-confirm.xml').is_file())

    def test_disappeared_or_replaced_confirmation_is_not_touched(self):
        for latest in (clear(), dialog("Lumo Lernen isn't responding")):
            with self.subTest(latest=ET.tostring(latest)):
                self.read.side_effect = [dialog(), latest]
                with self.assertRaisesRegex(RuntimeError, 'target changed'):
                    self.inspect()
                self.assert_no_input()

    def test_failed_fresh_dump_never_reuses_prior_xml(self):
        self.read.side_effect = RuntimeError('No fresh Android UI hierarchy')
        with self.assertRaisesRegex(RuntimeError, 'No fresh'):
            self.inspect()
        self.assert_no_input()

    def test_screenshot_bounds_mismatch_fails_without_input(self):
        def undersized(path, *, timeout):
            image = Image.new('RGB', (100, 100))
            image.save(path)
            return image
        self.capture.side_effect = undersized
        with self.assertRaisesRegex(RuntimeError, 'do not fit'):
            self.inspect()
        self.assert_no_input()

    def test_missing_original_launcher_log_is_not_recoverable(self):
        self.logs.return_value.stdout = 'ordinary log output\n'
        with self.assertRaisesRegex(RuntimeError, 'lacks the required original'):
            self.inspect()
        self.assert_no_input()

    def test_lumo_or_other_anr_alongside_launcher_remains_failure(self):
        for package in (probe.PACKAGE, 'com.android.systemui'):
            with self.subTest(package=package):
                self.read.side_effect = [dialog()]
                self.logs.return_value.stdout = LAUNCHER_ANR + f'I am_anr : [0,100,{package},123,timeout]\n'
                with self.assertRaisesRegex(RuntimeError, "Another app's ANR"):
                    self.inspect()
                self.assert_no_input()

    def test_required_screenshot_failure_prevents_touch(self):
        self.capture.side_effect = OSError('screenshot unavailable')
        with self.assertRaisesRegex(OSError, 'screenshot unavailable'):
            self.inspect()
        self.assert_no_input()

    def test_required_log_failure_prevents_touch_and_keeps_partial_streams(self):
        self.logs.side_effect = subprocess.CalledProcessError(
            255, ['adb', 'logcat'], output='partial original\n', stderr='original stderr\n')
        with self.assertRaisesRegex(RuntimeError, 'Required anr-logcat evidence'):
            self.inspect()
        self.assert_no_input()
        self.assertEqual(self.logs.call_count, 3)
        self.assertEqual((self.out / 'dschungelherz-environment-1-anr-logcat-attempt-1-stderr.txt').read_text(),
                         'original stderr\n')

    def test_lumo_anr_in_pre_touch_partial_log_blocks_recovery_even_after_successful_retry(self):
        self.logs.side_effect = [subprocess.CalledProcessError(
            255, ['adb', 'logcat'], output=f'I am_anr : [0,100,{probe.PACKAGE},123,timeout]\n',
            stderr='incomplete'), SimpleNamespace(stdout=LAUNCHER_ANR, stderr='', returncode=0)]
        with self.assertRaisesRegex(RuntimeError, "Another app's ANR"):
            self.inspect()
        self.assert_no_input()

    def test_dialog_persists_after_touch_is_fail_with_after_proof(self):
        self.read.side_effect = [dialog(), dialog(), dialog()]
        with self.assertRaisesRegex(RuntimeError, 'remains or recurred'):
            self.inspect()
        self.assertEqual(self.inputs.call_count, 1)
        self.assertEqual(self.env['pixel_launcher_recovery_attempts'], 1)
        event = self.env['observations'][0]
        self.assertEqual(event['status'], 'FAIL')
        self.assertTrue((self.out / event['after_screenshot']['file']).is_file())

    def test_recurrence_in_next_course_exhausts_shared_run_budget(self):
        self.assertTrue(self.inspect())
        self.read.side_effect = [dialog()]
        with self.assertRaisesRegex(RuntimeError, 'single run-wide recovery is exhausted'):
            self.inspect(name='zauberwald')
        self.assertEqual(self.inputs.call_count, 1)
        self.assertEqual(self.env['pixel_launcher_recovery_attempts'], 1)

    def test_unknown_touch_result_reserves_attempt_and_never_retries_input(self):
        self.inputs.side_effect = subprocess.TimeoutExpired(['adb', 'shell', 'input'], 35,
                                                            output=b'partial', stderr=b'timeout')
        with self.assertRaises(subprocess.TimeoutExpired):
            self.inspect()
        self.read.side_effect = [dialog()]
        with self.assertRaisesRegex(RuntimeError, 'single run-wide recovery is exhausted'):
            self.inspect(name='zauberwald')
        self.assertEqual(self.inputs.call_count, 1)
        self.assertEqual((self.out / 'dschungelherz-environment-1-failed-stderr.txt').read_bytes(), b'timeout')

    def test_final_gameplay_guard_never_dismisses_any_dialog(self):
        with self.assertRaisesRegex(RuntimeError, 'during gameplay'):
            self.inspect(allow=False)
        self.assert_no_input()

    def test_existing_deadline_is_not_extended_for_recovery(self):
        with self.assertRaisesRegex(TimeoutError, 'Existing course deadline expired'):
            self.inspect(deadline=0)
        self.assert_no_input()

    def test_fresh_hierarchy_adb_uses_only_remaining_course_budget(self):
        def read(adapter, out, *, attempts):
            adapter('shell', 'uiautomator', 'dump', timeout=20)
            return clear()
        self.read.side_effect = read
        with patch.object(probe, 'strict_adb', return_value='') as read_adb:
            self.assertFalse(self.inspect(deadline=2))
        read_adb.assert_called_once_with('shell', 'uiautomator', 'dump', timeout=2)
        self.assert_no_input()

    def test_new_anr_log_is_failure_after_known_external_dialog_was_recovered(self):
        self.assertTrue(self.inspect())
        path = self.out / 'final-logcat.txt'
        base = ('[LumoRun] ready\n[LumoRun] course dschungelherz:\n'
                '[LumoRun] running dschungelherz s=23\n' + LAUNCHER_ANR)
        evidence = {'file': path.name, 'attempts': [{'stdout': {'file': path.name}}]}
        path.write_text(base)
        probe.validate_course_logs('dschungelherz', True, evidence, self.env)
        for new in (LAUNCHER_ANR.replace('21:02:48.038', '21:04:49.001'),
                    f'I am_anr : [0,100,{probe.PACKAGE},123,timeout]\n'):
            with self.subTest(new=new):
                path.write_text(base + new)
                with self.assertRaisesRegex(RuntimeError, 'Another or recurring ANR'):
                    probe.validate_course_logs('dschungelherz', True, evidence, self.env)

    def test_anr_in_failed_partial_log_is_not_erased_by_later_complete_read(self):
        complete = self.out / 'complete.txt'
        partial = self.out / 'failed-partial.txt'
        complete.write_text('[LumoRun] ready\n[LumoRun] course dschungelherz:\n'
                            '[LumoRun] running dschungelherz s=23\n')
        partial.write_text(f'I am_anr : [0,100,{probe.PACKAGE},123,timeout]\n')
        evidence = {'file': complete.name, 'attempts': [
            {'stdout': {'file': partial.name}}, {'stdout': {'file': complete.name}}]}
        with self.assertRaisesRegex(RuntimeError, 'Another or recurring ANR'):
            probe.validate_course_logs('dschungelherz', True, evidence, self.env)
        self.assertIn(probe.PACKAGE, (self.out / 'dschungelherz-unexpected-anrs.txt').read_text())


if __name__ == '__main__':
    unittest.main()
