set -euo pipefail
test "$(git -C frozen-native rev-parse HEAD)" = e2d15dbc5f3709306decb139eeb70a1cf30c0b73
export XDG_DATA_HOME="$RUNNER_TEMP/c4-small-import/data"
export XDG_CONFIG_HOME="$RUNNER_TEMP/c4-small-import/config"
export XDG_CACHE_HOME="$RUNNER_TEMP/c4-small-import/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
(cd frozen-native && timeout 300s godot --headless --audio-driver Dummy --editor --import) 2>&1 | tee qa-evidence/original-import.log
if grep -En 'ERROR:|SCRIPT ERROR:|Parse Error:|Assertion failed' qa-evidence/original-import.log; then
  echo 'The original native import reported an error' >&2
  exit 1
fi
