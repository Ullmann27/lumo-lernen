# Rooms / Cards producer handoff boundary

Observed read-only at 2026-11-13T13:15:55.105537+00:00; integration host `95efd9bfe47b4d1a0575673f7111ea2203804eed`.
No producer worktree was changed, no WIP source or image was copied, and no new
producer implementation was tested or merged during this inventory.

## Actual local delivery points

| Producer worktree | Local branch | HEAD | State |
| --- | --- | --- | --- |
| `/workspace/scratch/777ac99b0ad0/lumo-lernen` | `chatgpt/lumo-game-rooms-20261113` | `3c712129fef8f144d8946fad567b9ed11c628a60` | Clean; no newer host product commit |
| `/workspace/scratch/777ac99b0ad0/flutter-rooms` | `chatgpt/lumo-cards-cup-20261113` | `3c712129fef8f144d8946fad567b9ed11c628a60` | One untracked widget and one untracked before-image |
| `/workspace/scratch/777ac99b0ad0/flutter-delivery` | `chatgpt/lumo-kart-graphics-apk-20261113` | `a4f1aa9f9d244e365656f293ea13a5153e9c9853` | Clean local QA/workflow commit; no new Cards product files |

The two Rooms/Cards branch refs returned `422 No commit found` in direct GitHub
queries. Their related branch searches and the current updated-PR inventory did
not identify a published producer handoff. The exact local delivery commit
`a4f1aa9f9d244e365656f293ea13a5153e9c9853` also returned `422 No commit found` when
queried directly. There is no established new PR/CI identity for these inspected
deltas; they must not be reported as delivered through an existing product PR.

## Cards stage: concrete missing connection

The untracked file is
`lib/features/games/lumo_cards/widgets/lumo_cards_cup_stage.dart`:

- 12,372 bytes; Git blob `89343ef3682b19f815aefe028edfdd5560b1b43a`.
- SHA-256 `da2e0f3aa578dff7a256587c897b19a57536331437955df5ec0da819110a4b72`.
- It declares `LumoCardsCupStage`, a painted room using the existing original
  `LumoCharacter`, the saved `LumoCardsCup` result, and three noninteractive
  round indicators. It accepts `cup` and `reduceMotion`.
- Searching both `lib` and `test` for the class or its filename finds only its
  declaration. No production import, constructor call, or new test uses it.
- `LumoCardsCupScreen` still uses its original trophy icon and three list rows.
  Its source is byte-identical to the current integration host, as are
  `LumoCardsScreen`, the Cup model, game controller, session, `LumoCharacter` and
  design-system dependencies.

The only local image is
`docs/evidence/cards-rooms-20261113/cup-gold-before.png` (114,224 bytes;
SHA-256 `2980ad5282394c84465073427f2f3f99a64e7adb89f8ce648e6e5bd704ad56c4`).
No accompanying final after-image, source-bound report or new test log was
present in that directory. Its existence does not establish completion of the
unwired stage.

**Handoff boundary:** wait for a producer-published immutable commit that
contains the intended Cup-screen import/use and its focused visual/state tests.
The new file alone is not a connected feature. It currently introduces no
textual collision with Studio, Bauwelt voice, or the host's existing Cards code.
The Android tour's responsive Pokal/Grand-Prix labels are owned separately by
the integration pipeline bot; any later actual producer UI change must be
compared with those selectors after publication.

## Local 2019 delivery preparation

The local `a4f1aa9` commit is based on `8eab228433f124c1e2332e3d3c2ecf462ec8b136`
and changes these eight files:

- `.github/probes/lumo_2003_update_android_probe.py`
- `.github/probes/lumo_2019_surfaces_android_probe.py` (new)
- `.github/probes/lumo_2019_update_android_probe.py` (new)
- `.github/probes/lumo_nextgen_surfaces_android_probe.py`
- `.github/workflows/lumo-unified-integration-2026.yml`
- `tools/android_qa/tests/test_update_2019_preservation.py` (new)
- `tools/android_qa/tests/test_update_preservation.py`
- `tools/android_qa/update_preservation.py`

Its subject is `build(android): add explicit 2019 update and surface entrypoints`.
This is local delivery preparation, not a new Cup implementation or an accepted
2019 APK. The existing Nextgen probe and Unified workflow overlap integration
owned QA surfaces and require a coordinated patch review if this commit is
published. No files from it were applied.
