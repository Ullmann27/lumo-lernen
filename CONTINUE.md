# Active LUMO 2020 combined integration — 2026-11-14

Active review: https://github.com/Ullmann27/lumo-lernen/pull/497
Working branch: `integration/lumo-live-connections-20261114`.
Version: `0.13.8+2020`.
Exact native source: `7d53f29e68269c21d1d5a66bdf3d488f8e886970`.
Native review: https://github.com/Ullmann27/lumo-godot/pull/173.
Main remains protected.

## Integrated source and acceptance boundary

The complete Play-quality follow-up through `803a4e960ffb804a46b6d09417731c031f00f680`
is preserved in the host integration. The native integration also includes the
actual latest native base `f052c2795b765265dbb6f5c27b9e92b557d39a39`; all original
Wisp checks and the four additional GPU checks remain enabled.

This candidate connects the eleven game portals, the direct Dorfwirtschaft
Flutter/Android/native route, the shared drawing surface, native learning
feedback and celebrations, game-hub routes, the learning world and its garden,
and the existing learning/journal modules. Responsive Home and village title
layouts retain real touch, navigation, large-text and original-image checks.
The Diktat tests now draw on the actual shared ink surface while retaining all
progress, repeated-rating and earned-reward assertions.

The first combined host `7fd9e91683ecf703c00f100e314aced9191f7847` was tested in
run https://github.com/Ullmann27/lumo-lernen/actions/runs/43579007561.
Native C4 runtime and Android host compilation passed. Full Flutter acceptance
reported 2,612 passed, three failed, zero skipped and 546 original PNGs.
All three failures came from the outdated Diktat gesture finder; their original
failure evidence is retained. No APK was built by that failed run.

The expanded native source passed ten local probes and all 38 discovery PNG
checks. The delivery verifier passed 129 Python tests, including its negative
checks. These focused results do not replace the new combined acceptance run.
The exact current host must pass the complete Flutter and native suites, signed
APK build, Android API35 journey, 2017-to-2020 data-preserving update, and final
delivery verification before its APK can be presented as accepted.
Physical Android 60-FPS performance has not been measured.

Source provenance and original evidence:
`docs/evidence/live-root-integration-20261114/source-integration.json`.
The full acceptance runner now requires original Village, Home and Nextgen
captures. The main C4 workflow also requires all discovery probes and images,
and the delivery verifier replays both original native connection helpers.

---

## Preserved earlier project handoff

# Active LUMO 2020 Play-quality candidate — 2026-11-14

Active review: https://github.com/Ullmann27/lumo-lernen/pull/491
Working branch: `work/lumo-play-quality-20261114`.
Base review: PR485, `integration/lumo-c4-connections-20261114`.
Version remains `0.13.8+2020`. Integration base `729585db3f49ecff7f0632439f90edb882f09454`
is merged with the actual ancestry retained. Its native integration pin is
`0e26153f0e58cc05739e72923b4c563a4cf380b8`.
Main is protected.

## Implemented and independently checked

- Shape drawing uses the existing ink surface, keeps the primary pointer,
  does not scroll the parent, and drops cancelled unfinished strokes.
- Left navigation respects reduced-animation and calm settings. The recovered
  exact learning selector and the 7,552-sample / 236-family audit are preserved;
  this is structural sample evidence, not a curriculum-wide approval.
- Family and Play distribution are separated in Android metadata, updater
  behavior and signing preparation. The new local `scripts/build_play_bundle.sh`
  prepares a canonical, externally signed AAB and verifies the actual bundle.
- Connect Four's board and minimum-48dp controls share a horizontal viewport.
  Phone margins adapt before scrolling is necessary. Older Flutter-only tests
  now explicitly establish the unavailable-native-plugin boundary.
- The historical APK diagnostic uses a stable QA pin fixture while the actual
  production verifier still rejects a wrong native revision/repository.
- The scanner accurately describes on-device text recognition. Unsupported
  app-wide tracking/Families assertions are removed from its developer header.

