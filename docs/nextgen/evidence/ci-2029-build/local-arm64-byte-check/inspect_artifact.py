from pathlib import Path
import hashlib
import io
import json
import sys
import urllib.request
import zipfile

spec = json.loads(Path(sys.argv[1]).read_text())
destination = Path(spec['destination'])
assert not destination.exists()
buffer = io.BytesIO()
digest = hashlib.sha256()
received = 0
request = urllib.request.Request(spec['download_url'], headers={'User-Agent': 'Lumo-2029-artifact-verification/1'})
with urllib.request.urlopen(request, timeout=60) as response:
    assert response.status == 200
    while chunk := response.read(4 * 1024 * 1024):
        received += len(chunk)
        assert received <= spec['archive_bytes']
        digest.update(chunk)
        buffer.write(chunk)
assert received == spec['archive_bytes'] and digest.hexdigest() == spec['archive_sha256']
buffer.seek(0)
with zipfile.ZipFile(buffer) as archive:
    names = archive.namelist()
    expected = {'Lumo-Lernen-Neu.apk', 'BUILD-PROVENANCE.json', 'APK-VERIFICATION.json', 'SHA256SUMS.txt'}
    assert len(names) == 4 and set(names) == expected
    metadata = {name: archive.read(name) for name in names if name != 'Lumo-Lernen-Neu.apk'}
    provenance = json.loads(metadata['BUILD-PROVENANCE.json'])
    verification = json.loads(metadata['APK-VERIFICATION.json'])
    apk_digest = hashlib.sha256()
    apk_bytes = 0
    with archive.open('Lumo-Lernen-Neu.apk') as apk:
        while chunk := apk.read(4 * 1024 * 1024):
            apk_bytes += len(chunk)
            apk_digest.update(chunk)
    assert apk_bytes == spec['apk_bytes'] and apk_digest.hexdigest() == spec['apk_sha256']
    assert provenance['flutter_source_commit'] == spec['source'] and provenance['tracked_source_clean'] is True
    for proof in (provenance, verification):
        assert proof['bytes'] == apk_bytes and proof['sha256'] == apk_digest.hexdigest()
        assert proof['package'] == 'dev.ullmann.lumo.lumo_lernen.coachpreview'
        assert proof['versionCode'] == 2029 and proof['versionName'] == '0.13.17'
        assert proof['signingCertificateSha256'] == 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
        assert proof['abis'] == ['arm64-v8a'] and proof['elf16KiBAligned'] is True
        assert proof['godot']['revision'] == '678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef'
        assert proof['godot']['pck_sha256'] == '9aeb88d1dc52f612ea591c04d7651ccc3eef8b807b33b8b78c2f82b4e4eea303'
    assert apk_digest.hexdigest() in metadata['SHA256SUMS.txt'].decode()
destination.mkdir(parents=True)
for name, content in metadata.items():
    destination.joinpath(name).write_bytes(content)
report = {key: value for key, value in spec.items() if key != 'download_url'}
report.update({'status': 'PASS', 'allArchiveMembersCRCsVerified': True, 'completeArchiveSha256Verified': True,
               'completeApkSha256Verified': True, 'metadataMatchedActualApkBytes': True,
               'apkKeptOnDisk': False, 'apkArchiveKeptOnDisk': False,
               'scope': 'Complete local artifact/APK byte verification and metadata binding. Signature and ELF checks are the unchanged CI verifier results; apksigner was not rerun locally. No Android device or public download claim.'})
destination.joinpath('artifact-byte-verification.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({key: report[key] for key in ('status', 'artifact_id', 'archive_bytes', 'archive_sha256', 'apk_bytes', 'apk_sha256')}))
buffer.close()
