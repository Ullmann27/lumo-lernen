"""Export the pinned Godot source as application data, never a second APK."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def run(*args, cwd=None):
    return subprocess.run(args, cwd=cwd, check=True)


def git_paths(repo: Path, *args):
    output = subprocess.check_output(['git', *args, '-z'], cwd=repo)
    return {path for path in output.decode('utf-8').split('\0') if path}


def remove_generated_sidecars(repo: Path, before: set[str]):
    """Remove only new, well-formed Godot UID sidecars of tracked inputs."""
    tracked = git_paths(repo, 'ls-files')
    untracked = git_paths(repo, 'ls-files', '--others', '--exclude-standard')
    for relative in untracked - before:
        if not relative.endswith(('.gd.uid', '.gdshader.uid')):
            continue
        if relative[:-4] not in tracked:
            continue
        path = repo / relative
        if path.is_symlink() or not path.is_file():
            continue
        if re.fullmatch(r'uid://[a-z0-9]+\s*', path.read_text()):
            path.unlink()



# Godot 4.6.3 extracts the three embedded JPEG images in the *verified*
# Meshy gate GLB to source-adjacent JPGs during import. They are generated
# files, not new application sources; the pack is exported BEFORE cleanup.
# For earlier releases, or for any other name or content, fail closed.
GROUNDED_GATE_REVISION = 'a17b06c4719cc94c94bdf97afb3b6862cd049323'
# Both reviewed revisions embed the exact same byte-identical GLB and 3 JPEGs.
# Cleanup remains restricted to these release pins; all other files fail closed.
GROUNDED_GATE_ALLOWED_REVISIONS = frozenset((
    GROUNDED_GATE_REVISION,
    '6518a13fb8eb30c81c8a2115d14791cbe7ddd24a',
))
GROUNDED_GATE_GLB_SHA256 = '8c8891062888eda5b553ae77390eda1a733368fc0bf73b86aefe2a7a666a565d'
GROUNDED_GATE_FILE = 'assets/kart/gates/lumo_kart_start_finish_gate_mobile.glb'
GROUNDED_GATE_GENERATED_IMAGES = frozenset(
    'assets/kart/gates/lumo_kart_start_finish_gate_mobile_' + name + '.jpg'
    for name in ('LumoBaseColor', 'LumoMetallicRoughness', 'LumoNormal')
)


def remove_generated_gate_images(repo: Path, before: set[str], source: dict):
    """Clean only verified GLB image sidecars of explicitly reviewed release pins.

    Preserve unexpected/untrusted files so the existing final dirty-source
    gate rejects packaging. Never remove a file present before import.
    """
    if source.get('revision') not in GROUNDED_GATE_ALLOWED_REVISIONS:
        return
    untracked = git_paths(repo, 'ls-files', '--others', '--exclude-standard')
    generated = (untracked - before) & GROUNDED_GATE_GENERATED_IMAGES
    if not generated:
        return

    glb = repo / GROUNDED_GATE_FILE
    if glb.is_symlink() or not glb.is_file():
        raise RuntimeError('Refusing gate image cleanup: missing trusted GLB')
    with glb.open('rb') as handle:
        digest = hashlib.file_digest(handle, 'sha256').hexdigest()
    if digest != GROUNDED_GATE_GLB_SHA256:
        raise RuntimeError('Refusing gate image cleanup: GLB hash mismatch')

    # A GLB v2 with embedded JPEGs is required, not an unrelated object
    # sharing a filename. Import-generated texture bytes remain unchanged
    # in the finished Godot PCK; only the temporary source checkout is reset.
    raw = glb.read_bytes()
    if len(raw) < 28 or raw[:4] != b'glTF':
        raise RuntimeError('Refusing gate image cleanup: malformed glTF header')
    _, version, total, json_length, json_tag = struct.unpack_from('<4s4I', raw)
    if version != 2 or total != len(raw) or json_tag != 0x4e4f534a:
        raise RuntimeError('Refusing gate image cleanup: invalid glTF 2.0')
    manifest = json.loads(raw[20:20 + json_length])
    jpeg_images = [
        image for image in manifest.get('images', [])
        if image.get('mimeType') == 'image/jpeg' and 'bufferView' in image
    ]
    if len(jpeg_images) < 3:
        raise RuntimeError('Refusing gate image cleanup: embedded JPEGs missing')

    for relative in sorted(generated):
        path = repo / relative
        if path.is_symlink() or not path.is_file():
            raise RuntimeError('Refusing gate image cleanup: unsafe output ' + relative)
        size = path.stat().st_size
        if not 100 <= size <= 6000000:
            raise RuntimeError('Refusing gate image cleanup: invalid size ' + relative)
        with path.open('rb') as handle:
            prefix = handle.read(3)
            handle.seek(-2, 2)
            suffix = handle.read(2)
        if prefix != b'\xff\xd8\xff' or suffix != b'\xff\xd9':
            raise RuntimeError('Refusing gate image cleanup: non-JPEG output ' + relative)

    for relative in sorted(generated):
        (repo / relative).unlink()
        print('[LumoGateImport] removed verified temporary JPEG:', relative)


def export(repo: Path, binary: str):
    source = json.loads((ROOT / 'config/godot-source.json').read_text())
    if not repo.exists():
        run('git', 'clone', source['repository'], str(repo))
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
    dirty = subprocess.check_output(['git', 'status', '--porcelain'], cwd=repo, text=True).strip()
    if head != source['revision']:
        if dirty:
            raise RuntimeError('Refusing to replace uncommitted Godot work')
        run('git', 'fetch', 'origin', source['revision'], cwd=repo)
        run('git', 'checkout', '--detach', source['revision'], cwd=repo)
    elif dirty:
        raise RuntimeError('Commit Godot changes before packaging the APK')
    version = subprocess.check_output([binary, '--version'], text=True).strip()
    if not version.startswith(source['engine'] + '.'):
        raise RuntimeError(f'Godot {source["engine"]} required, found {version}')
    before = git_paths(repo, 'ls-files', '--others', '--exclude-standard')
    try:
        run(binary, '--headless', '--path', str(repo), '--editor', '--import', '--quit')
        assets = ROOT / 'android/app/src/main/assets'
        assets.mkdir(parents=True, exist_ok=True)
        pack = assets / 'lumo_game.pck'
        run(binary, '--headless', '--path', str(repo), '--export-pack', 'Android', str(pack))
        header = pack.read_bytes()[:20]
        magic, _, major, minor, patch = struct.unpack('<4s4I', header)
        if magic != b'GDPC' or (major, minor, patch) != (4, 6, 3):
            raise RuntimeError('Export produced an invalid or mismatched Godot PCK')
        proof = {**source, 'pck_sha256': hashlib.file_digest(pack.open('rb'), 'sha256').hexdigest(), 'bytes': pack.stat().st_size}
        (assets / 'lumo_game_source.json').write_text(json.dumps(proof, indent=2) + '\n')
        print(json.dumps(proof))
    finally:
        remove_generated_sidecars(repo, before)
        remove_generated_gate_images(repo, before, source)
    remaining = subprocess.check_output(['git', 'status', '--porcelain'], cwd=repo, text=True).strip()
    if remaining:
        raise RuntimeError('Godot import changed sources; refuse exported candidate:\n' + remaining)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=ROOT / 'build/godot-source')
    parser.add_argument('--godot', default=shutil.which('godot') or 'godot')
    args = parser.parse_args()
    export(args.repo.resolve(), args.godot)
