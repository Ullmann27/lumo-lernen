# Focused Home and Village capture QA — actual executed evidence

## Integration entries

Only these two test blobs are the final source delta:
- test/design/home_1989_premium_cards_capture_test.dart:
  4259e169976f458135618d2a831d86f917fdb688
- test/design/dorfwirtschaft_spielewelt_capture_test.dart:
  935ca225a6fa67df73f520494d61480943435595

No product source changes in this QA delta. The central integration owner may
copy these exact blobs and the accompanying evidence. The temporary
Direct-Village workflow blob a24b296011d87cb21b5e6994c6b3483f5e28210b belongs only
to repair/lumo-capture-state-20261114 and is excluded from this delivery.
The original central workflow remains ecc2ba50e6a7215e1d01eaf4510d0ae87c713b52.

## Home: real strict red, then real green

The first strict run 43583996815 on QA 857b91c4 failed four Home sizes
after opening the expansion: it began dragging before the ticker's first
elapsed animation frame, while the children were still initially clipped.
The original 9-pass/4-fail job log and complete diagnosis remain in
../home-subject-capture-20261114.

The correction pumps the initial expansion frame and then advances the
existing 650ms interval. It retains actual header tapping, first-card hit
testing, complete viewport bounds, and post-rasterization rectangle stability.

Run 43584516810, attempt 1, job 132416045501 on QA head
b5b7f6d9c2c33fd43234fc28fefd1f84f933dcea passed:
- 13 Home, premium subject-card and navigation tests;
- eight additional actual Magic/Mirror/Quest tests.

Actual checkout 58c32b76745325e4b8d5daeeb2049c6f700de3b2 is the PR merge commit.
Its complete tree f192095cae6db2b88668b167a0eb92bcda67fa5b was independently
read from GitData and is exactly the tested QA head's tree.

The original log records hits=1 for the real Mathe InkWell in every device:
phone, fold-cover, fold-open and large-text. All complete bounds and position
checks passed. Artifact 14109224498 contains eight original PNGs; the archive
byte count, SHA-256, CRC and all PNG hashes/dimensions were verified.
All four learning-cards images were personally opened and visibly show
actual subject cards, with the complete first Mathe card in view.
The four start PNGs remain byte-identical to cf2593; all four learning-card
PNGs are now different. Lower cards or parts of the heading can naturally
fall outside the viewport. These are actual scrolled app images, not a claim
that every subject is visible simultaneously at every size.

## Village: fixture lifecycle restored, actual capture and compile pass

Run 43583899148, attempt 1, used exact QA source
c54d9aa3a4dccab6c1cf677c9857abf77df66174. Village test source remained unchanged
in subsequent QA commits.

Job 132414202983 passed 27 tests across four actual commands:
two direct portal cases, four existing world-layout cases, fifteen native
launcher lifecycle cases, and six real Village capture/tap/bridge-payload
cases. The six cases preserve original-font full-word glyph checks,
current text scaling, 48dp targets, real Flutter taps and the three required
settlement launch values. The SDK TargetPlatformVariant now restores Android
state before Flutter checks global invariants.

Job 132414202800 compiled the generated Android host, MainActivity and native
game bridge with :app:compileDebugKotlin: BUILD SUCCESSFUL in 2m 56s.
This is compilation evidence, not a claim of an on-device Village return.

Artifact 14109910120 contains six actual Village PNGs. Its byte count,
SHA-256, CRC and every PNG hash/dimension were verified. The six images are
byte-identical to the cf2593 originals; independent QA opened all six and
confirmed the complete Dorfwirtschaft word without glyph clipping, including
640dp and 690dp at text scale 1.2. Three columns remain at normal 690dp;
only the required layouts use two columns. The large-text viewport ends
partway through a lower card and does not prove every lower portal at once.

## Scope still requiring final integration CI

The preceding full cf2593 run is preserved as 2619 PASS / six FAIL / zero
SKIP / 566 PNG; those six cleanup failures are not relabelled as a full-suite
pass. Each of the three Diktat repairs already has an original successful
testDone event on cf2593. A new full run on the final combined host and Native
pin is still required. This focused record does not certify a final APK,
native runtime return, or unseen PNGs.

The original logs and manifests below contain source/run/artifact identities;
no screenshot pixels were changed.
