# Local English target word before the German lesson explanation

Source baseline: Host `2e20f5f24cee7a696296e6bea5618cc130a40ce2`. Native `29080ef8cd1a5b385eeeec97976fbefd31280427` stays unchanged.

## Exact source scope

The source manifest lists three changed existing product templates and seven added test/fixture files. `LumoLearningSpeech.kt` captures only a closed word/meaning/three-object descriptor from the trusted host options. The native request cannot select a different word or language. `LumoOfflineSpeechBridge.kt` keeps the existing Flutter availability and German method signature; its opt-in lesson entry returns an explicit `en-de` identity. `LumoOfflineSpeechEngine.java` generates the English word and the unchanged German explanation with the same F2 speaker, checks cancellation between the calls, and joins their actual PCM with a 250-ms gap. The total remains mono PCM16, 44,100 Hz, at most 30 seconds and below the existing envelope byte bound. There is no audio-result cache. The immutable model cache is unchanged and contains the same shared pinned weights.

The PCM helper is a static method inside the existing engine. No new production file or installer-copy change is required. `evidence/installation-source-binding.json` binds the actual existing installation loops. The playback, stop, release, status, Activity generation and mute sections remain byte-identical; the precise boundaries are recorded separately.

## Actual local result

`evidence/java-contracts-second/` records 11 Python/JVM cases with 103 actual Java assertions, including the 11 original German guards. Exit 0. The entire production Java engine was compiled without source extraction. ONNX sessions/tensors are explicit synthetic test doubles: this is neither real model inference nor Android playback, and nobody listened to synthesized audio.

The initial compiler attempt is preserved separately: the trimmed installed JDK21 exposes javac but lacks its `--release 17` system image. The actual green run uses Java source/target 17 against the installed JDK21 APIs and preserves the compiler warning. A real Android host compile remains mandatory.

## Pending Kotlin contracts and CI invocation

No local Kotlin compiler is installed; no dependency installation or local Flutter command was attempted. Eight Kotlin-backed cases are prepared, not locally passed: the unchanged original 23 envelope assertions, unchanged original 17 lifecycle assertions, plus six bounded bilingual lifecycle scenarios. The two original counts are separate from the 11/103 Java result. The historical apfel WAV is unchanged, 40,970 bytes, SHA256 `39aba71e80a9230d832f038630eaff8fa0fc0c5eae104581ce487bce9ebbd586`; it is an envelope fixture, not English pronunciation evidence. The new bilingual player fixture is explicitly synthetic PCM.

After the existing Android host compile, use its already installed Gradle compiler directory (B's wrapper resolves this without downloading a second compiler):

```bash
REQUIRE_ALL_TESTS=true python3 -B -m unittest discover -s scripts/tests -p test_english_lesson_speech.py -v
REQUIRE_ALL_TESTS=true LUMO_KOTLIN_LIB_DIR="$GRADLE_HOME/lib" python3 -B -m unittest discover -s scripts/tests -p test_learning_english_speech_lifecycle.py -v
```

`LUMO_KOTLIN_LIB_DIR` must be the real Gradle distribution `lib` directory; a missing compiler is an error when `REQUIRE_ALL_TESTS=true`. The lifecycle harness compiles the complete production Kotlin classes once and the three independent main classes into separate directories. The general Flutter client continues to expect `de` and is not edited. No branch, workflow, pin, save, reward or native product mutation is included.
