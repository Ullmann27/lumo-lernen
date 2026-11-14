#!/usr/bin/env bash
# Build a separately signed Play AAB; this never uploads to Google Play.
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: scripts/build_play_bundle.sh --bundletool PATH [--output-dir NEW_DIRECTORY] [--godot EXECUTABLE]

Requires external LUMO_PLAY_STORE_FILE, LUMO_PLAY_STORE_PASSWORD,
LUMO_PLAY_KEY_ALIAS and LUMO_PLAY_KEY_PASSWORD. The verifier validates them
before preparation or downloads. Credentials are never command-line arguments.
Output defaults to a new dist/play-* directory. An explicit output directory
must not exist, must have an existing parent, and must be outside source paths.
Use a clean dedicated checkout with Flutter's default build directory and no
previous release AAB. The family APK builder remains separate.
HELP
}

fail() {
  printf 'Play build rejected: %s\n' "$1" >&2
  exit 1
}

require_value() {
  [[ "$#" -ge 2 && -n "$2" && "$2" != --* ]] ||
    fail "$1 requires a value"
}

bundletool=""
output_dir=""
godot="godot"
godot_supplied=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --bundletool)
      require_value "$@"
      [[ -z "$bundletool" ]] || fail "duplicate --bundletool"
      bundletool="$2"
      shift 2
      ;;
    --output-dir)
      require_value "$@"
      [[ -z "$output_dir" ]] || fail "duplicate --output-dir"
      output_dir="$2"
      shift 2
      ;;
    --godot)
      require_value "$@"
      [[ "$godot_supplied" -eq 0 ]] || fail "duplicate --godot"
      godot="$2"
      godot_supplied=1
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *) fail "unknown argument: $1" ;;
  esac
done
[[ -n "$bundletool" ]] || fail "--bundletool is required"
for value in "$bundletool" "$output_dir" "$godot"; do
  [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] ||
    fail "paths and executable names must not contain line breaks"
done

command -v python3 >/dev/null || fail "python3 is required"
command -v git >/dev/null || fail "git is required"
export PYTHONDONTWRITEBYTECODE=1
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# Resolve user paths against the original working directory before changing it.
bundletool="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$bundletool")"
if [[ -n "$output_dir" ]]; then
  output_dir="$(python3 - "$output_dir" "$root" <<'PY'
from pathlib import Path
import sys
supplied = Path(sys.argv[1])
root = Path(sys.argv[2]).resolve()
if supplied.exists() or supplied.is_symlink():
    raise SystemExit("Play build rejected: output directory already exists")
destination = supplied.resolve()
if destination.is_relative_to(root) and not destination.is_relative_to(root / "dist"):
    raise SystemExit("Play build rejected: output inside source/build paths is not allowed")
if not destination.parent.is_dir():
    raise SystemExit("Play build rejected: output parent directory must already exist")
