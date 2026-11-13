#!/usr/bin/env bash
# Reuse the original production gates with explicit, different app/probe sources.
set -euo pipefail
api="${1:?Expected API 35 or 37}"
case "$api" in 35|37) ;; *) echo 'Only API 35 or 37 is supported' >&2; exit 2 ;; esac
probe_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apk_source="$probe_root/apk-source"
tour_out="$probe_root/tour"
dist="$probe_root/candidate/dist"
python="$probe_root/.probe-venv/bin/python"

# The unchanged verify_apk_identity() intentionally reads cwd's real Git HEAD,
# pubspec and Godot pin. No source value or verification function is overridden.
cd "$apk_source"
test "$(git rev-parse HEAD)" = e3d161cb2f79b732ac2dbafc2764b151247f018b
adb shell getprop ro.build.version.sdk > "$tour_out/android-sdk.txt"
adb shell getprop ro.build.version.release > "$tour_out/android-release.txt"
"$ANDROID_HOME/emulator/emulator" -version > "$tour_out/android-emulator-version.txt" 2>&1
"$python" "$probe_root/.github/probes/modernization_android_tour.py" \
  --apk "$dist/x86_64/Lumo-Lernen-Neu.apk" \
  --provenance "$dist/x86_64/BUILD-PROVENANCE.json" \
  --sums "$dist/ANDROID-TOUR-SHA256SUMS.txt" --out "$tour_out"
"$python" "$probe_root/.github/probes/lumo_studio_surfaces_android_probe.py" \
  --apk "$dist/x86_64/Lumo-Lernen-Neu.apk" \
  --provenance "$dist/x86_64/BUILD-PROVENANCE.json" \
  --sums "$dist/ANDROID-TOUR-SHA256SUMS.txt" \
  --prior-tour "$tour_out/tour-result.json" --expected-api "$api" --out "$tour_out/nextgen"
"$python" "$probe_root/scripts/verify_android_recheck_identity.py" \
  --phase after --dist "$dist" --out "$tour_out" --apk-source-checkout "$apk_source" \
  --probe-source "$LUMO_RECHECK_PROBE_SOURCE" --expected-api "$api"
