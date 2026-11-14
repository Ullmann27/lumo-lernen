# Memory durability and reading evidence corrections

Snapshot: 2026-11-14 18:06 UTC. This is source integration evidence, not a test-success record.

Host commit `28462a7547048b75fa114e6f5832248e54c94faa` is on `chatgpt/lumo-nextgen-feature-20261114`, draft PR [506](https://github.com/Ullmann27/lumo-lernen/pull/506). Parent b721 remains the current Studio candidate until the new Feature gates pass. Native remains pinned to `29080ef8cd1a5b385eeeec97976fbefd31280427`.

The complete recursive tree comparison found exactly two changed product files and two new tests, 4,365 unchanged existing file leaves and no deletion. Both Main refs were checked before integration and were not mutated. The Feature ref moved by an expected-SHA lease with `force:false`, followed by an exact post-ref read.

## Confirmed source problems and corrections

Memory's original adapter read the legacy SharedPreferences optimistic cache. Version 2.5.5 sets that cache before the platform write response, so a failed write could satisfy the controller's subsequent equality check. Every patched round/statistics read now awaits successful platform reload, including a new adapter/controller over the same singleton. A reload error propagates. Genuine commit-then-error recovery remains available through the unchanged controller. Rules, keys, schemas, owner checks and reward identities remain unchanged.

The report/planning engine previously interpreted unconfirmed ASR alignment, retained words and assistance counts as reading competence, including summaries without a current-child selection. It now derives competence from the existing SkillRecords and offers a neutral reading routine. Raw saved summaries, legacy JSON, input callbacks and public method signatures remain unchanged. Genuine assessed successes and errors still guide practice.

## Tests and boundaries

Fourteen Memory platform/cache/profile tests and ten reading-evidence tests are newly prepared. They were not executed locally. [Actual Feature run 43624674585](https://github.com/Ullmann27/lumo-lernen/actions/runs/43624674585) has started; its result must be recorded separately. Independent peer reviews report no further concrete blocker in these deltas, not an executed PASS result.

No physical-device durability, audio playback, Fold7 performance or release approval is inferred. The full Studio APK and Android gates still apply after successful development integration. Historical b721 captures remain evidence of the unchanged Native source, with their original Host revision retained.
