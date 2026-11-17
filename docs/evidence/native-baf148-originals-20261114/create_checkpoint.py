#!/usr/bin/env python3
"""Package already frozen evidence; no network, engine, reader or test invocation."""
from __future__ import annotations

import datetime as dt
import gzip
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
import tarfile
import zlib

BASE = Path('/workspace/scratch/b3485b7bb989')
SOURCE = BASE / 'native-discovery-baf148b-ci-evidence-20261114'
ROOT_REVIEW = BASE / 'root-native-baf148-visual-review-20261114/root-visual-review-15.json'
OUTPUT = Path(__file__).resolve().parent
ZIP_RELATIVE = 'artifacts/14116698243/native-baf148b-14116698243.zip'
ORIGINAL_PREFIX = 'verification/originals/'
EXPECTED = {
    'manifest.json': '88ed1ce2b606f0b48fc95fcfdd7ad04f13b33747e1c641f084df225d48a1b79f',
    'SHA256SUMS': '1845e531edcba6a9b5379d3db0136de03954d5bfddab3013a18d280fa45b5ced',
    'handoff.json': '5571d503914087ff034cb6dc6c5d99c196d455b1949115bfd5698d5ad2537d17',
}
EXPECTED_REVIEW_SHA = '53786944e762a151e21ae17dee1a3921e95893e8367ef10d502f16a2323e7b4e'
START = dt.datetime.now(dt.timezone.utc).isoformat()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(path):
    require(path.is_file() and not path.is_symlink(), f'Not a regular original: {path}')
    digest = hashlib.sha256()
    count = 0
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
            count += len(block)
    return {'bytes': count, 'sha256': digest.hexdigest()}