Focused final evidence is in:
`docs/evidence/connect-four-scroll-20261114/` (15 tests, five real PNGs,
0 analyzer errors/warnings and ten unchanged informational diagnostics);
`docs/evidence/play-aab-local-20261114/` (52 tests run together by root);
and `docs/evidence/play-quality-20261114/ci-followup/` (19 diagnostic tests
after reproducing the original failure). Root opened all five final C4 images.
The small landscape scroll mask still clips some decorative edge pixels; the
actual board cells and controls remain visible.

The preserved source checkpoints are C4
`43d66732d9450657147fb9a12a7811121a9557dc` and Play
`864452466627b366bd67f53ce2d581a05897ed62`. Their real ancestry is retained
when combining the next candidate. Earlier shape/learning/distribution evidence
under the 2026-11-14 directories remains applicable only to its recorded scope.

## Integration merge verification

Checkpoint `c1fef2d548ceaf42ccde8c8d8553d81f8400c349`, tree
`a2c9c60f56d536241ccc6ac84d8bf90b26734044`, joins the previous quality
candidate `95f12c7173e6ee718b03dce67ca2d7c6543fe716` with integration
`729585db3f49ecff7f0632439f90edb882f09454`. The two add/add conflicts were
resolved by retaining the formatted audit and stronger current-grade negative
checks. The complete live-source learning audit, console/decoder repairs and
17-raster native contract remain mandatory; the two exact permitted branches
still share every source/run/PR-head gate.

On the committed merged source: 123 focused Python contract methods passed,
workflow actionlint passed, and actual Dart generation plus the production
output verifier checked 7,552 samples across all 236 selected families.
This was a local check, with no invented GitHub run binding. The first attempt
before local HEAD advanced correctly failed the immutable-helper check; its
raw failure is preserved alongside the successful committed-source run.
Evidence: `docs/evidence/quality-integration-20261114/`.

## Actual predecessor CI and the next candidate

Host `01575aafc3f5b9032900bb57520ee65e98d7546c`, run 43576227541,
passed Android host compilation and the actual Dart/rendered-Godot C4 job.
The native runtime reported 170 successful checks; root rechecked all 259
recorded image hashes and opened seven original screenshots. The complete
Flutter/capture suite passed 2,564 tests, with no failures, skips or capture
errors, and produced 546 PNGs. Root separately opened six actual Home,
Journal and handwriting originals; a missing glyph in the Schreibcoach
capture remains an explicitly bounded visual observation. All 872 build-contract
tests passed. The subsequent 928-test Android-probe regression failed with
11 errors: the historical 2019 test invoked the real wrapper against current
2020 configuration. APK build and actual Android acceptance were not reached.
These are partial results of that exact predecessor, not Android/APK approval
of this follow-up. Original artifact identities, the
unmodified Flutter summary and root observations are preserved under
`docs/evidence/quality-01575-ci-20261114/`.

The independent Astra run 43576227534 failed with one class-setup error in
its 868-test inventory because FFmpeg was absent. The repaired workflow
installs FFmpeg and explicitly verifies ffmpeg and ffprobe before retaining
the original complete MP4/test inventory. Actual decoded failure logs,
actionlint, shell syntax checks and eight existing contract tests are in
`docs/evidence/astra-ffmpeg-20261114/`.

The bounded Orange URL-builder repair removes the free-text fallback when
a recognized color also names a fruit. The identical seven tests gave five
passes and two failures on the original code, then seven passes with the fix.
Default online opt-in remains false. The independent review and raw logs are
under `docs/evidence/image-prompt-privacy-20261114-2708/` and
`docs/evidence/play-data-audit-20261114-2708/`.


The historical 2019 test now uses a temporary 2019 source fixture with the
byte-identical real wrapper and real reviewed-pin policy, preserving every
original artifact identity negative case. Two additional rejected configurations
exercise the actual entry point before a blocked runner. Production version and
pin guards remain unchanged. See `docs/evidence/studio-2019-fixture-20261114/`.


After the local environment returned, the exact repaired test blob was actually
executed with ten unchanged, blob-checked predecessor dependencies. All three
StudioUpdateWrapperExecutionTests passed in 0.043 seconds; the eleven source
blobs were identical before and after execution. This is a focused Python
fixture result, not Android acceptance; the original failed CI remains preserved.

