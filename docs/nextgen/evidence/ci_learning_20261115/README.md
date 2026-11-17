# Learning CI corrections — 2026-11-15

Base: `aea9f63e5ea7a85a2d0a67d3b0e8988b0b0eb1fa`, the source of CI run
`43750469368`. This delivery addresses the eleven assigned failures in four
test files. It also fixes the lifecycle error exposed after the old help-button
expectation stopped hiding the remainder of that test.

| Assigned cases | Diagnosis and retained check |
| --- | --- |
| 3 shape layouts | The active renderer uses interactive `shape-explore-*` pictures. Tests check every actual option, matching semantic labels and painted shapes, 48 dp minimum targets, focus without evaluation, then wrong/right answer grading. |
| 3 long number comparisons | The old fixture supplied a solved expression and expected the answer immediately. The current fixture supplies the actual comparison contract, checks both numbers within the card bounds, requires `?` before evaluation, then checks the explicitly supplied evaluated symbol. |
| 2 learning page layouts | The old decorative `lumo-help-sparkle` belonged to a replaced help control. Tests check the enabled visible canonical `Hilf mir` button and its 48 dp target while retaining the page, encouragement, and overflow checks. |
| 1 quick-practice help flow | The current help button must drive the same staged hints as the companion request. Exam suppression, stable task identity, unchanged rewards, and clearing on exit remain asserted. |
| 2 parser fixtures | Their answer `5` contradicted 07:30 and half of 8. QualityGuard correctly replaced the invalid tasks. Correct answers/options now pass the guard without replacement before the payload assertions. Both `Hälfte` and `Haelfte` are checked. |

## Production correction

`LearningContent.dispose` used the newest queued `_publishedTaskContext` for its
deferred cleanup. A renderer help callback can prepare that snapshot before its
post-frame publication runs. Disposing in that interval left the binding's
previous, actually published context on the bus.

Cleanup now delegates to `LearningCoachBinding.clear()` after the frame. This
uses the existing exact owner check and releases only its last actual
publication. The added successor-screen regression publishes a new task before
the old deferred cleanup and verifies that the new owner survives. No shared
binding, bus, evaluator, renderer, reward, native pin, or workflow was changed.

## Executed validation

`tests-initial.log`: **41 passed, 1 failed**. This retained diagnostic run exposed
the stale context on quick-practice exit after the obsolete UI assertion was
corrected. The successor regression had not yet been added.

`tests.log`: **43 passed, 0 failed, 0 skipped**, exit 0, on the final files listed
by hash in `source.json`:

```sh
flock --close /workspace/scratch/c5a7dadab95f/toolchain/lumo-flutter.lock \
  /workspace/scratch/c5a7dadab95f/toolchain/flutter/bin/flutter test \
  --no-pub --reporter expanded \
  test/design/shape_question_runtime_test.dart \
  test/design/lumo_learning_tree_fold_visual_test.dart \
  test/task_help_integration_test.dart \
  test/visual_payload_data_test.dart
```

`analyze.log`: targeted `flutter analyze --no-pub` on the four test files and
`lib/features/learning/learning_content.dart` completed with **no issues**, exit 0.

These are local Flutter/widget tests with logical viewports and mocked storage.
They do not certify the complete CI suite, a physical Fold, real microphone
operation, native rendering performance, or an APK. No test was skipped or
removed. Expected solutions and complete explanations were not restored to the
unanswered UI.
