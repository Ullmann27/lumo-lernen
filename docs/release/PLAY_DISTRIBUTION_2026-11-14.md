# Explicit Play distribution preparation

Base: host `682f5991feb49d3a73ab7e2b42e23af725857ea9`, native pin
`504c8ba70d02702cbccc370d0d96c36a292c5d27`.

## Problem and behavior

The generated Android host previously requested `REQUEST_INSTALL_PACKAGES` for
every release and attached the public family test signing configuration. Its
settings updater could download and open a GitHub APK. These remain intentional
features of the direct family test distribution, but cannot establish a Play
release configuration.

`python3 scripts/prepare_android.py --distribution play` now prepares the
canonical `dev.ullmann.lumo.lumo_lernen` host with manifest merge-removal markers
for the installer permission, a native `play` distribution value, and an explicit
external upload signing configuration. It requires the environment variables
`LUMO_PLAY_STORE_FILE`, `LUMO_PLAY_STORE_PASSWORD`, `LUMO_PLAY_KEY_ALIAS` and
`LUMO_PLAY_KEY_PASSWORD` before changing the generated host. The keystore path
must be an existing absolute path outside the repository. The public family test
keystore and standard debug alias are rejected. Credential values are never
written into generated Gradle source. This validates the preparation inputs;
it does not establish a real keystore certificate or a successfully signed AAB.

The native installer rejects all installation operations unless the actual
manifest declares `family`. Dart queries that native channel before consulting
the GitHub API, starting an APK download, or opening its browser fallback. Play
settings open only the canonical Google Play listing. An unavailable/unknown
channel blocks APK updates; it cannot claim the installed version is newest.

The default preparation mode and existing family APK build scripts remain
`family`. Repeated preparation and transitions between both channels are tested.
The Play mode must be used in a dedicated generated host immediately before the
normal `flutter build appbundle --release` path; the existing family scripts
prepare their own family host and must not be used as a Play bundle builder.
The full AAB build, merged-manifest/certificate inspection, Play delivery size,
16 KB runtime, Android device tour, and Console declarations are not claimed by
this patch. No Play upload or publication was performed.

## Verified focused checks

- Seven Python Play preparation tests: merge-removal declarations,
  idempotence, family/Play transitions, missing credentials without mutation,
  test-key rejection, wrong namespace/preview/relative-key rejection.
- Three existing Android preparation tests: unchanged family identity,
  explicit stable signing, namespace/template preservation, idempotence.
- Seventeen Flutter updater tests: four Play/unknown-channel behavior tests and
  thirteen existing family/version/URL tests. The new tests fail on any attempted
  HTTP client creation, APK permission request, or installation in Play/unknown
  mode. Browser fallback is checked against the actual URL launcher channel.

Commands:

```sh
python3 -m unittest discover -s scripts/tests -p test_play_distribution_prepare.py -v
python3 -m unittest discover -s scripts/tests -p test_prepare_android.py -v
flutter test --no-pub --no-test-assets test/app_update_distribution_test.dart test/app_update_service_test.dart
```

Python fixtures use synthetic key bytes; they do not replace an Android build or
real upload-key verification. Kotlin/Android compilation and a final AAB remain
separate downstream checks.

## Primary references checked on 14 November 2026

- Google Play restricted installation permission policy:
  https://support.google.com/googleplay/android-developer/answer/12085295
- Current target API requirement (API 36 for new submissions/updates):
  https://support.google.com/googleplay/android-developer/answer/11926878
- Android publishing guidance (new Play apps use App Bundles):
  https://developer.android.com/studio/publish
- Families data practices and identifier restrictions:
  https://support.google.com/googleplay/android-developer/answer/11043825

The current Android page-size guide and older Play announcements show different
transition dates. Use the actual Console requirement and a built artifact's
alignment/runtime evidence; this patch does not assert a definitive extension
or acceptance date.