The combined follow-up needs a fresh `lumo-connect-four-2020.yml` run on its
actual PR head. Retain all full Flutter, build-contract, native, APK,
Android-C4, 2017-to-2020 preservation and delivery-verifier gates. A green
checkpoint test or an older source's APK does not approve this candidate.

## Release items still requiring real evidence

No Play-upload-signed AAB was produced: authorized external upload signing
inputs were not supplied. The builder and validator are executable source,
not proof of Play acceptance, generated-APK runtime, download size or physical
16-KiB compatibility. See `docs/release/PLAY_AAB_LOCAL_BUILD_2026-11-14.md`.

The direct native child `0e26153f` already contains the narrow Treasure
visibility correction, the five-profile/ten-state regression and the strict
17-raster compatibility update. Independent exact-blob review found production
and regression byte-identical to the separately tested port. The old source
failed 40 of 3,221 headless checks; the corrected source passed all 3,341.
Two local X11 attempts ended with SIGKILL before producing PNGs, so no local
render approval is claimed. The actual full 52-mode rendered CI gate is still
required. Directly replacing integration with PR167's divergent `785413d3`
would lose modules; its whole tree was not substituted.


The bounded data/SDK review at the exact predecessor is preserved under
`docs/evidence/play-data-audit-20261114-2708/`. It identifies the missing full
in-app privacy disclosure and content-reporting route, plus unverified actual
operator/hosting/retention facts. Prepared manifests and static SDK inspection
are not final AAB/network evidence. The local environment disconnected during
final evidence collection; the report explicitly lists missing raw outputs.

Actual child-data/backend disclosures, Play Console declarations, signed AAB
testing, and physical device frame-rate/thermal measurements remain separate
acceptance work. No Google Play publication or Nintendo-level performance is
claimed by this source checkpoint.

The delegated work used a coordinator, a release lead, a specialist and its
review worker within four concurrent sessions total. Recover work from the
published branches and immutable evidence; role files alone do not launch
persistent workers.

Earlier notes below are retained as historical context, not current approval.

---

# Integration follow-up: repair the real Android Cup selector

Updated: 2026-11-13. This follows published Host51e92fb5/treea13ab981.
Its immutable run43502594333 completed with successful Android Host compile,
APK build,2512 Flutter tests,472 build contracts and812 Android-probe contracts
without skips. API35, API37 and2017→2019 Update then failed on the same
ambiguous Cup-caption target. Final Verify and Publisher correctly skipped.

The current patch changes only the Cup matcher in the shared QA helper, plus
seven focused tests and six exact original OCR/readiness fixtures with manifest.
The matcher keeps decorative symbols instead of promoting '= Grand Prix' into
a second real target. Existing geometry/IoU, two-frame stability, image hashes,
actual race mode, progress and pause requirements remain. Twelve focused
methods pass; original red cases remain archived. Root directly inspected the
original API35 landing image; independent Native/source/fixture review passed.

API37 SDK/CLI22/AVD/framework preparation genuinely passed. Initial actual
2017→2019 install-r/offline learning preservation passed, but later Kart/restart/
Fold checks were not reached; two older baseline language-navigation failures
also remain explicit. New Cards lifecycle runtime acceptance was not reached.
None of these partial results make the original Android run green.

Native993c, all three2019 pins, both current visual receipts, original2018
receipt, version0.13.7+2019, product code and workflow gates are unchanged.
This repaired integration source needs its own fresh required PR CI.

The completed51e auxiliary and bounded recent-work review were copied byte-exact
from the separate published evidence checkpoint. All current failure and repair
proofs are under docs/evidence/integration-20261113/host-51e-*.

Separate DraftPR474 (QA6dcc5f5d/tree5b48c96a) runs additional creative controls
against the unchanged51e APK. Its actual push run43513179062 started; the last
observed21:48 status was in progress. Its APK source must never be confused
with its QA source or any new integration source. Await the actual result and
direct Jump-video review before making gameplay claims.

Earlier integration context below is retained as historical evidence.

---

# Continue combined LUMO integration / candidate 2019

