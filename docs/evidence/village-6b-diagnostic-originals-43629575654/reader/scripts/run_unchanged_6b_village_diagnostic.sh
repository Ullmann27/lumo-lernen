#!/usr/bin/env bash
# Diagnose the exact already-built 2020 APK with a separate committed observer.
set -euo pipefail

diagnostic_case="${1:?Expected main or update2017}"
case "$diagnostic_case" in
  main|update2017) ;;
  *) echo "Unknown unchanged-2020 diagnostic case: $diagnostic_case" >&2; exit 2 ;;
esac

diagnostic_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
diagnostic_python="$diagnostic_root/.probe-venv/bin/python"
diagnostic_source="$diagnostic_root/candidate-source"
diagnostic_dist="$diagnostic_root/candidate/dist"
diagnostic_out="$diagnostic_root/tour"
test -x "$diagnostic_python"
test -s "$diagnostic_out/candidate-and-probe-binding.json"
test "$(git -C "$diagnostic_source" rev-parse HEAD)" = 6b3047b7979dfb86d837e74a21b0fd890e4f9e66
test "$(git -C "$diagnostic_root" rev-parse HEAD)" = "${QA_SOURCE:?Missing exact diagnostic source}"
export PYTHONDONTWRITEBYTECODE=1
export GIT_OPTIONAL_LOCKS=0
export LUMO_NATIVE_STAGE_MENU=1
export LUMO_CANDIDATE_SOURCE_SHA=6b3047b7979dfb86d837e74a21b0fd890e4f9e66

diagnostic_bind=(
  "$diagnostic_python" "$diagnostic_root/scripts/verify_unchanged_6b_village_diagnostic.py"
  --qa-source "$diagnostic_root" --candidate-source "$diagnostic_source"
  --candidate-metadata-dir "$diagnostic_out/binding-inputs/candidate"
  --qa-metadata-dir "$diagnostic_out/binding-inputs/qa"
  --expected-qa-source "$QA_SOURCE" --expected-qa-run "${GITHUB_RUN_ID:?}"
  --expected-qa-attempt "${GITHUB_RUN_ATTEMPT:?}"
  --qa-job-name "unchanged-6b-${diagnostic_case}-api35"
  --apk "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk"
  --provenance "$diagnostic_dist/x86_64/BUILD-PROVENANCE.json"
  --sums "$diagnostic_dist/ANDROID-TOUR-SHA256SUMS.txt"
)
if [ "$diagnostic_case" = update2017 ]; then
  diagnostic_bind+=(
    --baseline "$diagnostic_root/baseline/dist/x86_64/Lumo-Lernen-Neu.apk"
    --baseline-metadata-dir "$diagnostic_out/binding-inputs/baseline"
  )
fi

finish_diagnostic() {
  local probe_exit=$? binding_exit receipt_exit
  trap - EXIT
  set +e
  "${diagnostic_bind[@]}" --out "$diagnostic_out/candidate-and-probe-binding-after.json"
  binding_exit=$?
  "$diagnostic_python" - "$diagnostic_out" "$diagnostic_case" "$probe_exit" "$binding_exit" <<'PY'
import hashlib
import json
from pathlib import Path
import sys

out, case = Path(sys.argv[1]), sys.argv[2]
probe_exit, binding_exit = map(int, sys.argv[3:5])
original = out / ('main/tour-result.json' if case == 'main' else 'update/update-result.json')
record = None
if original.is_file() and not original.is_symlink():
    raw = original.read_bytes()
    result = json.loads(raw)
    record = {'path': str(original.relative_to(out)), 'bytes': len(raw),
              'sha256': hashlib.sha256(raw).hexdigest(), 'status': result.get('status')}
extra = {}
if case == 'main':
    for name in ('village/village-result.json', 'c4/c4-result.json', 'c4-diagnostic-replay.json'):
        path = out / name
        if path.is_file() and not path.is_symlink():
            raw = path.read_bytes()
            value = json.loads(raw)
            extra[name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(),
                           'status': value.get('status')}
passed = (probe_exit == 0 and binding_exit == 0 and record is not None and record['status'] == 'PASS'
          and (case != 'main' or (len(extra) == 3 and all(v['status'] == 'PASS' for v in extra.values()))))
receipt = {'schema': 1, 'case': case, 'status': 'PASS' if passed else 'FAIL',
           'probe_exit_code': probe_exit, 'postflight_binding_exit_code': binding_exit,
           'original_result': record, 'roundtrip_results': extra, 'seven_job_acceptance': False,
           'scope': 'Isolated unchanged-APK diagnostic only; original run remains unchanged and no release is approved.'}
path = out / 'diagnostic-result.json'
with path.open('x') as stream:
    stream.write(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
if not passed:
    raise SystemExit(1)
PY
  receipt_exit=$?
  if [ "$probe_exit" -ne 0 ]; then exit "$probe_exit"; fi
  if [ "$binding_exit" -ne 0 ]; then exit "$binding_exit"; fi
  exit "$receipt_exit"
}
trap finish_diagnostic EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

adb shell getprop ro.build.version.sdk > "$diagnostic_out/android-sdk.txt"
adb shell getprop ro.build.version.release > "$diagnostic_out/android-release.txt"
test "$(tr -d '\r\n' < "$diagnostic_out/android-sdk.txt")" = 35
"${ANDROID_HOME:?}/emulator/emulator" -version > "$diagnostic_out/android-emulator-version.txt" 2>&1
sha256sum "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk" > "$diagnostic_out/tested-apk-sha256.txt"

# The actual APK identity reader uses this checkout's immutable HEAD and pin.
# Absolute observer paths and their imports continue to use the distinct QA tree.
cd "$diagnostic_source"
if [ "$diagnostic_case" = update2017 ]; then
  "$diagnostic_python" "$diagnostic_root/.github/probes/lumo_2020_update_android_probe.py" \
    --baseline "$diagnostic_root/baseline/dist/x86_64/Lumo-Lernen-Neu.apk" \
    --candidate "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk" --out "$diagnostic_out/update"
else
  "$diagnostic_python" "$diagnostic_root/.github/probes/modernization_android_tour.py" \
    --apk "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk" \
    --provenance "$diagnostic_dist/x86_64/BUILD-PROVENANCE.json" \
    --sums "$diagnostic_dist/ANDROID-TOUR-SHA256SUMS.txt" --out "$diagnostic_out/main"
  for diagnostic_mode in village c4; do
    "$diagnostic_python" "$diagnostic_root/.github/probes/lumo_6b_roundtrip_diagnostic.py" "$diagnostic_mode" \
      --apk "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk" \
      --provenance "$diagnostic_dist/x86_64/BUILD-PROVENANCE.json" \
      --sums "$diagnostic_dist/ANDROID-TOUR-SHA256SUMS.txt" \
      --out "$diagnostic_out/$diagnostic_mode" --prior-tour "$diagnostic_out/main/tour-result.json" \
      --metadata-dir "$diagnostic_out/binding-inputs/candidate" \
      --diagnostic-binding "$diagnostic_out/candidate-and-probe-binding.json" \
      --expected-source 6b3047b7979dfb86d837e74a21b0fd890e4f9e66 --expected-qa-source "$QA_SOURCE" \
      --expected-native 84789d0c2c6fb4b6ecd2897ce1951b89f958b604 \
      --build-run 43616038272 --run-attempt 1 --artifact-id 14125990109 \
      --artifact-digest sha256:1332b1d6604ae45c622bc70fa08a6d40991f5e8c9332466c17622135b81b11a6
  done
fi

