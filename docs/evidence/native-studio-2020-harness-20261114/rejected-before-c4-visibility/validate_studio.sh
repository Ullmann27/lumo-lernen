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

collect_face_movie() {
  # The engine recorded these real frames/audio. This only encodes and decodes
  # them; it never generates/interpolates frames or claims device FPS.
  python3 - "$1" <<'MOVIEPY'
import hashlib
import json
from pathlib import Path
import subprocess
import sys
root = Path(sys.argv[1])
avi = root / 'facial-runtime.avi'
movie = root / 'facial-runtime.mp4'
assert avi.is_file() and avi.stat().st_size > 1024, 'Missing actual MovieMaker AVI'
assert not movie.exists() and not (root / 'movie.json').exists(), 'Refusing stale movie evidence'
def run(name, args):
    with (root / name).open('wb') as log:
        result = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT, timeout=90)
    assert result.returncode == 0, (name, result.returncode)
    return result.returncode
encode = run('movie-encode.log', ['ffmpeg', '-nostdin', '-y', '-i', str(avi),
    '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p', '-c:a', 'aac',
    '-b:a', '128k', '-movflags', '+faststart', str(movie)])
decode = run('movie-decode.log', ['ffmpeg', '-nostdin', '-v', 'error', '-xerror',
    '-i', str(movie), '-f', 'null', '-'])
probe = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-show_streams',
    '-show_format', '-of', 'json', str(movie)], stdout=subprocess.PIPE,
    stderr=subprocess.PIPE, timeout=90)
(root / 'movie-ffprobe.json').write_bytes(probe.stdout)
(root / 'movie-ffprobe-stderr.log').write_bytes(probe.stderr)
assert probe.returncode == 0, ('ffprobe', probe.returncode)
json.loads(probe.stdout)
def identity(path):
    data = path.read_bytes()
    return {'file': path.name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
(root / 'movie.json').write_text(json.dumps({
    'schema': 1, 'kind': 'actual_godot_movie', 'recording_fps': 24,
    'scope': 'Actual MovieMaker frames and original local audio; not Android/device FPS or phoneme lip sync',
    'source_avi': identity(avi), 'encoded_movie': identity(movie),
    'ffprobe': identity(root / 'movie-ffprobe.json'),
    'encode_exit_code': encode, 'decode_exit_code': decode,
    'probe_exit_code': probe.returncode}, indent=2) + '\n')
MOVIEPY
}

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
    LUMO_CAPTURE_DIR="$capture" LUMO_FACE_CAPTURE_DIR="$capture" PUZZLE_ROTATION_CAPTURE_DIR="$capture" \
    TREASURE_EXPLORATION_CAPTURE_DIR="$capture" LUMO_PUZZLE_MENU_EVIDENCE_DIR="$puzzle_menu_evidence" \
    python3 tools/run_godot_probe.py --log "$LOG_DIR/$script-$mode.log" \
    --timeout "$seconds" --required "$marker" -- "${command[@]}" "${args[@]}" "$@" || return $?
  if [[ "$script" == lumo_facial_capture && "$mode" == rendered ]]; then
    collect_face_movie "$capture" || return $?
  fi
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

# Additive Studio2020 gates; all sixteen earlier probes/budgets remain above.
check_probe lumo_facial_regression 'LUMO_FACIAL_PASS checks=102' headless 180
check_probe lumo_facial_capture 'LUMO_FACIAL_CAPTURE_PASS frames=144' rendered 420 \
  --resolution 640x640 --fixed-fps 24 \
  --write-movie "$LOG_DIR/captures/lumo_facial_capture/facial-runtime.avi"
check_probe connect_four_visual_capture 'CONNECT_FOUR_VISUAL_PASS' rendered 600 -- --capture

# A logic PASS in a display process is insufficient: require the native rasters.
if ! python3 - "$LOG_DIR" <<'PY'
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import sys
root = Path(sys.argv[1])
required = {'learning_sharing_capture': 6, 'lumo_studio_motion_capture': 8,
            'puzzle_rotation_regression': 7, 'treasure_exploration_regression': 3,
            'puzzle_menu_lifecycle_regression': 6,
            'cards_safe_area_regression': 3, 'mobile_safe_area_regression': 4}
required.update({'lumo_facial_capture': 8, 'connect_four_visual_capture': 4})
puzzle_menu_files = {f'{width}x{height}-{phase}.png'
                    for width, height in ((960, 540), (640, 360))
                    for phase in ('rotation-menu', 'rotation-play', 'classic-play')}
face_names = {'teacher_scene.png', 'neutral.png', 'audio_jaw.png', 'blink.png',
              'blink_intermediate.png', 'muted.png', 'gaze_left.png', 'stopped.png'}
