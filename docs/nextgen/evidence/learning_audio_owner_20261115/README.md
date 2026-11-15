# Learning page audio ownership — 2026-11-15

Base: `16df94d2deb4d232795fa2ef9222da843e1d5a99` (the separately delivered
43-pass CI correction), on CI source
`aea9f63e5ea7a85a2d0a67d3b0e8988b0b0eb1fa`.

## Scope

Only `LearningContent` and `GuidedLessonScreen` production code changes.
Both use the existing central `LumoVoice.requestRevision` contract. A stop,
pause, exit, or old completion cannot stop a newer request, including one still
preparing. The optional injected `LumoVoice` defaults to the existing singleton
and permits deterministic tests of actual widget callbacks.

LearningContent captures the request produced by each page-owned playback.
Delayed catalog/availability preparation checks that the transport has not
changed. Its native handoff waits for the owned stop and refuses to launch after
a newer speaker has claimed the transport. Greeting, answer feedback, and
writing praise use the same page-owned playback helper.

Guided narration records ownership during stop as well as playback, so an old
delayed stop cannot restart speech over a newer owner. Its Ba/na/ne sequence
continues only after a confirmed completion of its still-current request.
Preparing does not highlight a syllable; actual speaking events do. Foreign
audio clears the old highlight without advancing the sequence.

Slower playback uses `speakAndWait(speedFactor: .7)`. There are no global rate
changes or completion-time rate restores in these two owners. Existing task
evaluation, explicit candidate confirmation, assistance evidence, rewards,
canonical bus, and voice service implementation remain unchanged.

## Executed verification

`tests.log`: **54 passed, 0 failed, 0 skipped**, exit 0:

```sh
flock --close /workspace/scratch/c5a7dadab95f/toolchain/lumo-flutter.lock \
  /workspace/scratch/c5a7dadab95f/toolchain/flutter/bin/flutter test \
  --no-pub --reporter expanded \
  test/learning/learning_voice_owner_test.dart \
  test/learning/learning_content_commands_test.dart \
  test/tutoring/guided_lesson_runtime_test.dart \
  test/task_help_integration_test.dart
```

The 14 new owner cases exercise stop/pause/dispose against newer speakers on
both pages, cancellation of each page's own pending transport, delayed stop
before normal and syllable speech, delayed adaptive preparation and native
handoff, request-local slow rates, and actual segment speaking/completion events.
The other files retain their real task, progress, layout, and help-flow checks.

`analyze.log`: targeted `flutter analyze --no-pub` on the two production files
and the new owner regression file reports **no issues**, exit 0. `source.json`
records SHA-256 hashes of the final production/test files and test log.

Development history is retained separately: `owner-tests-initial.log` failed
to compile because the new native-handoff fixture lacked Flutter's foundation
import; `owner-tests-fixture.log` recorded 9/5 before the static clip catalog
was loaded in `setUpAll` instead of one test's FakeAsync zone;
`owner-tests-platform-fixture.log` recorded 13/1 before restoring the fixture's
Android platform override within the test body. No assertions were removed or
weakened to resolve these fixture errors.

These are controlled transport futures and widget lifecycle events. They do not
prove physical microphone/speaker behavior, device performance, or a complete
CI run. No native pin or workflow changes are included.
