# Local Play Android App Bundle path — 2026-11-14

## Scope

This change adds a separate local, externally signed AAB build path based on
host commit 4564ad40c4d000b764e67719d19bd2445c04c870. It does not upload to
Google Play, change the existing family APK build path, generate signing keys,
or claim Play approval.

The family APK builder remains scripts/build_unified_apk.sh. The new entry
point is [build_play_bundle.sh](../../scripts/build_play_bundle.sh), which uses
the canonical dev.ullmann.lumo.lumo_lernen package and --distribution play.
The Play build does not use the preview package or the LUMO_SIDE_BY_SIDE Dart flag.

## Inputs and command

Use a clean, dedicated checkout with the existing project toolchain and pinned
assets. The local build needs Python 3.11 or later, a JDK 17 or later, Flutter,
the Android SDK, the Godot version pinned in config/godot-source.json, and an
existing official bundletool all-in-one JAR. The script does not silently
download a tool executable or configure Play credentials.

Provide these four variables through the local environment:

| Variable | Required value |
| --- | --- |
| LUMO_PLAY_STORE_FILE | Absolute path to an existing upload keystore outside the source checkout |
| LUMO_PLAY_STORE_PASSWORD | Keystore password |
| LUMO_PLAY_KEY_ALIAS | Alias of the upload private-key entry |
| LUMO_PLAY_KEY_PASSWORD | Password for that private-key entry |

The repository's public family key and the standard Android debug alias are
rejected. The preflight also opens the actual keystore, accesses the private-key
entry, checks the certificate's validity, and records its SHA-256 fingerprint.
Passwords are not passed as command-line arguments or embedded in generated
Gradle source.

After setting BUNDLETOOL_JAR to the actual reviewed local JAR path:

    scripts/build_play_bundle.sh --bundletool "$BUNDLETOOL_JAR"

Optional arguments are --output-dir for a new output directory whose parent
already exists and --godot for the intended executable. Run --help for the exact
CLI. A nondefault global Flutter build directory, stale release AABs, or an
existing explicit result directory are rejected. The builder uses a fresh
private native checkout for the pinned Godot export. Contradictory version
environment overrides are rejected before preparation.

The output is a new result directory containing Lumo-Lernen-Play.aab,
LAUNCHER-RESOURCES.json, and, only after all AAB checks succeed,
PLAY-BUNDLE-PROVENANCE.json. A failed build can leave an unverified AAB or
generated Android files. It does not retain a success report for that failure.

The preflight can also be run before preparing an Android host:

    python3 scripts/verify_play_bundle.py --preflight --bundletool "$BUNDLETOOL_JAR"

That result explicitly says artifactBuilt: false.

## Checks on the produced AAB

[verify_play_bundle.py](../../scripts/verify_play_bundle.py) uses the real
bundletool validate --bundle=... and bundletool dump manifest --bundle=...
--module=base commands. It checks the actual manifest exported from the bundle
for the canonical package, committed version, minSdk 24, targetSdk 36, release
debuggability, Play distribution metadata, the private embedded Godot activity,
and absence of android.permission.REQUEST_INSTALL_PACKAGES in both supported
permission declaration forms.

The archive validator rejects duplicate or unsafe paths and unreviewed additional
modules. It requires the base module's resource, dex and manifest payloads, both
reviewed 64-bit ABIs, and Flutter, Godot and ONNX runtime libraries. Each native
library must be a matching ELF64 shared object with bounded program headers and
PT_LOAD alignment of at least 16 KiB.

The packaged native source receipt must match the committed Godot repository,
revision and engine version. The actual PCK header, byte count and SHA-256 must
match that receipt. The existing strict offline voice validator is reused on
the actual base-module weights, licenses, clip catalog and all clip bytes.

[LumoPlayBundleVerifier.java](../../scripts/LumoPlayBundleVerifier.java) opens
the AAB with JAR verification enabled and reads every file entry fully before
inspecting its signers. Every payload entry must have exactly one signer whose
current X.509 certificate matches the preflight upload certificate. Merely
finding signature-related filenames does not count as valid signing. Source
identity and AAB/JAR hashes are checked again before evidence is written, and
an existing evidence file is never overwritten.

## Limits of the evidence

No authorized upload signing credentials were supplied for this work. No genuine
signed Play AAB has been built or accepted here.

The report deliberately retains these independent acceptance items as false:

- playConsoleAccepted
- playDownloadSizeVerified
- aabDerivedApksTested
- runtime16KiBTested

