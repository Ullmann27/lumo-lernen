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
git rev-parse 'HEAD^{tree}' > "$LOG_DIR/source-tree.txt"
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
  elif [[ "$name" == treasure_exploration_regression && "$mode" == rendered ]]; then
    timeout_seconds=600
  elif [[ "$name" == cards_safe_area_android_contract ]]; then
    timeout_seconds=180
  elif [[ "$name" == cards_safe_area_regression ]]; then
    timeout_seconds=180
    [[ "$mode" != rendered ]] || timeout_seconds=600
  elif [[ "$name" == mobile_safe_area_regression ]]; then
    timeout_seconds=240
    [[ "$mode" != rendered ]] || timeout_seconds=900
  elif [[ "$name" == lumo_facial_regression ]]; then
    timeout_seconds=180
  elif [[ "$name" == connect_four_visual_capture || "$name" == treasure_title_contrast_regression ]]; then
    timeout_seconds=600
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
  # In a Host build GITHUB_SHA belongs to the Host. Only this new capture
  # consumes it as a Native revision; bind that report to our actual checkout.
  if [[ "$name" == connect_four_visual_capture ]]; then
    local GITHUB_SHA
    GITHUB_SHA="$(<"$LOG_DIR/source-sha.txt")"
    export GITHUB_SHA
  fi
  XDG_DATA_HOME="$user_dir" LUMO_CAPTURE_DIR="$capture_dir" LUMO_EVIDENCE_DIR="$capture_dir" \
    LUMO_FACE_CAPTURE_DIR="$capture_dir" \
    LUMO_PUZZLE_MENU_EVIDENCE_DIR="$capture_dir" \
    PUZZLE_ROTATION_CAPTURE_DIR="$capture_dir" TREASURE_EXPLORATION_CAPTURE_DIR="$capture_dir" \
    python3 tools/run_godot_probe.py --log "$LOG_DIR/$name-$mode.log" \
    --timeout "$timeout_seconds" --required "$marker" -- "${command[@]}" "${args[@]}" "$@" || return $?
  if [[ "$name" == lumo_facial_capture && "$mode" == rendered ]]; then
    python3 tools/verify_studio_2020_rasters.py collect-face-movie "$capture_dir" || return $?
  fi
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
check_probe learning_sharing_regression '[LearningSharing] PASS' headless
check_probe learning_studio_regression '[LearningStudio] PASS' headless
check_probe learning_host_payload_regression '[LearningHostPayload] PASS' headless
check_probe puzzle_rotation_regression '[PuzzleRotation] PASS' headless
check_probe puzzle_menu_lifecycle_regression '[PuzzleMenuLifecycle] PASS' headless
check_probe treasure_exploration_regression '[TreasureExploration] PASS' headless
check_probe jump_nextgen_regression '[JumpNextgen] PASS' headless
check_probe jump_expeditions_regression '[JumpExpeditions] PASS' headless
check_probe lumo_teacher_pose_regression '[LumoTeacherPose] PASS' headless
check_probe lumo_studio_motion_regression '[LumoStudioMotion] PASS' headless
check_probe lumo_65bone_walk_gait_regression '[LumoGait] PASS' headless
check_probe lumo_original_jump_visual_regression '[JumpOriginalLumo] PASS' headless
check_probe bauwelt_identity_2013_regression '[BauweltIdentity2013] PASS' headless
check_probe build_frontier_regression '[BuildFrontier] PASS' headless
check_probe build_transform_regression '[BuildTransform] PASS' headless
check_probe build_nextgen_play_regression '[BuildNextgen] PASS' headless
check_probe build_settlement_regression '[Settlement] PASS' headless
check_probe build_settlement_play_regression '[SettlementPlay] PASS' headless
check_probe build_village_economy_regression '[VillageEconomy] PASS' headless
check_probe build_village_art_regression ' checks / 0 failures' headless
check_probe build_village_scene_regression '[VillageScene] PASS' headless
check_probe creative_nextgen_environment_regression '[CreativeNextgenEnvironment] PASS' headless
check_probe kart_nextgen_garage_regression '[NextGenGarage] PASS' headless
check_probe kart_track_pass_regression '[KartTrackPass] PASS' headless
check_probe cards_table_regression 'CARDS_TABLE_RUNTIME_PASS' headless
check_probe cards_safe_area_android_contract 'CARDS_ANDROID_INSETS_PASS' headless
check_probe cards_safe_area_regression 'CARDS_SAFE_AREA_PASS' headless
check_probe mobile_safe_area_regression 'MOBILE_SAFE_AREA_PASS' headless
check_probe rhythm_tour_regression '[RhythmTour] PASS' headless
check_probe rhythm_tour_play_regression '[RhythmTourPlay] PASS' headless
check_probe learning_world_capture '[LearningCapture] PASS' rendered -- "--output=$LOG_DIR/captures/learning_world_capture"
check_probe learning_sharing_capture '[LearningSharingCapture] PASS' rendered -- "--output=$LOG_DIR/captures/learning_sharing_capture"
check_probe lumo_studio_motion_capture '[LumoStudioCapture] PASS' rendered
check_probe puzzle_rotation_regression '[PuzzleRotation] PASS' rendered
check_probe puzzle_menu_lifecycle_regression '[PuzzleMenuLifecycle] PASS' rendered -- --capture
check_probe treasure_exploration_regression '[TreasureExploration] PASS' rendered
check_probe jump_nextgen_capture '[JumpNextgenCapture] PASS' rendered
check_probe build_nextgen_play_regression '[BuildNextgen] PASS' rendered -- --capture
check_probe build_settlement_play_regression '[SettlementPlay] PASS' rendered -- --capture
check_probe build_village_scene_regression '[VillageScene] PASS' rendered -- --capture
check_probe creative_nextgen_environment_regression '[CreativeNextgenEnvironment] PASS' rendered
# Fixed simulation time prevents a slow software-rendered frame from skipping
# the short selection gesture. This is never a measured device frame-rate claim.
check_probe kart_nextgen_garage_regression '[NextGenGarage] PASS' rendered --fixed-fps 60 -- --capture
check_probe cards_table_capture 'CARDS_TABLE_RENDER_PASS' rendered -- "--output=$LOG_DIR/captures/cards_table_capture"
check_probe cards_safe_area_regression 'CARDS_SAFE_AREA_PASS' rendered -- --capture
check_probe mobile_safe_area_regression 'MOBILE_SAFE_AREA_PASS' rendered -- --capture
check_probe rhythm_tour_play_regression '[RhythmTourPlay] PASS' rendered -- --capture
check_probe kart_player_full_route_regression '[PlayerFullRoute] PASS' rendered -- "--out=$LOG_DIR/captures/kart_player_full_route_regression"

