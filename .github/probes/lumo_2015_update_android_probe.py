#!/usr/bin/env python3
"""Real 2014 to 2015 in-place update with the original package and certificate.

The established update probe retains live-created learning, profile identity,
offline Kart, restart and simulated Fold checks. Only the reviewed source pair
and candidate version change here; this wrapper cannot approve arbitrary pins.
"""
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASELINE_SOURCE = '696db258693465acfc27d051c9c0874710ac9046'
BASELINE_NATIVE = '207bfbc5377c0f3e8be800854c83ddf2110ac3f6'


def reviewed_candidate_native(pubspec_text: str, source_text: str) -> str:
    spec = spec_from_file_location(
        'lumo_reviewed_candidate_pin', ROOT / 'scripts/verify_legacy_release_pin.py')
    if spec is None or spec.loader is None:
        raise RuntimeError('The reviewed native-source policy is unavailable')
    policy = module_from_spec(spec)
    spec.loader.exec_module(policy)
    version, native = policy.verify(pubspec_text, source_text)
    if version != 2015:
        raise ValueError('This update proof requires candidate version 2015')
    if native == BASELINE_NATIVE:
        raise ValueError('Candidate still embeds the unchanged 2014 native game')
    return native


if __name__ == '__main__':
    native_source = reviewed_candidate_native(
        (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'),
        (ROOT / 'config/godot-source.json').read_text(encoding='utf-8'),
    )
    from lumo_2003_update_android_probe import main

    raise SystemExit(main(
        baseline_source=BASELINE_SOURCE,
        baseline_version=2014,
        candidate_version=2015,
        baseline_native=BASELINE_NATIVE,
        candidate_native=native_source,
    ))
