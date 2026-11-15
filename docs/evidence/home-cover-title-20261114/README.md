# Narrow home secondary-card title repair

## Source identity

This change targets the observed 320 × 740 logical-pixel Fold cover at text scale 1.2.

- Combined host source inspected: `7fd9e91683ecf703c00f100e314aced9191f7847` (PR 497).
- Adventure card source: `f3a79f01fc5fb11d9cd9faa033dfdab3aeb8c3c4`, blob `94b9f5eece1570631a6bf7428b8d8cc5d83e3360`.
- Home layout source: blob `9d980f6c2663ebe965195af3c15d8533867503ba`.
- Existing mandatory capture-test source: blob `b639f895f24e1eba22edf604b68d3fc827b44fd4`.

The original eight-PNG capture manifest and the recovered five-test log are stored in `docs/evidence/home-capture-integration-20261114/`. Independent inspection of the original Fold-cover image observed the full word split as “Belohnunge” followed by “n”. The PNG bytes themselves did not survive the managed-runtime restart; the manifest is not a substitute for a new rendered image.

## Small product delta

At a 320 dp viewport, the two secondary cards receive 140 dp each: (320 − 32 outer padding − 8 gap) / 2. The previous 12 dp horizontal inner padding leaves 116 dp for the title.

Compact cards now use 8 dp horizontal inner padding, leaving 124 dp. Vertical inner padding remains 12 dp. Labels, title size, text scaling, card height, the two-card arrangement, artwork, callbacks, and the non-compact padding retain their source values.

The patch changes only `lib/widgets/design/lumo_adventure_card.dart` in product code.

## Required regression and rendering gate

The existing `test/design/home_1989_premium_cards_capture_test.dart` loads the actual Nunito fonts and runs the real HomeContent tree at its existing four viewport/text-scale combinations. It now verifies for both secondary cards:

- The full title's rendered selection has one text box and does not exceed a max-lines limit.
- The glyph bounds stay inside the card.
- Both card dimensions are at least 48 dp.
- At the Fold cover, both real card centers are hit-testable and taps call the Tests and Rewards section callbacks in order.

The existing capture path remains active through `LUMO_1989_CARD_CAPTURES`. The Fold-cover capture must be visually inspected after CI succeeds.

## Validation status at this checkpoint

The standalone Dart formatter parsed both changed Dart files successfully using the existing Dart SDK. No Flutter test or new PNG was produced locally for this patch: after the runtime restart the host checkout and Pub cache were missing, while the shared workspace had approximately 1.28 MB free. No unrelated checkout/cache was changed to free space.

The prior five passing capture tests predate these new assertions and this padding change. They do not certify this new source. Execute the strengthened test and the required Home/learning matrix in the final combined host CI; only that exact-source run may establish a new pass or visual acceptance.
