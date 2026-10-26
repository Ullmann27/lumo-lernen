# Release repair checkpoint — incomplete, do not integrate as a finished release

Work stopped immediately at the user's request. Branch
`sol/lumo-release-repair-20261026`, based on `26fced8f`, remains an isolated
work-in-progress. No workflow, app version, Godot pin, app code or historical
release identity was changed. No Actions run or publication was started.

## Findings

The current checkout has no `scripts/play`, appbundle or bundletool support.
The existing unified workflow already builds verified ARM64/x86_64 APKs but
publishing is tied to historical versions through 1999. It does not provide
the required new-candidate in-place update gate. The historical update probe
still pins 1999; its planned new-candidate arguments were not implemented.
No update-preservation PASS exists for a new candidate.

## Saved implementation, not release-ready

- `scripts/build_unified_apk.sh`: rejects untracked lib/config/assets inputs,
  records source tree identities, optionally builds an AAB with
  `LUMO_BUILD_AAB=1` after the verified APKs from the same prepared native host.
- `scripts/verify_unified_aab.sh`: draft staging verification with pinned
  bundletool 1.18.3, bundle validation, derived universal APK, existing strict
  APK verifier and a signed bundle provenance record.
- `scripts/verify_unified_aab.py`: draft source/identity/payload equality checks
  against the verified APKs; not exercised with actual Android build output.
- `scripts/LumoAabCertificateVerifier.java`: draft verification of every bundle
  payload's JAR signature against the existing public test certificate.

Only the existing public TEST signing key is used. No Play upload key exists;
this AAB would remain a staging artifact, never a Play release.

## Verification actually run

- `bash -n scripts/build_unified_apk.sh scripts/verify_unified_aab.sh`: PASS.
- `python3 -m py_compile scripts/verify_unified_aab.py`: PASS.
- Existing ABI contract tests: 4 PASS.
- Existing Gradle mirror tests: 3 PASS, 1 SKIP (Gradle unavailable).
- Existing workflow artifact/release identity contracts: 6 PASS.
- Bundletool official 1.18.3 download verified locally:
  SHA-256 `a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29`;
  `java -jar ... version` returned `1.18.3`.
- Java compilation NOT executed: `javac` is missing on PATH.
- No APK/AAB build, emulator tour, new dedicated AAB tests or public release.

## Required before resuming

Review and test all new AAB code, including unsigned/tampered bundle payload
rejection and exact AAB/APK payload comparisons with real Flutter output.
Add the new version only after integration. Extend the existing unified
workflow with exact approved source/native/version expectations and a real
1997-to-new-candidate preservation job before any publication. Preserve all
historical SHA contracts. Run full gates and verify an immutable direct APK
release before claiming delivery. There is currently no safe release dispatch
command for the new candidate.
