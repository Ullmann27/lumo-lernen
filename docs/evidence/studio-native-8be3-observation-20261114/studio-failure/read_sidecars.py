"""Read one declared original artifact without retaining its large ZIP."""
from pathlib import Path, PurePosixPath
import hashlib
import io
import json
import re
import sys
import zipfile
import requests

ROOT = Path(__file__).resolve().parent
SIZE = 78023259
DIGEST = '46db85923551b9e6508047fba6d8d096540e081b2d1ac3680e753476936f3ce1'


def require(value, message):
    if not value:
        raise RuntimeError(message)


def main(url):
    session = requests.Session()
    digest = hashlib.sha256()
    count = 0
    with session.get(url, stream=True, timeout=(20, 120)) as response:
        require(response.status_code == 200, 'Original stream HTTP status differs')
        require(int(response.headers['Content-Length']) == SIZE, 'Original stream length differs')
        etag = response.headers.get('ETag')
        require(bool(etag), 'Stable original ETag absent')
        for block in response.iter_content(1024 * 1024):
            count += len(block)
            require(count <= SIZE, 'Original stream exceeds expected size')
            digest.update(block)
    require(count == SIZE and digest.hexdigest() == DIGEST, 'Original stream identity differs')
    ranges = []

    class RangeReader(io.RawIOBase):
        def __init__(self):
            self.position = 0

        def seekable(self):
            return True

        def readable(self):
            return True

        def tell(self):
            return self.position

        def seek(self, offset, whence=0):
            position = offset if whence == 0 else self.position + offset if whence == 1 else SIZE + offset
            require(0 <= position <= SIZE, 'Out-of-range archive seek')
            self.position = position
            return position

        def read(self, size=-1):
            end = SIZE if size < 0 else min(SIZE, self.position + size)
            if end == self.position:
                return b''
            start = self.position
            headers = {'Range': f'bytes={start}-{end-1}', 'If-Match': etag}
            with session.get(url, headers=headers, stream=True, timeout=(20, 60)) as response:
                require(response.status_code == 206, 'Original range HTTP status differs')
                require(response.headers.get('Content-Range') == f'bytes {start}-{end-1}/{SIZE}', 'Original range coordinates differ')
                require(response.headers.get('ETag') == etag, 'Original artifact changed between reads')
                require(int(response.headers['Content-Length']) == end - start, 'Original range length differs')
                data = response.content
            require(len(data) == end - start, 'Original range is incomplete')
            ranges.append([start, end-1, len(data)])
            self.position = end
            return data

    inventory = []
    selected = []
    selected_bytes = 0
    out = ROOT / 'selected-originals'
    with zipfile.ZipFile(RangeReader()) as archive:
        for item in archive.infolist():
            path = PurePosixPath(item.filename)
            require(not path.is_absolute() and '..' not in path.parts and '\\' not in item.filename, 'Unsafe original member name')
            inventory.append({'path': item.filename, 'bytes': item.file_size, 'compressed_bytes': item.compress_size, 'crc32': f'{item.CRC:08x}'})
            if item.is_dir() or 'lumo_facial_capture/' not in item.filename or path.suffix not in ('.json', '.log', '.txt'):
                continue
            selected_bytes += item.file_size
            require(selected_bytes <= 5 * 1024 * 1024, 'Selected sidecar limit exceeded')
            data = archive.read(item)
            destination = out / item.filename
            destination.parent.mkdir(parents=True, exist_ok=True)
            with destination.open('xb') as stream:
                stream.write(data)
            selected.append({'path': item.filename, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(), 'crc32_verified': f'{item.CRC:08x}'})
    require(selected, 'No required original facial sidecars found')
    (ROOT / 'artifact-inventory.json').write_text(json.dumps(inventory, indent=2) + '\n')
    report = {'artifact_id': 14100974125, 'run_id': 43561885899, 'source': '8be3a95d5d948d457c4c39bc6694138d60b70027',
              'original_stream_bytes': count, 'original_stream_sha256': digest.hexdigest(), 'expected_digest_matched': True,
              'original_zip_saved': False, 'original_etag': etag, 'range_requests': ranges, 'selected': selected,
              'selected_bytes': selected_bytes, 'inventory_entries': len(inventory), 'crc_scope': 'Only the selected sidecars were decompressed and CRC-checked; whole ZIP SHA256 was independently streamed.'}
    (ROOT / 'sidecar-transfer.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ('artifact_id', 'original_stream_bytes', 'original_stream_sha256', 'selected_bytes', 'inventory_entries')}))


if __name__ == '__main__':
    try:
        main(sys.stdin.readline().strip())
    except Exception as error:
        # HTTP exceptions can include signed redirects: never print their text.
        print('Original sidecar transfer failed: ' + type(error).__name__, file=sys.stderr)
        raise SystemExit(1)
