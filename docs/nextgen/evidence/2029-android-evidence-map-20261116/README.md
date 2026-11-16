# Read-only map for the actual 2029 Android evidence

This is an independent source review, not an Android PASS. Reviewed Flutter/probe source: `684f54a6d11cfb5eccaec30f39fe34d6c17c82cc`; native source: `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`; pending full run: `43785937519`. No test or publication action was performed by this review.

## Match originals before interpreting results

The Android artifact contains `original-android/learning-android-result.json` and `reference-android/reference-android-result.json`. The reference must say current-build, bind QA and APK source to 684f, identify run43785937519 and native678, match installed bytes/version/certificate, and match the SHA of the complete original result. Running screenshot prefixes must be read from the current result, never copied from historical runs. Sections not reached after a failure remain untested.

## Actual acceptance observations and limits

| Area | Actual automated observation | Limit |
| --- | --- | --- |
| Flutter 8+5 | Typed Why first two question, task-grounded visible explanation, Stop/return and actual first stone tap with stored moved=1. Fields: conversation and bridge.checkpoint. | Typed conversation does not grade a school answer. |
| Native 8+5 | Native why question resets model to0, types/sends the actual question, requires automatic0→2, current explanation8/2/10/5/3 and new MediaPlayer playback IDs. `native-why-two-result.json` binds screenshots/video. | No manual movement after the question; no answer/reward API. Spoken words are not acoustically verified. |
| Flutter Banane | Actual Ba/na/ne token sequence [2,3,0], Listen/Repeat/Slower button taps followed by Stop, checkpoint/lifecycle retention. | Slower is stopped immediately; no full slow playback or measured speed difference. |
| Native Banane | Three visible syllable steps and current playback; Repeat must finish four distinct started/completed playback IDs, bound to video and screenshots. | The sequence Banane/Ba/na/ne is a source contract. No acoustic word recognition and no native slower run. |
| Pattern | Actual generated ABAB group, matching hint, unconfirmed native proposal and return to the same unanswered task. `pattern-ungraded-roundtrip.json` remains separate. | Native proposal never confirms the school answer. |
| Explicit core pattern answer | Only actual unique visible four-choice UI and exactly one new stored attempt, correct question/answer, Logik/Muster, ok=true and hint=true count as a performed answer. | core_submission=NOT_EXERCISED is permitted but is not an answer PASS. Require core_answer_submitted=true and core_submission.status=PASS for that claim. |
| Pause/return/resize | Actual foreground loss, reopening, model/progress/profile snapshots, bridge resize, native process exit on return. | Emulated dimensions are not a physical folding event, and fresh test-profile retention is not upgrade/process-death migration proof. |
| Microphone | Actual permission/recognition-service observation distinguishes listening from explicit device limitation. | No real spoken utterance. recognition=NOT_VERIFIED remains accurate. |

## Performance and interruption

`native-learning-performance.json` contains current-scene/current-PID process intervals over10–60seconds and at least two complete windows. The accepted window must actually contain coincident speech_playing_audible/fox_usable/effects samples. These samples do not mean the conditions were continuous throughout the window. Video, current replay playback and current native-speech logs bind the run; gfxinfo/SurfaceFlinger are supplemental. The metric is a Godot process interval in the software-rendered emulator, not physical ARM64 display FPS. There is no corresponding full performance check for every Banane/pattern/task variant.

Videos have no recorded audio. The current tour checks Stop UI and task continuation, not simultaneous numerical audio/mouth/gesture cancellation or its latency. Native `avatar_director.diagnostics()` internally contains mouth_mode, mouth_weights (AA/JawArticulation), mouth_supported, state, clip, target_id, point_target_id, pointing_angular_error_degrees, turn_open, audio_state, audio_audible, media_position_ms and paused. The production world does not export that dictionary through an externally readable Android endpoint/log/file. Kotlin speech status exposes state/id/positionMs/durationMs/audible/envelope internally to Godot; logcat has started/completed, no explicit stop record. Performance windows contain aggregate counters, no jaw/gesture timeline. The English-only learning_layout_v1 snapshot has no mouth/gesture fields and is not an8+5/Banane/pattern diagnostic.

The source Stop path and native model tests exist and can be reviewed as source/test evidence. They must not be relabeled as observed Android mouth/gesture telemetry. Existing APK bytes can show visible Stop-to-Listen transition and video only; a numerical coupled-stop claim is unsupported.

## Reviewed source files

Flutter `.github/probes/lumo_nextgen_learning_android_probe.py`, `lumo_nextgen_reference_android_probe.py`, `lumo_nextgen_current_reference_android_probe.py`, `run_lumo_nextgen_current_android.sh`, `tools/nextgen/prepare_current_learning_release.py`. Native `scripts/lumo_next/avatar_director.gd`, `learning_lumo_actor.gd`, `learning_world_next.gd`, `scripts/learning/learning_frame_probe.gd`, `learning_world.gd`; host `tools/auto_install/LumoLearningSpeech.kt`, `LumoGameActivity.kt`. Scope is exact existing code and future evidence interpretation, not a completed run.
