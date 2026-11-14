from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import sys
import urllib.request
import zipfile

cfg = json.load(sys.stdin)
out = Path(cfg['output_directory'])
out.mkdir(exist_ok=False)
archive = out/'artifact.zip'
maximum = int(cfg['expected_archive_bytes'])
digest = hashlib.sha256()
count = 0
with urllib.request.urlopen(cfg['download_url'], timeout=60) as response, archive.open('xb') as target:
    while True:
        chunk = response.read(1024 * 1024)
        if not chunk:
            break
        count += len(chunk)
        if count > maximum:
            raise ValueError('Downloaded archive exceeds the recorded artifact size')
        digest.update(chunk)
        target.write(chunk)
actual_digest = digest.hexdigest()
if count != maximum or actual_digest != cfg['expected_archive_sha256']:
    raise ValueError('Archive size or SHA-256 differs from actual artifact metadata')
members = []
with zipfile.ZipFile(archive) as source:
    infos = source.infolist()
    if len(infos) > int(cfg['maximum_members']):
        raise ValueError('Archive member limit exceeded')
    if sum(info.file_size for info in infos) > int(cfg['maximum_uncompressed_bytes']):
        raise ValueError('Archive uncompressed size limit exceeded')
    seen = set()
    for info in infos:
        relative = PurePosixPath(info.filename)
        canonical = str(relative) + ('/' if info.is_dir() else '')
        if (not relative.parts or relative.is_absolute() or '..' in relative.parts
                or '\\' in info.filename or '\0' in info.filename
                or canonical != info.filename or info.filename in seen
                or stat.S_ISLNK(info.external_attr >> 16) or info.flag_bits & 1):
            raise ValueError('Unsafe, duplicate, symbolic, or encrypted archive member')
        seen.add(info.filename)
    corrupt = source.testzip()
    if corrupt is not None:
        raise ValueError('Original ZIP CRC check failed')
    original = out/'originals'
    original.mkdir()
    for info in infos:
        if info.is_dir():
            continue
        path = original.joinpath(*PurePosixPath(info.filename).parts)
        path.parent.mkdir(parents=True, exist_ok=True)
        member_digest = hashlib.sha256()
        size = 0
        with source.open(info) as contents, path.open('xb') as target:
            while True:
                chunk = contents.read(1024 * 1024)
                if not chunk:
                    break
                size += len(chunk)
                if size > info.file_size:
                    raise ValueError('Archive member exceeds declared size')
                member_digest.update(chunk)
                target.write(chunk)
        if size != info.file_size:
            raise ValueError('Archive member size differs')
        members.append({'path': info.filename, 'bytes': size, 'sha256': member_digest.hexdigest()})
record = {
    'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'artifact_id': cfg['artifact_id'], 'run_id': cfg['run_id'], 'run_attempt': cfg['run_attempt'],
    'candidate_host': cfg['candidate_host'], 'archive_bytes': count,
    'archive_sha256': actual_digest, 'crc_verified': True,
    'archive_path': str(archive), 'original_directory': str(original),
    'members': members, 'download_url_persisted': False,
    'scope': 'Actual original archive identity, CRC, safe extraction and per-member byte identities. No application execution or release approval.'
}
(out/'archive-inspection.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps({'artifact_id': cfg['artifact_id'], 'archive_bytes': count,
                  'archive_sha256': actual_digest, 'members': len(members),
                  'uncompressed_bytes': sum(row['bytes'] for row in members),
                  'files': [row['path'] for row in members]}, indent=2))
