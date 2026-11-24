#!/usr/bin/env python3
"""Real 2013 to 2014 update; retain identity, earned progress and child data."""
from pathlib import Path
import json
import re

from lumo_2003_update_android_probe import main


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[2]
    source = json.loads((root / 'config/godot-source.json').read_text())
    if source.get('repository') != 'https://github.com/Ullmann27/lumo-godot.git':
        raise SystemExit('Unexpected native repository')
    native = source.get('revision', '')
    if not re.fullmatch(r'[0-9a-f]{40}', native) or source.get('engine') != '4.6.3':
        raise SystemExit('Native source must use the exact reviewed commit and engine')
    if native == '47bef06db45d61d50ecd06d0b0cd0a69b9a25917':
        raise SystemExit('Candidate still embeds the old 2013 native game')
    raise SystemExit(main(
        baseline_source='76aa559cb03d968f492b59129c1b7cee057e76e9',
        baseline_version=2013,
        candidate_version=2014,
        baseline_native='47bef06db45d61d50ecd06d0b0cd0a69b9a25917',
        candidate_native=native,
    ))
