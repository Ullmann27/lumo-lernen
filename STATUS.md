# LUMO 2020 – beobachteten C4-Testfehler und begrenzte Rückkehrabfragen reparieren

Der vollständige Lauf 43637785992 / Versuch 1 auf Host
`0cda410b9e5dceba3ffaf04f9c0fc45880dac6a9` ist tatsächlich fehlgeschlagen.
Die unveränderte Originalsummary nennt 2.732 bestandene Fälle, einen Fehler
in „Lifecycle pause during reward retry defers the settled result“ und keine
Skips. Android-Host-Compile und der gesonderte native C4-Runtimejob bestanden;
Script-/Native-Buildverträge, APK-Bau und die vier Folgejobs wurden nicht erreicht.
Der fehlende Contract-Uploadpfad ist ein Folgefehler des übersprungenen Schritts.
Eine Freigabe oder Veröffentlichung dieses Hosts ist ausgeschlossen.

Der vorbereitete Nachtrag führt vor der bestehenden Retry-Eintrittsassertion
die tatsächlich benötigte Millisekunde der Widget-Testuhr aus. Er erhält die
bisherigen Lifecycle-, Speicher-, Figuren- und Belohnungsassertionen, ergänzt
Pre-ACK-Prüfungen und sicheres Fixture-Cleanup. Produktionsdateien bleiben
unverändert. Zusätzlich erhalten die drei rein beobachtenden C4-Rückkehrabfragen
jeweils nur die verbleibende Zeit des bestehenden 45-Sekunden-Fensters. Der
bedingte Mailbox-Read, genau ein Zurück-Tap und alle nachfolgenden Prüfungen bleiben
bestehen; ein gezielter Test kontrolliert die tatsächlichen subprocess-Timeouts.

Dieser Commit ist ein Quellcheckpoint vor der begrenzten lokalen Nachprüfung.
Ein neuer erfolgreicher Gesamtlauf wird hier nicht behauptet. Native bleibt
`f9d9772bb932d7ee8702eeb5bca6d98c286f3b98`, Version `0.13.8+2020`; der komplette
siebenstufige Workflow und sämtliche Freigabebedingungen bleiben unverändert.
Neue Kartentwicklungen aus PR 183/184 werden separat geprüft. Main, frühere
Releases und vorhandene Nutzer-/Lernstände werden nicht verändert.

## Archiv: voriger Aktivierungsstand

# Current candidate: confirmed storage and explicit 3D entry

Updated: 2026-11-14 20:28:38 UTC. This documentation/evidence activation follows
Host `ea5748f42c82b8f0690ce32f42dc3a01342af392`, tree
`65f2d0aa1fec45cd4c875154fe230a1f8c8e0aa9`.
Version remains **0.13.8+2020** with exact Native
`f9d9772bb932d7ee8702eeb5bca6d98c286f3b98`, tree
`4036a20ab80de78bcdf0d074b585be88c2946492`.

## Connected repairs

Memory now requires a positive storage write response before acknowledging a
validated restored or recovered snapshot. A matching native preference cache
does not itself prove a committed write. The earlier 7ac description overstated
what reload alone establishes; the explicit confirmation barrier supersedes it.
Existing corrupt, historical unowned and foreign-child data remain protected.
Wallet retries confirm the same saved result without granting another reward.

Four-in-a-row opens its playable Flutter board first. Native 3D starts after the
visible "In 3D weiterspielen" action. The existing failed-bot and terminal-reward
retry mechanisms are retained together with the new opening guard.
Both actual Android openings now observe the loaded 3D control within the
existing 30-second destination wait, then require fresh original UI/PNG
observations before the touch. Return, mailbox closure and the 900-second total
budget remain. The saved-route test now covers 320x740 and 640x360 displays.

The two synthetic JVM speech adapters now match the production signatures,
constants and optional JSON object/array access. The production speech sources
and all original 23/17/30 PCM, lifecycle and consent/rate assertions are unchanged.
English synthesis is not simulated by these German-only fixtures.

Garage observation reuses the current hash-bound original frame analysis and
waits only for a changed or unqualified observation. Existing Boru word recovery,
two-frame acceptance, clipping, gesture and time limits remain.

## Validation state at activation

Source checkpoint ea5748 changes 19 existing source paths and adds four tests;
all other existing paths are preserved. Native pins, all historical releases,
the complete C4 workflow and publication verifiers are unchanged. Independent
source reviews and the selected **82 visible Flutter-case catalogue** are bound
to the exact checkpoint in the accompanying evidence.

One isolated **54-method Python invocation is running** on the exact checkpoint.
It uses eleven hash-bound materialized sources with the other 4,914 tracked paths
explicitly absent. Its completed original result will be preserved separately;
no local PASS is claimed by this activation. The full workflow independently
executes the entire current Android-contract suite. Running these validations
in parallel does not waive either result or permit publication after a failure.

