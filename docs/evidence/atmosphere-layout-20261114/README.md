# Atmosphere visibility after layout — 14 November 2026

Source reviewed: PR492 at `de3b74c56052794196b9f14fc65a13412209651f`.
The original atmosphere blob was `2a5ba8203a9777a28820ab36f7c2a979709c8620`;
the original seven-test file blob was `0617368d95256961681109537d641a1708e82e1f`.
This checkpoint follows the drawing/selection checkpoint
`440ea177e02df6728ef3b046c9b78ffadf9aff06` and contains only the atmosphere
product file, its tests and this evidence directory as its additional delta.
The other PR492 product files remain owned by the integration coordinator.

## Reproduced failure

The same cached atmosphere widget is initially below a 400px viewport. Its
preceding spacer changes from 700px to 80px with scroll offset fixed at zero.
The real content is then visible at y=80, but its functional child TickerMode
remains false. Changing a sibling's layout does not rebuild that cached child
or trigger a scroll-position listener. `atmosphere-layout-before.log` records
the actual failing assertion against the original PR492 product blob.

## Bounded correction

A single shared frame dispatcher schedules at most one post-frame visibility
check for all live scenes with a scroll ancestor. The check runs after layout
and only when a frame is already being rendered. It does not request frames,
start a timer, add a per-scene persistent callback or change input geometry.
The static dispatcher holds no scene closure. Its live instance set is updated
when ancestors change and removes states during disposal. The existing
app-lifecycle, route-TickerMode and reduced-motion controls remain in place.
Detached render boxes are ignored.

This also handles const/cached children moving without their own layout call;
adding only a didUpdateWidget check would miss the reproduced case. There is
one process-lifetime dispatcher callback, which performs an empty-set check
when no registered scenes remain. There is no process-lifetime callback per
scene and no retained disposed state in its set.

## Fresh validation

Flutter 3.44.9 / Dart 3.12.2, framework revision
`6b182d2c7585eba26d4edce0f97630effd256c33`.

- Before: one selected regression executed and failed with the child TickerMode
  still false after the card became visible.
- After: all ten atmosphere tests pass, exit 0, 3.33 seconds. The new cases
  cover constant-offset sibling relayout, viewport-height changes combined
  with pause/resume, GlobalKey reparenting out of a scroll view, and unmount.
- Hidden scenes and unmounted scenes both have zero transient callbacks and
  no scheduled frame in the new tests. A visible functional child resumes.
- The original seven effect-budget, reduced-motion, touch-position, background
  and scroll-visibility cases remain green.
- Targeted Dart analysis has no errors, warnings or informational hints.

The paired source manifests record actual Git blobs and SHA256 digests. Both
final files were checked against the successful run's manifest before upload.
The full Home/accessibility and optional real capture reruns are separate
integration-coordinator checks; this evidence does not replace them.
