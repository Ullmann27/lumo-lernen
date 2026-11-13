# Build 2018: reject data loss, recognize the exact additive migration

The application remains Flutter `a31c0070a9c1e9dfbea08f123d7ed77e5f0a8ad9`
and Godot `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`. No APK rebuild or
application change is required by this acceptance repair.

## Actual failed update

Recovery run `43395154888`, update job `131785002468`, installed the published
2017 baseline and performed `adb install -r` with the exact 2018 candidate.
The Android user ID and first-install time were retained. The failure occurred
after the first offline launch, before Kart started. Its inherited error message
incorrectly described this phase as a Kart session.

Original artifact `14022392802` contains 48,816,664 bytes, SHA-256
`63e14a7e65ea4d96a1f818c938f4b61ff96c1429654e6984b3c28ee492b0c6fa`.
The original ZIP digest and CRC were checked. The before/after preference XML
and the traceback establish the cause; the failed result remains failed.

The one changed learning value was the active local child's skill map.
All ten original fields were identical, including one correct answer, zero
wrong answers, zero hints, streak one, difficulty one and the original timestamp.
The application added only:

```json
{"independentEvidence":{"version":1,"correct":1,"wrong":0,"correctStreak":1,"wrongStreak":0}}
```

This is the existing, explicitly implemented `IndependentEvidence.fromLegacy`
migration. Earned stars and XP were unchanged. No preference key was removed.
The daily mission's `lastSeenAt` also advanced; mission completion and accepted
task identities were unchanged. That activity timestamp was already outside the
learning snapshot contract.

## Narrow repair

Ordinary Kart and update comparisons retain their strict default. Only the
explicit 2017-to-2018 upgrade may recognize the existing additive skill
migration. It must preserve the exact original skill IDs, fields, types and
values and compute exactly the expected evidence values. Foreign children,
unrelated data, removed or modified values, unknown fields and incorrect evidence
remain failures.

After the initial migration, the actual post-update snapshot is the reference
for byte-exact checks through Kart, restart and every simulated Fold size.
Thus a recognized upgrade does not excuse subsequent changes to either old
learning data or the new evidence field.

The acceptance checkout supplies the reviewed update wrapper and helpers while
the working directory and installed APK provenance remain the untouched product
source. The publication verifier, original package/signature checks and every
live runtime gate remain mandatory.

Local fixture and regression results are recorded separately from Android
execution. Neither accepting the historical fixture nor a successful installer
constitutes a completed update tour or permission to publish the APK.

## Executed local checks and subsequent product blocker

The complete revised probe suite passed 710 tests without skips. The migration
checks passed 34 Python tests and 57 Flutter tests, including ten new checks
against the original Android skill bytes. The independent replay rejected 38
negative cases. The recorded Cards OS-service header is now covered by the
parser's tests; its exact optional `c:<package>` suffix does not relax the
binding, process or package checks.

The same Android run completed the five learning moves, both local speech
callbacks and return to the unchanged Flutter lesson. The first actual Cards
draw was acknowledged and persisted with all 112 cards. The overall run still
failed before the idle, second-draw, pause and return checks.

Visual inspection additionally revealed white card fronts. An actual Godot
replay proved that JSON numeric values produced nonexistent paths such as
`green_5.0.png`, whereas the original asset is `green_5.png`. Consequently the
`a31c0070` APK is withdrawn from publication. These successful QA repairs are
retained for a new candidate with the narrowly repaired native texture path.
No historical failed workflow is reclassified as successful.