The preceding 7ac run **43632790204/1** remains FAILURE: native runtime and actual
Android compilation succeeded, its complete Flutter stage passed 2,686 visible
cases with zero failures/skips, then the build-contract stage failed because its
old speech fixtures lacked the production API. Four downstream jobs were skipped.
The complete historical originals are preserved in evidence commit
`8f3d3b6721a41062c99f1ac10bdf122e3ec60709`.
The earlier local Garage invocation also remains incomplete: 51 explicit
successes before its 240-second outer interruption, not a 109-case acceptance.
A static follow-up found no demonstrated fake-clock loop in the last named case;
the actual duration cause remains unestablished.

## Complete delivery gate

This activation requests the existing seven-job workflow through PR485 on
`integration/lumo-c4-connections-20261114`. Bind its actual activating Host/tree,
run and attempt after the event. Every runtime, compilation, full test, signed
ARM64/x86 APK, real Android tour, 2017-to-2020 preserved-data update, candidate
verification and delivery-bundle gate remains mandatory.

A public APK requires the accepted same-source bundle, current PR head, exact
signature/native/source identity and complete unauthenticated HTTPS APK byte
verification. Release and tag coachpreview-build-2020 were both absent at the
20:27 UTC preflight. No APK or new complete Android acceptance is claimed here.
Keep the active head stable while its run executes; prepare later producer work
on a separate branch. Main and producer refs remain protected.

---

# Historical source notes below

The following records retain their original source identities. In particular,
their older reload-only storage claim is superseded by the correction above.

# Activate the complete Memory, Quiz, English and return-repair candidate

Updated: 2026-11-14. This activation follows the fully published source checkpoint
`05d96d94d9e08f083ea451c3f4d661fb77fee9c5`, tree `36db95e0b283526ece10aea39b37cfe9aa926775`.
Version remains **0.13.8+2020**, with exact Native `f9d9772bb932d7ee8702eeb5bca6d98c286f3b98`,
tree `4036a20ab80de78bcdf0d074b585be88c2946492`, Godot 4.6.3.

This documentation-only successor requests the existing complete seven-job C4
workflow through PR485 on `integration/lumo-c4-connections-20261114`.
Its actual run, attempt, source and artifacts must be bound after activation.
No new complete APK, Android tour, update result or public release is claimed here.

## Connected product behavior

- Memory and Quiz now use their private native transport with the existing Dart
  rules, authority, persistence and reward ownership. Existing learning modules,
  writer, InkSurface and journal sources remain intact.
- The English object scene preserves its own fitted camera after the garden
  wrapper layout. The original Lumo and the existing 48dp minimum remain.
  The existing offline speech connection is preserved; no audible pronunciation
  or physical-device frame-rate acceptance is inferred from desktop checks.
- Memory reads reload the platform preference snapshot before acknowledging
  stored round/statistics state. Optimistic cache values after failed writes
  cannot impersonate durable saves.
- Reading summaries remain stored and their public API remains available.
  Competence reports use learning SkillRecords; ASR alignment observations
  do not establish confirmed reading competence or current-profile provenance.
- Village return observes fresh, uniquely bound frame/OCR/UI/process evidence
  under its shared 60-second local return limit and unchanged 900-second total.
- C4 return observes actual native exit, the correct MainActivity and a successful
  empty mailbox query together within its unchanged 45-second limit.
  Both probes retain their one explicit return touch and fail-closed checks.
- The Android preparation adds only the Godot downloader notification manifest
  declaration. Existing private Cards/C4/Table services, reflection rules and
  repeatable preparation are preserved. No runtime permission grant is added.

## Actual evidence already bound

The five-group run **43629637557/1** succeeded on Host
`b3c2bd008b4f1b07b4bfcb19f61839c4486b77e1` with the same exact Native above:
Flutter 53 visible cases; Android host compilation plus 19 orchestrator,
11 Java and 8 Kotlin cases; Quiz 381 checks/6 captures; Memory presenter
7020 checks/8 captures and pair 243 checks/57 inputs; English
7635 checks/17 captures/196 inputs. Full logs, final APIs and exact scope
are attached under `docs/integration/2026-11-14/next-candidate/qualification-b3-f9`.
This qualified predecessor result is not transferred to later changed Host files.

The frozen return repairs each ran once: Village **46 PASS**, C4 mailbox
**54 PASS**. The exact combined notification manifest case **1 PASS**.
Current pin contracts **64 PASS** (24 Candidate + 40 Legacy), all 50 historical
pins unchanged. Independent source reviews and full original outputs are retained.
The PR494 producer has 24 new cases (14 Memory + 10 reading) within its actual
2632-case successful suite on `28462a7547048b75fa114e6f5832248e54c94faa`.
Those remain producer results until this integrated Host is actually executed.

## Complete APK delivery still required

The old run **43614047730/1** on Host `5ad005bd` remains failed at the
Village returned-frame check. Its successful build and preserved 2017-to-2020
update do not clear that failure. No old APK is the new candidate.

