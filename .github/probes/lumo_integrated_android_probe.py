#!/usr/bin/env python3
"""Use the original C4/Village observations with the explicit new 2021 identity."""
import argparse
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools/android_qa'))
from integrated_candidate_profile import candidate_scope


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--game', choices=('c4', 'village'), required=True)
    selected, remaining = parser.parse_known_args()
    if selected.game == 'c4':
        from lumo_connect_four_android_probe import main as original
    else:
        from lumo_village_android_probe import main as original
    sys.argv = [sys.argv[0], *remaining]
    with candidate_scope():
        return original()


if __name__ == '__main__':
    raise SystemExit(main())
