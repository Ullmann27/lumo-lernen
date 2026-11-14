#!/usr/bin/env python3
"""Verify only the already downloaded, unchanged current ARM64 originals."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path('/dev/shm/lumo-198dd3-arm64-byte-review')
EXPECTED = Path('/dev/shm/lumo-198dd3-arm64-expected.json')
NAMES = {'Lumo-Lernen-Neu.apk', 'APK-SHA256.txt', 'APK-VERIFICATION.json',
         'BUILD-PROVENANCE.json', 'GODOT-SOURCE.json', 'APP-VERSION.txt'}


def digest(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def main():
    expected = json.loads(EXPECTED.read_text())
    artifact = expected['artifact']
    archive_path = ROOT / 'original-arm64-verified.zip'
    if archive_path.stat().st_size != artifact['size_in_bytes'] or digest(archive_path) != artifact['digest'].removeprefix('sha256:'):
        raise ValueError('Existing original archive differs from the bound actual artifact')
    extracted = ROOT / 'extracted'
    if {p.name for p in extracted.iterdir()} != NAMES:
        raise ValueError('Unexpected original ARM64 extraction roster')
    inventory = []
    with zipfile.ZipFile(archive_path) as archive:
        infos = archive.infolist()
        if len(infos) != 6 or {i.filename for i in infos} != NAMES:
            raise ValueError('Original ARM64 ZIP roster differs from the actual workflow')
        if archive.testzip() is not None:
            raise ValueError('Original ARM64 ZIP CRC failure')
        for info in infos:
            path = extracted / info.filename
            if path.is_symlink() or not path.is_file() or path.stat().st_size != info.file_size:
                raise ValueError('Original extracted path or byte count differs')
            h = hashlib.sha256()
            with archive.open(info) as original, path.open('rb') as current:
                while chunk := original.read(2 * 1024**2):
                    if current.read(len(chunk)) != chunk:
                        raise ValueError('Original extracted bytes differ from their ZIP entry')
                    h.update(chunk)
                if current.read(1):
                    raise ValueError('Trailing extracted bytes')
            inventory.append({'path':info.filename,'bytes':info.file_size,'sha256':h.hexdigest(),'crc32':f'{info.CRC:08x}'})
    verification = json.loads((extracted / 'APK-VERIFICATION.json').read_text())
    provenance = json.loads((extracted / 'BUILD-PROVENANCE.json').read_text())
    if set(expected['package_reports']) != {'arm64-v8a'} or verification != expected['package_reports']['arm64-v8a']:
        raise ValueError('Original ARM64 report differs from both actual completed CI report blocks')
    if verification['abis'] != ['arm64-v8a']:
        raise ValueError('Unexpected original ABI')
    if any(provenance.get(k) != v for k, v in verification.items()):
        raise ValueError('Original provenance differs from the original APK report')
    if provenance.get('flutter_source_commit') != expected['host'] or provenance.get('tracked_source_clean') is not True:
        raise ValueError('Actual original host provenance is not the exact clean current source')
    apk = extracted / 'Lumo-Lernen-Neu.apk'
    apk_sha = digest(apk)
    if apk.stat().st_size != verification['bytes'] or apk_sha != verification['sha256']:
        raise ValueError('Actual signed APK bytes differ from the original verified bytes')
    sums = (extracted / 'APK-SHA256.txt').read_text()
    if sums != apk_sha + '  dist/Lumo-Lernen-Neu.apk\n':
        raise ValueError('Original checksum differs from the literal current workflow output')
    version = (extracted / 'APP-VERSION.txt').read_text()
    if version != f"version: {verification['versionName']}+{verification['versionCode']}\n":
        raise ValueError('Original application version differs')
    source = json.loads((extracted / 'GODOT-SOURCE.json').read_text())
    with zipfile.ZipFile(apk) as package:
        if package.testzip() is not None:
            raise ValueError('Actual APK entry CRC failure')
        names = package.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate APK entries')
        abis = {name.split('/')[1] for name in names if name.startswith('lib/') and name.endswith('.so')}
        if abis != {'arm64-v8a'}:
            raise ValueError('Actual APK native ABI differs')
        embedded_bytes = package.read('assets/lumo_game_source.json')
        embedded = json.loads(embedded_bytes)
        if embedded != verification['godot'] or embedded['revision'] != expected['native']:
            raise ValueError('Actual embedded Godot source differs')
        if source != {key:embedded[key] for key in ('repository','revision','engine')}:
            raise ValueError('Original source pin file differs from the actual embedded source')
        info = package.getinfo('assets/lumo_game.pck')
        with package.open(info) as pack:
            pack_sha = hashlib.file_digest(pack, 'sha256').hexdigest()
        if info.file_size != embedded['bytes'] or pack_sha != embedded['pck_sha256']:
            raise ValueError('Actual embedded PCK bytes differ')
        with package.open(info) as pack:
            if pack.read(4) != b'GDPC':
                raise ValueError('Actual embedded PCK header differs')
    embedded_path = ROOT / 'actual-embedded-lumo_game_source.json'
    embedded_path.write_bytes(embedded_bytes)
    report = {'schema':1,'kind':'new_read_only_original_ARM64_byte_review',
              'host':expected['host'],'native':expected['native'],'run_id':expected['run_id'],
              'run_attempt':expected['run_attempt'],'producer_job_id':expected['producer_job_id'],
              'artifact_id':artifact['id'],'zip_bytes':archive_path.stat().st_size,
              'zip_sha256':artifact['digest'].removeprefix('sha256:'),'all_original_ZIP_CRCs_verified':True,
              'all_six_extracted_originals_byte_equal_to_ZIP':True,'inventory':inventory,
              'actual_ARM64_APK':{'path':str(apk),'bytes':apk.stat().st_size,'sha256':apk_sha,
                'all_APK_entry_CRCs_verified':True,'entry_count':len(names),'actual_abis':sorted(abis),
                'original_checksum_line':sums,'original_checksum_path':str(extracted/'APK-SHA256.txt'),
                'original_verification_path':str(extracted/'APK-VERIFICATION.json'),
                'original_provenance_path':str(extracted/'BUILD-PROVENANCE.json'),
                'actual_host_from_original_provenance':provenance['flutter_source_commit'],
                'tracked_source_clean':True,'actual_embedded_source':embedded,
                'embedded_source_copy_path':str(embedded_path),
                'signing_certificate_sha256_from_original_CI_verifier':verification['signingCertificateSha256']},
              'signature_scope':'Original completed CI ran apksigner on these exact matching signed APK bytes; no second local apksigner execution is claimed.',
              'reader_filename_correction':'Separate ARM64 upload contains APK-SHA256.txt with literal dist/Lumo-Lernen-Neu.apk from workflow step 34. No original was renamed or regenerated; this continuation uses the original ZIP already downloaded once.',
              'oversized_candidate_download_error':expected['oversized_candidate_download_error'],
              'local_full_candidate_ZIP_review':False,'local_x86_APK_review':False,
              'new_download_in_this_continuation':False,'product_tests_executed':False,
              'complete_candidate_acceptance':False}
    target = ROOT / 'byte-verification.json'
    target.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'report':str(target),'report_bytes':target.stat().st_size,'report_sha256':digest(target),
                      'actual_ARM64_APK':report['actual_ARM64_APK'],'scope':'ARM64-only'},indent=2))


if __name__ == '__main__':
    main()
