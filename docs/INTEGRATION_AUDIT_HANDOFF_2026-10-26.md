# Lumo integration audit handoff · 2026-10-26

Branch: `sol/lumo-writing-repair-20261026`, based on `26fced8f`.
The user requested immediate completion before implementation began. This
handoff records source findings only; no application or test source changed.

## Confirmed source findings awaiting repair

1. **Photo quiz opens speech instead of the camera.**
   `lib/features/live/lumo_live_pro_screen.dart:773` always binds the action to
   `_startListening`, although the photo mode labels it “Foto machen” at line
   780. `_capturePhoto` at line 343 has no caller and is the only writer of
   `_capturedImagePath`. Reproduction: open LIVE, select Foto-Quiz, press Foto
   machen. The current action enters microphone capture instead of taking a
   photo. A bounded repair needs both phases: take the initial photo, then
   offer speech answers once a photo exists. A camera-only replacement would
   leave the answer action inaccessible.

2. **Enrolled fourth-grade essays open single-letter practice.**
   `lib/features/teacher_mode/lumo_akademie_screen.dart:1182` routes
   `d4_aufsatz` to `LumoWritingCoachScreen`, whose default at
   `lib/features/writing/lumo_writing_coach_screen.dart:93` is uppercase letter
   practice. The existing authored text editor is reached at academy line
   1044 only when the selected grade differs from the enrolled grade.
   Reproduction: enrolled grade 4, Lernen, Lernatelier, Aufsätze. The existing
   `test/academy_exact_topic_units_test.dart` verifies the text editor directly
   for enrolled grade 2, but does not test this actual grade-4 academy route.

3. **Single-letter writing help is not marked in the school record.**
   `lib/features/writing/lumo_writing_coach_screen.dart:274` records an answer
   without `hintUsed`, so it defaults to false. The same screen offers “Lumo
   zeigt” at line 675 and can display a corrective demonstration. No durable
   help flag is carried into the answer. Reproduction: show the demonstration,
   then write and submit that letter; the recorded attempt reports no help.
   The word coach already carries `_currentLetterHintUsed` / `_wordHintUsed`
   and provides a local comparison for a small repair.

## Checks actually performed

- Read the navigation routes, writing/reading/journal repositories, learning
  owner capture, module save/retry boundary and relevant existing test sources.
- Read `/tmp/lumo-analyze.log`: 59 diagnostics; the unused `_capturePhoto`
  warning corresponds to the missing link above.
- Created this isolated worktree and ran `flutter pub get` successfully.
- **No Flutter test, analyzer or Android runtime run in this audit worktree.**
  These findings are not presented as runtime-verified failures.

## Limits and further observations

- Existing narrow Spielwelt code places logo, fox and adventure button before
  the first portal. At width 360 its fixed pre-grid content is about 465 dp,
  plus container padding. `GamesContent` supplies scrolling. Existing
  `test/design/parent_games_polish_test.dart` covers cover/Fold/tablet sizes and
  large text while using `ensureVisible` for Kart and Meister. This audit did
  not prove an unreachable portal or run a layout test.
- Writing progress and the personal journal use existing global preference
  keys. They were read only; no migration, deletion or ownership redesign was
  attempted.
- LIVE photo responses award stars/XP/Cosmos without checking answer content
  (`lumo_live_pro_screen.dart:366`). This is existing conversational reward
  behavior, not a newly verified school-assessment defect. No new evaluator
  was designed or implemented.
- Root owns the integrated test suite, APK delivery and all remaining repairs.
  No merge to main was performed.
