#!/usr/bin/env bash
set -euo pipefail
require_clean_sources() {
  if ! git diff --quiet HEAD --; then
    echo 'Build rejected: tracked source differs from the candidate commit.' >&2
    git diff HEAD --name-status >&2
    exit 1
  fi
}
require_clean_sources
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
# Isolated build-only image tooling; no global pip or app dependency changes.
python3 -m venv build/lumo-icon-tools
build/lumo-icon-tools/bin/python -m pip install --disable-pip-version-check \
  --only-binary=:all: -r scripts/requirements-icons.txt
build/lumo-icon-tools/bin/python -m unittest discover -s scripts/icon_tests -v
build/lumo-icon-tools/bin/python scripts/prepare_launcher_icons.py
python3 scripts/export_embedded_game.py "${@}"
flutter pub get --enforce-lockfile
require_clean_sources
flutter build apk --no-pub --release --target-platform android-arm64,android-x64 \
  --build-number "${LUMO_BUILD_NUMBER:-1502}" --build-name "${LUMO_VERSION_NAME:-0.10.8}" \
  --dart-define=LUMO_BUILD_NUMBER="${LUMO_BUILD_NUMBER:-1502}" \
  --dart-define=LUMO_VERSION_NAME="${LUMO_VERSION_NAME:-0.10.8}" \
  --dart-define=LUMO_SIDE_BY_SIDE=true
require_clean_sources
mkdir -p dist
python3 scripts/verify_unified_apk.py build/app/outputs/flutter-apk/app-release.apk | tee dist/APK-VERIFICATION.json
cp build/app/outputs/flutter-apk/app-release.apk dist/Lumo-Lernen-Neu.apk
(cd dist && sha256sum Lumo-Lernen-Neu.apk > SHA256SUMS.txt)
python3 - <<'PY'
import json
import subprocess
from pathlib import Path
info = json.loads(Path('dist/APK-VERIFICATION.json').read_text())
info['flutter_source_commit'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
info['tracked_source_clean'] = not subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], text=True).strip()
if not info['tracked_source_clean']:
    raise RuntimeError('Source changed after build; refuse candidate provenance')
info['launcher'] = json.loads(Path('dist/LAUNCHER-RESOURCES.json').read_text())
Path('dist/BUILD-PROVENANCE.json').write_text(json.dumps(info, indent=2) + '\n')
PY
