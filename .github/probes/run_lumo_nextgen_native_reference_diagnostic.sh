#!/usr/bin/env bash
set -euo pipefail

# The emulator runner invokes this one Bash script, never separate sh lines.
# No original acceptance result or reset-success assertion is supplied here.
.probe-venv/bin/python .github/probes/lumo_nextgen_native_reference_diagnostic.py \
  --candidate candidate/x86 --download-evidence evidence/origin \
  --qa-commit "$GITHUB_SHA" --out evidence/diagnostic-android
