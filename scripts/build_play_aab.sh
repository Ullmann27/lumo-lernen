#!/usr/bin/env bash
# Build a *separate* Google Play AAB. Never reuse or overwrite sideload APKs.
set -euo pipefail
: "${LUMO_PLAY_APPLICATION_ID:?Set the final Play Console applicationId}"
: "${LUMO_PLAY_UPLOAD_KEYSTORE:?Private upload keystore must be supplied}"
: "${LUMO_PLAY_UPLOAD_STORE_PASSWORD:?Private store password must be supplied}"
: "${LUMO_PLAY_UPLOAD_KEY_ALIAS:?Private upload alias must be supplied}"
: "${LUMO_PLAY_UPLOAD_KEY_PASSWORD:?Private key password must be supplied}"
[ -s "$LUMO_PLAY_UPLOAD_KEYSTORE" ] || { echo "Upload keystore is missing" >&2; exit 1; }
[ -d android ] && { echo "Refuse preexisting host: use a clean CI checkout" >&2; exit 1; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || {
  echo "Refuse Play build from modified tracked sources" >&2; exit 1;
}
[ "${CI:-}" = true ] || {
  echo "Play signing must run inside the approved isolated CI job" >&2; exit 1;
}
repo_root="$(pwd)"
temp="$(mktemp -d "${TMPDIR:-/tmp}/lumo-play-host.XXXXXXXX")"
trap 'rm -rf "$temp"' EXIT
flutter create --no-pub --project-name lumo_lernen --platforms=android \
  --org dev.ullmann.lumo "$temp/scaffold"
cp -a "$temp/scaffold/android" android
python3 scripts/prepare_android.py
python3 scripts/prepare_play_android.py --application-id "$LUMO_PLAY_APPLICATION_ID"
python3 scripts/prepare_embedded_games.py
python3 scripts/prepare_offline_voice.py
python3 -m venv build/lumo-play-icon-tools
build/lumo-play-icon-tools/bin/python -m pip install --disable-pip-version-check \
  --only-binary=:all: -r scripts/requirements-icons.txt
build/lumo-play-icon-tools/bin/python scripts/prepare_launcher_icons.py
python3 scripts/export_embedded_game.py
flutter pub get --enforce-lockfile
read -r version_name build_number <<< "$(python3 scripts/build_version.py)"
flutter build appbundle --no-pub --release --target-platform android-arm64,android-x64 \
  --build-name "$version_name" --build-number "$build_number" \
  --dart-define=LUMO_BUILD_NUMBER="$build_number" \
  --dart-define=LUMO_VERSION_NAME="$version_name" \
  --dart-define=LUMO_SIDE_BY_SIDE=false
bundle="build/app/outputs/bundle/release/app-release.aab"
test -s "$bundle"
unzip -tqq "$bundle"
command -v jarsigner >/dev/null || {
  echo "Missing JDK jarsigner" >&2; exit 1;
}
jarsigner -verify -strict -verbose "$bundle" > "$temp/jarsigner-result.txt" || {
  echo "AAB signature failed; detailed credentials redacted" >&2; exit 1;
}
unzip -Z1 "$bundle" > "$temp/bundle-members.txt"
grep -qx 'base/manifest/AndroidManifest.xml' "$temp/bundle-members.txt"
grep -qx 'base/dex/classes.dex' "$temp/bundle-members.txt"
grep -q '^base/assets/flutter_assets/' "$temp/bundle-members.txt"
test -z "$(git status --porcelain --untracked-files=no)"
mkdir -p dist/play
cp "$bundle" dist/play/Lumo-Lernen-Play-${build_number}.aab
(
  cd dist/play
  sha256sum "Lumo-Lernen-Play-${build_number}.aab" > SHA256SUMS.txt
)
python3 - "$bundle" "$version_name" "$build_number" "$LUMO_PLAY_APPLICATION_ID" <<'PY'
import hashlib, json, subprocess, sys
from pathlib import Path
bundle, version, code, package = sys.argv[1:]
data = Path(bundle).read_bytes()
report = {
  "format": "aab",
  "app_id": package,
  "version_name": version,
  "version_code": int(code),
  "source_commit": subprocess.check_output(
      ["git", "rev-parse", "HEAD"], text=True).strip(),
  "sha256": hashlib.sha256(data).hexdigest(),
  "bytes": len(data),
  "target_sdk_preparation": 36,
  "privacy_and_play_console": "requires separate verification",
  "native_page_size": "not certified by this build script",
}
Path("dist/play/PLAY-AAB-VERIFICATION.json").write_text(
    json.dumps(report, indent=2) + "\n")
print("Play AAB assembled and signature checked; policy/device review remains.")
PY
