from __future__ import annotations

import ast
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sys

import yaml

ROOT = Path('/home/agent/lumo-host-dream-merge-2708')
native = sys.argv[1]
assert re.fullmatch(r'[a-f0-9]{40}', native)
assert native not in ('6ecc560ea16202b935c4f1d32b08b93cda358e02', 'bd0712259bb64908a5649ee1999638826c9eb597')
source = json.loads((ROOT/'source-records.json').read_text())
conflict = re.compile(r'^<<<<<<< [^\n]+\n(.*?)^=======\n(.*?)^>>>>>>> [^\n]+\n', re.M | re.S)
resolved = {}
records = []
for row in source['records']:
    relative = row['path']
    text = (ROOT/'automatic'/relative).read_text()
    matches = list(conflict.finditer(text))
    assert len(matches) == row['merge_file_exit_code'], (relative, len(matches))
    if relative in ('.github/workflows/lumo-connect-four-2020.yml', 'scripts/verify_connect_four_delivery.py'):
        assert len(matches) == 1
        if relative.endswith('.yml'):
            assert matches[0][1].startswith('      - name: Require acknowledged Connect Four return retry\n')
            assert matches[0][2].startswith('      - name: Require actual Dream gates on the exact pinned native source\n')
        else:
            assert matches[0][1] == "        'Require acknowledged Connect Four return retry',\n"
            assert matches[0][2] == '        DREAM_STEP,\n'
        text = conflict.sub(lambda match: match[1] + match[2], text)
        strategy = 'Preserve both independent additions, return first and Dream second.'
    elif relative in ('config/godot-source.json', 'scripts/tests/test_candidate_2011_pin.py'):
        assert len(matches) == 1
        text = conflict.sub(lambda match: match[1], text)
        assert text.count('6ecc560ea16202b935c4f1d32b08b93cda358e02') == 1
        text = text.replace('6ecc560ea16202b935c4f1d32b08b93cda358e02', native)
        strategy = 'Bind only the current 2020 identity to the actual preserving Native merge.'
    elif relative == 'scripts/verify_legacy_release_pin.py':
        assert len(matches) == 1
        replacement = (
            '    # 2020: combined C4 return retry, facial, Treasure, Dream and minimap source.\n'
            '    # This entry binds source identity only. Fresh 52-mode and Dream renderer\n'
            '    # gates, Android integration and preserved-update acceptance remain mandatory.\n'
            '    2020: "' + native + '",\n'
        )
        text = conflict.sub(lambda match: replacement, text)
        strategy = 'Bind the actual Native merge and clarify the unchanged source-only approval scope.'
    else:
        assert not matches
        strategy = 'Actual conflict-free git merge-file output; preserve all parent changes.'
    assert not re.search(r'^(<<<<<<< |=======|>>>>>>> )', text, re.M), relative
    resolved[relative] = text
    raw = text.encode()
    target = ROOT/'resolved'/relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(raw)
    records.append({'path': relative, 'strategy': strategy, 'bytes': len(raw),
                    'blob': hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest(),
                    'sha256': hashlib.sha256(raw).hexdigest()})

workflow_path = '.github/workflows/lumo-connect-four-2020.yml'
workflow = yaml.safe_load(resolved[workflow_path])
parents = {name: yaml.safe_load((ROOT/name/workflow_path).read_text()) for name in ('ours', 'theirs')}
names = (
    'Retry the acknowledged native exit after a transient Android refusal',
    'Require the additional pinned native Treasure wisp regression',
    'Require actual gameplay gates on the exact pinned native source',
    'Require acknowledged Connect Four return retry',
    'Require actual Dream gates on the exact pinned native source',
)
def step(doc: dict, name: str) -> dict:
    found = [item for job in doc['jobs'].values() for item in job.get('steps', []) if item.get('name') == name]
    assert len(found) == 1, name
    return found[0]
