#!/usr/bin/env bash
set -euo pipefail

scope="${1:?Expected workshop, treasure or build}"
case "$scope" in
  workshop) probe=kart_workshop_density_regression; marker='[WorkshopDensity] PASS'; expected_pngs=6 ;;
  treasure) probe=treasure_density_regression; marker='[TreasureDensity] PASS'; expected_pngs=14 ;;
  build) probe=build_dialog_density_regression; marker='[BuildDialogDensity] PASS'; expected_pngs=12 ;;
  *) echo "Unknown Studio touch scope: $scope" >&2; exit 2 ;;
esac

godot_bin="${GODOT_BIN:-godot}"
log_dir="${LUMO_TOUCH_LOG_DIR:?Set an isolated scope-specific evidence directory}"
mkdir -p "$log_dir"
log_dir="$(cd "$log_dir" && pwd)"
git rev-parse HEAD > "$log_dir/source-sha.txt"
git rev-parse 'HEAD^{tree}' > "$log_dir/source-tree.txt"
git status --porcelain --untracked-files=no > "$log_dir/source-dirty.txt"
"$godot_bin" --version > "$log_dir/engine.txt"
printf 'probe\tmode\tresult\n' > "$log_dir/results.tsv"

run_probe() {
  local mode="$1" seconds="$2"
  local user_dir="$log_dir/data/$mode"
  local capture_dir="$log_dir/captures/$probe"
  mkdir -p "$user_dir" "$capture_dir"
  local command=("$godot_bin")
  local arguments=(--path . --audio-driver Dummy --script "scripts/tests/$probe.gd")
  if [[ "$mode" == headless ]]; then
    arguments=(--headless "${arguments[@]}")
  else
    command=(xvfb-run -a -s '-screen 0 2560x2560x24' "$godot_bin")
    arguments=(--rendering-method gl_compatibility "${arguments[@]}" -- --capture)
  fi
  XDG_DATA_HOME="$user_dir" XDG_CONFIG_HOME="$user_dir/config" XDG_CACHE_HOME="$user_dir/cache" \
    LUMO_CAPTURE_DIR="$capture_dir" \
    python3 tools/run_godot_probe.py --log "$log_dir/$probe-$mode.log" \
    --timeout "$seconds" --required "$marker" -- "${command[@]}" "${arguments[@]}"
}

failures=()
for mode in headless rendered; do
  seconds=600
  [[ "$mode" == rendered ]] && seconds=1200
  # The first full Mesa workshop run reached the seventh of eight layouts
  # without a failed assertion before its 1200s process limit. Preserve every
  # input/layout check and give this software-rendered run enough wall time.
  [[ "$mode" == rendered && "$scope" == workshop ]] && seconds=2100
  if run_probe "$mode" "$seconds"; then
    printf '%s\t%s\tPASS\n' "$probe" "$mode" >> "$log_dir/results.tsv"
  else
    printf '%s\t%s\tFAIL\n' "$probe" "$mode" >> "$log_dir/results.tsv"
    failures+=("$mode")
  fi
done

if ! python3 - "$log_dir" "$probe" "$expected_pngs" <<'PY'
import hashlib
import json
from pathlib import Path
import struct
import sys

root, probe, expected = Path(sys.argv[1]), sys.argv[2], int(sys.argv[3])
files = sorted((root / 'captures' / probe).glob('*.png'))
assert len(files) == expected, (probe, len(files), expected)
images = []
for path in files:
    assert path.is_file() and not path.is_symlink(), str(path)
    data = path.read_bytes()
    assert len(data) > 32 and data[:8] == b'\x89PNG\r\n\x1a\n', str(path)
    width, height = struct.unpack('>II', data[16:24])
    assert min(width, height) >= 320, (path, width, height)
    images.append({'path': path.relative_to(root).as_posix(), 'width': width, 'height': height,
                   'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
(root / 'renderer-images.json').write_text(json.dumps({'images': images}, indent=2) + '\n')
print('[StudioTouchRasterRoster] PASS', probe, len(images), 'original renderer PNGs')
PY
then
  failures+=(renderer-roster)
fi

git status --porcelain --untracked-files=no > "$log_dir/source-dirty-after.txt"
if ! cmp -s "$log_dir/source-dirty.txt" "$log_dir/source-dirty-after.txt"; then
  failures+=(tracked-source-changed)
fi
if (( ${#failures[@]} )); then
  printf '[StudioTouch] FAIL %s: %s\n' "$scope" "${failures[*]}" >&2
  exit 1
fi
printf '[StudioTouch] PASS %s: actual input, density geometry and original renderer captures\n' "$scope"
