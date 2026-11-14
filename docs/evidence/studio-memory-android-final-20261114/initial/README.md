# Read-only Android Memory acceptance probe

## Invocation

Run from the exact candidate Host checkout after the normal 21-step Android tour and the existing C4 probe, with that same installed APK. The Root workflow owns installation and the clean checkout.

    python .github/probes/lumo_memory_android_probe.py \
      --candidate-source "$HOST_SOURCE" --native-source "$NATIVE_SOURCE" \
      --apk "$CANDIDATE_APK" --provenance "$PROVENANCE_JSON" --sums "$SUMS_FILE" \
      --tour-result "$NORMAL_TOUR_RESULT" --out "$MEMORY_OUTPUT" \
      --expected-source "$HOST_SHA" --expected-native "$NATIVE_SHA" \
      --serial "$ANDROID_SERIAL" --expected-api 35

API 37 requires a separate invocation. The total deadline is 600 seconds; source and binary checks, captures, readbacks, native controls and return checks are included. Individual waits/captures use at most 45 seconds, actual route entry 60 seconds, and device calls cannot pass after the overall deadline. Failure diagnostics may take one final 15-second screenshot after the failed probe; they cannot convert the result to success.

## Actual actions and independent checks

The probe opens the real Memory tile from the current Flutter route, reads the current native state and measured layout, and requires an untouched real round. Existing progress is never cleared. A private saved deck is read solely as a documented QA oracle to choose a real matching pair and a later mismatch; no IPC request, preference, rule, reward or save is injected. Card, pause and resume actions use ADB touches on current, enabled, exposed 48dp controls and must receive their own current token/round/revision/sequence ACK. Exits are checked through the actual native-process/Flutter-return, removed-session and unchanged durable-save observations; the exit receipt is not claimed after its session directory has been removed.

Card quadrilaterals are recomputed from actual camera/world geometry rather than sampled from the supplied screen polygon. Insets must be real Android observations, at the same decor resolution as the screenshot. A before/after comparison inside the independently projected first card verifies visible face change. It does not claim image recognition of a particular motif; motif identity is bound separately to the actual Dart state and previously read private save.

After one matching pair the probe pauses, checks the unchanged persisted rule data, resumes, and makes a real mismatch. It must observe a new Dart opponent reveal. Home then produces a fresh inactive Activity lease and a durable frozen unfinished round. Returning from Home must keep the same native process and paused round. Native exit must produce a current Flutter pause screen, remove the old session, and preserve the round. Re-entering through the actual hub must produce a different token with the same owner/round and paused private rules; a second exit must return visibly to Flutter. All original preferences except this child's own current round remain equal, including other profiles, best scores, old Memory data and wallet.

The real source checkout, embedded PCK and installed APK are checked before and after. The ordinary prior tour must have passed on this exact binary/API. The probe cannot accept desktop inset fixtures in Android mode.

## Local evidence and limits

The final pure suite executed 24 cases with no failures or skips. Its first attempt had two test setup/expectation errors: a synthetic snapshot was still marked as desktop, and one expected error message had different capitalization. That original log remains. Those are not product failures. The final original image replay recognizes the existing native CI card flip and rejects reuse of the same image. No new engine, Android, Flutter, reward-round or physical-device performance execution occurred in this package.

The private fixture files are from the successful Native9f2e/Hostc0ca local Dart/Godot CI artifact, explicitly documented in their README. The production Android reader contract was cross-read against Host50503, including its unchanged C4 helper, and Native9f2e. Root reports that Native47ca keeps these Memory sources unchanged; its new execution evidence is separate.

The unit command is:

    python3 -B -m unittest discover -s tools/android_qa/tests -p test_memory_android_probe.py -v

It uses only the Python standard library and the existing C4 helper. Android capture execution additionally uses the already required Pillow/live helper environment. Native sparse reads are only scripts/games/memory/memory_table.gd and scenes/games/memory_table.tscn.
