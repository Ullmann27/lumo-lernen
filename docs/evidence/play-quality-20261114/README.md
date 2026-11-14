# LUMO Play quality integration — 14 November 2026

This work is based on Host PR485 at `682f5991feb49d3a73ab7e2b42e23af725857ea9`.
The original Native pin remains `504c8ba70d02702cbccc370d0d96c36a292c5d27`.
Main and other teams' working trees are not modified.

## Real work from the delegated hierarchy

Root delegated to the release lead, who delegated to the learning/UX lead,
who delegated to the touch worker. All four performed their own work. The
learning lead and touch worker then independently reviewed the release and
pipeline changes. Four is the total simultaneous-agent limit, not a quota per
manager. No endless background agent service is represented here.

- Shape tracing now owns its pointer and keeps a surrounding scroll view
  stationary. A cancelled stroke is discarded. The original widget tests
  reproduced 90 logical pixels of page movement before the fix.
- Sidebar motion now respects calm/reduced-animation and system settings.
  Normal effects, all 14 navigation destinations and 48dp targets are retained.
- PR484's exact task-selection API and all-grade audit have been recovered.
  The 7,552 generated samples from 236 topic families have zero sampled
  structural violations. Existing `next` callers remain unchanged; this is
  not an assertion of changed UI selection or a complete curriculum review.
- Explicit Play preparation removes the APK installer permission during
  manifest merging, disables out-of-Play APK update paths and requires
  external upload-signing inputs. The family APK preparation remains default.

## Actual APK blocker repaired

Original C4 run43570629751 / job132375346358 stopped at static analysis.
All 127 errors came from four retained, incomplete historical Dart excerpts
inside `docs/evidence`, with no product-source analyzer error in that log.
The three-line analysis boundary excludes only that archive from application
analysis. Replaying the four exact original excerpts gives 127 errors before
and zero after. Deliberate type errors in real `lib` and `test` files still
fail with exit3. No production lint rule or mandatory build gate is removed.

The full existing seven-job C4 workflow also accepts this explicit quality
branch. The verifier requires the same current PR/run branch, source SHA,
run/attempt, all six successful prerequisite jobs and original artifacts.
Unapproved branches, forks and cross-branch evidence remain rejected. The
legacy generic build is excluded for this branch to avoid a duplicate path.
The workflow only prepares a verified candidate bundle; it publishes nothing.

## Evidence and open boundaries

All three isolated Flutter test groups passed: 7 + 14 + 17 cases. The combined
Python run passed 51 tests without skips. Actionlint passed both workflows
with its optional shellcheck integration disabled. The original logs and
source hashes are retained next to this file.

The local combined Flutter attempt first lacked generated package metadata;
offline locked dependency resolution repaired that prerequisite. The later
attempt encountered an unexpected Dart compiler exit after the first test
file and stalled. It was explicitly stopped with exit130. Full local Dart
analysis also crashed. These are not green combined runs, and their cause
is not established. Their original logs are retained. A fresh complete CI
run on this exact source is required.

No new signed APK, Play AAB, physical Fold7 tour, sustained60FPS or Nintendo-level
visual acceptance is claimed. The Play configuration still needs an actual
AAB and merged-manifest/certificate inspection, store declarations and review.
Native PR167 has a separate newer Treasure-visibility correction; its source
and actual rendered acceptance must be integrated/reviewed separately before
any complete graphics claim. Preserve the existing data-update gates.