Active drafts: Native PR160 and Host PR465. This follow-up builds on published
Host 38a49f7dda404923da3955592ccb213871f2027d, tree
625b7940d9e8a4ddf32203126721efd97b3e8c2e (local twin 44dfd78d).
It selectively connects Producer318 Cards lifecycle and Android17 preparation,
and repairs the scroll assertion found by the actual 38a CI. Native source 993c,
all three 2019 pins, both current visual receipts, version 0.13.7+2019 and the
original 2018 receipt remain unchanged. Root publishes the exact new tree with
expected parent 38a49f7d; after publication, any later update must use the
actually observed current head. Android acceptance belongs to that new source.

## Current published-producer connection and prior Host CI

Producer PR466 was read at 20:04:08 UTC at
31883868bac56699dbf3b3d60a7cdb7afc496a8b, tree
5ca2eeee9ea3af3f67acbee83f19934942c1c5d5. Only its missing Cards lifecycle and
API37 preparation are connected. The current final-scroll helper and historical
APK verifier already matched. Producer pin/receipt/profile substitutions,
older workflow guards and relative Native Venv were not imported.

The Cards main-looper heartbeat renews every 500 ms only with visible Activity
and actual service authority. Pause, stop, return, destruction or lost authority
end it; stale callbacks cannot restart it. Render reads do not renew the lease.
The existing complete window and Learning/Build speech blocks are preserved.
Bounded lifecycle observations retain the original state result or exception;
they cannot replace any original Cards readiness or pixel gate. The corrected
delayed-engine fixture tests actual onStart and service binding before allowing
an active pulse. Final Cards evidence is 20 JVM/window/return plus 12 diagnostic
contracts, all passing without skips, with the original behavioral reds retained.

Both 2019 workflows modify only android-tour. API35 uses exact upstream action
a421e43855164a8197daf9d8d40fe71c6996bb0d; API37 uses that same checkout with
the reviewed additive guard immediately after the original boot-property wait.
The action's original keyevent, settings and cleanup remain. Official CLI22 ZIP
and installed files are hash-bound; original and newly generated AVD settings
are recorded. Actual API37/Android17 framework services and stable system_server
must pass before the unchanged candidate probes. The original state/disk/image
files are observed, never rewritten as a repair. Exact source and APK binding,
failure diagnostics, numeric API35/API37 measurements and separate artifacts
remain mandatory. Local 42 API37/delivery contracts and both actionlint checks
pass; the old workflows first failed the missing connection tests. This is not
an actual local SDK installation, boot or device-performance result.

The old default-scroll assertion now checks 24 gestures, 13 observations in each
direction and both final view positions. Seven existing voice/return and six
final-scroll cases pass, with the actual original 26-versus-24 failure retained.
No product scroll budget was increased. These 87 focused methods are disjoint;
their original logs and source bindings live in host-318-connection, while the
scroll-specific original repair is also retained in host-38a-auxiliary.

Original Host run 43497829121 is FAILURE on 38a49f7d. Compile job 132135471404
genuinely passed (actual AAR4.6.3 and nine required JVM classes). Build job
132135471868 passed its complete 2,512-test Flutter suite without skips, then
failed exactly one of 436 script tests: the obsolete scroll assertion. There
was no APK build, emulator tour or update test; dependent jobs skipped.
Auxiliary CI separately has eight current SUCCESS workflows, one Script-Recovery
FAILURE on that same assertion, eight expected historical SKIPs and two replaced
Change-Review CANCELLED runs. The two successful auxiliary full Flutter runs each
have 2,316 passes and 196 skips; analyzers retain 103 infos and five warnings.
Full original logs/metadata, exact failure and artifact identities are preserved
under host-38a-android and host-38a-auxiliary. No prior-source green is transferred
to the new candidate.

## Current Native source and finished gates

Native PR160 and its integration ref now point to
`993c145304c3e5f8aa947e1c7a949a8ef8685415`, Tree
`f13dd5fc5540ecb7705c5f18bf3cf8ba6e79d7a6`. Root's local Native twin is
`3497fc3cf9c3100ceb05f86c834f1668422d2dd8`.

