#!/usr/bin/env python3
"""Verify PR167's additional17 PNGs, actual facial movie and original sidecars.

The52-gate caller keeps every earlier gate and roster. Movie collection invokes
real ffmpeg/ffprobe once; verification can be completely read-only for publisher
replay. These are renderer-fixture/transport checks, never Android or device FPS.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys

from verify_village_rasters import verify_fixed_rasters

FACE_DIRECTORY = 'captures/lumo_facial_capture'
C4_DIRECTORY = 'captures/connect_four_visual_capture'
TITLE_DIRECTORY = 'captures/treasure_title_contrast_regression'
MANIFEST = 'studio-2020-images.json'
C4_SOURCE_PATHS = {
    'res://scripts/tests/connect_four_visual_capture.gd',
    'res://scenes/games/connect_four_table.tscn',
    'res://scripts/games/connect_four/connect_four_table.gd',
    'res://scripts/systems/host_bridge.gd',
    'res://scripts/app/mobile_runtime.gd',
    'res://scripts/app/android_safe_area.gd',
    'res://scripts/characters/lumo/lumo_rigged_actor.gd',
    'res://assets/characters/lumo_animated/Lumo-Animated-Mobile.glb',
}


def require(condition: bool, message: object) -> None:
    if not condition:
        raise ValueError(str(message))


def finite(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def file_record(root: Path, path: Path) -> dict:
    relative = path.relative_to(root)
    require(not root.is_symlink() and not any(part == '..' for part in relative.parts),
            'Evidence must remain inside its original root')
    current = root
    for part in relative.parts:
        current = current / part
        require(not current.is_symlink(), 'Symlinked evidence is forbidden: ' + str(path))
    require(path.is_file(), 'Missing original regular file: ' + str(path))
    before = path.stat()
    with path.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    after = path.stat()
    require((before.st_size, before.st_mtime_ns, before.st_ino)
            == (after.st_size, after.st_mtime_ns, after.st_ino),
            'Original changed while hashing: ' + str(path))
    return {'path': relative.as_posix(), 'bytes': after.st_size, 'sha256': digest}


def read_json(path: Path) -> dict:
    def invalid(value):
        raise ValueError('Nonfinite JSON constant: ' + value)
    def pairs(rows):
        result = {}
        for key, value in rows:
            require(key not in result, 'Duplicate JSON key: ' + key)
            result[key] = value
        return result
    require(path.stat().st_size <= 4 * 1024 * 1024, 'Oversized original report: ' + str(path))
    result = json.loads(path.read_bytes(), parse_constant=invalid, object_pairs_hook=pairs)
    require(isinstance(result, dict), 'Expected report object: ' + str(path))
    return result


def collect_face_movie(folder: Path) -> dict:
    """Encode the actual MovieMaker AVI, fully decode and preserve ffprobe output."""
    avi = folder / 'facial-runtime.avi'
    source = file_record(folder, avi)
    require(source['bytes'] > 1024, 'Missing actual MovieMaker AVI payload')
    names = ('facial-runtime.mp4', 'movie.json', 'movie-encode.log',
             'movie-decode.log', 'movie-ffprobe.json', 'movie-ffprobe-stderr.log')
    require(not any((folder / name).exists() or (folder / name).is_symlink() for name in names),
            'Refusing to replace existing facial movie evidence')
    movie = folder / 'facial-runtime.mp4'
    def run(name: str, command: list[str]) -> int:
        with (folder / name).open('xb') as log:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=90)
        require(result.returncode == 0, (name, result.returncode))
        return result.returncode
    encode = run('movie-encode.log', ['ffmpeg', '-nostdin', '-n', '-i', str(avi),
        '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p', '-c:a', 'aac',
        '-b:a', '128k', '-movflags', '+faststart', str(movie)])
    decode = run('movie-decode.log', ['ffmpeg', '-nostdin', '-v', 'error', '-xerror',
        '-i', str(movie), '-f', 'null', '-'])
    probe = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-show_streams',
        '-show_format', '-of', 'json', str(movie)], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=90)
    (folder / 'movie-ffprobe.json').write_bytes(probe.stdout)
    (folder / 'movie-ffprobe-stderr.log').write_bytes(probe.stderr)
    require(probe.returncode == 0, ('ffprobe', probe.returncode))
    require(not probe.stderr and not (folder / 'movie-decode.log').read_bytes(),
            'Movie decode or ffprobe reported an error')
    read_json(folder / 'movie-ffprobe.json')
    require(file_record(folder, avi) == source, 'MovieMaker source changed during collection')
    def identity(name):
        record = file_record(folder, folder / name)
        return {'file': name, 'bytes': record['bytes'], 'sha256': record['sha256']}
    result = {'schema': 1, 'kind': 'actual_godot_movie', 'recording_fps': 24,
        'scope': 'Actual MovieMaker frames and original local audio; not Android/device FPS or phoneme lip sync',
        'source_avi': identity('facial-runtime.avi'), 'encoded_movie': identity('facial-runtime.mp4'),
        'ffprobe': identity('movie-ffprobe.json'), 'encode_log': identity('movie-encode.log'),
        'decode_log': identity('movie-decode.log'), 'probe_stderr': identity('movie-ffprobe-stderr.log'),
        'encode_exit_code': encode, 'decode_exit_code': decode, 'probe_exit_code': probe.returncode}
    with (folder / 'movie.json').open('x') as stream:
        stream.write(json.dumps(result, indent=2) + '\n')
    return result

face_names = {'teacher_scene.png', 'neutral.png', 'audio_jaw.png', 'blink.png', 'blink_intermediate.png', 'muted.png', 'gaze_left.png', 'stopped.png'}

c4_views = {'c4-empty-landscape.png': ((960, 540), 0, 0, False, 'playing', True, '4b85b841d4981813dfcd61bc2a1232a9a665ea8be1b69f9ca192d57f2e2eb490'), 'c4-playing-phone.png': ((412, 915), 2, 0, False, 'playing', False, 'b871ef7da990d3f31143a80caa9cd4739d91a0dcf0028e56734d61ddfcf56ab6'), 'c4-win-landscape.png': ((960, 540), 7, 4, False, 'won', True, 'f19e96174c8d970a7d10df04259d05e99e370ef1884a5eda8682da48f09d5cc8'), 'c4-paused-small.png': ((640, 360), 3, 0, True, 'playing', False, '6812f85731ce01cf4aed2b34962fa86644ebec07728268f9ff100252e58f99f7')}

treasure_title_views = {'landscape': ((1920, 1080), 1.5, [112, 36, 0, 24]), 'compact': ((640, 320), 1.0, [0, 0, 0, 0]), 'portrait': ((1080, 2400), 2.625, [0, 136, 0, 63]), 'fold': ((2176, 1812), 2.25, [0, 136, 0, 63]), 'landscape-cutout': ((2400, 1080), 2.625, [136, 63, 0, 63])}


def verify(root: Path, *, write: bool = True) -> dict:
    """Recompute all new evidence; write=False never changes the original pack."""
    root = Path(root)
    stamps = [file_record(root, root / name) for name in
              ('source-sha.txt', 'source-tree.txt', 'source-dirty.txt')]
    head = (root / 'source-sha.txt').read_text().strip()
    tree = (root / 'source-tree.txt').read_text().strip()
    require(re.fullmatch(r'[a-f0-9]{40}', head) and re.fullmatch(r'[a-f0-9]{40}', tree),
            'Exact Native source and tree stamps are required')
    require((root / 'source-dirty.txt').read_bytes() == b'', 'Native source stamp is dirty')
    def identity(path):
        return file_record(root, path)
    def verify_file(folder, report, name, *, allow_empty=False):
        require(isinstance(report, dict) and report['file'] == name, (folder, name))
        actual = identity(folder / name)
        require(type(report['bytes']) is int and report['bytes'] == actual['bytes'], name)
        require(allow_empty or actual['bytes'] > 0, name)
        require(report['sha256'] == actual['sha256'], name)
        return actual

    def face_report(folder):
        path = folder / 'runtime-frames.json'
        state = read_json(path)
        require(state['lesson_kind'] == 'syllables' and state['lesson_word'] == 'Apfel', path)
        require(state['word_source'] == 'res://assets/audio/voice/words/apfel.wav', path)
        require(type(state['recording_fps']) is int and state['recording_fps'] == 24, path)
        require(all((state[key] is True for key in ('observed_audible_jaw', 'observed_muted_closed', 'observed_stopped_closed', 'observed_blink'))), path)
        rows = state['rows']
        require(len(rows) == 144 and [row['step'] for row in rows] == list(range(144)), path)
        require(all((type(row['step']) is int for row in rows)), path)
        drawn = [row['engine_drawn_frames'] for row in rows]
        require(all((type(n) is int and n > 0 for n in drawn)) and all((a < b for a, b in zip(drawn, drawn[1:]))), path)
        for row in rows:
            require(finite(row['actual_jaw_weight']) and 0 <= row['actual_jaw_weight'] <= 1, path)
            require(finite(row['blink']) and 0 <= row['blink'] <= 1, path)
            require(len(row['lid_mesh_weights']) == 8 and all((finite(v) and 0 <= v <= 1 for v in row['lid_mesh_weights'])), path)
            player = row['player']
            require(type(player['audible']) is bool and player['envelopeAvailable'] is True, path)
            require(finite(player['envelope']) and 0 <= player['envelope'] <= 1, path)
            require(finite(player['positionMs']) and player['positionMs'] >= 0, path)
            require(finite(player['durationMs']) and 928 <= player['durationMs'] <= 929, path)
        audible = [row for row in rows if row['player']['audible'] and row['player']['state'] == 'playing']
        require(audible and len({row['player']['positionMs'] for row in audible}) > 2, path)
        require(any((row['actual_jaw_weight'] > 0.05 and row['player']['envelope'] > 0 for row in audible)), path)
        require(finite(state['actual_max_jaw_weight']) and abs(state['actual_max_jaw_weight'] - max((row['actual_jaw_weight'] for row in rows))) < 1e-06, path)
        require(any((row['blink'] > 0.9 and sum(row['lid_mesh_weights']) > 1 for row in rows)), path)
        require(all((not row['player']['audible'] and row['player']['envelope'] == 0 and (row['actual_jaw_weight'] == 0) for row in rows[67:76])), path)
        require(all((row['player']['state'] == 'idle' and (not row['player']['audible']) and (row['player']['positionMs'] == 0) and (row['player']['envelope'] == 0) and (row['actual_jaw_weight'] == 0) for row in rows[112:])), path)
        proof_path = folder / 'movie.json'
        proof = read_json(proof_path)
        require(type(proof['schema']) is int and proof['schema'] == 1 and (proof['kind'] == 'actual_godot_movie'), proof_path)
        require(type(proof['recording_fps']) is int and proof['recording_fps'] == 24, proof_path)
        require(all((type(proof[key]) is int and proof[key] == 0 for key in ('encode_exit_code', 'decode_exit_code', 'probe_exit_code'))), proof_path)
        verify_file(folder, proof['source_avi'], 'facial-runtime.avi')
        movie = verify_file(folder, proof['encoded_movie'], 'facial-runtime.mp4')
        verify_file(folder, proof['ffprobe'], 'movie-ffprobe.json')
        media = read_json(folder / 'movie-ffprobe.json')
        video = [v for v in media['streams'] if v['codec_type'] == 'video']
        audio = [v for v in media['streams'] if v['codec_type'] == 'audio']
        require(len(video) == len(audio) == 1, proof_path)
        video = video[0]
        require(video['codec_name'] == 'h264' and (video['width'], video['height']) == (640, 640), proof_path)
        require(video['r_frame_rate'] == '24/1' and int(video['nb_read_frames']) > max(drawn), proof_path)
        require(math.isfinite(float(video['duration'])) and 6 <= float(video['duration']) < 60, proof_path)
        require(audio[0]['codec_name'] == 'aac' and int(audio[0]['nb_read_frames']) > 0, proof_path)
        movie['proof'] = identity(proof_path)
        return (identity(path), movie)

    def c4_report(folder):
        path = folder / 'visual-state.json'
        state = read_json(path)
        require(type(state['schema']) is int and state['schema'] == 1, path)
        require(state['kind'] == 'connect_four_visual_fixture' and state['read_only_fixture_host'] is True, path)
        require(state['errors'] == [] and finite(state['density']) and (state['density'] == 1), path)
        require(state['display_driver'] != 'headless' and state['rendering_method'] == 'gl_compatibility', path)
        require(state['source_before'] and state['source_before'] == state['source_after'], path)
        require(all((re.fullmatch('[a-f0-9]{64}', value) for value in state['source_before'].values())), path)
        events = state['input_events']
        require(any((v['kind'] == 'ScreenDrag' for v in events)) and any((v['kind'] == 'ScreenTouch' and v.get('pressed') is False for v in events)), path)
        reports = state['captures']
        require(len(reports) == 4 and {v['file'] for v in reports} == set(c4_views), path)
        reported = {v['file']: v for v in reports}
        for name, (size, discs, rings, paused, phase, lumo_visible, source_hash) in c4_views.items():
            item = reported[name]
            require(item['scope'] == 'visual_fixture_only' and item['fixture_source_sha256'] == source_hash, name)
            require(item['size_px'] == list(size), name)
            game = item['fixture_state']
            geom = item['geometry']
            layout = item['production_layout']
            require(game['game'] == 'connect_four' and game['paused'] is paused and (game['phase'] == phase), name)
            require(len(game['board']) == 42 and all((finite(v) and v in (0, 1, 2) for v in game['board'])), name)
            require(sum((v != 0 for v in game['board'])) == discs and len(game['winningLine']) == rings, name)
            require(geom['disc_count'] == discs == len(geom['discs']) and geom['win_ring_count'] == rings == len(geom['win_rings']), name)
            require(geom['board_vertices'] > 1000 and geom['board_indices'] > 1000 and finite(geom['board_depth']) and (geom['board_depth'] > 0.3), name)
            require(geom['original_lumo_visible'] is lumo_visible, name)
            require(all((v['mesh_class'] == 'CylinderMesh' for v in geom['discs'])), name)
            require(all((v['mesh_class'] == 'TorusMesh' for v in geom['win_rings'])), name)
            require(layout['settled'] is True and layout['window_px'] == list(size), name)
            require(layout['token'] == game['token'] and layout['revision'] == game['revision'] and (layout['board'] == game['board']), name)
            require(item['input_requests_rejected'] == [] and item['host_return_attempts'] == 0, name)
            require(item['raster_unique_samples'] > 80 and len(item['targets']) == 9, name)
            targets = item['targets'] + item['reachable_menu_targets']
            for target in targets:
                require(len(target['size_dp']) == 2 and all((finite(v) and v >= 47.99 for v in target['size_dp'])), name)
                rect, hit = (target['rect_px'], target['hit_rect_px'])
                require(len(rect) == len(hit) == 4 and all((finite(v) for v in rect + hit)), name)
                require(hit[0] <= rect[0] + 0.1 and hit[1] <= rect[1] + 0.1 and (hit[0] + hit[2] + 0.1 >= rect[0] + rect[2]) and (hit[1] + hit[3] + 0.1 >= rect[1] + rect[3]), name)
                require(hit[0] >= -0.1 and hit[1] >= -0.1 and (hit[0] + hit[2] <= size[0] + 0.1) and (hit[1] + hit[3] <= size[1] + 0.1), name)
            if paused:
                require(item['pause_caption'] == 'Spiel pausiert. Deine Runde bleibt gespeichert.', name)
                require(len(item['reachable_menu_targets']) >= 4 and item['reachable_menu_targets'][-1]['text'] == 'Fortsetzen' and (item['reachable_menu_targets'][-1]['enabled'] is True), name)
            else:
                require(item['pause_caption'] == '' and item['caption'] == ('Cyan gewinnt!' if phase == 'won' else 'Gespeichert · Cyan ist dran'), name)
        return (identity(path), reported)

    def treasure_title_report(folder):
        path = folder / 'treasure-title-report.json'
        state = read_json(path)
        require(type(state['checks']) is int and state['checks'] >= 3341, path)
        require(state['failures'] == [], path)
        require(state['scope'] == 'Production HUD, real ScreenTouch, declared saved-position and Android-boundary fixture; not device execution', path)
        rows = state['observations']
        starts = {'production fresh start', 'original86445 first tree save'}
        expected = {(profile, start) for profile in treasure_title_views for start in starts}
        require(isinstance(rows, list) and len(rows) == 10
                and {(row['profile'], row['initial_state_fixture']) for row in rows} == expected,
                (path, 'exact five profiles and both start states'))
        reported = {}

        def rect(value, label):
            require(isinstance(value, list) and len(value) == 4
                    and all(finite(v) for v in value) and min(value[2:]) > 0, label)
            return value

        def inside(value, bounds, label):
            require(value[0] >= bounds[0] - .51 and value[1] >= bounds[1] - .51, label)
            require(value[0] + value[2] <= bounds[2] + .51
                    and value[1] + value[3] <= bounds[3] + .51, label)

        def overlaps(a, b):
            return (a[0] < b[0] + b[2] and b[0] < a[0] + a[2]
                    and a[1] < b[1] + b[3] and b[1] < a[1] + a[3])

        for item in rows:
            profile = item['profile']
            size, density, insets = treasure_title_views[profile]
            name = f'treasure-title-{profile}.png'
            require(item['window_px'] == list(size), name)
            require(finite(item['density']) and item['density'] == density, name)
            require(item['insets_fixture'] == insets
                    and all(finite(v) for v in item['insets_fixture']), name)
            contrast = item['worst_white_backdrop_contrast']
            require(finite(contrast) and 7 <= contrast <= 21, name)
            safe = (insets[0], insets[1], size[0] - insets[2], size[1] - insets[3])
            inside(rect(item['title_rect'], name), safe, name)
            view = item['gameplay_view']
            avatar = rect(view['avatar_rect_px'], (name, 'avatar'))
            inside(avatar, (0, 0, size[0], size[1]), (name, 'avatar'))
            contrast = view['secondary_white_backdrop_contrast']
            require(finite(contrast) and 7 <= contrast <= 21, (name, 'secondary contrast'))
            compact = profile in {'compact', 'landscape-cutout'}
            roles = {'header', 'toast', 'joystick', 'action', 'jump', 'hint' if compact else 'clue'}
            hud = view['hud_rects']
            require(isinstance(hud, list) and len(hud) == len(roles)
                    and {region['role'] for region in hud} == roles, (name, 'HUD roles'))
            regions = {}
            for region in hud:
                role = region['role']
                require(type(region['name']) is str and region['name'], (name, role))
                bounds = rect(region['rect_px'], (name, role))
                inside(bounds, safe, (name, role))
                require(not overlaps(bounds, avatar), (name, role, 'avatar occluded'))
                overlap = region['overlap_px']
                require(isinstance(overlap, list) and len(overlap) == 4
                        and all(finite(v) for v in overlap) and overlap[2:] == [0, 0], (name, role))
                if role in {'joystick', 'action', 'jump', 'hint'}:
                    require(min(bounds[2:]) / density >= 47.99, (name, role, 'touch size'))
                regions[role] = bounds
            for role in {'joystick', 'action', 'jump', 'hint'} & roles:
                require(not overlaps(regions['toast'], regions[role]), (name, role, 'toast covers input'))
            # Both source-declared start states are mandatory. Only the original
            # four restored views and the fresh cutout view may claim an image.
            captured_start = ('production fresh start' if profile == 'landscape-cutout'
                              else 'original86445 first tree save')
            if item['initial_state_fixture'] == captured_start:
                require(Path(item['image']).name == name
                        and item['image_px'] == list(size), name)
                reported[profile] = item
            else:
                require(not {'image', 'image_px', 'image_sha256'} & item.keys(),
                        (name, 'unexpected capture state'))
        require(set(reported) == set(treasure_title_views), path)
        return (identity(path), reported)

    # Preserve every published sidecar condition, then bind the source and full
    # decoded rasters using the already active decoder (not header-only PNGs).
    face_folder, c4_folder, title_folder = (root / FACE_DIRECTORY, root / C4_DIRECTORY, root / TITLE_DIRECTORY)
    for folder, name in ((face_folder, 'runtime-frames.json'), (face_folder, 'movie.json'),
                         (face_folder, 'movie-ffprobe.json'), (c4_folder, 'visual-state.json'),
                         (title_folder, 'treasure-title-report.json')):
        file_record(root, folder / name)
    facial_state, facial_movie = face_report(face_folder)
    c4_state, c4_reported = c4_report(c4_folder)
    title_state, title_reported = treasure_title_report(title_folder)
    c4_document = read_json(c4_folder / 'visual-state.json')
    require(type(c4_document.get('checks')) is int and c4_document['checks'] > 0,
            'C4 visual report lacks actual checks')
    require(c4_document.get('source_revision') == head,
            'C4 report must identify the actual Native checkout, not the Host GITHUB_SHA')
    require(set(c4_document['source_before']) == C4_SOURCE_PATHS,
            'C4 report lacks the complete declared original source subset')
    proof = read_json(face_folder / 'movie.json')
    logs = [verify_file(face_folder, proof[key], name, allow_empty=True) for key, name in
            (('encode_log', 'movie-encode.log'), ('decode_log', 'movie-decode.log'),
             ('probe_stderr', 'movie-ffprobe-stderr.log'))]
    require(logs[1]['bytes'] == logs[2]['bytes'] == 0, 'Movie decode/ffprobe original stderr is not clean')
    require(proof['source_avi']['bytes'] > 1024 and proof['encoded_movie']['bytes'] > 1024,
            'Movie source/encoded payload is empty or truncated')
    face_expected = {FACE_DIRECTORY + '/' + name: (640, 640) for name in face_names}
    c4_expected = {C4_DIRECTORY + '/' + name: value[0] for name, value in c4_views.items()}
    title_expected = {TITLE_DIRECTORY + '/treasure-title-' + name + '.png': value[0]
                      for name, value in treasure_title_views.items()}
    images = []
    groups = ((FACE_DIRECTORY, face_expected, 'Facial runtime', 'facial-images.json'),
              (C4_DIRECTORY, c4_expected, 'C4 visual fixture', 'connect-four-visual-images.json'),
              (TITLE_DIRECTORY, title_expected, 'Treasure title', 'treasure-title-images.json'))
    for directory, expected, label, manifest in groups:
        # Inspect all ancestors before the reusable decoder opens any image.
        for relative in expected:
            file_record(root, root / relative)
        rows = verify_fixed_rasters(root, directory=directory, expected=expected,
                                    label=label, manifest=manifest, write=write)
        for entry in rows:
            name = Path(entry['path']).name
            if directory == FACE_DIRECTORY:
                entry['facial_runtime'] = facial_state
                entry['facial_movie'] = facial_movie
            elif directory == C4_DIRECTORY:
                require(c4_reported[name]['sha256'] == entry['sha256'], 'C4 original PNG hash mismatch: ' + name)
                entry['connect_four_visual_state'] = c4_state
            else:
                profile = Path(name).stem.removeprefix('treasure-title-')
                require(title_reported[profile]['image_sha256'] == entry['sha256'], 'Treasure original PNG hash mismatch: ' + name)
                entry['treasure_title_report'] = title_state
            images.append(entry)
    movie = {'encoded': identity(face_folder / 'facial-runtime.mp4'),
             'source_avi': identity(face_folder / 'facial-runtime.avi'),
             'proof': identity(face_folder / 'movie.json'),
             'ffprobe': identity(face_folder / 'movie-ffprobe.json'), 'logs': logs}
    result = {'schema': 1, 'kind': 'studio_2020_extension',
              'scope': '17 actual Native renderer PNGs, original facial movie and sidecars; no Android/device FPS or Dart rules acceptance',
              'source': {'commit': head, 'tree': tree, 'stamps': stamps},
              'images': images, 'reports': [facial_state, c4_state, title_state], 'movies': [movie]}
    if write:
        temporary = root / ('.' + MANIFEST + '.tmp')
        temporary.write_text(json.dumps(result, indent=2) + '\n')
        temporary.replace(root / MANIFEST)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    replay = commands.add_parser('verify')
    replay.add_argument('log_dir', type=Path)
    replay.add_argument('--read-only', action='store_true')
    collect = commands.add_parser('collect-face-movie')
    collect.add_argument('capture_dir', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'collect-face-movie':
            collect_face_movie(args.capture_dir)
            print('[Studio2020Movie] PASS: actual AVI encoded, fully decoded and ffprobed')
        else:
            result = verify(args.log_dir, write=not args.read_only)
            if args.read_only:
                file_record(args.log_dir, args.log_dir / MANIFEST)
                original = read_json(args.log_dir / MANIFEST)
                require(original == result, 'Original Studio2020 manifest differs from recomputed evidence')
            print('[Studio2020RasterRoster] PASS 17 actual PNG files, 3 original sidecars and 1 verified facial movie')
    except (OSError, ValueError, TypeError, KeyError, IndexError, subprocess.SubprocessError) as error:
        print('[Studio2020RasterRoster] FAIL: ' + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
