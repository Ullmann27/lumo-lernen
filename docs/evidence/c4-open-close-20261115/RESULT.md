# C4 native opening cancellation — original results

## Scope and source

Support branch: `support/lumo-c4-open-close-20261115`.
2023 base: `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`.
Product change: `2d8f311427097aa4fccd5f93f1bb075b45d88553`, one product file only: `lib/features/games/connect_four/connect_four_table_session.dart`.
Old blob: `fd8efe8e114de656b6802e097b96910535d83c39`; new blob: `f5c6befc9ab6d29535b29959a027df4efd4e7246`.
The old blob was independently read back on NextGen head `c5a4430f468df75ee927dbfc7e0e8e0868795e81`; the isolated change therefore does not replace another team's intervening C4 edits.
Native pin remains `d38967f6d39bc20188afe525b0af122d80634029` (Godot 4.6.3). Version, package, signature policy, original game rules, all controller/persistence/reward methods, writing trainer, journal, Kart/Jungle, Memory and Quiz product files are unchanged.

## Actual red run before implementation

Workflow run `43743047560`, job `132900203257`, source `3b1aafe9d90ee37bc80faecf419a7726b39631fa`:
- New test file compiled and executed on real Flutter 3.44.9.
- Eight visible tests: **2 passed, 6 failed, 0 skipped, 0 test errors**.
- Failures: cancellation during settlement; late Open after Close; concurrent Open; lost Open acknowledgement leaking the native token; Open overtaking pending Close; a second Close returning before cleanup.
- Original controls (profile revocation and exactly one legitimate game move) passed.
- The production session was still the unchanged old blob. Tests were not weakened after their failures.
- Original ZIP artifact `14172687716`, 1,802 bytes, SHA256 `d5335f30ae1d97c44b845259affcd81ce6b67712684afc9fd3362aa65c40f684`.
- Downloaded full ZIP, matched SHA256, checked all four members' CRC, parsed the original JSONL and recounted visible non-hidden testDone events. Source SHA and native pin matched.

## Actual focused green run after implementation

Workflow run `43743334086`, source `2d8f311427097aa4fccd5f93f1bb075b45d88553`:
- The **same eight tests passed**, zero failed/skipped.
- Existing session, native-route, interaction and complete-game widget groups: **34 passed**, zero failed/skipped. This includes the original C4 rules/ownership/reward/return cases as well as existing Cards and Dice whole-game checks; it is not 34 independent Android device journeys.
- Original ZIP artifact `14173107997`, 4,166 bytes, SHA256 `8da80f2e1ccacf3a8584c12b29add3ada70fff163e3cdd2f05db93a910502265`.
- Downloaded full ZIP, verified SHA256 and CRC, parsed both original JSONL files and checked exact source SHA.

## Changed runtime behavior

Opening claims a guard before its first await. Close invalidates that opening generation immediately, so delayed settlement cannot start native authority. Delayed or unsuccessfully acknowledged native Open is followed by cleanup of this exact session token; pending cleanup is awaited before the final cleanup. Concurrent opening and reopening during Close are rejected. All callers wait for the same in-progress transport close. A cancelled opening never reaches poller creation. Existing game messages and ACK processing are unchanged.

The existing policy catches cleanup transport exceptions; this patch does not represent a failed platform cleanup as independently verified native durability.

## Boundaries and remaining acceptance

The full Flutter suite is a separate mandatory job in the same workflow, followed by an internal signed APK attempt only after success. Their terminal results were not yet available when this report was committed. No successful overall workflow, current combined NextGen acceptance, physical Fold7 test, native Binder execution or ready-to-install repaired APK is claimed here.

The earlier NextGen28cb joined analysis failed on `NativeLearningActivity.fromPattern` and incompatible pattern payload dialects. That finding was passed to PR511, not bypassed here. Newer NextGen changes require their own combined validation. The user's reported device exit remains a separate device-level diagnosis: these six reproduced source races are real defects, not proof that all possible Android crashes are fixed.
