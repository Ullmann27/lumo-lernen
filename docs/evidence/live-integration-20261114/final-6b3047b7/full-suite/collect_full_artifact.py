import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import struct
import urllib.request
import zipfile


SOURCE = '6b3047b7979dfb86d837e74a21b0fd890e4f9e66'
RUN = 43616038272
ATTEMPT = 1


def utc_now():
    return datetime.now(timezone.utc).isoformat()


parser = argparse.ArgumentParser()
parser.add_argument('--metadata', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--url', required=True)
args = parser.parse_args()
metadata = json.loads(args.metadata.read_text())
assert metadata['workflow_run']['id'] == RUN
assert metadata['workflow_run']['head_sha'] == SOURCE
assert metadata['workflow_run']['head_branch'] == 'integration/lumo-live-connections-20261114'
assert not metadata['expired']
expected_size = metadata['size_in_bytes']
algorithm, expected_digest = metadata['digest'].split(':', 1)
assert algorithm == 'sha256' and len(expected_digest) == 64
args.output.mkdir(parents=True, exist_ok=True)
archive = args.output / f"original-artifact-{metadata['id']}.zip"
partial = archive.with_suffix('.zip.partial')
assert not archive.exists() and not partial.exists(), 'Refusing a duplicate original download'
started = utc_now()
digest = hashlib.sha256()
received = 0
with urllib.request.urlopen(args.url, timeout=60) as response, partial.open('xb') as output:
    while block := response.read(1024 * 1024):
        received += len(block)
        assert received <= expected_size, 'Archive exceeds the original API size'
        digest.update(block)
        output.write(block)
assert received == expected_size, (received, expected_size)
assert digest.hexdigest() == expected_digest, digest.hexdigest()
partial.rename(archive)
download_completed = utc_now()

members = []
seen = set()
text_suffixes = {'.json', '.jsonl', '.log', '.txt', '.csv', '.tsv', '.md'}
with zipfile.ZipFile(archive) as source:
    for info in source.infolist():
        path = PurePosixPath(info.filename)
        assert not path.is_absolute() and '..' not in path.parts
        assert info.filename not in seen, f'Duplicate ZIP member: {info.filename}'
        seen.add(info.filename)
        assert not stat.S_ISLNK(info.external_attr >> 16)
        if info.is_dir():
            continue
        output_path = args.output / 'originals' / Path(*path.parts)
        extract = path.suffix.lower() in text_suffixes
        if extract:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            assert not output_path.exists(), f'Original member already exists: {path}'
        hasher = hashlib.sha256()
        byte_count = 0
        header = b''
        output = output_path.open('xb') if extract else None
        try:
            # ZipExtFile validates the stored CRC at end-of-file. Every member
            # is consumed once, including images that remain in the archive.
            with source.open(info) as member:
                while block := member.read(1024 * 1024):
                    if len(header) < 24:
                        header += block[:24 - len(header)]
                    hasher.update(block)
                    byte_count += len(block)
                    if output is not None:
                        output.write(block)
        finally:
            if output is not None:
                output.close()
        assert byte_count == info.file_size
        row = {'path': info.filename, 'bytes': byte_count,
               'sha256': hasher.hexdigest(), 'zip_crc32': f'{info.CRC:08x}',
               'extracted_original_text': extract}
        if path.suffix.lower() == '.png':
            assert header[:8] == b'\x89PNG\r\n\x1a\n'
            assert header[12:16] == b'IHDR'
            row['width'], row['height'] = struct.unpack('>II', header[16:24])
        members.append(row)

report = {
    'source_sha': SOURCE, 'run_id': RUN, 'run_attempt': ATTEMPT,
    'download_started_utc': started,
    'download_completed_utc': download_completed,
    'inventory_completed_utc': utc_now(),
    'original_metadata': metadata,
    'archive': {'path': archive.name, 'bytes': received,
                'sha256': digest.hexdigest(), 'original_api_digest_matches': True},
    'all_zip_member_crcs': 'PASS',
    'png_count': sum(row['path'].lower().endswith('.png') for row in members),
    'members': members,
    'scope': 'All member hashes and ZIP CRCs checked; PNG dimensions read from original headers. This inventory does not claim visual inspection of every image.',
}
(args.output / 'archive-manifest.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({
    'archive': str(archive), 'bytes': received, 'sha256': digest.hexdigest(),
    'members': len(members), 'png_count': report['png_count'],
    'text_files': [row['path'] for row in members if row['extracted_original_text']],
    'png_groups': dict(Counter(str(PurePosixPath(row['path']).parent)
                               for row in members if row['path'].lower().endswith('.png'))),
}, ensure_ascii=False))
