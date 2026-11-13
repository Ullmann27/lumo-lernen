#!/usr/bin/env python3
"""Add one fail-closed readiness call to an exact upstream action checkout.

The upstream action, dependencies and LICENSE remain in their original checkout.
No dependency installation or TypeScript rebuild is performed. Both the readable
TypeScript and its checked-in JavaScript receive the same additive call; only the
JavaScript is executed by the action.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import re
import subprocess


UPSTREAM_REVISION = "a421e43855164a8197daf9d8d40fe71c6996bb0d"
ORIGINAL_HASHES = {
    "action.yml": "a7c4de9a466ae7d70a599ffdc5a27b2bccadd7b2d602e24b44f8b490cb7bbdfe",
    "LICENSE": "0b64a565cedfa1ac8d2cd7cf40965e6098f97f260fe51a4df9f697a063d0a8db",
    "src/main.ts": "a52d9ff8ea3b544677bbfaeb995b1db4d0cf8f9b520f34e25b0532250123358d",
    "lib/main.js": "8121ea56f1c89d470071e89f80e15f932b2d8d5f711c28fc99476f34a442bc35",
    "src/emulator-manager.ts": "1e9ca00c20d35d925440afc1ce82303c42cddc4c1ac196da65e39209ef87696f",
    "lib/emulator-manager.js": "a63db8fe9ffb4fb3651e9a2c97f8bac5ca4ce0078a7bbe61ef2e02019082c577",
}
MODIFIED_PATHS = ("src/emulator-manager.ts", "lib/emulator-manager.js")
GUARD_LINES = (
    "// LUMO modification: bounded framework readiness; original boot/keyevent/settings/cleanup remain unchanged.",
    "await exec.exec('python3', [`${process.env.GITHUB_WORKSPACE}/scripts/android_framework_ready.py`, 'wait', '--serial', `emulator-${port}`, '--out', `${process.env.GITHUB_WORKSPACE}/tour/framework-start`, '--timeout', '120', '--stable-seconds', '10', '--minimum-samples', '3', '--cli22-proof', `${process.env.GITHUB_WORKSPACE}/tour/framework-start/cli22`]);",
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_bytes(path: str, original: bytes) -> bytes:
    if path not in MODIFIED_PATHS or sha256(original) != ORIGINAL_HASHES[path]:
        raise ValueError(f"Unexpected upstream bytes: {path}")
    indent = "    " if path.endswith(".js") else "  "
    anchor = (
        f"{indent * 2}await waitForDevice(port, emulatorBootTimeout);\n"
        f"{indent * 2}await adb(port, `shell input keyevent 82`);"
    )
    text = original.decode("utf-8")
    if text.count(anchor) != 1:
        raise ValueError(f"Unique readiness insertion point missing: {path}")
    inserted = "".join(f"{indent * 2}{line}\n" for line in GUARD_LINES)
    return text.replace(anchor, anchor.replace("\n", "\n" + inserted, 1), 1).encode("utf-8")


def git(directory: Path, *args: str) -> str:
    return subprocess.check_output(
        ["git", "--no-replace-objects", "-C", str(directory), *args], text=True
    ).strip()


def prepare(action_dir: Path, out: Path, probe_root: Path, probe_source: str, workflow: str, apk_source: str, native_source: str, context: str) -> dict:
    if any(not re.fullmatch(r"[0-9a-f]{40}", value) for value in (probe_source, apk_source, native_source)):
        raise ValueError("Full probe, APK and native source revisions are required")
    workflow_path = (probe_root / workflow).resolve(strict=True)
    if not workflow_path.is_relative_to(probe_root) or not workflow.startswith(".github/workflows/"):
        raise ValueError("The actual invoking workflow must belong to the probe checkout")
    if git(action_dir, "rev-parse", "HEAD") != UPSTREAM_REVISION:
        raise ValueError("Action checkout is not the exact reviewed upstream commit")
    if git(action_dir, "status", "--porcelain", "--untracked-files=all"):
        raise ValueError("Action checkout must be clean before the additive patch")
    if git(probe_root, "rev-parse", "HEAD") != probe_source:
        raise ValueError("Unexpected actual diagnostic source commit")
    if git(probe_root, "status", "--porcelain", "--untracked-files=no"):
        raise ValueError("Tracked diagnostic source must be clean")
    originals = {}
    for relative, expected in ORIGINAL_HASHES.items():
        data = (action_dir / relative).read_bytes()
        if sha256(data) != expected:
            raise ValueError(f"Unexpected original action file: {relative}")
        originals[relative] = data
    patched = {path: patch_bytes(path, originals[path]) for path in MODIFIED_PATHS}
    out.mkdir(parents=True, exist_ok=True)
    if (out / "action-patch-manifest.json").exists():
        raise ValueError("Refusing to replace an existing action patch manifest")
    changes = []
    for relative, data in patched.items():
        (action_dir / relative).write_bytes(data)
        changes.append({
            "path": relative,
            "before_sha256": sha256(originals[relative]),
            "after_sha256": sha256(data),
            "before_bytes": len(originals[relative]),
            "after_bytes": len(data),
        })
        diff = "".join(difflib.unified_diff(
            originals[relative].decode().splitlines(keepends=True),
            data.decode().splitlines(keepends=True),
            fromfile=f"a/{relative}", tofile=f"b/{relative}",
        ))
        (out / (relative.replace("/", "-") + ".patch")).write_text(diff)
    actual_changed = set(git(action_dir, "diff", "--name-only").splitlines())
    if actual_changed != set(MODIFIED_PATHS):
        raise ValueError("Unexpected action mutation outside the two mirrored guard insertions")
    runtime_files = (
        workflow,
        "scripts/android_framework_ready.py",
        "scripts/prepare_android37_emulator_action.py",
        "scripts/tests/test_android_framework_ready.py",
        "scripts/prepare_android37_cli22.py",
        "scripts/tests/test_android37_cli22.py",
    )
    manifest = {
        "schema": 1,
        "status": "EXACT_UPSTREAM_PLUS_ADDITIVE_GUARD",
        "upstream_repository": "ReactiveCircus/android-emulator-runner",
        "upstream_revision": UPSTREAM_REVISION,
        "upstream_tree": git(action_dir, "rev-parse", "HEAD^{tree}"),
        "upstream_license_file": "LICENSE",
        "upstream_license_sha256": ORIGINAL_HASHES["LICENSE"],
        "license_note": "Original LICENSE retained byte-for-byte; it contains Apache License 2.0. Upstream package.json says MIT; neither metadata file is rewritten.",
        "original_verified_files": ORIGINAL_HASHES,
        "modified_files": changes,
        "source_and_execution": "Equivalent additive calls in src/emulator-manager.ts and checked-in lib/emulator-manager.js; no npm install, compilation, or other action modification.",
        "guard_position": "After original waitForDevice; before original input keyevent 82.",
        "original_calls_preserved": ["waitForDevice", "input keyevent 82", "settings put", "killEmulator"],
        "probe_revision": probe_source,
        "probe_tree": git(probe_root, "rev-parse", "HEAD^{tree}"),
        "probe_file_sha256": {path: sha256((probe_root / path).read_bytes()) for path in runtime_files},
        "invoking_workflow": workflow,
        "execution_context": context,
        "apk_source_revision": apk_source,
        "native_source_revision": native_source,
        "apk_binding_scope": "Caller-declared source identities; the unchanged original APK/provenance verifier must verify the actual binary independently.",
        "framework_readiness_claim": "Not yet tested; this manifest only binds the prepared action bytes.",
    }
    (out / "action-patch-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--action-dir", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--probe-root", type=Path, default=Path.cwd())
    parser.add_argument("--probe-source", required=True)
    parser.add_argument("--workflow", required=True)
    parser.add_argument("--apk-source", required=True)
    parser.add_argument("--native-source", required=True)
    parser.add_argument("--context", choices=("unchanged-apk-diagnostic", "studio-matrix"), required=True)
    args = parser.parse_args()
    result = prepare(args.action_dir.resolve(), args.out.resolve(), args.probe_root.resolve(), args.probe_source, args.workflow, args.apk_source, args.native_source, args.context)
    print(json.dumps({"status": result["status"], "upstream_revision": UPSTREAM_REVISION, "modified_files": result["modified_files"]}))


if __name__ == "__main__":
    main()
