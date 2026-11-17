# Shape tracing input repair

## Source and reproduced defect

Starting host: `682f5991feb49d3a73ab7e2b42e23af725857ea9` (PR #485,
version `0.13.8+2020`). This repair changes the shape tracing widget and adds
focused input regression tests. Existing writing coach and journal modules
are preserved.

The original `_TraceStage` fed raw pointer events into drawing while using a
horizontal drag recognizer that accepted rejected gestures. That recognizer
did not reserve a vertical stroke from its scrollable parent. The baseline
widget test demonstrated a **90 logical pixel page movement for a 90 pixel
vertical drawing stroke**. A separate baseline test showed that a cancelled
pointer incorrectly saved its unfinished stroke and enabled submission.

## Change

The shape canvas now uses the existing `LumoInkSurface` used by the writing
modules. It reserves pointers beginning inside the drawing area immediately,
tracks a single active drawing pointer, and distinguishes cancellation from
completion. Coordinates still clamp to the same bounded canvas. Cancelling
discards only the unfinished stroke; normal completed strokes and retry
policy continue to work. Gestures beginning outside the canvas can still
scroll the lesson.

## Verification

The baseline failures are captured in `before.txt`. The repaired source was
checked using the installed Flutter SDK with this command:

```sh
flutter test --no-pub --no-test-assets --concurrency=1 --reporter=expanded \
  test/shape_trace_input_regression_test.dart \
  test/shape_trace_retry_test.dart \
  test/lumo_ink_surface_regression_test.dart
```

**Result: seven tests passed, zero failed, exit 0.** They cover the stationary
shape canvas, outside scrolling, second pointer ownership, cancellation and
retry, both shape task retry policies, and the original writing surface.
The complete final run is in `after.txt`.

```sh
dart analyze lib/features/learning/widgets/lumo_shape_trace_canvas.dart \
  test/shape_trace_input_regression_test.dart
```

**Result: no issues found, exit 0.** See `analyze.txt`. `git diff --check` also
passed. These are widget/source checks; this patch does not claim a physical
Fold7 test, a newly built APK, or Play Store approval. Those remain integration
and release gates on the combined source.