The unchanged C4 workflow must execute exact source: native runtime, actual
Android host compilation, full Flutter/script/Android-contract suites, signed
ARM64 and x86_64 builds, the actual main/Village/C4 Android tour, the preserved
2017-to-2020 update, candidate verification and delivery bundle preparation.
Only an accepted same-run bundle may enter the prepared publisher. A new immutable
`coachpreview-build-2020` release requires the verified signature, source/native
identities, SHA256 and complete unauthenticated HTTPS APK byte verification.
The release and tag were both absent at the 19:31 UTC preflight.

Main, producer refs and old releases remain protected. Keep this active C4 head
stable while its workflow runs because its concurrency policy cancels superseded
runs. Further producer work belongs on separate integration preparation branches.

---

# Historical record below — earlier candidates and results

# Activate the checked Hub, native notices and Garage connection

Updated: 2026-11-14. This documentation-only activation follows exact Host
`9f2f3690caacadbe7ced363f0e810f0cc0b5eb9b`, tree
`4159e7ab2212aca6e3347aa5f08544bdfdb30c26`. Version remains 0.13.8+2020.
The actual new complete C4 run must bind the activating successor, its own
attempt and original artifacts. No complete new Android result is claimed here.

## Integrated behavior and actual focused evidence

The existing Flutter games hub now exposes the guarded 56dp native 3D world
entry while retaining all 11 original portals. The exact predecessor Hub 036e
passed six Flutter cases and real Android host compilation in run 43609106020.
That focused result is retained with its original source identity.

All three current native identity locations bind
`2281d990fb584db6f2cf786da8fec3badc2d9585`, tree
`d7e0128afbda641cb92e29c41a8839d901ef5b43`. All 50 historical pin values
remain identical. One actual 1158-source invocation passed all 64 existing
Candidate/Legacy contracts without failures or skips. The new Native Android
export explicitly retains the three existing attribution/notice texts, removes
six stale references to absent model files and restores the unchanged web
bundle script executable mode. A real Godot 4.6.3 export plus separate PCK
reader confirms all three texts byte-identical to their original Gitblobs.
A separately bound fresh baf export contains none of these three members;
this does not assert a retrospective inspection of a historical shipped APK.

Garage input now derives a short gesture from the current observed list clip,
workshop outline and scrollbar. Complete unambiguous interior captions and
two current observations remain mandatory before a vehicle tap. The original
Boru word parser, driver/cup/save/continue functions and standalone pause
caption guard remain unchanged. The six complete relevant/neighbor suites
ran once on 9f2f: **103 PASS, 0 failure/error/skip, exit 0**, 86.912749 seconds
wall time. All 4545 index paths, 1677 materialized files, HEAD/tree, flags,
raw index and Git status remained unchanged. These are source/image replays;
they do not substitute for the actual new Android tour.

Originals are retained in
[Garage acceptance](docs/evidence/host9f2f-garage-acceptance-20261114/),
[Native PCK comparison](docs/evidence/native2281-packaging-acceptance-20261114/),
[64 pin contracts](docs/evidence/host1158-pin-acceptance-20261114/) and
[Hub CI originals](docs/evidence/hub036-accepted-source-20261114/).

## Required complete acceptance

The C4 workflow and its 150/80-minute outer budgets remain byte-identical.
All individual deadlines, 52 native modes / 17 rasters, Dream and Discovery
gates, Village, signed ARM64/x86 identity, actual Android C4/main tour and
2017-to-2020 preserved-data upgrade remain mandatory. Writer, InkSurface,
Journal, child profiles, learning state and exact publication verifier are
unchanged. PR485 and the protected Main branch retain their established roles.

The preceding 0b7/baf run 43604903064 has actually completed Runtime, Host
compile, 2608 Flutter cases, 877 build/preservation methods, 994 Android-QA
methods and the complete
Native/Dream/Discovery stages, then signed APK build and hash verification.
Its Build job 132478533146 ended SUCCESS at 16:03:00 UTC. Its Android/update
jobs had only just started at activation preparation. Those original results
remain bound to 0b7/baf and do not approve this new successor.

The separate publisher source remains 72143d3586109967773d6442072d486c11dc1449,
with its actual 32 isolated tests and corrected absolute-path workflow plan.
Activation requires the actual final successful seven-job candidate, its
original delivery bundle ID/digest/size, current PR head and fresh full
release/tag checks. No public APK URL is approved before public-byte verification.

## Preserved preceding records

# Separater Folgeanschluss: vorhandene native 3D-Spielewelt

Der Quellcheckpoint `1735ef3e9010f2d28b9dbff087a03730bdc6ca8a` verbindet die vorhandene native Spielewelt über einen sichtbaren 56 dp-Einstieg mit Flutter. Er basiert auf Host `0b7bacadd3cdc45d22a8e038c5df50ba8b739d62` und behält Native `baf148b03a7a32c6ad9f737d731f900eb9113ea1` unverändert.

