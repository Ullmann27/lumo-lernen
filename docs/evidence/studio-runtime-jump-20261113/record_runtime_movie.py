#!/usr/bin/env python3
"""Reproduce an actual Godot viewport take and encode its unchanged frames."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import time

OUTPUT = Path(__file__).resolve().parent
PROJECT = OUTPUT.parents[3] / 'lumo-godot'
PROBE = OUTPUT / 'record_jump_runtime.gd'
VIDEO = OUTPUT / 'Lumo-Original-Jump-Runtime.mp4'
SOURCES = [
    'project.godot',
    'scenes/games/jump_islands.tscn',
    'scripts/games/jump_islands.gd',
    'scripts/games/jump_expeditions.gd',
    'scripts/games/kart_joystick.gd',
    'scripts/games/jump_touch_button.gd',
    'scripts/characters/lumo/lumo_rigged_actor.gd',
    'scripts/characters/lumo/lumo_platform_pose.gd',
    'scripts/characters/lumo/lumo_walk_locomotion.gd',
    'scripts/characters/lumo/lumo_body_space_pose.gd',
    'assets/characters/lumo_animated/lumo_studio_clips.gd',
    'assets/characters/lumo_animated/Lumo-Animated-Mobile.glb',
    'tools/run_local_renderer.py',
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(*args):
    return subprocess.check_output(['git', '-C', str(PROJECT), *args], text=True).strip()


def logged(command, filename):
    with (OUTPUT / filename).open('w') as stream:
        subprocess.run(command, check=True, stdout=stream, stderr=subprocess.STDOUT)


def main():
    assert (PROJECT / 'project.godot').is_file(), PROJECT
    temporary = Path(tempfile.mkdtemp(prefix='lumo-jump-runtime-'))
    renderer = temporary / 'renderer'
    frames = temporary / 'frames'
    frames.mkdir()
    source_hashes = {name: digest(PROJECT / name) for name in SOURCES}
    provenance = {
        'kind': 'actual_godot_viewport_recording',
        'source_kind': 'current local working-tree bytes, not a final native commit receipt',
        'local_checkout_head': git('rev-parse', 'HEAD'),
        'local_branch': git('branch', '--show-current'),
        'working_tree_status_before': git('status', '--short', '--untracked-files=no'),
        'final_native_commit_asserted': None,
        'sources_sha256': source_hashes,
        'probe_sha256': digest(PROBE),
        'reproduction_script_sha256': digest(Path(__file__)),
        'capture_resolution': [960, 540],
        'capture_format_fps': 24,
        'fixed_capture_timestep': True,
        'physical_device_fps_measured': False,
        'product_source_modified_by_recorder': False,
        'camera_or_physics_overridden': False,
        'audio_in_delivered_video': False,
    }
    (OUTPUT / 'source-manifest.json').write_text(json.dumps(provenance, indent=2) + '\n')
    environment = os.environ.copy()
    environment['LUMO_RUNTIME_EVIDENCE_DIR'] = str(OUTPUT)
    environment['LUMO_RUNTIME_FRAMES_DIR'] = str(frames)
    command = [
        'python3', str(PROJECT / 'tools/run_local_renderer.py'),
        '--display', '98', '--output', str(renderer), '--timeout', '600',
        '--project', str(PROJECT), '--', '--resolution', '960x540',
        '--disable-vsync', '--fixed-fps', '24',
        '--quit-after', '260', '--script', str(PROBE),
    ]
    provenance['capture_command'] = command
    print('Recording temporary session:', temporary, flush=True)
    started = time.monotonic()
    with (OUTPUT / 'renderer-launcher.log').open('w') as stream:
        result = subprocess.run(command, env=environment, stdout=stream, stderr=subprocess.STDOUT)
    provenance['capture_wall_seconds'] = time.monotonic() - started
    provenance['capture_exit_code'] = result.returncode
    for name in ['godot.log', 'run.json']:
        if (renderer / name).exists():
            shutil.copyfile(renderer / name, OUTPUT / name)
    log = (OUTPUT / 'godot.log').read_text()
    if result.returncode or '[JumpRuntimeMovie] PASS' not in log or re.search(r'SCRIPT ERROR|Parse Error|ERROR:|Assertion failed', log):
        provenance['status'] = 'recording_failed_not_a_deliverable'
        provenance['temporary_recording_retained_at'] = str(temporary)
        (OUTPUT / 'source-manifest.json').write_text(json.dumps(provenance, indent=2) + '\n')
        raise SystemExit('Recording failed; inspect the original renderer log.')
    provenance['sources_unchanged_during_capture'] = all(digest(PROJECT / name) == value for name, value in source_hashes.items())
    assert provenance['sources_unchanged_during_capture'], 'Relevant source changed while recording'
    originals = sorted(frames.glob('frame-*.png'))
    assert len(originals) == 240
    provenance['original_renderer_frames'] = [
        {'frame': index, 'sha256': digest(path), 'bytes': path.stat().st_size}
        for index, path in enumerate(originals)
    ]
    logged(['ffmpeg', '-hide_banner', '-y', '-framerate', '24', '-start_number', '0',
            '-i', str(frames / 'frame-%04d.png'), '-frames:v', '240', '-an',
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p',
            '-movflags', '+faststart', str(VIDEO)], 'encode.log')
    logged(['ffmpeg', '-v', 'error', '-i', str(VIDEO), '-map', '0:v:0', '-f', 'null', '-'], 'decode-all.log')
    details = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-count_frames', '-show_streams', '-show_format',
        '-of', 'json', str(VIDEO)], text=True))
    (OUTPUT / 'ffprobe.json').write_text(json.dumps(details, indent=2) + '\n')
    stream = next(s for s in details['streams'] if s['codec_type'] == 'video')
    assert (stream['width'], stream['height']) == (960, 540)
    assert 8 <= float(details['format']['duration']) <= 12
    assert stream['r_frame_rate'] == '24/1'
    provenance.update({
        'status': 'recorded_encoded_and_fully_decoded_awaiting_visual_review',
        'video_file': VIDEO.name, 'video_sha256': digest(VIDEO), 'video_bytes': VIDEO.stat().st_size,
        'encoded_frames': int(stream['nb_read_frames']), 'duration_seconds': float(details['format']['duration']),
        'all_video_frames_decoded_without_error': (OUTPUT / 'decode-all.log').stat().st_size == 0,
        'encoding_frame_interpolation': False,
        'raw_sequence_retained_in_git': False,
    })
    (OUTPUT / 'source-manifest.json').write_text(json.dumps(provenance, indent=2) + '\n')
    shutil.rmtree(temporary)
    print(json.dumps({k: provenance[k] for k in ['status', 'video_file', 'video_sha256', 'duration_seconds', 'encoded_frames', 'capture_wall_seconds']}), flush=True)


if __name__ == '__main__':
    main()
