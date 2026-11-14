#!/usr/bin/env bash
# Run repaired observers against the independently checked, unchanged 7b16 APK.
set -euo pipefail

diagnostic_case="${1:?Expected api35, api37-host, api37-swiftshader or update2017}"
case "$diagnostic_case" in
  api35|api37-host|api37-swiftshader|update2017) ;;
  *) echo "Unknown diagnostic case: $diagnostic_case" >&2; exit 2 ;;
esac

diagnostic_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
diagnostic_python="$diagnostic_root/.probe-venv/bin/python"
diagnostic_source="$diagnostic_root/candidate-source"
diagnostic_dist="$diagnostic_root/candidate/dist"
diagnostic_out="$diagnostic_root/tour"
test -s "$diagnostic_out/candidate-and-probe-binding.json"
test -x "$diagnostic_python"
test "$(git -C "$diagnostic_source" rev-parse HEAD)" = 7b16f2f5ab16f3d913ee170aefd9807c87216260
export PYTHONDONTWRITEBYTECODE=1
export LUMO_NATIVE_STAGE_MENU=1

finish_android17() {
  local tour_exit_code=$? verification_exit_code
  trap - EXIT
  set +e
  "$diagnostic_python" "$diagnostic_root/scripts/verify_android_runtime_anr.py" finish \
    --framework-out "$diagnostic_out/framework-start" \
    --out "$diagnostic_out/runtime-anr" --serial emulator-5554 \
    --tour-exit-code "$tour_exit_code"
  verification_exit_code=$?
  if [ "$tour_exit_code" -eq 0 ] && [ "$verification_exit_code" -ne 0 ]; then
    tour_exit_code=$verification_exit_code
  fi
  exit "$tour_exit_code"
}

if [[ "$diagnostic_case" == api37-* ]]; then
  # Keep the full startup stream. Before root can restart its ADB transport,
  # prove overlap with an independent device logger that covers root, both
  # tours and the final system dumps without reconnecting or clearing its file.
  "$diagnostic_python" "$diagnostic_root/scripts/verify_android_runtime_anr.py" begin \
    --framework-out "$diagnostic_out/framework-start" \
    --out "$diagnostic_out/runtime-anr" --serial emulator-5554 --preserve-through-adb-root
  export LUMO_RUNTIME_ANR_START="$diagnostic_out/runtime-anr/runtime-start.json"
  trap finish_android17 EXIT
  trap 'exit 143' TERM
  trap 'exit 130' INT
  timeout 20s adb -s emulator-5554 shell dumpsys SurfaceFlinger \
    > "$diagnostic_out/surfaceflinger-start.stdout" \
    2> "$diagnostic_out/surfaceflinger-start.stderr"
  python3 - "$diagnostic_root" "$diagnostic_case" <<'PY'
import hashlib
import json
from pathlib import Path
import sys

root, case = Path(sys.argv[1]), sys.argv[2]
out = root / 'tour'
baseline_path = root / 'config/diagnostic-baselines/android37-7b16.json'
baseline = json.loads(baseline_path.read_text())
framework = out / 'framework-start'
readiness = json.loads((framework / 'framework-readiness.json').read_text())
hardware_path = framework / 'cli22/avd-guard/configuration/hardware-qemu.ini'
hardware = {}
for line in hardware_path.read_text().splitlines():
    if '=' in line:
        key, value = line.split('=', 1)
        key = key.strip()
        if key in hardware:
            raise ValueError('Duplicate effective hardware field: ' + key)
        hardware[key] = value.strip()
