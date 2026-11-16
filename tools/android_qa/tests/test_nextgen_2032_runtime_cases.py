"""Observed XML regressions and narrow current-identity/result counterexamples.

Historical subcases are input fixtures only. Synthetic current identities and
Core attempts in these host tests are never presented as new Android results.
"""
from __future__ import annotations

import copy
from contextlib import contextmanager
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("runtime_2032_under_test",
    ROOT / ".github/probes/lumo_nextgen_2032_runtime_cases_android_probe.py")
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)
FIXTURES = Path(__file__).parent / "fixtures/nextgen_2032_runtime_cases"
DATA = json.loads((FIXTURES / "observed-subcases.json").read_text())
TASK = DATA["currentPattern"]["task"]
QA_COMMIT, QA_RUN = "a" * 40, 123456789


def xml_nodes(number=453):
    return list(ET.fromstring((FIXTURES / f"{number:04d}-pattern-observed-core-answer-cards.xml").read_bytes()).iter("node"))


def patterned_evidence():
    before = copy.deepcopy(DATA["switch"]["after"])
    after = copy.deepcopy(before)
    key = next(key for key in after["learning"] if "attempt_log" in key)
    attempts = json.loads(after["learning"][key])
    attempts.append({"id": "synthetic-host-test-core-attempt", "sub": "Logik", "unit": "Muster",
                     "q": TASK["prompt"], "a": TASK["next"], "e": TASK["next"], "ok": True, "hint": True})
    after["learning"][key] = json.dumps(attempts)
    pattern = copy.deepcopy(DATA["currentPattern"])
    pattern.update(core_answer_submitted=True,
                   core_submission=probe.reference.verify_core_submission(before, after, TASK))
    return pattern, {"before": before, "after": after, "selection": probe.observed_pattern_answer(xml_nodes(), TASK),
                     "selection_xml_sha256": hashlib.sha256((FIXTURES / "0453-pattern-observed-core-answer-cards.xml").read_bytes()).hexdigest(),
                     "explicit_answer_taps": 1, "video": copy.deepcopy(DATA["switch"]["video"])}


def complete_synthetic_result():
    """A validator fixture, deliberately NOT a claimed Android execution."""
    pattern, evidence = patterned_evidence()
    candidate = probe.fixed_identity(DATA["currentCandidate"])
    result = {"schema": "lumo.nextgen.2032.runtime_cases.android", "version": 1,
        "status": "PASS_WITH_LIMITATIONS", "mode": "immutable-runtime-cases", "cases": probe.CASES,
        "qa_commit": QA_COMMIT, "qa_workflow_run": QA_RUN, "apk_source": probe.SOURCE,
        "native_source": probe.NATIVE, "source_build_run": probe.SOURCE_RUN,
        "probe_sha256": probe.digest(Path(probe.__file__)), "helper_sha256": probe.helper_hashes(),
        "config": probe.load(probe.CONFIG), "config_sha256": probe.digest(probe.CONFIG), "candidate": candidate,
        "installed": {key: candidate[key] for key in ("package", "versionCode", "versionName", "sha256", "signingCertificateSha256")},
        "device": {"api": 35, "abi": "x86_64", "physical_device": False, "package_absent_before_install": True},
        "onboarding": {"synthetic": True, "profile": DATA["switch"]["before"]["profile"]},
        "final_profile": DATA["switch"]["before"]["profile"], "auto_read_restored_before_native": True,
        "local_voice_settings": {"auto_read": True},
        "runtime_auto_read_ui_changes": [{"control": "Automatisch vorlesen", "private_preferences_written": False,
                                           "before": {"autoReadEnabled": True}, "after": {"autoReadEnabled": False}}],
        "numeric_wrong_then_correct": copy.deepcopy(DATA["numeric"]),
        "flutter_switch_during_syllable_playback": copy.deepcopy(DATA["switch"]),
        "native_banana_slower": probe.bind_current_banana(DATA["banana"]),
        "pattern": pattern, "pattern_core_evidence": evidence}
    result["source_binding"] = {"mode": "immutable-runtime-cases", "qa_commit": QA_COMMIT,
        "qa_workflow_run": QA_RUN, "apk_source": probe.SOURCE, "source_build_run": probe.SOURCE_RUN,
        "runtime_source_changed": False, "config_sha256": probe.digest(probe.CONFIG),
        "helper_sha256": probe.helper_hashes(), "source_rate_contract": probe.source_rate_contract(),
        "apk_source_tree": "1c572ff37dde942229e8ae8b1f141ec95df50545", "qa_tree": "b" * 40,
        "changed_paths": [".github/probes/lumo_nextgen_2032_runtime_cases_android_probe.py"]}
    result["installed"]["signature_binding"] = "installed base.apk hash equals independently signature-verified input APK"
    result.update({key: False for key in ("release_eligible", "original_probe_requirement_satisfied",
        "historical_tour_pass_used", "private_app_data_written_by_probe", "apk_rebuilt_by_probe", "fullModernizationComplete")})
    return result


