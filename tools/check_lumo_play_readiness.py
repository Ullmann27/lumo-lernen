#!/usr/bin/env python3
"""Read-only LUMO Google Play release blockers; no secrets, billing or publishing."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "scripts/prepare_android.py"
PUBSPEC = ROOT / "pubspec.yaml"
RELEASE_WORKFLOWS = ROOT / ".github/workflows"
REPORT_DIR = ROOT / "audit/play"
REPORT_DIR.mkdir(parents=True, exist_ok=True)

source = ANDROID.read_text(encoding="utf-8")
pub = PUBSPEC.read_text(encoding="utf-8")
v = re.search(r"^version:\s*(\S+)", pub, re.M)
if not v:
    raise SystemExit("Missing declared Flutter version")
release_config = re.search(r'getByName\("release"\)\s*\{(?P<body>.*?)\n\s*\}', source, re.S)
release_body = release_config.group("body") if release_config else ""
signing_uses_debug = 'signingConfigs.getByName("debug")' in release_body
if not release_config:
    raise SystemExit("No release signing configuration found")
native_apk_script = (ROOT / "scripts/build_unified_apk.sh").read_text(encoding="utf-8")
workflow_scripts = [f for f in RELEASE_WORKFLOWS.glob("*.yml")]
aab_entries = []
for path in workflow_scripts + list((ROOT / "scripts").glob("*.sh")):
    text = path.read_text(encoding="utf-8", errors="replace")
    if re.search(r'flutter\s+build\s+appbundle|:app:bundleRelease|\bbundletool\s+build-bundle', text):
        aab_entries.append(str(path.relative_to(ROOT)))
checks = [
    {
        "name": "release_signing_is_not_debug",
        "status": "BLOCKED" if signing_uses_debug else "NEEDS_MANUAL_SIGNING_REVIEW",
        "evidence": "scripts/prepare_android.py release signingConfig",
        "note": "Existing debug-signed family APK must not be relabelled as Play-upload signed."
    },
    {
        "name": "reproducible_aab_build_in_repo",
        "status": "CANDIDATE_EXISTS_NEEDS_VERIFICATION" if aab_entries else "BLOCKED",
        "sources": aab_entries,
        "note": "A build script is not a verified production bundle or successful Play submission."
    },
    {
        "name": "target_sdk_36_or_newer",
        "status": "NEEDS_COMPILED_BUNDLE_VERIFICATION",
        "note": "Determine targetSdk from exact Play AAB manifest, not a Flutter setting alone."
    },
    {
        "name": "children_policy_consent_and_data_safety",
        "status": "NEEDS_PLAY_CONSOLE_AND_PRIVACY_REVIEW",
        "note": "The repository cannot establish current account declarations and child eligibility."
    },
    {
        "name": "signed_aab_asset_delivery_and_16kb",
        "status": "NEEDS_DEVICE_AND_BUNDLE_INSPECTION",
        "note": "Validate Play App Signing, PCK packaging, 16KiB ELF layout, AAB/PAD limits."
    },
    {
        "name": "real_fold7_and_in_place_upgrade",
        "status": "NEEDS_PHYSICAL_HARDWARE_EVIDENCE",
        "note": "Flutter CI and simulator success cannot establish Fold7 FPS, temperature, or storage upgrade safety."
    },
]
report = {
    "project": "Ullmann27/lumo-lernen", "version": v.group(1),
    "purpose": "read-only blocker inventory; not a Play approval",
    "status": "BLOCKED",
    "checks": checks, "play_release_approved": False,
    "auto_publish": False, "auto_spend": False,
}
out = REPORT_DIR / "play-readiness.json"
out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(json.dumps(report, indent=2, ensure_ascii=False))