# PR167 additions preserve all 48 preceding probe/mode/argument combinations.
check_probe lumo_facial_regression 'LUMO_FACIAL_PASS checks=102 actual_meshes=true original_bones=65 original_clips=9 phoneme_lipsync=false' headless
check_probe lumo_facial_capture 'LUMO_FACIAL_CAPTURE_PASS frames=144 original_word=true recording_fps=24 not_device_fps=true' rendered \
  --resolution 640x640 --fixed-fps 24 \
  --write-movie "$LOG_DIR/captures/lumo_facial_capture/facial-runtime.avi"
check_probe connect_four_visual_capture 'CONNECT_FOUR_VISUAL_PASS' rendered -- --capture
check_probe treasure_title_contrast_regression '[TreasureTitleContrast] PASS' rendered -- --capture

# Every required Studio view must exist even when all probe markers say PASS.
if ! python3 tools/verify_studio_rasters.py "$LOG_DIR"; then
  failures+=("renderer-roster")
fi
# Village is an additional production capture set, never a Studio replacement.
if ! python3 tools/verify_village_rasters.py "$LOG_DIR"; then
  failures+=("village-raster-roster")
fi
if ! python3 tools/verify_puzzle_menu_rasters.py "$LOG_DIR"; then
  failures+=("puzzle-menu-raster-roster")
fi
if ! python3 tools/verify_safe_area_rasters.py "$LOG_DIR"; then
  failures+=("safe-area-raster-roster")
fi
if ! python3 tools/verify_studio_2020_rasters.py verify "$LOG_DIR"; then
  failures+=("studio-2020-raster-movie-roster")
fi

if (( ${#failures[@]} )); then
  printf '[LumoNextgen] FAIL: %s\n' "${failures[*]}" >&2
  exit 1
fi

echo '[LumoNextgen52] PASS: all 48 previous modes plus four Studio2020 modes and 17 bound rasters/movie/sidecars'
echo "[LumoNextgen] PASS: new production learning, platforming, building, cards, rhythm and garage checks; logs $LOG_DIR"