package_files = {}
for relative in baseline['package_files']:
    data = (framework / 'cli22/packages-guard' / relative).read_bytes()
    package_files[relative] = {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
gpu = 'swiftshader' if case == 'api37-swiftshader' else 'host'
gles = [line.strip() for line in (out / 'surfaceflinger-start.stdout').read_text().splitlines()
        if line.strip().startswith('GLES:')]
renderer_marker = 'swiftshader' if gpu == 'swiftshader' else 'llvmpipe'
checks = {
    'same_original_package_descriptor_and_properties': package_files == baseline['package_files'],
    'same_observed_android_fingerprint': bool(readiness['samples']) and all(
        sample['android_runtime'] == baseline['android_runtime'] for sample in readiness['samples']),
    'same_effective_non_graphics_hardware': all(
        hardware.get(key) == value for key, value in baseline['effective_hardware_unchanged'].items()),
    'effective_gpu_mode_matches_requested_case': hardware.get('hw.gpu.mode') == gpu,
    'one_actual_gles_renderer_matches_case': len(gles) == 1 and renderer_marker in gles[0].casefold(),
    'actual_framework_guard_passed': readiness.get('status') == 'PASS',
}
report = {
    'schema': 1, 'status': 'PASS' if all(checks.values()) else 'FAIL',
    'case': case, 'requested_gpu': gpu, 'observed_gles': gles,
    'baseline_sha256': hashlib.sha256(baseline_path.read_bytes()).hexdigest(),
    'original': baseline['original'], 'checks': checks, 'package_files': package_files,
    'effective_hardware': {key: hardware.get(key) for key in
                           (*baseline['effective_hardware_unchanged'], 'hw.gpu.mode')},
    'hardware_sha256': hashlib.sha256(hardware_path.read_bytes()).hexdigest(),
    'scope': 'Observed configuration and GLES renderer only. Complete startup/Vulkan logs, '
             'full runtime ANR observation and app-tour results remain separate requirements. '
             'No FPS or whole-system-image byte identity claim.',
}
(out / 'renderer-comparison-binding.json').write_text(json.dumps(report, indent=2) + '\n')
if not all(checks.values()):
    raise SystemExit('Android37 comparison mismatch: ' + ', '.join(key for key, ok in checks.items() if not ok))
PY
fi

adb shell getprop ro.build.version.sdk > "$diagnostic_out/android-sdk.txt"
adb shell getprop ro.build.version.release > "$diagnostic_out/android-release.txt"
"$ANDROID_HOME/emulator/emulator" -version > "$diagnostic_out/android-emulator-version.txt" 2>&1

if [ "$diagnostic_case" = update2017 ]; then
  export LUMO_CANDIDATE_SOURCE_SHA=7b16f2f5ab16f3d913ee170aefd9807c87216260
  cd "$diagnostic_source"
  "$diagnostic_python" "$diagnostic_root/.github/probes/lumo_2019_update_android_probe.py" \
    --baseline "$diagnostic_root/baseline/dist/x86_64/Lumo-Lernen-Neu.apk" \
    --candidate "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk" --out "$diagnostic_out"
else
  diagnostic_api=35
  if [[ "$diagnostic_case" == api37-* ]]; then diagnostic_api=37; fi
  (
    # The unchanged verifier reads this checkout's actual HEAD, version and pin.
    # Probe imports still resolve to their repaired source via absolute __file__.
    cd "$diagnostic_source"
    "$diagnostic_python" "$diagnostic_root/.github/probes/modernization_android_tour.py" \
      --apk "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk" \
      --provenance "$diagnostic_dist/x86_64/BUILD-PROVENANCE.json" \
      --sums "$diagnostic_dist/ANDROID-TOUR-SHA256SUMS.txt" --out "$diagnostic_out"
    "$diagnostic_python" "$diagnostic_root/.github/probes/lumo_studio_surfaces_android_probe.py" \
      --apk "$diagnostic_dist/x86_64/Lumo-Lernen-Neu.apk" \
      --provenance "$diagnostic_dist/x86_64/BUILD-PROVENANCE.json" \
      --sums "$diagnostic_dist/ANDROID-TOUR-SHA256SUMS.txt" \
      --prior-tour "$diagnostic_out/tour-result.json" \
      --expected-api "$diagnostic_api" --out "$diagnostic_out/nextgen"
  )
fi
