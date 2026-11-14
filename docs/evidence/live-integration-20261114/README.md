# Live integration QA · 14 November 2026

These are compact original logs and source-bound metadata from the coordinated
integration working tree based on host commit
`4564ad40c4d000b764e67719d19bd2445c04c870`. The working tree also contained the
other integration agents' changes. Each run's JSON records its actual command,
exit code, log hash and, where captured, exact file identities. The source index
covers the ten QA-owned source files only; it is not a claim that all coordinated
product changes are contained in the QA repair branch.

## Observed results

| Check | Actual result | Original evidence |
| --- | --- | --- |
| Historical APK diagnostic | Original test reproduced one error; repaired fixture and direct neighbors passed all 47 tests | `unchanged-apk-fixture-recovered-red-source-bound.*`, `unchanged-apk-fixture-recovered-green.*` |
| Android C4 evidence contracts | New integration branches first rejected by old helper; final four-branch contract and direct deadline/update neighbors passed all 51 tests | `pr493-android-evidence-red.*`, `pr493-four-branches-android-evidence-green.*` |
| C4 Flutter tests | 44 passed, zero failures/skips, across seven files | `c4-widget-integration-run.*` |
| Workflow/delivery contracts | Before the change, missing/skipped Return recovery was accepted and the new branch was blocked; final delivery/workflow/source-pin suite passed all 83 tests | `workflow-delivery-red.*`, `workflow-delivery-green.*` |
| Workflow syntax and expressions | Installed actionlint 1.7.12 checked both changed workflows and returned zero with no diagnostics | `workflow-actionlint.*` |

The unchanged diagnostic production verifier remains historical. The fixture
repair preserves its real helper/Git/APK checks. The two C4 test repairs exercise
the actual Flutter controls after asynchronous initialization, reach every
48dp target by scrolling where required, complete a game, and verify restart
invalidates old bot callbacks. No C4 production source was changed by this QA
patch.

The current delivery workflow admits exactly the original C4, quality,
agent-execution and live-integration branch names. The additional native Return
regression runs after source import and before the real Dart/Godot two-process
gate. Its exact successful step is mandatory in the delivery verifier: a green
job cannot conceal that step being absent or skipped. Existing LIVE-branch and
17-raster integration changes are preserved. This patch does not change the
current or historical Native source pins.

## Original failing CI and rendered captures

`pr491-original-flutter-failures.json` records the original GitHub run/job URLs
and complete raw-log hashes. The large downloaded CI logs are intentionally not
duplicated in this directory. They remain identifiable by those original URLs
and hashes.

`c4-captures-manifest.json` records five PNGs rendered by the actual passing
Flutter test run: 360x800, 640x360, 740x840, 1280x720 and 1200x896. All five were
visually inspected. Their original local locations, dimensions, byte counts and
SHA-256 values are retained unchanged in that manifest. The PNG bytes are not
duplicated in this compact checkpoint. These are Flutter render captures, not
Android device screenshots; local locations may expire with the execution
environment.

## Scope and remaining acceptance

The Python evidence checks use explicitly synthetic contract inputs. The
Flutter native-route tests use their declared platform fixtures. These results
do not establish an Android device run, a newly built APK, device performance,
physical audio, or publication. The new native Return script has not been run
by this workflow-editing task. The final combined Native source must still be
pinned by the integration coordinator, and the complete build, Android tour,
in-place update and delivery verification must execute on that combined source.

Old local logs lost in the earlier environment restart are not represented as
available here. The diagnostic red/green records are the actual reruns after
recovery, and the original CI log metadata was independently retrieved again.
