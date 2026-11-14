#!/usr/bin/env python3
"""Read-only replay of exact committed readers against original CI evidence."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time
import PIL

sys.dont_write_bytecode = True
BASE = Path('/workspace/scratch/2708c7907f28/aab-native-evidence-14114314120')
ORIGINAL = BASE / 'original'
READERS = BASE / 'review-readers'
HOST = Path('/workspace/scratch/2708c7907f28/lumo-host-current')
HOST_SHA = 'aab09275ec6b5808de9be539ca4e1a7e70921249'
NATIVE_SHA = 'e2d15dbc5f3709306decb139eeb70a1cf30c0b73'
NATIVE_TREE = 'ea0f73ae6aad8792a963cadaa483c290a2f2a62e'
sys.path.insert(0, str(READERS))
sys.path.insert(0, str(HOST / 'scripts'))

def identity(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()}

def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module

expected_helpers = {
    'verify_studio_2020_rasters.py': 'b60c3360730f0db73f91324cbaed3a8806fd141e',
    'verify_dream_rasters.py': 'da8eed7d6383fcbc82a03596518a5fcc3b9a00c5',
    'verify_village_rasters.py': '7c9522903db13f9bd0917ef2768ddbc08e624b1d',
    'validate_nextgen.sh': '3255c2e6bd6cfd4b7bb6e50e6dc9b4aaf67e5946',
}
helpers_before = {name: identity(READERS/name) for name in expected_helpers}
assert all(helpers_before[name]['git_blob'] == blob for name, blob in expected_helpers.items())
host_file = HOST/'scripts/verify_connect_four_delivery.py'
host_before = identity(host_file)
assert subprocess.check_output(['git', '-C', str(HOST), 'rev-parse', 'HEAD'], text=True).strip() == HOST_SHA
assert host_before['git_blob'] == subprocess.check_output(
    ['git', '-C', str(HOST), 'rev-parse', HOST_SHA+':scripts/verify_connect_four_delivery.py'], text=True).strip()
assert (ORIGINAL/'dream-verifier-original.py').read_bytes() == (READERS/'verify_dream_rasters.py').read_bytes()

archive_index = json.loads((BASE/'archive-review.json').read_text())
indexed = {row['path']: row for row in archive_index['original_files']}
assert len(indexed) == 5035
studio_original = json.loads((ORIGINAL/'nextgen/studio-2020-images.json').read_text())
dream_original = json.loads((ORIGINAL/'dream/dream-images.json').read_text())
tracked_paths = {'nextgen/studio-2020-images.json', 'dream/dream-images.json',
                 'source-sha.txt', 'nextgen-runner.log', 'dream-runner.log',
                 'dream-verifier-original.py', 'nextgen/results.tsv',
                 'nextgen/engine.txt', 'connect-four-return.log'}
for row in studio_original['images'] + studio_original['reports'] + studio_original['source']['stamps']:
    tracked_paths.add('nextgen/'+row['path'])
movie = studio_original['movies'][0]
for key in ('encoded', 'source_avi', 'proof', 'ffprobe'):
    tracked_paths.add('nextgen/'+movie[key]['path'])
for row in movie['logs']:
    tracked_paths.add('nextgen/'+row['path'])
for key in ('probes', 'source_stamps', 'source_inventories', 'original_pngs', 'original_reports'):
    tracked_paths.update('dream/'+row['path'] for row in dream_original[key])
tracked_paths.add('dream/'+dream_original['results']['path'])
for row in (ORIGINAL/'nextgen/results.tsv').read_text().splitlines()[1:]:
    name, mode, result = row.split('\t')
    tracked_paths.add('nextgen/'+name+'-'+mode+'.log')
before = {}
for relative in sorted(tracked_paths):
    record = identity(ORIGINAL/relative)
    assert all(record[key] == indexed[relative][key] for key in ('bytes', 'sha256'))
    before[relative] = record

delivery = load_module('_original_host_delivery_reader', host_file)
studio = load_module('_approved_native_studio_reader', READERS/'verify_studio_2020_rasters.py')
dream = load_module('_approved_native_dream_reader', READERS/'verify_dream_rasters.py')
start = time.monotonic()
modes = delivery.checked_native_results(ORIGINAL/'nextgen', (READERS/'validate_nextgen.sh').read_text())
runner_record = delivery.checked_native_runner_log(ORIGINAL/'nextgen-runner.log')
studio_fresh = studio.verify(ORIGINAL/'nextgen', write=False)
dream_fresh = dream.verify(ORIGINAL/'dream', write=False)
assert studio_fresh == studio_original
assert dream_fresh == dream_original
assert len(modes) == 52
assert len(studio_fresh['images']) == 17 and len(studio_fresh['reports']) == 3 and len(studio_fresh['movies']) == 1
assert len(dream_fresh['probes']) == 5 and len(dream_fresh['original_pngs']) == 7 and len(dream_fresh['original_reports']) == 2
assert studio_fresh['source']['commit'] == dream_fresh['native_source'] == NATIVE_SHA
assert studio_fresh['source']['tree'] == dream_fresh['native_tree'] == NATIVE_TREE
dream_runner = (ORIGINAL/'dream-runner.log').read_text()
assert all(dream_runner.splitlines().count(marker) == 1 for marker in delivery.DREAM_RUNNER_MARKERS)
assert not delivery.ERROR_LINE.search(dream_runner)
assert (ORIGINAL/'source-sha.txt').read_text() == NATIVE_SHA+'\n'
expected = json.loads((READERS/'expected-remote-native-tree.json').read_text())
remote = {row['path']: row for row in expected['files']}
inventories = []
for phase in ('before', 'after'):
    inventory = json.loads((ORIGINAL/'dream'/('source-inventory-'+phase+'.json')).read_text())
    assert inventory['head'] == NATIVE_SHA and inventory['tree'] == NATIVE_TREE
    assert len(inventory['tracked']) == len(remote) == 3649
    assert {row['path'] for row in inventory['tracked']} == set(remote)
    for row in inventory['tracked']:
        reference = remote[row['path']]
        assert row['git_blob'] == reference['git_blob'] and row['mode'] == reference['mode']
        assert row['materialized'] and row['actual_blob'] == row['git_blob']
        assert row['bytes'] == reference['bytes']
    inventories.append(inventory)
assert inventories[0]['tracked'] == inventories[1]['tracked']
assert inventories[0]['index_sha256'] == inventories[1]['index_sha256']
elapsed = time.monotonic()-start
after = {relative: identity(ORIGINAL/relative) for relative in sorted(tracked_paths)}
assert before == after
assert helpers_before == {name: identity(READERS/name) for name in expected_helpers}
assert host_before == identity(host_file)
report = {
    'schema': 'lumo.native-main.original-reader-replay.v1',
    'performed': True, 'passed': True,
    'host': HOST_SHA, 'native': NATIVE_SHA, 'native_tree': NATIVE_TREE,
    'artifact_id': 14114314120, 'run_id': 43590864772, 'run_attempt': 1,
    'python': sys.version, 'pillow': PIL.__version__, 'reader_elapsed_seconds': elapsed,
    'command': ['python3', '-B', str(BASE/'reader-replay.py')],
    'approved_helpers': helpers_before, 'host_delivery_reader': host_before,
    'actual_calls': [
        'checked_native_results(nextgen, exact_committed_validate_nextgen_text)',
        'checked_native_runner_log(original_nextgen_runner_log)',
        'verify_studio_2020_rasters.verify(nextgen, write=False)',
        'verify_dream_rasters.verify(dream, write=False)',
    ],
    'core_modes': len(modes), 'mode_log_records': modes, 'complete_runner_record': runner_record,
    'studio': {'images': 17, 'reports': 3, 'movies': 1, 'fresh_result_equals_original': True},
    'dream': {'probes': 5, 'images': 7, 'reports': 2, 'fresh_result_equals_original': True,
              'changed_pairs': dream_fresh['changed_pairs'],
              'untracked_inventory_counts': dream_fresh['untracked_inventory_counts']},
    'remote_tracked_tree_entries_matched_before_and_after': 3649,
    'tracked_inventory_and_git_index_unchanged': True,
    'source_inventory_files_byte_equal':
        (ORIGINAL/'dream/source-inventory-before.json').read_bytes() ==
        (ORIGINAL/'dream/source-inventory-after.json').read_bytes(),
    'original_records_before_after': before,
    'original_records_checked_unchanged': len(before),
    'helper_and_host_reader_bytes_unchanged': True,
    'limits': [
        'Only approved committed reader code was loaded; archived Python is evidence only.',
        'No engine, renderer, game probe, ffmpeg, ffprobe or application test was run.',
        'Local Pillow 13.0.0 reader outputs exactly equal original CI manifests; this is not a new capture.',
        'The C4 raster set contains visual fixtures, separate from the production Dart/runtime result-action proof.',
        'No physical Android, audible speaker output or device FPS measurement is inferred.',
        'No full host delivery verification, APK verification or whole-workflow success is claimed here.',
    ],
}
(BASE/'reader-replay-result.json').write_text(json.dumps(report, indent=2)+'\n')
(BASE/'studio-fresh-readonly.json').write_text(json.dumps(studio_fresh, indent=2)+'\n')
(BASE/'dream-fresh-readonly.json').write_text(json.dumps(dream_fresh, indent=2)+'\n')
print(json.dumps({key: report[key] for key in ('performed','passed','core_modes','studio','dream',
    'remote_tracked_tree_entries_matched_before_and_after','tracked_inventory_and_git_index_unchanged',
    'source_inventory_files_byte_equal','original_records_checked_unchanged',
    'helper_and_host_reader_bytes_unchanged','reader_elapsed_seconds')}, indent=2))
