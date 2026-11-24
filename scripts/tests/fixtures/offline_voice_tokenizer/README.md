# Original Banane tokenizer regression

The unchanged `unicode_indexer.bin` is the real 262144-byte table already pinned
by `config/lumo-offline-voice.json` (SHA-256
`8402ca48e5189a8950138580b0fff64db6f072f24ac07cd54ba8b2fbb9883b30`).
It was read from the existing verified model assets; no model/tool download was
performed. The model license is preserved alongside it. The Python gate compares
it to the current repository pin and the Java contract hashes it again before use.

The input is the exact first native Banane sentence from diagnostic run
43790709991 / job133048238984, APK source684f54a6d11cfb5eccaec30f39fe34d6c17c82cc:
`Baue Banane. Als Nächstes kommt die Silbe „Ba“.`

The compiled **production** LumoOfflineSpeechEngine constructor, prepareGerman,
ids and synthesize entry execute. ONNX session/tensor construction is explicitly
synthetic, with a zero style fixture of the required shape. A supplied cancellation
is reached only after the real tokenizer and prevents all inference. Any ONNX
run throws an AssertionError. This proves tokenizer acceptance/refusal with the
real dictionary; it is neither real model inference nor Android playback.

Before the fix, ids rejects U+201E as an unsupported speech character. The real
Android run did not record its thrown exception: its existing failed path was
silent. The local deterministic rejection supports the identified cause without
claiming a captured Android Throwable or a repaired device result.

The unknown-character negative case still reaches the production rejection;
no question character is silently removed. Existing Java voice guards also run.
