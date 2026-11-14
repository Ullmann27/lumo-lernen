set -euo pipefail
native_revision="$(python3 -c 'import json; print(json.load(open("config/godot-source.json"))["revision"])')"
native_source="$RUNNER_TEMP/lumo-native-acceptance"
native_logs="$GITHUB_WORKSPACE/acceptance-native"
test "$(git -C "$native_source" rev-parse HEAD)" = "$native_revision"
git -C "$native_source" diff --exit-code HEAD -- scripts/games/connect_four/connect_four_table.gd scripts/tests/connect_four_return_regression.gd
mkdir -p "$native_logs/connect-four-return-user-data" "$native_logs/connect-four-return-user-config" "$native_logs/connect-four-return-user-cache"
XDG_DATA_HOME="$native_logs/connect-four-return-user-data" \
XDG_CONFIG_HOME="$native_logs/connect-four-return-user-config" \
XDG_CACHE_HOME="$native_logs/connect-four-return-user-cache" \
  timeout --signal=TERM --kill-after=10s 180s godot --headless --path "$native_source" \
    --script scripts/tests/connect_four_return_regression.gd 2>&1 | tee "$native_logs/connect-four-return.log"
test "$(grep -Fxc 'CONNECT_FOUR_RETURN_PASS checks=21' "$native_logs/connect-four-return.log")" -eq 1
if grep -En "ERROR:|SCRIPT ERROR:|Parse Error:" "$native_logs/connect-four-return.log"; then
  echo "Connect Four return regression emitted an engine error" >&2
  exit 1
fi
git -C "$native_source" diff --exit-code HEAD -- scripts/games/connect_four/connect_four_table.gd scripts/tests/connect_four_return_regression.gd
