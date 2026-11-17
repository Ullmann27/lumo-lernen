# Host PCM envelope integration candidate

This packet is based on published Host `43db2662e890b6468cf77f7044da16364a259482` (tree `4a70b60c254d3ee35832cb2a4b5eb9aa819e02fd`). The two PCM sources came from an explicitly frozen, stage-only producer packet. This is not a claim that those Host PCM sources were already published or validated on Android.

`final-source/` contains exactly 17 paths for Root to review and apply. Production changes are the merged speech class, the unchanged new PCM envelope class, and one additional installer tuple. The existing installer test retains both application namespaces, repeated preparation and the fictional retained-data check. Two original Kotlin contracts and seven explicit synthetic Android platform fixtures are byte-identical. The original 40,970-byte `apfel.wav` is also byte-identical. A new JVM neighbor checks the retained build scene, existing consent gates, actual media-position envelope, rate bounds, pause and late completion.

The source freeze precedes our own execution. Producer original logs remain separate under `producer-originals/`; their 23+17 assertions are not an integration run. Root should checkpoint the exact frozen paths before the combined checks. No worktree, Git index, pin, receipt or reference was changed.

After applying to a clean integration snapshot with existing Gradle/JDK tools, the targeted command is:

```sh
python3 -B -m unittest -v scripts.tests.test_prepare_android scripts.tests.test_speech_envelope_contract
```

Put the existing Gradle `bin` directory on PATH or provide `LUMO_KOTLIN_LIB_DIR` pointing at its existing `lib` directory. No compiler, dependencies or Android SDK are downloaded. The JVM fixtures cannot prove Android playback, real loudspeaker output, or native face rendering.
