# Original full Flutter result on cf2593 and platform-fixture repair

## Exact source and execution

Host: cf2593cb6dec51b66461c8e5984dfbfdd5091c22
Tree: 014b2acc4cea5def174f7c51a12902c4aa2c22d6
Run: 43582160954, attempt 1
Job: 132410003806
Artifact: 14109586844, lumo-candidate-all-flutter-tests-and-captures
Archive: 368268066 bytes
SHA-256: 786e4385cda296c59e54fdce9829bbec09017fa0650d9e58e3bd04aea7e66e1e

The job log confirms checkout of the exact host SHA. The downloaded original
archive matched its recorded byte count and SHA-256; its complete ZIP CRC
check passed. Raw acceptance-summary.json is preserved unchanged. The adjacent
failed-tests-original.json and diktat-results-original.json retain the original
testStart, testDone and relevant original print/error event objects from
flutter-machine.jsonl. The original full JSONL and ZIP remain available in the
source-bound workflow artifact; selected-capture-manifest.json binds the
twenty extracted, unmodified Home/Village PNGs.

## Actual result, before the fixture cleanup

2619 tests passed, six failed, zero skipped. No capture errors were reported.
566 original PNGs were produced, including six Village, eight Home premium,
six Home nextgen and eighty learning-adventure images.

All three previously failing Diktat cases now have individual success
testDone events with skipped=false:
- d1_woerter exact subject/topic persistence: test 3262
- actual canvas and duplicate self-ratings: test 3343
- two complete sessions, twenty words each, bonuses without extra Daily: test 3355

The only six failures are the six Village capture sizes. Each failed at
TestWidgetsFlutterBinding._verifyInvariants with
"The value of a foundation debug variable was changed by the test."
All preceding original-font title/glyph, size, tap, launch and three-option
assertions completed, and all six PNGs were generated. This does not turn
the six failed tests into overall passes.

## Minimal correction

Only the test fixture changes. The handwritten
debugDefaultTargetPlatformOverride assignment with addTearDown restoration is
replaced by TargetPlatformVariant.only(TargetPlatform.android). Flutter 3.44.9
widget_tester.dart was inspected: the variant setup wraps the actual test
callback, and its teardown executes in finally before binding invariants.
Android behavior and all six actual UI/capture/launch cases are retained.
No assertion, platform route, glyph bound or global invariant is disabled.

The corrected test parsed and was formatted with Dart 3.12.2. No local
Flutter run is claimed because the isolated host and package cache are
missing. The dedicated QA branch is based on this exact cf2593 tree and must
run the existing Home and Direct-Village workflows. Its only workflow delta
is an additional push branch entry for that QA branch; all original gates
remain. The central workflow is not changed by this QA trigger.

## Home capture evidence

The separately documented Home capture-state repair requires a real visible
expansion and first subject card for every named learning-cards image.
The cf2593 Home images precede that repair and remain original before evidence.
See ../home-subject-capture-20261114 for exact hashes and observed limitations.

QA pull request: https://github.com/Ullmann27/lumo-lernen/pull/501
QA branch: repair/lumo-capture-state-20261114. Its first source checkpoint is
c54d9aa3a4dccab6c1cf677c9857abf77df66174. This documentation-only follow-up
creates the branch push needed to invoke the existing Direct-Village workflow.
The Home and Village test source blobs remain identical to that checkpoint.
