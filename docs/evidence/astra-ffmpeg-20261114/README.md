# Astra app-script CI prerequisite repair — 2026-11-14

## Exact original failure

- Repository: Ullmann27/lumo-lernen
- Tested PR head: `01575aafc3f5b9032900bb57520ee65e98d7546c`
- Run: [43576227534, attempt 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43576227534)
- Failed job: [132390953713, full-app-script-regression](https://github.com/Ullmann27/lumo-lernen/actions/runs/43576227534/job/132390953713)
- Failed step: `Reproduce the whole Astra app-script test inventory`.
- Result: `Ran 868 tests in 273.622s`, `FAILED (errors=1)`.
- Error: `RuntimeError: ffmpeg is required for the original MP4 regression` from `scripts/tests/test_studio_jump_decode.py:69`.

`original-github-job-132390953713.log` preserves the complete decoded job log returned by GitHub, without replacing the original failure with a local run.

On the tested source, `.github/workflows/lumo-astra-script-recovery.yml` installed only `ripgrep` through apt. The original MP4 test requires both `ffmpeg` and `ffprobe` in its class setup before decoding the fixed original movie. The independent C4 pipeline already installs these prerequisites; the failing Astra workflow did not.

## Narrow change

Install the `ffmpeg` package in the Astra workflow's prerequisite step, then explicitly locate and execute the version command for each of `ffmpeg` and `ffprobe`. The step retains `set -euo pipefail`, and remains before unfiltered discovery of the entire app-script inventory.

The MP4 test, original media, test discovery, failure handling, source filters, and upload-on-failure behavior are unchanged. No tests were added or weakened.

Changed workflow Git blob: `777d8f3c3bb7dad2a0155a156c6a1f9f7d37e11b`.

## Local verification and scope

- actionlint 1.7.12 on the changed workflow: exit 0.
- `bash -n` on each of its three actual run blocks: exit 0.
- Existing `scripts.tests.test_connect_four_pipeline.WorkflowTests`: 8 tests passed in 0.079 seconds. These preserve the related C4 source/branch/dependency/learning/delivery contracts; they are not an execution of apt installation or the repaired GitHub job.
- `git diff --check`: exit 0.

The first local contract invocation lacked `config/godot-source.json` because the isolated sparse checkout excluded that directory. Including the unchanged baseline `config/` resolved that local setup issue; both invocation outputs are retained in `local-validation.log`.

No local full Python-suite rerun, apt installation, APK build, or signed bundle was performed for this four-line prerequisite check addition. A new actual CI run must establish the corrected workflow result.
