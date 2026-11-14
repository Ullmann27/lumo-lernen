# Incoming 32e integration review against 182e

Scope: the requested two product files and five Flutter test files only. Current Host is `182e5e236a9a08fa4e8b33778338ac22ac05575a`; incoming source is `32e7efbff427fef64e90b3a1fcecd3b52f00af42`; the incoming three-commit range starts at `2b586530db4f2cb20c28f426e2549342316151bf`.

**Two files are identical; five contain preservable improvements. No conflicting current-side changes exist in these five files, and no static blocker was found.** This is a source review. The runtime was unavailable; no tests were run and no ref was changed.

| File | Classification | Decision and evidence |
|---|---|---|
| `lib/core/lumo_image_generator.dart` | Identical | Both branches contain the same Orange privacy-fix blob `d8f14f1c344e7c3721f6f337b733fded012db897`. |
| `test/core/lumo_image_generator_test.dart` | Identical | Both contain regression blob `59fe89a46a5d52e2f97529a21832240ecf2a8a46`. |
| `lib/features/games/connect_four/lumo_connect_four_game.dart` | Preservable improvement | The sole new line is `pressedScale: 1` on the column buttons at line 930. Existing dimensions, scroll layout, gameplay, native-session flow and assets stay unchanged. |
| `test/design/connect_four_visual_test.dart` | Preservable improvement | Requires actual playable state, hit-testable mode/move controls and six occupied cells after six moves; retains five viewport captures and alignment, with explicit 48dp RenderBox requirements. |
| `test/games/connect_four_fold_controls_test.dart` | Preservable improvement | Preserves all original assertions and adds before/after scroll alignment, full viewport bounds, hit-testability and actual pointer-down geometry. The released pointer must still place a real stone. |
| `test/games/connect_four_scroll_alignment_test.dart` | Preservable improvement | Keeps 0→6→0 touches, alignment, nonoverlap and board outcomes. Target size remains>=48; only global-coordinate subtraction allows 1e-9 roundoff. |
| `test/games/games_screen_flow_test.dart` | Preservable improvement | Retains full game/results/rewards, waits on real readiness with deadlines, verifies no old stones after restart and adds delayed native-refusal→real Flutter fallback coverage. |

The five changed files on 182e are byte-identical to their 2b586 ancestors, verified through both full contents and Git blob IDs. Their incoming versions can be retained without resolving competing source edits in these files. Workflow/Python integration belongs to Root and is not covered by this verdict.

The existing `LumoPressable` dependency was read only to verify the production argument: `lumo_motion.dart` blob `2f92e6319cda41d73abbc677545e02f2d509eb53` has default pressedScale=.955 at line 41 and applies the actual transform at lines 113–114. Setting 1 on these column buttons removes that shrinking transform while retaining the existing glow. The new pointer-down test should be preserved with that production line. It has not been independently executed in this review.

The 1e-9 comparison is bounded to global-rectangle arithmetic after requiring the underlying RenderBox width/height>=48. It does not permit a materially smaller target or remove the hit/placement checks.

All seven original/current/incoming blob identities and precise source references are retained in `review.json`. This review grants no Flutter/Android, performance, or release-readiness result.
