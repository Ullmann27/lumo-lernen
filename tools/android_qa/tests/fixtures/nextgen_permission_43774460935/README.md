# Android microphone permission reader correction

## Exact original evidence

Run **43774460935**, Android job **133004691086**, artifact **14186359772**.
The APK product source is **fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242**,
native source **678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef**, versionCode **2028**.
The reader correction starts from **dd89719f84405cd6b570c094042d2c71ca30c731**.

`0138-microphone-outcome.xml` is copied byte for byte, including CRLF.
Its only PermissionController node has `visible-to-user="false"` and
`bounds="[27,1205][1053,1205]"`: the dialog is still appearing. The old reader
mistook this package presence for a fully ready dialog and failed immediately.
The later original screenshot `0139-failure-current-screen.png` visibly shows
“Allow Lumo Lernen Neu to record audio?” and one “While using the app” button.
That screenshot is retained with the original artifact, not converted into a
fabricated accessibility fixture. Exact hashes and archive identity are in
`manifest.json`.

## Narrow correction

The existing 35-second budget is unchanged. Each poll reads a fresh hierarchy.
Only a visible, enabled, clickable system control with valid observed bounds
and the matching visible Lumo audio request can authorize a tap. Caption case
aliases and duplicate semantics identify one target; two different controls
remain ambiguous. Camera, location, another app and combined permissions are
refused. An incomplete dialog/prompt is observed again without a guessed touch.

After one actual Allow tap, the reader never repeats that tap during dismissal.
It waits for the system dialog to disappear and for the existing listening UI
or explicit device limitation. Dialog disappearance alone, underlying app text,
a missing outcome and a late hierarchy are not success. No adb pregrant, private
app-data write, product change, source pin change or loosened learning gate is
included.

## RED / GREEN

- `permission-reader-red-final.log`: the **same final 14 regression tests** run
  against the original reader loaded from Git commit `dd89719…`. The original
  zero-height XML reproduces the original conversation failure. Caption aliases,
  unrelated grants, invisible controls and repeated grant taps also expose the
  old behavior. The expected result is **FAIL**.
- `permission-reader-green.log`: **63/63 PASS**, comprising all 49 existing tests
  in `test_nextgen_learning_android_probe.py` plus 14 permission-flow tests.
  Original identity, preservation, playback and performance checks remain in
  that run. No test is skipped or weakened.
- Python AST parsing and Git whitespace verification are separate source checks.

The later ready/transition nodes in the pure Python tests are explicitly
**synthetic transport cases**. Only the 0138 XML is an original Android hierarchy.
No new Android run, actual permission grant, microphone recognition or runtime
PASS is claimed. A fresh UI may report a device limitation or a lifecycle-related
cancellation; the full immutable-APK replay must observe that actual result.

Reproduction:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tools/android_qa/tests/test_nextgen_learning_android_probe.py -v
```
