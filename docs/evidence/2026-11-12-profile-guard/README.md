# Formatted profile constructor guard — 12 November 2026

Base Host commit: `78669c05985ffda68c89f4dd5f23ebfd6a930918`.

The real portable preview-APK build stopped at the repair guard. `lib/main.dart` passes the restored `_profile` to `AppShell` in a valid multiline constructor, but the guard required the obsolete single-line text `AppShell(profile: _profile`. The application connection itself was unchanged and present.

## Narrow repair

The existing constructor-argument guard now accepts a constructor, named argument and expected variable. The existing six `appState: _appState` checks retain their wrapper and expected values. The application entry check requires the actual direct `AppShell` argument `profile: _profile` across whitespace. Quoted strings and comments are masked, and nested constructor arguments cannot satisfy the direct connection. A genuinely different profile, a missing argument, an unbalanced call or a matching phrase only in a comment/string remains a failure.

No production Dart files, app version, native source pin, package identity, signing, saves, routes or build workflow were changed.

## Evidence

- `before.log`: unmodified portable guard failure on the exact base commit, exit 1.
- `constructor-tests.log`: 19 actual-helper tests passed, exit 0. These include 12 constructor cases with formatted positive connections and adversarial wrong-profile cases, plus all seven existing obsolete-code scanner tests.
- `after.log`: complete actual repair guard, including real Flutter package resolution and analysis, exit 0. The analyzer reported no errors; its existing 5 warnings and 105 informational messages remain visible. This result does not claim a clean lint baseline or a completed APK build.
- `manifest.json`: SHA-256 of these logs and the changed guard/test files.

Commands:

```sh
python3 -m unittest scripts.tests.test_lumo_repair_guard_constructor scripts.tests.test_lumo_repair_guard_scan -v
CI=true FLUTTER_SUPPRESS_ANALYTICS=true PATH=/tmp/lumo-flutter/bin:$PATH bash scripts/lumo_repair_guard.sh
```

`CI=true` and the supported Flutter analytics opt-out suppress unnecessary SDK cloud detection and telemetry in this automated environment. No SDK or network-policy modification was made. The previously rejected metadata-access attempt remains separately documented in the local portable build record; it is not represented as successful.

The signed APK must be built again against the final published Host commit after integration and the updated strict native pin. These guard results alone are not Android execution, rendering or upgrade evidence.