c4_views = {
    'c4-empty-landscape.png': ((960, 540), 0, 0, False, 'playing',
        '4b85b841d4981813dfcd61bc2a1232a9a665ea8be1b69f9ca192d57f2e2eb490'),
    'c4-playing-phone.png': ((412, 915), 2, 0, False, 'playing',
        'b871ef7da990d3f31143a80caa9cd4739d91a0dcf0028e56734d61ddfcf56ab6'),
    'c4-win-landscape.png': ((960, 540), 7, 4, False, 'won',
        'f19e96174c8d970a7d10df04259d05e99e370ef1884a5eda8682da48f09d5cc8'),
    'c4-paused-small.png': ((640, 360), 3, 0, True, 'playing',
        '6812f85731ce01cf4aed2b34962fa86644ebec07728268f9ff100252e58f99f7'),
}
def finite(value):
    return type(value) in (int, float) and math.isfinite(value)
def identity(path):
    data = path.read_bytes()
    return {'path': path.relative_to(root).as_posix(), 'bytes': len(data),
            'sha256': hashlib.sha256(data).hexdigest()}
def verify_file(folder, report, name):
    assert report['file'] == name, (folder, name)
    actual = identity(folder / name)
    assert type(report['bytes']) is int and report['bytes'] == actual['bytes'] > 0, name
    assert report['sha256'] == actual['sha256'], name
    return actual

def face_report(folder):
    path = folder / 'runtime-frames.json'
    state = json.loads(path.read_text())
    assert state['lesson_kind'] == 'syllables' and state['lesson_word'] == 'Apfel', path
    assert state['word_source'] == 'res://assets/audio/voice/words/apfel.wav', path
    assert type(state['recording_fps']) is int and state['recording_fps'] == 24, path
    assert all(state[key] is True for key in ('observed_audible_jaw', 'observed_muted_closed',
                                             'observed_stopped_closed', 'observed_blink')), path
    rows = state['rows']
    assert len(rows) == 144 and [row['step'] for row in rows] == list(range(144)), path
    assert all(type(row['step']) is int for row in rows), path
    drawn = [row['engine_drawn_frames'] for row in rows]
    assert all(type(n) is int and n > 0 for n in drawn) and all(a < b for a, b in zip(drawn, drawn[1:])), path
    for row in rows:
        assert finite(row['actual_jaw_weight']) and 0 <= row['actual_jaw_weight'] <= 1, path
        assert finite(row['blink']) and 0 <= row['blink'] <= 1, path
        assert len(row['lid_mesh_weights']) == 8 and all(finite(v) and 0 <= v <= 1 for v in row['lid_mesh_weights']), path
        player = row['player']
        assert type(player['audible']) is bool and player['envelopeAvailable'] is True, path
        assert finite(player['envelope']) and 0 <= player['envelope'] <= 1, path
        assert finite(player['positionMs']) and player['positionMs'] >= 0, path
        assert finite(player['durationMs']) and 928 <= player['durationMs'] <= 929, path
    audible = [row for row in rows if row['player']['audible'] and row['player']['state'] == 'playing']
    assert audible and len({row['player']['positionMs'] for row in audible}) > 2, path
    assert any(row['actual_jaw_weight'] > .05 and row['player']['envelope'] > 0 for row in audible), path
    assert finite(state['actual_max_jaw_weight']) and abs(state['actual_max_jaw_weight'] - max(row['actual_jaw_weight'] for row in rows)) < 1e-6, path
    assert any(row['blink'] > .9 and sum(row['lid_mesh_weights']) > 1 for row in rows), path
    assert all(not row['player']['audible'] and row['player']['envelope'] == 0 and row['actual_jaw_weight'] == 0 for row in rows[67:76]), path
    assert all(row['player']['state'] == 'idle' and not row['player']['audible'] and row['player']['positionMs'] == 0 and row['player']['envelope'] == 0 and row['actual_jaw_weight'] == 0 for row in rows[112:]), path
    proof_path = folder / 'movie.json'
    proof = json.loads(proof_path.read_text())
    assert type(proof['schema']) is int and proof['schema'] == 1 and proof['kind'] == 'actual_godot_movie', proof_path
    assert type(proof['recording_fps']) is int and proof['recording_fps'] == 24, proof_path
    assert all(type(proof[key]) is int and proof[key] == 0 for key in ('encode_exit_code', 'decode_exit_code', 'probe_exit_code')), proof_path
    verify_file(folder, proof['source_avi'], 'facial-runtime.avi')
    movie = verify_file(folder, proof['encoded_movie'], 'facial-runtime.mp4')
    verify_file(folder, proof['ffprobe'], 'movie-ffprobe.json')
    media = json.loads((folder / 'movie-ffprobe.json').read_text())
    video = [v for v in media['streams'] if v['codec_type'] == 'video']
    audio = [v for v in media['streams'] if v['codec_type'] == 'audio']
    assert len(video) == len(audio) == 1, proof_path
    video = video[0]
    assert video['codec_name'] == 'h264' and (video['width'], video['height']) == (640, 640), proof_path
    assert video['r_frame_rate'] == '24/1' and int(video['nb_read_frames']) > max(drawn), proof_path
    assert math.isfinite(float(video['duration'])) and 6 <= float(video['duration']) < 60, proof_path
    assert audio[0]['codec_name'] == 'aac' and int(audio[0]['nb_read_frames']) > 0, proof_path
    movie['proof'] = identity(proof_path)
    return identity(path), movie

