# Existing Bauwelt narration integration

Reviewed host commit `fe66edf97ae1cf8b680fd1b596ea06425352b379` as a five-file delta on `6e33ba6d02050fd07d00c20aa3dfb4c8cff7393f`, which already includes the Studio host.

The exact patch is stored losslessly as `fe66-on-studio.patch.gz`; the manifest records both archive and uncompressed hashes. Four result files equal the published fe66 blobs. MainActivity combines fe66 narration support with the Studio `equal_sharing` allowlist; its required result blob is `3fdc3a7665743b0bff64825c502c16347023fd2a`. Replacing that whole file with the fe66 snapshot would discard the Studio addition.

Focused results: **47 Flutter tests, 12 Python host/offline tests and 9 actual Kotlin return-store tests passed, with no skipped test cases**. The first Python invocation could not set up the Kotlin class because its local library directory was absent from the environment. The separate recorded JVM invocation supplied the verified installed Kotlin libraries and completed all nine cases. The original setup log is retained rather than relabeled as a passing invocation.

The new five-scenario voice test covers allowed offline voice, mute, missing license, a different selected voice, and calm mode. Existing tests retain the learning contract, saved caller identity, rewards-before-launch, profile/navigation cancellation, warm/cold origin return, and mission access rules. Source review confirms the Android playback guard still requires both voiceEnabled and the license flag, and all existing lifecycle cancellation/release paths remain.

This delivery wires narration for the existing `build` scene. It does not activate the unfinished native living-village model and adds no village-option flag. The native counterpart and overall visual/runtime acceptance remain separate. No Android Activity compile, JNI/Android IPC, actual device speech, APK, source pin or visual receipt is established or changed by these host checks.

Exact source blobs, file hashes, commands and evidence limits are in `manifest.json`.

## Verified native boundary

On published native `7c088c521fc6a3d6033040956b2f4aa255caf926`, HostBridge and SceneRouter preserve the speech options. Neither build_world nor build_settlement_world consumes them or calls LumoHost.speakLearning. Therefore this is a tested Host preparation, not evidence of audible speech in either Build world. The native producer is working on the missing World-to-speech trigger in a separate, not yet published followup.
