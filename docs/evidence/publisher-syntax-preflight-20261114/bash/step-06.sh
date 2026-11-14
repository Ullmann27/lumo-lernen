set -euo pipefail
test "$(git rev-parse HEAD)" = "$SOURCE_SHA"
git diff --exit-code HEAD --
mkdir -p publication/apk-verification
sdkmanager 'build-tools;36.0.0' 2>&1 | tee publication/apk-verification/sdkmanager.log
publisher_build_tools="$ANDROID_HOME/build-tools/36.0.0"
test -x "$publisher_build_tools/apksigner"
test -x "$publisher_build_tools/aapt"
export PATH="$publisher_build_tools:$PATH"
java -version 2>&1 | tee publication/apk-verification/java-version.log
"$publisher_build_tools/apksigner" version 2>&1 | tee publication/apk-verification/apksigner-version.log
"$publisher_build_tools/aapt" version 2>&1 | tee publication/apk-verification/aapt-version.log
cp "$publisher_build_tools/source.properties" publication/apk-verification/source.properties
sha256sum "$publisher_build_tools/apksigner" "$publisher_build_tools/lib/apksigner.jar" "$publisher_build_tools/aapt" > publication/apk-verification/tools.sha256
publisher_apk="publication/delivery/assets/Lumo-Lernen-Neu.apk"
"$publisher_build_tools/apksigner" verify --verbose --print-certs "$publisher_apk" 2>&1 | tee publication/apk-verification/apksigner-original.log
"$publisher_build_tools/aapt" dump badging "$publisher_apk" > publication/apk-verification/aapt-badging-original.txt 2> publication/apk-verification/aapt-badging.stderr.log
python3 scripts/verify_unified_apk.py "$publisher_apk" --abi arm64-v8a > publication/apk-verification/fresh-apk-verification.json 2> publication/apk-verification/verifier.stderr.log
python3 - <<'PY'
import hashlib, json, os, subprocess
from pathlib import Path
root = Path('publication')
assets = root/'delivery/assets'
fresh = json.loads((root/'apk-verification/fresh-apk-verification.json').read_text())
original = json.loads((assets/'PUBLISH-VERIFICATION.json').read_text())
provenance = json.loads((assets/'BUILD-PROVENANCE.json').read_text())
delivery = json.loads((assets/'C4-DELIVERY-FACTS.json').read_text())
plan = json.loads((root/'delivery/publication-plan.json').read_text())
pin = json.loads(Path('config/godot-source.json').read_text())
source = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
assert source == os.environ['SOURCE_SHA'] == delivery['host_source'] == provenance['flutter_source_commit']
assert provenance['tracked_source_clean'] is True
assert fresh == original == delivery['apks']['arm64-v8a']
assert fresh['package'] == 'dev.ullmann.lumo.lumo_lernen.coachpreview'
assert fresh['versionCode'] == 2020 and fresh['versionName'] == '0.13.8'
assert fresh['abis'] == ['arm64-v8a'] and fresh['minSdk'] == 24 and fresh['targetSdk'] == 36
assert fresh['signingCertificateSha256'] == 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
assert fresh['godot']['revision'] == pin['revision'] == delivery['native_source']
assert all(provenance.get(key) == value for key, value in fresh.items())
apk = assets/'Lumo-Lernen-Neu.apk'
with apk.open('rb') as stream:
    digest = hashlib.file_digest(stream, 'sha256').hexdigest()
assert digest == fresh['sha256'] == plan['assets']['Lumo-Lernen-Neu.apk']['sha256']
assert apk.stat().st_size == fresh['bytes'] == plan['assets']['Lumo-Lernen-Neu.apk']['bytes']
subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], check=True)
paths = ('scripts/verify_unified_apk.py', 'scripts/verify_android_apk.py',
         'scripts/LumoApkCertificateVerifier.java', 'pubspec.yaml',
         'config/godot-source.json', 'config/lumo-offline-voice.json',
         'assets/audio/voice/lumo_free/catalog.json')
receipt = {
    'schema': 1, 'status': 'VERIFIED_ORIGINAL_TEST_APK_BEFORE_PUBLICATION',
    'host_source': source, 'host_tree': subprocess.check_output(
        ['git', 'rev-parse', 'HEAD^{tree}'], text=True).strip(),
    'native_source': pin['revision'], 'acceptance_run': int(os.environ['ACCEPTANCE_RUN']),
    'acceptance_attempt': int(os.environ['ACCEPTANCE_ATTEMPT']),
    'pull_request': int(os.environ['ACCEPTANCE_PR']), 'apk': fresh,
    'verifier_sources': {name: hashlib.sha256(Path(name).read_bytes()).hexdigest() for name in paths},
    'signing_scope': 'Existing stable LUMO test certificate; not a Google Play signing certificate',
    'published': False, 'physical_arm64_tested': False,
}
with (root/'APK-PREPUBLISH-VERIFICATION.json').open('x') as stream:
    stream.write(json.dumps(receipt, indent=2) + '\n')
PY