Diese Aktivierung gehört ausschließlich zu `integration/lumo-next-hub-20261114`. Der vollständige C4-/APK-Lauf 43604903064 bleibt auf seinem aktuellen 0b7-Stand. Die zwei neuen Fokusjobs führen den Original-Einstiegstest, die vorhandenen Dorf-/Spielrouten und eine echte Kotlin-/Java-Kompilierung auf der neuen kombinierten Quelle aus. Bei Erstellung dieser Aktivierung sind deren tatsächliche Ergebnisse noch offen.

Änderungsumfang: drei Produktdateien, ein originaler aussagekräftiger Flutter-Test und ein isolierter Workflow mit Lesezugriff. Die bestehenden elf Kacheln, Profile, Datenformate, Schreibtrainer, Journal, C4-Autorität, alten Releasepins und bestehende vollständige Abnahme werden erhalten. Die Android-Datei enthält genau ein zusätzliches Allowlist-Element `games`; alle anderen Bytes ihrer aktuellen Integrationsbasis sind erhalten.

Die sechs bestandenen Producer-Fokustests und dessen Android-Kompilierung gehören nur zu 5259bfe. Der eigene Sourcecheckpoint ist getrennt belegt. Die vorhandenen nativen Boot-/Hub-/Rückkehrdateien wurden unabhängig blobgenau bestätigt. PR505s verändertes C4-Startverhalten bleibt wegen seiner drei tatsächlichen aktuellen Regressionen ausgeschlossen.

Originalquellen, Fehlerlogs, Patch, Erhaltungsprüfung und Herkunft: `docs/evidence/next-hub-connection-20261114/`. Keine neue APK- oder Gerätefreigabe ist mit diesem Fokuslauf verbunden.

---

## Unveränderter vorheriger Integrationsstand

# Diktat progress fixture repaired and checked — 2026-11-14

This documentation/evidence-only activation follows Host
`cfa4725263f15e9cc3f75d8f6dfae0949fbb86ab`, tree
`d0fedc2ceeb02e7eefea61b2667195a43f14bdf6`. The sole executable delta from
Host79c7 is the existing Diktat progress test helper: it now selects the actual
four `LumoInkSurface` rows inside the actual `WortDiktatScreen`, makes the first
row visible and performs the unchanged real drag/Fertig/self-rating flow.
All original test bodies and progress, persistence and bonus assertions remain
byte-identical. No product, Writer, InkSurface, Journal or child-data code changed.

The complete existing test file ran exactly once on cfa4725: **17 PASS,
0 failures, 0 skips, exit 0**, in 59.552 seconds with the existing locked packages
and `--no-pub`. The original machine stream ends with success=true. All 4,475
index entries, 2,342 materialized files, HEAD/tree, raw index and package inputs
are unchanged. Full original evidence and the independent source review are in
[the Diktat acceptance pack](docs/evidence/host-diktat-acceptance-20261114/).

Both earlier complete C4 Flutter results remain failures: Host37ec recorded
2,605 passes and the three obsolete-finder errors before its later cancellation;
Host79c7 run43603036260 ended FAILURE at 14:23:35 UTC with the same 2,605
passes, three errors and zero skips. These are not runtime-product successes
and are not relabelled by this focused repair. The full pipeline must now
run on this exact successor, with its own attempt and original artifacts.

The fixed Native source remains
`baf148b03a7a32c6ad9f737d731f900eb9113ea1`. Its separate original Native run
43600806315/attempt1/job132464933411 succeeded: 47 Python methods, four
headless groups, Dream5/7/2, Discovery10/38/2, Village339/42/46 and rendered
Mobile428 with 4 safe-area plus 9 minimap PNGs. All 60 PNGs were technically
decoded; Root directly inspected exactly the 15 new Village/Mobile/Minimap
images. This does not claim Android, device FPS or a full Host acceptance.
[Native result and Root observations](docs/evidence/host-diktat-acceptance-20261114/native-handoff.json).

Outer Host/Android budgets remain **150/80 minutes**; every inner deadline,
release verifier and historical pin is unchanged. PR485 is still the integration
candidate. The separate publisher is preserved on
`integration/lumo-c4-publisher-20261114` at 72143d3586109967773d6442072d486c11dc1449;
its actual source9799d1d passed 32 isolated contracts once, without any live
release operation. Publication requires a complete successful new seven-job
C4 run, the authenticated prepared bundle and verified public APK bytes.

## Preserved preceding activation and evidence records

# Activate the verified complete-build budget

This documentation/evidence-only activation follows published Host
`c77e2456ac8eb7e02a9950e7b764684da6f5eb7b`, tree
`d124623c936de7d2fe142a22c2683dfbb1343ac2`. Its actual single Delivery
regression invocation passed all **71 methods**, with exit 0 and no failures,
errors or skips. One Actionlint invocation passed the exact changed workflow.
All 4,460 index paths, 749 materialized sources, HEAD, tree, raw index and
Git status remained unchanged. Full original streams, invocation and inventories
are preserved in [the actual validation pack](docs/evidence/host-budget150-acceptance-20261114/).

The effective outer Host build/Android budgets are **150/80 minutes**.
Individual probes, exact Native pin, every runtime/product file and all
release verifiers are unchanged by this activation. The actual complete
C4 workflow must bind this successor, its attempt and original artifacts.
Previous run 43601673844 remains bound to Host37ec; its successful Runtime
and Android compile do not substitute for this new source run.

