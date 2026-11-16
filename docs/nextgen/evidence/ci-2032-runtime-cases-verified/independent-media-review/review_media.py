#!/usr/bin/env python3
"""Read-only inspection of already retained original supplemental media."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import struct
import subprocess
import time

SOURCE = Path('/dev/shm/lumo-2032-runtime-cases-originals')
ORIGINAL = SOURCE / 'original'
MEDIA = ORIGINAL / 'android/runtime-cases'
OUT = Path(__file__).resolve().parent


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open('rb') as stream:
        for part in iter(lambda: stream.read(1024 * 1024), b''):
            result.update(part)
    return result.hexdigest()


def save(name: str, value: object) -> None:
    with (OUT / name).open('x', encoding='utf-8') as stream:
        json.dump(value, stream, indent=2, ensure_ascii=False)
        stream.write('\n')


manifest_path = SOURCE / 'artifact-verification.json'
manifest = json.loads(manifest_path.read_text())
assert manifest['artifactId'] == 14220263387
assert manifest['workflowRun'] == 43853317375
assert manifest['archiveBytes'] == 65735724
assert manifest['archiveSha256'] == '17ccdb2993b814c96a986fe6d36515713877c7e178a2a52f7f6db38c25a59eed'
members = {item['path']: item for item in manifest['members']}
assert len(members) == len(manifest['members']) == 1889


def original_record(relative: str) -> dict:
    path = ORIGINAL / relative
    assert path.resolve().is_relative_to(ORIGINAL.resolve())
    entry = members[relative]
    actual = {'bytes': path.stat().st_size, 'sha256': digest(path)}
    assert actual['bytes'] == entry['bytes'], relative
    assert actual['sha256'] == entry['sha256'], relative
    return {'member': relative, 'original_path': str(path), **actual,
            'matches_artifact_manifest': True, 'manifest_crc32': entry['crc32']}


result_record = original_record('android/runtime-cases/runtime-cases-result.json')
result = json.loads((MEDIA / 'runtime-cases-result.json').read_text())
assert result['qa_commit'] == 'ce8458e88d16e7c3b97fafcf34c4d29b0c1d9fdc'
assert result['apk_source'] == '9b38360ca5f21919dce4a2b99e605ee39bbbf454'
assert result['native_source'] == '9d6ef1d704a0e54098a8f8f0818f36deae0e3789'

claims: dict[str, list[dict]] = {}
excluded_repository_paths = []


def walk(value: object, pointer: str = '$') -> None:
    if isinstance(value, dict):
        for field in ('file', 'verified_file'):
            filename = value.get(field)
            if isinstance(filename, str) and filename.endswith(('.png', '.mp4')):
                assert Path(filename).name == filename, (pointer, filename)
                claims.setdefault(filename, []).append({'json_field': pointer + '.' + field,
                    'sha256': value.get('sha256'), 'bytes': value.get('bytes'),
                    'width': value.get('width'), 'height': value.get('height')})
        for key, item in value.items():
            walk(item, pointer + '.' + key)
    elif isinstance(value, list):
        for index, item in enumerate(value):
            walk(item, f'{pointer}[{index}]')
    elif isinstance(value, str) and pointer.startswith('$.source_binding.changed_paths') and value.endswith(('.png', '.mp4')):
        excluded_repository_paths.append({'field': pointer, 'value': value,
            'reason': 'Repository source-diff inventory; not current artifact-media reference.'})


walk(result)
media_records = []
for filename, references in sorted(claims.items()):
    record = original_record('android/runtime-cases/' + filename)
    record['result_references'] = references
    for claim in references:
        if claim['sha256'] is not None:
            assert claim['sha256'] == record['sha256'], (filename, claim['json_field'])
        if claim['bytes'] is not None:
            assert claim['bytes'] == record['bytes'], (filename, claim['json_field'])
    if filename.endswith('.png'):
        with (MEDIA / filename).open('rb') as stream:
            header = stream.read(24)
        assert header[:8] == b'\x89PNG\r\n\x1a\n' and header[12:16] == b'IHDR'
        record['width'], record['height'] = struct.unpack('>II', header[16:24])
        for claim in references:
            for dimension in ('width', 'height'):
                if claim[dimension] is not None:
                    assert claim[dimension] == record[dimension], (filename, dimension)
    media_records.append(record)

video_names = [entry['file'] for entry in result['videos']]
png_names = [entry['file'] for entry in result['screenshots']]
assert len(video_names) == len(set(video_names)) == 12
assert len(png_names) == len(set(png_names)) == 28
assert set(claims) == set(video_names + png_names)
for transfer in result['recording_transfers']:
    filename = transfer['file']
    expected = next(entry for entry in media_records if entry['member'].endswith('/' + filename))
    for observation in transfer['remote_observations']:
        if 'sha256_output' in observation:
            assert observation['sha256_output'].split()[0] == expected['sha256']

extra_visual = original_record('android/runtime-cases/0348-runtime-banana-slower-panel.png')
save('media-hash-review.json', {
    'artifact': {key: manifest[key] for key in ('artifactId', 'workflowRun', 'archiveBytes', 'archiveSha256')},
    'manifest_path': str(manifest_path), 'manifest_sha256': digest(manifest_path),
    'result': result_record, 'referenced_png_count': len(png_names),
    'referenced_video_count': len(video_names), 'all_referenced_bytes_and_claimed_hashes_match': True,
    'media': media_records, 'additional_original_visual': extra_visual,
    'excluded_repository_inventory_paths': excluded_repository_paths,
    'archive_verified_by': 'Root; this review independently rehashes result and referenced media, not the outer ZIP.'})
print('HASH REVIEW: 28 PNG + 12 MP4, all result/manifest/actual byte bindings match; extra panel PNG also matches.', flush=True)

version = subprocess.run(['ffprobe', '-version'], capture_output=True, text=True, check=True)
with (OUT / 'ffprobe-version.txt').open('x') as stream:
    stream.write(version.stdout)
results = []
for index, entry in enumerate(result['videos'], 1):
    filename = entry['file']
    command = ['ffprobe', '-v', 'error', '-threads', '1', '-count_frames',
               '-show_streams', '-show_format', '-of', 'json', str(MEDIA / filename)]
    started = time.monotonic()
    completed = subprocess.run(command, capture_output=True, text=True, timeout=120)
    elapsed = time.monotonic() - started
    prefix = Path(filename).stem
    with (OUT / (prefix + '-ffprobe.json')).open('x') as stream:
        stream.write(completed.stdout)
    with (OUT / (prefix + '-ffprobe.stderr.txt')).open('x') as stream:
        stream.write(completed.stderr)
    assert completed.returncode == 0, (filename, completed.returncode, completed.stderr)
    assert not completed.stderr.strip(), (filename, completed.stderr)
    data = json.loads(completed.stdout)
    video = [item for item in data['streams'] if item['codec_type'] == 'video']
    audio = [item for item in data['streams'] if item['codec_type'] == 'audio']
    assert len(video) == 1, filename
    stream = video[0]
    count = int(stream['nb_read_frames'])
    duration = float(stream.get('duration', data['format']['duration']))
    assert count > 1 and duration > 0, (filename, count, duration)
    assert stream['width'] == entry['width'] and stream['height'] == entry['height']
    assert int(data['format']['size']) == entry['bytes']
    assert abs(float(data['format']['duration']) - entry['duration_seconds']) < 0.00001
    assert bool(audio) == entry['audio_recorded'], filename
    record = {'file': filename, 'sha256': digest(MEDIA / filename), 'bytes': entry['bytes'],
        'command': command, 'returncode': completed.returncode, 'stderr_empty': True,
        'sequential_process': True, 'inspection_elapsed_seconds': round(elapsed, 3),
        'video_stream_count': len(video), 'audio_stream_count': len(audio),
        'codec_name': stream.get('codec_name'), 'width': stream['width'], 'height': stream['height'],
        'duration_seconds': duration, 'format_duration_seconds': float(data['format']['duration']),
        'nb_frames_reported': stream.get('nb_frames'), 'nb_read_frames_through_eof': count,
        'r_frame_rate': stream.get('r_frame_rate'), 'avg_frame_rate': stream.get('avg_frame_rate'),
        'audio_streams': audio,
        'boundary': 'Container/video frame reading through EOF; not an acoustic or physical-render-FPS measurement.'}
    results.append(record)
    print(f'VIDEO {index}/12: {filename}: {count} frames, {duration:.6f} s, audio={len(audio)}', flush=True)

save('video-eof-review.json', {'all_twelve_completed_to_eof': True,
    'all_stderr_empty': True, 'all_durations_positive': True,
    'audio_stream_count_total': sum(item['audio_stream_count'] for item in results),
    'videos': results,
    'limits': ['No sound track means no acoustic speed, word/phoneme quality or acoustic stop proof.',
               'Recorded video timestamps/average frame rates are not Godot render performance measurements.',
               'No new screen capture, app execution, domain verifier, remote action or source mutation.']})
print('COMPLETE: all referenced video files inspected sequentially through EOF.', flush=True)
