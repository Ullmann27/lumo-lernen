"""Retain one authorized artifact with bounded transfer/extraction buffers."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import stat
import sys
import urllib.request
import zipfile


def main() -> None:
    spec = json.loads(Path(sys.argv[1]).read_text())
    size = spec['bytes']
    expected = spec['sha256'].removeprefix('sha256:')
    assert isinstance(size, int) and 0 < size <= 1_200_000_000
    assert len(expected) == 64 and all(c in '0123456789abcdef' for c in expected)
    dest = Path(spec['destination'])
    assert not dest.exists(), 'Evidence destination must be new'
    assert shutil.disk_usage(dest.parent).free > size + 20_000_000
    dest.mkdir()
    partial = dest / ('artifact-' + str(spec['artifact_id']) + '.zip.part')
    final = partial.with_suffix('')
    digest = hashlib.sha256()
    received = 0
    request = urllib.request.Request(spec['download_url'], headers={'User-Agent': 'Lumo-artifact-verification-stream/1'})
    with urllib.request.urlopen(request, timeout=60) as response, partial.open('xb') as output:
        assert response.status == 200
        if response.headers.get('Content-Length') is not None:
            assert int(response.headers['Content-Length']) == size
        while block := response.read(1024 * 1024):
            received += len(block)
            assert received <= size
            digest.update(block)
            output.write(block)
    assert received == size and digest.hexdigest() == expected, 'Archive bytes differ'
    partial.rename(final)
    members = []
    with zipfile.ZipFile(final) as archive:
        entries = archive.infolist()
        assert 0 < len(entries) < 20_000
        names = set()
        total = 0
        for entry in entries:
            path = PurePosixPath(entry.filename)
            assert entry.filename and entry.filename not in names and '\\' not in entry.filename
            assert not path.is_absolute() and all(p not in ('', '.', '..') for p in path.parts)
            assert not stat.S_ISLNK(entry.external_attr >> 16)
            names.add(entry.filename)
            total += entry.file_size
        assert total <= 2_500_000_000
        assert shutil.disk_usage(dest).free > total + 20_000_000
        originals = dest / 'original'
        originals.mkdir()
        for entry in entries:
            target = originals.joinpath(*PurePosixPath(entry.filename).parts)
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            temporary = target.with_name(target.name + '.part')
            assert not target.exists() and not temporary.exists()
            item_hash = hashlib.sha256()
            written = 0
            with archive.open(entry) as source, temporary.open('xb') as output:
                while block := source.read(1024 * 1024):
                    item_hash.update(block)
                    output.write(block)
                    written += len(block)
            assert written == entry.file_size
            temporary.rename(target)
            members.append({'path': entry.filename, 'bytes': written, 'sha256': item_hash.hexdigest(),
                            'crc32': f'{entry.CRC:08x}'})
    report = {'artifactId': spec['artifact_id'], 'workflowRun': spec['run_id'],
              'archiveBytes': received, 'archiveSha256': digest.hexdigest(),
              'allMemberCRCsVerified': True, 'archiveRetainedLocally': True,
              'transferBufferBytes': 1024 * 1024, 'archiveLoadedIntoPythonMemory': False,
              'members': members}
    (dest / 'artifact-verification.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'status': 'PASS', 'artifactId': spec['artifact_id'], 'archiveBytes': received,
                      'archiveSha256': digest.hexdigest(), 'members': len(members),
                      'uncompressedBytes': sum(x['bytes'] for x in members), 'destination': str(dest)}))


if __name__ == '__main__':
    main()
