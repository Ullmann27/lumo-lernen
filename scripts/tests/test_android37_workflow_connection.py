"""Keep both real Android tour paths connected to the same candidate and probes.

These source contracts supplement the executable action/readiness counterexamples;
they do not assert that an emulator has booted or that an APK has passed its tour.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
from pathlib import Path
import re
import sys
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ("lumo-studio-2019", "lumo-kart-graphics-2019")
UPSTREAM = "a421e43855164a8197daf9d8d40fe71c6996bb0d"
LOCAL_ACTION = "./runner-actions/android-emulator-runner"


def tour_steps(workflow):
    source = (ROOT / ".github/workflows" / f"{workflow}.yml").read_text()
    job = source.split("  android-tour:\n", 1)[1].split(
        "  update-2019-from-2017:\n", 1)[0]
    return job, ["        " + step for step in re.split(r"(?m)^      - ", job)[1:]]


def field(step, name):
    match = re.search(rf"(?m)^        {re.escape(name)}: (.+)$", step)
    return match.group(1) if match else None


def script(step):
    match = re.search(r"(?m)^          script: \|\n((?:            [^\n]*\n)+)", step)
    if not match:
        raise AssertionError("The emulator action must execute the actual candidate tour")
    return [line[12:] for line in match.group(1).splitlines()]


class Android37WorkflowConnectionTests(unittest.TestCase):
    def test_each_matrix_api_runs_exactly_one_tour_of_the_same_candidate(self):
        for workflow in WORKFLOWS:
            with self.subTest(workflow=workflow):
                job, steps = tour_steps(workflow)
                self.assertIn("api: [35, 37]", job)
                actions = [step for step in steps
                           if "android-emulator-runner" in (field(step, "uses") or "")]
                self.assertEqual(len(actions), 2)
                self.assertEqual({field(step, "if") for step in actions},
                                 {"matrix.api == 35", "matrix.api == 37"})
                selected = {}
                for api in (35, 37):
                    matching = [step for step in actions if field(step, "if") == f"matrix.api == {api}"]
                    self.assertEqual(len(matching), 1)
                    selected[api] = matching[0]
                    self.assertIn("api-level: ${{ matrix.api == 37 && '37.0' || matrix.api }}", matching[0])
                    self.assertNotIn("continue-on-error", matching[0])
                self.assertEqual(field(selected[35], "uses"),
                                 f"reactivecircus/android-emulator-runner@{UPSTREAM}")
                self.assertEqual(field(selected[37], "uses"), LOCAL_ACTION)
                old_script, new_script = script(selected[35]), script(selected[37])
                self.assertEqual(new_script[1:], old_script)
                self.assertEqual(new_script[0], 'python3 "$GITHUB_WORKSPACE/scripts/android_framework_ready.py" stop --out "$GITHUB_WORKSPACE/tour/framework-start" --serial emulator-5554')
                self.assertEqual(len(old_script), 5)
                for command, probe in zip(old_script[-2:],
                        ("modernization_android_tour.py", "lumo_studio_surfaces_android_probe.py")):
                    self.assertTrue(command.startswith(f".probe-venv/bin/python .github/probes/{probe} "))
                    self.assertIn("--apk candidate/dist/x86_64/Lumo-Lernen-Neu.apk", command)
                    self.assertIn("--provenance candidate/dist/x86_64/BUILD-PROVENANCE.json", command)
                    self.assertIn("--sums candidate/dist/ANDROID-TOUR-SHA256SUMS.txt", command)
                self.assertIn("--prior-tour tour/tour-result.json --expected-api ${{ matrix.api }}", old_script[-1])

    def test_api37_preparation_is_source_bound_and_failures_preserve_diagnostics(self):
        for workflow in WORKFLOWS:
            with self.subTest(workflow=workflow):
                job, steps = tour_steps(workflow)
                markers = (
                    "repository: ReactiveCircus/android-emulator-runner",
                    "-p test_android_framework_ready.py",
                    "-p test_android37_cli22.py",
                    "scripts/prepare_android37_cli22.py prepare ",
                    "scripts/prepare_android37_emulator_action.py --action-dir ",
                    f"uses: {LOCAL_ACTION}",
                )
                indexes = []
                for marker in markers:
                    matches = [(index, step) for index, step in enumerate(steps) if marker in step]
                    self.assertEqual(len(matches), 1, marker)
                    index, step = matches[0]
                    indexes.append(index)
                    self.assertEqual(field(step, "if"), "matrix.api == 37")
                    self.assertNotIn("continue-on-error", step)
                    self.assertNotIn("|| true", step)
                self.assertEqual(indexes, sorted(indexes))
                self.assertIn(f"ref: {UPSTREAM}", steps[indexes[0]])
                self.assertIn("persist-credentials: false", steps[indexes[0]])
                binding = steps[indexes[-2]]
                context = "studio-matrix" if workflow == "lumo-studio-2019" else "graphics-matrix"
                self.assertIn(f"--workflow .github/workflows/{workflow}.yml --context {context}", binding)
                self.assertIn("SOURCE_SHA: ${{ github.event.pull_request.head.sha || github.sha }}", binding)
                self.assertIn('--probe-source "$SOURCE_SHA"', binding)
                self.assertIn('--apk-source "$SOURCE_SHA" --native-source "$native_revision"', binding)
                self.assertIn('config/godot-source.json', binding)
                action = steps[indexes[-1]]
                self.assertIn("emulator-port: 5554", action)
                self.assertIn("--phase before-boot", action)
                self.assertIn('android_framework_ready.py" start ', action)
                for marker in ("--phase after-action", "--allow-not-started"):
                    matches = [(i, step) for i, step in enumerate(steps) if marker in step]
                    self.assertEqual(len(matches), 1)
                    self.assertGreater(matches[0][0], indexes[-1])
                    self.assertEqual(field(matches[0][1], "if"), "always() && matrix.api == 37")
                self.assertEqual(field(steps[-1], "uses"), "actions/upload-artifact@v4")
                self.assertEqual(field(steps[-1], "if"), "always()")
                self.assertIn("path: tour/", steps[-1])
                self.assertIn(f"'{workflow}-android-17-tour'", steps[-1])

    def test_action_cli_accepts_the_graphics_context_and_rejects_unknown_contexts(self):
        spec = importlib.util.spec_from_file_location(
            "workflow_action_patch", ROOT / "scripts/prepare_android37_emulator_action.py")
        patcher = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(patcher)
        args = ["prepare_android37_emulator_action.py", "--action-dir", "/synthetic/action",
                "--out", "/synthetic/output", "--probe-source", "a" * 40,
                "--workflow", ".github/workflows/lumo-kart-graphics-2019.yml",
                "--apk-source", "a" * 40, "--native-source", "b" * 40, "--context"]
        with mock.patch.object(patcher, "prepare", return_value={
                "status": "SYNTHETIC_CALL_ONLY", "modified_files": {}}) as prepare:
            with mock.patch.object(sys, "argv", [*args, "graphics-matrix"]), contextlib.redirect_stdout(io.StringIO()):
                patcher.main()
            self.assertEqual(prepare.call_args.args[-1], "graphics-matrix")
            prepare.reset_mock()
            with mock.patch.object(sys, "argv", [*args, "unknown-matrix"]), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as rejected:
                    patcher.main()
            self.assertEqual(rejected.exception.code, 2)
            prepare.assert_not_called()


if __name__ == "__main__":
    unittest.main()
