#!/usr/bin/env python3
"""Record unmodified production puzzle frames and verify the resulting film."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import time
import urllib.request

OUTPUT = Path(__file__).resolve().parent
PROJECT = OUTPUT.parents[3] / 'lumo-godot'
SOURCE = '76980a941fa05d047574d8cc386d3249d93ffca3'
PROBE = OUTPUT / 'record_puzzle_runtime.gd'
VIDEO = OUTPUT / 'Lumo-Drehpuzzle-Runtime.mp4'
SOURCES = [
    'project.godot', 'scenes/creative/puzzle_world.tscn',
    'scripts/creative/puzzle_world.gd', 'scripts/creative/puzzle_state.gd',
    'scripts/creative/puzzle_piece.gd', 'scripts/creative/puzzle_atelier_art.gd',
    'scripts/creative/creative_kit.gd', 'scripts/creative/creative_runtime.gd',
    'scripts/creative/build_premium_props.gd', 'scripts/creative/build_voxel_style.gd',
    'scripts/games/kart_world_meshes.gd',
    'scripts/systems/render/lumo_environment_creative_presets.gd',
    'scripts/app/mobile_runtime.gd', 'scripts/app/scene_router.gd',
    'scripts/systems/host_bridge.gd', 'tools/run_local_renderer.py',
    'assets/creative/puzzle/puzzle_alive.gdshader',
    'assets/creative/puzzle/puzzle_table.gdshader',
    'assets/creative/puzzle/hafen.webp', 'assets/creative/puzzle/moonlight.webp',
    'assets/creative/puzzle/candy.webp', 'assets/creative/puzzle/volcano.webp',
    'assets/creative/puzzle/bluetenwiese.webp', 'assets/creative/models/lumo_lantern.glb',
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def logged(command, filename):
    with (OUTPUT / filename).open('w') as stream:
        subprocess.run(command, check=True, stdout=stream, stderr=subprocess.STDOUT)


def main():
    assert not VIDEO.exists(), 'Do not overwrite an existing reviewed recording'
    request = urllib.request.Request(
        f'https://api.github.com/repos/Ullmann27/lumo-godot/git/trees/{SOURCE}?recursive=1',
        headers={'Accept': 'application/vnd.github+json', 'User-Agent': 'Lumo-runtime-source-review'})
    with urllib.request.urlopen(request, timeout=30) as response:
        tree = json.load(response)
    assert not tree.get('truncated')
    remote = {entry['path']: entry['sha'] for entry in tree['tree']}
    sources = []
    for name in SOURCES:
        data = (PROJECT / name).read_bytes()
        blob = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
        assert blob == remote[name], f'Relevant local source differs from {SOURCE}: {name}'
        sources.append({'path': name, 'git_blob_sha': blob,
                        'sha256_before': hashlib.sha256(data).hexdigest(), 'bytes': len(data)})
    temporary = Path(tempfile.mkdtemp(prefix='lumo-puzzle-runtime-'))
    frames = temporary / 'frames'
    frames.mkdir()
    renderer = temporary / 'renderer'
    report = {
        'kind': 'actual_production_puzzle_viewport_recording', 'native_source': SOURCE,
        'source_binding': 'Each listed local Git blob verified against exact GitHub commit; no clean checkout claim',
        'sources': sources, 'probe_sha256': digest(PROBE),
        'reproduction_script_sha256': digest(Path(__file__)),
        'product_modified': False, 'camera_or_physics_modified': False,
        'progress_or_piece_positions_assigned_by_recorder': False,
        'capture_resolution': [960, 540], 'capture_format_fps': 24,
        'physical_device_fps_measured': False, 'audio_track': False,
    }
    environment = os.environ.copy()
    environment.update({'LUMO_RUNTIME_EVIDENCE_DIR': str(OUTPUT),
                        'LUMO_RUNTIME_FRAMES_DIR': str(frames)})
    command = ['python3', str(PROJECT / 'tools/run_local_renderer.py'),
               '--display', '95', '--output', str(renderer), '--timeout', '600',
               '--project', str(PROJECT), '--', '--resolution', '960x540',
               '--disable-vsync', '--fixed-fps', '24', '--quit-after', '420',
               '--script', str(PROBE)]
    report['capture_command'] = command
    report['temporary_directory'] = str(temporary)
    (OUTPUT / 'source-manifest.json').write_text(json.dumps(report, indent=2) + '\n')
    started = time.monotonic()
    with (OUTPUT / 'renderer-launcher.log').open('w') as stream:
        result = subprocess.run(command, env=environment, stdout=stream, stderr=subprocess.STDOUT)
    report.update(capture_wall_seconds=time.monotonic() - started, capture_exit_code=result.returncode)
    for name in ('godot.log', 'run.json'):
        if (renderer / name).exists():
            shutil.copyfile(renderer / name, OUTPUT / name)
    for item in sources:
        item['sha256_after'] = digest(PROJECT / item['path'])
        assert item['sha256_after'] == item['sha256_before'], 'Product source changed during recording'
    log = (OUTPUT / 'godot.log').read_text()
    if result.returncode or '[PuzzleRuntimeMovie] PASS' not in log or re.search(
            r'SCRIPT ERROR|Parse Error|ERROR:|Assertion failed', log):
        report['status'] = 'failed_capture_not_a_deliverable'
        (OUTPUT / 'source-manifest.json').write_text(json.dumps(report, indent=2) + '\n')
        raise SystemExit('Recording failed; original log and temporary frames retained.')
    originals = sorted(frames.glob('frame-*.png'))
    assert len(originals) == 240
    report['original_renderer_frames'] = [
        {'frame': index, 'sha256': digest(path), 'bytes': path.stat().st_size}
        for index, path in enumerate(originals)]
    logged(['ffmpeg', '-hide_banner', '-y', '-framerate', '24', '-start_number', '0',
            '-i', str(frames / 'frame-%04d.png'), '-frames:v', '240', '-an',
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p',
            '-movflags', '+faststart', str(VIDEO)], 'encode.log')
    logged(['ffmpeg', '-v', 'error', '-i', str(VIDEO), '-map', '0:v:0', '-f', 'null', '-'],
           'decode-all.log')
    details = json.loads(subprocess.check_output(
        ['ffprobe', '-v', 'error', '-count_frames', '-show_streams', '-show_format',
         '-of', 'json', str(VIDEO)], text=True))
    (OUTPUT / 'ffprobe.json').write_text(json.dumps(details, indent=2) + '\n')
    stream = next(s for s in details['streams'] if s['codec_type'] == 'video')
    assert (stream['width'], stream['height']) == (960, 540)
    assert int(stream['nb_read_frames']) == 240 and stream['r_frame_rate'] == '24/1'
    assert float(details['format']['duration']) == 10.0
    assert (OUTPUT / 'decode-all.log').stat().st_size == 0
    selected = [(8, 'runtime-initial.png'), (25, 'runtime-selected.png'),
                (45, 'runtime-first-turn.png'), (55, 'runtime-quarter-turned.png'),
                (77, 'runtime-second-turn.png'), (135, 'runtime-dragging.png'),
                (171, 'runtime-matching-target.png'), (190, 'runtime-snapped.png')]
    decoded = []
    for index, name in selected:
        logged(['ffmpeg', '-v', 'error', '-y', '-i', str(VIDEO),
                '-vf', f'select=eq(n\\,{index})', '-vsync', '0', '-frames:v', '1',
                str(OUTPUT / name)], f'decode-{index:03d}.log')
        decoded.append({'frame': index, 'path': name, 'sha256': digest(OUTPUT / name)})
    report.update(status='recorded_fully_decoded_awaiting_visual_review',
                  video_file=VIDEO.name, video_sha256=digest(VIDEO), video_bytes=VIDEO.stat().st_size,
                  encoded_frames=240, duration_seconds=10.0, interpolation=False,
                  decoded_representative_frames=decoded, sources_unchanged=True,
                  runtime_manifest_sha256=digest(OUTPUT / 'runtime-frames.json'))
    (OUTPUT / 'source-manifest.json').write_text(json.dumps(report, indent=2) + '\n')
    shutil.rmtree(temporary)
    print(json.dumps({k: report[k] for k in ('status', 'video_sha256', 'encoded_frames',
                                            'duration_seconds', 'capture_wall_seconds')}))


if __name__ == '__main__':
    main()
