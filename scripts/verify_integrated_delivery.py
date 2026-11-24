#!/usr/bin/env python3
"""Prepare or check the new immutable 2021 delivery using all inherited gates."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools/android_qa'))
from integrated_candidate_profile import candidate_scope


def main():
    import verify_connect_four_delivery
    with candidate_scope(delivery=True):
        return verify_connect_four_delivery.main()


if __name__ == '__main__':
    raise SystemExit(main())
