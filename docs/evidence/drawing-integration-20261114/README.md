# Drawing and explicit lesson selection — 14 November 2026

Base: `4564ad40c4d000b764e67719d19bd2445c04c870` (Host PR491), tree
`afd7246580623609abdc8e5b7754aa2bd2e2fd2e`.
The first, deliberately unverified source checkpoint was
`990503c72b60e0c509d52438f8858a03883110c6`.

## Source provenance

The full uncommitted drawing producer files were read from the existing
isolated `support/drawing-input-stability-20261114` checkout based on
`682f5991feb49d3a73ab7e2b42e23af725857ea9`. Its original byte digests are in
`producer-sources.json`. These files were recovered after the environment
restart. No source was reconstructed from truncated chat, and the producer
worktree and its refs were not changed.

PR493 was read at `b3f75f6fe3506321b7991f975cdc3854b341c596`. Its generator,
LearningContent and shape-canvas files were reviewed against PR491 and
selectively adopted; their Git blobs match that exact source. The existing
PR491 exact-selection test is preserved because it additionally asserts that
an earlier-grade unit is rejected by the current-grade-only path. The new
selection integration tests are retained, with formatting only. Shape tests
also include an additional idle-painter invalidation regression.

`integration-source-manifest.json` lists every owned product/test blob and
SHA256, source commits and the scoped validation results. The complete
pre-run Dart source fingerprints record the surrounding Host working tree,
which also contained other root/QA integration deltas. A scoped widget run
is not a claim that the complete final integration tree has passed release CI.

## Product changes

- Shared ink keeps one active pointer per Flutter view, cancels additional
  contacts, and rejects stale local coordinates after a canvas move or resize.
- Its new scroll registration is limited to actual ancestors of mounted ink
  surfaces. Flutter normally makes children unhittable during scrolling;
  the registration keeps the paper reachable for the first pen contact and
  uses `ScrollPosition.hold` to stop an existing drag or ballistic animation.
  The last departing surface restores the normal scroll hit-test policy.
  It uses public ScrollContext/ScrollPosition APIs, without synthetic events
  or Flutter SDK modifications.
- The older letter screen uses the shared ink hooks and a repaint revision;
  cancellation discards only the active stroke. Both action labels can wrap
  within their allocated width, including the tested 320×740 layout.
- The real WortDiktat rows now use the same input hooks, bounded coordinates
  and an explicit active-stroke reference. A cancelled stroke leaves earlier
  writing intact. Existing comparison, self-rating and reward behavior remains.
- The shape painter receives a snapshot of the completed stroke list so Undo
  and Clear invalidate ink even when no ancestor happens to repaint.
- Explicit learning selections reach `nextExact` with child personalization;
  real curriculum topics take priority over legacy aliases. Exhausting a
  finite reading bank repeats a checked reading task instead of switching
  subjects. Changing test difficulty replaces the task and companion context.

The full handwriting-practice trainer, word-coach implementation and journal
editor are not rewritten. Existing PR491 Play and motion changes remain in
this branch's ancestry.

## Fresh validation and failures retained

The restored environment used Flutter 3.44.9 / Dart 3.12.2, framework revision
`6b182d2c7585eba26d4edce0f97630effd256c33`. Locked pub dependencies were restored
with ordinary Dart pub; no foreign SDK startup lock was removed or bypassed.

1. `drawing-first-combined.log`: 25 passes, five failures on the initial
   checkpoint. Three motion cases and both real WortDiktat layouts exposed
   missing scroll takeover/input integration. The first coasting fixture was
   also below the actual fling threshold; its replacement asserts that the
   page is genuinely moving before the first pen contact.
2. `shape-painter-before.log`: the added idle-invalidation regression failed
   on the unchanged PR491 shape painter: Undo returned `shouldRepaint=false`.
   The broad raster test alone happened to pass because an ancestor repainted;
   the independent invalidation assertion exposes the missing contract.
3. `drawing-learning-integrated.log`: **75 passes, zero failures**, 12 test
   files, concurrency 1, exit 0, 24.617 seconds. Product and test byte digests
   were checked against the pre-run fingerprint before this checkpoint.
4. `drawing-learning-analyze.log`: exit 0, zero errors and warnings. Four
   informational style hints remain in imported tests (two interpolation
   suggestions and two redundant imports); the tested bytes are preserved.

The successful combined run covers all of the following:

- outside contact already down, active outside drag, genuinely moving coasting
  page, multiple canvases, extra palm contact and ordinary parent rebuilds;
- removing one canvas, removing the last canvas, and disposing an active page;
- legacy repaint, mouse/stylus input, bounded points, cancellation and resize;
- real WortDiktat at 430×600 and 640×360, with unchanged scroll offsets and
  canvas origins during every movement, preservation after cancellation and
  entry into the existing word-comparison action;
- all drawing directions, pointer ownership, cancellation, pixel-level
  Undo/Clear, idle painter invalidation and retry behavior;
- seven exact-selector cases plus seven real selection-integration cases;
- the existing practice trainer at four display sizes, complete writing-to-next
  task flow, and word-coach storage/reward/retry/background behavior.

The exact command and result are in `drawing-learning-integrated.json`. The
run uses `--no-test-assets`; real local Nunito font files and the required real
fox assets are explicitly loaded by the legacy/Diktat fixtures. This keeps the
input/layout test independent of the unrelated large game asset bundle.

## Remaining acceptance boundary

These are scoped desktop Flutter widget and analyzer results. Physical Android
stylus/palm behavior, final signed APK execution, the complete combined release
pipeline and device performance remain separate release checks. Root must bind
those checks to the final combined Host/Native sources. No new public APK,
physical-device input pass or 60 FPS performance result is claimed here.