## Preserved correction and preceding activation records

# Current build-budget correction — 2026-11-14

This narrowly scoped successor follows Host
`37ec6c6aee67c31ce16550cd59d616c80e80e305`, tree
`6ab0e6cafc9fb37d3b3d95d76805aff4b6810d7a`. Its unchanged Native pin is
`baf148b03a7a32c6ad9f737d731f900eb9113ea1`. The current outer Host build
budget is **150 minutes**; the Android budget remains **80 minutes**.
Every individual probe limit, required gate, source/PR binding, signature
policy and publication check remains unchanged. Only one workflow value
and its two existing Delivery-test expectations change.

The reason is original predecessor run 43590864772, job 132436033818:
the service recorded a 90-minute whole-job timeout during APK construction.
Its original API timeline shows 22m06 before Native, 64m07 for the Native
step and 1m17 for Dream. The current integration also includes the additional
Discovery stage (19m05 actually observed on c300). The new outer limit leaves
reserve for the real APK build, verification, upload and runner variation.
Root read the original API and the separately published timeout observation;
no current-candidate timeout or new Android success is claimed.

The 37ec run 43601673844 belongs to the previous source, even though its
Runtime and Android-compile stages completed successfully. The corrected
successor requires its own exact-source complete workflow. Local verification
of the budget correction follows its published source checkpoint. Originals:
[`docs/evidence/host-build-budget150-20261114/`](docs/evidence/host-build-budget150-20261114/).

## Previous activation notes retained verbatim

The following 120-minute references describe the preceding activation and
are superseded only by the current outer build budget stated above.

# Combined 2020 candidate: fixed-source acceptance activation

