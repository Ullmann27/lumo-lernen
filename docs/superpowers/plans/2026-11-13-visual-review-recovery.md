# Visual review recovery implementation plan

**Goal:** Record corrected Build 2018 renderer evidence without overwriting previous originals or weakening release gates.

**Architecture:** Keep the existing source-bound archive, CI, image and module checks. Give each copied PNG a deterministic filename containing its full SHA-256, rather than its position in a review selection. Identical images can be reused; changed pixels get a distinct immutable file. No changes to app code, profiles, version, native pin, existing review records or APK workflows.

**Tech stack:** Existing Python standard-library review recorder and unittest regressions.

**Scope:** scripts/record_nextgen_visual_review.py, one new test module, isolated support CI and handoff documentation. Base a31c0070; current native candidate ada5ed81. Main and product integration remain untouched.

## Executed steps

- [x] Read live PRs, continuation constraints, recorder and verifier; verify new native artifact digest/CRC.
- [x] Create isolated branch and exact-source reproduction workflow.
- [x] Run new tests against unchanged recorder: actual four failing cases in run 43406783909; original log retained.
- [x] Replace ordinal-based image names with full content-hash names; preserve collision and release validation checks.
- [x] Run targeted Nextgen contracts: 22/22 passed in run 43407405933.
- [x] Run the complete script suite: 312/312 passed with no skips in run 43407676499, including the targeted 22; source hashes and tracked diff unchanged.
- [x] Inspect one genuine current portrait Cards image; no complete native visual review or Android claim.
- [x] Secure code, exact run/job/artifact identities and draft PR463 against the active development branch.

## Remaining boundaries

Full real-image review and the new APK/Android/update acceptance belong to concurrent product integration #461, now at 3c712129. The local tool failure prevented further real-archive recorder execution; synthetic tests do not replace that visual review. Independent PR review and incorporation are still open. Do not cancel or restart the active APK build to incorporate this support-only patch.

## Review focus

Different native commits with changed images; same-source rerenders; reordered selections; historical ordinal-named originals; tampered existing files; failed/expired/wrong-source evidence; incomplete scene coverage. Tests cover every listed case. Synthetic fixtures are never product screenshots or release approval.
