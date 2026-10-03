# Exact-APK Android integration check

The manually dispatched `android-integration-qa.yml` workflow checks one APK on
an API 35 x86_64 emulator with KVM and SwANGLE. It keeps the release unpublished
and never replaces an existing APK.

Inputs are `mode`, `releaseTag` and, for download mode, the full 64-character
`apkSha`. Build mode compiles the saved Flutter checkout selected by dispatch
and the full Godot revision in `config/godot-source.json` using the committed
stable signing keystore. It verifies and freezes the APK hash before the actual
usage test. Before UI QA it saves immutable bytes as
`Lumo-Lernen-Pruefkandidat.bin` and their verified provenance as
`Lumo-Lernen-Pruefkandidat-Provenienz.json` in the **existing unpublished draft**.
Existing candidates or final APKs prevent another build from replacing them.
Only after success does it attach the exact bytes as `Lumo-Lernen-Neu.apk`,
then download the uploaded bytes and verify their hash again.
Source revision, pinned PCK, signature, version and checksum are in the proof.

Download mode reads its single final APK, or, when there is no final APK,
the unique candidate/provenance pair using `GITHUB_TOKEN` and an explicit SHA.
It verifies hash, byte count, original saved source, draft ID, APK structure and
signature, and installs those exact bytes with the selected QA harness. After
passing UI checks it can promote the same candidate bytes to the final APK;
an existing final APK is verified without replacement. Root reviews the proof
and removes candidate assets before any publication. Helpers never publish or
delete assets. APK source and QA harness commits are recorded separately.

The workflow must be
available for manual dispatch on the repository's default branch; the dispatch
ref selects the version of these test scripts. Dispatch remains a separate
operator action.

The real UI check creates a synthetic first-grade profile, uses the actual
`Plus bis 10` topic, requests local task help, computes the answer solely from
the visible addition prompt and checks increased visible home stars, XP and
daily completion. It then opens Home → Games → Lumo Kart, checks Android Back/pause/continue, answers one actual math question
after inspecting a wrong-answer hint, waits through a full two-lap race, restarts
from the result, and returns to Flutter. It opens the game again to check a fresh
engine process and compares the saved/restored visible race HUD, then restarts
Flutter offline. It also plays all twelve Memory pairs through real touches,
checks result/restart/back/background/return, completes an actual Cards round
using accessible visible card faces, and checks its result/restart/back/return.
It compares visible wallet rewards after each game. Racing uses the
normal automatic gas and actual CPU/physics time; it uses no engine commands,
teleports, save edits or altered clocks.

Flutter controls use the APK's Android accessibility semantics; Godot controls
use OCR of raw screenshots and actual ADB touch input. Missing captions,
unreadable math, crashes, missing native returns, unchanged engine PID or APK
hash mismatches fail the check rather than being assumed successful.

The final Flutter checks resize the emulator to 904×2316, 1812×2176 and back to
904×2316 at density 320, perform real Learn/Home navigation at each size, then
force-stop and relaunch the app offline. The visible home stars, reconstructed
total XP/level, daily completion and profile captions must match before/after
each resize and process restart. These are emulated Fold-shaped layouts, not a
physical Samsung test. They do not verify hardware folding or hinge behaviour.

Limits: this CI extension checks one grade-1 addition in the main learning flow,
not all sixteen class/subject cases in the separate learning test plan. Cards
may select a visible option for a non-arithmetic Denkpause to exercise its game
flow; such selections are explicitly counted as unverified learning answers,
never asserted correct. Cards math touches are computed from visible text;
the native Kart flow separately proves a wrong hint and correct continuation.
Memory remembers only symbols actually exposed by the UI. Brief opponent/second
card reveals missed by a hierarchy dump remain unknown. Both game helpers have
a 600-second timeout in CI; unreadable controls, unfinished rounds or missing
rewards fail instead of being skipped. Active board state after process death,
all game settings, full audio/microphone/camera behaviour and every subject or
class remain outside this focused automated flow.

Screenshots, XML, OCR TSV/text, actions, installation metadata and Android logs
are retained, including on failure, in a proof ZIP named
`android-api35-qa-RUN_ID-ATTEMPT.zip`. The final step attaches only that ZIP to the
existing draft; APK bytes are excluded from the proof ZIP and the draft stays
unpublished. It uses
release assets instead of Actions artifact storage. `contents: write` is needed
for the explicitly scoped APK/proof uploads. A failed usage test uploads only
the proof ZIP and withholds the final APK; the unpublished candidate remains
available for an explicit-SHA rerun after a QA harness correction.

Local read-only OCR smoke check (no emulator interaction):

```sh
python3 tools/android_qa/kart_android_race.py --self-test path/to/learning-frame.png
```

`LUMO_QA_DIR` selects evidence storage; `LUMO_ADB` can select the adb binary.
The scripts record the tested emulator and do not claim a physical Galaxy Fold
test. The combined Android path remains unverified until an actual run passes.