def c4_report(folder):
    path = folder / 'visual-state.json'
    state = json.loads(path.read_text())
    assert type(state['schema']) is int and state['schema'] == 1, path
    assert state['kind'] == 'connect_four_visual_fixture' and state['read_only_fixture_host'] is True, path
    assert state['errors'] == [] and finite(state['density']) and state['density'] == 1, path
    assert state['display_driver'] != 'headless' and state['rendering_method'] == 'gl_compatibility', path
    assert state['source_before'] and state['source_before'] == state['source_after'], path
    assert all(re.fullmatch('[a-f0-9]{64}', value) for value in state['source_before'].values()), path
    events = state['input_events']
    assert any(v['kind'] == 'ScreenDrag' for v in events) and any(v['kind'] == 'ScreenTouch' and v.get('pressed') is False for v in events), path
    reports = state['captures']
    assert len(reports) == 4 and {v['file'] for v in reports} == set(c4_views), path
    reported = {v['file']: v for v in reports}
    for name, (size, discs, rings, paused, phase, source_hash) in c4_views.items():
        item = reported[name]
        assert item['scope'] == 'visual_fixture_only' and item['fixture_source_sha256'] == source_hash, name
        assert item['size_px'] == list(size), name
        game = item['fixture_state']; geom = item['geometry']; layout = item['production_layout']
        assert game['game'] == 'connect_four' and game['paused'] is paused and game['phase'] == phase, name
        assert len(game['board']) == 42 and all(finite(v) and v in (0, 1, 2) for v in game['board']), name
        assert sum(v != 0 for v in game['board']) == discs and len(game['winningLine']) == rings, name
        assert geom['disc_count'] == discs == len(geom['discs']) and geom['win_ring_count'] == rings == len(geom['win_rings']), name
        assert geom['board_vertices'] > 1000 and geom['board_indices'] > 1000 and finite(geom['board_depth']) and geom['board_depth'] > .3, name
        assert geom['original_lumo_visible'] is True, name
        assert all(v['mesh_class'] == 'CylinderMesh' for v in geom['discs']), name
        assert all(v['mesh_class'] == 'TorusMesh' for v in geom['win_rings']), name
        assert layout['settled'] is True and layout['window_px'] == list(size), name
        assert layout['token'] == game['token'] and layout['revision'] == game['revision'] and layout['board'] == game['board'], name
        assert item['input_requests_rejected'] == [] and item['host_return_attempts'] == 0, name
        assert item['raster_unique_samples'] > 80 and len(item['targets']) == 9, name
        targets = item['targets'] + item['reachable_menu_targets']
        for target in targets:
            assert len(target['size_dp']) == 2 and all(finite(v) and v >= 47.99 for v in target['size_dp']), name
            rect, hit = target['rect_px'], target['hit_rect_px']
            assert len(rect) == len(hit) == 4 and all(finite(v) for v in rect + hit), name
            assert hit[0] <= rect[0] + .1 and hit[1] <= rect[1] + .1 and hit[0] + hit[2] + .1 >= rect[0] + rect[2] and hit[1] + hit[3] + .1 >= rect[1] + rect[3], name
            assert hit[0] >= -.1 and hit[1] >= -.1 and hit[0] + hit[2] <= size[0] + .1 and hit[1] + hit[3] <= size[1] + .1, name
        if paused:
            assert item['pause_caption'] == 'Spiel pausiert. Deine Runde bleibt gespeichert.', name
            assert len(item['reachable_menu_targets']) >= 4 and item['reachable_menu_targets'][-1]['text'] == 'Fortsetzen' and item['reachable_menu_targets'][-1]['enabled'] is True, name
        else:
            assert item['pause_caption'] == '' and item['caption'] == ('Cyan gewinnt!' if phase == 'won' else 'Gespeichert · Cyan ist dran'), name
    return identity(path), reported

images = []
for probe, count in required.items():
    found = sorted((root / 'captures' / probe).glob('*.png'))
    assert len(found) == count, (probe, len(found), count)
    if probe == 'lumo_facial_capture':
        assert {path.name for path in found} == face_names, probe
        facial_state, facial_movie = face_report(root / 'captures' / probe)
    if probe == 'connect_four_visual_capture':
        assert {path.name for path in found} == set(c4_views), probe
        c4_state, c4_reported = c4_report(root / 'captures' / probe)
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
        if probe == 'lumo_facial_capture':
            assert (width, height) == (640, 640), str(path)
            entry['facial_runtime'] = facial_state
            entry['facial_movie'] = facial_movie
        if probe == 'connect_four_visual_capture':
            assert (width, height) == c4_views[path.name][0], str(path)
            assert c4_reported[path.name]['sha256'] == entry['sha256'], str(path)
            entry['connect_four_visual_state'] = c4_state
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
echo '[LumoStudio] PASS: source-bound learning, character, puzzle, exploration, safe-area, actual facial movie and C4 visual fixture evidence'
