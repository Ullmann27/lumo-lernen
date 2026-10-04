#!/usr/bin/env python3
"""Fetch and verify Heinz's immutable Lumo bundle. Never imports into a repository."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import tempfile
import urllib.request
import zipfile

URL = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/3f6109fb-0429-4acc-9ef0-22219252239a.zip'
SHA256 = 'e32a2d6e78d1af8d51c4e27b6b66c5a87d2c2da252a5f61a3e7da0d76a5ffe20'
BYTE_COUNT = 24962269
FILE_COUNT = 170
ROOT = 'Lumo_Assetpaket_Einzelbilder_2026-10-04'
MAX_EXPANDED = 50_000_000

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise RuntimeError('Unexpected redirect: stop and verify the delivery source')

def validate_members(members: list[zipfile.ZipInfo]) -> None:
    seen: set[str] = set()
    expanded = 0
    for info in members:
        name = info.filename
        parts = PurePosixPath(name).parts
        mode = stat.S_IFMT(info.external_attr >> 16)
        if (not parts or parts[0] != ROOT or name.startswith('/')
                or '\\' in name or ':' in name or '..' in name.split('/')
                or '.' in name.split('/') or mode not in (0, stat.S_IFREG, stat.S_IFDIR)
                or info.flag_bits & 1):
            raise ValueError(f'Unsafe archive member: {name}')
        key = name.rstrip('/').casefold()
        if key in seen:
            raise ValueError(f'Duplicate archive member: {name}')
        seen.add(key)
        expanded += info.file_size
        if expanded > MAX_EXPANDED:
            raise ValueError('Archive expands beyond the transport budget')

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--local-zip', type=Path, help='Verify existing bytes without network access')
    args = parser.parse_args()
    work = Path(tempfile.mkdtemp(prefix='lumo-asset-receipt-')).resolve()
    try:
        if args.local_zip:
            archive = args.local_zip.resolve(strict=True)
        else:
            archive = work / (ROOT + '.zip')
            opener = urllib.request.build_opener(NoRedirect())
            with opener.open(URL, timeout=60) as response, archive.open('xb') as out:
                total = 0
                while chunk := response.read(1024 * 1024):
                    total += len(chunk)
                    if total > BYTE_COUNT:
                        raise ValueError('Download exceeds the expected size')
                    out.write(chunk)
        if archive.stat().st_size != BYTE_COUNT:
            raise ValueError('Archive byte count differs from the approved package')
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        if digest != SHA256:
            raise ValueError('SHA-256 mismatch; do not extract or import')
        with zipfile.ZipFile(archive) as package:
            members = package.infolist()
            validate_members(members)
            if len(members) != FILE_COUNT:
                raise ValueError('Archive member count differs from the approved package')
            if package.testzip() is not None:
                raise ValueError('ZIP CRC verification failed')
            unpacked = work / 'unpacked'
            unpacked.mkdir()
            package.extractall(unpacked)
        receipt = {'status': 'TRANSPORT_VERIFIED', 'source_url': URL,
                   'archive_path': str(archive), 'unpacked_root': str(unpacked / ROOT),
                   'bytes': BYTE_COUNT, 'sha256': digest, 'archive_entries': FILE_COUNT,
                   'source_mode': 'local' if args.local_zip else 'https_download',
                   'repo_files_changed': False, 'app_runtime_tested': False}
        (work / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(receipt, indent=2))
        return 0
    except (OSError, ValueError, RuntimeError, zipfile.BadZipFile) as exc:
        print(json.dumps({'status': 'BLOCKED', 'reason': str(exc), 'work_dir': str(work)}))
        return 1

if __name__ == '__main__':
    raise SystemExit(main())
