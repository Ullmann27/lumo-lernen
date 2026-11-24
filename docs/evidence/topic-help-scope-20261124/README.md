# Topic and offline-help correction, 24 November 2026

Base: `6e7b26906a15c8497cb36cf8c1d0c2126740658c`, the existing PR #545.
This patch preserves that exact Plus bis 100 routing correction.

## Confirmed and corrected

- Essay suggestions contained fraction questions; word-problem suggestions contained unrelated million-number questions.
- The million-number context exceeded its own upper bound. The word-problem example now illustrates three dependent calculations.
- The `s4_europa` ID is retained, but its context, local generated questions and academy subtitle now match the actual selection, Kontinente und Ozeane. Every locally offered geography question has a dedicated offline answer; the unrelated capitals dictionary stays excluded.
- Beginning reading combines sounds instead of spelling the letter name Em.
- Scoped offline questions no longer search unrelated subject dictionaries. A German article question containing Hund no longer triggers an animal fact.
- Requests such as ich weiss es nicht no longer produce a random riddle solution without an associated question. Missing-question requests ask for the exact task/riddle wording; an explicitly supplied known riddle is answered without shared child/session state. General unscoped conversation and relevant scoped dictionary/calculator replies remain available.
- The teacher fallback calculator is restricted to Mathematik; its generic introductory language no longer assumes every topic is arithmetic.

## Actual verification

`dart test/learning/topic_context_scope_regression.dart` was executed on the unchanged base sources and then on the patch using the already installed Dart 3.12.2 runtime. Original output is in `before.log` and `after.log`; exact source hashes and limits are in `result.json`.

- Base: 57 failed assertions out of 64. Thirty assertions cover variants of the same geography error; assertion counts are not counts of separate defects.
- Patch: all 64 checks passed.
- Dart analysis of lumo_brain.dart, topic_curriculum.dart and the regression script: no issues found.
- Both changed Flutter widgets were parsed by the Dart formatter in output=none mode. This does not replace Flutter type checking or widget execution.
- `git diff --check` passed.

## Remaining integration work

No complete Flutter widget run, APK build, emulator tour or device verification is claimed. The test script is a standalone Dart regression and is not automatically picked up by flutter test. Run it explicitly alongside the existing PR #545 widget tests.

This is a bounded repair, not a complete review of every task or pedagogical approval. Mathematics needs a further exact-topic/range audit inside its subject. TopicContext.buildPromptHeader currently has no caller; the teacher cloud request passes subject, grade and title, but not the full detailed scope. The current primary academy routes essays to the writing coach; the corrected essay suggestions belong to the separate teacher context. Writing coach, journal, profiles, learning records and game code were not changed.
