import hashlib, json, stat, zipfile
from pathlib import Path, PurePosixPath
archive = Path('publication/original-bundle.zip')
artifact = json.loads(Path('publication/metadata/bundle.json').read_text())
assert archive.stat().st_size == artifact['size_in_bytes']
with archive.open('rb') as handle:
    assert 'sha256:' + hashlib.file_digest(handle, 'sha256').hexdigest() == artifact['digest']
root = Path('publication/delivery')
root.mkdir()
with zipfile.ZipFile(archive) as zipped:
    seen = set()
    for member in zipped.infolist():
        path = PurePosixPath(member.filename)
        name = path.as_posix()
        assert not member.flag_bits & 1
        assert path.parts and not path.is_absolute() and '..' not in path.parts
        assert '\\' not in member.filename and name == member.filename.rstrip('/')
        assert name not in seen
        seen.add(name)
        kind = stat.S_IFMT(member.external_attr >> 16)
        assert kind in ((0, stat.S_IFDIR) if member.is_dir() else (0, stat.S_IFREG))
    zipped.extractall(root)
