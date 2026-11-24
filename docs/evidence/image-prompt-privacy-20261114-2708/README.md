# Image prompt privacy regression — 2026-11-14

## Scope and result

Based on Host `01575aafc3f5b9032900bb57520ee65e98d7546c` (tree `7c5d36998ebcd1a78740b26f8a6c587976806e4b`). This change only repairs the URL builder in `lib/core/lumo_image_generator.dart` and extends its existing regression test file. It does not update the running quality candidate, native pin, parental opt-in, backend, or account settings.

The old production accepts “orange” as an allowlisted fruit, treats it as a color, and then skips it while selecting the main topic. The fallback at old line 266 is the entire `childPrompt`. A synthetic name and address therefore remain in the Pollinations URL. This path is reachable: `lib/features/teacher_mode/lumo_teacher_screen.dart` passes an explicit image request's free text at lines229–230 to `_generateImage`, enables the URL builder only when `aiProxyEnabled` is true at lines391–394, then renders that URL using `Image.network` at lines775–777. No external request was made during this verification.

The repaired builder derives its main topic exclusively from the fixed translation map. If no other topic exists, an overlapping allowlisted color/fruit can be selected from that same map; its color modifier is cleared. Thus “Orange” remains a fruit and “orange Auto” remains an orange-colored car. If there is no safe dictionary topic, the builder returns null. It never uses free input as the outgoing main topic. Default/offline behavior is unchanged.

## Genuine red/green evidence

| Run | Production | Test bytes | Result |
| --- | --- | --- | --- |
| Red | Exact original 01575 file | New full regression file | 5 passed, 2 failed, process exit 1 |
| Green | Patched file | Identical regression file | 7 passed, 0 failed, process exit 0 |

`red.log` records the actual failure including `SYNTHETIC_NAME_2708` and `SYNTHETIC_ADDRESS_2708` in the old outgoing prompt. The second failure records the fruit interpretation. `green.log` records the same tests passing after the production patch.

The seven tests cover the existing opt-in and ordinary allowlist behavior, synthetic personal text alongside Orange, pure Orange as a fruit, six color/topic pairs with an extra synthetic marker, disallowed topics/colors without a topic, and default/explicitly disabled online operation. Synthetic labels are invented test data. Neither test calls an image server or contacts the deployed AI proxy.

The exact production and test files were copied byte-for-byte into a minimal Flutter test harness with the included `harness-pubspec.yaml` and lockfile. Dependencies were resolved using `flutter pub get --offline`; no new dependency was added to the app. Command: `flutter test --no-pub --reporter expanded test/core/lumo_image_generator_test.dart`. This is a focused production-function regression run, not a full application build, full test suite, device test, network capture, or proof of Play approval. The full host candidate remains under root-controlled CI.

For reproduction, create a temporary directory; copy the committed production/test files to their same relative paths; copy the harness manifest and lockfile to `pubspec.yaml` and `pubspec.lock`; use the same Flutter/Dart toolchain with cached dependencies; run the above two commands. `source-identities.json` binds source and logs by SHA-256 and Git blob identity. Independent review is requested separately; it is not claimed in this initial checkpoint.
