import json, os, re
from pathlib import Path
metadata = Path('publication/metadata')
run = json.loads((metadata/'run.json').read_text())
assert run['id'] == int(os.environ['ACCEPTANCE_RUN'])
assert run['run_attempt'] == int(os.environ['ACCEPTANCE_ATTEMPT'])
assert run['head_sha'] == os.environ['SOURCE_SHA']
assert run['head_branch'] == 'integration/lumo-live-connections-20261114'
assert run['event'] == 'pull_request'
assert run['path'] == '.github/workflows/lumo-connect-four-2020.yml'
assert run['status'] == 'completed' and run['conclusion'] == 'success'
catalog = json.loads((metadata/'artifacts.json').read_text())
assert catalog['total_count'] == len(catalog['artifacts'])
matches = [a for a in catalog['artifacts'] if a['name'] == 'lumo-connect-four-2020-delivery-bundle']
assert len(matches) == 1
artifact = matches[0]
assert artifact['expired'] is False
assert artifact['workflow_run']['id'] == run['id']
assert artifact['workflow_run']['head_sha'] == os.environ['SOURCE_SHA']
assert type(artifact['id']) is int and artifact['id'] > 0
assert re.fullmatch(r'sha256:[a-f0-9]{64}', artifact['digest'])
(metadata/'bundle.json').write_text(json.dumps(artifact, indent=2) + '\n')
with open(os.environ['GITHUB_ENV'], 'a') as handle:
    handle.write('BUNDLE_ARTIFACT_ID=' + str(artifact['id']) + '\n')
