#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT_BIN:-godot}"
LOG_DIR="${LUMO_STUDIO_LOG_DIR:-$(mktemp -d /tmp/lumo-studio.XXXXXXXX)}"
mkdir -p "$LOG_DIR"
LOG_DIR="$(cd "$LOG_DIR" && pwd)"
git rev-parse HEAD > "$LOG_DIR/source-sha.txt"
git rev-parse 'HEAD^{tree}' > "$LOG_DIR/source-tree.txt"
git status --porcelain --untracked-files=no > "$LOG_DIR/source-dirty.txt"
"$GODOT" --version > "$LOG_DIR/engine.txt"
failures=()
printf 'probe\tmode\tresult\n' > "$LOG_DIR/results.tsv"

run_probe() {
  local script="$1" marker="$2" mode="$3" seconds="$4"
  shift 4
  local capture="$LOG_DIR/captures/$script"
  local user="$LOG_DIR/data/$script-$mode"
  local puzzle_menu_evidence="$capture"
  if [[ "$mode" == headless ]]; then
    puzzle_menu_evidence="$LOG_DIR/evidence/$script-$mode"
  fi
  mkdir -p "$capture" "$user" "$puzzle_menu_evidence"
  local command=("$GODOT")
  local args=(--path . --audio-driver Dummy --script "scripts/tests/$script.gd")
  if [[ "$mode" == headless ]]; then
    args=(--headless "${args[@]}")
  else
    args=(--rendering-method gl_compatibility "${args[@]}")
    if [[ -z "${DISPLAY:-}" ]]; then
      if ! command -v xvfb-run >/dev/null 2>&1; then
        echo 'Studio capture requires an actual display or xvfb-run.' >&2
        return 1
      fi
      command=(xvfb-run -a -s '-screen 0 2560x2560x24' "${command[@]}")
    fi
  fi
  XDG_DATA_HOME="$user" XDG_CONFIG_HOME="$user/config" XDG_CACHE_HOME="$user/cache" \
    LUMO_CAPTURE_DIR="$capture" PUZZLE_ROTATION_CAPTURE_DIR="$capture" \
    TREASURE_EXPLORATION_CAPTURE_DIR="$capture" LUMO_PUZZLE_MENU_EVIDENCE_DIR="$puzzle_menu_evidence" \
    python3 tools/run_godot_probe.py --log "$LOG_DIR/$script-$mode.log" \
    --timeout "$seconds" --required "$marker" -- "${command[@]}" "${args[@]}" "$@"
}

check_probe() {
  if run_probe "$@"; then
    printf '%s\t%s\tPASS\n' "$1" "$3" >> "$LOG_DIR/results.tsv"
  else
    failures+=("$1/$3")
    printf '%s\t%s\tFAIL\n' "$1" "$3" >> "$LOG_DIR/results.tsv"
  fi
}

check_probe learning_sharing_regression '[LearningSharing] PASS' headless 180
check_probe learning_studio_regression '[LearningStudio] PASS' headless 180
check_probe lumo_studio_motion_regression '[LumoStudioMotion] PASS' headless 180
check_probe puzzle_rotation_regression '[PuzzleRotation] PASS' headless 180
check_probe puzzle_menu_lifecycle_regression '[PuzzleMenuLifecycle] PASS' headless 180
check_probe treasure_exploration_regression '[TreasureExploration] PASS' headless 180
check_probe cards_safe_area_android_contract 'CARDS_ANDROID_INSETS_PASS' headless 180
check_probe cards_safe_area_regression 'CARDS_SAFE_AREA_PASS' headless 180
check_probe mobile_safe_area_regression 'MOBILE_SAFE_AREA_PASS' headless 240
check_probe learning_sharing_capture '[LearningSharingCapture] PASS' rendered 600 \
  -- "--output=$LOG_DIR/captures/learning_sharing_capture"
