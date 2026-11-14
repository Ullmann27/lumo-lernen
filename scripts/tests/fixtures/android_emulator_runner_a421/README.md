# Immutable offline action test fixture

These six files are copied byte-for-byte from
[`ReactiveCircus/android-emulator-runner` at `a421e43855164a8197daf9d8d40fe71c6996bb0d`](https://github.com/ReactiveCircus/android-emulator-runner/tree/a421e43855164a8197daf9d8d40fe71c6996bb0d).
They are used by `test_android_framework_ready.py` when no explicit
`LUMO_ACTION_TEST_SOURCE` is provided. The test performs no download and no emulator
execution. A separately supplied action checkout is still checked against exactly
the same SHA256 values before any test execution.

The original `LICENSE` is retained without modification. It contains Apache
License 2.0 with the original Yang Chen attribution. Upstream `package.json` has
an inconsistent MIT metadata entry; this fixture does not change or resolve that
upstream metadata. None of these six files is modified. Tests apply the explicit
LUMO guard only to temporary copies and run the original JavaScript with a
synthetic SDK/adb call recorder. The real CI action remains a separate checkout
at the same immutable commit, with its actual dependencies and original license.

| Original repository path | Bytes | SHA256 |
| --- | ---: | --- |
| `action.yml` | 3980 | `a7c4de9a466ae7d70a599ffdc5a27b2bccadd7b2d602e24b44f8b490cb7bbdfe` |
| `LICENSE` | 11343 | `0b64a565cedfa1ac8d2cd7cf40965e6098f97f260fe51a4df9f697a063d0a8db` |
| `src/main.ts` | 9407 | `a52d9ff8ea3b544677bbfaeb995b1db4d0cf8f9b520f34e25b0532250123358d` |
| `lib/main.js` | 11865 | `8121ea56f1c89d470071e89f80e15f932b2d8d5f711c28fc99476f34a442bc35` |
| `src/emulator-manager.ts` | 5396 | `1e9ca00c20d35d925440afc1ce82303c42cddc4c1ac196da65e39209ef87696f` |
| `lib/emulator-manager.js` | 7155 | `a63db8fe9ffb4fb3651e9a2c97f8bac5ca4ce0078a7bbe61ef2e02019082c577` |
