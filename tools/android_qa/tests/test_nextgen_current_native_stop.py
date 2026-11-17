"""Current-candidate stop integration contracts; no Android success fixture."""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


support = module("current_stop_support", "tools/android_qa/tests/test_nextgen_current_candidate.py")
current, release = support.probe, support.release
stop = current.native_stop
legacy_support = module("current_stop_timing_support", "tools/android_qa/tests/test_nextgen_2031_native_runtime_cases.py")
VERSION, VERSION_NAME = 2032, "0.13.20"


def current_inputs():
    original, extra = support.inputs()
    candidate = {**support.identity(), "versionCode": VERSION, "versionName": VERSION_NAME,
                 "signingCertificateSha256": current.reference.CERTIFICATE}
    original["candidate"] = copy.deepcopy(candidate)
    original["installed"] = copy.deepcopy(candidate)
    extra["candidate"] = copy.deepcopy(candidate)
    extra["installed"] = copy.deepcopy(candidate)
    extra["previous_complete_probe"]["installed_before_reset"] = copy.deepcopy(candidate)
    extra["final_profile"] = {"id": "second-fictional-id", "name": current.learning.PROFILE_NAME}
    return original, extra, candidate


def publish(original, extra):
    return release.verify_tours(original, extra, source=support.SOURCE, native=support.NATIVE,
        version=VERSION, version_name=VERSION_NAME, certificate=current.reference.CERTIFICATE,
        x86_sha256=support.SHA, workflow_run=support.RUN, original_result_sha256=support.RESULT_SHA)


def fixture_preferences(profile_id="second-fictional-id"):
    return {"flutter.lumo_active_profile": json.dumps({"id": profile_id, "name": current.learning.PROFILE_NAME}),
            "flutter.lumo_progress": "synthetic unchanged learning record"}


def installed_record(candidate):
    path = "/data/app/~~synthetic/" + current.learning.PACKAGE + "-fixture/base.apk"
    dump = f"Package [{current.learning.PACKAGE}]:\n versionCode={VERSION}\n versionName={VERSION_NAME}\n"
    return {"apk_path": path, "package_dump": dump, "sha256_output": candidate["sha256"] + "  " + path + "\n",
            "metadata": current.learning.verify_installed_metadata(dump, candidate["sha256"], candidate)}


def stop_fixture():
    """Synthetic checker inputs, not an Android result or a recorded stop."""
    original, extra, candidate = current_inputs()
    bridge = legacy_support.synthetic_result()["bridge_active_stop"]
    bridge["preservation"]["profile_id"] = extra["final_profile"]["id"]
    bridge["video"]["audio_recorded"] = False
    bridge["stop_touch"]["elapsed_before_input"] = 1.2
    before = current.learning.learning_snapshot(fixture_preferences())
    result = {"schema": stop.SCHEMA, "version": 1, "status": "PASS_WITH_LIMITATIONS", "mode": "current-build",
        "candidate": candidate, "qa_commit": support.SOURCE, "apk_source": support.SOURCE,
        "native_source": support.NATIVE, "workflow_run_id": support.RUN,
        "helper_sha256": stop.digest(Path(stop.__file__)), "observed_helper_sha256": stop.digest(Path(stop.observed.__file__)),
        "installation_or_reset_performed": False, "flow_phase": "after_complete_banana_before_pattern",
        "completed_banana_sha256": stop.banana_digest(extra["banana"]), "installed": installed_record(candidate),
        "before": before, "after": copy.deepcopy(before), "preservation": current.learning.require_preserved(before, before),
        "bridge_active_stop": bridge}
    extra["current_native_active_stop"] = result
    return original, extra, candidate


class InstallationProbe:
    """Only the current adapter's read-only transport boundary is simulated."""
    def __init__(self):
        _, self.result, self.identity = stop_fixture()
        self.result.pop("current_native_active_stop")
        self.installed = installed_record(self.identity)
        self.result["installed"] = copy.deepcopy(self.installed["metadata"])
        self.args = SimpleNamespace(qa_commit=support.SOURCE, expected_source=support.SOURCE, workflow_run_id=support.RUN)
        self.base = SimpleNamespace(adb=self.adb)
        self.events, self.prefs = [], fixture_preferences()

    def candidate_identity(self):
        self.events.append("candidate identity")
        return copy.deepcopy(self.identity)

    def fresh(self, tag):
        return tag

    def read_installed_base_apk_path(self, tag):
        self.events.append("observed installed path")
        return self.installed["apk_path"]

    def adb(self, *args, **kwargs):
        self.events.append(args)
        if args == ("shell", "dumpsys", "package", current.learning.PACKAGE):
            return self.installed["package_dump"]
        if args == ("shell", "sha256sum", self.installed["apk_path"]):
            return self.installed["sha256_output"]
        raise AssertionError("Unexpected install/reset/UI action: " + repr(args))

    def preferences(self, tag):
        self.events.append(tag)
        return copy.deepcopy(self.prefs)


