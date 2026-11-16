"""Retain the verified current runtime archive without a duplicate working-tree ZIP."""
from pathlib import Path
import datetime
import hashlib
import json
import shutil
import subprocess
import zipfile

ROOT = Path('/workspace/scratch/4fa97167812c/lumo-lernen')
SRC = Path('/dev/shm/lumo-2032-runtime-cases-originals')
REL = Path('docs/nextgen/evidence/ci-2032-runtime-cases-verified')
DEST = ROOT / REL
EXPECTED = '17ccdb2993b814c96a986fe6d36515713877c7e178a2a52f7f6db38c25a59eed'


def git(*args, data=None):
    return subprocess.check_output(['git', '-C', str(ROOT), *args], input=data)


def file_digest(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        while block := stream.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def main():
    assert git('rev-parse', 'HEAD').decode().strip() == '5a5779fefef6fd526765d6987a552ee62001025f'
    assert not git('diff', '--name-only') and not git('diff', '--cached', '--name-only')
    assert not DEST.exists()
    assert shutil.disk_usage(ROOT).free > 120_000_000
    verification = json.loads((SRC / 'artifact-verification.json').read_text())
    assert verification['artifactId'] == 14220263387 and verification['workflowRun'] == 43853317375
    assert verification['archiveBytes'] == 65735724 and verification['archiveSha256'] == EXPECTED
    assert len(verification['members']) == 1889 and verification['allMemberCRCsVerified'] is True
    archive = SRC / 'artifact-14220263387.zip'
    assert archive.stat().st_size == 65735724 and file_digest(archive) == EXPECTED
    by_path = {row['path']: row for row in verification['members']}
    for path in git('ls-tree', '-r', '--name-only', 'HEAD', '--', str(REL)).decode().splitlines():
        raise AssertionError('Retention path already tracked: ' + path)
    DEST.mkdir(parents=True)
    (DEST / 'artifact-verification.json').write_bytes((SRC / 'artifact-verification.json').read_bytes())

    chosen = ['download/verified-download.json', 'source/qa-source-binding.json',
              'android/runtime-cases/runtime-cases-result.json', 'android/runtime-cases/qa-source-binding.json']
    names = ['0149-numeric-before-wrong-answer.png', '0155-numeric-wrong-before-explicit-check.png',
             '0163-numeric-wrong-after-assessment.png', '0169-numeric-corrected-before-explicit-check.png',
             '0177-numeric-corrected-after-assessment.png', '0223-switch-joint-viewport-before-replay.png',
             '0249-switch-new-unanswered-rakete.png', '0253-switch-original-density-restored.png',
             '0342-runtime-banana-before-slower.png', '0389-runtime-banana-after-slower.png',
             '0460-pattern-two-sign-group.png', '0488-pattern-before-explicit-core-answer.png',
             '0492-pattern-after-explicit-core-assessment.png', '0150-numeric-wrong-submission.mp4',
             '0164-numeric-corrected-submission.mp4', '0221-switch-during-actual-active-syllable.mp4',
             '0350-runtime-banana-four-slower-segments.mp4',
             '0487-pattern-explicit-core-answer-after-ungraded-return.mp4']
    chosen += ['android/runtime-cases/' + name for name in names]
    for name in chosen:
        meta = by_path[name]
        source = SRC / 'original' / name
        assert source.stat().st_size == meta['bytes'] and file_digest(source) == meta['sha256']
        dest = DEST / 'original' / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, dest)
        assert file_digest(dest) == meta['sha256']

    text_rows = [row for row in verification['members'] if Path(row['path']).suffix.lower() not in ('.png', '.mp4')]
    text_archive = DEST / 'original-text-evidence.zip'
    with zipfile.ZipFile(text_archive, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as out:
        for meta in text_rows:
            p = SRC / 'original' / meta['path']
            assert p.stat().st_size == meta['bytes'] and file_digest(p) == meta['sha256']
            out.write(p, meta['path'])
    with zipfile.ZipFile(text_archive) as check:
        assert len(check.infolist()) == len(text_rows)
        for row in text_rows:
            value = check.read(row['path'])
            assert len(value) == row['bytes'] and hashlib.sha256(value).hexdigest() == row['sha256']

    # Scope sparse materialization to this root worktree and this new archive.
    sparse = Path(git('rev-parse', '--git-path', 'info/sparse-checkout').decode().strip())
    if not sparse.is_absolute():
        sparse = ROOT / sparse
    assert sparse.exists()
    pattern = '!/' + str(REL / 'archive-parts') + '/'
    before = sparse.read_text()
    assert pattern not in before.splitlines()
    sparse.write_text(before.rstrip('\n') + '\n' + pattern + '\n')
    parts = []
    aggregate = hashlib.sha256()
    retained = 0
    with archive.open('rb') as source:
        while block := source.read(8 * 1024 * 1024):
            name = f'archive-parts/artifact.zip.part{len(parts) + 1:03d}'
            path = str(REL / name)
            blob = git('hash-object', '-w', '--stdin', data=block).decode().strip()
            stored = git('cat-file', 'blob', blob)
            assert stored == block
            git('update-index', '--add', '--cacheinfo', '100644', blob, path)
            git('update-index', '--skip-worktree', '--', path)
            aggregate.update(stored)
            retained += len(stored)
            parts.append({'path': name, 'bytes': len(stored), 'sha256': hashlib.sha256(stored).hexdigest(), 'gitBlob': blob})
    assert retained == 65735724 and aggregate.hexdigest() == EXPECTED
    assert not git('diff', '--name-only')
    proof = {'schemaVersion': 1, 'createdAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
             'workflowRun': 43853317375, 'jobId': 133251156609, 'artifactId': 14220263387,
             'qaCommit': 'ce8458e88d16e7c3b97fafcf34c4d29b0c1d9fdc',
             'apkSource': '9b38360ca5f21919dce4a2b99e605ee39bbbf454',
             'nativeSource': '9d6ef1d704a0e54098a8f8f0818f36deae0e3789',
             'archiveBytes': retained, 'archiveSha256': EXPECTED, 'memberCount': len(verification['members']),
             'uncompressedBytes': sum(row['bytes'] for row in verification['members']),
             'allOriginalsRetainedInArchiveParts': True,
             'archiveFormat': 'Ordered byte-exact concatenation of listed Git blobs reconstructs original Actions ZIP',
             'archivePartsMaterializedInRootWorktree': False,
             'rootWorktreeSparseRuleAdded': pattern,
             'originalArchiveAndAllMembersRemainAt': str(SRC),
             'parts': parts,
             'selectedOriginals': [by_path[name] for name in chosen],
             'textArchive': {'path': text_archive.name, 'bytes': text_archive.stat().st_size,
                             'sha256': file_digest(text_archive), 'fileCount': len(text_rows),
                             'allMemberCrcAndShaRechecked': True,
                             'format': 'Derived ZIP; all original non-PNG/non-MP4 bytes preserved without normalization'}}
    (DEST / 'archive-retention.json').write_text(json.dumps(proof, indent=2) + '\n')
    print(json.dumps({'archiveBytes': retained, 'archiveParts': len(parts), 'all1889OriginalMembersRetained': True,
                      'selectedOriginals': len(chosen), 'textArchiveBytes': text_archive.stat().st_size,
                      'remainingOverlayBytes': shutil.disk_usage(ROOT).free}))


if __name__ == '__main__':
    main()
