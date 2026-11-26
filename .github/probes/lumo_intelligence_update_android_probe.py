#!/usr/bin/env python3
"""Run the existing in-place Android update contract from the verified 2082 baseline."""

import json
from pathlib import Path

from lumo_2003_update_android_probe import main

BASELINE_APP = '6574b19f92abb4f6421fd3074cec09738dc0974a'
BASELINE_GAME = '62108c0355f860ab9a0a020ecb5f3f941f1032e9'


if __name__ == '__main__':
    repo = Path(__file__).resolve().parents[2]
    request = json.loads((repo / 'config/intelligence-2-0-apk-request.json').read_text())
    version = int(request['version'].rsplit('+', 1)[1])
    if version <= 2082:
        raise ValueError('The Android update must be newer than build 2082')
    game = json.loads((repo / 'config/godot-source.json').read_text())
    if game['revision'] != request['godot_revision']:
        raise ValueError('The build request does not identify the packaged game')
    raise SystemExit(main(baseline_source=BASELINE_APP, baseline_version=2082,
                          baseline_native=BASELINE_GAME, candidate_version=version,
                          candidate_native=game['revision']))
