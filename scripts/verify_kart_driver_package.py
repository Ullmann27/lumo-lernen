"""Bind all 27 production driver variants to the actual APK's Godot pack."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile

from export_embedded_game import run_godot


ROOT = Path(__file__).resolve().parents[1]
DRIVER_MANIFEST = 'assets/kart/production/drivers/manifest.json'
DRIVERS = frozenset(('badger', 'cat', 'frog', 'lion', 'otter', 'owl',
                     'rabbit', 'squirrel', 'turtle'))
LOD_FILES = {'lod0': 'driver.glb', 'lod1': 'driver_lod1.glb', 'lod2': 'driver_lod2.glb'}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def source_inventory(source: Path) -> dict:
    manifest_path = source / DRIVER_MANIFEST
    require(manifest_path.is_file() and not manifest_path.is_symlink(),
            'The production driver manifest must be a regular source file')
    raw = manifest_path.read_bytes()
    manifest = json.loads(raw)
    drivers = manifest.get('drivers')
    require(isinstance(drivers, list) and len(drivers) == len(DRIVERS),
            'The driver manifest must contain all nine production rivals')
    require(all(isinstance(row, dict) for row in drivers)
            and {row.get('id') for row in drivers} == DRIVERS,
            'The driver manifest has missing, duplicate or unexpected rivals')
    files = []
    for driver in drivers:
        identifier = driver['id']
        bones, animations = driver.get('bones'), driver.get('animations')
        require(isinstance(bones, list) and bones
                and all(isinstance(name, str) and name for name in bones)
                and len(set(bones)) == len(bones), f'{identifier}: invalid declared skeleton')
        require(isinstance(animations, dict) and animations
                and all(isinstance(name, str) and name for name in animations),
                f'{identifier}: invalid declared animation inventory')
        lods = driver.get('lods')
        require(isinstance(lods, list) and len(lods) == 3
                and all(isinstance(row, dict) for row in lods)
                and {row.get('level') for row in lods} == set(LOD_FILES),
                f'{identifier}: exactly three distinct production LODs are required')
        for lod in lods:
            level = lod['level']
            relative = f'assets/kart/production/drivers/{identifier}/{LOD_FILES[level]}'
            require(lod.get('file') == relative, f'{identifier}: unexpected production asset path')
            path = source / relative
            require(path.is_file() and not path.is_symlink()
                    and path.resolve().is_relative_to(source.resolve()),
                    f'{relative}: source GLB is missing or redirected')
            size, digest = lod.get('bytes'), lod.get('sha256')
            require(type(size) is int and size > 0 and isinstance(digest, str)
                    and re.fullmatch(r'[0-9a-f]{64}', digest),
                    f'{relative}: invalid declared GLB identity')
            with path.open('rb') as stream:
                actual_digest = hashlib.file_digest(stream, 'sha256').hexdigest()
            require(path.stat().st_size == size and actual_digest == digest,
                    f'{relative}: actual source GLB differs from the driver manifest')
            files.append({'driver': identifier, 'level': level, 'file': relative,
                          'bytes': size, 'sha256': digest,
                          'bones': list(bones), 'clips': sorted(animations)})
    return {'source_manifest': DRIVER_MANIFEST,
            'source_manifest_sha256': hashlib.sha256(raw).hexdigest(),
            'source_files': sorted(files, key=lambda row: row['file'])}


def extract_verified_pack(apk: Path, destination: Path, source: dict) -> dict:
    with zipfile.ZipFile(apk) as archive:
        for name in ('assets/lumo_game_source.json', 'assets/lumo_game.pck'):
            require(archive.namelist().count(name) == 1, f'APK has a missing or duplicate {name}')
        packaged = json.loads(archive.read('assets/lumo_game_source.json'))
        require(all(packaged.get(key) == source.get(key)
                    for key in ('repository', 'revision', 'engine')),
                'APK Godot source identity differs from the pinned source')
        with archive.open('assets/lumo_game.pck') as stream, destination.open('wb') as output:
            shutil.copyfileobj(stream, output)
    with destination.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    require(packaged.get('pck_sha256') == digest
            and packaged.get('bytes') == destination.stat().st_size,
            'Actual APK PCK differs from its source receipt')
    return packaged


def verify(apk: Path, source_root: Path, godot: str, out: Path):
    source = json.loads((ROOT / 'config/godot-source.json').read_text())
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source_root, text=True).strip()
    require(revision == source['revision'], 'Driver audit source is not the exact pinned Godot commit')
    require(not subprocess.check_output(['git', 'status', '--porcelain'], cwd=source_root, text=True).strip(),
            'Driver audit source contains uncommitted changes')
    engine = subprocess.check_output([godot, '--version'], text=True).strip()
    require(engine.startswith(source['engine'] + '.'), 'Driver audit Godot engine differs from the build')
    inventory = source_inventory(source_root)
    with apk.open('rb') as stream:
        apk_digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    provenance = json.loads((apk.parent / 'BUILD-PROVENANCE.json').read_text())
    flutter_revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    require(provenance.get('sha256') == apk_digest
            and provenance.get('flutter_source_commit') == flutter_revision
            and provenance.get('tracked_source_clean') is True,
            'Driver audit APK differs from the verified Flutter build')
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='lumo-driver-pack-') as work:
        directory = Path(work)
        pack = directory / 'lumo_game.pck'
        packaged = extract_verified_pack(apk, pack, source)
        require(provenance.get('godot') == packaged,
                'APK source receipt differs from the verified build provenance')
        expected = directory / 'expected-drivers.json'
        expected.write_text(json.dumps(inventory, indent=2) + '\n')
        result = directory / 'packaged-drivers.json'
        run_godot(godot, '--headless', '--path', str(directory), '--main-pack', str(pack),
                  '--script', str(ROOT / '.github/probes/lumo_kart_driver_assets_probe.gd'),
                  '--', str(expected), str(result),
                  log=out.with_suffix('.log'), timeout=600)
        observed = json.loads(result.read_text())
        expected_paths = {row['file'] for row in inventory['source_files']}
        scenes = observed.get('scenes', [])
        require(observed.get('status') == 'PASS'
                and observed.get('source_manifest_sha256') == inventory['source_manifest_sha256']
                and len(scenes) == 27
                and {row.get('file') for row in scenes} == expected_paths,
                'The actual APK pack did not load all 27 production driver scenes')
        report = {'status': 'PASS', 'apk_sha256': apk_digest,
                  'flutter_source_commit': flutter_revision, 'godot': packaged,
                  **inventory, 'packaged_scenes': scenes,
                  'scope': '27 source GLB hashes verified against the manifest also read from the actual PCK; '
                           'all 27 imported scenes, complete declared rigs/clips and albedo textures loaded '
                           'from the PCK extracted from this APK. No physical-device FPS claim.'}
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print('KART_DRIVER_APK_PASS: 9 drivers, 27 production variants, actual APK PCK')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', required=True, type=Path)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--godot', default=shutil.which('godot') or 'godot')
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    verify(args.apk.resolve(), args.source.resolve(), args.godot, args.out.resolve())
