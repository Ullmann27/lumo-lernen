# Continue combined LUMO integration / candidate 2019

The active drafts are Host PR465 and Native PR160. Root prepares published
followups in `integration/lumo-host-followups-20261113`; the published Host
integration ref remains `e5c8d6f931647b56368daefab5b924070a02f11f` until the
final exact Native source and its two reviewed evidence sets are ready.
The previous public Host review checkpoint is
`4098d8992a649640c408e89f0aeab78fd9e7d1a4`, tree
`86e6ed0f439b9ec8fda6d83d6f1e7d0c5e24b3b1` (local `fd0d777`).
Root uses exact-tree GitData checkpoints and expected-SHA branch updates.
Main, live Host PR461 and producer dirty worktrees remain protected.

## New published followups connected

The shared Native/Host acceptance now requires 43 Core pairs, unchanged
24 Studio PNGs, four Village PNGs, six additional Puzzle-menu PNGs and
unchanged six Touch pairs/32 Touch PNGs. A current Puzzle-menu image and a
Village image must each be explicitly reviewed in addition to the nine module
families and all three repaired Touch surfaces. The new six-frame set fixes
both 960x540 and 640x360 across rotation menu, rotation play and classic play.
Names, physical sizes, original bytes/hashes, full decoding and visible pixels
are mandatory. Studio's separate default profile remains unchanged.

The corresponding published Native code checkpoint is
`8a90fa9fb0db7a8f8fb45a0bd157baf476381ab3`, tree
`07591ef728f12a665ab226a74778535f05583d1d`, on the own branch
`checkpoint/lumo-puzzle-connections-20261113`. It includes published Puzzle
PR165 and retains all Loop, Village, build-goal and HUD repairs. The currently
running Native PR160 source remains cce with its frozen 41-pair contract;
8a90 has not yet received its own complete renderer/Android acceptance.

Published Host PR469's historical verifier now reads four expectation files
from an explicit full Git commit, with replacement objects disabled, and
records each original SHA256. Current verification code still enforces the
package, family signature, exact ABI set, voice assets, PCK and manifests.
Conflicting version overrides cannot reinterpret a historical candidate.
The 1999 workflow fixes its expectation commit to c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf
and preserves our internal repository/fork/branch condition.

Published Host PR468 has no missing lib/test/assets runtime. Its full branch
would discard the stronger Village gate and remove a helper imported by the
existing 2019 tests. Only its explicit 2017-to-2020 update wrapper is connected,
using an additive, strictly typed, mutually exclusive allow_2020 option.
Existing 2018/2019 wrappers and tests remain unchanged. The real 2020 release
pin is still unapproved; no 2020 version, source pin, receipt or incomplete
release workflow has been adopted.

## Exact local validation and preserved boundaries

Native runner/raster contracts pass 15 tests; affected Host scene/Graphics
contracts pass 76. Historical APK/ABI/Voice/update contracts pass 86 tests,
with all 24 bound paths and 12 protected identity/receipt/legacy paths unchanged.
The changed historical workflow passes actionlint. Original producer evidence
and these integration proofs are retained separately under
`docs/evidence/integration-20261113/host-published-followups/`.

The complete Host build-contract suite passes 434 tests with zero errors or
skips. The complete Android QA contract suite passes 794 tests, also with zero
errors or skips. All 1,246 bound paths are unchanged across the runs. The first
build-contract invocation lacked Gradle on PATH and had two setup errors plus
one skip; that diagnostic is preserved. Restoring the already installed
Gradle/Java toolchain produced the successful full run without source changes.
These are contract and Kotlin execution tests, not an APK or emulator tour.
The existing ResourceWarnings in the inherited APK hash reader are preserved
in the original logs. Earlier 414/409-test results keep their own source scopes.

Earlier 55 Flutter runtime tests apply to the unchanged lib/test/assets and
Pubspec sources. They are not current Android IPC or physical-device proof.
The original handwriting trainer, journal, child data and existing game paths
remain preserved by the combined source.

## Finish the source-bound Android pipeline

Published Native cce / tree8409 has successful Graphics, all thirteen auxiliary
workflows, Gameplay, Learning Preview, Core/Worlds, Build Touch and Treasure
Touch. Workshop and final bundling are still being collected. Root reviewed
all five current Graphics originals and all four current Village originals.
Keep those 41-pair proofs under their original cce identities; they cannot
approve the subsequent 43-pair Puzzle source.

After the final combined Native source passes its own complete Native/Graphics
runs, review its original images and record both current Host receipts. Set
config/godot-source.json, APPROVED[2019] and the candidate-2019 test constant
atomically to that accepted Native SHA. Publish the exact Host tree to its own
PR with the expected E5 lease. Then complete actual ARM64/x86 compile,
API35/API37, APK/PCK/signing identity and the real 2017-to-2019 update gates.
The integration branch does not publish an APK. No unattended automation is
running after the active session.

## Published graphics producer handoff

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