class PatternXmlTests(unittest.TestCase):
    def test_eight_original_xmls_are_byte_bound_and_targets_are_fully_visible(self):
        manifest = json.loads((FIXTURES / "manifest.json").read_text())
        self.assertEqual(len(manifest["originalFixtures"]), 8)
        for item in manifest["originalFixtures"]:
            with self.subTest(file=item["file"]):
                raw = (FIXTURES / item["file"]).read_bytes()
                self.assertEqual(hashlib.sha256(raw).hexdigest(), item["sha256"])
                nodes = list(ET.fromstring(raw).iter("node"))
                self.assertNotIn(probe.HEADER, probe.learning.node_labels(nodes))  # Exact old false negative.
                result = probe.observed_pattern_answer(nodes, TASK)
                self.assertEqual(result is not None, int(item["file"][:4]) >= 453)

    def test_substrings_foreign_disabled_and_ambiguous_headers_are_not_accepted(self):
        for mutate in ("substring", "foreign", "disabled", "ambiguous", "different-task"):
            with self.subTest(mutate=mutate):
                nodes = xml_nodes()
                header = next(n for n in nodes if probe.HEADER in n.get("content-desc", ""))
                if mutate == "substring":
                    header.set("content-desc", header.get("content-desc").replace(probe.HEADER, "Nicht " + probe.HEADER))
                elif mutate == "foreign": header.set("package", "another.app")
                elif mutate == "disabled": header.set("enabled", "false")
                elif mutate == "ambiguous":
                    duplicate = copy.deepcopy(header); duplicate.set("bounds", "[40,357][1041,1693]"); nodes.append(duplicate)
                else: header.set("content-desc", header.get("content-desc").replace("Quadrat – Kreis – Quadrat – Kreis", "Stern – Kreis – Stern – Kreis"))
                if mutate in ("ambiguous", "different-task"):
                    with self.assertRaises(RuntimeError): probe.observed_pattern_answer(nodes, TASK)
                else: self.assertIsNone(probe.observed_pattern_answer(nodes, TASK))

    def test_disabled_duplicate_or_edge_clipped_cards_are_not_tap_targets(self):
        for mutate in ("disabled", "duplicate", "clipped"):
            nodes = xml_nodes()
            card = next(n for n in nodes if n.get("content-desc") == TASK["next"])
            if mutate == "disabled": card.set("enabled", "false")
            elif mutate == "duplicate":
                duplicate = copy.deepcopy(card); duplicate.set("bounds", "[40,1300][524,1500]"); nodes.append(duplicate)
            else: card.set("bounds", "[39,1704][524,1914]")
            if mutate == "duplicate":
                with self.assertRaises(RuntimeError): probe.observed_pattern_answer(nodes, TASK)
            else:
                self.assertIsNone(probe.observed_pattern_answer(nodes, TASK), mutate)

    def test_recorded_multiline_heading_reaches_one_explicit_domain_submission(self):
        pattern, proof = patterned_evidence()
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)

            class Harness:
                def __init__(self):
                    self.out = out; self.result = {"pattern": copy.deepcopy(DATA["currentPattern"])}
                    self.recordings = []; self.touches = []; self.index = 0
                    self.live = SimpleNamespace(live_nodes=self.live_nodes)

                def read_pattern(self, tag): return TASK
                def see(self, *args, **kwargs): return None
                def nodes(self, tag):
                    number = min(450 + self.index, 457); self.index += 1
                    return xml_nodes(number)
                def scroll(self, *args): return None
                def fresh(self, tag): return "host-" + tag
                def live_nodes(self, destination, tag):
                    raw = (FIXTURES / "0453-pattern-observed-core-answer-cards.xml").read_bytes()
                    (destination / (tag + ".xml")).write_bytes(raw)
                    return list(ET.fromstring(raw).iter("node"))
                @contextmanager
                def recording(self, tag):
                    yield
                    self.recordings.append(copy.deepcopy(proof["video"]))
                def capture(self, tag): return {"file": "synthetic-host-capture.png"}
                def save(self, *args): return None
                def touch(self, bounds, tag, label): self.touches.append((bounds, label))
                def preferences(self, tag): return proof["after"]
                def wait(self, message, callback, **kwargs): return callback()

            harness = Harness()
            method = (probe.reference.ReferenceProbe.submit_pattern_answer
                      if os.environ.get("LUMO_2032_HEADER_BASELINE") == "1"
                      else probe.RuntimeCases2032Probe.submit_pattern_answer)
            with patch.object(probe.learning, "learning_snapshot", side_effect=lambda value: value):
                method(harness, TASK, proof["before"])
            self.assertEqual(len(harness.touches), 1, "Recorded current cards must reach exactly one explicit answer")
            self.assertEqual(harness.result["pattern"]["core_submission"]["status"], "PASS")
            self.assertEqual(harness.touches[0][0], probe.observed_pattern_answer(xml_nodes(), TASK)["target"])