print(destination)
PY
)"
fi
if [[ "$godot" == */* ]]; then
  godot="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$godot")"
fi
cd -- "$root"

require_clean_sources() {
  if ! git diff --quiet HEAD --; then
    fail "tracked source differs from the candidate commit"
  fi
  if [[ -n "$(git ls-files --others --exclude-standard -- lib assets scripts tools config)" ]]; then
    fail "untracked files in build source paths must be committed or moved out"
  fi
}
require_clean_sources

# Play provenance is tied to the committed pubspec version. Family-build
# environment overrides must not silently produce another Play candidate.
version_values="$(python3 - <<'PY'
import os
from pathlib import Path
import sys
sys.path.insert(0, str(Path('scripts').resolve()))
from build_version import resolve_version
try:
    pubspec = Path('pubspec.yaml').read_text()
    expected = resolve_version(pubspec, {})
    requested = resolve_version(pubspec, os.environ)
except ValueError as error:
    raise SystemExit(f'Play build rejected: {error}') from error
if requested != expected:
    raise SystemExit('Play build rejected: version overrides must match committed pubspec.yaml')
print(*expected)
PY
)"
read -r lumo_version_name lumo_build_number <<< "$version_values"

# This must precede Flutter, mkdir, scaffold generation, pip, pub and native/model
# downloads. The verifier rejects missing/invalid external upload signing.
python3 scripts/verify_play_bundle.py --preflight --bundletool "$bundletool"

command -v flutter >/dev/null || fail "flutter is required"
command -v curl >/dev/null || fail "curl is required for the pinned voice model"
godot="$(command -v "$godot")" || fail "the requested Godot executable is unavailable"
[[ -x "$godot" ]] || fail "the requested Godot executable is not executable"

# Flutter appbundle has no per-command build-dir option. Do not change a user's
# global Flutter configuration or accidentally select a stale default output.
flutter_config="$(flutter config --machine)"
python3 -c '
import json, sys
try:
    config = json.load(sys.stdin)
except (ValueError, TypeError):
    raise SystemExit("Play build rejected: invalid Flutter configuration response")
if not isinstance(config, dict) or config.get("build-dir") not in (None, "build"):
    raise SystemExit("Play build rejected: a dedicated checkout with default Flutter build-dir is required")
' <<< "$flutter_config"

shopt -s nullglob
bundle_directory="$root/build/app/outputs/bundle/release"
previous_bundles=("$bundle_directory"/*.aab)
[[ "${#previous_bundles[@]}" -eq 0 ]] ||
  fail "release AAB output already exists; use a fresh dedicated checkout"

source_commit="$(git rev-parse --short=12 HEAD)"
work_dir=""
created_output=0
cleanup() {
  local status="$?"
  if [[ "$status" -ne 0 && "$created_output" -eq 1 ]]; then
    rm -f -- "$output_dir/PLAY-BUNDLE-PROVENANCE.json"
    printf 'Play build failed; any remaining AAB is unverified.\n' >&2
  fi
  if [[ -n "$work_dir" ]]; then
    rm -rf -- "$work_dir"
  fi
  exit "$status"
}
trap cleanup EXIT
if [[ -z "$output_dir" ]]; then
  [[ ! -L "$root/dist" ]] || fail "dist must not be a symbolic link"
  mkdir -p -- "$root/dist"
  output_dir="$(mktemp -d "$root/dist/play-$source_commit.XXXXXXXX")"
else
  mkdir -- "$output_dir"
fi
created_output=1
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/lumo-play-build.XXXXXXXX")"

if [[ ! -d android ]]; then
  flutter create --no-pub --project-name lumo_lernen --platforms=android \
    --org dev.ullmann.lumo "$work_dir/scaffold"
  cp -a -- "$work_dir/scaffold/android" android
fi
require_clean_sources
python3 scripts/prepare_android.py --distribution play
python3 scripts/prepare_embedded_games.py
python3 scripts/prepare_offline_voice.py
python3 -m venv "$work_dir/icon-tools"
"$work_dir/icon-tools/bin/python" -m pip install --disable-pip-version-check \
  --only-binary=:all: -r scripts/requirements-icons.txt
"$work_dir/icon-tools/bin/python" -m unittest discover -s scripts/icon_tests -v
"$work_dir/icon-tools/bin/python" scripts/prepare_launcher_icons.py \
  --report-dir "$output_dir"
# export_embedded_game may fetch/checkout a pin, so give it only our new private
# staging directory, never another user's existing Godot working tree.
python3 scripts/export_embedded_game.py --repo "$work_dir/godot-source" --godot "$godot"
flutter pub get --enforce-lockfile
require_clean_sources
flutter build appbundle --no-pub --release \
  --target-platform android-arm64,android-x64 \
  --build-number "$lumo_build_number" --build-name "$lumo_version_name" \
  --dart-define=LUMO_BUILD_NUMBER="$lumo_build_number" \
  --dart-define=LUMO_VERSION_NAME="$lumo_version_name"
require_clean_sources

bundles=("$bundle_directory"/*.aab)
[[ "${#bundles[@]}" -eq 1 ]] ||
  fail "expected exactly one newly built release AAB"
source_bundle="${bundles[0]}"
case "${source_bundle##*/}" in
  app-release.aab|app.aab) ;;
  *) fail "unexpected release AAB filename" ;;
esac
[[ -f "$source_bundle" && -s "$source_bundle" && ! -L "$source_bundle" ]] ||
  fail "release AAB must be a nonempty regular file"

destination="$output_dir/Lumo-Lernen-Play.aab"
cp -- "$source_bundle" "$destination"
python3 scripts/verify_play_bundle.py "$destination" --bundletool "$bundletool" \
  --output-json "$output_dir/PLAY-BUNDLE-PROVENANCE.json"
require_clean_sources
printf 'Play bundle and verification report: %s\n' "$output_dir"
