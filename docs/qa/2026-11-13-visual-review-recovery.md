# Immutable visual-review recovery

## Scope

Support PR https://github.com/Ullmann27/lumo-lernen/pull/463 is based on host `a31c0070a9c1e9dfbea08f123d7ed77e5f0a8ad9`. It does not change the app, original assets, child profiles, version, native pin, release validator, committed visual approval, or active APK workflows. Main and the concurrent product integration remain untouched.

## Reproduced problem

`record_nextgen_visual_review.py` used a review-position prefix for copied screenshots. A corrected capture with the same basename then hit the intended no-overwrite guard; changing selection order also renamed unchanged images. Historical original files must not be deleted to work around this.

Actual red source: `019cefec085ea39215c8891e39b07202830abaf9`.
Actual CI run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43406783909
Job `131822933804`: 22 tests, 1 assertion failure and 3 ValueError errors reproducing filename collisions; 0 skipped. All fourteen pre-existing Nextgen delivery/workflow tests passed. Original log artifact `14027971482`, SHA256 `97676a83d45df64c69ce6716300c2b985209364b15c1fc0fe4f6a6a7fdcdb633`.

## Minimal repair and verification

Commit `b82ad63627919323c5bfbdcfecd0b8b94ab741f7` names each copied PNG using its module, full SHA256 and original basename. Corrected bytes get a new path, unchanged bytes have stable paths regardless of selection order. Historical ordinal-named originals stay untouched. All original exact-source, clean-source, archive digest, CI status, image/dimension, coverage and destination integrity checks remain.

Actual targeted green run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43407405933
Job `131825016222`: 22/22 tests passed, no failures or skips. Source is exactly `b82ad63627919323c5bfbdcfecd0b8b94ab741f7`.

Actual complete script-contract run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43407676499
Job `131825911193`: **312/312 tests passed in 33.818 seconds, no failures or skips**, on exact source `21f9920ca098f35b6969881d6a3cee9464607641`. The same job separately reran the 22 targeted tests; they are included in the 312 and are not added again. Existing production Java/Kotlin store checks and the actual verified Gradle contract ran. SHA256 readback of recorder, unchanged release validator and new test file passed; `git diff --exit-code` passed. Artifact `14026879870`, 11521 bytes, reported ZIP SHA256 `28c129c91290977341dd23371aa9e601aebff2d9f1ae1c70d3b5f7c12ad7e66e` contains the original test logs, tested source SHA/tree and source-file hashes. Unlike the earlier native ZIP, this small proof ZIP was not independently downloaded/hash-checked in the unavailable local container; its digest is the actual upload log value.

Eight new regression methods cover changed-source captures, same-source rerenders, reordered selections, historical files, idempotence, corrupted destination bytes, invalid evidence and incomplete module sets. The PNGs and CI JSON in these tests are explicitly synthetic storage fixtures, not app screenshots or Android evidence.

## Review and integration limits

The read-back diff against a31 contains exactly five files: the recorder, its new tests, the isolated read-only CI workflow, this report and the plan. No Dart, Kotlin, Godot, profile, version, nativepin or actual release-approval file changed. Recorder code was also reread on the concurrent product head `3c712129fef8f144d8946fad567b9ed11c628a60`; its original blob remains `3b369bf85aa5f74ab487ce8ae2e082173fb6f6c3`, so the fix remains relevant. A separate reviewer has not approved this patch; PR463 stays a draft and unmerged.

Local container execution became unavailable; tests were executed on GitHub-hosted runners. Native `ada5ed81ad62339f15289da62670c0a4f9f7f2b9` run `43399721309` completed successfully. The original native archive `14026025798` was downloaded and independently checked for SHA256 and ZIP CRC before the local tool failure. Only the portrait Cards screenshot was visually inspected in this support session; no complete new visual approval is claimed.

Product integration #461 has advanced separately to `3c712129fef8f144d8946fad567b9ed11c628a60` and runs complete APK/Android/update acceptance in `43405216014`. This support patch must not cancel that run, replace its newer source, revive the withdrawn a31/51fb APK, or imply an Android release. Incorporate the minimal recorder/test changes at the next safe integration point; preserve the current native pin and all existing acceptance gates. There is no merge to main in this work.
