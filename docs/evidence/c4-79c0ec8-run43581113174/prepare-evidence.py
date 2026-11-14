from __future__ import annotations

import base64
import gzip
import hashlib
import io
import json
import shutil
import tarfile
from pathlib import Path


ROOT = Path('/tmp/lumo-root-recovery-0900/host79-evidence-publication')
DOCS = ROOT / 'documents'
CHUNKS = ROOT / 'gitdata'
PREFIX = 'docs/evidence/c4-79c0ec8-run43581113174'


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def checked_file(path: Path, expected: str | None = None) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise ValueError(f'Not a regular original file: {path}')
    data = path.read_bytes()
    if expected is not None and digest(data) != expected:
        raise ValueError(f'Original digest changed: {path}')
    return data


def copy_original(source: Path, destination: str, expected: str | None = None) -> dict:
    data = checked_file(source, expected)
    target = DOCS / destination
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    if checked_file(target) != data:
        raise ValueError(f'Copied original changed: {target}')
    return {'path': destination, 'bytes': len(data), 'sha256': digest(data), 'source': str(source)}


def archive_pack(source: Path, destination: str, expected_manifest: str) -> dict:
    manifest_path = source / 'manifest.json'
    manifest = json.loads(checked_file(manifest_path, expected_manifest))
    for entry in manifest['files']:
        original = checked_file(source / entry['path'], entry['sha256'])
        if len(original) != entry['bytes']:
            raise ValueError(f'Original length changed: {entry["path"]}')
    originals = {}
    for path in sorted(source.rglob('*')):
        if path.is_symlink():
            raise ValueError(f'Symlink in frozen pack: {path}')
        if path.is_file():
            name = path.relative_to(source).as_posix()
            originals[name] = checked_file(path)
    target = DOCS / destination
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open('wb') as raw:
        with gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode='w') as archive:
                for name, data in originals.items():
                    info = tarfile.TarInfo(name)
                    info.size = len(data)
                    info.mode = 0o644
                    info.mtime = 0
                    archive.addfile(info, io.BytesIO(data))
    with tarfile.open(target, 'r:gz') as archive:
        members = archive.getmembers()
        if len(members) != len(originals):
            raise ValueError('Archive member count differs')
        for member in members:
            if not member.isfile() or archive.extractfile(member).read() != originals[member.name]:
                raise ValueError(f'Archive round-trip differs: {member.name}')
    data = checked_file(target)
    return {'path': destination, 'bytes': len(data), 'sha256': digest(data),
            'source': str(source), 'members': len(originals),
            'original_manifest_sha256': expected_manifest, 'all_members_read_back_equal': True}


def prepare(spec_path: Path) -> None:
    spec = json.loads(spec_path.read_text())
    if ROOT.exists():
        raise ValueError('Publication directory already exists; refusing overwrite')
    DOCS.mkdir(parents=True)
    CHUNKS.mkdir()
    sources = []
    for item in spec['copies']:
        sources.append(copy_original(Path(item['source']), item['destination'], item.get('sha256')))
    for item in spec['archives']:
        sources.append(archive_pack(Path(item['source']), item['destination'], item['manifest_sha256']))
    for item in spec['raw_directories']:
        directory = Path(item['source'])
        for original in sorted(directory.rglob('*')):
            if original.is_file():
                sources.append(copy_original(original, item['destination'] + '/' + original.relative_to(directory).as_posix()))
    (DOCS / 'checkpoint-intent.json').write_text(json.dumps(spec['intent'], ensure_ascii=False, indent=2) + '\n')
    (DOCS / 'original-archive-bindings.json').write_text(json.dumps({'schema': 1, 'files': sources}, ensure_ascii=False, indent=2) + '\n')
    (DOCS / 'prepare-evidence.py').write_bytes(Path(__file__).read_bytes())
    inventory = []
    entries = []
    blobs = []
    local_files = []
    for original in sorted(DOCS.rglob('*')):
        if not original.is_file():
            continue
        data = checked_file(original)
        git_path = PREFIX + '/' + original.relative_to(DOCS).as_posix()
        sha = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
        entry = {'path': git_path, 'mode': '100644', 'type': 'blob', 'sha': sha}
        entries.append(entry)
        inventory.append({'path': git_path, 'bytes': len(data), 'sha256': digest(data), 'git_blob': sha})
        try:
            content = data.decode('utf-8')
            encoding = 'utf-8'
        except UnicodeDecodeError:
            content = base64.b64encode(data).decode('ascii')
            encoding = 'base64'
        chunks = []
        for offset in range(0, len(content), 30000):
            chunk = CHUNKS / f'{sha}-{offset // 30000:04d}.chunk'
            chunk.write_bytes(content[offset:offset + 30000].encode('utf-8'))
            chunks.append(str(chunk))
        if not chunks:
            chunk = CHUNKS / f'{sha}-0000.chunk'
            chunk.write_bytes(b'')
            chunks.append(str(chunk))
        blobs.append({'sha': sha, 'encoding': encoding, 'bytes': len(data), 'characters': len(content),
                      'chunks': chunks, 'source_path': git_path})
        local_files.append({'entry': entry, 'file': str(original)})
    plan = {'repository_full_name': 'Ullmann27/lumo-lernen', 'base_tree': 'e70dccc439c99a1bc2e8546f552a7886b8838225',
            'parent_sha': '79c0ec868d6a6236eb2ae942d18251d0ed96379f', 'local_commit': None,
            'branch_name': 'evidence/lumo-c4-79c0ec8-20261114',
            'message': 'docs(evidence): preserve exact 79c C4 runtime and local contracts without moving active build [skip ci]',
            'entries': entries, 'blobs': blobs}
    result = {'plan': plan, 'local_files': local_files, 'inventory': inventory}
    (ROOT / 'prepared.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'prepared': str(ROOT / 'prepared.json'), 'paths': len(entries), 'bytes': sum(x['bytes'] for x in inventory),
                      'archives': [x for x in sources if x['path'].endswith('.tar.gz')]}, indent=2))


if __name__ == '__main__':
    import sys
    prepare(Path(sys.argv[1]))
