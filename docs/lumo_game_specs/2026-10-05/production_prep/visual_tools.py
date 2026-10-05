#!/usr/bin/env python3
"""Read-only Lumo asset checks. No app, renderer or visual-acceptance claim.
Requires Python >= 3.10 and Pillow for image operations. No network access.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import struct
import zipfile
from pathlib import Path, PurePosixPath


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def contained(root: Path, relative: str) -> Path:
    p = PurePosixPath(relative)
    if not relative or p.is_absolute() or '\\' in relative or ':' in relative or '..' in p.parts:
        raise ValueError('Unsafe relative path: ' + relative)
    result = (root / p).resolve()
    if not result.is_relative_to(root.resolve()) or not result.is_file():
        raise ValueError('Missing file or path outside root: ' + relative)
    return result


def image_info(path: Path) -> dict:
    from PIL import Image
    with Image.open(path) as im:
        if im.width * im.height > 40_000_000:
            raise ValueError('Image exceeds the 40-megapixel inspection limit')
        im.load()
        alpha = im.convert('RGBA').getchannel('A').getextrema()
        return dict(width=im.width, height=im.height, format=im.format,
                    mode=im.mode, has_transparent_pixels=alpha[0] < 255,
                    bytes=path.stat().st_size, sha256=sha256(path))


def verify(root: Path, manifest: Path) -> dict:
    data = json.loads(manifest.read_text(encoding='utf-8'))
    rows = data.get('files', [])
    if not rows:
        raise ValueError('Empty manifest is not verification')
    seen, results = set(), []
    for row in rows:
        rel = row['path']
        if rel in seen:
            raise ValueError('Duplicate path: ' + rel)
        seen.add(rel)
        path = contained(root, rel)
        if not re.fullmatch(r'[a-f0-9]{64}', row['sha256']):
            raise ValueError('Invalid SHA256: ' + rel)
        actual = dict(bytes=path.stat().st_size, sha256=sha256(path))
        if path.suffix.lower() in ('.png', '.webp', '.jpg', '.jpeg'):
            actual.update(image_info(path))
        checks = {k: actual.get(k) == row[k] for k in actual if k in row}
        results.append(dict(path=rel, checks=checks, pass_all=all(checks.values())))
    return dict(status='PASS' if all(r['pass_all'] for r in results) else 'FAIL',
                checked_files=len(results), files=results, runtime='NOT_EXECUTED')


def comparison(reference: Path, runtime: Path, output: Path, source_sha: str,
               runtime_kind: str) -> dict:
    from PIL import Image, ImageDraw, ImageOps
    if not re.fullmatch(r'[a-fA-F0-9]{40}', source_sha):
        raise ValueError('A full 40-character source SHA is required')
    if runtime_kind not in ('android', 'desktop', 'widget_test'):
        raise ValueError('Explicit runtime kind required')
    ref_info, run_info = image_info(reference), image_info(runtime)
    # Never overwrite any reference or a previous evidence result.
    output.mkdir(parents=True, exist_ok=False)
    canvas = Image.new('RGB', (1600, 700), '#081426')
    draw = ImageDraw.Draw(canvas)
    labels = ('REFERENCE / NOT RUNTIME', 'DECLARED RUNTIME / ORIGIN NOT VERIFIED')
    for i, (path, label) in enumerate(zip((reference, runtime), labels)):
        with Image.open(path) as im:
            # Whole images preserved: no stretching, no hidden cropping.
            thumb = ImageOps.contain(im.convert('RGB'), (780, 600))
            canvas.paste(thumb, (i * 800 + (800-thumb.width)//2, 50+(600-thumb.height)//2))
        draw.text((i * 800+12, 16), label, fill='white')
    draw.text((12, 670), f'{runtime_kind} | source {source_sha} | VISUAL ACCEPTANCE: NOT ASSESSED', fill='white')
    canvas.save(output / 'comparison.png')
    report = dict(reference=ref_info, runtime=run_info, source_sha=source_sha,
                  runtime_kind=runtime_kind, provenance='USER_SUPPLIED_NOT_AUTHENTICATED',
                  same_input_bytes=ref_info['sha256']==run_info['sha256'],
                  resized_for_display_only=True, cropped=False,
                  verdict='NOT_ASSESSED', physical_device_performance='NOT_EXECUTED')
    (output / 'comparison.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    return report


def glb_inventory(path: Path) -> dict:
    """Container/JSON inventory only. NOT a full glTF or deformation validator."""
    size = path.stat().st_size
    if size < 20 or size > 80_000_000:
        raise ValueError('Unsupported GLB inspection size')
    data = path.read_bytes()
    magic, version, declared_size = struct.unpack_from('<4sII', data)
    if magic != b'glTF' or version != 2 or declared_size != len(data):
        raise ValueError('Invalid GLB header/version/length')
    pos, chunks = 12, []
    while pos < len(data):
        if pos+8 > len(data):
            raise ValueError('Truncated chunk header')
        length, kind = struct.unpack_from('<II', data, pos)
        pos += 8
        if length % 4 or pos+length > len(data):
            raise ValueError('Unaligned or truncated chunk')
        chunks.append((kind, data[pos:pos+length]))
        pos += length
    if not chunks or chunks[0][0] != 0x4E4F534A:
        raise ValueError('First chunk must be JSON')
    if sum(k == 0x4E4F534A for k, _ in chunks) != 1:
        raise ValueError('Duplicate JSON chunk')
    doc = json.loads(chunks[0][1].decode('utf-8'))
    if not isinstance(doc, dict):
        raise ValueError('GLB JSON must be an object')
    if doc.get('asset', {}).get('version') != '2.0':
        raise ValueError('Expected glTF asset version 2.0')
    return dict(sha256=sha256(path), bytes=size, nodes=len(doc.get('nodes', [])),
                meshes=len(doc.get('meshes', [])), skins=len(doc.get('skins', [])),
                skin_joint_counts=[len(s.get('joints', [])) for s in doc.get('skins', [])],
                animation_names=[a.get('name', f'unnamed_{i}') for i,a in enumerate(doc.get('animations', []))],
                materials=len(doc.get('materials', [])), images=len(doc.get('images', [])),
                container_scan='COMPLETE', full_gltf_validation='NOT_EXECUTED',
                rig_fidelity='NOT_ASSESSED', animation_quality='NOT_ASSESSED',
                runtime_import='NOT_EXECUTED')


def pack(root: Path, paths: list[str], output: Path, max_bytes: int = 28_000_000) -> list[dict]:
    """Independent ZIPs, STORE, exact overhead budget, no spanned archives."""
    if not paths or len(set(paths)) != len(paths):
        raise ValueError('Empty or duplicate file list')
    if not 100 <= max_bytes <= 30_000_000:
        raise ValueError('Package bound must be 100..30000000 bytes')
    groups, current, budget = [], [], 22
    for rel in paths:
        path = contained(root, rel)
        # STORE: one local header + one central header + UTF-8 filename twice.
        cost = path.stat().st_size + 76 + 2 * len(rel.encode('utf-8'))
        if cost+22 > max_bytes:
            raise ValueError('Single file exceeds package bound: ' + rel)
        if budget+cost > max_bytes:
            groups.append(current)
            current, budget = [], 22
        current.append((rel, path, sha256(path)))
        budget += cost
    groups.append(current)
    # Validate all inputs before creating any output; no overwrite.
    output.mkdir(parents=True, exist_ok=False)
    result = []
    for index, group in enumerate(groups, 1):
        target = output / f'Lumo_Referenzen_{index:02d}.zip'
        with zipfile.ZipFile(target, 'x', compression=zipfile.ZIP_STORED) as archive:
            for rel, path, expected in group:
                payload = path.read_bytes()
                if hashlib.sha256(payload).hexdigest() != expected:
                    raise ValueError('Input changed while packing: ' + rel)
                info = zipfile.ZipInfo(rel, date_time=(2026, 10, 5, 0, 0, 0))
                info.compress_type = zipfile.ZIP_STORED
                info.external_attr = 0o100644 << 16
                archive.writestr(info, payload)
        if target.stat().st_size > max_bytes:
            raise ValueError('Package bound violated; do not distribute ' + target.name)
        with zipfile.ZipFile(target) as archive:
            if archive.testzip() is not None:
                raise ValueError('ZIP integrity failed')
            for rel, _, expected in group:
                if hashlib.sha256(archive.read(rel)).hexdigest() != expected:
                    raise ValueError('ZIP member changed: ' + rel)
        result.append(dict(name=target.name, bytes=target.stat().st_size,
                           sha256=sha256(target), members=len(group), bound=max_bytes))
    (output / 'PACKAGES.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    return result


def main() -> None:
    cli = argparse.ArgumentParser(description=__doc__)
    cmds = cli.add_subparsers(dest='cmd', required=True)
    v = cmds.add_parser('verify'); v.add_argument('root', type=Path); v.add_argument('manifest', type=Path)
    c = cmds.add_parser('compare'); c.add_argument('reference', type=Path); c.add_argument('runtime', type=Path)
    c.add_argument('output', type=Path); c.add_argument('--source-sha', required=True)
    c.add_argument('--runtime-kind', required=True, choices=['android','desktop','widget_test'])
    g = cmds.add_parser('glb'); g.add_argument('path', type=Path)
    p = cmds.add_parser('pack'); p.add_argument('root', type=Path); p.add_argument('manifest', type=Path)
    p.add_argument('output', type=Path); p.add_argument('--max-bytes', type=int, default=28_000_000)
    args = cli.parse_args()
    try:
        if args.cmd == 'verify': result = verify(args.root, args.manifest)
        elif args.cmd == 'compare': result = comparison(args.reference,args.runtime,args.output,args.source_sha,args.runtime_kind)
        elif args.cmd == 'glb': result = glb_inventory(args.path)
        else:
            check = verify(args.root,args.manifest)
            if check['status'] != 'PASS': raise ValueError('Manifest verification failed; not packing')
            names = [r['path'] for r in json.loads(args.manifest.read_text(encoding='utf-8'))['files']]
            result = pack(args.root,names,args.output,args.max_bytes)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        if isinstance(result,dict) and result.get('status') == 'FAIL': raise SystemExit(1)
    except (OSError,ValueError,KeyError,TypeError,struct.error) as error:
        cli.exit(2, f'ERROR: {error}\n')


if __name__ == '__main__':
    main()
