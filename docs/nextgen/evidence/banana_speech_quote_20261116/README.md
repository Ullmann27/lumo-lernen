# German opening quote: exact local speech correction

Original Android diagnostic 43790709991 / job 133048238984 remains FAILED. The actual native initial sentence contains U+201E. It is unsupported by the pinned model indexer and was missing from the existing typographic-quote normalization.

The local RED runs the actual Java prepareGerman → synthesize → ids path and rejects the original sentence. GREEN normalizes only the opening quote to the supported ASCII equivalent, preserving the words, numerals and strict unknown-character rejection. The exact indexer hash is verified. The ONNX boundary is explicitly synthetic; an inference call would fail, and cancellation ends the successful tokenizer probe before inference.

A small Kotlin change records only current failed phases/codes and numeric playback/generation identifiers. It records no source text, arbitrary error message, transcript or child/device data. Stale, stopped and destroyed owners cannot produce a current failure record. Existing started/completed lines remain byte-identical. No playback, generation, consent or scope behavior changed.

The original RED, first new-control expectation failure, corrected GREEN and source checks are retained without rewriting. Twelve Python methods passed, with nested Java/Kotlin assertions reported separately in the producer handoff. Root and Learning independently reviewed the exact component; no Android playback or acoustic PASS follows from these local tests. Component commit/tree and root integration are in component.json.