class CurrentBindingTests(unittest.TestCase):
    def test_exact_current_identity_rejects_old_or_mismatched_sources_and_bytes(self):
        self.assertEqual(probe.fixed_identity(DATA["currentCandidate"])["versionCode"], 2032)
        for key, value in (("sha256", "0" * 64), ("flutter_source_commit", probe.native.SOURCE),
                           ("versionCode", 2031), ("versionName", "0.13.19"), ("package", "other.app"),
                           ("signingCertificateSha256", "0" * 64), ("abis", ["arm64-v8a"])):
            candidate = copy.deepcopy(DATA["currentCandidate"]); candidate[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError): probe.fixed_identity(candidate)
        for key, value in (("revision", probe.native.NATIVE), ("pck_sha256", "0" * 64)):
            candidate = copy.deepcopy(DATA["currentCandidate"]); candidate["godot"][key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError): probe.fixed_identity(candidate)

    def test_config_requires_four_cases_and_distinct_qa_identity(self):
        config = probe.load(probe.CONFIG)
        self.assertEqual(probe.verify_config(config)["cases"], probe.CASES)
        for key, value in (("cases", probe.CASES[:-1]), ("versionCode", 2031), ("caseAttempt", True)):
            bad = copy.deepcopy(config); bad[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError): probe.verify_config(bad)
        with self.assertRaises(RuntimeError): probe.verify_qa_identity(probe.SOURCE, QA_RUN)
        with self.assertRaises(RuntimeError): probe.verify_qa_identity(QA_COMMIT, probe.SOURCE_RUN)

    def test_only_new_supplemental_files_and_documentation_are_allowed(self):
        for path in probe.QA_FILES:
            self.assertTrue(probe.allowed_qa_path(path))
        for path in ("lib/core/foo.dart", "config/godot-source.json", ".github/probes/lumo_nextgen_reference_android_probe.py",
                     ".github/probes/lumo_nextgen_2031_native_runtime_cases.py", "tools/nextgen/prepare_current_learning_release.py",
                     "docs/../lib/foo.dart"):
            self.assertFalse(probe.allowed_qa_path(path), path)

    def test_origin_pins_actual_source_jobs_and_zip_artifact(self):
        run = {"id": probe.SOURCE_RUN, "head_sha": probe.SOURCE, "repository": {"full_name": probe.reference.REPOSITORY,
            "id": probe.reference.REPOSITORY_ID}, "path": ".github/workflows/lumo-nextgen-learning-apk.yml",
            "status": "completed", "conclusion": "success"}
        artifact = {"id": probe.ARTIFACT_ID, "name": probe.ARTIFACT_NAME, "size_in_bytes": probe.ZIP_BYTES,
            "digest": "sha256:" + probe.ZIP_SHA, "expired": False, "workflow_run": {"id": probe.SOURCE_RUN,
                "head_sha": probe.SOURCE, "repository_id": probe.reference.REPOSITORY_ID,
                "head_repository_id": probe.reference.REPOSITORY_ID}}
        jobs = [{"id": number, "run_id": probe.SOURCE_RUN, "head_sha": probe.SOURCE, "name": name,
            "status": "completed", "conclusion": "success", "steps": [{"name": "Independently verify both produced artifacts",
                                                                         "conclusion": "success"}]}
                for number, name in ((probe.VALIDATION_JOB, "validate"), (probe.BUILD_JOB, "build"))]
        probe.verify_origin(run, artifact, *jobs)
        for index, key, value in ((0, "head_sha", probe.native.SOURCE), (1, "digest", "sha256:" + "0" * 64),
                                  (2, "conclusion", "failure"), (3, "id", 1)):
            records = copy.deepcopy([run, artifact, *jobs]); records[index][key] = value
            with self.subTest(index=index, key=key), self.assertRaises(RuntimeError): probe.verify_origin(*records)