All thirteen auxiliary workflows and all fourteen original job logs are now
clean on this exact source. The 158 successful steps and two expected
complementary Lifecycle-matrix skips are recorded separately. The repaired
Geometry run 43489950863 / job 132108137506 passed all five workflow counterchecks
and genuine import/geometry execution. Its original log ZIP 14069312290 has
SHA256 `e0719fa627076fe6034d7e902e5cadf28a9328341ec1df893619cde5843e18b7`.
Direct Head and PR-merge checkout 80f93e52 have the same exact source tree.
Original logs, metadata, source bytes and the actual new result are preserved
under `docs/evidence/integration-20261113/native-993c-auxiliary/`.

Graphics run 43489950655 completed all three jobs successfully. Three new
original archives, 62 fully decoded PNGs (36 current, 26 baseline), 40 clean
artifact logs and their source/ZIP/image bindings are preserved under
`docs/evidence/integration-20261113/native-993c-graphics/`. Root directly
opened the five current required originals, including wide/portrait Home.
The final review SHA256 is
`2c383d58a58fed9b97c857ff88bf6f97c32ceda55baa6f9606b5a62fe503f293`;
the prepared selection is
`8d2ab7a70941b1567a4f946e4c7395fffd69d4e4b73a34daf1368737544f9e90`.
The current Graphics receipt was produced by the existing recorder from these
three original ZIPs and five actual Root observations. Its SHA256 is
7b92eef83695cd35f1712b4095a6389e4d661eeabe5bf9ed03d8c0304608170a.

Nextgen run 43489950659 completed all eight jobs successfully at 19:42:56 UTC.
Original bundle 14072020645 contains 176,663,366 bytes; SHA256:
69b9112e524a6e204d8504c787768513e57e2c59a236d1488b8d6ec4e49cada0.
The unchanged frozen Host 2fa parser passes 43 Core / 24 Studio / 4 Village /
6 Puzzle-menu / 6 Touch pairs plus 32 Touch images. All four source trees are
f13dd5fc. The complete bundle contains 146 decoded PNGs (136 current, 10 baseline)
and 108 clean artifact logs. All eight full original job logs are retained.
Release 444662111 / asset 744941184 has the same exact source and ZIP digest;
the original archive job downloaded the public bytes and compared them with cmp.

Root directly opened all 19 selected Worlds originals and three selected Touch
originals. The resulting 22-image review covers nine distinct production families,
three Touch groups, all four Village states and all six Puzzle-menu states.
The separate final byte-binding record has SHA256
feff0b8174365f97088729233fb656aa9cd7f47c4c94f8923eb93187c2cbbf96.
Actual overflow, wrapping and ellipsized labels remain in the findings; static
review does not claim natural input or device performance. The existing Native
recorder produced config/nextgen-2019-visual-review.json with SHA256
1ed85c672b956792498ab3cf3948dab0bc0417ccb071e13c51ef2f1840c78943.
Complete original metadata/logs/indices and Root observations are preserved in
native-993c-nextgen. Both current receipts approve precisely 993c; no older
source or review is silently substituted.

## Geometry defect and historical correction

The prior 90d and cce original geometry jobs reported success and a positive
marker despite eleven real Parse/Compile errors. Their manually copied fixture
omitted four existing transitive source files; a nonterminal inverted grep
failed to stop the shell before the later positive marker. Historical green
API states are not reinterpreted as clean geometry proof.

The published 993c fix adds the complete unchanged 15-file dependency closure
and runs both genuine engine phases through the unchanged strict runner, with
original 120-second limits and success marker. The actual local old fixture
faithfully reproduces Exit 0 plus the marker despite eleven errors; the repaired
fixture runs cleanly in 9.697 seconds. Five synthetic counterchecks, actionlint
and an independent 18-source review support the narrow fix. The final trigger
change preserves the actually executed engine block byte-for-byte. The new
published CI confirmation above is a separate, genuine success.

The fully completed prior 90d Nextgen run 43483977169 retains its own exact
43 Core / 24 Studio / 4 Village / 6 Puzzle / 6 Touch pairs + 32 Touch-PNG contract.
Original bundle 14069131343 has 176,564,239 bytes and SHA256
`744949fb597d7a7f9442db0cee16740f241adcee3c515f6fd4154ebd2dec6800`.
All eight full job logs, frozen Host 2fa parser, complete indices, release/tag
bindings, all non-ZIP metadata and 268 original artifact-log members are now
preserved losslessly in `native-90d-checkpoint/`. Its original 146 PNGs include
136 current and 10 baseline frames. Root opened six Puzzle originals at that
source, explicitly documenting compact scrolling. That predecessor proof does
not approve 993c; its separate geometry defect still prevents overall acceptance.

