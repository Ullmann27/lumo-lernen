# Bauwelt speech: verified connection boundary

**Result:** host commit `fe66edf97ae1cf8b680fd1b596ea06425352b379` prepares the
existing `build` route for the licensed local speech channel. Together with
published native commit `7c088c521fc6a3d6033040956b2f4aa255caf926`, it does **not**
yet provide a complete Bauwelt speech function. Both actual build scenes retain
the options but have no consumer or utterance trigger for this channel.

The focused host results remain valid: 47 Flutter tests, 12 Python host/offline
tests and 9 Kotlin return-store tests completed successfully. They prove the
host boundaries documented in the existing evidence; they do not prove a
native-world speech trigger or audible Android playback. No tests were repeated
for this read-only source trace, and no product source was changed.

## Exact published path

| Step | Source and actual behavior | Status |
| --- | --- | --- |
| Flutter launch | `lib/features/lumo3d/lumo3d_launcher.dart`: `launchLumo3D(scene: 'build')` includes `learningVoiceEnabled`, `localVoiceLicenseAccepted`, `learningAutoRead` and `learningVoiceRate`. Voice requires enabled settings, accepted local license and `LumoVoiceIdentity.freeOffline`. Calm mode suppresses automatic reading. | Present in fe66 |
| Android envelope | `tools/auto_install/MainActivity.kt`: the shared `learning`/`build` block copies these flags into the launch JSON and releases Flutter's local inference model. Only the `learning` route requires a learning descriptor. The integration merge retains Studio's `equal_sharing` allowlist entry. | Present in the reviewed combined host |
| Android service and plugin | `LumoGameActivity.onCreate` constructs `LumoLearningSpeech` for `learning` or `build`. `LumoHostPlugin` exposes `getLaunchOptions`, `speakLearning`, `getLearningSpeechStatus` and `stopLearningSpeech`. Constructing the service does not request an utterance. | Present in fe66 |
| Native intake | `scripts/systems/host_bridge.gd`: `getLaunchOptions` is parsed as JSON; `validated_options` duplicates the entire raw dictionary, maps `game` to `scene`, and permits `build`. `launch_options()` returns a copy. The speech fields are retained. | Present in 7c |
| Boot and routing | `scripts/app/app_boot.gd` merges the embedded host options into `SceneRouter.launch_options`. `scripts/app/scene_router.gd` maps `build` to `res://scenes/creative/build_world.tscn` and `settlement` to `res://scenes/creative/build_settlement_world.tscn`. | Present in 7c |
| Free Bauwelt | `scripts/creative/build_world.gd` consumes the child/save-slot identity. Its Siedlung/Wettbau actions call `_open_settlement`, which sets `settlementMode` and `buildSlot` and calls `SceneRouter.goto('settlement')`. It does not clear the speech fields. It also has no reader of those fields or call to `speakLearning`. | Missing speech consumer/trigger in 7c |
| Siedlung/Wettbau | `scripts/creative/build_settlement_world.gd` constructs `STATE.new(mode)` and the existing world. It has no reader of the speech flags and no `speakLearning` call. The new living-village UI is not activated by this published source. | Missing speech consumer/trigger in 7c |

The missing connection is therefore **an actual Bauwelt event/dialog calling the
native speech interface**. It is not a dropped JSON field or an absent Android
host method. The native helper's repository-wide production GDScript check also
located the existing voice-flag consumer and `speakLearning` call only in
`learning_world.gd`, not either Bauwelt script. This finding concerns the new
spoken explanation channel; it does not assert that the worlds have no music
or other audio.

## Source binding for the published native trace

The following files were fetched directly at immutable native SHA
`7c088c521fc6a3d6033040956b2f4aa255caf926`:

| File | Git blob |
| --- | --- |
| `project.godot` | `296b8b1752ebfd526aedd019907ac88efbfd0c02` |
| `scenes/app/boot.tscn` | `792c0324ae03debe7904517af52fe5473880bb8b` |
| `scripts/systems/host_bridge.gd` | `7d0c4e67ace04af02f91738368648380d573bcd3` |
| `scripts/app/app_boot.gd` | `a0805a73bf40b4a334188f6da4b134491848c96e` |
| `scripts/app/scene_router.gd` | `9cfea6e6d7f0ab5322a1e0d0b140a7109f9a6307` |
| `scripts/creative/build_world.gd` | `93bc6926de47dda1b1a8e9cb2eb77a90030690cd` |
| `scripts/creative/build_settlement_world.gd` | `5006410a5daf92afebd315645f8182d18c107c49` |

The reviewed combined host's `MainActivity.kt` has Git blob
`3fdc3a7665743b0bff64825c502c16347023fd2a`; the other fe66 production files remain
the published fe66 blobs listed in the archived village-host manifest.

## Concrete unpublished counterpart

At **2026-11-13 13:17:54 UTC**, a fresh direct query confirmed:

- `Ullmann27/lumo-godot`, ref `chatgpt/lumo-living-village-20261113`, still resolves
  to `7c088c521fc6a3d6033040956b2f4aa255caf926`. Its commit message explicitly
  describes UI integration and final economy campaign checks as pending.
- The exact local UI successor `85ac830c6ce647cd5db80302e227581c7efef322` returned
  GitHub `422 No commit found`. Its local branch is
  `chatgpt/lumo-village-ui-20261113` in
  `/workspace/scratch/5a306b6c9c68/village-ui`.

That committed local successor was inspected read-only by commit, without
copying or modifying producer files. In its `build_settlement_world.gd`, the
world combines host/router options and requires both `learningVoiceEnabled`
and `localVoiceLicenseAccepted` before exposing speech. Its new
`build_village_dialogs.gd` connects explicit **Anhören** buttons in story,
task and daily-report dialogs. `_speak` checks paused/consent/host state,
rejects empty or over-220-character text, and calls `speakLearning` with JSON
containing `id`, `text` and `style: 'explain'`. It checks the returned JNI-safe
acknowledgement through `HostBridge.durable_ack`.

This is a concrete dependency candidate for manual narration in settlement
dialogs, not a published or integrated successor and not evidence of automatic
speech in the free construction editor. No completed published counterpart
for that trigger was established by this review.

## Speech-rate and automatic-reading distinction

`learningVoiceRate` already has a real **host-side** consumer. MainActivity
accepts only finite values and clamps them to `0.70..1.60`.
`LumoLearningSpeech` reads that option as `speed` and applies it with
`MediaPlayer.playbackParams.setSpeed(speed)` when preparing playback. A separate
GDScript read of that value is not required.

`learningAutoRead` has no consumer in either published 7c Bauwelt script. The
inspected local UI successor uses explicit buttons; its manual speech path
does not establish automatic narration or an auto-read behavior. No new auto-read
feature or identity field was added during integration.

## Handoff decision

Keep fe66 classified as **tested host preparation awaiting its native trigger**.
The next reviewable package must publish the intended native UI/trigger source
and then pass the applicable focused native/host and actual Android speech
checks. The existing source pin, visual receipt, source-bound screenshots and
APK acceptance remain separate gates. Existing archived evidence files were
left unchanged; this document adds the precise downstream connection boundary.
