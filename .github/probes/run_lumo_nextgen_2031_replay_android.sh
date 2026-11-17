#!/usr/bin/env bash
# The emulator action starts this single Bash command through /bin/sh.
# A failed original tour must never enter the reference tour or reset its app.
set -euo pipefail

.probe-venv/bin/python .github/probes/lumo_nextgen_learning_android_probe.py --apk candidate/x86/Lumo-Lernen-Neu.apk --provenance candidate/x86/BUILD-PROVENANCE.json --expected-sha256 "$LUMO_EXPECTED_SHA256" --expected-source "$LUMO_EXPECTED_SOURCE" --expected-native "$LUMO_EXPECTED_NATIVE" --expected-version "$LUMO_EXPECTED_VERSION" --expected-certificate "$LUMO_CERTIFICATE" --out evidence/android/original-android
.probe-venv/bin/python .github/probes/lumo_nextgen_2031_replay_reference_android_probe.py run --candidate candidate/x86 --download-evidence evidence/download --previous-probe-out evidence/android/original-android --qa-commit "$GITHUB_SHA" --workflow-run-id "$GITHUB_RUN_ID" --submit-core-answer --out evidence/android/reference-android