## Host code repairs and scoped validation

The published Host 5d44 source connects the exact final-scroll observation,
SDK37.0 package selector for numeric API37 and absolute Native Python Venv.
The actual API37/Android17 measurement, version, identities and publish guards
remain. Six Scroll, 25 workflow/platform and 126 Android-neighbour methods pass:
157 disjoint focused methods, no errors or skips; both workflows pass actionlint.
All 1,853 bound paths stayed unchanged during the tests. Original producer
failures, stable SDK catalogs, Action implementation, local red/green logs and
independent source review remain under `host-2019-readiness/`.

The prior 2fa/851554 checkpoint retains its full 434 Script and 794 Android-QA
results with 1,246 unchanged bound paths. Original missing-Gradle diagnostics
and inherited ResourceWarnings remain preserved. No full-suite rerun or
Android execution is inferred from the current documentation/evidence update.
The original handwriting trainer, journal, child saves and game product paths
remain. The unchanged Flutter runtime retains its earlier scoped 55 checks.

Historical APK expectations remain bound to four explicit immutable Git blobs
with replacement objects disabled, while current signature/ABI/voice/PCK checks
stay enforced. The additive 2017-to-2020 wrapper retains strictly typed exclusive
opt-in; existing 2018/2019 behavior remains and the actual 2020 release pin stays
unapproved. No whole older Collector branch is substituted for stronger gates.

## Complete the actual Android connection

All three 2019 pins now identify 993c145304c3e5f8aa947e1c7a949a8ef8685415.
The actual verify_kart_graphics_delivery.verify_visual_acceptance call passed
with both current receipts, original workflow metadata and the original complete
Native ZIP. The strict pin CLI and 63 current/historical pin regressions also
passed with no errors or skips. Exact commands, original logs, source identities
and preserved-path verification are retained under host-993c-connection.
No unchanged full-suite or Android run is inferred from these focused results.

Publish the exact final Host tree to PR465 using the observed expected head, then
observe LUMO Kart graphics 2019 Android candidate on that actual Host SHA.
Required jobs are android-host-compile, verify-and-build, both android-tour
matrix jobs (actual API35 and API37/Android17), update-2019-from-2017 and
verify-reviewed-2019. ARM64/x86 APK bytes, signature, native PCK, source identity
and real 2017-to-2019 learning-state preservation must agree across their proofs.
The integration PR permits the internal completion job. A workflow_dispatch
would skip that PR-exclusive completion job, so it is not an equivalent path.
publish-reviewed-2019 requires the separate producer branch and remains skipped
on integration/lumo-connections-20261113. No APK publication is authorized here.

Main, live Host PR461 and producer dirty worktrees stay protected. Root alone
stages/commits and moves its own refs. No unattended automation is enabled.
The 20:04:08 UTC Producer check found new source only in Host PR466 (31883868).
Native 158/165 and Host 468/469 stayed at their previously reviewed heads;
newer metadata timestamps were not treated as new source work.

## Historical published graphics producer handoff

The following original producer notes are preserved as history. They do not
replace the active combined integration source, acceptance or publication scope.

The current isolated host branch is `chatgpt/lumo-kart-graphics-apk-20261113`,
based on PR #461 recovery `8eab228433f124c1e2332e3d3c2ecf462ec8b136`.
Native changes are in PR #159, `chatgpt/lumo-graphics-expansion-20261113`, based
on PR #157 source `ada5ed81ad62339f15289da62670c0a4f9f7f2b9`.
The historical 2018 notes below are retained as history, not current delivery
approval. Main and previous releases remain untouched.

1. Check the actual branch/PR heads and dirty workspaces before continuing.
   Existing concurrent worktrees are not disposal candidates. Save through the
   authorized GitHub connector with exact-tree checks and expected-SHA leases;
   do not reset, force push or depend on an unavailable authenticated CLI push.
