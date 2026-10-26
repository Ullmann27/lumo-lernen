#!/usr/bin/env bash
set -euo pipefail
split_apks="${LUMO_SPLIT_PER_ABI:-0}"
build_aab="${LUMO_BUILD_AAB:-0}"
case "$build_aab" in
  0|1) ;;
  *) echo 'LUMO_BUILD_AAB must be 0 or 1' >&2; exit 1 ;;
esac
case "$split_apks" in
  0|1) ;;
  *) echo 'LUMO_SPLIT_PER_ABI must be 0 or 1' >&2; exit 1 ;;
esac
require_clean_sources() {
  if ! git diff --quiet HEAD --; then
    echo 'Build rejected: tracked source differs from the candidate commit.' >&2
    git diff HEAD --name-status >&2
    exit 1
  fi
  if [ -n "$(git ls-files --others --exclude-standard -- lib config assets)" ]; then
    echo 'Build rejected: uncommitted app input would escape candidate provenance.' >&2
    exit 1
  fi
}
require_clean_sources
# Maven Central throttles shared CI addresses (HTTP 404 + Retry-After or 429);
# that broke Flutter's Kotlin plugin resolution in Actions run 38896179742.
# On CI, resolve Maven Central artifacts through Google's official mirror
# first. Declared repositories and all versions stay unchanged as fallback.
if [ "${CI:-}" = true ] || [ "${LUMO_GRADLE_CENTRAL_MIRROR:-0}" = 1 ]; then
  gradle_init_dir="${GRADLE_USER_HOME:-$HOME/.gradle}/init.d"
  mkdir -p "$gradle_init_dir"
  cp scripts/gradle/lumo-maven-central-mirror.init.gradle "$gradle_init_dir/"
  sha256sum "$gradle_init_dir/lumo-maven-central-mirror.init.gradle"
fi
version_values=$(python3 scripts/build_version.py)
read -r lumo_version_name lumo_build_number <<< "$version_values"
if [ ! -d android ]; then
  # A Flutter scaffold may replace dependency metadata even with --no-pub.
  # Generate outside this repository and copy ONLY its native Android host.
  host_scaffold="$(mktemp -d "${TMPDIR:-/tmp}/lumo-host.XXXXXXXX")"
  trap 'rm -rf "$host_scaffold"' EXIT
  flutter create --no-pub --project-name lumo_lernen --platforms=android \
    --org dev.ullmann.lumo "$host_scaffold/scaffold"
  cp -a "$host_scaffold/scaffold/android" android
fi
require_clean_sources
python3 scripts/prepare_android.py --side-by-side
python3 scripts/prepare_embedded_games.py
python3 scripts/prepare_offline_voice.py
# Isolated build-only image tooling; no global pip or app dependency changes.
python3 -m venv build/lumo-icon-tools
build/lumo-icon-tools/bin/python -m pip install --disable-pip-version-check \
  --only-binary=:all: -r scripts/requirements-icons.txt
build/lumo-icon-tools/bin/python -m unittest discover -s scripts/icon_tests -v
build/lumo-icon-tools/bin/python scripts/prepare_launcher_icons.py
python3 scripts/export_embedded_game.py "${@}"
flutter pub get --enforce-lockfile
require_clean_sources
split_options=()
if [ "$split_apks" = 1 ]; then
  split_options+=(--split-per-abi)
  # Validate the actual fully configured Gradle outputs before compiling.
  # This is a configuration-only task: no second Flutter/native APK build.
  (cd android && ./gradlew :app:verifyLumoSplitVersionCodes \
    -Psplit-per-abi=true -Ptarget-platform=android-arm64,android-x64)
fi
flutter build apk --no-pub --release --target-platform android-arm64,android-x64 \
  "${split_options[@]}" \
  --build-number "$lumo_build_number" --build-name "$lumo_version_name" \
  --dart-define=LUMO_BUILD_NUMBER="$lumo_build_number" \
  --dart-define=LUMO_VERSION_NAME="$lumo_version_name" \
  --dart-define=LUMO_SIDE_BY_SIDE=true
require_clean_sources
mkdir -p dist
write_provenance() {
python3 - "$1" <<'PY'
import json
import subprocess
import sys
from pathlib import Path
directory = Path(sys.argv[1])
info = json.loads((directory / 'APK-VERIFICATION.json').read_text())
info['flutter_source_commit'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
info['tracked_source_clean'] = not subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], text=True).strip()
info['source_trees'] = {name: subprocess.check_output(['git', 'rev-parse', 'HEAD:' + name], text=True).strip()
                        for name in ('lib', 'config', 'assets', 'tools')}
if not info['tracked_source_clean']:
    raise RuntimeError('Source changed after build; refuse candidate provenance')
info['launcher'] = json.loads(Path('dist/LAUNCHER-RESOURCES.json').read_text())
(directory / 'BUILD-PROVENANCE.json').write_text(json.dumps(info, indent=2) + '\n')
PY
}
if [ "$split_apks" = 1 ]; then
  for abi in arm64-v8a x86_64; do
    destination=dist
    if [ "$abi" = x86_64 ]; then destination=dist/x86_64; fi
    mkdir -p "$destination"
    source_apk="build/app/outputs/flutter-apk/app-${abi}-release.apk"
    python3 scripts/verify_unified_apk.py "$source_apk" --abi "$abi" \
      | tee "$destination/APK-VERIFICATION.json"
    cp "$source_apk" "$destination/Lumo-Lernen-Neu.apk"
    (cd "$destination" && sha256sum Lumo-Lernen-Neu.apk > SHA256SUMS.txt)
    write_provenance "$destination"
  done
else
  python3 scripts/verify_unified_apk.py build/app/outputs/flutter-apk/app-release.apk \
    | tee dist/APK-VERIFICATION.json
  cp build/app/outputs/flutter-apk/app-release.apk dist/Lumo-Lernen-Neu.apk
  (cd dist && sha256sum Lumo-Lernen-Neu.apk > SHA256SUMS.txt)
  write_provenance dist
fi
if [ "$build_aab" = 1 ]; then
  # Reuse this exact prepared native host, source, PCK, voice and Dart defines.
  # This public-key-signed bundle is a staging artifact, never a Play upload.
  flutter build appbundle --no-pub --release --target-platform android-arm64,android-x64 \
    --build-number "$lumo_build_number" --build-name "$lumo_version_name" \
    --dart-define=LUMO_BUILD_NUMBER="$lumo_build_number" \
    --dart-define=LUMO_VERSION_NAME="$lumo_version_name" \
    --dart-define=LUMO_SIDE_BY_SIDE=true
  require_clean_sources
  bash scripts/verify_unified_aab.sh
  require_clean_sources
fi
