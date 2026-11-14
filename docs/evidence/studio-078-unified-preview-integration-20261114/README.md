# Unified workflow: observed Kart preview skip

This isolated change targets only `.github/workflows/lumo-unified-integration-2026.yml` from published Host `078774ddaf64808addaa4c6406f6a3c85b1f239a`. Its original Git blob is `b393e64d87874794742be4a44052fb188aef6b95`. No active checkout, source pin, branch, receipt, release, or workflow run was changed by this package.

## Exact change

The existing `android-tour` job's `Live UI reader` preparation now requires the nonempty `tools/android_qa/tests/test_kart_preview_skip.py` and executes that existing 23-contract module with `python3 -B -m unittest discover -s tools/android_qa/tests -p test_kart_preview_skip.py -v`. This runs inside the existing `set -euo pipefail` block, after Python compilation of the tour helper and before the emulator starts. A missing module or failed contract stops preparation.

The existing single actual `modernization_android_tour.py` command receives `--skip-observed-kart-preview`. It retains the same APK/provenance/checksum arguments and output directory. The probe's flag still defaults to false for callers that do not explicitly opt in.

Root must integrate the unchanged, separately frozen sources from QA commit `3f89e5f045171424e9187ebdfb9ec1900ab16df3`:

| File | Git blob |
| --- | --- |
| `.github/probes/modernization_android_tour.py` | `481c19f8c9b9ed15ee205a534d1cfc8797d06aa8` |
| `tools/android_qa/tests/test_kart_preview_skip.py` | `ca2477afc4708385e705645613d45e3374f829f7` |

Those files were read and rehashed for the integration check; this package does not modify or reinstall them. The unchanged probe observes two fresh target frames, obtains actual OCR text and bounds, sends the real touch, and preserves the original 55-second start and 150-second race-running limits and all following gameplay/data gates.

## Performed validation

`prepare_and_validate.py` was executed once with Python 3. It checked the exact original Git blob, produced the explicit patch, parsed both workflows with the already installed PyYAML 6.0.3 BaseLoader, and verified that reversing only the two preparation lines and the single flag reproduces the entire original file byte for byte. The twelve other jobs and all non-job workflow settings are equal. The Android job retains seven steps, its 50-minute timeout, the preparation step's eight-minute timeout, all action arguments, permissions, conditions, and output preservation. `bash -n` accepted the exact modified preparation script with exit 0.

The validation performs no Flutter, Android, OCR, dependency-installation, or 23-contract execution. The original execution record and machine-readable source identities are included separately. The successful 23-contract run and API 35 countercheck are earlier actual CI evidence from Run `43587032836`; they are not relabelled as execution of this new workflow. No API 37 success follows from that API 35 result. Historical failed runs remain failed.

The corrected workflow is an integration proposal until Root combines it with the exact frozen probe/test and starts the intended candidate. Its source manifest contains exactly one workflow file. Its evidence manifest contains only explicitly listed documentation and validation records.
