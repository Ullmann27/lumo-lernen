"""Clean only proven importer byproducts of the reviewed LUMO 2100 native tree."""
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import difflib

NATIVE_REVISION = '76e9da9c572ddfdb050a7e5f7da3479cf8086515'
WORLD_MODELS = {
    'assets/creative/lumo_world/meshy/market_stall.glb': (
        3894360, '1ae949b50fc26121c44ff3734eb1d3fd7f4ba5877afc77f1562e73f8a7e3e386'),
    'assets/creative/lumo_world/meshy/lumo_house.glb': (
        4998144, '15bea2db7cc6d5e840b6ed6216f4c90f8c110c6c379d6df7c9f2ed50467a12a7'),
}
ACTOR = 'assets/characters/lumo_nextgen_chat3/Lumo-Learning-Animated.glb'
ACTOR_IDENTITY = (6012864, '48801da4e10e297902d493c7d9dab6e2fac2800dd3ee6779d3f98ba6d17ffada')


def git_paths(repo, *args):
    output = subprocess.check_output(['git', *args, '-z'], cwd=repo)
    return {item for item in output.decode('utf-8').split('\0') if item}


def regular_file(repo, relative):
    path = repo / relative
    if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(repo.resolve()):
        raise RuntimeError('Unsafe recovered import path: ' + relative)
    return path


def verified_model(repo, relative, identity, tracked):
    if relative not in tracked:
        raise RuntimeError('Recovered model is not tracked: ' + relative)
    raw = regular_file(repo, relative).read_bytes()
    if (len(raw), hashlib.sha256(raw).hexdigest()) != identity:
        raise RuntimeError('Recovered GLB identity mismatch: ' + relative)
    return raw


def png_payload(raw):
    # Permit only the GLB's zero to three alignment bytes after a complete PNG.
    normalized = raw.rstrip(b'\0')
    if (not 16 <= len(raw) <= 100_000_000 or len(raw) - len(normalized) > 3
            or not normalized.startswith(b'\x89PNG\r\n\x1a\n')
            or not normalized.endswith(b'IEND\xaeB\x60\x82')):
        raise RuntimeError('Invalid recovered embedded PNG')
    return normalized


def embedded_png(raw):
    if len(raw) < 28 or struct.unpack_from('<4sII', raw) != (b'glTF', 2, len(raw)):
        raise RuntimeError('Invalid recovered GLB header')
    size, kind = struct.unpack_from('<I4s', raw, 12)
    offset = 20 + size
    if kind != b'JSON' or size % 4 or offset + 8 > len(raw):
        raise RuntimeError('Invalid recovered GLB JSON chunk')
    try:
        doc = json.loads(raw[20:offset])
        images = doc['images']
        if (len(images) != 1 or images[0]['mimeType'] != 'image/png'
                or 'uri' in images[0] or len(doc['buffers']) != 1
                or 'uri' in doc['buffers'][0]):
            raise ValueError('Expected one embedded PNG and one internal buffer')
        view = doc['bufferViews'][images[0]['bufferView']]
        start, count = view.get('byteOffset', 0), view['byteLength']
        length, kind = struct.unpack_from('<I4s', raw, offset)
        used = doc['buffers'][0]['byteLength']
        if (kind != b'BIN\0' or offset + 8 + length != len(raw)
                or not 0 <= length - used <= 3 or view['buffer'] != 0
                or start < 0 or count <= 0 or start + count > used):
            raise ValueError('Invalid recovered GLB binary buffer view')
    except (KeyError, IndexError, TypeError, ValueError, struct.error) as exc:
        raise RuntimeError('Invalid recovered GLB embedded image') from exc
    return png_payload(raw[offset + 8 + start:offset + 8 + start + count])


def cleanup_recovered_imports(repo: Path, before: set[str], source: dict):
    """Validate the entire removal set, then restore only known byproducts.

    Called after export, so the generated PCK still contains the imported
    resources. The immutable model bytes, params and other sources must not
    change. Unknown revisions and unexpected files retain the dirty-tree gate.
    """
    if source.get('revision') != NATIVE_REVISION:
        return
    tracked = git_paths(repo, 'ls-files')
    generated = git_paths(repo, 'ls-files', '--others', '--exclude-standard') - before
    remove = []
    for relative, identity in WORLD_MODELS.items():
        name = str(Path(relative).with_name(Path(relative).stem + '_0.png'))
        if name not in generated:
            continue
        raw = verified_model(repo, relative, identity, tracked)
        output = regular_file(repo, name)
        if png_payload(output.read_bytes()) != embedded_png(raw):
            raise RuntimeError('Extracted World PNG differs from verified GLB: ' + name)
        remove.append(output)

    metadata_name = ACTOR + '.import'
    if metadata_name not in tracked:
        raise RuntimeError('Missing tracked learning actor import metadata')
    metadata = regular_file(repo, metadata_name)
    original = subprocess.check_output(['git', 'show', 'HEAD:' + metadata_name], cwd=repo)
    current = metadata.read_bytes()
    restore = current != original
    if restore:
        verified_model(repo, ACTOR, ACTOR_IDENTITY, tracked)
        # Godot generates the previously absent UID during the import. It must
        # be the only difference, at the exact expected position in [remap].
        normalized, count = re.subn(
            rb'(?m)(^type="PackedScene"\n)uid="uid://[a-z0-9]+"\n', rb'\1', current)
        if count != 1 or normalized != original or re.search(rb'(?m)^uid=', original):
            difference = ''.join(difflib.unified_diff(
                original.decode('utf-8', errors='replace').splitlines(keepends=True),
                current.decode('utf-8', errors='replace').splitlines(keepends=True),
                fromfile='pinned import metadata', tofile='observed import metadata'))
            raise RuntimeError('Unexpected learning actor import change; only generated UID is permitted\n' + difference)

    for path in remove:
        path.unlink()
        print('[LumoRecoveredImport] verified generated PNG removed:', path.relative_to(repo))
    if restore:
        metadata.write_bytes(original)
        print('[LumoRecoveredImport] restored original metadata after UID-only import change')
