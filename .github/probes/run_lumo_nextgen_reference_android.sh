#!/usr/bin/env bash
# The emulator runner invokes each script line with /bin/sh. Keep the ordered
# probes and their shared fail-fast policy inside one explicitly selected Bash.
set -euo pipefail

.probe-venv/bin/python .github/probes/lumo_nextgen_learning_android_probe.py --apk candidate/x86/Lumo-Lernen-Neu.apk --provenance candidate/x86/BUILD-PROVENANCE.json --expected-sha256 "$LUMO_APK_SHA256" --expected-source "$LUMO_APK_SOURCE" --expected-native "$LUMO_NATIVE_SOURCE" --expected-version 2027 --expected-certificate "$LUMO_CERTIFICATE" --out evidence/original-android
.probe-venv/bin/python .github/probes/lumo_nextgen_reference_android_probe.py run --candidate candidate/x86 --download-evidence evidence/origin --previous-probe-out evidence/original-android --submit-core-answer --qa-commit "$GITHUB_SHA" --out evidence/reference-android
