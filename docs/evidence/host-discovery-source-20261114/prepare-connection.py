from __future__ import annotations

import base64
import hashlib
import importlib.util
import json
from pathlib import Path
import sys


def identity(data: bytes) -> tuple[str, str]:
    return (hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest(),
            hashlib.sha256(data).hexdigest())


def regular(path: Path) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise ValueError(f'Expected original regular file: {path}')
    return path.read_bytes()


def main(spec_path: Path) -> None:
    spec = json.loads(spec_path.read_text())
    root = Path(spec['output_directory'])
    if root.exists():
        raise ValueError('Refusing to overwrite an existing prepared publication')
    documents = root / 'documents'
    chunks_dir = root / 'gitdata'
    documents.mkdir(parents=True)
    chunks_dir.mkdir()
    files = []
    archive_records = []
    loader = importlib.util.spec_from_file_location('evidence_archive', '/tmp/lumo-root-recovery-0900/prepare_host79_evidence.py')
    helper = importlib.util.module_from_spec(loader)
    loader.loader.exec_module(helper)
    helper.DOCS = documents
    for item in spec.get('copies', []):
        archive_records.append(helper.copy_original(Path(item['source']), item['destination'], item.get('sha256')))
    for item in spec.get('archives', []):
        archive_records.append(helper.archive_pack(Path(item['source']), item['destination'], item['manifest_sha256']))
    for item in spec.get('source_files', []):
        source = Path(item['source'])
        data = regular(source)
        blob, sha256 = identity(data)
        if blob != item['git_blob'] or sha256 != item['sha256']:
            raise ValueError(f'Frozen source identity changed: {source}')
        files.append({'path': item['path'], 'source': str(source), 'mode': item.get('mode', '100644')})
    (documents / 'root-connection.json').write_text(json.dumps(spec['connection'], ensure_ascii=False, indent=2) + '\n')
    (documents / 'original-archive-bindings.json').write_text(json.dumps({'schema': 1, 'files': archive_records}, ensure_ascii=False, indent=2) + '\n')
    (documents / 'prepare-connection.py').write_bytes(Path(__file__).read_bytes())
    for source in sorted(documents.rglob('*')):
        if source.is_file():
            files.append({'path': spec['evidence_prefix'] + '/' + source.relative_to(documents).as_posix(),
                          'source': str(source), 'mode': '100644'})
    entries = []
    blobs = []
    local_files = []
    inventory = []
    paths = set()
    seen_blobs = set()
    for item in files:
        path = item['path']
        if path.startswith('/') or any(p in ('', '.', '..') for p in path.split('/')) or path in paths:
            raise ValueError(f'Unsafe or duplicate publication path: {path}')
        paths.add(path)
        data = regular(Path(item['source']))
        sha, sha256 = identity(data)
        entry = {'path': path, 'mode': item['mode'], 'type': 'blob', 'sha': sha}
        entries.append(entry)
        local_files.append({'entry': entry, 'file': item['source']})
        inventory.append({'path': path, 'bytes': len(data), 'sha256': sha256, 'git_blob': sha})
        if sha in seen_blobs:
            continue
        seen_blobs.add(sha)
        try:
            content = data.decode('utf-8')
            encoding = 'utf-8'
        except UnicodeDecodeError:
            content = base64.b64encode(data).decode('ascii')
            encoding = 'base64'
        chunks = []
        for offset in range(0, max(1, len(content)), 30000):
            chunk = chunks_dir / f'{sha}-{offset // 30000:04d}.chunk'
            chunk.write_bytes(content[offset:offset + 30000].encode('utf-8'))
            chunks.append(str(chunk))
        blobs.append({'sha': sha, 'encoding': encoding, 'bytes': len(data), 'characters': len(content),
                      'chunks': chunks, 'source_path': path})
    plan = {key: spec[key] for key in ('repository_full_name', 'parent_sha', 'base_tree', 'branch_name', 'message')}
    plan.update({'local_commit': None, 'entries': entries, 'blobs': blobs})
    result = {'plan': plan, 'local_files': local_files, 'inventory': inventory}
    (root / 'prepared.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'prepared': str(root / 'prepared.json'), 'paths': len(entries),
                      'source_paths': len(spec.get('source_files', [])), 'bytes': sum(x['bytes'] for x in inventory)}, indent=2))


if __name__ == '__main__':
    main(Path(sys.argv[1]))
