#!/usr/bin/env bash
set -euo pipefail

# This gate adds production-scene checks; all pre-existing acceptance suites
# remain mandatory in the caller. Rendered checks never accept a dummy display.
GODOT="${GODOT_BIN:-godot}"
LOG_DIR="${LUMO_NEXTGEN_LOG_DIR:-$(mktemp -d /tmp/lumo-nextgen.XXXXXXXX)}"
mkdir -p "$LOG_DIR"
LOG_DIR="$(cd "$LOG_DIR" && pwd)"
export XDG_DATA_HOME="$LOG_DIR/user-data"
export XDG_CONFIG_HOME="$LOG_DIR/user-config"
export XDG_CACHE_HOME="$LOG_DIR/user-cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
git rev-parse HEAD > "$LOG_DIR/source-sha.txt"
git status --porcelain --untracked-files=no > "$LOG_DIR/source-dirty.txt"
"$GODOT" --version > "$LOG_DIR/engine.txt"

run_probe() {
  local name="$1" marker="$2" mode="$3"
  shift 3
  local script="scripts/tests/$name.gd"
  local capture_dir="$LOG_DIR/captures/$name"
  local user_dir="$LOG_DIR/user-data/$name-$mode"
  local timeout_seconds=420
  # All 25 high-resolution software-rendered learning views must finish.
  # This is a CI collection budget, never a target-device performance claim.
  if [[ "$name" == learning_world_capture && "$mode" == rendered ]]; then
    timeout_seconds=900
  fi
  if [[ ! -s "$script" ]]; then
    echo "Missing required nextgen probe: $script" >&2
    return 1
  fi
  mkdir -p "$capture_dir" "$user_dir" || return 1
  local args=(--audio-driver Dummy --path . --script "$script")
  local command=("$GODOT")
  if [[ "$mode" == headless ]]; then
    args=(--headless "${args[@]}")
  else
    args=(--rendering-method gl_compatibility "${args[@]}")
    if [[ -z "${DISPLAY:-}" ]]; then
      if ! command -v xvfb-run >/dev/null 2>&1; then
        echo 'Nextgen visual acceptance requires DISPLAY or xvfb-run.' >&2
        return 1
      fi
      command=(xvfb-run -a -s '-screen 0 2560x2560x24' "${command[@]}")
    fi
  fi
  XDG_DATA_HOME="$user_dir" LUMO_CAPTURE_DIR="$capture_dir" LUMO_EVIDENCE_DIR="$capture_dir" \
    python3 tools/run_godot_probe.py --log "$LOG_DIR/$name-$mode.log" \
    --timeout "$timeout_seconds" --required "$marker" -- "${command[@]}" "${args[@]}" "$@"
}

# Every independent module still produces its own evidence when another module
# fails. A partial collection can never emit PASS or unblock an Android build.
failures=()
check_probe() {
  if run_probe "$@"; then
    printf '%s\t%s\tPASS\n' "$1" "$3" >> "$LOG_DIR/results.tsv"
  else
    failures+=("$1/$3")
    printf '%s\t%s\tFAIL\n' "$1" "$3" >> "$LOG_DIR/results.tsv"
  fi
}
printf 'probe\tmode\tresult\n' > "$LOG_DIR/results.tsv"
check_probe learning_world_regression '[LearningWorld] PASS' headless
check_probe jump_nextgen_regression '[JumpNextgen] PASS' headless
check_probe jump_expeditions_regression '[JumpExpeditions] PASS' headless
check_probe lumo_teacher_pose_regression '[LumoTeacherPose] PASS' headless
check_probe lumo_65bone_walk_gait_regression '[LumoGait] PASS' headless
check_probe lumo_original_jump_visual_regression '[JumpOriginalLumo] PASS' headless
check_probe build_transform_regression '[BuildTransform] PASS' headless
check_probe build_nextgen_play_regression '[BuildNextgen] PASS' headless
check_probe build_settlement_regression '[Settlement] PASS' headless
check_probe build_settlement_play_regression '[SettlementPlay] PASS' headless
check_probe creative_nextgen_environment_regression '[CreativeNextgenEnvironment] PASS' headless
check_probe kart_nextgen_garage_regression '[NextGenGarage] PASS' headless
check_probe kart_track_pass_regression '[KartTrackPass] PASS' headless
check_probe cards_table_regression 'CARDS_TABLE_RUNTIME_PASS' headless
check_probe rhythm_tour_regression '[RhythmTour] PASS' headless
check_probe rhythm_tour_play_regression '[RhythmTourPlay] PASS' headless
check_probe learning_world_capture '[LearningCapture] PASS' rendered -- "--output=$LOG_DIR/captures/learning_world_capture"
check_probe jump_nextgen_capture '[JumpNextgenCapture] PASS' rendered
check_probe build_nextgen_play_regression '[BuildNextgen] PASS' rendered -- --capture
check_probe build_settlement_play_regression '[SettlementPlay] PASS' rendered -- --capture
check_probe creative_nextgen_environment_regression '[CreativeNextgenEnvironment] PASS' rendered
# Fixed simulation time prevents a slow software-rendered frame from skipping
# the short selection gesture. This is never a measured device frame-rate claim.
check_probe kart_nextgen_garage_regression '[NextGenGarage] PASS' rendered --fixed-fps 60 -- --capture
check_probe cards_table_capture 'CARDS_TABLE_RENDER_PASS' rendered -- "--output=$LOG_DIR/captures/cards_table_capture"
check_probe rhythm_tour_play_regression '[RhythmTourPlay] PASS' rendered -- --capture
check_probe kart_player_full_route_regression '[PlayerFullRoute] PASS' rendered -- "--out=$LOG_DIR/captures/kart_player_full_route_regression"

if (( ${#failures[@]} )); then
  printf '[LumoNextgen] FAIL: %s\n' "${failures[*]}" >&2
  exit 1
fi

echo "[LumoNextgen] PASS: new production learning, platforming, building, cards, rhythm and garage checks; logs $LOG_DIR"
