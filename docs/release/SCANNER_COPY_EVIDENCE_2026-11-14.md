# Scanner banner correction — 2026-11-14

## Change

The displayed informational text in lib/widgets/scan_screen.dart is corrected:

Old: “🛡️ Dein Foto bleibt auf deinem Gerät. Es wird nichts ins Internet gesendet.”

New: “🛡️ Die Texterkennung läuft direkt auf deinem Gerät.”

The code, permissions, parent settings, callbacks, camera/gallery behavior,
and local learning analysis are unchanged. This is a positive statement about
the text-recognition operation, not a promise about all SDK or app traffic.

## Source inspection

Base: 4564ad40c4d000b764e67719d19bd2445c04c870.

ScanScreen passes the file path from image_picker into InputImage.fromFilePath
and then TextRecognizer(script: TextRecognitionScript.latin).processImage.
It passes the resulting trimmed text to onTextDetected. The inspected consumers
are the local ScannedWorkAnalysisEngine in the photo lesson and the corresponding
analysis path in LumoAppState.

The committed pubspec.lock fixes google_mlkit_text_recognition at 0.13.1. Its
actual published archive was downloaded read-only from pub.dev and SHA-256
checked against the lockfile:

179349417066fa2c275d7a6ed6cbceeb7fa265d73aacdb2d732f1a2991face0a

The package's android/build.gradle declares
com.google.mlkit:text-recognition:16.0.1. Its Dart processImage implementation
calls the platform channel; its Android implementation selects
TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS) for Latin and
calls textRecognizer.process(inputImage). This confirms the native ML Kit
recognition path used by the screen.

## Official supporting sources

Checked on 2026-11-14:

- https://developers.google.com/ml-kit/terms
  Google's ML Kit terms/privacy page states that input processing happens on the
  device. It separately describes SDK contacts and performance/usage metrics.
  This distinction supports the narrower replacement wording.
- https://developers.google.com/ml-kit/vision/text-recognition/v2/android
  Official Android text-recognition API and file-input processing documentation.
- https://developers.google.com/ml-kit/android-data-disclosure
  Describes SDK data disclosures and explicitly limits its version coverage to
  the latest SDK versions. No actual traffic observation for Lumo's resolved
  transitive Android dependency graph is claimed here.
- https://pub.dev/api/packages/google_mlkit_text_recognition/versions/0.13.1
  Package version metadata; the referenced archive was checked against the
  committed SHA-256 above.

No inference is made about backend retention, providers, app-wide privacy,
Families approval, or complete Google Play Data safety declarations.

## Verification scope

A repository search over the existing tests found scanner usage in
test/photo_lesson_subject_flow_test.dart and
test/feature_permission_regression_test.dart. These tests assert OCR callback
behavior and saved camera consent, not the old banner text. They need no
assertion changes for this copy correction.

The displayed string and the developer header are corrected. The header now
states the inspected local recognition/callback path and links the official
SDK metrics description. Unverified assertions about tracking, implementation
internals, image retention and automatic Families suitability are removed.
Runtime behavior is unchanged. No test duplicating this text was added and no
competing Flutter workload was started while the C4 focus slot was occupied.
Root independently opened the official ML Kit terms and Android documentation.
