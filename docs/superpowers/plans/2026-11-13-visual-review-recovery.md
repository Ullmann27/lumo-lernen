# Visual review recovery implementation plan

**Goal:** Record corrected Build 2018 renderer evidence without overwriting previous originals or weakening release gates.

**Architecture:** Keep the existing source-bound archive, CI, image and module checks. Give each copied PNG a deterministic filename containing its full SHA-256, rather than its position in a review selection. Identical images can be reused; changed pixels get a distinct immutable file. No changes to app code, profiles, version, native pin, existing review records or APK workflows.

**Tech stack:** Existing Python standard-library review recorder and unittest regressions.

**Scope:** scripts/record_nextgen_visual_review.py, one new test module, isolated support CI and this handoff. Base a31c0070; current native candidate ada5ed81. Main and product integration remain untouched.

## Steps

- [x] Read live PRs, continuation constraints, recorder and verifier; verify new native artifact digest/CRC.
- [x] Create isolated branch and exact-source reproduction workflow.
- [ ] Run new tests against unchanged recorder and retain the actual failure log.
- [ ] Replace ordinal-based image names with full content-hash names; keep existing destination collision checks.
- [ ] Run all Nextgen contracts and the full available script suite; report failures or skips explicitly.
- [ ] Verify real ada5 archive selection with unchanged release validator and inspect current original pictures.
- [ ] Secure code, test outcomes, source hashes and a reviewable PR against the active development branch.

## Review focus

Different native commits with changed images; same-source rerenders; reordered selections; historical ordinal-named originals; tampered existing files; failed/expired/wrong-source evidence; incomplete scene coverage. Tests cover every listed case. Synthetic fixtures are never product screenshots or release approval.
