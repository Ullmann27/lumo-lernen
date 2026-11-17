from __future__ import annotations
import argparse
import ast
import hashlib
import json
import subprocess
from pathlib import Path
import yaml

BASE = "9c5a14d73679f68249d31db5401c489094ccf903"
FILES = [
    "lib/features/live/lumo_live_pro_screen.dart",
    "test/feature_permission_regression_test.dart",
    ".github/workflows/lumo-feature-connections.yml",
]

def blob(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()

parser = argparse.ArgumentParser()
parser.add_argument("--repo", required=True, type=Path)
parser.add_argument("--candidate", required=True, type=Path)
parser.add_argument("--output", required=True, type=Path)
args = parser.parse_args()
original = {p: subprocess.check_output(["git", "show", BASE + ":" + p], cwd=args.repo) for p in FILES}
candidate = {p: (args.candidate / p).read_bytes() for p in FILES}
checks = []

live = candidate[FILES[0]].decode()
reverted = live.replace(
    "  Future<void> _handleSafariAnswer(LearningProfileLease owner) async {\n    final revision = _modeRevision;",
    "  Future<void> _handleSafariAnswer(LearningProfileLease owner) async {",
)
assert reverted != live
assert reverted.count("if (_isCurrentInteraction(revision, owner)) _nextSafariAnimal();") == 2
reverted = reverted.replace(
    "if (_isCurrentInteraction(revision, owner)) _nextSafariAnimal();",
    "if (mounted && widget.appState.isCurrentLearningLease(owner)) _nextSafariAnimal();",
)
assert reverted.encode() == original[FILES[0]]
checks.append("Only one captured mode revision and the two delayed Safari guards change production bytes.")

old_test = original[FILES[1]].decode()
new_test = candidate[FILES[1]].decode()
old_cases = old_test[old_test.index("  testWidgets('Live word magic"):old_test.rfind("\n}")]
assert old_cases in new_test
assert new_test.count("'Live safari ${correct ? 'correct' : 'wrong'} answer keeps its delayed continuation bound during $continuation'") == 1
assert "for (final correct in [true, false])" in new_test
for item in ("word magic", "safari round trip", "unchanged safari", "profile change"):
    assert "      '" + item + "'," in new_test
assert "_handleSafariAnswer(" not in new_test
assert "_nextSafariAnimal(" not in new_test
assert "tester.state" not in new_test
assert "await pressAction(tester, 'Sprechen')" in new_test
assert "handlePlatformMessage(" in new_test
assert "'resultType': 2" in new_test
assert "await tester.tap(reward);" in new_test
checks.append("Every original feature test body remains byte-identical; eight parameter cases use public UI and the native speech message boundary.")

workflow = candidate[FILES[2]].decode()
reverted_workflow = workflow.replace("Execute exactly the 30 feature cases", "Execute exactly the 22 feature widget cases").replace('"expected_cases": 30', '"expected_cases": 22').replace('report["passed"] != 30', 'report["passed"] != 22')
assert reverted_workflow.encode() == original[FILES[2]]
parsed = yaml.safe_load(workflow)
steps = parsed["jobs"]["feature-widget-contracts"]["steps"]
step = next(s for s in steps if s.get("name") == "Require completed tests, zero skips and the exact case count")
python_source = step["run"].split("python3 - <<'PY'\n", 1)[1].rsplit("\nPY", 1)[0]
ast.parse(python_source)
compile(python_source, "feature-summary-heredoc", "exec")
assert '"expected_cases": 30' in python_source
assert 'report["passed"] != 30 or event_errors' in python_source
assert 'report["status"] == "PASS"' in python_source
checks.append("Workflow changes only its label and two exact case-count literals, preserving every existing gate and trigger; YAML and the changed Python heredoc parse.")

report = {
    "schema": 1,
    "base_commit": BASE,
    "base_tree": subprocess.check_output(["git", "rev-parse", BASE + "^{tree}"], cwd=args.repo).decode().strip(),
    "scope": FILES,
    "source_check_status": "PASS",
    "widget_execution": "NOT_RUN",
    "dart_compilation": "NOT_RUN",
    "checks": checks,
    "test_cardinality_by_source": {"prior": 22, "new": 8, "required_total": 30},
    "files": [{"path": p, "base_blob": blob(original[p]), "candidate_blob": blob(candidate[p]), "candidate_sha256": hashlib.sha256(candidate[p]).hexdigest(), "candidate_bytes": len(candidate[p])} for p in FILES],
}
args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(report, ensure_ascii=False, indent=2))