2. Read `docs/KART_GRAPHICS_2019_QA.md` and
   `docs/KART_GRAPHICS_2019_DELIVERY.md`. The final native candidate is
   `25e3a1187234860414fa69822e7b301e75880c82`, tree
   `71b52d8ab5b14a36cb50c4dc1164ee347bd7d9b8`, graphics run `43445815461`.
   Its product files are byte-identical to `ea72b244`: only editor-import
   invocation in the graphics workflow changed. On the previous run
   `43441307548`, Worlds and Feedback succeeded; Root and their module agents opened all six
   current images in each area. Their verified original bytes are preserved in
   `docs/evidence/kart-graphics-2019-reviewed/`. The current Home capture and all
   seven new/preserved Home gates passed, but attempt 1's old-source importer
   segfaulted (exit 139). Its failure excerpt is preserved. The exact failed
   Home job failed a second time on the same old-source import. Both excerpts
   and two successful isolated full local imports are preserved. The new CI
   invocation isolates XDG before import and uses the complete --import exit
   instead of --quit. This is not a proven native crash diagnosis. The entire
   new run must pass; preserved ea72 evidence cannot approve the new source.
   No final visual receipt or 2019 APK is approved.
3. Native corrections include physical menu preview resolution, ground-connected
   winter stations with exact obstruction checks, live vehicle-effect rebinding,
   and the actual Cards header safe-area defect found in the 2018 Android tour.
   The 2018 tour's repeated Pause OCR rejection must not be hidden by relaxing
   OCR, card-face pixel, same-revision, two-frame or timeout gates.
4. Version, native config, the additive `APPROVED[2019]` entry and current-candidate
   tests now bind 0.13.7+2019 to the exact native candidate. The 24 pin-policy
   tests pass. This source identity decision follows actual current-image review
   and does not replace full workflow acceptance. After the retry and all three
   final native jobs succeed, create the dated receipt with original
   logs/PNGs/API metadata. Preserve every historical pin and the 2018 workflow,
   receipt and publisher. Recheck PR #461 for concurrent recovery before the
   final host PR. The dedicated 2019 internal PR workflow builds fresh signed
   ARM64/x86 APKs and performs the full Android tour and real 2017-to-2019 update.
5. Complete actual Android acceptance and immutable public publication. Verify
   the direct HTTPS APK bytes, signature, source identity, size and SHA-256
   before returning a link. An earlier APK or desktop image review cannot stand
   in for this candidate. Physical Fold7/Android17 performance, thermal behavior,
   audible speech and input latency remain outside emulator proof.

## Historical Next Generation / candidate 2018 handoff

Current work is on `chatgpt/lumo-nextgen-20261113`, host PR #461 and native PR #157. Do not switch back to the previous 2017 branch or replace the current dirty workspace. Main remains unchanged.

