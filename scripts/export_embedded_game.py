"""Export the pinned Godot source as application data, never a second APK."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import struct
import subprocess
import sys
import time

from package_notices import bundle_notices

ROOT = Path(__file__).resolve().parents[1]


def run(*args, cwd=None):
    return subprocess.run(args, cwd=cwd, check=True)


GODOT_FAULT = re.compile(
    rb"SCRIPT ERROR:|Parse Error:|Compile Error:|ERROR:[^\r\n]*p_size"
)


def _stop_godot(process):
    """Stop the managed importer/exporter and its children before returning."""
    if process.poll() is not None:
        return
    try:
        if os.name == 'posix':
            os.killpg(process.pid, signal.SIGTERM)
        else:
            process.terminate()
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        try:
            if os.name == 'posix':
                os.killpg(process.pid, signal.SIGKILL)
            else:
                process.kill()
        except ProcessLookupError:
            pass
        process.wait()


def run_godot(*args, log: Path, timeout: float = 600):
    """Keep a full engine log and reject reported faults, including exit zero."""
    if timeout <= 0:
        raise ValueError('Godot timeout must be positive')
    log.parent.mkdir(parents=True, exist_ok=True)
    offset = 0
    tail = b''
    fault = False
    timed_out = False

    def drain():
        nonlocal offset, tail, fault
        with log.open('rb') as reader:
            reader.seek(offset)
            chunk = reader.read()
        offset += len(chunk)
        if chunk:
            sys.stdout.write(chunk.decode('utf-8', errors='replace'))
            sys.stdout.flush()
        scanned = tail + chunk
        fault = fault or GODOT_FAULT.search(scanned) is not None
        # Keep the complete unfinished line, even across reads. A font-error
        # prefix and p_size may arrive in different chunks of the same line.
        boundary = max(scanned.rfind(b'\n'), scanned.rfind(b'\r'))
        tail = scanned[boundary + 1:]

    with log.open('wb') as output:
        process = subprocess.Popen(
            args, stdout=output, stderr=subprocess.STDOUT,
            start_new_session=(os.name == 'posix'),
        )
        deadline = time.monotonic() + timeout
        try:
            while True:
                drain()
                if fault:
                    _stop_godot(process)
                    break
                if process.poll() is not None:
                    break
                if time.monotonic() >= deadline:
                    timed_out = True
                    _stop_godot(process)
                    break
                time.sleep(0.05)
            code = process.wait()
        finally:
            _stop_godot(process)
    # Include output written between the last read and process termination.
    drain()
    if fault:
        raise RuntimeError(
            'Godot reported a script, parser, compiler or invalid font error; '
            f'complete log: {log}'
        )
    if timed_out:
        raise subprocess.TimeoutExpired(args, timeout)
    if code:
        raise subprocess.CalledProcessError(code, args)


def import_with_sigsegv_retry(binary: str, repo: Path, attempts: int = 3, *,
                              log_dir: Path | None = None,
                              timeout: float = 600) -> None:
    """Retry only the known transient Godot 4.6.3 editor SIGSEGV.

    Do not turn genuine import errors, other exits or persistent crashes into
    successes. Reuse the same exact pinned checkout and engine, completing the
    full editor import before attempting a signed Android package.
    """
    if attempts not in (1, 2, 3):
        raise ValueError('Godot import requires one to three attempts')
    log_dir = ROOT / 'build-proof' if log_dir is None else log_dir
    command = (
        binary, '--headless', '--single-threaded-scene', '--path',
        str(repo), '--editor', '--import', '--quit',
    )
    for attempt in range(1, attempts + 1):
        try:
            run_godot(
                *command, log=log_dir / f'GODOT-package-import-{attempt}.txt',
                timeout=timeout,
            )
            return
        except subprocess.CalledProcessError as error:
            if error.returncode != -signal.SIGSEGV or attempt == attempts:
                raise
            print(
                f'[LumoGodotImport] Godot 4.6.3 editor SIGSEGV on attempt '
                f'{attempt}/{attempts}; retrying the same pinned source',
                flush=True,
            )
            time.sleep(2 * attempt)


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
# These reviewed revisions embed the exact same byte-identical GLB and 3 JPEGs.
# Cleanup remains restricted to these release pins; all other files fail closed.
GROUNDED_GATE_ALLOWED_REVISIONS = frozenset((
    GROUNDED_GATE_REVISION,
    '6518a13fb8eb30c81c8a2115d14791cbe7ddd24a',
    'efa1f69b4128a047e6196ee85762447e412db266',
    '20652880eda687c67cfa72301dad5a173b1fe6c5',
    # 1985's six Kart commits only change scripts/tests/workflows, not the gate GLB.
    'ffd2955ca9222daf02e6b602b3f213fd9383204a',
    # 1991 adds ONLY one headless scene-switch regression and CI job hook;
    # Git ancestry confirms identical trusted Meshy gate GLB to 1985–1990.
    '63cecf09fa89dd504cc468ebd121b4ec71a0f36c',
    # 1993 cinematic menu branch is 12 commits ahead with no gate GLB edits;
    # still require the exact trusted GLB SHA256 and all three genuine JPEGs.
    '8342a2f10b2ecb8cf9cf1cb9566093fbc4d0b07c',
    # 1994 modifies only UI scripts and tests, never the hash-pinned Meshy GLB.
    '928fed3c7f0b39357e0f06463ce13c8d5677d6e1',
    # 1995 reviewed SOL menu and responsive owner; gate GLB remains SHA-locked.
    '700baf49828eda693ecce15b415847818b1b56d3',
    # 1997 changes only the landing layout script, one test and docs.
    '3a3142608f6b150ee251373ba81e6face2eed4b3',
    # 1999 changes only the game-hub scroll flag and its regression.
    '4d0fd40fdf188be6ca86057596c7b51f41701fa3',
    # Combined 2022 chassis + Adventure art; GLB hash checks remain mandatory.
    'd38967f6d39bc20188afe525b0af122d80634029',
    # 2027 learning integration: the existing gate GLB was independently read
    # from this exact Git tree and retains GROUNDED_GATE_GLB_SHA256 unchanged.
    '332307fafa2f68a1aa3667d81b7c90d3683c5c45',
    # Same independently verified gate bytes after bounded native QA/layout fixes.
    'ec702dad29def7ea3db6f62f2ead7b8ca6bca2bb',
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


# Godot 4.6.3 writes import metadata and one extracted PNG next to each
# production Meshy GLB. Historical pins retain their reviewed rules. A
# later pin must carry the exact reviewed manifest and produce textures
# byte-identical to the embedded PNGs. Only new importer outputs are cleaned.
PRODUCTION_MESHY_REVISION = '410327bfd5d1a66c54e3d75f772895d320daa5d6'
PRODUCTION_MESHY_ALLOWED_REVISIONS = frozenset((
    PRODUCTION_MESHY_REVISION,
    # Both production asset subtrees are unchanged from the reviewed 2077 pin.
    '21a76bcda69c20ea3a427a63098cb2fc736eb881',
    'c3f459eca88f659da1a9e4af1c990c804e715528',
    # 2081 World integration keeps the production asset tree byte-identical
    # to c3f459e; all 16 manifest GLB hashes and output checks still apply.
    'c814e35249e4038f903d1fca3e19bb4751040a43',
    # 2082 changes World/table scripts, tests, docs and CI; every asset blob
    # is unchanged from c814. Manifest hashes and exact cleanup checks remain.
    '62108c0355f860ab9a0a020ecb5f3f941f1032e9',
    # 2083: Git tree comparison against 2082 confirms identical production
    # Meshy/garage subtrees (54d73b2b / 11ea80a8), including all 16 GLBs
    # and the manifest. Exact manifest hashes and output checks still apply.
    'dedc588cd0862069fe22863f671877042aa7c53c',
    # 2085 preserves both production Git trees from the reviewed 2083 pin.
    # Existing byte, manifest, and temporary-output checks still apply.
    '0c36dbaa2e778dc982550989159bf70efbf1d47c',
    # 2084 preserves both production Git trees from the reviewed 2083 pin.
    # Existing byte, manifest, and temporary-output checks still apply.
    'c328fc8b94237cef7f05b613fceb0aa47e864f95',
))
PRODUCTION_MESHY_MANIFEST = 'assets/kart/production/meshy/manifest.json'
PRODUCTION_MESHY_MANIFEST_SHA256 = '763df5822780b995ceff8b87d927341374141fb3aa8b3a3d6dda4add49c25f31'
PRODUCTION_MESHY_VEHICLE_IDS = frozenset((
    'blitz', 'boru_rally', 'comet', 'gecko_velo', 'glider', 'iva_aurora',
    'koloss', 'nala_comet', 'noa_tide', 'phantom', 'stella', 'terra',
    'turbo', 'zuri_volt',
))
PRODUCTION_MESHY_GARAGE_IDS = frozenset((
    'meshy_tool_workbench', 'meshy_turntable',
))


def embedded_meshy_png_sha256(raw: bytes, gltf: dict, json_length: int, images: list) -> str:
    """Read the only embedded PNG buffer view in an already verified GLB."""
    binary_header = 20 + json_length
    binary_start = binary_header + 8
    if len(images) != 1 or binary_start > len(raw):
        raise RuntimeError('Refusing Meshy import cleanup: expected one embedded PNG')
    bin_length, bin_tag = struct.unpack_from('<2I', raw, binary_header)
    view = gltf['bufferViews'][images[0]['bufferView']]
    offset = view.get('byteOffset', 0)
    length = view['byteLength']
    if (bin_tag != 0x004e4942 or binary_start + bin_length != len(raw)
            or view['buffer'] != 0 or offset < 0 or length <= 0 or offset + length > bin_length):
        raise RuntimeError('Refusing Meshy import cleanup: invalid embedded PNG buffer')
    return hashlib.sha256(raw[binary_start + offset:binary_start + offset + length]).hexdigest()


def remove_generated_production_meshy_imports(repo: Path, before: set[str], source: dict):
    """Remove the known sidecars of byte-verified production Meshy assets."""
    historical_pin = source.get('revision') in PRODUCTION_MESHY_ALLOWED_REVISIONS
    manifest_path = repo / PRODUCTION_MESHY_MANIFEST
    if manifest_path.is_symlink() or not manifest_path.is_file():
        if not historical_pin:
            return
        raise RuntimeError('Refusing 2077 Meshy import cleanup: missing manifest')
    try:
        manifest_raw = manifest_path.read_bytes()
        if not historical_pin and hashlib.sha256(manifest_raw).hexdigest() != PRODUCTION_MESHY_MANIFEST_SHA256:
            return
        manifest = json.loads(manifest_raw)
    except (OSError, json.JSONDecodeError) as error:
        raise RuntimeError('Refusing 2077 Meshy import cleanup: invalid manifest') from error

    vehicles = manifest.get('vehicles')
    garage = manifest.get('garage')
    if (manifest.get('schema_version') != 1
            or not isinstance(vehicles, list) or not isinstance(garage, list)
            or len(vehicles) != 14 or len(garage) != 2):
        raise RuntimeError('Refusing 2077 Meshy import cleanup: manifest inventory mismatch')

    rows = vehicles + garage
    vehicle_ids = {row.get('id') for row in vehicles if isinstance(row, dict)}
    garage_ids = {row.get('id') for row in garage if isinstance(row, dict)}
    if vehicle_ids != PRODUCTION_MESHY_VEHICLE_IDS or garage_ids != PRODUCTION_MESHY_GARAGE_IDS:
        raise RuntimeError('Refusing 2077 Meshy import cleanup: manifest IDs mismatch')

    allowed_outputs = set()
    expected_paths = set()
    expected_textures = {}
    for row in rows:
        if not isinstance(row, dict):
            raise RuntimeError('Refusing 2077 Meshy import cleanup: malformed manifest row')
        identifier = row.get('id')
        relative = row.get('path')
        expected_relative = (
            f'assets/kart/production/meshy/{identifier}.glb'
            if identifier in PRODUCTION_MESHY_VEHICLE_IDS
            else f'assets/kart/production/garage/{identifier}.glb'
        )
        if relative != expected_relative or relative in expected_paths:
            raise RuntimeError('Refusing 2077 Meshy import cleanup: manifest path mismatch')
        expected_paths.add(relative)

        glb = repo / relative
        if glb.is_symlink() or not glb.is_file():
            raise RuntimeError('Refusing 2077 Meshy import cleanup: manifest GLB missing')
        raw = glb.read_bytes()
        expected_bytes = row.get('bytes')
        expected_sha = row.get('sha256')
        if (not isinstance(expected_bytes, int) or expected_bytes <= 0
                or not isinstance(expected_sha, str)
                or not re.fullmatch(r'[0-9a-f]{64}', expected_sha)
                or len(raw) != expected_bytes
                or hashlib.sha256(raw).hexdigest() != expected_sha):
            raise RuntimeError('Refusing 2077 Meshy import cleanup: manifest GLB mismatch')

        if len(raw) < 20 or raw[:4] != b'glTF':
            raise RuntimeError('Refusing 2077 Meshy import cleanup: malformed GLB')
        _, version, total, json_length, json_tag = struct.unpack_from('<4s4I', raw)
        if (version != 2 or total != len(raw) or json_tag != 0x4e4f534a
                or json_length <= 0 or 20 + json_length > len(raw)):
            raise RuntimeError('Refusing 2077 Meshy import cleanup: invalid glTF 2.0')
        try:
            gltf = json.loads(raw[20:20 + json_length])
        except json.JSONDecodeError as error:
            raise RuntimeError('Refusing 2077 Meshy import cleanup: invalid GLB manifest') from error
        embedded = [
            image for image in gltf.get('images', [])
            if isinstance(image, dict) and image.get('mimeType') == 'image/png'
            and 'bufferView' in image
        ]
        if not embedded:
            raise RuntimeError('Refusing 2077 Meshy import cleanup: embedded PNG missing')

        rel_path = Path(relative)
        texture_path = str(rel_path.with_name(rel_path.stem + '_0.png'))
        allowed_outputs.add(relative + '.import')
        allowed_outputs.add(texture_path)
        if not historical_pin:
            expected_textures[texture_path] = embedded_meshy_png_sha256(raw, gltf, json_length, embedded)

    untracked = git_paths(repo, 'ls-files', '--others', '--exclude-standard')
    generated = (untracked - before) & allowed_outputs
    if not generated:
        return

    # Validate the complete removal set before deleting any file.
    for relative in sorted(generated):
        path = repo / relative
        if path.is_symlink() or not path.is_file():
            raise RuntimeError('Refusing 2077 Meshy import cleanup: unsafe output ' + relative)
        size = path.stat().st_size
        if relative.endswith('.glb.import'):
            if not 20 <= size <= 1000000:
                raise RuntimeError('Refusing 2077 Meshy import cleanup: invalid import metadata size')
            try:
                metadata = path.read_text()
            except UnicodeDecodeError as error:
                raise RuntimeError('Refusing 2077 Meshy import cleanup: binary import metadata') from error
            source_relative = relative[:-len('.import')]
            if ('[remap]' not in metadata or 'importer="scene"' not in metadata
                    or f'source_file="res://{source_relative}"' not in metadata):
                raise RuntimeError('Refusing 2077 Meshy import cleanup: unexpected import metadata')
            if not historical_pin and 'type="PackedScene"' not in metadata:
                raise RuntimeError('Refusing Meshy import cleanup: expected scene remap type')
        elif relative.endswith('_0.png'):
            if not 16 <= size <= 100000000:
                raise RuntimeError('Refusing 2077 Meshy import cleanup: invalid PNG size')
            with path.open('rb') as handle:
                prefix = handle.read(8)
                tail_size = min(size, 11)
                handle.seek(-tail_size, 2)
                tail = handle.read(tail_size)
            # Embedded glTF bufferViews are 4-byte aligned. Godot 4.6.3 keeps
            # up to three alignment NUL bytes when it extracts these exact
            # verified textures next to the GLB.
            unpadded = tail.rstrip(b'\x00')
            padding = len(tail) - len(unpadded)
            if (prefix != b'\x89PNG\r\n\x1a\n' or padding > 3
                    or not unpadded.endswith(b'IEND\xaeB\x60\x82')):
                raise RuntimeError(
                    'Refusing 2077 Meshy import cleanup: invalid PNG output '
                    f'{relative} size={size} prefix={prefix.hex()} '
                    f'tail={tail.hex()} padding={padding}'
                )
            if not historical_pin:
                with path.open('rb') as handle:
                    actual_sha256 = hashlib.file_digest(handle, 'sha256').hexdigest()
                if actual_sha256 != expected_textures[relative]:
                    raise RuntimeError('Refusing Meshy import cleanup: extracted PNG differs from GLB')
        else:
            raise RuntimeError('Refusing 2077 Meshy import cleanup: unrecognised output')

    for relative in sorted(generated):
        (repo / relative).unlink()
        print('[LumoMeshyImport] removed verified temporary import output:', relative)



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
        # Godot 4.6.3 importer sometimes dispatches scene notifications from
        # worker groups and crashes (SIGSEGV) on busy CI runners. Force only
        # the headless importer/editor into main-thread scene dispatch; the
        # exported Android game's runtime threading remains unchanged.
        import_with_sigsegv_retry(binary, repo)
        assets = ROOT / 'android/app/src/main/assets'
        assets.mkdir(parents=True, exist_ok=True)
        pack = assets / 'lumo_game.pck'
        run_godot(binary, '--headless', '--single-threaded-scene', '--path',
                  str(repo), '--export-pack', 'Android', str(pack),
                  log=ROOT / 'build-proof/GODOT-package-export.txt')
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
        remove_generated_production_meshy_imports(repo, before, source)
    remaining = subprocess.check_output(['git', 'status', '--porcelain'], cwd=repo, text=True).strip()
    if remaining:
        raise RuntimeError('Godot import changed sources; refuse exported candidate:\n' + remaining)
    bundle_notices(ROOT, repo)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=ROOT / 'build/godot-source')
    parser.add_argument('--godot', default=shutil.which('godot') or 'godot')
    args = parser.parse_args()
    export(args.repo.resolve(), args.godot)

