#!/usr/bin/env python3
"""Record unchanged, source-bound Godot learning gameplay as consecutive frames."""
from pathlib import Path
import argparse
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
NATIVE = '76980a941fa05d047574d8cc386d3249d93ffca3'
PROBE = OUTPUT / 'record_learning_runtime.gd'
VIDEO = OUTPUT / 'Lumo-Lernen-12-durch-3-Runtime.mp4'
SOURCES = [
    'project.godot', 'scenes/learning/learning_world.tscn', 'scenes/default_env.tres',
    'scripts/learning/learning_world.gd', 'scripts/learning/learning_activity.gd',
    'scripts/learning/learning_atelier.gd',
    'scripts/characters/lumo/lumo_rigged_actor.gd',
    'scripts/characters/lumo/lumo_teacher_pose.gd',
    'scripts/characters/lumo/lumo_walk_locomotion.gd',
    'scripts/characters/lumo/lumo_platform_pose.gd',
    'scripts/characters/lumo/lumo_body_space_pose.gd',
    'assets/characters/lumo_animated/lumo_studio_clips.gd',
    'assets/characters/lumo_animated/Lumo-Animated-Mobile.glb',
    'assets/learning/studio/learning_studio.glb',
    'assets/learning/studio/studio_leaf_motion.gdshader',
    'assets/creative/models/lumo_lantern.glb',
    'scripts/games/visual/kart_harbor_cinema.gd',
    'scripts/games/visual/kart_cinema_materials.gd',
    'assets/shaders/kart_lumo_cinema_high.gdshader',
    'assets/shaders/kart_lumo_cinema_mobile.gdshader',
    'scripts/systems/event_bus.gd', 'scripts/systems/settings_store.gd',
    'scripts/systems/performance_manager.gd', 'scripts/systems/host_bridge.gd',
    'scripts/systems/asset_loader.gd', 'scripts/systems/audio_manager.gd',
    'scripts/systems/progress_store.gd', 'scripts/app/mobile_runtime.gd',
    'scripts/app/scene_router.gd', 'assets/manifests/assets.json',
    'tools/run_local_renderer.py',
]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def digest(path):
    return sha(path.read_bytes())


def git(*args):
    return subprocess.check_output(['git', '-C', str(PROJECT), *args])


def write_manifest(data):
    (OUTPUT / 'source-manifest.json').write_text(json.dumps(data, indent=2) + '\n')


