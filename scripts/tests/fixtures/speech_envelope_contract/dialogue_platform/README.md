# Explicit dialogue platform extensions

These three synthetic JVM platform sources extend the frozen producer
fixtures with `JSONObject.has/opt`, `Build.VERSION.SDK_INT` and audio-focus
request/callback surfaces. The test compiler substitutes these files by
filename while using the other original platform files unchanged.

The frozen originals in `../platform/` and every hash in `../provenance.json`
remain byte-for-byte intact. These overlays are new test infrastructure;
they are not original producer artifacts or Android runtime evidence.
