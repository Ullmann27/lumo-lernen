# Supplemental 2031: numeric still capture after video finalization

## Original observation retained

Run **43822740773**, job **133149336951**, QA **7b811531ecd3034c0689edd3b39e44223d966857** failed before entering 15 or submitting either answer. APK source remains **e05a96a52aaf57e466e79831f15aaffd144284ee**; this change neither rebuilds nor changes it.

The complete original artifact **14204798832** is 22,181,444 bytes, SHA-256 **d28a0b855eb8ad8cc5127cac5fa0b453f79999dd98a798ba449bdb72ad6131df**. Root retains its 187 original members in three byte-exact archive parts under `docs/nextgen/evidence/ci-2031-runtime-cases-numeric-capture-failure/`. Its status remains **FAIL**.

All twelve `0134-numeric-before-wrong-answer-render-candidate-*.png` files are identical: 994,598 bytes each, SHA-256 **4f35e9ad513aeb47822ff071fac20b46641347754834d394aac6768d2b180081**. They show Android wallpaper, not the task. The raw readiness journal records 1080×2340, entropy 2.791, twelve attempts and 31.512 seconds. This is **not an established entropy false-negative**; those pictures must remain rejected.

Original XML `0132-numeric-nine-plus-seven.xml` already exposes the exact 9+7 recall question, an empty enabled answer field and enabled “Antwort prüfen”. Original video `0113-numeric-build-before-graded-recall.mp4` is 1,351,831 bytes, SHA-256 **70d7aedde9280c924dba4e06934a6ab385ac95366d81e1c7586d8c841a8ef78b**, with positive duration 42.172644 seconds and 41 frames according to the retained ffprobe JSON. The unedited video frame at t=20 seconds was decoded from the verified archive in memory and personally inspected: the complete 9+7 view is visible. The video is retained in the complete archive, not duplicated here.

The twelve screenshot calls run inside the recording context. After that context's finally stops the owned recorder and validates/transfers the same MP4, failure screenshot `0135-runtime-failure-current-screen.png` shows the complete task; its SHA-256 is **6d8ea6595439389ba2f87e65eb74721046354402b3022952c57dfaa056802264**. Both still-image paths use the same real `adb exec-out screencap -p`. The deeper Android surface/display cause is **unresolved**, because corresponding runtime display/layer observations were not collected.

## Narrow change

Only `RuntimeCasesProbe.numeric_wrong_then_correct` changes. Before finishing its existing build video it reads the current unanswered recall checkpoint and profile/learning snapshot. After successful recorder finalization and the existing positive-video gate, it freshly observes the exact question, rereads the unanswered checkpoint and persisted profile/learning state, and requires both to remain identical. Only then does the one original pre-submission still capture run through the unchanged screenshot readiness gate. Its evidence is stored under `numeric_wrong_then_correct.pre_submission_capture`.

There is no extra UI action, display mutation, capture fallback, threshold change or timeout change. The 15→16 submission loop and assessment verifier are byte-identical. Shared original/reference/capture/recording/publisher files, all 31 publisher-bound files, and the native active-stop helper remain unchanged. This adds no full-tour or publication success.

## Exact host checks and limits

- `numeric-capture-red.log`: the new sequence regression on unchanged QA production reproduces the original twelve-wallpaper/2.791 error: one test, one expected error. The exact test patch and source/test/log hashes are retained.
- `numeric-capture-green.log`: the affected existing runtime test module passes **27/27**, with no failures, errors or skips; six methods are new. It exercises actual numeric orchestration, recorder finalization, preservation checks, assessment verification and the unchanged pixel gate.
- Android processes, transfer/ffprobe responses, most UI responses and persisted values are isolated host transports. Original pixels/XML are used where stated; the ffprobe response is the original metadata fixture. Constructed values are not claimed as a new Android observation. These tests do not establish that the amended sequence has succeeded on a device.
- Negative cases retain hard failure for zero-duration build video, changed profile/learning/session, already-answered checkpoint, missing fresh question, or wallpaper still returned after recording. They assert no numeric input occurs. The successful host path retains exactly one explicit check of 15 and one of 16, with unchanged incorrect/corrected assistance semantics.

**New Android execution: NOT_RUN.** Root alone integrates, publishes the QA snapshot and starts a separate supplemental attempt. Original failure and completed full-replay evidence remain unchanged.
