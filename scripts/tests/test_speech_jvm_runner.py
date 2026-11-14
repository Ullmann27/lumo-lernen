"""Fail-closed orchestration contracts; no Kotlin/Gradle/download is executed.

The tiny JARs below are format-boundary fixtures, never compiler artifacts.
Actual 11 Java / 8 Kotlin production contracts run only in the dedicated runner.
"""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "speech_jvm_runner", ROOT / "scripts/run_speech_jvm_contracts.py")
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class SpeechJvmRunnerTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="speech-runner-contract-")
        self.addCleanup(self.temporary.cleanup)
        self.work = Path(self.temporary.name)
        self.root = self.work / "repo"
        self.root.mkdir()
        self.cache = self.work / "gradle-cache"
        self.home = self.cache / "wrapper/dists/gradle-9.1.0-bin/fixture-url-hash/gradle-9.1.0"
        properties = self.root / "android/gradle/wrapper/gradle-wrapper.properties"
        properties.parent.mkdir(parents=True)
        properties.write_text(
            "distributionBase=GRADLE_USER_HOME\n"
            "distributionPath=wrapper/dists\n"
            "distributionUrl=https\\://services.gradle.org/distributions/gradle-9.1.0-bin.zip\n")
        self.properties = properties
        self.environment = {"GRADLE_USER_HOME": str(self.cache)}

    def cached_distribution(self, home=None):
        home = home or self.home
        executable = home / "bin/gradle"
        executable.parent.mkdir(parents=True)
        executable.write_text("#!/bin/sh\nexit 99\n")
        executable.chmod(0o755)
        libraries = home / "lib"
        libraries.mkdir()
        for name, member in (
            ("kotlin-compiler-embeddable-2.2.0.jar", "org/jetbrains/kotlin/cli/jvm/K2JVMCompiler.class"),
            ("kotlin-stdlib-2.2.0.jar", "kotlin/Unit.class"),
        ):
            with zipfile.ZipFile(libraries / name, "w") as archive:
                archive.writestr(member, bytes.fromhex("cafebabe") + b"synthetic-format-only")
        return executable

    def result(self, name):
        count = RUNNER.GROUPS[name]["cases"]
        return {"module": name, "successful": True, "tests_run": count,
                "test_ids": [name + ".Contract.test_" + str(i) for i in range(count)],
                "failures": 0, "errors": 0, "skips": 0,
                "expected_failures": 0, "unexpected_successes": 0}

    def log(self, name):
        return "\n".join(marker + ("3" if marker.endswith("=") else "")
                         for marker in RUNNER.GROUPS[name]["markers"]) + "\n"

    def test_missing_distribution_cannot_bootstrap_or_use_global_gradle(self):
        with mock.patch.object(RUNNER.subprocess, "Popen") as process:
            with self.assertRaisesRegex(RuntimeError, "no download or global Gradle fallback"):
                RUNNER.existing_distribution(self.root, self.environment)
            process.assert_not_called()

    def test_pull_request_binds_actual_head_instead_of_synthetic_merge(self):
        event = self.work / "event.json"
        event.write_text(json.dumps({"pull_request": {"head": {
            "sha": "a" * 40, "repo": {"full_name": "Ullmann27/lumo-lernen"}}}}))
        environment = {"GITHUB_EVENT_NAME": "pull_request", "GITHUB_SHA": "b" * 40,
                       "GITHUB_EVENT_PATH": str(event), "GITHUB_REPOSITORY": "Ullmann27/lumo-lernen"}
        self.assertEqual(RUNNER.expected_ci_source(environment), "a" * 40)
        for event_name in ("push", "workflow_dispatch"):
            self.assertEqual(RUNNER.expected_ci_source({**environment, "GITHUB_EVENT_NAME": event_name}), "b" * 40)

    def test_foreign_or_missing_pull_request_payload_cannot_supply_sources(self):
        event = self.work / "event.json"
        event.write_text(json.dumps({"pull_request": {"head": {
            "sha": "a" * 40, "repo": {"full_name": "foreign/fork"}}}}))
        environment = {"GITHUB_EVENT_NAME": "pull_request", "GITHUB_SHA": "b" * 40,
                       "GITHUB_EVENT_PATH": str(event), "GITHUB_REPOSITORY": "Ullmann27/lumo-lernen"}
        with self.assertRaisesRegex(RuntimeError, "same-repository"):
            RUNNER.expected_ci_source(environment)
        del environment["GITHUB_EVENT_PATH"]
        with self.assertRaisesRegex(RuntimeError, "original event payload"):
            RUNNER.expected_ci_source(environment)

    def test_ambiguous_cached_distribution_is_rejected(self):
        self.cached_distribution()
        self.cached_distribution(self.home.parent.parent / "other-url-hash/gradle-9.1.0")
        with self.assertRaisesRegex(RuntimeError, "Exactly one"):
            RUNNER.existing_distribution(self.root, self.environment)

    def test_nonstandard_wrapper_cache_is_rejected(self):
        self.cached_distribution()
        self.properties.write_text(self.properties.read_text().replace("wrapper/dists", "custom-cache"))
        with self.assertRaisesRegex(RuntimeError, "Unsupported wrapper cache layout"):
            RUNNER.existing_distribution(self.root, self.environment)

    def test_invalid_compiler_class_is_rejected(self):
        self.cached_distribution()
        with zipfile.ZipFile(self.home / "lib/kotlin-compiler-embeddable-2.2.0.jar", "w") as archive:
            archive.writestr("org/jetbrains/kotlin/cli/jvm/K2JVMCompiler.class", b"not-bytecode")
        with self.assertRaisesRegex(RuntimeError, "Invalid existing Kotlin library"):
            RUNNER.existing_distribution(self.root, self.environment)

    def test_two_compiler_versions_are_rejected(self):
        self.cached_distribution()
        compiler = self.home / "lib/kotlin-compiler-embeddable-2.2.0.jar"
        (compiler.parent / "kotlin-compiler-embeddable-2.1.0.jar").write_bytes(compiler.read_bytes())
        with self.assertRaisesRegex(RuntimeError, "One existing Kotlin compiler"):
            RUNNER.existing_distribution(self.root, self.environment)

    def test_offline_command_uses_observed_distribution_not_wrapper(self):
        executable = self.cached_distribution()
        distribution = RUNNER.existing_distribution(self.root, self.environment)
        command = RUNNER.offline_gradle_command(distribution, self.root, self.work / "init.gradle")
        self.assertEqual(Path(command[0]), executable)
        self.assertIn("--offline", command)
        self.assertIn("--no-daemon", command)
        self.assertEqual(command[-1], "lumoSpeechJvmToolchain")
        self.assertFalse(any(Path(item).name == "gradlew" for item in command))
        self.assertEqual(distribution["version"], "9.1.0")
        self.assertEqual(len(distribution["libraries"]["jars"]), 2)

    def test_missing_jdk_refuses_inherited_skip_policy(self):
        with self.assertRaisesRegex(RuntimeError, "does not contain java and javac"):
            RUNNER.bound_environment({"REQUIRE_ALL_TESTS": "false"}, {
                "java_home": str(self.work / "missing"), "kotlin_lib_dir": str(self.home / "lib")})

    def test_resolved_jdk_and_strict_policy_override_inherited_environment(self):
        java_home = self.work / "actual-jdk"
        (java_home / "bin").mkdir(parents=True)
        for name in ("java", "javac"):
            (java_home / "bin" / name).touch()
        bound = RUNNER.bound_environment({"JAVA_HOME": "/wrong", "PATH": "/prior", "REQUIRE_ALL_TESTS": "false"}, {
            "java_home": str(java_home), "kotlin_lib_dir": str(self.home / "lib")})
        self.assertEqual(bound["JAVA_HOME"], str(java_home))
        self.assertEqual(bound["REQUIRE_ALL_TESTS"], "true")
        self.assertEqual(bound["LUMO_KOTLIN_LIB_DIR"], str(self.home / "lib"))
        self.assertEqual(bound["PATH"].split(os.pathsep)[0], str(java_home / "bin"))

    def test_complete_declared_rosters_have_positive_controls(self):
        for name in RUNNER.GROUPS:
            with self.subTest(group=name):
                RUNNER.validate_group(name, self.result(name), self.log(name))

    def test_partial_or_duplicate_test_roster_cannot_pass(self):
        name = "test_learning_english_speech_lifecycle"
        for fault in ("short", "duplicate", "foreign-module"):
            with self.subTest(fault=fault):
                result = self.result(name)
                if fault == "short":
                    result["tests_run"] -= 1
                    result["test_ids"].pop()
                elif fault == "duplicate":
                    result["test_ids"][-1] = result["test_ids"][0]
                else:
                    result["test_ids"][-1] = "unrelated.Contract.test_only"
                with self.assertRaisesRegex(RuntimeError, "roster is incomplete"):
                    RUNNER.validate_group(name, result, self.log(name))

    def test_skip_expected_failure_or_error_is_not_success(self):
        name = "test_learning_english_speech_lifecycle"
        for key in ("failures", "errors", "skips", "expected_failures", "unexpected_successes"):
            with self.subTest(field=key):
                result = self.result(name)
                result[key] = 1
                with self.assertRaisesRegex(RuntimeError, "may not fail, skip"):
                    RUNNER.validate_group(name, result, self.log(name))

    def test_missing_duplicate_and_unexecuted_markers_fail_closed(self):
        name = "test_learning_english_speech_lifecycle"
        lines = self.log(name).splitlines()
        for log in ("\n".join(lines[1:]), self.log(name) + lines[0],
                    self.log(name).replace(lines[0], "expected marker: " + lines[0])):
            with self.subTest(log=log):
                with self.assertRaisesRegex(RuntimeError, "Missing or duplicate actual contract marker"):
                    RUNNER.validate_group(name, self.result(name), log)

    def compile_evidence(self):
        classes = {}
        for name in RUNNER.PRODUCTS:
            path = self.root / "build/app/contract-fixture" / (name + ".class")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(bytes.fromhex("cafebabe") + name.encode())
            binding = RUNNER.measure(path)
            classes[name] = [{"path": str(path.relative_to(self.root)),
                              "bytes": binding["bytes"], "sha256": binding["sha256"]}]
        report = {"status": "PASS", "flutter_source_commit": "a" * 40, "classes": classes}
        destination = self.root / "host-compile-evidence/result.json"
        destination.parent.mkdir()
        destination.write_text(json.dumps(report))
        return report, destination

    def test_compile_source_and_class_bytes_must_both_match(self):
        report, destination = self.compile_evidence()
        RUNNER.verify_host_compile(self.root, "a" * 40)
        with self.assertRaisesRegex(RuntimeError, "exact checkout"):
            RUNNER.verify_host_compile(self.root, "b" * 40)
        compiled = self.root / report["classes"][RUNNER.PRODUCTS[0]][0]["path"]
        compiled.write_bytes(compiled.read_bytes() + b"changed")
        with self.assertRaisesRegex(RuntimeError, "Compiled class changed"):
            RUNNER.verify_host_compile(self.root, "a" * 40)

    def test_foreign_class_path_cannot_satisfy_compile_binding(self):
        report, destination = self.compile_evidence()
        report["classes"][RUNNER.PRODUCTS[0]][0]["path"] = "../unrelated.class"
        destination.write_text(json.dumps(report))
        with self.assertRaisesRegex(RuntimeError, "escapes the actual build"):
            RUNNER.verify_host_compile(self.root, "a" * 40)

    def test_deadline_retains_original_output_and_never_reports_success(self):
        log = self.work / "timeout-original.log"
        result = RUNNER.run_command(
            [sys.executable, "-c", "import time; print('original-start',flush=True); time.sleep(10)"],
            self.work, dict(os.environ), log, 0.25)
        self.assertTrue(result["timed_out"])
        self.assertNotEqual(result["exit_code"], 0)
        self.assertEqual(log.read_text(), "original-start\n")
        self.assertEqual(result["log_binding"], RUNNER.measure(log))
        self.assertLess(result["duration_seconds"], 5)

    def test_child_records_skip_as_failure_without_claiming_jvm_execution(self):
        directory = self.root / "scripts/speech_contracts"
        directory.mkdir(parents=True)
        (directory / "transport_contract.py").write_text(
            "import unittest\nclass TransportOnly(unittest.TestCase):\n"
            " @unittest.skip('synthetic unavailable compiler')\n"
            " def test_unavailable(self): pass\n")
        child = self.work / "child.py"
        child.write_text(RUNNER.CHILD)
        report = self.work / "result.json"
        result = subprocess.run([sys.executable, "-B", str(child), "transport_contract", str(self.root), str(report)],
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(json.loads(report.read_text())["skips"], 1)
        self.assertNotIn("LUMO_SPEECH_LIFECYCLE_PASS", result.stdout)

    def test_broad_discovery_does_not_collect_dedicated_jvm_modules(self):
        broad = self.root / "scripts/tests"
        dedicated = self.root / "scripts/speech_contracts"
        broad.mkdir(parents=True)
        dedicated.mkdir()
        (broad / "test_existing.py").write_text("import unittest\nclass Existing(unittest.TestCase):\n def test_yes(self): pass\n")
        for name in RUNNER.GROUPS:
            (dedicated / (name + ".py")).write_text("raise AssertionError('broad discovery must not import speech contracts')\n")
        result = subprocess.run([sys.executable, "-B", "-m", "unittest", "discover", "-s", str(broad), "-v"],
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Ran 1 test", result.stderr)
        self.assertFalse((dedicated / "__init__.py").exists())
        RUNNER.verify_contract_layout(self.root)
        (broad / "test_learning_english_speech_lifecycle.py").write_text("# misplaced copy\n")
        with self.assertRaisesRegex(RuntimeError, "must not also enter broad unittest discovery"):
            RUNNER.verify_contract_layout(self.root)


if __name__ == "__main__":
    unittest.main()
