"""Verify signing, embedded source, package, ABIs and resource packaging."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import zipfile

from verify_android_apk import verify_apk, find_apksigner

ROOT = Path(__file__).resolve().parents[1]


def verify(path: Path):
    certificate = verify_apk(path)
    tools = Path(find_apksigner()).parent
    badging = subprocess.check_output([str(tools / 'aapt'), 'dump', 'badging', str(path)], text=True)
    package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    if package is None or package.group(1) != 'dev.ullmann.lumo.lumo_lernen.coachpreview':
        raise RuntimeError('Wrong package: this delivery must safely update the Build 274 parallel app')
    expected_code = os.environ.get('LUMO_BUILD_NUMBER', '275')
    expected_name = os.environ.get('LUMO_VERSION_NAME', '0.10.0')
    if package.group(2) != expected_code or package.group(3) != expected_name:
        raise RuntimeError('Wrong Android version')
    if "sdkVersion:'24'" not in badging:
        raise RuntimeError('Unexpected minimum Android version')
    source = json.loads((ROOT / 'config/godot-source.json').read_text())
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise RuntimeError('APK ZIP integrity failed')
        names = archive.namelist()
        abis = {name.split('/')[1] for name in names if name.startswith('lib/') and name.endswith('.so')}
        if abis != {'arm64-v8a', 'x86_64'}:
            raise RuntimeError(f'Unexpected native architectures: {abis}')
        for abi in abis:
            for library in ('libflutter.so', 'libapp.so', 'libgodot_android.so'):
                if f'lib/{abi}/{library}' not in names:
                    raise RuntimeError(f'Missing {abi}/{library}')
        info = archive.getinfo('resources.arsc')
        if info.compress_type != zipfile.ZIP_STORED:
            raise RuntimeError('Android 11 requires uncompressed resources.arsc')
        pack = archive.read('assets/lumo_game.pck')
        provenance = json.loads(archive.read('assets/lumo_game_source.json'))
        if provenance['revision'] != source['revision']:
            raise RuntimeError('Wrong Godot source revision')
        if hashlib.sha256(pack).hexdigest() != provenance['pck_sha256']:
            raise RuntimeError('Embedded PCK digest mismatch')
        if struct.unpack('<4s4I', pack[:20])[0] != b'GDPC':
            raise RuntimeError('Invalid Godot PCK')
    xml = subprocess.check_output([str(tools / 'aapt'), 'dump', 'xmltree', str(path), 'AndroidManifest.xml'], text=True)
    if 'LumoGameActivity' not in xml or ':lumo_game' not in xml:
        raise RuntimeError('Private embedded game activity missing')
    if re.search(r'android:debuggable[^\n]*0xffffffff', xml):
        raise RuntimeError('Release APK is debuggable')
    result = {'package': package.group(1), 'versionCode': int(package.group(2)), 'versionName': package.group(3),
              'minSdk': 24, 'abis': sorted(abis), 'bytes': path.stat().st_size,
              'sha256': hashlib.file_digest(path.open('rb'), 'sha256').hexdigest(),
              'signingCertificateSha256': certificate, 'godot': provenance}
    print(json.dumps(result, indent=2))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    verify(parser.parse_args().apk)
