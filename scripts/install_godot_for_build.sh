#!/usr/bin/env bash
set -euo pipefail
if command -v godot >/dev/null 2>&1; then
  godot --version
  exit 0
fi
# Official Godot 4.6.3-stable Linux x86_64 release archive. Pinned so a build
# host never runs an engine binary that differs from the reviewed release.
readonly GODOT_ZIP_SHA256='d0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3'
LUMO_GODOT_DIRECTORY="${RUNNER_TEMP:-/tmp}/lumo-godot-engine-4.6.3"
mkdir -p "$LUMO_GODOT_DIRECTORY"
curl -fL --retry 2 \
  https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_linux.x86_64.zip \
  -o "$LUMO_GODOT_DIRECTORY/engine.zip"
if ! printf '%s  %s\n' "$GODOT_ZIP_SHA256" "$LUMO_GODOT_DIRECTORY/engine.zip" | sha256sum -c --quiet -; then
  echo 'Godot 4.6.3 download does not match the pinned SHA-256; refusing to install it' >&2
  rm -f "$LUMO_GODOT_DIRECTORY/engine.zip"
  exit 1
fi
unzip -qo "$LUMO_GODOT_DIRECTORY/engine.zip" -d "$LUMO_GODOT_DIRECTORY"
ln -sf "$LUMO_GODOT_DIRECTORY/Godot_v4.6.3-stable_linux.x86_64" "$LUMO_GODOT_DIRECTORY/godot"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$LUMO_GODOT_DIRECTORY" >> "$GITHUB_PATH"
fi
"$LUMO_GODOT_DIRECTORY/godot" --version
