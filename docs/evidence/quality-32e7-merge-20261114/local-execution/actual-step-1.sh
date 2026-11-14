set -euo pipefail
export XDG_DATA_HOME="$RUNNER_TEMP/c4-wisps/data"
export XDG_CONFIG_HOME="$RUNNER_TEMP/c4-wisps/config"
export XDG_CACHE_HOME="$RUNNER_TEMP/c4-wisps/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
(cd native-source && python3 tools/run_godot_probe.py --log "$GITHUB_WORKSPACE/c4-runtime/wisps.log" --timeout 180 --required '[TreasureWisp] PASS' -- godot --headless --path . --audio-driver Dummy --script scripts/tests/treasure_wisp_regression.gd)
test "$(grep -Fxc '[TreasureWisp] PASS checks=14' c4-runtime/wisps.log)" = 1
