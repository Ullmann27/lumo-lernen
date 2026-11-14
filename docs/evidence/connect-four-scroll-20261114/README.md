# Connect Four: aligned 48 dp controls and deterministic Flutter fallback tests

## Exact scope and baseline

Base: `4564ad40c4d000b764e67719d19bd2445c04c870` in `Ullmann27/lumo-lernen`.
The three failures from [CI job 132380123884](https://github.com/Ullmann27/lumo-lernen/actions/runs/43572640431/job/132380123884) were reproduced locally before changes:

- The complete touch game found no enabled column while asynchronous native opening/fallback was still pending.
- The 360 × 800 visual test measured the first button at x = 48.0 and the corresponding well at x = 46.62857142857142.
- The 640 × 360 visual test hit the pause overlay instead of the mode control, then could not find column 2.

These are one production alignment defect and test fixture/timing corrections. They are not evidence of three independent production defects.

## Production change

The board and the seven column controls now share one horizontal scroll viewport and the same content width. The board's 10 dp padding plus 2.4 dp border is also the controls' horizontal inset. The minimum content width is 7 × 48 + 2 × 12.4 = 360.8 dp. Each control retains a physical minimum of 48 × 48 dp, with no overlap.

The available height still bounds the board. Wells and pieces stay circular; compact landscape layouts use wider horizontal spacing. Narrow portrait layouts first reclaim unnecessary outer padding so a 360 dp phone shows every column and arrow in the captured game. Smaller viewports scroll the board and controls together.

The shared scroll viewport clips some outer decorative board/table/glow pixels in compact landscape. All actual cells and controls remain visible in the reviewed 640 × 360 capture. This is a limited cosmetic observation, not a claim of complete visual approval.

## Tests and actual results

`baseline.log` records 10 focused cases on unchanged baseline production code and unchanged existing tests, plus the three new scroll cases: **4 passed, 6 failed, exit 1**. The failures are the original three CI cases plus all three new scroll-alignment cases at 320 × 740, 360 × 800 and 640 × 360.

`after.log` records the final source after the portrait-padding refinement: **15 passed, exit 0**. This includes:

- The full touch game, saved result/reward, replay, and restart cancelling the old bot.
- The five existing visual sizes.
- The original 320 dp Fold-control test.
- Three new scroll tests that play columns 0–6 and then return to column 0, verify their real game state, enforce 48 dp targets, full visibility, non-overlap, and unchanged 1 dp center-alignment tolerance after scrolling.
- The unchanged native-route widget test for opening, returning paused and reopening the same round.
- Four unchanged interaction tests for board taps, double-tap locking, paused bot turns, rewards and restart.

Only tests intended to exercise the Flutter fallback now explicitly make the native C4 channel throw `MissingPluginException` and wait for initialization with `pumpAndSettle`. No existing full-game/restart assertion or alignment tolerance was removed or relaxed. The separate native-route fixture remains unchanged and uses its existing mocked platform channels.

The final focused analyzer exited 0 with **0 errors, 0 warnings and 10 existing informational diagnostics**. A separate analysis of the exact baseline file confirmed the same nine brace-style infos and one async-context info; see `analyze-before.log` and `analyze-after.log`. `git diff --check` also passed.

## Reproduction and captures

Runtime: Flutter 3.44.9, framework `6b182d2c7585eba26d4edce0f97630effd256c33`, Dart 3.12.2. Lost package caches were restored with `flutter pub get --enforce-lockfile`; the host lockfile and SDK revision were not changed.

The exact final test command was:

```sh
LUMO_CONNECT_CAPTURES=/home/agent/lumo-c4-ci-2708/captures-final \
flutter test --no-pub --no-test-assets --concurrency=1 --reporter=expanded \
  test/games/games_screen_flow_test.dart \
  test/design/connect_four_visual_test.dart \
  test/games/connect_four_fold_controls_test.dart \
  test/games/connect_four_scroll_alignment_test.dart \
  test/games/connect_four_native_route_test.dart \
  test/games/connect_four_interaction_test.dart \
  --name 'Four in a row|Connect Four layout|Fold outer-screen|48dp columns|Actual Android Flutter route|tapping the board|double taps|local two-player win|restart mid-fall'
```

This environment reused an existing asset bundle read-only. The two Nunito fonts and all three image assets used by these C4 visual/result tests were SHA-256 checked against this exact checkout and match. The checks are recorded in `manifest.json`. A fresh checkout can omit `--no-test-assets` to build its own assets.

All five PNGs are actual `RenderRepaintBoundary.toImage(pixelRatio: 1)` captures after real test moves: [360 × 800](360x800.png), [640 × 360](640x360.png), [740 × 840](740x840.png), [1280 × 720](1280x720.png), [1200 × 896](1200x896.png). Their sizes and SHA-256 values, plus the exact tested source blobs, are bound in `manifest.json`. The root reviewer inspected all five final captures. An independent source review found no functional blocker in the shared-coordinate layout.

These checks cover the Flutter widget routes and the specified source changes. No physical Android device, emulator, signed APK/AAB, frame-rate measurement or Play submission was performed in this focused repair.
