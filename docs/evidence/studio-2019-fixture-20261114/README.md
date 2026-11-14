# Historical 2019 update-wrapper fixture repair — 2026-11-14

## Original CI failure

- Tested host: `01575aafc3f5b9032900bb57520ee65e98d7546c`.
- [C4 run 43576227541](https://github.com/Ullmann27/lumo-lernen/actions/runs/43576227541), attempt 1.
- [Job 132391949339, verify-and-build](https://github.com/Ullmann27/lumo-lernen/actions/runs/43576227541/job/132391949339).
- Failed step 22: `Code-level Android probe regression with verified image dependencies`.
- Prior build-script suite: `Ran 872 tests in 237.077s`, `OK`.
- Android-QA suite: `Ran 928 tests in 73.704s`, `FAILED (errors=11)`.

All eleven errors originated from the two existing methods in `StudioUpdateWrapperExecutionTests`: the positive case and all ten identity-negative subcases. Each stopped at the real 2019 wrapper's version check with `ValueError: This update proof requires candidate version 2019`, before reaching the intended APK identity validation.

`original-ci-failure-excerpt.log` contains the exact contiguous failure section and final suite result extracted from GitHub's decoded original job log. It is an excerpt, not a replacement full log or a new execution result.

## Cause and narrow correction

The historical test read its candidate native pin from the running checkout's `config/godot-source.json` and executed the wrapper at the running checkout path. On the tested 2020 source, the wrapper therefore read `version: 0.13.8+2020`. The production check correctly rejected this input for a 2019 update proof.

The test now copies the real wrapper and real reviewed-source policy byte for byte into a temporary historical source root. That root supplies `version: 0.13.7+2019`, the approved repository/engine fields, and the existing reviewed 2019 native pin `17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845`. The copied production policy remains unchanged and validates this pair. No `APPROVED` assignment or policy override is added.

The existing helper still loads the real shared 2003 runner from the repository and exercises its real identity validators. The original synthetic metadata files remain explicitly labelled as non-APK fixtures. Android I/O remains blocked at the existing boundary.

All ten original identity-negative cases, their assertions, the original positive assertions, and the migration-parser tests are unchanged. The existing execution helper changes only the wrapper path to the temporary historical root.

One additional test runs the actual wrapper entry point against two invalid configurations: a valid reviewed 2020 pair, whose pin is read from the unchanged policy, and an unreviewed 2019 pin. Both must raise their specific real `ValueError` before a strictly blocked update runner can be invoked. Neither test can establish Android acceptance.

## Exact source identities and review

- Original test Git blob: `fdafce627a7399fa30d7bae933afe779f8ff3365`.
- Repaired test Git blob: `b9c667de8d9d9fd3ec158141d17d09d899aea2b6`.
- Unchanged 2019 wrapper Git blob: `7a59bf3842b49737115005c452e36565582b6410`.
- Unchanged shared 2003 runner Git blob: `f8afca6f798fd4c309ee97737a2fcb983081d65a`.
- Unchanged reviewed-source policy Git blob: `28f3aee40eb0028c5a4aa80196749f5867cbffc4`.

An independent agent retrieved the original and candidate test blobs from GitHub and found no concrete blocker. Its source comparison confirmed preservation of the original cases/assertions, correct temporary ROOT resolution, unchanged copied policy/wrapper bytes, original shared runner, and restoration of patched module/environment state.

## Execution status

The local runtime was unavailable during this repair. No local Python invocation, compilation, test pass, APK execution, or Android result is claimed for the repaired source. The next actual CI run is required to establish execution results.
