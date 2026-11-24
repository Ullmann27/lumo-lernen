#!/usr/bin/env python3
"""Reuse one reviewed core run, only for the bounded request-43 exporter repair.

No package, signing, PCK, or Android result is reused. GitHub must independently
confirm successful core steps, the complete old job log must match its reviewed
canonical hash, and all non-allowlisted Git leaves must be identical.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

POLICY = {
    "repository": "Ullmann27/lumo-lernen",
    "baseline_run": 45148445440,
    "baseline_job": 137603486783,
    "baseline_commit": "351ec6418264ec0f69d7c65d0fcb4dc1a71c4fb8",
    "godot_revision": "c9619c589e3a9faa0b56f190fb38a61bf44bb1d6",
    "native_run": 45148095909,
}
WORKFLOW = ".github/workflows/lumo-kart-action-apk.yml"
REQUEST = "config/test-apk-request.json"
PIN = "config/godot-source.json"
CHECKER = ".github/probes/verify_prior_core.py"
ALLOWED = frozenset((
    "scripts/export_embedded_game.py",
    "scripts/tests/test_export_embedded_game.py",
    WORKFLOW, CHECKER, REQUEST,
))
# UTF-8 (optional initial BOM removed), CRLF/CR -> LF, exactly one final LF.
# All remaining characters, timestamps, ANSI codes and internal BOMs are retained.
LOG_SHA256 = "e41308ae8490986f7bb3900d9d7a47b2383fe6136a3a3b0102b76ba22997a54e"
ENGINE = "Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org"
BUILD_STEP = "Eine signierte Flutter-Godot-APK bauen"
CORE_STEPS = (
    "Quellstand und Godot-Pin festhalten",
    "Android- und Godot-Werkzeuge einrichten",
    "Native Sprache, Lerndialog und Datensicherung – JVM-Verträge",
    "Flutter – Analyse und Kernprüfungen",
    "Godot – gepinnter Spielstand startet und besteht seine Kernprüfungen",
    "Exakten Spielstand gegen vollständige native Prüfung absichern",
)
# Exact successful summaries from the reviewed run, including every count.
PROBES = (
    ("lumo_run_loop_regression", r"\[LumoRun\] PASS: 69 checks"),
    ("kart_dyno_parts_regression", r"\[KartDynoParts\] PASS 921 checks"),
    ("kart_evolution_regression", r"\[KartEvolution\] PASS checks=112196 pairwise=1877 sampled=5760 actual_race_setups=4 boundary_race_setups=3"),
    ("kart_action_spectacle_regression", r"\[KartSpectacle\] PASS tracks=15 errors=0"),
    ("kart_loop_seam_regression", r"\[LoopSeam\] PASS: 4 loops join the road seamlessly"),
    ("kart_sonnenhafen_stunt_regression", r"\[SonnenhafenStunt\] PASS: real loop, boost pad, stars, safe exit and safe failure"),
    ("kart_action_course_regression", r"\[KartActionCourse\] PASS: 12 Strecken ohne Überlagerung, Turbo-Feld, Slalom mit Hütchen, Sprungschanze mit Landung, Unterwasser-Tunnel, offene Kante mit fairer Rettung"),
    ("kart_neon_home_regression", r'\[NeonHome\] \{"checks":163,"failures":\[\],"status":"PASS"\}'),
    ("kart_garage_landscape_regression", r"\[GarageLandscape\] PASS: 88 checks"),
    ("kart_race_kinds_regression", r"\[KartRaceKinds\] PASS: 133 checks; five race kinds and START on 4 displays"),
    ("kart_result_reachability_regression", r"\[KartResultReach\] PASS: all result actions reachable on 11 display sizes"),
    ("native_table_boot_regression", r"\[NativeTableBoot\] PASS 26 actual boot, resource and authority-context checks"),
    ("learning_android_host_capability_regression", r'\{"checks":43,"failures":\[\],"scope":"4\.6\.3 capability dispatch and actual routed Stop owners; no Android audio or device PASS claim","status":"PASS","test":"learning_android_host_capability"\}'),
    ("native_learning_boot_regression", r"\[NativeLearningBoot\] PASS 41 actual boot, plan and task-context checks"),
    ("lumo_kart_production_driver_regression", r"\[ProductionDriver\] checks=8200 failures=0 imported=27 maximum_hand_error_m=0\.00020463427063"),
    ("lumo_opponent_roster_regression", r"\[OpponentRoster\] checks=131 failures=0"),
    ("kart_extra_drivers_regression", r"EXTRA_DRIVERS_PASS checks=79 failures=0"),
    ("learning_holo_lesson_regression", r"\[HoloLesson\] checks=1336 failures=0"),
    ("lumo_run_stunt_relay_regression", r"\[RunRelay\] PASS"),
    ("kart_arena_battle_regression", r"ARENA_BATTLE_PASS checks=16 failures=0"),
    ("parcours_menu_entry_regression", r"\[ParcoursMenu\] PASS: 8 Prüfungen"),
    ("parcours_race_regression", r"\[ParcoursRace\] PASS"),
    ("lumo_run_regression", r"\[LumoRun\] PASS: 511 checks"),
    ("lumo_run_flow_regression", r"\[LumoFlow\] PASS: 13 checks"),
    ("quiz_studio_escape_regression", r'\{"checks":14,"failures":\[\],"status":"PASS","test":"quiz_studio_escape"\}'),
    ("learning_tutor_regression (validation, invalid, return, voice)", r"\[Tutor\] PASS checks=107 failures=0"),
)
FAULT = re.compile(r"SCRIPT ERROR:|Parse Error:|Compile Error:|ERROR:[^\r\n]*p_size")
STAMP = re.compile(r"^\ufeff?(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)(?:\.\d+)?Z (.*)$")
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
MAX_BYTES = 64 * 1024 * 1024


class Rejected(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise Rejected(message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def git_blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class GitHub:
    def __init__(self, token):
        require(bool(token), "GH_TOKEN is required for immutable job-log access")
        self.token = token
        self.opener = urllib.request.build_opener(NoRedirect)

    def _read(self, url, authenticated):
        parsed = urllib.parse.urlsplit(url)
        require(parsed.scheme == "https" and parsed.hostname and
                not parsed.username and not parsed.password and
                parsed.port in (None, 443), "Unsafe GitHub/download URL")
        require(not authenticated or parsed.hostname == "api.github.com",
                "Refusing to send GH_TOKEN outside api.github.com")
        headers = {"User-Agent": "lumo-reviewed-core-resume/1",
                   "Accept": "application/vnd.github+json"}
        if authenticated:
            headers["Authorization"] = "Bearer " + self.token
            headers["X-GitHub-Api-Version"] = "2022-11-28"
        request = urllib.request.Request(url, headers=headers)
        with self.opener.open(request, timeout=60) as response:
            data = response.read(MAX_BYTES + 1)
        require(len(data) <= MAX_BYTES, "GitHub response exceeds size limit")
        return data

    def get(self, path):
        require(path.startswith("/repos/") and "?" not in path,
                "Unexpected API resource path")
        try:
            data = self._read("https://api.github.com" + path, True)
        except urllib.error.HTTPError as error:
            raise Rejected("GitHub JSON API failed with HTTP " + str(error.code)) from None
        return json.loads(data)

    def log(self, repo, job):
        url = "https://api.github.com/repos/%s/actions/jobs/%d/logs" % (repo, job)
        try:
            return self._read(url, True)
        except urllib.error.HTTPError as error:
            require(error.code == 302, "GitHub job-log endpoint did not return a log")
            location = error.headers.get("Location", "")
        # A distinct request without Authorization; no implicit redirects.
        host = urllib.parse.urlsplit(location).hostname or ""
        require(host.endswith((".blob.core.windows.net", ".githubusercontent.com")),
                "Unexpected GitHub signed-log download host")
        try:
            return self._read(location, False)
        except urllib.error.HTTPError as error:
            raise Rejected("Signed log download failed with HTTP " + str(error.code)) from None


def tree(api, repo, commit):
    data = api.get("/repos/%s/git/commits/%s" % (repo, commit))
    require(data["sha"] == commit, "Commit API returned a different source")
    tree_sha = data["tree"]["sha"]
    # The fixed API path is safe; add the one controlled query separately.
    data = json.loads(api._read(
        "https://api.github.com/repos/%s/git/trees/%s?recursive=1" % (repo, tree_sha), True))
    require(data.get("sha") == tree_sha and data.get("truncated") is False,
            "Incomplete or mismatched recursive Git tree")
    leaves = {}
    for row in data["tree"]:
        if row["type"] == "tree":
            continue
        path = row["path"]
        require(path not in leaves and not path.startswith("/") and
                ".." not in path.split("/"), "Invalid duplicate/tree path")
        leaves[path] = {key: row[key] for key in ("mode", "type", "sha")}
    require(leaves, "Empty Git tree")
    return tree_sha, leaves


def blob(api, repo, entry):
    require(entry["type"] == "blob" and entry["mode"] == "100644",
            "Expected regular tracked source file")
    data = api.get("/repos/%s/git/blobs/%s" % (repo, entry["sha"]))
    require(data.get("sha") == entry["sha"] and data.get("encoding") == "base64",
            "Unexpected source blob")
    raw = base64.b64decode("".join(data["content"].split()), validate=True)
    require(git_blob(raw) == entry["sha"], "Git source blob hash mismatch")
    return raw


def compare_trees(before, after):
    changed = {path for path in before.keys() | after.keys()
               if before.get(path) != after.get(path)}
    require(changed == ALLOWED,
            "Source differences are not exactly the five reviewed exporter/CI/request paths: " +
            ", ".join(sorted(changed)))
    for path in changed:
        require(path in after and after[path]["mode"] == "100644" and
                after[path]["type"] == "blob", "Deleted or non-regular exception: " + path)
        if path in before:
            require(before[path]["mode"] == after[path]["mode"] and
                    before[path]["type"] == after[path]["type"],
                    "Changed exception file mode/type: " + path)
    for path in (PIN, "pubspec.yaml", "pubspec.lock"):
        require(path in before and before[path] == after.get(path),
                "Missing/changed mandatory product dependency or Godot pin: " + path)
    product = [[path, before[path]] for path in sorted(before) if path not in ALLOWED]
    return {
        "unchanged_leaves": len(product),
        "unchanged_product_sha256": sha256(json.dumps(product, sort_keys=True).encode()),
        "changed_paths": [{"path": p, "before": before.get(p), "after": after[p]}
                          for p in sorted(changed)],
    }


def check_metadata(run, job, native):
    require(run.get("id") == POLICY["baseline_run"] and
            run.get("head_sha") == POLICY["baseline_commit"] and
            run.get("repository", {}).get("full_name") == POLICY["repository"] and
            run.get("path") == WORKFLOW and run.get("run_attempt") == 1 and
            run.get("status") == "completed" and run.get("conclusion") == "failure",
            "Baseline run identity, attempt or conclusion mismatch")
    require(job.get("id") == POLICY["baseline_job"] and
            job.get("run_id") == POLICY["baseline_run"] and
            job.get("head_sha") == POLICY["baseline_commit"] and
            job.get("run_attempt") == 1 and job.get("status") == "completed" and
            job.get("conclusion") == "failure" and
            job.get("name") == "Signierte Test-APK bauen", "Baseline job identity mismatch")
    steps = job["steps"]
    checked = {}
    for name in CORE_STEPS:
        matches = [step for step in steps if step["name"] == name]
        require(len(matches) == 1 and matches[0]["status"] == "completed" and
                matches[0]["conclusion"] == "success", "Core step is not successful: " + name)
        step = matches[0]
        require(step.get("started_at") and step.get("completed_at") and
                step["started_at"] <= step["completed_at"], "Incomplete step timing: " + name)
        checked[name] = step
    failed = [step for step in steps if step["conclusion"] == "failure"]
    require(len(failed) == 1 and failed[0]["name"] == BUILD_STEP,
            "Baseline has a different or additional failed step")
    numbers = [checked[name]["number"] for name in CORE_STEPS] + [failed[0]["number"]]
    require(numbers == sorted(set(numbers)), "Core/build steps are out of order")
    require(native.get("id") == POLICY["native_run"] and
            native.get("repository", {}).get("full_name") == "Ullmann27/lumo-godot" and
            native.get("head_sha") == POLICY["godot_revision"] and
            native.get("path") == ".github/workflows/kart-action-20261123.yml" and
            native.get("run_attempt") == 1 and native.get("status") == "completed" and
            native.get("conclusion") == "success", "Exact native source gate is not successful")
    return checked


def canonical_log(raw):
    return raw.decode("utf-8-sig").replace("\r\n", "\n").replace("\r", "\n").rstrip("\n") + "\n"


def parse_groups(text):
    lines, timestamps, groups, stack = [], [], {}, []
    stamp = ""
    for number, raw in enumerate(text.splitlines(), 1):
        match = STAMP.match(raw)
        if match:
            stamp, line = match.groups()
        else:
            line = raw
        lines.append(line)
        timestamps.append(stamp)
        if line.startswith("##[group]"):
            stack.append((line[len("##[group]"):], number - 1))
        elif line == "##[endgroup]":
            require(stack, "Unmatched log group terminator")
            name, start = stack.pop()
            groups.setdefault(name, []).append((start, number - 1))
    require(not stack, "Truncated/open job-log group")
    return lines, timestamps, groups


def verify_log(raw, steps):
    text = canonical_log(raw)
    require(sha256(text.encode()) == LOG_SHA256,
            "Previous job log does not match its reviewed canonical SHA256")
    require(not FAULT.search(text), "Previous job log contains a guarded Godot runtime error")
    lines, timestamps, groups = parse_groups(text)
    files, records, intervals = {}, [], []
    step = steps[CORE_STEPS[4]]
    for name, success in PROBES:
        found = groups.get(name, [])
        require(len(found) == 1, "Missing or duplicated complete probe group: " + name)
        start, end = found[0]
        require(step["started_at"][:19] <= timestamps[start] <= timestamps[end] <=
                step["completed_at"][:19], "Probe lies outside successful Godot step: " + name)
        body = "\n".join(lines[start + 1:end]) + "\n"
        clean = ANSI.sub("", body)
        require(ENGINE in clean.splitlines() and
                len(re.findall("^" + success + "$", clean, re.MULTILINE)) == 1,
                "Missing engine or exact successful probe summary: " + name)
        require(not any(line.startswith("##[group]") for line in lines[start + 1:end]),
                "Nested/incomplete probe log: " + name)
        filename = "GODOT-" + name.split(" ", 1)[0] + ".txt"
        files[filename] = body.encode("utf-8")
        records.append({"probe": name, "status": "PASS", "log_file": filename,
                        "job_log_lines": [start + 2, end],
                        "reconstructed_sha256": sha256(files[filename])})
        intervals.append((start, end))
    require(intervals == sorted(intervals), "Probe sequence differs from reviewed workflow")
    observed = [name for name in groups if name.endswith("_regression") or
                name.startswith("learning_tutor_regression")]
    require(set(observed) == {name for name, _ in PROBES},
            "Unexpected or missing Godot regression group")
    first = intervals[0][0]
    imports = [i for i in range(first) if lines[i] == ENGINE and
               timestamps[i] >= step["started_at"][:19]]
    require(len(imports) == 1, "Cannot unambiguously reconstruct successful first import")
    files["GODOT-import-first.txt"] = ("\n".join(lines[imports[0]:first]) + "\n").encode()
    flutter = [i for i, line in enumerate(lines)
               if re.fullmatch(r"\d\d:\d\d \+650: All tests passed!", ANSI.sub("", line))]
    require(len(flutter) == 1, "Missing exact Flutter 650-test success")
    stop = flutter[0]
    fstep = steps[CORE_STEPS[3]]
    require(fstep["started_at"][:19] <= timestamps[stop] <= fstep["completed_at"][:19],
            "Flutter summary lies outside its successful step")
    starts = [i for i in range(stop) if lines[i].startswith("00:00 +0: loading ")]
    require(len(starts) == 1, "Ambiguous Flutter test output")
    files["FLUTTER-CORE-TESTS.txt"] = ("\n".join(lines[starts[0]:stop + 1]) + "\n").encode()
    analysis = [i for i in range(starts[0]) if lines[i].startswith("Analyzing lumo-lernen...")]
    require(len(analysis) == 1, "Missing Flutter analysis output")
    files["FLUTTER-ANALYSIS.txt"] = ("\n".join(lines[analysis[0]:starts[0]]) + "\n").encode()
    native_line = "Exact native source gate: PASS https://github.com/Ullmann27/lumo-godot/actions/runs/%d" % POLICY["native_run"]
    require(lines.count(native_line) == 1, "Missing exact native gate success in job log")
    require("died with <Signals.SIGSEGV: 11>" in text,
            "Baseline no longer describes the reviewed exporter SIGSEGV")
    return files, records, {"raw_sha256": sha256(raw), "canonical_sha256": LOG_SHA256,
                           "normalization": "UTF-8-sig; CRLF/CR to LF; exactly one terminal LF",
                           "guarded_runtime_errors": 0, "flutter_tests": 650}


def verify_sources(api, repo, commit):
    before_sha, before = tree(api, repo, POLICY["baseline_commit"])
    after_sha, after = tree(api, repo, commit)
    result = compare_trees(before, after)
    read = lambda entries, path: blob(api, repo, entries[path])
    current_request = json.loads(read(after, REQUEST))
    old_request = json.loads(read(before, REQUEST))
    require(current_request.get("reuse_verified_core") == POLICY and
            current_request.get("request") == 43 and old_request.get("request") == 41,
            "Missing or different explicit request-43 reuse policy")
    require(set(current_request) == set(old_request) | {"reuse_verified_core"},
            "Unexpected request fields")
    require({k: v for k, v in current_request.items() if k not in ("request", "note", "reuse_verified_core")} ==
            {k: v for k, v in old_request.items() if k not in ("request", "note")},
            "Product/version request fields changed")
    pin = json.loads(read(after, PIN))
    require(pin.get("revision") == POLICY["godot_revision"] and pin.get("engine") == "4.6.3" and
            pin.get("repository") == "https://github.com/Ullmann27/lumo-godot.git",
            "Different embedded Godot source or engine")
    tail = "      - name: " + BUILD_STEP + "\n"
    old_workflow = read(before, WORKFLOW).decode()
    new_workflow = read(after, WORKFLOW).decode()
    require(old_workflow.count(tail) == new_workflow.count(tail) == 1 and
            old_workflow.split(tail, 1)[1] == new_workflow.split(tail, 1)[1],
            "Export/PCK/signing/Android/publishing gates were changed")
    result.update({"baseline_tree": before_sha, "current_tree": after_sha,
                   "godot_revision": pin["revision"], "engine": pin["engine"],
                   "post_core_workflow_identical": True})
    return result, after


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("repo", "commit", "baseline-run", "baseline-job", "baseline-commit", "output"):
        parser.add_argument("--" + name, required=True,
                            type=int if name in ("baseline-run", "baseline-job") else str)
    args = parser.parse_args()
    try:
        require(args.repo == POLICY["repository"] and args.baseline_run == POLICY["baseline_run"] and
                args.baseline_job == POLICY["baseline_job"] and
                args.baseline_commit == POLICY["baseline_commit"], "CLI baseline is not the reviewed run")
        require(re.fullmatch(r"[0-9a-f]{40}", args.commit) is not None and
                args.commit != args.baseline_commit, "Current commit must be a new full SHA")
        root = Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip())
        require(subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip() ==
                args.commit, "Local checkout differs from requested current commit")
        require(subprocess.run(["git", "diff", "--quiet", "HEAD", "--"], cwd=root).returncode == 0,
                "Tracked working source differs from the committed tree")
        output = Path(args.output) / "REUSED-CORE-SOURCE.json"
        require(not output.exists(), "Refusing to overwrite the reuse success record")
        api = GitHub(os.environ.get("GH_TOKEN", ""))
        source, current_tree = verify_sources(api, args.repo, args.commit)
        require(git_blob(Path(__file__).read_bytes()) == current_tree[CHECKER]["sha"],
                "Executed checker differs from its committed source")
        base = "/repos/" + args.repo
        run = api.get(base + "/actions/runs/" + str(args.baseline_run))
        job = api.get(base + "/actions/jobs/" + str(args.baseline_job))
        native = api.get("/repos/Ullmann27/lumo-godot/actions/runs/" + str(POLICY["native_run"]))
        steps = check_metadata(run, job, native)
        raw = api.log(args.repo, args.baseline_job)
        files, probes, log_proof = verify_log(raw, steps)
        files["REUSED-CORE-ORIGINAL-JOB.txt"] = raw
        files["REUSED-CORE-BASELINE-JOB.json"] = (json.dumps(job, indent=2) + "\n").encode()
        native_record = {key: native.get(key) for key in
                         ("id", "head_sha", "status", "conclusion", "html_url", "run_attempt")}
        files["NATIVE-KART-SOURCE-QA.json"] = (json.dumps(native_record, indent=2) + "\n").encode()
        output.parent.mkdir(parents=True, exist_ok=True)
        require(not any((output.parent / name).exists() for name in files),
                "Refusing to overwrite current/prior proof files")
        record = {
            "status": "PASS", "scope": "unchanged Flutter/Godot core tests only",
            "current_commit": args.commit, "baseline": POLICY,
            "baseline_job_url": "https://github.com/%s/actions/runs/%d/job/%d" %
                                (args.repo, args.baseline_run, args.baseline_job),
            "source_equivalence": source, "successful_steps": list(steps.values()),
            "log": log_proof, "probes": probes,
            "reconstruction": "Probe outputs are extracted from complete original job-log groups; "
                              "GitHub timestamp prefixes/group delimiters removed. They are not "
                              "claimed byte-identical to the unuploaded former runner files.",
            "fresh_checks_required": ["Godot import/export", "PCK runtime", "APK identity/signature",
                                      "installed Android tour", "native starts", "backup roundtrip"],
            "files": {name: {"bytes": len(data), "sha256": sha256(data)}
                      for name, data in files.items()},
        }
        for name, data in files.items():
            with (output.parent / name).open("xb") as handle:
                handle.write(data)
        # The only success record is written after every check and proof write.
        with output.open("x") as handle:
            handle.write(json.dumps(record, indent=2, ensure_ascii=False) + "\n")
        print("[VerifiedCoreReuse] PASS: 26 full Godot probes, 650 Flutter tests; unchanged product tree")
        return 0
    except (Rejected, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print("[VerifiedCoreReuse] REJECTED: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

