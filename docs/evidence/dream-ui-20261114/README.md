# Lumo dream UI: original evidence

Source: f3a79f01fc5fb11d9cd9faa033dfdab3aeb8c3c4. The CI synthetic merge e668242c89f71161022eb94efc8cf0be6081b67f has the identical Git tree, verified through GitHub's Git Data API. This evidence-only checkpoint does not alter that production code.

## Actual results

The seven atmosphere tests passed locally on the exact unchanged source files with Flutter 3.44.9, Dart 3.12.2 and the unchanged application pubspec/lock. The sparse harness contained the real production dependency files, not replacement widgets. They cover the bounded effect budget, quiet mode, route ticker mode, fixed action positions while the landscape moves, preserved content tickers, lifecycle and scroll visibility. The scoped analyzer completed with two TickerMode.of deprecation information notices; do not describe it as zero findings.

CI visual run 43573964195 / job 132384049622 passed 13 Home/card/navigation checks and 8 Magic/Mirror/Quest checks. The two PNGs are unedited files from its original eight-image artifact 14105287507. The downloaded ZIP hash matches the original CI log. Both provided images were visually inspected: original Lumo, readable headings, landscape and real buttons are visible without an observed overlap. Static images cannot prove animation, Android hardware performance or 60 FPS.

## Remaining actual failure

Full Flutter run 43573964099 / job 132384049345 ended with 2365 passed, 196 skipped and 3 failed Connect Four cases. Preserve the complete original log in this directory. The failures concern a missing reachable column finder, the existing 48dp column-control width contract, and a missing column after a landscape tap. Their cause relative to the baseline has not yet been established. This is not a complete application or APK approval.

## Reproduction

On the source revision: `flutter test --no-pub --concurrency=1 --reporter=expanded test/lumo_scene_atmosphere_test.dart`.

For the CI images use the repository's existing `test/design/home_1989_premium_cards_capture_test.dart` with its documented capture environment. Run references and all hashes are in `provenance.json`. Exact original logs are retained alongside the images.
