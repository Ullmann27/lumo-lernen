# Original full Flutter acceptance and Diktat input-finder repair

## Original run

- Repository/source: `Ullmann27/lumo-lernen@7fd9e91683ecf703c00f100e314aced9191f7847`.
- GitHub Actions run: `43579007561`, attempt 1, job `132400677288`.
- Artifact: `14108001389`, `lumo-candidate-all-flutter-tests-and-captures`.
- Original ZIP: 332442555 bytes; SHA-256 `9f5ca0444df87b1cc1758d330d283e26b5f415897b03805975306cd9f85e1eee`.
- Result: **2612 passed, 3 failed, 0 skipped, 0 capture-error files, 546 PNGs**. This is a failed full acceptance run.

The ZIP was downloaded once and its exact size and SHA-256 were checked. `acceptance-summary.json` is the unmodified archived summary. `failed-tests-original.json` preserves the original testStart metadata and print/error/testDone events for each of the three failed tests, extracted from the archive's complete `flutter-machine.jsonl`. The original ZIP and complete machine log were retained locally at `/tmp/lumo-ci-43579007561-909ddb52fe7b/`; the GitHub artifact remains the source for all unmodified logs and rendered images.

## Shared failure cause

All three failures throw `StateError: Bad state: No element` in `_revealWrittenWord`, at the old `tester.drag` call in `test/learning_modules/deutsch_sach_module_progress_test.dart`. The helper searches for a `GestureDetector` with pan callbacks. The integrated production Diktat rows use `LumoInkSurface`, so the old finder is empty before any answer or reward assertion executes.

Original test blob: `c794b4239d1d402b3084a67ba49ea81d28d8d4a3`.
Production Diktat blob: `aab44260ac43b595dc1d8cd781a70f8953828d88`.

## Minimal repair

Only the test helper changes. It locates `LumoInkSurface` inside the actual `WortDiktatScreen`, ensures the row is visible and hit-testable, then performs the same real pointer drag and completion tap. No private callback is invoked and no answer/progress/reward state is injected.

All exact subject/topic persistence, duplicate self-rating, correct/wrong answer, two complete twenty-word sessions, earned bonus, and Daily checks remain intact. Product handwriting and reward code is unchanged.

## Validation boundary

The modified Dart test parsed successfully using the existing Dart SDK. The repaired helper has not yet run under Flutter at this checkpoint; it must pass in the final combined host CI. Do not recast the original three failures as passing.

The original complete machine log independently confirms that the twelve drawing/learning regression files passed all 75 tests, the atmosphere file passed all 10 tests, and the three new Connect Four scroll-alignment cases passed, each with zero skips. These scoped results belong to the original `7fd9e916` run.
