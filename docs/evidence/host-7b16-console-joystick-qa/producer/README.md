# Isolated Console and portrait-joystick diagnostic hookup

This package is a scratch-only patch against the published Host checkpoint `21f7fbe6d378003d46b6d266eff9fdb91bc398b9`, tree `5a938c9bb82e3f966babd86adb26aceb0ae5f759`. It does not change a worktree, Git index, branch, pin, receipt, APK, or running workflow. Root owns applying, committing and publishing the eight listed source files.

## Exact new route

The new `.github/workflows/lumo-console-joystick-7b16.yml` is restricted to the internal branch `qa/lumo-console-joystick-7b16-20261114`, targeting `integration/lumo-connections-20261113`; manual dispatch is restricted to the same exact branch. The contract job gates all four device jobs. The three API37 cases keep the previous host, SwiftShader and SWANGLE hardware, package, APK/PCK, framework, continuous ANR and timeout requirements. A separate API35 Creative job runs the complete Jump, Build, Puzzle and Treasure tour. The previously successful main API35 and 2017-update cases are not repeated here.

The input is the unchanged APK from Host `7b16f2f5ab16f3d913ee170aefd9807c87216260`, original run `43540111465`, artifact `14093773196`, with Native `17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845`. QA source is independently checked out and bound through original current-run/job metadata. No new APK is built or released by this workflow.

## Console wiring

Every device job prepares one new private directory and calls the actual Console `prepare` CLI before starting its emulator. `runner.temp` is used only in the valid step-level environment. The exact socket is `$RUNNER_TEMP/lumo-serial-$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT/console.sock`; it is propagated through `GITHUB_ENV` and passed to the emulator as `-shell-serial unix:<same path>,server,nowait`. The original `prepare.json` is copied into the uploaded evidence before the emulator step, so an emulator failure before launch does not lose that receipt.

The Console implementation, Android17 framework adapter, runtime shell wrapper and its `begin`/`finish` sequence are unchanged. The Creative API35 job also retains its prepare receipt, but no API37 continuity claim is inferred from that preparation. Actual emulator support, QEMU peer identity, logger survival through `adb root`, renderer behavior and final ANR acceptance must still be observed in the new device run.

## Minimal explicit routing changes

- `verify_unchanged_apk_diagnostic.py` adds four exact new workflow/branch/job mappings. All existing mappings and verification functions are preserved.
- `run_unchanged_creative_diagnostic.py` accepts only the historical or the new exact Creative job through an optional CLI argument. Its default remains the historical job. The original metadata and all three source roots are rechecked before any tour input.
- `export_creative_evidence_parts.py` adds only this workflow as another diagnostic route. It retains schema 2 and `probe_source_sha`, preserving the distinction from the original APK source. Limits, complete snapshot checks, hashes, and byte copying remain unchanged.

`qa-hookup.patch` contains these three files, the new workflow and its focused tests. `auto-trigger-exclusions.patch` is separate: it adds only an exact new-branch exclusion to the old unified full build, broad Astra script suite and old Cards-route Flutter QA. Existing branch guards remain, and unrelated branches (including same-prefix names) keep their behavior. The older isolated QA workflows are untouched.

## Validation and its boundaries

The actual old metadata and parts-export validators reject the new route; the two original failures are retained in `validation/original-route-rejections.json`. The new route and negative cases execute in the real modified validators. Eleven new focused tests passed, including real execution of the prepare shell block, retention without emulator launch, exact route separation, genuine duplicate/missing-job rejection, and a byte-complete tiny exporter roundtrip.

The final supported local selection executed **125 tests, zero failures, errors or skips**, including all eleven new tests, seven portrait tests and the existing relevant Creative/transport/routing contracts. One additional existing preflight is **not claimed locally successful**: it requires a genuinely committed helper and the explicit scratch test overlay has no Git checkout. Its original failure is preserved in `validation/focused-contracts.log`; it is not mocked, weakened or skipped in the committed workflow. The initial missing historical Creative fixtures were then materialized from 84 exact published Git blobs (9,838,524 bytes), solely in the scratch test view, and the corresponding tests passed. No download was used.

The new CI runs the **entire unfiltered five-module Console suite: 86 methods, including all three real AF_UNIX cases**, followed by all seven portrait tests. Exact counts and plain `OK` are required; skips cannot pass. Local discovery confirms those 86/7 names. The three real Unix cases retain their previously documented local EPERM boundary and require actual CI execution. The subsequent existing diagnostic and Creative suites retain their full preflight checks and no-skips requirements.

Actionlint passed for all four changed/new workflows. Source hashes stayed unchanged during validation. These results establish local contract and workflow consistency only, not a fresh Android, renderer, functional, visual, or FPS pass.

## Files to apply and frozen evidence

Use only `final-source/` paths listed in `source-freeze.json`, preserving their exact bytes. `handoff.json`, `manifest.json` and `SHA256SUMS` bind the patch, inputs, validation logs and final source. `runtime-preservation.json` binds unchanged runtime dependencies to the published checkpoint. `test-view/` is an auxiliary disposable scratch test copy, including referenced/materialized historical fixtures; it is not part of the source patch or compact frozen evidence package and must not be copied into the repository.
