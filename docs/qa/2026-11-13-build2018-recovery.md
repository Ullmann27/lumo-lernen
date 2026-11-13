# Build 2018 recovery — actual failures and acceptance

The failed candidate is Flutter `8f2925b2d800714901e76ab131508b8c7d868f53`,
Godot `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`, version `0.13.6+2018`.
It was built and signed, but is **not released or accepted**. Main remains unchanged.
This repair does not add a new game or change the approved native assets.

## Observed navigation failure

Both workflows `43368260144` and `43368257044` stopped at
`learning_roundtrip()` with `No live Flutter route: ['Lumo erklärt es mir']`.
The original 21-check Android tour passed; the subsequent new learning/Cards
probe failed before opening Godot. Update and publication were correctly skipped.

The actual `guided-hub-19-missing.png`, recorded accessibility hierarchy and
`LumoAkademieScreen` agree: the learning tools are initially collapsed. The probe
must tap the visible **Lernwerkzeuge & Geschichten** control before selecting
**Lumo erklärt es mir**. Scrolling cannot reveal a widget that has not been built.
There is no evidence that an overlay or a delayed page build caused this failure.

A second incorrect assumption was found before rerunning: **Über den Zehner** is
the course heading, not a button. The existing accessibility-based course helper
selects the actual **Mit Lumo anfangen** button belonging to that named course.
The checked-in closed-tools XML is unchanged recorded Android evidence, not a
synthetic successful hierarchy. Its regression is a local probe check, not an
Android gameplay result.

## Independently reproduced product defect

`LumoGameActivity.returnToLearningApp()` persisted the generic `destination` for
every native scene. On resume, the real `EmbeddedGameService` consumed it and the
real `AppShell` called `Navigator.popUntil(route.isFirst)`. This removed the
originating guided lesson or Cards screen/controller instead of returning to it.

Four actual Flutter router/lifecycle regressions failed: learning and Cards,
each with the Activity result before and after resume. They used the real shell,
production buttons, lesson/Cards state and storage, controlling only Android
transport. In all four, `originCurrent=false`, `originRemoved=true` and
`originMounted=false`; the durable event was read and acknowledged. The clean
before log and its hashes are under `docs/evidence/nextgen-learning-20261113/`.
This defect requires a product change and therefore a newly compiled APK. The
previous APK cannot be approved by rerunning only its corrected test script.

## Implemented repair

The learning probe opens the real tools toggle, selects the real named-course
action, and checks the same returned lesson after bounded actual content swipes.
That last scroll matters: a measured 412×915 phone layout retains the launch
button's scroll offset, placing the lesson title above the visible viewport.
Activity/process-return checks and exact lesson/data checks remain mandatory.

The Android host now assigns learning/Cards returns to their live launch session.
`GameEventStore` retains the durable fallback, but masks that session's generic
navigation from the still-running Flutter caller. It does not mask rewards. The
matching return is consumed atomically before completing the native launch call.
A recreated host has no live owner and therefore receives the normal durable
fallback. Old 2017 events and legacy game navigation remain supported. Starting a
new explicit caller-owned scene supersedes stale navigation without removing
earned rewards. No child/profile/save schema migration is introduced.

The Cards probe rechecks real pause state and revision after OCR and immediately
before touching **Weiterspielen**. If the first native heartbeat has already
resumed the game, it observes that active state. A real resume touch instead must
produce a fresh native request and matching Dart acknowledgement for the same
round. Both draw actions, persisted-card checks, 35-second service binding,
pause and return/reopen checks remain required.

The Nextgen workflow now has one automatic APK event: the internal PR update.
Manual runs are confined to its expected branch and share the branch concurrency
group. The historical Unified workflow explicitly rejects version 2018 before
compilation; historical 2017 release checks remain. An audit of all 39 APK jobs
found zero matching automatic push builds and one matching PR build. Publication
still requires the matching internal PR event and every original successful gate.

## Release boundaries

The original native source and its approved renderer receipt remain unchanged.
Historical Flutter/native results stay historical; fresh checks must name their
actual source. Reuse is permitted only with exact source, artifact hash and
acceptance identity. Push and PR events must not compile the same candidate twice.

The new source must pass its focused route/lifecycle regressions, complete
Flutter/native/Android gates, live offline learning interaction and speech-state
round trip, live Cards state transitions, and the actual in-place 2017→2018 update.
Publication then rechecks package, version, original TEST certificate, ARM64,
source provenance and SHA-256, preserves existing releases, and hashes the public
APK bytes. No skipped gate or synthetic screenshot substitutes for these checks.

## Executed repair checks

| Check | Actual result | Evidence |
| --- | --- | --- |
| Original router reproduction | 4 failures before repair | `docs/evidence/nextgen-learning-20261113/native-origin-return-before-manifest.json` |
| Real Flutter shell/route regression | 31 passed, including all 10 new warm/cold/legacy/reward cases; analyzer clean | `docs/evidence/nextgen-learning-20261113/native-origin-return-after-manifest.json` |
| Kotlin store, wiring, installers and Cards registry | 21 passed; 9 scenarios execute production Kotlin with test-only Android filesystem adapters | `docs/evidence/native-caller-return-20261113/RESULT.json` |
| Complete build/preservation contracts | 304 passed, zero failed/skipped; 49 source hashes unchanged during execution | `docs/evidence/build2018-recovery-20261113/RESULT.json` |
| Android probe regressions | 684 passed, zero failed/skipped | Same result and raw logs |
| Targeted release/workflow contracts | 92 passed, zero failed/skipped; included in the complete contract suite | Same result and raw logs |

The local repair checks are complete at this source checkpoint. A fresh complete
APK/Android/update/publication run remains mandatory. There is no public Build
2018 APK yet. The old candidate's successful compilation is not a release result.
Emulator speech callbacks do not prove audible voice quality; no physical
Fold7/Android 17 performance claim is made. The workflow's source-bound artifacts
and final public-delivery receipt supply the subsequent acceptance outcome.