def write_json(name, value):
    path = OUTPUT / name
    require(not path.exists(), f'Output already exists: {name}')
    raw = (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
    path.write_bytes(raw)
    require(path.read_bytes() == raw, f'Output readback differs: {name}')


def safe_relative(value):
    p = PurePosixPath(value)
    require(value and not p.is_absolute() and '..' not in p.parts and '\\' not in value,
            'Unsafe original relative path')
    require(p.as_posix() == value, 'Noncanonical original path')
    return value


for relative, digest in EXPECTED.items():
    require(identity(SOURCE / relative)['sha256'] == digest, f'Frozen identity mismatch: {relative}')
require(identity(ROOT_REVIEW)['sha256'] == EXPECTED_REVIEW_SHA, 'Root review identity mismatch')
manifest = json.loads((SOURCE / 'manifest.json').read_bytes())
catalog = json.loads((SOURCE / 'root-review-candidates-15.json').read_bytes())
root_review = json.loads(ROOT_REVIEW.read_bytes())
archive_record = json.loads((SOURCE / 'verification/archive-verification.json').read_bytes())
handoff = json.loads((SOURCE / 'handoff.json').read_bytes())
binding = {key: manifest[key] for key in
           ('repository', 'native_source', 'native_tree', 'run_id', 'attempt', 'job_id', 'artifact_id')}
require(binding == {
    'repository': 'Ullmann27/lumo-godot',
    'native_source': 'baf148b03a7a32c6ad9f737d731f900eb9113ea1',
    'native_tree': '0c18a0ca5200ade267cfedb4c12d5c4b0a761a00',
    'run_id': 43600806315, 'attempt': 1, 'job_id': 132464933411, 'artifact_id': 14116698243,
}, 'Unexpected original source binding')

original_files = {}
for row in manifest['files']:
    relative = safe_relative(row['path'])
    require(relative not in original_files, 'Duplicate source manifest path')
    original_files[relative] = {'bytes': row['bytes'], 'sha256': row['sha256']}
for relative in ('manifest.json', 'SHA256SUMS'):
    require(relative not in original_files, 'Unexpected self-referential source manifest')
    original_files[relative] = identity(SOURCE / relative)
require(len(original_files) == 1594, 'Unexpected full original pack file count')


def source_snapshot():
    paths = sorted(p.relative_to(SOURCE).as_posix() for p in SOURCE.rglob('*') if p.is_file())
    require(paths == sorted(original_files), 'Original pack membership changed')
    summary = hashlib.sha256()
    total = 0
    for relative in paths:
        p = SOURCE / relative
        actual = identity(p)
        require(actual == original_files[relative], f'Original byte identity differs: {relative}')
        metadata = p.stat()
        snapshot_row = [relative, actual['bytes'], actual['sha256'], stat.S_IMODE(metadata.st_mode), metadata.st_mtime_ns]
        summary.update((json.dumps(snapshot_row, separators=(',', ':')) + '\n').encode())
        total += actual['bytes']
    return {'regular_files': len(paths), 'total_bytes': total,
            'all_files_match_frozen_manifest': True, 'inventory_with_modes_and_mtime_sha256': summary.hexdigest(),
            'frozen_manifest': {'path': str(SOURCE / 'manifest.json'), **original_files['manifest.json']},
            'frozen_checksums': {'path': str(SOURCE / 'SHA256SUMS'), **original_files['SHA256SUMS']},
            'root_review': {'path': str(ROOT_REVIEW), **identity(ROOT_REVIEW)}}


before = source_snapshot()
zip_members = {safe_relative(row['path']): row for row in archive_record['regular_files']}
require(len(zip_members) == 1516, 'Unexpected original ZIP member count')
require({p[len(ORIGINAL_PREFIX):] for p in original_files if p.startswith(ORIGINAL_PREFIX)} == set(zip_members),
        'Extraction inventory differs from full original ZIP inventory')
for relative, row in zip_members.items():
    require(original_files[ORIGINAL_PREFIX + relative] == {'bytes': row['bytes'], 'sha256': row['sha256']},
            'Original member binding differs')

for key, value in {'native_source': binding['native_source'], 'native_tree': binding['native_tree'],
                   'run': binding['run_id'], 'job': binding['job_id'], 'attempt': binding['attempt'],
                   'artifact_id': binding['artifact_id'],
                   'archive_sha256': original_files[ZIP_RELATIVE]['sha256']}.items():
    require(catalog[key] == value and root_review[key] == value, f'Root/catalog binding mismatch: {key}')
selected_images = {row['original_entry']: row for row in catalog['images']}
reviewed_images = {row['original_entry']: row for row in root_review['images']}
require(len(catalog['images']) == len(selected_images) == len(reviewed_images) == root_review['images_reviewed'] == 15,
        'Root image selection is not exactly fifteen unique originals')
require(set(selected_images) == set(reviewed_images), 'Root/catalog image sets differ')
decoded = {row['path']: row for row in archive_record['decoded_pngs']}
for relative, row in selected_images.items():
    require(relative.endswith('.png'), 'Unexpected non-PNG in visual selection')
    require(all(reviewed_images[relative][key] == value for key, value in row.items()), 'Root/catalog image fields differ')
    require(row['original_path'] == str(SOURCE / ORIGINAL_PREFIX / relative), 'Original PNG path mismatch')
    for field in ('bytes', 'sha256', 'crc32', 'width', 'height', 'decoded_rgba_sha256'):
        require(row[field] == decoded[relative][field], f'PNG inventory binding mismatch: {relative}/{field}')


def member_record(relative, archive_path):
    record = {'archive_path': safe_relative(archive_path), 'original_pack_path': relative,
              'original_path': str(SOURCE / relative), **original_files[relative],
              'mode': oct(stat.S_IMODE((SOURCE / relative).stat().st_mode))}
    if relative.startswith(ORIGINAL_PREFIX):
        entry = relative[len(ORIGINAL_PREFIX):]
        record.update({'original_zip_entry': entry, 'crc32': zip_members[entry]['crc32']})
    return record


documentary = []
excluded = []
for relative in sorted(original_files):
    reason = None
    if relative == ZIP_RELATIVE:
        reason = 'The complete original ZIP is retained separately without another payload copy.'
    elif relative.startswith(ORIGINAL_PREFIX):
        entry = relative[len(ORIGINAL_PREFIX):]
        if entry.endswith('.png'):
            reason = 'Original PNG retained separately; only the fifteen selected images are copied into the visual archive.'
        elif '/mesa_shader_cache/' in '/' + entry or '/shader_cache/' in '/' + entry:
            reason = 'Original Mesa/Godot shader-cache payload retained separately; full member CRC/SHA inventory is included.'
    record = member_record(relative, 'native-evidence/' + relative)
    if reason:
        record.pop('archive_path')
        record['exclusion_reason'] = reason
        record['included_in_visual_archive'] = relative.startswith(ORIGINAL_PREFIX) and relative[len(ORIGINAL_PREFIX):] in selected_images
        excluded.append(record)
    else:
        documentary.append(record)
require(len(documentary) == 203 and len(excluded) == 1391, 'Unexpected documentary inclusion/exclusion count')
require(sum(row['original_pack_path'].startswith(ORIGINAL_PREFIX) for row in documentary) == 126,
        'Original technical-file selection changed')
require(not any(row['archive_path'].endswith(('.png', '.zip', '.cache')) for row in documentary),
        'Large payload unexpectedly included in documentary archive')

visual = [member_record(ORIGINAL_PREFIX + relative, 'original-pngs/' + relative) for relative in sorted(selected_images)]
visual.append(member_record('root-review-candidates-15.json', 'catalog/root-review-candidates-15.json'))
visual.append({'archive_path': 'review/root-visual-review-15.json', 'original_path': str(ROOT_REVIEW),
               **identity(ROOT_REVIEW), 'mode': oct(stat.S_IMODE(ROOT_REVIEW.stat().st_mode))})
visual.sort(key=lambda row: row['archive_path'])
require(len(visual) == 17 and sum(row['archive_path'].endswith('.png') for row in visual) == 15,
        'Unexpected visual archive member set')

# No signed transfer addresses are copied into the new publishable metadata.
signed_keys = re.compile(r'(?:[?&](?:sig|signature|token|access_token|x-amz-[^=&#]*|x-goog-[^=&#]*)=)', re.I)
url_pattern = re.compile(rb'https?://[^\s<>"\'\\]+')
for row in documentary + visual:
    if row['archive_path'].endswith(('.png', '.bin')):
        continue
    for raw_url in url_pattern.findall(Path(row['original_path']).read_bytes()):
        require(not signed_keys.search(raw_url.decode('ascii', 'ignore')),
                'Signed/query-token transport URL in a selected original; retain privately instead')

write_json('documentary-inclusion.json', {'schema': 1, **binding, 'members': documentary,
           'member_count': len(documentary), 'uncompressed_original_bytes': sum(row['bytes'] for row in documentary),
           'selection': 'Every original pack metadata file plus all 126 non-PNG/non-shader-cache original ZIP members. '
                        'All 63 artifact logs, all 22 original JSON reports/inventories, all source stamps/index bytes '
                        'and five original Python readers are included without rewriting.'})
write_json('documentary-exclusion.json', {'schema': 1, **binding, 'original_pack_root': str(SOURCE),
           'original_zip': {'path': str(SOURCE / ZIP_RELATIVE), **original_files[ZIP_RELATIVE]},
           'exclusions': excluded, 'excluded_file_count': len(excluded),
           'excluded_bytes': sum(row['bytes'] for row in excluded),
           'retention': 'The complete original ZIP and all 1,516 extracted originals remain in place unchanged. '
                       'An exclusion here is an omission from the documentary transport archive, never a deletion.'})
write_json('visual-inclusion.json', {'schema': 1, **binding, 'members': visual, 'member_count': len(visual),
           'png_count': 15, 'png_bytes': sum(row['bytes'] for row in visual if row['archive_path'].endswith('.png')),
           'uncompressed_original_bytes': sum(row['bytes'] for row in visual),
           'review_origin': 'Exactly the original Root review; no new visual examination by this archive builder.',
           'catalog_semantics': 'The unchanged selection catalog predates the Root review and therefore says it makes '
                                'no visual-review claim. The separately included unchanged Root review supplies the actual observations.',
           'excluded_pngs': [{**row, 'original_path': str(SOURCE / ORIGINAL_PREFIX / relative)}
                             for relative, row in sorted(decoded.items()) if relative not in selected_images],
           'other_omissions': 'The remaining 45 PNGs and all non-image artifact files are not members of this visual archive. '
                              'Their full original inventory and technical reports remain in the documentary archive and source pack.'})


def create_archive(name, rows):
    path = OUTPUT / name
    require(not path.exists(), 'Archive already exists')
    with path.open('xb') as raw:
        with gzip.GzipFile(fileobj=raw, mode='wb', filename='', mtime=0, compresslevel=9) as compressed:
            with tarfile.open(fileobj=compressed, mode='w', format=tarfile.PAX_FORMAT) as tar:
                for row in sorted(rows, key=lambda value: value['archive_path']):
                    info = tarfile.TarInfo(row['archive_path'])
                    info.size = row['bytes']
                    info.mode = int(row['mode'], 8)
                    info.uid = info.gid = info.mtime = 0
                    info.uname = info.gname = ''
                    with Path(row['original_path']).open('rb') as original:
                        tar.addfile(info, original)
    expected = {row['archive_path']: row for row in rows}
    seen = set()
    verified = []
    with tarfile.open(path, mode='r:gz') as tar:
        for member in tar:
            require(member.isfile() and member.name in expected and member.name not in seen,
                    'Unexpected archive member or type')
            seen.add(member.name)
            row = expected[member.name]
            require(member.size == row['bytes'] and member.mode == int(row['mode'], 8), 'Archive size/mode mismatch')
            digest, crc, count = hashlib.sha256(), 0, 0
            with tar.extractfile(member) as recovered, Path(row['original_path']).open('rb') as original:
                while True:
                    a, b = recovered.read(1024 * 1024), original.read(1024 * 1024)
                    require(a == b, f'Full byte roundtrip mismatch: {member.name}')
                    if not a:
                        break
                    digest.update(a)
                    crc = zlib.crc32(a, crc)
                    count += len(a)
            require(count == row['bytes'] and digest.hexdigest() == row['sha256'], 'Roundtrip hash mismatch')
            if 'crc32' in row:
                require(f'{crc & 0xffffffff:08x}' == row['crc32'], 'Original ZIP member CRC mismatch')
            verified.append({'archive_path': member.name, 'bytes': count, 'sha256': digest.hexdigest(),
                             'fully_read_and_byte_equal_to_original': True})
        # Read through the gzip footer too, including its CRC/length verification.
        while tar.fileobj.read(1024 * 1024):
            pass
    require(seen == set(expected), 'Archive is missing original members')
    return {'path': name, **identity(path), 'member_count': len(verified),
            'uncompressed_original_bytes': sum(row['bytes'] for row in rows),
            'all_members_fully_byte_compared': True, 'gzip_stream_read_to_eof': True, 'members': verified}


documentary_archive = create_archive('native-baf148b-documentary-originals.tar.gz', documentary)
visual_archive = create_archive('native-baf148b-root-reviewed-15.tar.gz', visual)
after = source_snapshot()
require(before == after, 'Original pack or Root review changed during packaging')
write_json('source-retention-verification.json', {'schema': 1, **binding, 'before': before, 'after': after,
           'all_original_bytes_modes_and_mtimes_unchanged': True, 'retained_original_zip': str(SOURCE / ZIP_RELATIVE),
           'retained_extracted_originals': str(SOURCE / 'verification/originals'), 'extracted_count': 1516,
           'no_source_pack_file_created_deleted_or_edited': True, 'no_root_review_edit': True})
write_json('roundtrip-verification.json', {'schema': 1, **binding, 'archives': [documentary_archive, visual_archive],
           'method': 'Every archive member was fully decompressed and directly compared byte-for-byte with its unchanged original. '
                     'Sizes, SHA256, available original ZIP CRC32 values, file modes, exact member sets, and gzip EOF were checked.',
           'new_engine_runs': 0, 'new_tests': 0, 'new_reader_replays': 0, 'new_image_decodes': 0,
           'new_remote_actions': 0, 'new_artifact_exports': 0, 'image_reencoding': False})

readme = f'''# Native baf: compact documentary checkpoint

This checkpoint preserves already frozen, actual Native CI evidence for `{binding['native_source']}`,
tree `{binding['native_tree']}`, run **{binding['run_id']}**, attempt **1**, job **{binding['job_id']}**.
It does not change a Native or Host pin and performs no publication.

## Two separate archives

| Archive | Exact contents | Compressed bytes |
|---|---|---:|
| `{documentary_archive['path']}` | 203 original files: complete job log, every saved API original, source binding, complete CRC/SHA and image catalogs, frozen readers, replay reports, plus all 126 original non-image/non-cache artifact files | {documentary_archive['bytes']} |
| `{visual_archive['path']}` | Exactly 15 original PNGs actually viewed by Root, the unchanged original selection catalog, and the unchanged Root review: 17 members | {visual_archive['bytes']} |

Every member was fully read back and compared directly with its original bytes. No image was
decoded again, transformed, recompressed as an image, or substituted. Gzip is a lossless transport
wrapper; tar headers use a fixed time and numeric owner, preserving each member's bytes and mode.
The complete member results are in `roundtrip-verification.json`.

## Original retention and exclusions

The complete original ZIP remains at:

`{SOURCE / ZIP_RELATIVE}`

It has **66,871,509 bytes**, SHA256 `{original_files[ZIP_RELATIVE]['sha256']}`.
All **1,516** extracted originals also remain unchanged under `{SOURCE / 'verification/originals'}`.
No original source-pack file was created, removed, rewritten, or renamed. Before/after verification
binds all **1,594** source-pack files, their bytes, modes and modification times, plus Root's review.

The documentary archive excludes only the complete ZIP, 60 PNG payloads, and 1,330 original
Mesa/Godot shader-cache files. All excluded member identities and original locations are listed
in `documentary-exclusion.json`. The 15 selected PNGs are copied only into the separate visual
archive; the other 45 remain in the original pack. All original technical logs, JSON reports,
source inventories, raw index/tree snapshots, TSV results and archived reader sources are included.
No full extraction tree or staging copy was created for this transport checkpoint.

Inside the documentary archive, `native-evidence/manifest.json` and `native-evidence/SHA256SUMS`
are the **unchanged original full-pack inventories**. They deliberately still enumerate separately
retained payloads. They are not a claim that the compact archive contains the entire original pack.
Use this checkpoint's inclusion files to identify compact archive members. A full raster replay
still needs the separately retained original payloads; this archive operation did not rerun it.

## Preserved findings and limits

The previous frozen technical verification records actual SUCCESS for 47 Python methods,
Return21/Wisp14/Treasure92/Learning5347, Dream5/7/2, Discovery10/38/2,
Village339/42/46 with two PNGs, and Mobile **rendered428** with four safe-area and nine minimap PNGs.
It records 60 fully decoded original PNGs and all 1,516 original ZIP members verified by CRC/SHA.
The earlier local Mobile380 headless result remains a separate historical result.

The unchanged Root review covers **exactly 15** images: nine minimap, four mobile safe-area and
two Village images. Its concrete observations include clipping, ellipses and scroll limitations.
Its conclusion and limitations remain verbatim in the separate review member. The unchanged
catalog predates that review and correctly makes no visual-review assertion itself.
No new visual assessment is asserted by this packaging step. This is not an Android, physical
device, FPS, complete52/17, Host build, APK, release or publication acceptance.

The original Actions artifact is `{handoff['artifact_id']}` in `Ullmann27/lumo-godot`, with recorded
expiry 2026-12-14T14:01:59Z. Both full local retention and that external expiry are explicit;
this checkpoint performs no new remote fetch. No signed transport URL is published in these
selected originals. All selected source bytes and the review were unchanged after packaging.
'''
(OUTPUT / 'README.md').write_text(readme, encoding='utf-8')
require((OUTPUT / 'README.md').read_bytes() == readme.encode('utf-8'), 'README readback differs')
write_json('handoff.json', {'schema': 1, 'state': 'FROZEN', **binding, 'started_utc': START,
           'finished_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
           'archives': [{key: value for key, value in row.items() if key != 'members'}
                        for row in (documentary_archive, visual_archive)],
           'source_pack': str(SOURCE), 'source_pack_manifest': original_files['manifest.json'],
           'root_review': {'path': str(ROOT_REVIEW), **identity(ROOT_REVIEW)},
           'full_original_retention': {'zip_path': str(SOURCE / ZIP_RELATIVE), **original_files[ZIP_RELATIVE],
                                       'extracted_path': str(SOURCE / 'verification/originals'), 'extracted_members': 1516},
           'inclusion_indexes': ['documentary-inclusion.json', 'visual-inclusion.json'],
           'exclusion_index': 'documentary-exclusion.json', 'roundtrip_report': 'roundtrip-verification.json',
           'source_retention_report': 'source-retention-verification.json',
           'scope': 'Documentary transport and original-byte preservation only. Root observations remain limited to the actual 15 images. '
                    'No new test, engine, reader replay, image decode, source/ref/pin change or remote mutation.'})
final_files = [{'path': p.relative_to(OUTPUT).as_posix(), **identity(p)}
               for p in sorted(OUTPUT.rglob('*')) if p.is_file()]
write_json('manifest.json', {'schema': 1, 'state': 'FROZEN', **binding, 'files': final_files,
           'self_hash_location': 'SHA256SUMS', 'scope': 'Two compact transport archives and their complete byte-roundtrip records.'})
checksum_paths = sorted(p for p in OUTPUT.rglob('*') if p.is_file())
checksum_text = ''.join(f"{identity(p)['sha256']}  {p.relative_to(OUTPUT).as_posix()}\n" for p in checksum_paths)
(OUTPUT / 'SHA256SUMS').write_text(checksum_text, encoding='utf-8')
require((OUTPUT / 'SHA256SUMS').read_bytes() == checksum_text.encode('utf-8'), 'Final checksum readback differs')
print(json.dumps({'state': 'FROZEN', 'directory': str(OUTPUT),
                  'archives': [{key: value for key, value in row.items() if key != 'members'}
                               for row in (documentary_archive, visual_archive)],
                  'manifest': identity(OUTPUT / 'manifest.json'),
                  'checksums': identity(OUTPUT / 'SHA256SUMS'),
                  'handoff': identity(OUTPUT / 'handoff.json'),
                  'original_retention_unchanged': before == after}, indent=2))