Verified starting points are host `47889f74a651b073965def70743417cf320b1eb9` (PR #459) and Godot `1d5c5cb45a323228f627ec529e6ff1ddd86f1c57` (PR #156). The real 2017 public APK now exists; PR #460 recovered publication only. It is an update baseline, never the new deliverable.

1. Inspect the actual current PR heads before continuing. Connector commits and the local base HEAD differ: no unauthenticated CLI push, automatic watcher, reset or checkout while this shared workspace contains coordinated changes. Use explicit connector trees/commits and expected-SHA ref updates.
2. Read `docs/NEXTGEN_AUDIT_20261113.md`, `docs/NEXTGEN_QA_2018.md`, the module reports, and current CI logs. Implemented learning includes seven genuine native concepts, same-task assistance, local speech integration, assisted-versus-independent evidence, and explicit reading-comprehension assessment. Games include original-Lumo Jump controls/expeditions, city economy and AI, actual Cards room/cup, garage goals and Rhythm tour. The entire master request is not declared complete.
3. Current native candidate is `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`. Earlier `e181eeca2b33390c15c1c13a8ac6eb5924fb620d` passed legacy gameplay and 24/25 new gates; the learning capture hit its 420-second software-render timeout. Its independent preview produced 21 genuine PNGs, all inspected. The runner now allows 900 seconds only for that capture. `cc6e95a9bb5f49b70758f6d749cec1504c986fcb` also passed its independent learning preview, but Root found a real plant heading/explanation mismatch in the image. The new real-touch regression additionally exposed a locked-button restart error. Both are fixed in `51fb026`: 5328 actual native learning checks pass; final native approval is recorded in item 5, and Android acceptance remains item 6. Earlier successful images never approve a corrected source automatically.
4. Host product checkpoint `bf695de27f87fca592f6fe46ebc57119a0ea6c0a` passed the complete local Flutter suite: 2462 tests, zero failed/skipped, 542 PNGs, all 47 changed Dart source/test hashes unchanged through the run. Evidence is under `docs/evidence/nextgen-cards-header-20261113/`. Full analysis exits 0 with no errors, 5 warnings and 103 information findings. Host `8a228c53c342675fd89b6ab9b662d40fb60a8535` passed actual Kotlin/Java compilation, including nine required classes; that remains historical compile evidence and the final release must compile again. Real Android speech, IPC, APK gameplay and update acceptance are not yet established.
5. Final native `51fb026f0b0e7a43b3aad30cc0fcdc144050c724` now passes all 14 workflows, including complete Nextgen run `43365141980` (all three jobs successful, all 25 new gates PASS). Native artifact `14010558382` is SHA-256 `84a71c209c7f01015b2dd1735d27087c40b2ed37fb022c406b959128d5e0bb4c`. All 66 current original images are covered by actual final module reviews and explicitly recorded byte-identical comparisons with previously inspected originals; both corrected plant images and portrait math were opened again. The genuine source-bound receipt is now approved in `config/nextgen-2018-visual-review.json`; selected originals, raw metadata, logs, metrics and reviews are under `docs/evidence/nextgen-2018-reviewed/`. No image-generation output is accepted as renderer evidence.
6. Candidate version remains 0.13.6+2018 with exact native pin `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`; historical pins remain unchanged. Both 8f2925b2 runs `43368260144`/`43368257044` compiled signed APKs and passed the original 21-check Android tour, but FAILED the new probe at the collapsed learning-tools entry. They did not run upgrade/publication. A separate real 4-case router reproduction also proved that generic native returns removed the originating Guided/Cards route. **Do not release or reuse that APK as an accepted candidate.** The original failure, raw logs and exact test are secured in checkpoint `ce2a3c0289800a93b760adbf2f403b56fd5e27c9`.
   The current repair introduces live caller-session ownership in the three existing Android host templates, preserves durable cold/legacy navigation and rewards, fixes actual tools/course navigation and retained-scroll assertions, and makes Cards readiness follow current heartbeat/revision evidence. PR synchronization is now the single automatic APK event; the historical Unified workflow rejects build 2018. Local repair acceptance: 31 Flutter route/service tests, 21 Kotlin/store/installer checks, all 304 build contracts and all 684 Android-probe contracts PASS; no skipped tests. See `docs/qa/2026-11-13-build2018-recovery.md` and its linked raw evidence. No Dart production, native source, version or child-data migration changed in this repair.
   The full workflow `.github/workflows/lumo-nextgen-2018.yml` must now pass on this actual repaired host commit: full Flutter/native gates, fresh signed ARM64/x86 APKs, live Android learning/Cards actions and speech, original game tour, in-place 2017-to-2018 update and public download verification. Use the matching internal PR run; a manual run does not publish. Speech requires real local MediaPlayer start/completion offline; the emulator's `-noaudio` does not establish audible quality or mouth synchrony. Never replace these pending gates with the old candidate's results.
7. The repository owner's existing instruction authorizes an immutable public test APK without another question. Enable the prepared publication job only after its concrete source/visual prerequisites are met; downstream actual build/tour/update/signature/provenance gates still apply. Verify release bytes, file size, signing certificate and SHA-256 before returning the direct HTTPS APK URL. Do not publish or present a failed/unverified candidate as successful.

Local toolchain: Flutter/Dart under `/workspace/scratch/e0abce7d2838/toolchain/flutter/bin`, Godot 4.6.3, Gradle 9.1.0. Original assets and child data must be preserved. There is no connected physical Galaxy Z Fold7: no desktop/emulator result establishes 60 FPS, thermal behavior or physical input latency on Android 17.