def logged(command, filename):
    with (OUTPUT / filename).open('w') as stream:
        subprocess.run(command, check=True, stdout=stream, stderr=subprocess.STDOUT)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--display', type=int, default=105)
    args = parser.parse_args()
    if Path(f'/tmp/.X{args.display}-lock').exists():
        raise SystemExit('The selected display has an existing Xorg lock; choose another display.')
    records = []
    for name in SOURCES:
        expected = git('show', f'{NATIVE}:{name}')
        actual = (PROJECT / name).read_bytes()
        if actual != expected:
            raise SystemExit('Local product bytes differ from the requested native commit: ' + name)
        records.append({'path': name, 'bytes': len(actual), 'before_sha256': sha(actual),
                        'pinned_commit_sha256': sha(expected),
                        'pinned_git_blob': git('rev-parse', f'{NATIVE}:{name}').decode().strip()})
    temporary = Path(tempfile.mkdtemp(prefix='lumo-learning-runtime-'))
    renderer, frames = temporary / 'renderer', temporary / 'frames'
    frames.mkdir()
    provenance = {
        'kind': 'actual_godot_viewport_recording', 'native_commit': NATIVE,
        'native_tree': git('rev-parse', NATIVE + '^{tree}').decode().strip(),
        'local_checkout_head': git('rev-parse', 'HEAD').decode().strip(),
        'local_branch': git('branch', '--show-current').decode().strip(),
        'source_scope': 'The listed product paths match native76980 before and after capture. No whole-checkout or imported-cache cleanliness is claimed.',
        'sources': records, 'probe_sha256': digest(PROBE),
        'reproduction_script_sha256': digest(Path(__file__)),
        'capture_resolution': [960, 540], 'capture_format_fps': 24,
        'fixed_capture_timestep': True, 'physical_device_fps_measured': False,
        'product_source_modified_by_recorder': False, 'scene_camera_or_gameplay_overridden': False,
        'input_scope': 'Twelve synthetic QA finger touches on the existing production button; no direct activity mutation.',
        'audio_in_delivered_video': False,
    }
    environment = os.environ.copy()
    environment['LUMO_RUNTIME_EVIDENCE_DIR'] = str(OUTPUT)
    environment['LUMO_RUNTIME_FRAMES_DIR'] = str(frames)
    command = ['python3', str(PROJECT / 'tools/run_local_renderer.py'),
               '--display', str(args.display), '--output', str(renderer), '--timeout', '900',
               '--project', str(PROJECT), '--', '--resolution', '960x540',
               '--disable-vsync', '--fixed-fps', '24', '--quit-after', '300', '--script', str(PROBE)]
    provenance['capture_command'] = command
    write_manifest(provenance)
    print('Recording session:', temporary, flush=True)
    started = time.monotonic()
    with (OUTPUT / 'renderer-launcher.log').open('w') as stream:
        result = subprocess.run(command, env=environment, stdout=stream, stderr=subprocess.STDOUT)
    provenance['capture_wall_seconds'] = time.monotonic() - started
    provenance['capture_exit_code'] = result.returncode
    for name in ('godot.log', 'run.json'):
        if (renderer / name).exists():
            shutil.copyfile(renderer / name, OUTPUT / name)
    for record in records:
        record['after_sha256'] = digest(PROJECT / record['path'])
    unchanged = all(r['before_sha256'] == r['after_sha256'] == r['pinned_commit_sha256'] for r in records)
    provenance['listed_product_sources_unchanged_and_match_native'] = unchanged
    log = (OUTPUT / 'godot.log').read_text() if (OUTPUT / 'godot.log').exists() else ''
    if result.returncode or not unchanged or '[LearningRuntimeMovie] PASS' not in log or re.search(r'SCRIPT ERROR|Parse Error|ERROR:|Assertion failed', log):
        provenance['status'] = 'recording_failed_not_a_deliverable'
        provenance['temporary_recording_retained_at'] = str(temporary)
        write_manifest(provenance)
        raise SystemExit('Recording failed; original logs and any actual frames retained for diagnosis.')
    runtime = json.loads((OUTPUT / 'runtime-frames.json').read_text())
    if runtime['failures'] or len(runtime['frames']) != 240 or runtime['button_activations'] != 12:
        raise SystemExit('Incomplete actual runtime evidence')
    originals = sorted(frames.glob('frame-*.png'))
    assert len(originals) == 240
    provenance['original_renderer_frames'] = [
        {'frame': index, 'bytes': path.stat().st_size, 'sha256': digest(path)}
        for index, path in enumerate(originals)
    ]
    logged(['ffmpeg', '-hide_banner', '-y', '-framerate', '24', '-start_number', '0',
            '-i', str(frames / 'frame-%04d.png'), '-frames:v', '240', '-an',
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p',
            '-movflags', '+faststart', str(VIDEO)], 'encode.log')
    logged(['ffmpeg', '-v', 'error', '-i', str(VIDEO), '-map', '0:v:0', '-f', 'null', '-'], 'decode-all.log')
    details = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-count_frames',
                       '-show_streams', '-show_format', '-of', 'json', str(VIDEO)], text=True))
    (OUTPUT / 'ffprobe.json').write_text(json.dumps(details, indent=2) + '\n')
    stream = next(s for s in details['streams'] if s['codec_type'] == 'video')
    assert (stream['width'], stream['height']) == (960, 540)
    assert stream['r_frame_rate'] == '24/1' and int(stream['nb_read_frames']) == 240
    assert float(details['format']['duration']) == 10.0
    assert (OUTPUT / 'decode-all.log').stat().st_size == 0
    samples = runtime['frames']
    chosen = {'start': 12, 'moving': next(s['frame'] for s in samples if s['moving_tokens']) + 4}
    for round_number in range(1, 4):
        chosen[f'round-{round_number}'] = next(s['frame'] for s in samples
            if s['placed'] == round_number * 3 and not s['moving_tokens'])
    chosen['complete'] = 239
    decoded = []
    for label, index in chosen.items():
        path = OUTPUT / f'runtime-learning-{label}.png'
        logged(['ffmpeg', '-v', 'error', '-y', '-i', str(VIDEO),
                '-vf', f'select=eq(n\\,{index})', '-frames:v', '1', '-update', '1', str(path)],
               f'decode-{label}.log')
        decoded.append({'file': path.name, 'video_frame': index, 'sha256': digest(path),
                        'bytes': path.stat().st_size, 'runtime_sample': samples[index]})
    (OUTPUT / 'decoded-samples.json').write_text(json.dumps(decoded, indent=2) + '\n')
    (OUTPUT / 'input-events.json').write_text(json.dumps(runtime['inputs'], indent=2) + '\n')
    provenance.update({
        'status': 'recorded_encoded_and_fully_decoded_awaiting_visual_review',
        'video_file': VIDEO.name, 'video_sha256': digest(VIDEO), 'video_bytes': VIDEO.stat().st_size,
        'encoded_frames': 240, 'duration_seconds': 10.0,
        'all_video_frames_decoded_without_error': True, 'encoding_frame_interpolation': False,
        'raw_sequence_retained_in_git': False,
    })
    write_manifest(provenance)
    shutil.rmtree(temporary)
    print(json.dumps({k: provenance[k] for k in ['status', 'video_file', 'video_sha256',
          'duration_seconds', 'encoded_frames', 'capture_wall_seconds']}), flush=True)


if __name__ == '__main__':
    main()
