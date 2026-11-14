#!/usr/bin/env python3
"""Real 2017 to 2019 in-place update with the original package and certificate.

The established update probe retains live-created learning, profile identity,
offline Kart, restart and simulated Fold checks. Only the reviewed source pair
and candidate version change here; this wrapper cannot approve arbitrary pins.
"""
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import os


ROOT = Path(__file__).resolve().parents[2]
BASELINE_SOURCE = '47889f74a651b073965def70743417cf320b1eb9'
BASELINE_NATIVE = '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57'


def reviewed_candidate_native(pubspec_text: str, source_text: str) -> str:
    spec = spec_from_file_location(
        'lumo_reviewed_candidate_pin', ROOT / 'scripts/verify_legacy_release_pin.py')
    if spec is None or spec.loader is None:
        raise RuntimeError('The reviewed native-source policy is unavailable')
    policy = module_from_spec(spec)
    spec.loader.exec_module(policy)
    version, native = policy.verify(pubspec_text, source_text)
    if version != 2019:
        raise ValueError('This update proof requires candidate version 2019')
    if native == BASELINE_NATIVE:
        raise ValueError('Candidate still embeds the unchanged 2017 native game')
    return native


if __name__ == '__main__':
    native_source = reviewed_candidate_native(
        (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'),
        (ROOT / 'config/godot-source.json').read_text(encoding='utf-8'),
    )
    from lumo_2003_update_android_probe import main

    os.environ['LUMO_NATIVE_STAGE_MENU'] = '1'
    raise SystemExit(main(
        baseline_source=BASELINE_SOURCE,
        baseline_version=2017,
        candidate_version=2019,
        baseline_native=BASELINE_NATIVE,
        candidate_native=native_source,
        allow_2018_independent_evidence_migration=True,
    ))