Updated: 2026-11-14. This documentation-only activation follows the published
Host pin checkpoint
[68f86b7dafa2dcd1e42ee019c4be46b9e9bdc697](https://github.com/Ullmann27/lumo-lernen/commit/68f86b7dafa2dcd1e42ee019c4be46b9e9bdc697),
tree ecd5df0797c2b4102f2c7bbc30146f3061d713ce, whose parent is evidence
checkpoint a9e03188083db5517d0614b2acfa289342f2de8b. Version remains
0.13.8+2020. The actual acceptance run must bind its own final Host commit,
including this documentation change.

All three current 2020 pin locations now identify Native
[baf148b03a7a32c6ad9f737d731f900eb9113ea1](https://github.com/Ullmann27/lumo-godot/commit/baf148b03a7a32c6ad9f737d731f900eb9113ea1),
tree 0c18a0ca5200ade267cfedb4c12d5c4b0a761a00. Historical approved pins
are unchanged.

At activation preparation, Native run
[43600806315](https://github.com/Ullmann27/lumo-godot/actions/runs/43600806315),
attempt 1, job 132464933411, is in progress and has no final renderer
acceptance. Actionlint and Mobile 380 checks passed on parent
4d2cbb6ea235c7bf519aa5f3873a16f6b177be2b with the same product/workflow
blobs; their original proofs are preserved in the Native activation commit.
Those parent-source results are not a completed new renderer run or a new
combined Android acceptance.

## Final pin check before activation

On published Host 68f86b7dafa2dcd1e42ee019c4be46b9e9bdc697 with Native
baf148b03a7a32c6ad9f737d731f900eb9113ea1, one actual local invocation
passed all 64 existing pin contracts (24 Candidate and 40 Legacy), with
exit 0 and zero errors, failures or skips. All 4,440 index paths and all
seven required materialized original sources remained unchanged; the other
4,433 index paths were explicitly sparse-absent. Complete original streams,
invocation, preparation and before/after source inventories are preserved in
[the activation evidence](docs/evidence/host-final-activation-20261114/).
This is local pin acceptance only; the complete new Android workflow remains required.

## Integrated scope of this candidate

The Host combines the exact-topic Math correction, the separate Dorfwirtschaft
route, the current native Discovery/Dream connection, the original-frame Kart
word recovery and the bounded C4 return-to-Flutter observation. These are
selective connections on the existing product source. The handwriting trainer,
journal, original Lumo assets, child profiles, learning saves and existing
consent/ownership boundaries remain protected.

Math now selects an available exact unit before grade/alias fallback. The Dorf
portal identifies the settlement scene explicitly, keeps profile/session
ownership and acknowledged return, and is included in the actual API35 tour
using the same candidate APK. The Kart fallback only recovers exact known card
word sequences from the current original TSV inside the observed list region;
ambiguity, image hashes, two stable observations, gesture limits and deadlines
remain enforced. C4 observes the returned Flutter games control after one leave
touch, within its local and global deadlines, before the existing two fresh
portal observations.

The complete C4 workflow retains 52 native modes and 17 bound rasters, the
separate Dream gates, Discovery's 10 probes / 38 PNGs / 2 reports, signed
ARM64/x86 APK identity, current-source Android evidence, actual Village
entry/return and learning/profile preservation, and the in-place 2017-to-2020
update. Its outer build/Android budgets are 120/80 minutes; the individual
probe deadlines remain unchanged. Its delivery job prepares a verified bundle
and does not publish a release.

## Actual completed evidence, separated by source

| Source | Actual result | Evidence scope |
| --- | --- | --- |
| 0411b62f59425bc4f36226ca59e9ed5ef901709a | 88 Pipeline/Delivery methods passed, no skips; C4 Actionlint passed | Local Python/source contracts |
| bb97ab6b2e563f3662f1ce5e6141e95cf62d79a7 | Three old-source Math failures reproduced; current shared Dart contract passed 29,845 checks; strict pub resolution succeeded without changing pubspec/lock | Actual isolated Dart RED and current production-generator GREEN |
| bb97ab6b2e563f3662f1ce5e6141e95cf62d79a7 | 9 focused Flutter methods passed, no skips: Math 1, Village routing 2, Village captures 6 | Actual Flutter widgets; native bridge mocked |
| a8a9b84cffd9819d4c8c2dddb55e870f448a9f13 | 70 focused Kart/Garage/Driver/Readiness methods passed, no skips; original Boru failure reproduced separately | Original-fixture and callback contracts, no new Android/OCR run |
| adb88bef880861e23b451166c04ee7d28c96a95d | 36 C4 Evidence/Deadline/Navigation methods passed, no skips | Local source contracts, no new device run |

All six bb97 Village widget PNGs were decoded, hashed and then directly viewed
independently and by Root. The Village title/image are complete and distinct
from Bauwelt in every frame, without visible Village-card overlap or overflow.
Lower scroll-content boundaries are not reclassified as Village-card failures.
This is static widget evidence, not Android/native entry, audio, FPS or
screenreader acceptance.

The first Math-only Flutter attempt retains an incomplete execution receipt:
its test stream succeeded, but the external evidence adapter failed before
persisting the child exit. That exit remains unknown. The separately authorized
nine-case follow-up recorded the actual exit before parsing and passed with
exit 0; no test or production expectation was changed.

The source-bound compact originals and reviews are preserved in
[focused acceptance evidence](docs/evidence/host-focused-acceptance-20261114/),
with the earlier 88-method record in
[Math source evidence](docs/evidence/math-pr491-source-20261114/) and the
70-method record in
[C4 return source evidence](docs/evidence/c4-return-navigation-source-20261114/).
Each result retains its original source; none is relabelled as a new combined
Android acceptance.

## Required current-source acceptance

Historical C4 run
[43589206933](https://github.com/Ullmann27/lumo-lernen/actions/runs/43589206933)
remains Android-failed and unpublished. Its real failure and original
APK/probe evidence remain intact. Source fixes and local green contracts do
not alter that run or approve its APK.

The exact newly activated Host/Native combination must complete its own full
C4 workflow and downstream verification before any delivery claim. No new
feature or producer branch is to be added during that candidate's acceptance.

## Preserved historical STATUS

The complete original STATUS.md begins below, byte-for-byte unchanged. Its
older candidates, pins, pending items and release instructions describe their
original historical sources, not this activation.

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

# Combined LUMO integration / candidate 2019

Updated: 2026-11-13, 20:22 UTC. Active drafts: Native PR160 and Host PR465.
The accepted Native source is 993c1453 / tree f13dd5fc. This Host candidate
connects that exact source through all three 2019 pins and both current visual
receipts. Version remains 0.13.7+2019; prior version policies are preserved.

All fifteen current Native workflows completed successfully. Their original
logs are checked separately: thirteen auxiliary workflows, the three Graphics
jobs and all eight Nextgen jobs. The repaired geometry gate is genuinely clean,
including five counterchecks and actual engine execution. The frozen Nextgen
contract passes 43 Core / 24 Studio / 4 Village / 6 Puzzle / 6 Touch probes plus
32 Touch images. All four capture-source trees match f13dd5fc.

Root directly inspected 22 current Native originals and five current Graphics
originals. Each selected Native image matches the final original bundle byte
for byte. Both existing recorders passed, and the actual combined Host visual
acceptance passed with the new pins. The pin CLI and 63 current/historical pin
regressions pass without errors or skips. These are source, renderer and local
contract results; actual Android acceptance remains pending on this Host source.

Original evidence is retained under docs/evidence/integration-20261113/ in
native-993c-nextgen, native-993c-graphics, native-993c-auxiliary and
host-993c-connection. Earlier 90d proof remains separate in native-90d-checkpoint;
its invalid historical geometry result is not relabelled as a clean result.

Published Host 38a49f7d / tree 625b7940 completed its real native Host compile,
including all nine required JVM classes. Its full Android-build Flutter suite
passed 2,512 tests without skips. The build then stopped at the existing scroll
test's obsolete 24-observation assertion: 24 gestures now require 26 observations.
That original failure remains recorded; no APK was built or emulator started in
run 43497829121. Separately, eight current auxiliary workflows passed; their two
full Flutter runs each passed 2,316 tests with 196 explicit skips. Their analyzer
reported 103 infos, five warnings and no errors. Script-Recovery failed on the
same obsolete assertion; eight historical workflows skipped and two replaced
Change-Review runs were cancelled.

This follow-up connects published Producer 31883868 selectively. Cards leases
now renew from the Android main looper while the visible Activity has actual
authority, independently of render frames. Existing window/edge-to-edge and
Learning/Build speech behavior remains. Both 2019 tours now prepare the exact
Android-17 SDK/CLI bytes and check source-bound AVD/framework readiness before
the unchanged APK tour. The scroll test explicitly verifies all 24 gestures
and both final views. Local evidence: 32 Cards, 42 API37/delivery and 13 scroll
contracts pass without skips; both workflows pass actionlint. Original red
cases remain separate. Native pins, visual receipts and version are unchanged.

The new exact Host tree requires its own real ARM64/x86 builds, API35/API37 tours,
APK/PCK/signature checks and 2017-to-2019 preservation test. Prior-source build
and Flutter successes do not approve this follow-up. Source and original CI
records are under host-318-connection, host-38a-auxiliary and host-38a-android.
The integration branch performs internal verification and does not publish an
APK. Main, live PR461 and producer worktrees remain protected. See CONTINUE.md
for exact sources, evidence identities and the remaining Android gates.

## Earlier candidate-2017 history

The following preserved notes describe their original 2017 candidates and
historical decisions. They are not the active integration source or approval.

# Lumo Spielewelt and Kart action candidate 2017

Updated: 2026-11-12. Branch: `chatgpt/lumo-spielewelt-stage-20261112`.

## Corrected kart-card source; fresh visual acceptance pending

The current native pin is the concrete card-viewport correction `1d5c5cb45a323228f627ec529e6ff1ddd86f1c57`. Fresh exact-source renderer captures and Android APK/visual acceptance remain pending. Its headless regression is described below; this handoff is not release acceptance.

The preceding native pin `f04e580ec0d7d8f70e8be269523fabedd15b0766` and host `d279afa3af65e5224d28ae3855594a2da6a99739` remain an unpublished, visually rejected intermediate candidate. Actual renderer review found a selected 90 dp Gecko kart card in a visible scroll viewport of only 82.2857 dp at 2400x1080/420dpi; scrolling could not expose the whole card. The current workflow and 2017 policy reject this source as well as `0aa89cd`. D279's completed Flutter and native gates are valid partial evidence for that rejected source, not acceptance of the new pin. Its run `43215384284` had reached APK build before this follow-up commit; cancellation by the new synchronized run must be observed, not assumed.

The preceding host `c0ff902552e94856ea1dcda3cfb1f07e9e2044ed` remains visually rejected. Its Android tour passed 21 functional checks and its APK integrity was verified, but artifact `13940128981` exposed header/tab overlap and excessive landing-model occlusion at 2400x1080. Native pin `0aa89cdea3a07d0c2bc0a31a153737a1fee41454` is explicitly rejected by both the current 2017 policy and the current workflow's initial source check. Host run `43203717096` was actually cancelled at 11:54:51 UTC: its update job was cancelled and its publication job had no executed steps. The 2017 release lookup returned 404. That APK must not be published or presented as the corrected build. Current workflow changes cannot alter historical workflow revisions used by older runs.

## Source identity

- Flutter version: **0.13.5+2017**.
- Godot 4.6.3 source: **1d5c5cb45a323228f627ec529e6ff1ddd86f1c57** in [native PR #156](https://github.com/Ullmann27/lumo-godot/pull/156).
- The remote native commit was independently read back with tree `0941a80d811df4e3630f0c9de44d1417148ae320`, identical to local native commit `6279801354f0688b0c5ae166e502c5fab2d2651c`. Historical version policies 1950–2016 remain unchanged. Earlier unpublished 2017 candidates, including `b496fdd`, `0aa89cd` and `f04e580`, are explicitly rejected by the source policy.
- The installed-family package and public test certificate remain unchanged. This is not a Google Play signing claim.

## Current card-viewport correction

Native [card-viewport evidence](https://github.com/Ullmann27/lumo-godot/blob/1d5c5cb45a323228f627ec529e6ff1ddd86f1c57/docs/evidence/2026-11-12-card-viewport/RESULT.json) records **355 passing checks across six cases**, with all **14 kart cards fully visible** when selected and scrolled into view. The identical test fails on the rejected f04 baseline after **346 checks across six cases**. The corrected Android geometry has a 136.5714 dp scroll viewport for 90.28571 dp cards. These measurements are headless checks, not new renderer screenshots or Android APK acceptance. Local gdlint/gdformat were unavailable; no lint pass is claimed.

## Partial native layout evidence from the rejected f04 candidate

The native [layout evidence record](https://github.com/Ullmann27/lumo-godot/blob/f04e580ec0d7d8f70e8be269523fabedd15b0766/docs/evidence/2026-11-12-android-stage-layout/RESULT.json) reproduces the observed 2400x1080 Android geometry at 420 dpi, with a 1600x720 logical viewport and 1.5 pixel scale. The identical regression test executes **554 checks across five cases**: the corrected candidate passes and the rejected `0aa89cd` baseline fails. Compact selection passes **181 checks across four cases**; **240 touch controls** retain a minimum of 48x48 dp. These are headless geometry/behavior checks, not newly rendered Android screenshots. The touch-target run reports two resources still in use at teardown; local gdlint/gdformat were unavailable. No lint, renderer or device-performance pass is inferred from those runs.

## Included work and earlier development evidence

The Flutter Spielewelt restores the dimensional game cards and the established navigation. The native game presents its menus on one live 3D stage, uses twice the former physical driving pace, defaults new setups to the stronger `pro`/Extrem opponents, and adds physical ramps and bounded roadside lasso encounters. Existing learning modules, profiles and saved-game contracts remain in place.

The integrated native development checks include two driven laps with eight jumps and landings, sixteen checkpoints and two inverted loops; all thirty opponents across six fields completed their two-lap routes. The subsequent full touch/save/resume flow passed sixteen gates with two reopens and one reward delivery. Compact-menu validation passed 181 checks, and the camera checks passed 192 headless assertions. These checks do not establish Android frame rate or physical Fold7 performance.

The first active-snapshot engine probe now navigates the real section tabs and touches START once. Its unchanged eleven conditions passed with the first active snapshot at 1.0 seconds and the next at 6.016667 seconds. The adjacent snapshot and actual write-failure probes passed all 41 and 8 conditions respectively. Four additional rendered production fixtures use the same current navigation; their actual renderer acceptance remains a CI responsibility.

Earlier native portrait-labelled captures were found to contain landscape pixels because desktop startup reset the requested size. The integrated capture gate now resizes after startup, verifies the saved raster dimensions and checks rendered content. The earlier images are not evidence for portrait rendering. Exact-final-source native CI is still required.

Review of genuine portrait images then exposed magnified, blurred landing labels. The runtime now uses physical font and layout dimensions instead of scaling the whole landing Control. After 354 headless font/layout checks, actual X11 rendering on `b496fdd` passed **386 production UI checks** and saved correctly sized landing, garage and track images for all four surfaces. The two earlier workflow success-marker mismatches were corrected without changing game scripts or assets.

Historically, the now-rejected `0aa89cd` differed from `b496fdd` only in two test scripts, raw logs and a handoff. On that earlier source, the pointer probe passed **27 conditions** plus a failing disabled-tab negative control, MenuDepth passed **41 conditions**, and GaragePresentation passed **66 conditions**. Those were headless behavioral checks. The test-only description does not apply to the subsequent runtime corrections, and neither those checks nor the earlier 386 rendered UI checks establish current Android visual acceptance.

## Android delivery is pending

The host also includes the reviewed formatted-constructor guard correction: the actual multiline `AppShell(profile: _profile)` connection is accepted, while wrong direct arguments, quoted/commented lookalikes and nested arguments are rejected. The existing application-state checks and failed-scan handling remain enforced.

The current card-pin update passed **89 targeted pin, historical-policy, delivery, artifact-name and Android-tour contract tests with no skips**, plus the actual strict-pin CLI check. Current raw output and command/source hashes are stored separately in [card-pin evidence](docs/evidence/2026-11-12-host-card-pin/RESULT.json); the preceding d279/f04 host records remain unchanged in [earlier host evidence](docs/evidence/2026-11-12-host-layout-pin/RESULT.json). The historical 1950–2016 policy digest remains `6577810bda4d3811422fc9df47733f1d2e698ede56206d9c11f850dc6150b0db`. The regression executes the actual initial workflow Python check, requires each precise layout rejection for `0aa89cd` and `f04e580`, and accepts the current `1d5c5cb` pin. Synthetic publication metadata tests remain rejection-contract evidence only. No production Dart, concurrency setting or APK build script changed in this update.

The unified workflow now requires the existing full Flutter, legacy-native, 2014 and technical-art gates plus `validate_action_stage.sh` on the exact pin. The real Android tour touches Grand Prix, Garage, Fahrer and START. A separate real 2015→2017 install-in-place job must preserve learning and profile state through offline Kart, restart and simulated Fold changes.

Publication is restricted to this same-repository pull request after build, Android tour and update jobs succeed. It rechecks the actual ARM64 manifest, certificate, native source, APK hash and source-bound emulator evidence. It creates the immutable `coachpreview-build-2017` prerelease; an existing matching release can only be verified, never replaced. The final public APK is downloaded without authentication and compared byte-for-byte by size and SHA-256 before its link is accepted.

At this handoff there is **no newly built APK for `1d5c5cb` and no 2017 public download receipt**. Previous intermediate sources remain visually rejected; the cancelled c0ff update artifact is a partial record, not a successful upgrade result. The public test key, emulator acceptance and physical-device performance are distinct claims. Main and older published APKs remain unchanged.

