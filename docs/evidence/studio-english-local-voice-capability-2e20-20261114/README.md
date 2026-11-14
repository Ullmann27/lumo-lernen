# Local English voice capability — exact Host 2e20

## Conclusion

**The pinned Supertonic 3 int8 model and F2 voice support an English input path. The current Lumo adapter exposes only German.** An internal, bounded English-cue/German-explanation implementation can retain the existing model bytes and voice. This audit does not show generated English audio, heard pronunciation, Android playback, or a new performance result.

Host: `2e20f5f24cee7a696296e6bea5618cc130a40ce2`, tree `f53e255d2edcf59977a1e23f6638b219a136ebe2`. Native `29080ef8cd1a5b385eeeec97976fbefd31280427` is unchanged. Nineteen existing Host snapshots supplied by agent A were independently rehashed against the fresh, complete GitHub tree. Their before/after hashes are identical.

## Direct model and tokenizer evidence

The official [Supertonic 3 model card](https://huggingface.co/Supertone/supertonic-3) lists English as `en` and describes local ONNX inference. More specifically, the converter's [English documentation](https://k2-fsa.github.io/sherpa/onnx/tts/all/English/supertonic-3-en.html) points to **the exact int8 archive used by Lumo**, `sherpa-onnx-supertonic-3-tts-int8-2026-05-11.tar.bz2`, and passes `extra["lang"] = "en"` while loading the same seven file names.

The small converted-model files were read from fixed mirror commit `cca5a0e6c96e1d2c720986bf7e75fcc81dee3ae4`. The official F2 reference was read from the exact already-configured upstream commit `aafc6e32416a594460b32413efc49d7fe4ce6d46`. All four downloads matched the actual Host config pins:

| Original | Bytes | SHA-256 |
| --- | ---: | --- |
| tts.json | 8,253 | 42078d3aef1cd43ab43021f3c54f47d2d75ceb4e75f627f118890128b06a0d09 |
| unicode_indexer.bin | 262,144 | 8402ca48e5189a8950138580b0fff64db6f072f24ac07cd54ba8b2fbb9883b30 |
| voice.bin | 517,168 | 67d5209b0ee8ce6c74105ffbe12fe6a7628aea3b4ba2fcb308a4a67938a93ce8 |
| official F2.json | 292,423 | 7c722c6a72707b1a77f035d67f0d1351ba187738e06f7683e8c72b1df3477fc6 |

This was 1,079,988 bytes of static configuration/tokenizer/style data. No ONNX weights or full bundle was downloaded for the audit.

The original `voice.bin` header is `[10,50,256,10,8,16]`. Comparing both complete official F2 tensors after float32 encoding against all ten entries produces exactly one match: **speaker index 1**, comprising 12,800 TTL and 128 duration-style values. The voice identity is independent of the language argument.

The [official Java helper at fixed commit 1e9799e](https://github.com/supertone-oss-archive/supertonic/blob/1e9799e964ea4c0dad7cde993b65c3c813a7b373/java/Helper.java), Gitblob `e09cbad351ca3d458b8f9a385218cf7241bf682f`, explicitly validates `en` and `de` and wraps normalized text with language markup. The exact English form is `<en>text.</en>`; `en-US` and `en-GB` are absent from the inspected accepted-language list. The existing custom Lumo Java adapter is not the Sherpa public API and cannot gain English simply by passing an unrecognized extra argument.

The actual 65,536-entry pinned indexer accepts the markup and all fourteen current illustration words/phrases: book, pen, ruler, ball, car, sun, apple, bag, rubber, school bag, desk, chair, pencil case, paper. The markup is encoded through character IDs (`<:29, e:64, n:73, /:16, d:63, >:31`), not an invented locale token. This demonstrates encoding, while the model's language capability is established by the upstream documentation for the exact converted bundle. Neither fact substitutes for an audible pronunciation check.

### Sample-rate discrepancy resolved by the original

The converter's English webpage contains a 24,000-Hz summary. The **byte-verified pinned `tts.json` contains 44,100 Hz**, agreeing with Lumo's configuration, engine, client validation and existing model contract. Preserve 44,100 Hz; the contradictory generic webpage summary must not drive a format change. The internal `tts_version` field is `v1.7.3`; that internal config string is reported without reinterpreting the model release identity.

## Actual current App boundary

| File | Exact Host Gitblob | Current relevant contract |
| --- | --- | --- |
| config/lumo-offline-voice.json | 200b67029cd4e19f27118f77b52e683c49461a6b | Pinned seven model hashes, F2, speaker 1, ONNX Runtime 1.23.1, 44,100 Hz, German profile |
| tools/auto_install/LumoOfflineSpeechEngine.java | 7a986433953773678feb4c98226caafb47c6abd9 | synthesize(text, style, cancelled) calls prepareGerman; fixed German wrapper |
| tools/auto_install/LumoOfflineSpeechBridge.kt | b40217befd633a2a606a5cd8ae732f33068a1c22 | No language argument; replies identify language de |
| tools/auto_install/LumoLearningSpeech.kt | d9adf0665b3a037c090299091340fdae76af9e3a | Native request id/text/style; bounded synthesis and generation-guarded playback |
| lib/core/lumo_offline_voice_client.dart | 81a38c5657966229fd7cdb48d0b269308fab2e92 | MethodChannel lumo_lernen/offline_speech; validates profile/F2/de/local/44,100 |
| lib/core/lumo_voice.dart | 22e7ebaa40c270fe3d0a76d22294ad3667745b08 | selectedLocale de-DE; explicit freeOffline versus Sulafat identity |
| lib/domain/tutoring/native_english_vocabulary.dart | 4469849b204f91fab3e645604e11922e29cb594c | Fourteen reviewed words derived only from validated current English tasks |
| scripts/prepare_offline_voice.py | e9d91a8d41ea520cade4f73a2dd078e4e54865f0 | Build-time model download/hash/license validation and bundled Android assets |

The German normalizer also replaces the German word “Verb” with a model-specific spelling hint “Werb”. That rule must remain exclusive to German. It cannot be reused indiscriminately for English.

## Permission and offline constraints to preserve

Native learning speech is allowed only for the learning game, enabled voice, accepted existing local model license and the selected freeOffline identity. Automatic reading additionally respects autoRead/calmMode. Inactive/destroyed activity and changed generations suppress stale output. The existing consent concerns model use; it is not a microphone permission or cloud authorization.

The build step downloads and verifies public model files once and embeds them into Android assets. The runtime copies/hash-checks those packaged files in `noBackupFilesDir` and runs CPU ONNX inference. The inspected speech path has no network, microphone, Android system-TTS or paid-service call. The wider app manifest still declares INTERNET and RECORD_AUDIO for other features, so this is a speech-path finding, not a claim that the entire app has no network/microphone permission.

Availability currently checks that the model manifest can be opened; full component validation occurs when preparing the first engine. An availability response alone therefore cannot prove successful English inference. Existing error/cancellation and visible-text behavior must remain.

The current license dialog describes the voice as German. That description is part of the present product; any later description of the added English capability must reflect what has actually been implemented and verified. This audit does not request a new approval flow or alter the existing assent.

## Minimal integration implications and limits

Agent A owns the authorized three-file Host implementation. A bounded internal en/de overload may retain the public German signature, F2 identity, all byte pins, sample rate and existing gates. The English cue should come from the already validated current lesson, not free caller-provided tags or locale values. Combining a real English cue and a German explanation requires preserving total bounds, cancellation/generation, PCM consistency and the one existing player/envelope; B reviews those implementation details.

No production file, Native source, pin, workflow, ref or installed dependency changed in this audit. No synthesis, listening, Android execution, Flutter invocation or pub-get was performed. A correct native English accent, particular regional dialect, startup latency and device frame rate remain unmeasured.

The evidence manifest contains seven small documents/config records. Larger tokenizer/style originals and full reference-source copies remain local with exact immutable source URLs/hashes, and are deliberately not reinstalled or relabeled as product changes.