class CurrentStopEntryTest(unittest.TestCase):
    def test_current_publisher_requires_completed_stop(self):
        original, extra, _ = current_inputs()
        with self.assertRaisesRegex(RuntimeError, "stop|Stop"):
            publish(original, extra)

    def test_actual_reference_run_orders_complete_banana_stop_then_pattern(self):
        events = []
        probe = object.__new__(current.CurrentCandidateProbe)
        probe.args = SimpleNamespace(expected_version=VERSION)
        probe.result = {"device": {"api": 35}}
        for name in ("reset_successful_original", "identify_and_install", "onboard", "configure_local_voice"):
            setattr(probe, name, lambda name=name: events.append(name))
        probe.pattern = lambda: events.append("pattern")
        probe.preferences = lambda tag: {"flutter.lumo_active_profile": json.dumps({
            "id": "synthetic", "name": current.learning.PROFILE_NAME})}
        helper = SimpleNamespace(run_current_native_stop=lambda instance: events.append("stop"))
        with patch.object(current, "native_stop", helper, create=True), patch.object(
                current.reference.ReferenceProbe, "banana", autospec=True,
                side_effect=lambda instance: events.append("complete banana")):
            probe.run()
        self.assertEqual(events[-3:], ["complete banana", "stop", "pattern"])

    def test_incomplete_banana_prevents_stop_and_pattern(self):
        probe = object.__new__(current.CurrentCandidateProbe)
        probe.args = SimpleNamespace(expected_version=VERSION)
        with patch.object(current.reference.ReferenceProbe, "banana", side_effect=RuntimeError("incomplete banana")), \
                patch.object(current.native_stop, "run_current_native_stop") as run_stop:
            with self.assertRaisesRegex(RuntimeError, "incomplete banana"):
                probe.banana()
        run_stop.assert_not_called()

    def test_historical_2031_banana_does_not_enter_current_stop(self):
        probe = object.__new__(current.CurrentCandidateProbe)
        probe.args = SimpleNamespace(expected_version=2031)
        with patch.object(current.reference.ReferenceProbe, "banana") as banana, \
                patch.object(current.native_stop, "run_current_native_stop") as run_stop:
            probe.banana()
        banana.assert_called_once()
        run_stop.assert_not_called()


