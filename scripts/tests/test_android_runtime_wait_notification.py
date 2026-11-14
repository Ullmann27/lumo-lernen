"""Replay an original Android wait notification through the strict protocol.

Only the transport is synthetic. The source fixture remains the failed PR486
run; these contracts neither repeat Android nor relabel that run as successful.
"""
from contextlib import contextmanager
import hashlib
import json
from pathlib import Path
import unittest
from unittest import mock

from scripts.tests import test_android_runtime_device_logger as DEVICE


FIXTURES = Path(__file__).with_name("fixtures") / "android37_wait_08e"


class OriginalWaitNotificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        DEVICE.DeviceLogContracts.setUpClass()
        provenance = json.loads((FIXTURES / "manifest.json").read_bytes())
        if (provenance["source_sha"] != "08e63bd32917a6672ae99b66a17c3fa57c83977a"
                or provenance["run_id"] != 43574161418
                or provenance["job_id"] != 132384862707
                or provenance["artifact_id"] != 14105941453
                or provenance["archive_sha256"] != "18346b2b68cf72ab0d5423365dfef7ca66f998b7a8f215feddbdb75f9505f3e1"):
            raise AssertionError("Original wait fixture lost its exact CI identity")
        for row in provenance["files"]:
            data = (FIXTURES / row["file"]).read_bytes()
            if len(data) != row["bytes"] or hashlib.sha256(data).hexdigest() != row["sha256"]:
                raise AssertionError("An original wait fixture changed")
        cls.notification = (FIXTURES / "swangle-wait.stderr").read_bytes()
        if cls.notification != b"Terminated \n" or (FIXTURES / "swangle-exit.stdout").read_bytes() != b"143\n":
            raise AssertionError("The observed wait bytes or original exit changed")
        stop = json.loads((FIXTURES / "swangle-stop.json").read_bytes())
        if stop["command"][-4:] != ["shell", "kill", "-TERM", "2528"] or stop["returncode"] != 0:
            raise AssertionError("The real original did not deliberately signal its recorded logger")
        original = json.loads((FIXTURES / "swangle-runtime-anr-verification.json").read_bytes())
        if original["status"] != "FAIL" or "device_continuity_unverified:Unrecognized wait notification from the device logger shell" not in original["errors"]:
            raise AssertionError("The original failure was replaced or relabelled")

    @contextmanager
    def recording(self, notification=None):
        case = DEVICE.DeviceLogContracts("test_raw_shell_wait_notification_is_preserved_and_bound_to_term")
        case.setUp()
        dispatch = case.fake.dispatch
        payload = self.notification if notification is None else notification

        def with_observed_wait(command):
            result = dispatch(command)
            if command[3:6] == ["shell", "kill", "-TERM"]:
                case.fake.wait_stderr = payload
            return result

        try:
            with mock.patch.object(case.fake, "dispatch", side_effect=with_observed_wait):
                yield case
        finally:
            case.doCleanups()

    def test_original_twelve_bytes_survive_the_complete_production_protocol(self):
        with self.recording() as case:
            result = case.complete()
            self.assertEqual(result["status"], "PASS", result["errors"])
            final = DEVICE.ANR.read_json(case.out / "device-logger/finish.json")
            self.assertEqual((case.out / "device-logger/finish" / final["wait.stderr"]).read_bytes(), self.notification)
            self.assertEqual(final["exit_code"], 143)
            self.assertEqual(result["device_recording"]["start_identity"]["logger"]["pid"], case.fake.child)
            self.assertEqual(result["device_recording"]["logcat"]["anr_record_count"], 0)

    def test_empty_and_existing_exact_notification_remain_accepted(self):
        for notification in (b"", b"Terminated\n"):
            with self.subTest(notification=notification), self.recording(notification) as case:
                result = case.complete()
                self.assertEqual(result["status"], "PASS", result["errors"])

    def test_other_whitespace_and_additional_output_remain_rejected(self):
        for notification in (b"Terminated  \n", b"Terminated\t\n", b"Terminated\r\n",
                             b" Terminated \n", b"Terminated \nerror\n", b"Terminated ", b"Killed \n"):
            with self.subTest(notification=notification), self.recording(notification) as case:
                result = case.complete()
                self.assertEqual(result["status"], "FAIL")
                self.assertIn("device_continuity_unverified:Unrecognized wait notification from the device logger shell", result["errors"])

    def test_notification_cannot_excuse_an_unrequested_exit(self):
        with self.recording() as case:
            case.fake.bad_exit = True
            with self.assertRaisesRegex(ValueError, "requested TERM"):
                case.complete()

    def test_same_bytes_in_real_logger_or_session_stderr_are_errors(self):
        for name in ("logcat.stderr", "session.stderr"):
            with self.subTest(file=name), self.recording() as case:
                files = case.fake.files

                def with_real_stderr():
                    result = files()
                    result[name] = self.notification
                    return result

                with mock.patch.object(case.fake, "files", side_effect=with_real_stderr):
                    result = case.complete()
                self.assertEqual(result["status"], "FAIL")
                self.assertIn("device_continuity_unverified:Device logger emitted unexpected output/errors", result["errors"])

    def test_actual_original_gms_anr_remains_terminal(self):
        with self.recording() as case:
            case.test_real_gms_original_is_terminal_even_when_later_events_are_empty()
        with self.recording() as case:
            case.start()
            case.fake.log += (FIXTURES / "swiftshader-events-anr.stdout").read_bytes()
            DEVICE.ANR.capture_end(case.framework, case.out, case.serial, 0)
            DEVICE.FRAMEWORK.finish_device_log(case.out / "device-logger")
            DEVICE.FRAMEWORK.stop_monitor(case.framework)
            result = DEVICE.ANR.verify(case.framework, case.out, case.serial)
            self.assertEqual(result["status"], "FAIL")
            self.assertIn("recorded_android_anr_in_device_session", result["errors"])
            self.assertEqual(result["device_recording"]["logcat"]["anr_record_count"], 2)

    def test_process_or_inode_change_still_fails_before_root_acceptance(self):
        for field, message in (("corrupt_identity", "identity changed"), ("corrupt_inode", "file identity changed")):
            with self.subTest(field=field), self.recording() as case:
                setattr(case.fake, field, True)
                with self.assertRaisesRegex(ValueError, message):
                    case.start()

    def test_changed_pre_root_prefix_remains_rejected(self):
        with self.recording() as case:
            case.test_changed_pre_root_prefix_remains_a_failure()

    def test_valid_recording_cannot_override_the_tour_failure(self):
        with self.recording() as case:
            result = case.complete(tour_exit=1)
            self.assertEqual(result["status"], "FAIL")
            self.assertEqual(result["device_recording"]["status"], "PASS")
            self.assertIn("tour_command_failed_or_missing", result["errors"])


if __name__ == "__main__":
    unittest.main()
