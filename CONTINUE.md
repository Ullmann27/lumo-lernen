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

# Continue the actual repaired 2020 APK build

The complete source checkpoint is
`ea5748f42c82b8f0690ce32f42dc3a01342af392` /
`65f2d0aa1fec45cd4c875154fe230a1f8c8e0aa9`.
This documentation-only successor activates the unchanged C4 workflow through
PR485. Record the actual successor SHA/tree/run/attempt; do not reuse 7ac results.

- Central Pipeline owns the one current-run status watch and original terminal
  API/log collection. Flutter owns the new complete machine stream, exact
  82-case catalogue and Android-compile originals. Godot owns the one already
  running 54-method local replay and then the exact native runtime originals.
- The local replay was running when this activation was prepared. Preserve its
  actual child exit, complete output, warnings and any recorder error; recounting
  originals does not rerun tests. Its result belongs to ea5748. Full CI must also
  execute all current contracts before any APK acceptance.
- Require the unchanged three Speech JVM contracts (23/17/30), every full
  Flutter/script/Android-QA gate, Native52/Dream/Discovery, signed ARM64/x86 APKs,
  actual main/Village/C4 tour and the preserved 2017-to-2020 update.
- 7ac run43632790204 remains failed at speech fixture compilation. Its 2,686
  Flutter successes, runtime and host compile cannot approve changed sources.
  The complete originals are in evidence commit8f3d3b6721a41062c99f1ac10bdf122e3ec60709.
- The separate publisher branch still holds the reviewed CLI at
  72143d3586109967773d6442072d486c11dc1449. Its older 7ac-bound plan is obsolete.
  Rebind the executable workflow to the actual fully successful new candidate,
  its run/attempt and original delivery artifact ID/digest/size before activating
  publication. The activating publisher SHA/tree must identify the new workflow
  commit, while the reviewed CLI bytes stay unchanged.
- Verify the new immutable public ARM64 HTTPS APK bytes and signature before
  returning the direct download URL. No Main/producer reset, forced update,
  old-release overwrite, external message or unattended automation is authorized
  by this continuation. Automation_ef722d06b7cc81918d0f36265bdbdf43 remains disabled.

---

# Preserved earlier continuation records

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

## Exact continuation for this activation

1. Read PR485 and the run whose head is this activating successor. Bind its
   attempt and all seven jobs. Do not rerun or relabel the old 5ad failure.
2. Preserve original full outputs and first failing evidence. Fix any genuine
   failure on a separate source checkpoint; do not weaken image, persistence,
   source, deadline, signing or public-byte checks.
3. The complete build discovers both new PR494 tests and the new Village/C4
   regressions. Their actual integrated outcomes are still pending here.
4. Once all required jobs and the accepted delivery bundle succeed, freeze their
   exact identifiers into the separately prepared publisher workflow. Publisher
   source 72143d3586109967773d6442072d486c11dc1449 and its recorded tests remain
   separate from this candidate source. Recheck the current PR head and release
   vacancy before publication. Do not delete, replace or resume an occupied tag.
5. Provide a public direct HTTPS .apk link only after the publisher reads the
   complete public bytes and verifies the expected digest. State the actual
   source, native revision, version, signing fingerprint and SHA256.
6. Additional producer completions may be prepared without moving this active
   C4 head while it runs. The recurring ChatGPT automation remains disabled.

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

# Fortsetzung: separaten Hub-Anschluss tatsächlich qualifizieren

Aktueller Folge-Quellcheckpoint: `1735ef3e9010f2d28b9dbff087a03730bdc6ca8a`, Tree `7a7f92e16d2157dfe8f87b5cc26815ae06c8f000`. Dieser Branch erhält die 0b7-Quelle und ergänzt ausschließlich den bestehenden Flutter→Android→Godot-Spielwelteinstieg.

Der automatisch gestartete Workflow `lumo-native-3d-hub-entry-qa.yml` muss auf dem tatsächlichen Aktivierungscommit geprüft werden. Beide Jobs müssen abgeschlossen und erfolgreich sein. Die originalen Maschinenereignisse, deren tatsächlicher Exitcode, die Analyzer-Ausgabe, die echten Androidklassen und Quellen vor/nach den Prüfungen müssen an denselben Head gebunden bleiben. Ein erfolgreicher Fokuslauf ersetzt keine vollständige APK-/Android-/Updateprüfung.

Die aktuelle vollständige Auslieferung bleibt gesondert an Host 0b7 / Native baf, PR 485 und Run 43604903064 / Versuch 1 gebunden. Den laufenden Kandidaten nicht mit diesem Folgestand verwechseln. Die neue Games-Route ist dort noch nicht enthalten.

Memory-/Quiz-/Englisch-Nachträge sind anhand ihrer eigenen exakten Producerstände weiterzuprüfen. Echte rote Hosttests bleiben offen, auch wenn native Paarläufe grün sind. Der C4-Opt-in-Patch aus PR505 wurde nicht übernommen. Alte Releases und der geschützte Main bleiben unverändert.

---

## Unveränderte vorherige Fortsetzung

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

# Continue the combined 2020 acceptance

