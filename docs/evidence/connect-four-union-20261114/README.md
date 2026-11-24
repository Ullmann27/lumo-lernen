# C4 late-producer union — 14 November 2026

Frozen producer source: `01575aafc3f5b9032900bb57520ee65e98d7546c`.
The earlier 44-case QA source is `2d8ff889dcd172bfd694309a064a40e3e6a749a6`.
This commit continues the saved drawing/atmosphere checkpoint
`69cadb6cad90c653cc044e8d073b06e5906ee97d`.

## Four-file integration

The product and new scroll-alignment test are byte-identical to the frozen
producer. Board cells and all seven 48dp controls now share one horizontal
viewport and matching content insets. The minimum board width is 360.8dp
(7×48 + 2×12.4); short displays adapt board height independently.

The visual test is based on the actual tested QA blob
`8b685178fab49504a70cf0c63797d9fe7ce23d46`. It retains explicit native fallback
with cleanup, access to the real two-player control, every actual column's
48dp size and hittability, real stone placement, five real raster sizes and
companion bounds. Only the old narrow/scrolling exception is removed:
every control center must now align with its actual board column, also after
scrolling.

The games-flow test remains exactly the tested QA blob
`13cba5bd740b3b63f0af8c234e634473cfc1f123`. Its stronger complete-game,
reward-persistence, replay, explicit native-fallback and all-42-cells-empty
restart checks are preserved. The broader producer fixture replacement adds
no missing behavior to this already stronger local fixture.

## Validation boundary

The managed environment became unavailable during source preparation.
The new four-file union has **not** been executed locally. The earlier 44-case
QA pass is retained at its original source and must not be transferred to this
new product. The new scroll test adds three cases at 320×740, 360×800 and
640×360, including all seven columns and returning to the first column.

Required final gate, with real test assets and fonts available:

```sh
flutter test --no-pub --reporter=expanded --timeout=60s --concurrency=1 \
  test/games/games_screen_flow_test.dart \
  test/design/connect_four_visual_test.dart \
  test/games/connect_four_interaction_test.dart \
  test/games/connect_four_fold_controls_test.dart \
  test/games/connect_four_lumo_level_test.dart \
  test/games/connect_four_native_route_test.dart \
  test/games/connect_four_native_session_test.dart \
  test/games/connect_four_scroll_alignment_test.dart
```

Set LUMO_CONNECT_CAPTURES to preserve the five real C4 images. This remains
Flutter widget coverage; it does not replace the separate native/Android gate.