class CaseAcceptanceTests(unittest.TestCase):
    def test_observed_numeric_and_switch_subcases_keep_their_existing_gates(self):
        probe.verify_numeric_case(DATA["numeric"])
        probe.verify_switch_case(DATA["switch"])
        bad = copy.deepcopy(DATA["numeric"])
        bad["corrected"]["after"]["learning"] = copy.deepcopy(bad["wrong"]["after"]["learning"])
        with self.assertRaises(RuntimeError): probe.verify_numeric_case(bad)
        for mutate in ("stale", "restoration", "extra-answer"):
            case = copy.deepcopy(DATA["switch"])
            if mutate == "stale": case["capture_to_touch_seconds"] = 1.01
            elif mutate == "restoration": case["viewport"]["restored"]["display"]["density_dpi"] = 320
            else: case["checkpoint_after"]["attempt"] += 1
            with self.subTest(mutate=mutate), self.assertRaises(RuntimeError): probe.verify_switch_case(case)

    def test_historical_rate_metadata_is_explicitly_separate_from_current_binding(self):
        original = copy.deepcopy(DATA["banana"])
        current = probe.bind_current_banana(original)
        self.assertEqual(original["source_rate_contract"]["apk_source"], probe.native.SOURCE)
        self.assertEqual(current["source_rate_contract"]["apk_source"], probe.SOURCE)
        self.assertEqual(current["source_rate_contract"]["native_source"], probe.NATIVE)
        self.assertFalse(current["source_rate_contract"]["runtime_rate_measured"])
        probe.verify_banana_case(current, DATA["switch"]["before"]["profile"]["id"])
        with self.assertRaises(RuntimeError): probe.verify_banana_case(original, original["preservation"]["profile_id"])

    def test_current_banana_rejects_old_ids_wrong_profile_or_acoustic_claim(self):
        for mutate in ("old-id", "profile", "segments", "acoustic", "old-source"):
            case = probe.bind_current_banana(DATA["banana"])
            if mutate == "old-id": case["playback"]["utterance_ids"][0] = case["previous_ids"][0]
            elif mutate == "profile": case["playback"]["profile"] = "another-voice"
            elif mutate == "segments": case["playback"]["segments"] = 3
            elif mutate == "acoustic": case["acoustic_speed_verified"] = True
            else: case["source_rate_contract"]["native_source"] = probe.native.NATIVE
            with self.subTest(mutate=mutate), self.assertRaises(RuntimeError):
                probe.verify_banana_case(case, case["preservation"]["profile_id"])

    def test_actual_core_assessment_is_required_and_still_domain_checked(self):
        pattern, evidence = patterned_evidence()
        probe.verify_pattern_case(pattern, evidence)
        with self.assertRaises(RuntimeError): probe.verify_pattern_case(DATA["currentPattern"], evidence)
        for mutate in ("multiple", "wrong-task", "not-assisted"):
            changed = copy.deepcopy(evidence)
            key = next(k for k in changed["after"]["learning"] if "attempt_log" in k)
            attempts = json.loads(changed["after"]["learning"][key])
            if mutate == "multiple": attempts.append({**attempts[-1], "id": "another-synthetic-attempt"})
            elif mutate == "wrong-task": attempts[-1]["q"] = "different task"
            else: attempts[-1]["hint"] = False
            changed["after"]["learning"][key] = json.dumps(attempts)
            with self.subTest(mutate=mutate), self.assertRaises(RuntimeError): probe.verify_pattern_case(pattern, changed)

    def test_final_gate_requires_all_four_cases_current_identity_and_positive_videos(self):
        result = complete_synthetic_result()
        self.assertEqual(probe.verify_runtime_cases(result, qa_commit=QA_COMMIT, workflow_run_id=QA_RUN)["cases"], probe.CASES)
        for mutate in ("missing-pattern", "old-helper", "installed-hash", "publish", "zero-video", "product-diff", "old-source-record"):
            bad = copy.deepcopy(result)
            if mutate == "missing-pattern": bad["pattern"]["core_submission"] = {"status": "NOT_EXERCISED"}
            elif mutate == "old-helper": bad["helper_sha256"][probe.HELPERS[0]] = "0" * 64
            elif mutate == "installed-hash": bad["installed"]["sha256"] = "0" * 64
            elif mutate == "publish": bad["release_eligible"] = True
            elif mutate == "zero-video": bad["native_banana_slower"]["video"]["duration_seconds"] = 0
            elif mutate == "product-diff": bad["source_binding"]["changed_paths"].append("lib/core/lumo_voice.dart")
            else: bad["source_binding"]["source_rate_contract"]["apk_source"] = probe.native.SOURCE
            with self.subTest(mutate=mutate), self.assertRaises(RuntimeError):
                probe.verify_runtime_cases(bad, qa_commit=QA_COMMIT, workflow_run_id=QA_RUN)


if __name__ == "__main__":
    unittest.main()
