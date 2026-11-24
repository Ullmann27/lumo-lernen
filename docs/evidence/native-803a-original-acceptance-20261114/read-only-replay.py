from pathlib import Path
import datetime
import hashlib
import importlib.util
import json
import platform
import sys

root = Path('/home/agent/lumo-native-review-803a-2708')
original = root / 'original'
source = root / 'verifier-source'
native_source = source / 'native'
nextgen = original / 'nextgen'
revision = '0e26153f0e58cc05739e72923b4c563a4cf380b8'
tree = '5b5992487e60ae805d708965f1500954c6b0556d'
code_manifest = json.loads((source / 'source-blobs.json').read_text())
for relative, wanted in code_manifest['files'].items():
    data = (source / relative).read_bytes()
    actual = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
    if actual != wanted:
        raise RuntimeError('Verifier source mismatch: ' + relative)

def snapshot(folder):
    entries = {}
    for path in sorted(folder.rglob('*')):
        if path.is_symlink():
            raise RuntimeError('Symlinked original evidence: ' + str(path))
        if path.is_file():
            with path.open('rb') as stream:
                digest = hashlib.file_digest(stream, 'sha256').hexdigest()
            entries[path.relative_to(folder).as_posix()] = {
                'bytes': path.stat().st_size, 'sha256': digest}
    encoded = json.dumps(entries, sort_keys=True, separators=(',', ':')).encode()
    return entries, hashlib.sha256(encoded).hexdigest()

started = datetime.datetime.now(datetime.timezone.utc).isoformat()
before, before_digest = snapshot(original)
for relative, expected in (
        ('source-sha.txt', revision),
        ('nextgen/source-sha.txt', revision),
        ('nextgen/source-tree.txt', tree)):
    actual = (original / relative).read_text().strip()
    if actual != expected:
        raise RuntimeError('Original source identity mismatch: ' + relative)
if (nextgen / 'source-dirty.txt').read_bytes() != b'':
    raise RuntimeError('Original native tracked source was dirty')
engine = (nextgen / 'engine.txt').read_text().strip()
if not engine.startswith('4.6.3.stable.'):
    raise RuntimeError('Unexpected original engine: ' + engine)

path = source / 'host/scripts/verify_connect_four_delivery.py'
spec = importlib.util.spec_from_file_location('original_host_delivery_verifier', path)
host = importlib.util.module_from_spec(spec)
spec.loader.exec_module(host)
runner = (native_source / 'tools/validate_nextgen.sh').read_text()
modes = host.checked_native_results(nextgen, runner)
runner_proof = host.checked_native_runner_log(original / 'nextgen-runner.log')
extension_proof = host.checked_native_extension(nextgen, native_source, revision, tree)
studio = json.loads((nextgen / 'studio-2020-images.json').read_text())
after, after_digest = snapshot(original)
if before != after:
    raise RuntimeError('An original evidence file changed during read-only replay')
report = {
    'schema': 1, 'status': 'PASS',
    'scope': 'Independent read-only replay of the original 52 native mode logs and 17 Studio2020 PNGs/3 sidecars/1 facial movie proofs. No engine rerun, Android-device, device-FPS, or full APK/workflow acceptance claim.',
    'started_utc': started,
    'completed_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'python_version': platform.python_version(),
    'source': {'native_commit': revision, 'native_tree': tree, 'engine': engine},
    'verifier_git_blobs': code_manifest,
    'mode_count': len(modes), 'mode_proofs': modes,
    'original_runner': runner_proof,
    'original_studio_manifest': extension_proof,
    'studio_images': studio['images'],
    'studio_reports': studio['reports'],
    'studio_movies': studio['movies'],
    'original_input_preservation': {
        'files': len(before),
        'total_bytes': sum(item['bytes'] for item in before.values()),
        'canonical_inventory_sha256_before': before_digest,
        'canonical_inventory_sha256_after': after_digest,
        'all_original_files_identical': True},
    'full_host_checked_native_function_executed': False,
    'used_original_host_functions': [
        'checked_native_results', 'checked_native_runner_log',
        'checked_native_extension'],
    'additional_source_checks': 'Original source/clean/engine stamps compared to the exact independently retrieved GitHub commit/tree; original verifier file blobs checked before loading.'
}
(root / 'read-only-replay.json').write_text(json.dumps(report, indent=2) + '\n')
(root / 'original-file-inventory.json').write_text(
    json.dumps(before, indent=2, sort_keys=True) + '\n')
print('PASS original ordered 52/52 modes and their exact PASS/error-free logs')
print('PASS original complete native runner ending and 17 PNGs / 3 sidecars / 1 facial movie proof')
print('PASS exact native source', revision, 'tree', tree, 'engine', engine)
print('PASS original files unchanged', len(before), 'inventory SHA256', before_digest)
print('SCOPE read-only evidence replay; no engine, APK, Android-device or performance run')
