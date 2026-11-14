# Actual execution follow-up — 2026-11-14

This follow-up records the narrow execution requested after the managed runtime returned. The earlier checkpoint `cadfeb090a5d665557fd5ffa4d7943ef1a4a50c1` remains unchanged and records the unavailable runtime at that time. The current README now links this later execution result explicitly.

## Exact execution

- Repaired test blob: `b9c667de8d9d9fd3ec158141d17d09d899aea2b6`, unchanged from the independently reviewed checkpoint.
- Production and supporting files: exact blobs retrieved from host `01575aafc3f5b9032900bb57520ee65e98d7546c`.
- The old local checkouts had been removed. Eleven necessary source/fixture files were restored into an isolated temporary directory from the exact GitHub sources; no SDK rebuild or changes to an existing checkout were needed.
- Git blob hashes of all eleven provided files were verified before and after execution and matched their expected identities.
- Started: `2026-11-14T08:59:04.619768+00:00`.
- Command: `python3 -m unittest tools.android_qa.tests.test_update_2019_preservation.StudioUpdateWrapperExecutionTests -v`.
- Actual result: `Ran 3 tests in 0.043s`, `OK`, exit 0.

The executed methods cover the original successful metadata-to-device-boundary case, all ten original identity-negative subcases, and the added reviewed-2020/unreviewed-2019 configuration rejection subcases. The actual wrapper, unchanged reviewed-source policy, and original shared runner/identity validator files were used as described in the preceding checkpoint.

`wrapper-tests.raw.log` preserves the merged stdout/stderr of the actual unittest process. Its SHA-256 is `adaa65538f90fbe0d97e9825e59fc6c29c5f2783c1496335e94fc4df0016c354`.

`execution.json` records the precise interpreter/version, command, timestamps, exit code, source blob identities before and after, and log digest.

## Scope

Only these three test methods ran. The original CI failure remains documented; this local follow-up is not a full Android-QA-suite, full candidate CI, APK, emulator, or Play acceptance result. The newly combined candidate still requires its actual complete CI run.