Updated: 2026-11-14. Documentation activation base:
Host 68f86b7dafa2dcd1e42ee019c4be46b9e9bdc697 /
tree ecd5df0797c2b4102f2c7bbc30146f3061d713ce.
Its exact configured Native source is
baf148b03a7a32c6ad9f737d731f900eb9113ea1 /
tree 0c18a0ca5200ade267cfedb4c12d5c4b0a761a00.
Version remains 0.13.8+2020. Bind the subsequent actual workflow to its
own final Host SHA; this documentation-only commit adds no feature,
workflow or pin change.

Native run 43600806315, attempt 1, job 132464933411 is still in progress
in the recorded activation handoff. Its final renderer acceptance is open.
The original Actionlint/Mobile380 results belong to parent
4d2cbb6ea235c7bf519aa5f3873a16f6b177be2b and unchanged product/workflow
blobs, not a completed new Native or Android run.

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

## Resume the fixed candidate

Keep the activation's exact Host source and configured Native pin fixed while
its complete C4 workflow runs. Main, historical releases and producer branches
remain unchanged. This candidate introduces no further feature work after
activation; new producer deltas belong in separate review packs.

1. Bind the actual workflow run to its Host SHA/tree, configured Native SHA,
   attempt and original job/artifact metadata. A successful predecessor or
   local test run cannot supply a missing current-source gate.
2. Require genuine runtime/compile and full build acceptance, including the
   exact-topic Math contract, every enabled Flutter capture without skips,
   the current-grade curriculum audit, complete script/Android QA contracts,
   52 native modes / 17 rasters, Dream and Discovery 10/38/2.
3. Use the same verified candidate APK for the actual API35 main tour, C4 and
   Village. Preserve package/version/signature/ABI/APK/PCK/source identities,
   original screenshots/OCR/TSV/logs and the learning/profile comparisons.
   Village must actually enter the settlement and return to Flutter with the
   existing ownership/save/acknowledgement checks. C4 must observe Flutter
   games after the single leave action and retain its two fresh portal reads.
4. Require the real in-place 2017-to-2020 preservation job and the final
   candidate verifier. Keep individual probe deadlines, original error gates
   and no-skip policy. The 120-minute build and 80-minute Android outer
   budgets do not extend a local input, arrival or observation deadline.
5. Require the read-only delivery verifier and its complete original evidence
   bundle. The existing C4 delivery step prepares a bundle without publishing
   a release. Do not present an APK link as accepted before the exact
   current-source build, Android, update and delivery gates are complete.

## Evidence already completed

The following results are complete on their named sources and do not need
optional broad local repetition merely for this activation:

- 0411b62f59425bc4f36226ca59e9ed5ef901709a: 88 Pipeline/Delivery methods,
  zero skips, and C4 Actionlint. Original result:
  docs/evidence/math-pr491-source-20261114/host0411-validation-result.json.
- bb97ab6b2e563f3662f1ce5e6141e95cf62d79a7: actual old-0411 Math RED
  (three known failures), current Dart GREEN (29,845 checks, 3,955 template
  calls, 4,640 factory calls), and strict official Flutter 3.44.9 / Dart 3.12.2
  pub resolution with unchanged pubspec/lock.
- The same bb97: exactly nine focused Flutter methods, zero failures/skips,
  actual exit 0 in 22.867 seconds; Math 1 plus Village routing 2 and captures 6.
  All 2,327 materialized source files, 4,383 logical index paths, HEAD/tree,
  index bytes and empty status remained unchanged. The optional Feature22
  suite was not rerun.
- a8a9b84cffd9819d4c8c2dddb55e870f448a9f13: 70 Kart/Garage/Driver/Readiness
  methods, zero skips, and a separate actual old-source Boru callback RED.
  Original result:
  docs/evidence/c4-return-navigation-source-20261114/kart-a8a9-validation-result.json.
- adb88bef880861e23b451166c04ee7d28c96a95d: 36 C4 Evidence/Deadline/
  Navigation methods, zero skips. The single leave action, 30-second Flutter
  return observation, global 900-second limit and late-arrival rejection remain.

The newer compact proofs are under
docs/evidence/host-focused-acceptance-20261114/:
math-dart-pub-originals.tar.gz, math-village-widget-originals.tar.gz,
c4-navigation-originals.tar.gz, their summaries/handoffs, capture inventory
and separate visual/source reviews. Their original bytes and source bindings
are preserved. The widget archive keeps the first adapter failure with its
unknown child exit separately from the successful authorized follow-up.

All six Village PNGs were actually inspected. Dorfwirtschaft remains fully
visible and separate from Bauwelt; wide layouts retain the fox/action area,
and large text changes the grid without clipping the Village title. Some
lower content continues outside the viewport. Static images and mocked-bridge
widget tests do not prove Android input, native return, audible speech,
screenreader behavior or physical-device performance.

## Historical failure remains authoritative

Run 43589206933 is an Android-failed, unpublished predecessor. Its original
Boru/garage evidence is the basis for the bounded word-recovery repair; the
new local 70-method result does not turn that historical run green. Keep its
logs, artifacts, first failures and unexecuted downstream stages unchanged.

Do not reuse old APKs, old receipts or historical runtime successes as the
acceptance of the newly activated combination. Keep later device observations
and any remaining repair work explicitly tied to their actual APK and probe
sources.

## Preserved historical CONTINUE

The complete original CONTINUE.md begins below, byte-for-byte unchanged.
Its previous tools, branches, pins and pending work are historical context;
the activation and source-bound requirements above govern this candidate.

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