ELF PT_LOAD alignment is a static packaging check. It is not proof of startup,
native compatibility or behavior on a 16-KiB device. Compressed base-module ZIP
bytes are reported only as archive bytes, not as Google's device-specific
download estimate. Generated icon provenance is not a launcher screenshot.
Offline voice hashes are not audible playback acceptance.

An authorized release owner must still confirm the upload certificate registered
in Play Console, version availability, the generated APKs and their download
sizes, installation and runtime behavior, device testing, policy declarations,
and release approval. Privacy/backend facts remain a separate release decision
and are not inferred by this build script.

## Executed focused verification

The new verifier source and its tests were materialized from exact GitHub blobs
after a temporary execution-environment outage. Python 3.12.14 and OpenJDK
21.0.13 were used. These focused tests actually completed successfully:

| Test file | Result | Evidence scope |
| --- | --- | --- |
| scripts/tests/test_verify_play_bundle.py | 18 passed | Synthetic manifest, ELF, ZIP, PCK and voice counterexamples; real JDK source execution rejects an invalid command, an invalid keystore without exposing secrets, a standard debug alias and an unsigned synthetic archive |
| scripts/tests/test_play_distribution_prepare.py | 7 passed | Existing family/Play host transition, external signing-input and permission-merge regressions |
| scripts/tests/test_prepare_android.py | 3 passed | Existing namespace, family signing, original host-template and idempotence regressions |
| scripts/tests/test_build_play_bundle.py | 15 passed | Real Bash control flow with explicitly fake build tools: early signing/version/source gates, stale/ambiguous/symlink output rejection, failure cleanup and the separate Play command path |
| scripts/icon_tests/test_launcher_icons.py | 9 passed | Actual icon preparation and preservation of the existing family report when a separate Play report directory is used |

The release lead executed the 28 verifier/preparation tests successfully; the
builder worker executed the 15 orchestration and nine icon tests successfully.
The combined focused total is 52. Root independently reran the initial
27 tests before the additional invalid-keystore case was added. The final source
files matched Git blobs 054324b3f9ba8b7dc269e42a20b9c91a8717b27a,
d6078bf64dde4fb25cce78635d81e7f4e0114b60,
da1aa45e530e6dfa32886df740095c3eea3c1ae2 and
6db74c257d67f193a96f4b759e09550100e081ff.

Synthetic data is explicitly marked in the tests. No fixture is described as a
real compiled Android binary, usable voice model or accepted signature.

The final 15 builder tests completed in 6.742 seconds; the nine icon tests
completed in 2.285 seconds. Bash syntax and Git whitespace checks also passed.
The icon checks used installed Pillow 13.0.0; the release tooling requirement
remains the existing Pillow 12.3.0 pin. A complete build would install and run
the icon checks with that pinned dependency in its temporary environment.

The combined real builder and real verifier were also invoked with all four
Play signing variables unset. They exited 1 with the missing-signing-input
message, no stdout, no output directory, and no new android, build or dist
paths. The checkout remained clean. Flutter, native export, model, pip and pub
steps were not reached. This is an actual fail-closed preflight observation,
not a successful Android build.

Final builder-source Git blobs are:

| File | Git blob |
| --- | --- |
| scripts/build_play_bundle.sh | 213c95f80ea4473bae5e1d8dd97e553dfd7d86c4 |
| scripts/tests/test_build_play_bundle.py | b8fdb17b6128766348dd43971f7e80d406c1f49b |
| scripts/prepare_launcher_icons.py | ebd6cb5586fd721d8e321a4ba68db26efe1a8845 |
| scripts/icon_tests/test_launcher_icons.py | 5c70341705e2db311ef4b9ead5afa5be003df1c9 |

## Official API references

- Android bundletool usage, AAB signing and generated APK testing:
  https://developer.android.com/tools/bundletool
- Official bundletool manifest dump implementation:
  https://github.com/google/bundletool/blob/master/src/main/java/com/android/tools/build/bundletool/commands/DumpCommand.java
- Official bundletool bundle-validation implementation:
  https://github.com/google/bundletool/blob/master/src/main/java/com/android/tools/build/bundletool/commands/ValidateBundleCommand.java
- Public JDK KeyStore file probing and private-key APIs:
  https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/security/KeyStore.html
- Public JDK JAR signature verification and signer-trust boundary:
  https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/jar/JarFile.html
- JAR entry signer availability after reading:
  https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/jar/JarEntry.html
- Android 16-KiB compatibility and runtime testing:
  https://developer.android.com/guide/practices/page-sizes
- Upload certificates and Play app signing:
  https://developer.android.com/studio/publish/app-signing
