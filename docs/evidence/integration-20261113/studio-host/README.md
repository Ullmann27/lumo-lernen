# Studio host integration evidence

The isolated review uses integration base `993fa4a2415690cabfe71c37405077e103429e91`
with exactly the six published files from host commit
`a8e09123805b2bf30706c8dd1914b928ae6b24ca`. The source blobs and file SHA-256
values are recorded in `manifest.json`. No Studio working files were copied.

## Focused host acceptance

- `flutter-targeted.log`: 91 tests passed, no failures or skips. This includes the
  eight new task/renderer/launcher tests and the existing direct payload,
  native-launch, assistance and learning-evidence neighbours.
- `python-host-generation.log`: the new Android host-generation contract passed.
- The four production files remain byte-identical to the published host snapshot.
  The additional integration work consists only of tests, fixtures and evidence.

## One fixture across both runtimes

The prior host tests compared Dart maps and mocked method calls; the native
sharing regression constructed native dictionaries. Neither exercised the same
serialized host payload in Godot. The new
`test/tutoring/native_learning_serialized_contract_test.dart` closes that gap.

The fixture is generated from actual `LumoTask` instances through the production
legacy adapter, `NativeLearningActivity`, and `launchLumo3D`. The test runs the
captured call through Flutter's `StandardMethodCodec`, then serializes the actual
`learning` member. Dart's `jsonEncode` models the Kotlin `JSONObject(learning)`
boundary; this is **not evidence of running Android IPC or the Kotlin serializer**.
The native consumer reads the resulting real JSON bytes and runs
`JSON.parse_string` and the production `LearningActivity.configure`.

| Case | Original task | Expected native values |
| --- | --- | --- |
| Sharing | `12 : 3 = ?` | `equal_sharing`, `a=12`, `b=3` |
| Multiplication | `3 × 4 = ?` | `equal_groups`, `a=3`, `b=4` |
| Reversed multiplication | `4 × 3 = ?` | `equal_groups`, `a=4`, `b=3` |
| Fraction addition | `1/4 + 2/4 = ?` | `fraction_parts`, `a=1`, `b=4`, `extra=2` |
| Equivalent fraction answer | `1/4 + 1/4 = ?`, answer `1/2` | `fraction_parts`, `a=1`, `b=4`, `extra=1` |

All identities, timestamps and profiles are deterministic synthetic data. The
host compares every fresh result against `test/fixtures/learning_host_payloads.json`.
Export also verifies the four exact production Git blobs. A second successful
export reproduced the same 4,951 bytes and SHA-256:

`df186ff311e5775342793cbfd41911d9d4b5ca25a7b7083c19b8040448788264`

The identical native fixture lives at
`scripts/tests/fixtures/learning_host_payloads.json`; the native consumer is
`scripts/tests/learning_host_payload_regression.gd`. Its focused run passed
5 cases and 135 checks, including JSON-number conversion, actual operand order,
sharing/group/fraction state, restart and unchanged input. It is also attached
to the native headless regression runner.

## Preserved caller identity and persistence

The native explanation intentionally receives no new task identity field. The
original task remains owned by the Flutter caller. The host test checks the
original task ID, seed, prompt and answer after returning from the real launcher.
Return alone leaves the mission count and stars at zero. An explicit answer
through the existing persistence API stores the SHA-256 of that same task ID.
Reloading persisted mission bytes and replaying the same ID through a fresh
repository preserves the count: **0 after native return, 1 after the answer,
1 after replay**. This does not claim a full learning-screen/Android interaction;
the existing learning-screen neighbours were checked separately above.

## Reproduce the contract

Run in a host checkout containing the reviewed Studio files and the integration
test/fixture. The default test always compares with the frozen fixture; export
is optional and refuses a source that differs from the four reviewed blobs.

```bash
flutter test --no-pub --concurrency=1 --timeout=60s \
  --dart-define=LUMO_LEARNING_CONTRACT_EXPORT=/tmp/lumo-host-contract.json \
  test/tutoring/native_learning_serialized_contract_test.dart
godot --headless --path /path/to/lumo-godot \
  --script res://scripts/tests/learning_host_payload_regression.gd \
  -- --fixture=/tmp/lumo-host-contract.json
```

## Acceptance boundary

The existing native source pin and visual receipt still refer to
`ada5ed81ad62339f15289da62670c0a4f9f7f2b9`. The published native Studio candidate
is `cfa9f6657a2fda218f8752dbd21e4cfb49045a70`; native import, motion, visual and
whole-package acceptance are assessed separately. These host and JSON-contract
results do not approve an unchanged visual receipt, APK, Android build, real
device performance, speech or JNI/Android IPC for the new pair.