class CurrentStopIdentityTest(unittest.TestCase):
    def test_completed_current_result_passes_without_mutating_inputs(self):
        original, extra, _ = stop_fixture()
        before = copy.deepcopy((original, extra))
        self.assertEqual(publish(original, extra), original["native_learning"]["performance"])
        self.assertEqual((original, extra), before)

    def test_different_run_source_helper_or_historical_identity_fails(self):
        original, extra, _ = stop_fixture()
        source = extra["current_native_active_stop"]
        changes = (("qa_commit", "1" * 40), ("apk_source", "1" * 40), ("native_source", "2" * 40),
            ("workflow_run_id", support.RUN + 1), ("workflow_run_id", True), ("mode", "immutable-runtime-cases"),
            ("helper_sha256", "0" * 64), ("observed_helper_sha256", "0" * 64),
            ("installation_or_reset_performed", True), ("flow_phase", "before_banana"),
            ("completed_banana_sha256", "0" * 64), ("status", "RUNNING"),
            ("candidate", {**source["candidate"], "versionCode": 2031}))
        for field, value in changes:
            with self.subTest(field=field, value=value), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(extra)
                changed["current_native_active_stop"][field] = value
                publish(original, changed)
        with self.assertRaises(RuntimeError):
            stop.current_identity({**source["candidate"], "versionCode": 2031}, support.SOURCE)

    def test_actual_installed_bytes_version_and_profile_are_required(self):
        original, extra, _ = stop_fixture()
        for field, value in (("sha256_output", "0" * 64 + "  /different/base.apk"),
                             ("package_dump", "Package [other]: versionCode=2031"), ("metadata", {})):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(extra)
                changed["current_native_active_stop"]["installed"][field] = value
                publish(original, changed)
        for key, value in (("profile", {"id": "another"}), ("learning", {"new_reward": 1})):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(extra)
                changed["current_native_active_stop"]["after"][key] = value
                publish(original, changed)

    def test_missing_live_guards_video_return_or_acoustic_overclaims_fail(self):
        original, extra, _ = stop_fixture()
        bridge = extra["current_native_active_stop"]["bridge_active_stop"]
        changes = (("active_before_stop", {**bridge["active_before_stop"], "completed_observed": True}),
            ("active_before_stop", {**bridge["active_before_stop"], "profile": "foreign"}),
            ("previous_ids", [21]), ("stop_touch", {**bridge["stop_touch"], "stable_observed_target": False}),
            ("stop_touch", {**bridge["stop_touch"], "elapsed_before_input": 45.01}),
            ("returned_voice_control", {}), ("observation_seconds", 4.99),
            ("no_late_new_segments", False), ("active_id_completed_after_stop", True),
            ("question_menu_opened_during_active_window", True), ("acoustic_stop_verified", True),
            ("mouth_gesture_stop_verified", True), ("millisecond_stop_verified", True),
            ("video", {**bridge["video"], "duration_seconds": 0}), ("returned_to_academy", {}),
            ("model_after", {}), ("native_answer_submitted", True))
        for field, value in changes:
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(extra)
                changed["current_native_active_stop"]["bridge_active_stop"][field] = value
                publish(original, changed)


class CurrentStopAdapterTest(unittest.TestCase):
    def action(self, probe):
        self.assertEqual(probe.events[-1], "current-stop-learning-before")
        self.assertIn(("shell", "sha256sum", probe.installed["apk_path"]), probe.events)
        probe.events.append("actual action boundary")
        return stop_fixture()[1]["current_native_active_stop"]["bridge_active_stop"]

    def test_adapter_rechecks_installed_source_before_version_neutral_action(self):
        probe = InstallationProbe()
        with patch.object(stop.observed, "bridge_active_stop", side_effect=self.action) as action, \
                patch.object(stop.observed, "run_native_cases", side_effect=AssertionError("historic runner called")), \
                patch.object(stop.observed, "verify_native_cases", side_effect=AssertionError("historic gate called")):
            result = stop.run_current_native_stop(probe)
        action.assert_called_once_with(probe)
        self.assertEqual(result["status"], "PASS_WITH_LIMITATIONS")
        self.assertEqual(probe.events[-2:], ["actual action boundary", "current-stop-learning-after"])
        self.assertFalse(result["installation_or_reset_performed"])

    def test_changed_installation_incomplete_banana_or_foreign_profile_prevents_action(self):
        for mode in ("installed", "banana", "profile", "source"):
            probe = InstallationProbe()
            if mode == "installed":
                probe.installed["sha256_output"] = probe.installed["sha256_output"].replace(support.SHA, "0" * 64)
            elif mode == "banana":
                probe.result["banana"]["steps"] = [{}]
            elif mode == "profile":
                probe.prefs = fixture_preferences("another")
            else:
                probe.result["qa_commit"] = "0" * 40
            with self.subTest(mode=mode), patch.object(stop.observed, "bridge_active_stop") as action:
                with self.assertRaises(RuntimeError):
                    stop.run_current_native_stop(probe)
                action.assert_not_called()
                self.assertEqual(probe.result["current_native_active_stop"]["status"], "FAIL")

    def test_native_failure_is_retained_and_cannot_become_a_pass(self):
        probe = InstallationProbe()
        with patch.object(stop.observed, "bridge_active_stop", side_effect=RuntimeError("actual stop not observed")):
            with self.assertRaisesRegex(RuntimeError, "actual stop not observed"):
                stop.run_current_native_stop(probe)
        self.assertEqual(probe.result["current_native_active_stop"]["status"], "FAIL")
        self.assertEqual(probe.result["current_native_active_stop"]["error"], "actual stop not observed")


if __name__ == "__main__":
    unittest.main()
