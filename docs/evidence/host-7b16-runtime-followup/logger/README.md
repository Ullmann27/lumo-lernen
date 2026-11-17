# API37 device log continuity and fresh speech section

This is a local repair checkpoint following the two failed jobs in QA run 43551424080, source 61c94cfb. The APK remains Host 7b16 / Native 17f5. The original jobs are still failures; no device has run this new observer yet.

## Observed problem

Both original host logcat processes ended with exit 255 around the actual adbd root transition, before the later tour endpoint. A later clear also removed the events buffer. The old interval verifier correctly rejected the incomplete recording. The host renderer case additionally contains an actual later GMS broadcast ANR. Its unchanged original bytes are a mandatory negative fixture. Neither a positive startup guard nor empty later fields can erase that event. Old root helpers provide elapsed offsets, not an absolute UTC command timestamp. `original-ci-binding.json` preserves that limit and the original file hashes.

## Repair

The explicit API37 runner starts a private detached device logcat while the original boot monitor is still alive. An actual unique log marker must appear identically in both recordings. The actual process/session/start ticks and regular-file device/inode identities must remain unchanged through one positively observed root preparation, the tours and end dumps. The process is not reconnected. Its file is not cleared or rotated. Requested TERM, actual exit 143, exact complete retrieval and prefix extension are all mandatory. Unexpected stderr, early process death, altered identities, missing markers, ANR records and failing tours remain failures. The small `wait.stderr` file retains only the shell wait notification; only empty or exact `Terminated\n` can match a positively observed requested TERM/143. Logger stderr still must be empty.

The two API37 probe clear calls are suppressed only when the current tour's runtime-start, device-start hash, positive root state and actual emulator serial/API are bound. In the native lesson, a fresh unique speech marker is written and actually read before entry. Initial speech, all five movements and final speech use that same boundary. Complete filtered reads are separately preserved, along with the complete all-buffer device original. An old completion or old movement before the marker never counts. The existing same-PID and strictly increasing completed-utterance requirements remain unchanged. Normal non-diagnostic probe clear behavior is retained. All other functions/classes in the two probe files are AST-identical to their just-before-logger versions.

## Validation and limits

* 88 focused Python tests passed, zero failures/errors/skips, exit 0; full output is `focused-green.log`. Seventeen direct source files plus HEAD were identical before/after. The existing Android17 fixture test also checks its own original fixture manifest.
* This comprises 17 new device-session contracts, 48 unchanged runtime/framework neighbors, 11 section contracts and 12 unchanged speech neighbors. A fake ADB drives the real Python collector/verifier. It is explicitly synthetic, not an Android session.
* Two fresh-section negative cases failed against the unchanged old speech functions because earlier completed utterances/moves were accepted. The full red output is `speech-old-source-red.log`. The earlier `original-source-red.log` separately demonstrates the old collector lacks the new protocol API; it is not a device reproduction.
* `bash -n` and the owned-file diff check passed. No SDK installation, new Android run, full suite, source-ref or index mutation occurred.
* Real Android session survival, remote toybox/setsid behavior, final logger stop bytes and whole-tour operation remain mandatory in the next explicitly assigned device job. A failed start is never approved; the disposable emulator owns any unfinished remote session until teardown.

`before/`, `before-clear-speech/` and `after/` retain exact source bytes. `repair.patch` contains only this agent's assigned differences, not other concurrent Root/agent work. `source-freeze.json` binds all 11 repair paths. `clear-speech.patch` isolates the extra authorized hunks. Complete original CI archives and large images are not duplicated here; their original-member/digest proofs and central paths are in `original-ci-binding.json`.
