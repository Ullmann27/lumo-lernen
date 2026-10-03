# Exact-APK Android integration check

The manually dispatched `android-integration-qa.yml` workflow downloads the
single APK of an **existing draft release** using `GITHUB_TOKEN`. It verifies the
requested SHA-256, APK ZIP structure, signature and package metadata before
installing those exact bytes on an API 35 x86_64 emulator with KVM and SwANGLE.
It does not build, re-sign, replace or publish an APK.

Inputs are `releaseTag` and the full 64-character `apkSha`. The workflow must be
available for manual dispatch on the repository's default branch; the dispatch
ref selects the version of these test scripts. Dispatch remains a separate
operator action.

The real UI check creates a synthetic first-grade profile, opens Home → Games →
Lumo Kart, checks Android Back/pause/continue, answers one actual math question
after inspecting a wrong-answer hint, waits through a full two-lap race, restarts
from the result, and returns to Flutter. It opens the game again to check a fresh
engine process and saved pause, then restarts Flutter offline. Racing uses the
normal automatic gas and actual CPU/physics time; it uses no engine commands,
teleports, save edits or altered clocks.

Flutter controls use the APK's Android accessibility semantics; Godot controls
use OCR of raw screenshots and actual ADB touch input. Missing captions,
unreadable math, crashes, missing native returns, unchanged engine PID or APK
hash mismatches fail the check rather than being assumed successful.

Screenshots, XML, OCR TSV/text, actions, installation metadata and Android logs
are retained, including on failure, in a proof ZIP named
`android-api35-qa-RUN_ID-ATTEMPT.zip`. The final step attaches only that ZIP to the
existing draft; APK bytes are excluded and the draft stays unpublished. It uses
release assets instead of Actions artifact storage. `contents: write` is needed
for this explicitly scoped proof upload.

Local read-only OCR smoke check (no emulator interaction):

```sh
python3 tools/android_qa/kart_android_race.py --self-test path/to/learning-frame.png
```

`LUMO_QA_DIR` selects evidence storage; `LUMO_ADB` can select the adb binary.
The scripts record the tested emulator and do not claim a physical Galaxy Fold
test. The combined Android path remains unverified until an actual run passes.
