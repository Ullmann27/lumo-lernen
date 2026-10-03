#!/usr/bin/env bash
set -euo pipefail
if [ ! -d android ]; then
  flutter create --platforms=android --org dev.ullmann.lumo .
fi
python3 scripts/prepare_android.py --side-by-side
python3 scripts/prepare_embedded_games.py
python3 scripts/export_embedded_game.py "${@}"
flutter pub get --enforce-lockfile
flutter build apk --release --target-platform android-arm64,android-x64 \
  --build-number "${LUMO_BUILD_NUMBER:-276}" --build-name "${LUMO_VERSION_NAME:-0.10.1}" \
  --dart-define=LUMO_BUILD_NUMBER="${LUMO_BUILD_NUMBER:-276}" \
  --dart-define=LUMO_VERSION_NAME="${LUMO_VERSION_NAME:-0.10.1}" \
  --dart-define=LUMO_SIDE_BY_SIDE=true
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
Path('dist/BUILD-PROVENANCE.json').write_text(json.dumps(info, indent=2) + '\n')
PY
