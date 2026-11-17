#!/usr/bin/env bash
# The emulator runner starts this one command through /bin/sh. Bash owns both
# ordered probes; a failed original tour never enters the additional tour.
set -euo pipefail

.probe-venv/bin/python .github/probes/lumo_nextgen_learning_android_probe.py --apk candidate/x86/Lumo-Lernen-Neu.apk --provenance candidate/x86/BUILD-PROVENANCE.json --expected-sha256 "$LUMO_EXPECTED_SHA256" --expected-source "$LUMO_EXPECTED_SOURCE" --expected-native "$LUMO_EXPECTED_NATIVE" --expected-version "$LUMO_EXPECTED_VERSION" --expected-certificate "$LUMO_CERTIFICATE" --out evidence/android/original-android
.probe-venv/bin/python .github/probes/lumo_nextgen_current_reference_android_probe.py --candidate candidate/x86 --previous-probe-out evidence/android/original-android --qa-commit "$GITHUB_SHA" --workflow-run-id "$GITHUB_RUN_ID" --expected-sha256 "$LUMO_EXPECTED_SHA256" --expected-source "$LUMO_EXPECTED_SOURCE" --expected-native "$LUMO_EXPECTED_NATIVE" --expected-version "$LUMO_EXPECTED_VERSION" --expected-version-name "$LUMO_EXPECTED_VERSION_NAME" --expected-certificate "$LUMO_CERTIFICATE" --submit-core-answer --out evidence/android/reference-android
