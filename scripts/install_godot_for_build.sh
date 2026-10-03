#!/usr/bin/env bash
set -euo pipefail
if command -v godot >/dev/null 2>&1; then
  godot --version
  exit 0
fi
LUMO_GODOT_DIRECTORY="${RUNNER_TEMP:-/tmp}/lumo-godot-engine-4.6.3"
mkdir -p "$LUMO_GODOT_DIRECTORY"
curl -fL --retry 2 \
  https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_linux.x86_64.zip \
  -o "$LUMO_GODOT_DIRECTORY/engine.zip"
unzip -qo "$LUMO_GODOT_DIRECTORY/engine.zip" -d "$LUMO_GODOT_DIRECTORY"
ln -sf "$LUMO_GODOT_DIRECTORY/Godot_v4.6.3-stable_linux.x86_64" "$LUMO_GODOT_DIRECTORY/godot"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$LUMO_GODOT_DIRECTORY" >> "$GITHUB_PATH"
fi
"$LUMO_GODOT_DIRECTORY/godot" --version
