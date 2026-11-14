# Native 17f5 and Host Android repair integration

This integration connects the current reviewed Native source and repairs concrete
failures observed in the previous Host and Creative Android runs. The protected
production branch and historical release pins remain unchanged. This branch does
not publish an APK.

## Connected behavior

- Native is pinned to `17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845` in the source
  configuration, the 2019 release policy and its tests. Earlier release pins are
  preserved. The current Nextgen and Graphics visual receipts bind that same
  exact source.
- The strict Nextgen contract now requires all 48 core probe/mode passes, the
  original Village and Puzzle lifecycle captures, seven safe-area captures,
  three Cards layout sidecars and both original safe-area reports. Cards layout
  evidence is mandatory for the 2019 Graphics delivery as well.
- The garage return uses a fresh, stable complete footer observation and a
  bounded stationary input before requiring the actual landing screen. It does
  not substitute a guessed landing state for the failed original navigation.
- Android 37 readiness requires consistent framework/window state and a stable
  ready interval, rejects system ANRs, and avoids the unconditional post-check
  MENU input that appeared in the failed original emulator setup.
- Creative gameplay uses the current build artifact, upload digest, Host source
  and Native source from the same workflow run. Puzzle selection, Jump control
  selection, game orientation and Treasure approach/deadline handling use the
  observed live UI and original save data. The decision deadline is not described
  as a hard whole-process timeout.
- Both 2019 workflows retain the original complete Creative evidence upload and
  add deterministic bounded exports. Each part contains original byte copies and
  an identical complete index. These exports are their own stable snapshot after
  the full upload; equality with an earlier full ZIP is not assumed.
- The Spielwelt portal exposes its existing open action through semantics. The
  read-only fold-device collector is connected with its existing provenance and
  installed-identity checks. No writing-trainer, journal, asset, Android app source
  or package-version changes are part of this Host increment.

## Verified before this Host commit

The actual Native Nextgen run
[43532048311](https://github.com/Ullmann27/lumo-godot/actions/runs/43532048311)
completed all eight jobs successfully. The final original bundle contains all
48 required core passes, six touch probe passes and the required original
capture/report sets. Its 3,265 members match the complete Worlds/Touch union.
The public archive was created and its observed bytes are bound by SHA256;
the release API reports `immutable=false`.

The actual Native Graphics run
[43532048253](https://github.com/Ullmann27/lumo-godot/actions/runs/43532048253)
completed all three jobs successfully. Root directly inspected 29 current
Nextgen originals and five current Graphics originals. The existing strict
recorders wrote the receipts only after checking the selected original bytes.
The findings retain scroll viewport clipping, ellipses, wrapped text and
background occlusion rather than treating every visible detail as flawless.

The final complete local `scripts/tests` discovery passed **574 tests with no
errors or skips**. All 1,383 hashed source/fixture/review-image files and the
local HEAD stayed unchanged during that run. The earlier combined local run's
**870 Android-QA Python tests** passed; that suite was not unnecessarily repeated.
Its original result and the initially failing scripts result remain preserved.
Targeted repairs and independent reviews are included in the evidence packs.

The 90-minute Host build budget remains unchanged. A measured comparison of the
old and new corresponding Native sequences gives a conditional 76:25.9 total
only if every other old Host phase remains unchanged. That calculation is not a
prediction or guarantee for the new runner.

## Evidence map

| Directory | Preserved evidence |
| --- | --- |
| `host-studio-repairs/` | Earlier concrete failures, repairs, original local suites and source reviews; lossless two-part transport of the complete evidence archive. |
| `host-studio-followups/` | Later producer countercases, bounded producer observations and transport records. |
| `native-17f5-acceptance/` | Current actual Native run identities, original logs, strict verification and original-archive bindings. |
| `root-17f5-visual-review/` | Root's exact per-image observations, original metadata, previous receipts and current recorder results. |
| `creative-parts-and-budget/` | Additional complete archive exporter, 20 focused tests, independent review and observed budget comparison. |
| `final-scripts-gate/` | The final 574-case local suite, complete original log and source hashes before/after. |

The production receipts retain original content-addressed images under
`docs/evidence/nextgen-2019-reviewed/` and
`docs/evidence/kart-graphics-2019-reviewed/`.

## Still required on the newly published Host source

Actual Android API 35 and API 37 execution, the complete 2017-to-2019 upgrade,
Creative gameplay and the final delivery verifier must run on this new Host
commit. The actual additional Creative artifacts must be checked for digest,
size, common index and full membership. Local Python tests and native software
renderer fixtures do not establish Android input, device insets, performance or
release acceptance. Historical failed runs remain failed.
