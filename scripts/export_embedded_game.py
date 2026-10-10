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
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=repo, text=True).strip():
        raise RuntimeError('Godot import changed sources; refuse exported candidate')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=ROOT / 'build/godot-source')
    parser.add_argument('--godot', default=shutil.which('godot') or 'godot')
    args = parser.parse_args()
    export(args.repo.resolve(), args.godot)
