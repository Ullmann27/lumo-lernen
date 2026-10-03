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
  --build-number "${LUMO_BUILD_NUMBER:-275}" --build-name "${LUMO_VERSION_NAME:-0.10.0}" \
  --dart-define=LUMO_BUILD_NUMBER="${LUMO_BUILD_NUMBER:-275}" \
  --dart-define=LUMO_VERSION_NAME="${LUMO_VERSION_NAME:-0.10.0}" \
  --dart-define=LUMO_SIDE_BY_SIDE=true
python3 scripts/verify_unified_apk.py build/app/outputs/flutter-apk/app-release.apk
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/Lumo-Lernen-Neu.apk
sha256sum dist/Lumo-Lernen-Neu.apk > dist/SHA256SUMS.txt
