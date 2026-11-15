#!/usr/bin/env python3
"""Verify the 2021 APK with the complete inherited gates and new activity proofs."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools/android_qa'))
from integrated_candidate_profile import candidate_scope


def main():
    import verify_connect_four_candidate
    with candidate_scope(complete=True):
        return verify_connect_four_candidate.main()


if __name__ == '__main__':
    raise SystemExit(main())
