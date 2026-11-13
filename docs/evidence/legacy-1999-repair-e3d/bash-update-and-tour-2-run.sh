set -euo pipefail
mkdir -p update-proof
gh api repos/Ullmann27/lumo-lernen/actions/runs/40096024152 > update-proof/candidate-run.json
gh api repos/Ullmann27/lumo-lernen/actions/runs/39755153883 > update-proof/baseline-run.json
python3 - <<'PY'
import json
from pathlib import Path
for name, sha in [('candidate', 'c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf'),
                  ('baseline', '136f486ac3bdc4aabbd3b990e6629d2d6640c7d4')]:
    data = json.loads(Path(f'update-proof/{name}-run.json').read_text())
    assert data['head_sha'] == sha
    assert data['status'] == 'completed' and data['conclusion'] == 'success'
    assert data['repository']['full_name'] == 'Ullmann27/lumo-lernen'
PY

