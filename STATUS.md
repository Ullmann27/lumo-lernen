# Aktueller gemeinsamer LUMO-2020-Integrationsstand — 14. November 2026

Host-Review: [PR 497](https://github.com/Ullmann27/lumo-lernen/pull/497).
Arbeitszweig: `integration/lumo-live-connections-20261114`.
Version: **0.13.8+2020**, unveröffentlichter Family-Testkandidat.
Native-Review: [PR 173](https://github.com/Ullmann27/lumo-godot/pull/173).
Exakt gebundene Godot-4.6.3-Quelle: `e9a9f60f20403ffa6b2b26d1437f958b2704d2aa`,
Tree `1c2b5da7a4485cb8b911adcac2b567481cf902b5`.
Main und vorhandene Veröffentlichungen bleiben geschützt.

## Vollständige Zusammenführung

Dieser Host-Merge führt `9516068cfb67938fc90d48ff45d56169f00941fc` und den
tatsächlichen aktuellen Qualitätszweig `aab09275ec6b5808de9be539ca4e1a7e70921249`
mit beiden realen Eltern zusammen. Die gemeinsame Basis ist
`803a4e960ffb804a46b6d09417731c031f00f680`.
Der Abgleich verwendet vollständige rekursive Git-Bäume, weil die
Compare-Dateiliste bei 300 der 302 Upstreamänderungen endet.
280 Änderungen werden als Originalblobs übernommen; 18 konkurrierende Dateien
werden ausdrücklich aufgelöst. Vier bereits identische Änderungen und sämtliche
151 ausschließlich eigenen Änderungen bleiben erhalten. Es gibt keine Löschung.

Der Native-Merge verbindet `71a4c1e2304b52005950b12490d070c286c45438`
mit `e2d15dbc5f3709306decb139eeb70a1cf30c0b73`.
Sein vollständiger Baum wurde unabhängig mit allen 3.712 Nicht-Tree-Einträgen
verglichen: null Abweichungen von der berechneten Vereinigung. Die 63 zusätzlichen
Upstreamblobs und zwei Provenienzdateien ergänzen den bisherigen Stand.
Alle geschützten Hub-/Village-Dateien und bisherigen Prüfprogramme bleiben
blob- und modusgleich.

Die elf Spieleportale, der direkte Dorfwirtschaft-Einstieg samt sichtbarer
Rückkehr zu Spiele, gesicherte Profile/Lernstände, Original-Lumo, gemeinsames
Zeichnen sowie die vorhandenen Schreibtrainer- und Journalmodule bleiben
angeschlossen. Dazu kommen die exakte kumulative Mathematik-Themenwahl,
unverkleinerte gedrückte C4-Touchflächen, sichere Kart-Minimap-Geometrie,
die zusätzliche Dream-Abnahme und die präzise Android-Continue-Erkennung.

Die Testauflösung behält echte Spielzüge, Replay-/Restart-Nachweise, vollständige
Rückwege und alle Herkunftsprüfungen. Die Auslieferung verlangt weiterhin genau
elf Assets einschließlich des originalen Village-Android-Ergebnisses.
Live9/7 und Discovery10/38 bleiben zusätzlich zu Dream5/7/2 verpflichtend.

## Tatsächlicher abgeschlossener Vorgängerlauf

Run [43586101225](https://github.com/Ullmann27/lumo-lernen/actions/runs/43586101225),
Versuch 1, prüfte Host `07cac7225e2f7b6451665dfda9c38841f51c758b`
und Native `71a4c1e2304b52005950b12490d070c286c45438`.

- C4-Runtime und tatsächliche Android-Host-Kompilierung bestanden.
- Die vollständige Flutter-Abnahme bestand **2.625 Tests**, ohne Fehler,
  übersprungene Tests, Runner- oder Capturefehler; **566 PNGs** wurden erfasst.
- Die 52 Native-Modi mit 17 Extension-PNGs bestanden. Der gesamte große
  Native-Schritt benötigte 58 Minuten 51 Sekunden; die 52er-Stufe selbst
  rund 41 Minuten 25 Sekunden.
- Live bestand neun Proben und sieben PNGs. Bei Discovery waren acht von zehn
  Proben abgeschlossen; die Lernwelt-Capture erreichte zehn von 25 Bildern.
  Die abschließende Discovery10/38-Freigabe wurde nicht erreicht.
- Der Buildjob wurde nach etwa 90 Minuten abgebrochen. Das Originalprotokoll
  meldet `The operation was canceled.`; die vollständige Providerannotation
  war nicht zugänglich. Vorher wurde im Native-Abschnitt kein Engine-,
  Assertion-, Ressourcenleck- oder innerer Probe-Timeoutfehler gefunden.
  APK-Build, Android-Touren, Update und Abschlussjobs wurden nicht ausgeführt.

Das äußere Buildbudget wurde deshalb von 90 auf 150 Minuten erhöht.
Alle inneren Probegrenzen, Fehlermarker und erforderlichen Prüfungen bleiben
bestehen. Der neue Dream-Vertrag ergänzt fünf echte Proben, sieben Original-PNGs
und zwei Originalberichte; sein Reader bleibt vor dem Import exakt an
Gitblob `da8eed7d6383fcbc82a03596518a5fcc3b9a00c5` und SHA256
`f7296a802d15c382dbcc77640373a0f53e30306fcaab3de869549ff1656de89d` gebunden.

Die ungekürzten Vorgängeroriginale sind dauerhaft gesichert:
[Android/Build](https://github.com/Ullmann27/lumo-lernen/commit/5cc5ef0498012cf49ce5070cc8d932a855b3260a),
[Flutter](https://github.com/Ullmann27/lumo-lernen/commit/b40260edaf5ecfa8eef060a46364021b2a9eadd0)
und [Native-Originalprüfung](https://github.com/Ullmann27/lumo-lernen/commit/a6216484bd48bc2db8615d73d1397c0b5b35feb4).
Sie bescheinigen keinen neuen APK-Erfolg.

## Noch auszuführende gemeinsame Abnahme und Auslieferung

Der exakte neue Hostkopf muss seinen eigenen vollständigen Flutter-/Scriptlauf,
Native52/17, Live9/7, Discovery10/38, Dream5/7/2 und zusätzlichen Return-/Wisp-Nachweis
bestehen. Danach folgen frische signierte ARM64-/x86-APKs, die tatsächlichen
API35-Atelier/Kart/Village/C4-Touren, das datenerhaltende 2017→2020-Update und die
vollständige erneute Auslieferungsprüfung. Alle sieben Pflichtjobs müssen zum
selben aktuellen Quellstand und Run gehören.

Der ausführbare Publisher ist vorbereitet, aber die früher an Host07/Run43586101225
gebundenen Objekte sind verworfen und dürfen nicht aktiviert werden.
Er wird erst an den endgültigen erfolgreichen neuen Kopf und dessen tatsächlichen
Run gebunden. Er prüft das originale Delivery-Bundle, wiederholt Signatur,
Paket-/Versions-/ABI-/Quellenprüfung an der tatsächlichen ARM64-APK, erstellt
ausschließlich ein neues Release und vergleicht anschließend die anonym
heruntergeladenen öffentlichen APK-Bytes mit den freigegebenen Originalen.
Der dauerhafte Eigentümerauftrag in AGENTS.md erlaubt diese neue Testauslieferung
ohne erneute Nachfrage; ein geplanter Pfad ist noch kein gültiger Downloadlink.

Die Ausführungsumgebung wurde nach dem Remote-Quellabgleich als frische leere
Umgebung wiederhergestellt. Der vollständige Checkpoint
`f36579a3a7e06045eaecea7c00e497ac06930100`, Tree
`ed67b3939bb3caeb69231a2c70387860155b1a83`, wurde tatsächlich ausgecheckt.

Auf genau diesem gemeinsamen Produkt-/Test-/Workflowstand bestanden am
14.11.2026 von 12:47:32 bis 12:49:03 UTC **373 gezielte Tests in 16 Dateien**,
ohne Fehler oder Skips. Sechs YAMLs, sechs echte extrahierte Native-Shellblöcke
und die vorhandene Diagnostic-Shell bestanden ihre Syntaxprüfung.
Alle 4.655 Dateien wurden vor und nach dem Lauf gegen ihre Gitblobs geprüft;
Quelle und gesamte Dateiidentität blieben unverändert. Root hat die 16
Originalprotokolle, ihre Hashes und Testzahlen unabhängig nachgelesen.
Lokale Werkzeuge: Python 3.12.14, PyYAML 6.0.3 und Pillow 13.0.0.
Der vollständige Kandidatenworkflow verwendet weiterhin sein gepinntes
Pillow 12.3.0. Actionlint war lokal nicht vorhanden und wurde nicht ausgeführt.
Diese fokussierten Tests ersetzen keinen Flutter-, Renderer-, APK- oder
Emulatorlauf auf dem endgültigen Hostkopf.

Der vorliegende Freigabe-Commit ergänzt zum geprüften Checkpoint ausschließlich
diese Originalbelege und Statusdokumentation. Produkt, Tests, Policies, Assets,
Native-Pin und Workflows bleiben bytegleich. Der separate alte Publisher wurde
zusätzlich tatsächlich nur auf Syntax geprüft: YAML, sieben Bash-Blöcke und
drei Python-Heredocs bestanden; seine verworfene07-Bindung blieb unverändert.
Originale: [Publisher-Syntaxbeleg](https://github.com/Ullmann27/lumo-lernen/commit/68cff44598c141e5f1f0c02012c5e6503503d4da).

Play-Produktionssignierung, Play-Console-Abnahme, physische Android-Bildraten und
thermisches Dauerverhalten sind weiterhin unbelegt. Die strukturelle
Mathematik-/Curriculumprüfung ersetzt keine vollständige pädagogische Freigabe.
Private Profildaten werden nicht als öffentliche Betreiberangaben übernommen.


---

# Historische Übergaben beider Eltern

Die folgenden unveränderten Texte dokumentieren die jeweiligen früheren Quellen.
Alte Pins, offene Prüfungen, Zugangsgrenzen und vorgeschlagene Aktionen sind
historisch; maßgeblich ist der aktuelle gemeinsame Stand oben.

## Bisheriger eigener Integrationsstand

# Active LUMO 2020 integration and complete acceptance — 2026-11-14

Active review: https://github.com/Ullmann27/lumo-lernen/pull/497
Working branch: `integration/lumo-live-connections-20261114`.
Version: `0.13.8+2020`.
Exact native source: `71a4c1e2304b52005950b12490d070c286c45438`.
Native review: https://github.com/Ullmann27/lumo-godot/pull/173.
Main remains protected.

## Integrated behavior

The complete host integration through `cf2593cb6dec51b66461c8e5984dfbfdd5091c22`
is retained, including the Play-quality base, drawing and learning progress,
eleven Flutter game portals, responsive C4, direct Dorfwirtschaft launch and the
existing handwriting/journal modules.

The native Hub now loads the existing original facial Lumo rig. Its actual GLB,
bones, animations, visible mesh and free camera framing are checked. Eight native
routes are retained. The original portrait and landscape PNGs were independently
viewed; the portrait keeps its existing scroll continuation.

A direct embedded Dorfwirtschaft entry now has the visible `‹ Spiele` return
through the existing save and HostBridge path. Failed saves block departure,
and a refused return acknowledgement remains retryable. The original internal
Bauwelt context and the optional Bauwelt route remain available. AndroidBack
continues to pause. The original initialized-state marker identifies the actual
running village for the additive API35 roundtrip proof.

The Home capture tests now open the real subject expansion, wait for its actual
animation frames, require the first Mathe card to be fully visible and hittable,
and capture that state. Village captures use Flutter's SDK-owned Android platform
variant so the framework restores its debug state correctly.

## Actual predecessor and focused results

The first combined run on 7fd9e916 reported 2,612 passed / three failed / zero
skipped / 546 PNGs. Its three outdated Diktat finders were repaired.

The next combined run [43582160954](https://github.com/Ullmann27/lumo-lernen/actions/runs/43582160954)
on cf2593cb passed native C4 runtime, actual Android host compilation, static
analysis and all 888 script tests. Full Flutter reported **2,619 passed / six
failed / zero skipped / 566 PNGs**. All three repaired Diktat cases passed
individually. The six failures were the Village tests' platform-cleanup invariant,
after their layout and real launch assertions. No APK was built by this run.

The focused corrections subsequently passed:
- Home run 43584516810: 13 Home/navigation tests and eight additional world tests,
  with eight original captures; the four learning-card captures now show real
  opened subject cards.
- Village run 43583899148: 27 Flutter tests, six original captures and actual
  Kotlin/Android host compilation.
- Native 71a4c1e2: original Hub identity and two real renders; Village host return,
  save/restore and rejected-ACK retry; existing Rig, VillageScene and Economy
  regressions; eleven helper tests with 57 negative cases and a read-only replay
  of the complete 38-image set.

## Required final acceptance

The exact next combined host must pass its own full Flutter suite, the native
52-mode suite and original 17-image extension, Live nine-probe/seven-image suite,
Discovery ten-probe/38-image suite, signed APK build, actual API35
Atelier/Kart/Village/C4 journeys, 2017-to-2020 data-preserving update and final
delivery replay. The Village result must be bound to the same original APK,
source, run, main tour, native PID, profile, real scene and preserved learning data.
Only the complete accepted source may be used for a new direct APK release.

Focused or predecessor results do not certify the final APK. No physical Android
60-FPS, Play-production signing or curriculum-wide approval is claimed.
Original evidence and source provenance remain under
`docs/evidence/live-root-integration-20261114/source-integration.json`,
`docs/evidence/capture-state-qa-20261114/` and the corresponding native evidence.

---

## Previous combined-candidate handoff

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

## Hinzugekommener Qualitätsstand aab09275

# Aktueller LUMO-2020-Kandidat – 14. November 2026

Review: [PR 491](https://github.com/Ullmann27/lumo-lernen/pull/491). Arbeitszweig: `work/lumo-play-quality-20261114`. Wiederaufnahme: `checkpoint/lumo-next-quality-20261114-2708`. Version **0.13.8+2020** bleibt ein unveröffentlichter Testkandidat. Main und bestehende Releases bleiben geschützt.

Dieser Stand führt den Qualitätscheckpoint `38c2fe8cb9e1b1021842e886c1a7cfa199e687ca` und den Integrationsstand `3d91bd8355a539c3c2413760959684cd3fee985a` mit beiden tatsächlichen Eltern zusammen. Der gemeinsame Host-Vorfahr ist `32e7efbff427fef64e90b3a1fcecd3b52f00af42`. Die exakt gebundene Native-Revision ist `e2d15dbc5f3709306decb139eeb70a1cf30c0b73` (Tree `ea0f73ae6aad8792a963cadaa483c290a2f2a62e`), ein tatsächlicher Merge mit den Eltern `bd0712259bb64908a5649ee1999638826c9eb597` und `6ecc560ea16202b935c4f1d32b08b93cda358e02`. Originale: [Native-Zusammenführung](https://github.com/Ullmann27/lumo-godot/tree/e2d15dbc5f3709306decb139eeb70a1cf30c0b73/docs/evidence/native-dream-minimap-merge-20261114). Der Kandidat wird für den vollständigen Lauf auf diesen Quellen eingefroren; spätere parallele Erweiterungen werden während dieser Abnahme nicht automatisch übernommen.

## Enthaltene Korrekturen

- Die Mathematik-Auswahl behält das ausdrücklich gewählte Thema auch bei Wiederholungen aus früheren Klassen. Ein Alias der aktuellen Klasse ersetzt kein anderes exakt angefordertes Thema. Zulässige Aufgabenmischungen innerhalb eines Themas bleiben erhalten.
- Die passive Kart-Minimap berücksichtigt das tatsächliche sichere Bildschirmrechteck, Steuerelemente, Pedalgrafik und eingeblendete Hinweise. Sie reagiert auch auf das Erscheinen und Verschwinden des Sprunghinweises. Fahrphysik und vorhandene Steuerung bleiben erhalten.
- Connect Four behält seine vollständigen Touchflächen beim Drücken. Android erkennt die alleinstehende Continue-Beschriftung. Die Quellenbindung akzeptiert den Qualitätszweig ausdrücklich und prüft weiterhin genau den aktuellen PR-Kopf, Run, Workflow, Branch und Artefaktinhalt.
- Die bisherigen 52 Native-Prüfmodi, die strenge Return-21-Stufe und die zusätzlichen frühen Return-/Wisp-Stufen bleiben unverändert. Die Traumwelt ergänzt fünf Pflichtmodi mit sieben tatsächlichen PNGs und zwei Originalberichten. Ihr Reader wird vor dem Import an den freigegebenen Git-Blob und SHA-256 gebunden; die Auslieferungsprüfung wiederholt seine Prüfung ohne Veränderung der Originale.
- Frühere Formeingabe-, Navigations-, Datenschutz- und Family-/Play-Korrekturen bleiben erhalten. Schreibtrainer, Journal, Profile, Lernstände und der vollständige bisherige Host-Assetbaum werden durch diese Zusammenführung nicht ersetzt.

## Tatsächlich vorhandene eng begrenzte Nachweise

**Mathematik:** Derselbe Vertrag lief mit echten Produktions-Dart-Dateien gegen beide Fassungen. Der alte Generator verletzte 386 Bedingungen; die Korrektur bestand 29.845 erreichte Prüfungen. Geprüft wurden 145 kumulative Klassen-/Themenkombinationen mit 32 Seeds, 4.640 tatsächliche Factory-Aufrufe und 3.955 direkte Template-Aufrufe. Der Flutter-Testwrapper ist enthalten; seine Ausführung gehört zum nächsten vollständigen Kandidatenlauf. Originale: `docs/evidence/math-exact-cumulative-20261114/EXECUTION.md`.

**Minimap:** Dieselbe Godot-4.6.3-Probe meldete beim alten Produktionscode 380 Prüfungen mit 26 Fehlern, bei der Korrektur 380 ohne Fehler. Auch die Kombination mit den neuen Dream-Quellen bestand die tatsächlichen 380 Prüfungen. Alle 15 bisherigen SafeArea-Ziele bleiben erhalten. Die lokale Geometrieprobe enthält keine Rasterbilder und bescheinigt keine Android-Bildrate; der vollständige Renderer-Lauf bleibt erforderlich.

**Bisheriger Host-Zwischenstand:** Auf `dfc3e0a1ea20f1491e4844ecfa913c598e1c6c5f` bestanden 226 gezielte Python-Tests sowie Actionlint und die Bash-Syntaxprüfungen der vier bisherigen Native-Blöcke. Ein erster Fehler beim Modul-Suchpfad ist zusammen mit dem unveränderten erfolgreichen Wiederholungslauf gesichert. Auf `38c2fe8cb9e1b1021842e886c1a7cfa199e687ca` bestanden zusätzlich die 65 aktuellen und historischen Pin-Verträge. Originale: `docs/evidence/quality-32e7-merge-20261114/local-execution/`.

**Gemeinsamer Host-/Dream-Stand:** Auf dem tatsächlichen Merge `dc966e8e4e4f69c5cb19e53822625025bb0fe766` (Tree `883461f7827d92eb4175b191bb66202a98251f60`) bestanden 237 gezielte Python-Tests in 26,816 Sekunden, Actionlint und Bash-Syntaxprüfungen aller fünf relevanten Native-Blöcke. HEAD, Tree, verfolgte Dateien und Index blieben unverändert. Vollständige Originale und der tatsächlich ausgeführte Treiber: `docs/evidence/quality-dream-merge-20261114/execution/` und `run_committed_source_checks.py`.

Der abschließende Freigabe-Commit ergänzt ausschließlich diese Nachweise und die Statusdokumente; der geprüfte Produkt-, Test-, Policy- und Workflow-Code bleibt bytegleich. Der vollständige CI-Lauf auf genau diesem neuen PR-Kopf wird damit angefordert und muss noch tatsächlich bestehen. Frühere Erfolge werden diesem Stand nicht als APK- oder Android-Freigabe zugerechnet.

## Abgeschlossener Vorgängerlauf und seine Grenzen

Run [43578509499](https://github.com/Ullmann27/lumo-lernen/actions/runs/43578509499) auf Host `803a4e960ffb804a46b6d09417731c031f00f680` endete insgesamt mit **Fehler**. Der Hauptjob bestand 2.569 Flutter-Tests, 872 Build-Verträge, 929 Android-Probe-Verträge und 52 Native-Modi und erzeugte eine signierte Family-Test-APK. Das echte Update 2017→2020 erhielt das eine geprüfte Kinderprofil und seine gespeicherten Ergebnisse über sechs Snapshots auf einem API-35-Emulator.

Die allgemeine Android-Tour bestand 21 Schritte ohne erfassten fatalen Absturz. Connect Four brach aber vor dem Spiel wegen des damals nicht erlaubten Qualitätszweigs ab: null Spielbeobachtungen, Übergänge und Rückgaben. Die abschließenden Freigabe- und Auslieferungsjobs wurden übersprungen. Originale sind im Evidence-Commit [6a5ae5327570fc60434672074f246c95e1c59283](https://github.com/Ullmann27/lumo-lernen/commit/6a5ae5327570fc60434672074f246c95e1c59283) erhalten. Diese alte APK enthält die neueren Korrekturen nicht.

Der separate Integrationslauf `43583493817` auf 32e7 scheiterte an einer von 938 Android-Probe-Vertragsprüfungen: Die Continue-Mock-Erwartung enthielt das erforderliche `standalone_caption=True` noch nicht. Das vollständige ursprüngliche Fehlerprotokoll und die korrigierte enge Erwartung bleiben gesichert.

## Noch erforderliche Auslieferung und Play-Abnahme

Den vollständigen Workflow auf dem exakten eingefrorenen PR-Kopf ausführen. Frische Flutter-/Native-/Android-Originale und das echte 2017-Update prüfen, die daraus gebaute signierte ARM64-APK samt Herkunft, Zertifikat, Größe und SHA-256 verifizieren und sämtliche Abschlussgates verlangen.

Der bestehende 2020-Workflow bereitet danach ein Actions-Auslieferungsartefakt vor. Die verfügbare GitHub-Anbindung stellt zurzeit keinen Weg für die Erstellung, den APK-Upload und die Veröffentlichung eines neuen öffentlichen Releases bereit; das lokale `gh` ist nicht angemeldet. Die alten Publisher sind an ihre historischen Kandidaten gebunden. Ihr Umnutzen ersetzt keinen berechtigten 2020-Upload. Der tatsächlich geprüfte Zugang und die Grenzen stehen in `docs/evidence/c4-delivery-access-review-20261114/review.json`. Ein geplanter Downloadpfad ist kein existierender öffentlicher APK-Link.

Der Play-AAB-Builder und seine Prüfungen sind vorhanden. Tatsächliche Play-Upload-Signierung, ein damit gebautes AAB und Play-Console-Abnahme fehlen. Die veröffentlichungsfähige Datenschutzerklärung und die Meldemöglichkeit für Online-KI-Inhalte benötigen noch die verifizierten Betreiber-, Kontakt- und Backend-Angaben. Für die Backend-Inspektion verlangt der Anbieter die ausdrückliche Auswahl eines Workspaces. Keine privaten Konto- oder Profildaten als öffentliche Kontaktdaten verwenden. Datenprüfung: `docs/evidence/play-data-audit-20261114-2708/`. Der belegte deutsche Store-Text liegt als unveröffentlichter Entwurf unter `docs/release/PLAY_STORE_LISTING_DE_2026-11-14.md`.

Physische Android-Bildraten, Frame-Pacing und thermisches Dauerverhalten sind ungemessen. Weder konstante 60 FPS, eine Nintendo-Freigabe noch Play-Store-Reife werden bescheinigt.

## Wiederaufnahme

Originalcode und Nachweise sind in Git gesichert. Lokale Änderungen vor jeder Aktualisierung prüfen und das vorgeschriebene Autosave ausführen. Aktuelle PR-/Run-Metadaten vor der Fortsetzung lesen. Die aktive Arbeit nutzt höchstens vier gleichzeitige Agenten in der bestehenden Hierarchie; die Rollenbeschreibung erzeugt keine unbegrenzten oder dauerhaften Hintergrundprozesse.

---

# Historical handoff before the current integration

The following earlier notes are retained as history. Older pins, pending-test statements and proposed actions below do not override the current source and results above.

## Earlier 803a quality candidate

## Gemeinsame frühere Projekthistorie


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
