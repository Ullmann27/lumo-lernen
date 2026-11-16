#!/usr/bin/env bash
set -euo pipefail

# One Bash command for emulator-runner. No acceptance tour, reset, or publisher.
.probe-venv/bin/python .github/probes/lumo_nextgen_2029_native_diagnostic.py run \
  --candidate candidate/x86 --download-evidence evidence/origin \
  --qa-commit "$GITHUB_SHA" --workflow-run-id "$GITHUB_RUN_ID" \
  --scene "$LUMO_DIAGNOSTIC_SCENE" --out evidence/diagnostic-android