step_proofs = []
for name in names:
    parent = 'theirs' if 'Dream gates' in name else 'ours'
    assert step(workflow, name) == step(parents[parent], name), name
    step_proofs.append({'name': name, 'unchanged_from': source[parent]})
new_steps = workflow['jobs']['verify-and-build']['steps']
labels = [item.get('name', '') for item in new_steps]
assert labels.index(names[2]) < labels.index(names[3]) < labels.index(names[4])
upload = lambda doc: [item for item in doc['jobs']['verify-and-build']['steps'] if item.get('with', {}).get('name') == 'lumo-candidate-pinned-native-gameplay']
assert upload(workflow) == upload(parents['ours']) == upload(parents['theirs'])

test_path = 'scripts/tests/test_connect_four_delivery.py'
def methods(text: str) -> dict:
    tree = ast.parse(text)
    return {node.name + '.' + member.name: ast.dump(member, include_attributes=False)
            for node in tree.body if isinstance(node, ast.ClassDef)
            for member in node.body if isinstance(member, ast.FunctionDef) and member.name.startswith('test_')}
new_methods = methods(resolved[test_path])
preserved_tests = {}
base_methods = methods((ROOT/'base'/test_path).read_text())
our_methods = methods((ROOT/'ours'/test_path).read_text())
their_methods = methods((ROOT/'theirs'/test_path).read_text())
assert all(new_methods.get(name) == body for name, body in our_methods.items())
expected_methods = dict(our_methods)
incoming_changes = {}
for name, body in their_methods.items():
    if base_methods.get(name) != body:
        assert name not in our_methods or our_methods[name] in (base_methods.get(name), body), name
        expected_methods[name] = body
        incoming_changes[name] = body
assert new_methods == expected_methods
preserved_tests = {'ours_unchanged': len(our_methods),
                   'incoming_additions_or_changes_unchanged': len(incoming_changes),
                   'incoming_total': len(their_methods),
                   'common_base_total': len(base_methods)}

policy_path = 'scripts/verify_legacy_release_pin.py'
def approved(text: str) -> dict:
    node = next(node for node in ast.parse(text).body if isinstance(node, ast.Assign)
                and any(isinstance(target, ast.Name) and target.id == 'APPROVED' for target in node.targets))
    return ast.literal_eval(node.value)
new_pins = approved(resolved[policy_path])
for label in ('ours', 'theirs'):
    old_pins = approved((ROOT/label/policy_path).read_text())
    assert {k: v for k, v in new_pins.items() if k != 2020} == {k: v for k, v in old_pins.items() if k != 2020}
assert new_pins[2020] == native
delivery_path = 'scripts/verify_connect_four_delivery.py'
def functions(text: str) -> dict:
    return {node.name: ast.dump(node, include_attributes=False) for node in ast.parse(text).body if isinstance(node, ast.FunctionDef)}
old_functions = functions((ROOT/'ours'/delivery_path).read_text())
new_functions = functions(resolved[delivery_path])
assert all(new_functions[name] == body for name, body in old_functions.items() if name not in ('checked_native', 'prepare'))
assert new_functions['checked_native'] == functions((ROOT/'theirs'/delivery_path).read_text())['checked_native']
assert "QUALITY_BRANCH = 'work/lumo-play-quality-20261114'" in resolved[delivery_path]
record = {
    'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'base': source['base'], 'parents': [source['ours'], source['theirs']], 'native_revision': native,
    'resolved_files': records, 'unchanged_workflow_steps': step_proofs,
    'original_native_artifact_upload_unchanged': True,
    'delivery_test_methods_unchanged_from_each_parent': preserved_tests,
    'merged_delivery_test_methods': len(new_methods),
    'all_pre_2020_native_policies_unchanged': True,
    'delivery_functions_unchanged_except_additional_dream_collection_and_release_text': True,
    'scope': 'Actual source merge and static identity assertions; no execution or new APK approval is implied.'
}
(ROOT/'resolution-record.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record, indent=2))
