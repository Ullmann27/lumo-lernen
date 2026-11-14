set -euo pipefail
export XDG_DATA_HOME="$RUNNER_TEMP/c4-return/data"
export XDG_CONFIG_HOME="$RUNNER_TEMP/c4-return/config"
export XDG_CACHE_HOME="$RUNNER_TEMP/c4-return/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
timeout 60s godot --headless --audio-driver Dummy --path native-source --script res://scripts/tests/connect_four_return_regression.gd 2>&1 | tee c4-runtime/return-recovery.log
if grep -En 'ERROR:|SCRIPT ERROR:|Parse Error:|Assertion failed' c4-runtime/return-recovery.log; then
  echo 'The actual native return regression reported an engine or script failure' >&2
  exit 1
fi
test "$(grep -Fxc 'CONNECT_FOUR_RETURN_PASS checks=21' c4-runtime/return-recovery.log)" = 1
