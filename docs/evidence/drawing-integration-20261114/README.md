# Drawing integration checkpoint — 14 November 2026

Base: `4564ad40c4d000b764e67719d19bd2445c04c870` (Host PR491), tree
`afd7246580623609abdc8e5b7754aa2bd2e2fd2e`.

## Sources and scope

The complete uncommitted producer files were read from the existing isolated
`support/drawing-input-stability-20261114` checkout based on
`682f5991feb49d3a73ab7e2b42e23af725857ea9`. The producer files and their tests
were present after the workspace restart. No code was reconstructed from
truncated chat output. The manifest records their actual byte digests.
No producer worktree or existing remote branch was modified.

This checkpoint selectively connects the existing shared-ink contact and
geometry guards and the older letter route's repaint/cancellation repair.
Both older letter-route action labels are additionally bounded with Flexible
and centered text so they can wrap at a narrow available width. Existing
actions, stroke evaluation, rewards and route structure remain.

The already integrated shape-canvas implementation from PR491 is preserved.
Its independent producer gesture tests are included without replacing the
newer canvas. The full handwriting-practice trainer and journal implementation
are not modified.

## Verification boundary at checkpoint creation

This commit is a source checkpoint, not acceptance. Its exact source has not
yet passed the new combined Flutter run, Android input execution, screenshots
or an APK build. The earlier local producer log reported 16 passing cases and
one failing narrow legacy-layout case. Those results belong to that earlier
producer state, not this commit. The later producer motion cases, including
initial contact during scrolling, require fresh execution as well.

The original shared Flutter preparation was blocked by the startup lock. The
managed environment then became unavailable; its temporary working tree and
SDK-copy preparation were lost. After the environment returned, original
producer files were recovered read-only and the source is now saved through
Git data before further testing. A missing or unsuccessful run is not green.

Required focused command (with the repository's locked dependencies and real
bundled fonts available):

```sh
flutter test --no-pub --no-test-assets --concurrency=1 \
  test/lumo_ink_surface_motion_regression_test.dart \
  test/legacy_letter_repaint_regression_test.dart \
  test/shape_trace_gesture_regression_test.dart \
  test/wort_diktat_gesture_regression_test.dart \
  test/lumo_ink_surface_regression_test.dart \
  test/shape_trace_input_regression_test.dart \
  test/writing_practice_trainer_test.dart
```

Root must bind the final combined Host/Native acceptance to the actual final
source after all focused failures have been resolved. No new public APK or
complete input/performance acceptance is claimed here.
