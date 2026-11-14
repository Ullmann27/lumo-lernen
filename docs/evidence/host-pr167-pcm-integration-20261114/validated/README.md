# PCM / installer targeted validation — published 8dd2ad1f

Source: 8dd2ad1fc2f04a8a116c15147436da3c15102b87, tree 37ac9221832bc4ec8d0b2faf98bcd1360f2d103c. All 17 frozen PCM blobs and four unchanged fixture dependencies matched the actual committed/worktree bytes before and after. The repository stayed clean; no Git or source mutation was made.

## Actual results

- Original installer + new real template expectation: expected exit 1, missing LumoSpeechEnvelope.kt in both namespaces (two original subtest errors).
- Integrated installer: three existing test methods passed, exit 0.
- Exact frozen producer learning-only Speech + Build neighbor: expected exit 1 at the actual licensed Build acceptance assertion.
- Integrated actual Speech + original Envelope: three JVM methods passed, exit 0. Actual markers report 23 original envelope, 17 original learning lifecycle, and 30 Build/consent/rate/lifecycle assertions (70 total).

The four phases took 12.442 seconds in total. Each complete combined stdout/stderr log and its original return code, timing and before/after source map is preserved. Green is six unittest methods; the 70 count is Kotlin assertions, not 70 Python methods.

## Evidence

compact-originals.tar.gz contains the unchanged frozen source manifest, source variants, original fixtures, complete phase logs/results, exact published-source bindings, orchestration and toolchain description. manifest.json lists every path, size and SHA256. Every archive member was fully read back and checked. No compiler binaries or generated class files are included.

## Scope

This is an actual local installer/synthetic-JVM result, not Android playback, audible output, lip sync, rendered facial acceptance or a release approval. The stage-only producer origin remains explicit. Both expected red failures remain original failures. The pre-test source-freeze is unchanged; this is a separate later evidence pack. Work and outputs were confined to /tmp.