check_probe lumo_studio_motion_capture '[LumoStudioCapture] PASS' rendered 420
check_probe puzzle_rotation_regression '[PuzzleRotation] PASS' rendered 600
check_probe puzzle_menu_lifecycle_regression '[PuzzleMenuLifecycle] PASS' rendered 600 -- --capture
check_probe treasure_exploration_regression '[TreasureExploration] PASS' rendered 600
check_probe cards_safe_area_regression 'CARDS_SAFE_AREA_PASS' rendered 600 -- --capture
check_probe mobile_safe_area_regression 'MOBILE_SAFE_AREA_PASS' rendered 900 -- --capture

# A logic PASS in a display process is insufficient: require the native rasters.
if ! python3 - "$LOG_DIR" <<'PY'
import hashlib
import json
from pathlib import Path
import struct
import sys
root = Path(sys.argv[1])
required = {'learning_sharing_capture': 6, 'lumo_studio_motion_capture': 8,
            'puzzle_rotation_regression': 7, 'treasure_exploration_regression': 3,
            'puzzle_menu_lifecycle_regression': 6,
            'cards_safe_area_regression': 3, 'mobile_safe_area_regression': 4}
puzzle_menu_files = {f'{width}x{height}-{phase}.png'
                    for width, height in ((960, 540), (640, 360))
                    for phase in ('rotation-menu', 'rotation-play', 'classic-play')}
images = []
for probe, count in required.items():
    found = sorted((root / 'captures' / probe).glob('*.png'))
    assert len(found) == count, (probe, len(found), count)
    if probe == 'puzzle_menu_lifecycle_regression':
        assert {path.name for path in found} == puzzle_menu_files, probe
    if probe == 'mobile_safe_area_regression':
        assert {path.name for path in found} == {
            f'{module}-landscape-cutout.png' for module in ('jump', 'build', 'puzzle', 'treasure')
        }, probe
        report = json.loads((root / 'captures' / probe / 'mobile-safe-area.json').read_text())
        assert report['failures'] == [] and len(report['targets']) == 15, probe
        assert all(row['fully_inside_true_safe_area'] and min(row['exposed_dp']) >= 47.95
                   for row in report['targets']), probe
        reported = {row['path']: row for row in report['images']}
        assert set(reported) == {path.name for path in found}, probe
    for path in found:
        data = path.read_bytes()
        assert data[:8] == b'\x89PNG\r\n\x1a\n', str(path)
        width, height = struct.unpack('>II', data[16:24])
        assert width >= 360 and height >= 360, str(path)
        if probe == 'puzzle_menu_lifecycle_regression':
            assert (width, height) == tuple(map(int, path.name.split('-', 1)[0].split('x'))), str(path)
        entry = {'path': path.relative_to(root).as_posix(), 'width': width, 'height': height,
                 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        if probe == 'mobile_safe_area_regression':
            assert (width, height) == (2400, 1080), str(path)
            assert reported[path.name]['sha256'] == entry['sha256'], str(path)
        if probe == 'cards_safe_area_regression':
            layout_path = path.with_suffix('.layout.json')
            layout_bytes = layout_path.read_bytes()
            layout = json.loads(layout_bytes)
            assert type(layout.get('schema')) is int and layout['schema'] == 1, str(layout_path)
            assert layout.get('settled') is True and layout.get('ui_visible') is True, str(layout_path)
            assert layout.get('pending') == 0, str(layout_path)
            assert layout.get('observation_source') == 'fixture', str(layout_path)
            assert layout.get('window_px') == [width, height], str(layout_path)
            assert layout.get('hand') and layout.get('discard', {}).get('quad'), str(layout_path)
            entry['native_layout'] = {'path': layout_path.relative_to(root).as_posix(),
                                     'bytes': len(layout_bytes),
                                     'sha256': hashlib.sha256(layout_bytes).hexdigest()}
        images.append(entry)
(root / 'renderer-images.json').write_text(json.dumps({'images': images}, indent=2) + '\n')
print('[StudioRasterRoster] PASS', len(images), 'actual PNG files')
PY
then
  failures+=("renderer-roster")
fi

if (( ${#failures[@]} )); then
  printf '[LumoStudio] FAIL: %s\n' "${failures[*]}" >&2
  exit 1
fi
echo '[LumoStudio] PASS: source-bound learning, character, puzzle, exploration and Cards safe-area evidence'
