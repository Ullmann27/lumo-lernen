# Additional creative-game Android QA for the unchanged Studio 318 APK

## Preparation status

This is a separate QA-only package. It has not yet run the APK on Android. No
product source, primary checkout, child save or existing release was changed.
Root must publish this package on `chatgpt/lumo-creative-android-31883868-20261113`
before the push workflow can execute. Its eventual QA commit is recorded
separately from the immutable APK source.

The actual candidate already exists. The wrapper requires all of these values:

| Identity | Required observed value |
| --- | --- |
| Repository | `Ullmann27/lumo-lernen` |
| Host source | `31883868bac56699dbf3b3d60a7cdb7afc496a8b` |
| Native source | `796b2818ff729dc5389a92f8bf1f7fd7e6b6d93e` |
| Original build run | `43496928833` |
| Original artifact | `14076081664`, `lumo-studio-2019-candidate` |
| Artifact ZIP bytes | `647428301` |
| GitHub artifact digest | `1058baf7755a0ad34502c5552bfbeaa2c6807803ddea7ba2f616e5e80c0e273f` |
| x86 APK bytes | `325278174` |
| x86 APK SHA256 | `a9813af17f45eb3ce0db16c6bef13f5e776831e8e76a3f2e6466c8a8a5b8ee5f` |
| Embedded PCK bytes | `66217496` |
| Embedded PCK SHA256 | `13f87bd1b72526d187584a35f50c67961dc88ca67af6d703472b439bc07a523b` |

Artifact identity comes from the original build metadata. APK/PCK values come
from that build's verifier log; this preparation did not download the APK.
At execution, the existing unmodified 318 `verify_apk_identity` checks its own
clean checkout/provenance/sums/certificate/version/ABI. The new wrapper also
measures the downloaded APK bytes and reads/hashes the PCK directly inside that
APK. No new APK or PCK is built.

## What the real job will do

- Create a fictional `LumoTest` profile in a fresh disposable API 35/release 15
  emulator using existing onboarding helpers, then require offline mode.
- Open each game through the current hub's actual, complete, enabled clickable
  Semantics label and live bounds. Ten scroll gestures per direction are bounded
  by eleven observations, including the last reached state.
- Before every positional input, capture an unchanged Android screenshot and
  record coordinates and their observed/source-based rationale. Existing OCR
  readiness and accessibility journals remain in the artifact.
- **Jump:** send separate left/right stick holds and short/held jump presses;
  record the production scene through Android `screenrecord`; fully decode the
  MP4, retain frames and timing metadata; read the real scoped checkpoint;
  pause, return and reopen the same session. A human must review visible motion.
- **Build:** project an empty cell using the actual saved camera and observed
  Android window frame, require visible green land, touch it, and require exactly
  one new Sandstein object with every previous piece preserved. Undo must restore
  the original pieces; redo must restore the changed pieces. Reopen the save.
  The existing starter-house goal separately checks its original 3-star/24-XP
  reward and replay deduplication; it is not called a newly constructed house.
- **Puzzle:** make four genuine count changes and three mode toggles, start a
  six-piece motif 1 Drehpuzzle, infer one tray center from the freshly observed
  board contour, select it, press the real Save and Rotate controls, and require
  exactly one saved quarter-turn plus one move. Reopen the same result and pieces.
  Opening Pause clears the game's selection, so it is not used between selecting
  and rotating the piece.
- **Treasure:** use actual joystick segments and read each persisted position;
  approach the first tree clue, open its real question, select its visible answer,
  require the new `tree` solved ID, see the Blattschlüssel in the real backpack,
  and reopen the same position/progress. The complete journey is outside scope.

The native game process must stop on return, current Flutter accessibility and
an exact visibly rendered `Spielen` caption must return, and the child profile
must remain the same. Engine errors and actual app fatal logs fail the job.
Each game is attempted once. A failed game remains failed; a documented app
restart may permit the next independent game to be checked without rewriting
its state or retrying the failed case.

Successful machine contracts produce `RECORDED_REVIEW_REQUIRED`, not a full
visual or device-performance acceptance. The eventual video, screenshots and
raw state differences must be reviewed. There is no numeric jump-height,
multitouch, Samsung Fold7, Android 17, latency, temperature or 60-FPS claim here.

## Completed local checks

`local-contracts.log` records nine passing narrow contracts. They cover actual
candidate-source rejection, wrong/expired artifact rejection, current hub
semantics, clipped/ambiguous controls, the final allowed scroll, exact piece
addition, rotation and resume identity, real hashed Jump scope, and correct
Godot ConfigFile variants. The final run treats ResourceWarnings as errors.
The preceding warning-containing log is retained transparently; a `with`-bound
image reader closed the observed file handles.

`godot-config-serializer.log` records an actual isolated Godot 4.6.3 run. Its
synthetic fixture contains an unindented multiline dictionary, nested values,
escaped strings and `Array[String]`. The former INI parser actually failed on
those bytes; the new reader preserves complete raw Variant values. No Lumo game
or profile was loaded during that format test. The authoring script, generated
fixture and `config-format-red-green.json` are included.

`existing-renderer-target-checks.json` records the new coordinate detector on
two existing genuine desktop renderer images. That establishes only the tested
image geometry; it is not an Android hit or gameplay result. The live job must
still confirm every requested effect through current images and actual saves.

Actionlint 1.7.12 and all five embedded shell snippets passed. The emulator action
is the same exact a421 commit already used for API 35. Its script is one Python
command; the unchanged action enforces that command's exit status. Read-only
reviews by Agents A/C cover the workflow/identity and game/save contracts.

## Reproduction

The workflow is `.github/workflows/lumo-studio-creative-android.yml`. It uses
three separate sparse checkouts (QA, immutable 318 host helpers, immutable 796b
native source), downloads the original candidate once, installs it and runs:

```bash
.probe-venv/bin/python qa-source/.github/probes/studio_creative_android_probe.py \
  --candidate-source candidate-source \
  --native-source native-source \
  --probe-source qa-source \
  --apk candidate/dist/x86_64/Lumo-Lernen-Neu.apk \
  --provenance candidate/dist/x86_64/BUILD-PROVENANCE.json \
  --sums candidate/dist/ANDROID-TOUR-SHA256SUMS.txt \
  --out evidence/tour
```

The job always uploads `studio318-creative-api35-original`, including partial
failure evidence. The complete current test source and exact file hashes are
listed in the separately supplied upload manifest. No release, branch merge,
workflow retry or product mutation is performed by this package.
