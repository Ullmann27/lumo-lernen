# Stand und Weiterarbeit · 9. Oktober 2026 (Claude, Version 0.12.7+1914)

**Zuerst lesen:**
1. [docs/LUMO_VISUAL_EXECUTION_2026-10-09.md](docs/LUMO_VISUAL_EXECUTION_2026-10-09.md) – Bestandsaufnahme der PRs, Integrationsmatrix, Prüfungen, APK-Stand.
2. [docs/LERNAPP_PRUEFBERICHT_2026-10-09.md](docs/LERNAPP_PRUEFBERICHT_2026-10-09.md) – Lernapp: was geprüft, behoben und offen ist, Markt/Evidenz und die Idee fürs Alleinstellungsmerkmal.
3. Godot-Repo `docs/wip/2026-10-09-lumo-gesicht/README.md` – Lumo-Gesicht und Anzug als Patch (Zwischenstand, **nicht** im Spiel).

**Stände:** App und Godot auf `claude/continue-previous-chat-KtY7p`. Die App pinnt Godot `de91cc9` (Claude-Strang + Codex-1909/1910-Strang +
Spielstart-Branding); das Godot-Repo liegt inzwischen bei `4a4bf98` (nur Doku). Eingearbeitet: App-PR #227 und #228, der Codex-Strang (#223/#225/#226)
und Godot-PR #37, #32/#35/#36. #229 bleibt Alternative zu #228. Kein Merge nach `main`, kein Release.

**APK:** 1913 ist gebaut (Run 37937263563; Build, Flutter-Suite und 26 strenge Spielproben grün, Android 16 komplettes Rennen grün, Android 15
Rennen komplett durchgelaufen, nur das Abholen der Aufnahme scheiterte an „device offline“). 1914 enthält die Reparaturen aus dem Lernapp-Bericht und
die Absicherung dieses Abholens. **APK 1909 bleibt der unveränderte, geprüfte Rückfallstand.** „Technisch fertig“ und „visuell abgenommen“ sind getrennt:
visuell ist **nichts abgenommen** (VISUAL_GAP).

**Wo weiterarbeiten (Reihenfolge):**
1. **Lumo und COMET** nach den Referenzblättern (`docs/design_targets/2026-10-08-kart-fahrzeuge/`): Patch einbauen, Referenzmaße ausmessen, acht Ansichten,
   Materialien, dann das COMET-Premiumkart. Nichts als „identisch zur Vorlage“ melden.
2. **Knobel-Test Messqualität** (Bericht Abschnitt 3): Ablenker so bauen, dass keine Ratestrategie über Zufall liegt (F1), mehr Rätsel je Bereich (F2),
   Sprachausgabe, Eltern-Ansicht, Mehrprofil.
3. **Vier nicht geprüfte Lernapp-Themen** (Bericht Abschnitt 6): Lerninhalt/Lehrplan je Klasse, Aufgaben-Fuzzing, Grafik per echter Renderings, Fehlersuche.
4. **Alleinstellungsmerkmal „Lumo macht einen Fehler“** (Bericht Abschnitt 5, MVP in 1–2 Tagen) – erst nach Heinz' Freigabe.
5. **Spielstart** Phase D/E (Menü, Vorschau, Kamerafahrt) und **Welten** (Identität, Tiefenschichten, Streckenlängen Zauberwald 377 m, Holo-City 443 m,
   Himmelsinseln 473 m).
6. **Android:** Lauf auf API 35 und 36 mit dem abgesicherten Aufnahme-Abholen, Fold/Responsive-Matrix, Gerät und Bildrate (bisher nicht gemessen).

**Offene Entscheidungen für Heinz:** Spracherkennung `onDevice` (Datenschutz), PIN-freier Elternbereich beibehalten?, „Werkstatt-Mathe“ (widerspricht
DESIGN_ZIEL_KART), Name „Knobel-Test“ statt „IQ-Test“.

---

# Übergabe an ChatGPT Sol 6.1 · 9. Oktober 2026 (Claude-Strang)

Zuerst [die Übergabe von Claude](docs/handoffs/CLAUDE_TO_SOL_2026-10-09.md) lesen: Stände, Nachweise,
Offenes, Arbeitsweise. Branch `claude/continue-previous-chat-KtY7p` (App und Godot) enthält die
Codex-Stände (App 214/215/216/221, Godot 27/28/29/31) und den Claude-Strang (14 Karts, Werkstatt mit
Prüfstand, Action-Parcours, Knobel-Test). **VISUAL_GAP / NOT FINISHED**; Main und Releases unverändert.
Die ältere Recovery-Anweisung darunter bleibt gültig, soweit sie hier nicht ersetzt wurde.

# Neuer App-Wiederherstellungsstand1906 · 9. Oktober2026UTC

---

# Aktueller Stand: APK 0.12.6+1909 · 9. Oktober 2026

Die **installierbare, signierte APK 1909 ist gebaut und bereitgestellt**. Aktueller App-PR: [#223](https://github.com/Ullmann27/lumo-lernen/pull/223); Spielstand: [lumo-godot#32](https://github.com/Ullmann27/lumo-godot/pull/32).

- APK-Quellstand: App `aa6519226fded77d5d5022dc6fe8c223e9dc82b8`, Godot `a377b9e2db3337ae46f9439200ef0af17af06cb5`.
- APK: 203803554 Bytes, SHA256 `b58e055340595ac882fed47d0c11660f2420e41c1528ed2841c5100f13304fb7`; Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, Version `0.12.6+1909`, ARM64/x86_64, stabil signiert. Der PCK enthält Aquarium, Hütchen und Prüfstand.
- [Bau und Nachweise](https://github.com/Ullmann27/lumo-lernen/actions/runs/37888592898): 808 Flutter-Tests bestanden (4 vorhandene Skips), 579 QA-/36 Vorbereitungstests, 25 native Proben, 24 Profilbudgetprüfungen; APK-Signatur/Version/Quellstand/16-KiB-Ausrichtung geprüft. Android-Update, Offline-Spiel und Speicher-/Belohnungsschutz für Bauwelt, Puzzle, Rhythmus und Schatzsuche grün.
- Beide erste Kart-Läufe stoppten vor dem Vollrennen an einem belegten Bildleser-Fehlnegativ für DRIFT. [Reparatur und echte Fehlerbilder](docs/APK_1909_ANDROID_READER.md) sind in Testwerkzeug-Commit `7a570c1fc69b21f0e081ace208b082796bc30057` enthalten. 581 Tests einschließlich beider echten Bildfixtures grün.
- **Android 16 / API 36: vollständiges Kart-Rennen PASS** in [Job 113699324621](https://github.com/Ullmann27/lumo-lernen/actions/runs/37893374564/job/113699324621): 16 Checkpoints, Pause, Größenwechsel/Rotation, Ergebnis, Offline-Wiederaufnahme, Host-ACK und doppelte Belohnung verhindert. Exakt dieselbe APK; keine physische Fold-/FPS-Messung.
- **Android 15 / API 35: vollständiges Kart-Rennen PASS** in [Job 113710020612](https://github.com/Ullmann27/lumo-lernen/actions/runs/37896765244/job/113710020612), einschließlich 16 Checkpoints, Pause, Bildschirmwechsel, Ergebnis, Offline-Wiederaufnahme, ACK und Belohnungs-Deduplizierung. 585 QA-Tests lokal und in CI bestanden. Die Testwerkzeuge wurden korrigiert; die APK blieb unverändert. Frühere Fehlläufe und ein zusätzlicher API-36-OCR-Timeout bleiben dokumentiert.

**Abschlussbericht:** [APK_1909_ABSCHLUSS.md](docs/APK_1909_ABSCHLUSS.md) enthält genaue Jobs, Hashes, Testgrenzen und verbleibenden PR-Mergekonflikt. Beide Android-Versionen bestanden in getrennten Nachläufen; kein pauschaler Gesamt-CI-Erfolg.

Neu abgeschlossen: 14er-Flotte und Werkstattanschluss erhalten, kostenloser Prüfstand mit gemeinsamen Fahrformeln, Aquarium mit animiertem Wasser/Fischen und sanfte Hütchen-Hindernisse. [Details](docs/APK_1909_ACTION_WORKSHOP.md).

Physische Fold-Leistung/60 FPS und vollständige Referenzvideo-Gleichheit sind nicht belegt. Kein Main-Merge und kein Release. Ältere Angaben unten zu fehlender APK oder vorläufigem Pin sind historisch; die jeweiligen früheren Designabweichungen bleiben nachvollziehbar dokumentiert.

---

# Gemeinsamer App-Entwurf 1908 · 9. Oktober 2026 UTC

Zuerst [die neue selektive Integrationsübergabe](docs/handoffs/LUMO_SELECTIVE_INTEGRATION_1908_2026-10-09.md)
lesen. **SOURCE CHECKPOINT / FINAL PIN PENDING / VISUAL_GAP / NOT FINISHED**. Der Entwurf
führt den tatsächlich aktuellen App-Stand `36391b2d2a332e93f3bac46bf21afb83fad15d8a`
mit Recovery `4458590063b9e59fc7f36fe9dea4e798b95a192a` zusammen und bewahrt
die neuen IQ-, Analyze-, FleetStats- und Workshop-Anschlüsse. Quellversion:
`0.12.5+1908`. Der vorhandene Godot-Pin `99cdb776df10e8cc719d19792c17074c887b5112`
ist zunächst nur der unveränderte Ausgangspin. Ein endgültiger Pin und neue
echte Native-Fixtures warten auf den geprüften gemeinsamen Godot-Quellstand.
Aktuell:579QA+36Scripts PASS,0Fehler/Skips; unabhängige68Quell-/AST-Prüfungen PASS. Keine1908APK oder Android-Abnahme.

Die folgenden 1906-Abschnitte bleiben historische Wiederherstellungsübergaben.
Nach einem dritten Workspaceverlust wurden die veröffentlichten Quellen erneut
aus Git wiederhergestellt; verlorene lokale Nachweise gelten nicht als neue
Prüfungen dieses Entwurfs.

# Neuer App-Wiederherstellungsstand1906 · historischer Kontext vom 9. Oktober2026UTC

Aktuelle Fortsetzung nach **zweitem Workspaceverlust**: vollständiger sauberer
Recoverycheckout aus `1c5300267b5689d450f67bcf59d700f1c3d6d0d8`/Tree
`4b92e0531c23c0bf93a75b95179b2353cae4b01a`. Lokale historische Reports sind
verloren; frühere Testzahlen ersetzen keine neue Ausführung. Der
[neue Lifecycle-Quellanschluss](docs/handoffs/HANDOFF_LIFECYCLE_SOURCE_PREPARATION_1906_2026-10-09.md)
ergänzt fünf streng gebundene Summaryfelder und den eigenen JSON-Artefaktpfad.
Seine neue Testfixture ist ausdrücklich synthetisch. Aktuelle leakfreie
Godot-/Lifecycle10-GL-Abnahme, finaler Pin und APK1906 bleiben ausstehend.
Gesamtstatus: **VISUAL_GAP / NOT FINISHED**.

Neue tatsächliche Quellenprüfung nach diesem Verlust:579 Android-QA- und36
Scriptprüfungen PASS,0 FAIL/0 ERROR/0 SKIP. Darin30 neue ausschließlich
synthetische Lifecycleguards; alte48 Originaldateien und bisherige86 Lapguards
bleiben unverändert. Der historische erste NDK-Scriptfehlversuch bleibt im
neuen Handoff dokumentiert. Kein aktueller Runtime-/APK-Erfolg wird übertragen.

Zuerst [die neue Wiederherstellungsübergabe](docs/handoffs/LUMO_APP_RECOVERY_1906_2026-10-09.md)
lesen. Status: **RECONSTRUCTED_NEW_SOURCE / VISUAL_GAP / NOT FINISHED**.
Veröffentlichte App-Basis ist `f6c4f3350db8153200594b52a9d82606279dc238`;
die neue Quellversion ist `0.12.4+1906`. Der Original-Godot-Pin
`ad3ee9c9a1e2cfa60a6d2fe4970181b3150a1a1b` bleibt zunächst als Baseline
erhalten. Ein finaler Pin wartet den tatsächlich veröffentlichten, neu
geprüften Godot-Wiederherstellungsstand. Noch kein neuer App-Quellfreeze.

Der ursprüngliche Arbeitsbereich ging nach geschlossenen Prüfungen verloren.
Alte lokale App45-/SDK576-/436-/47-/Godot103-Nachweise sind historische
Ausführungen und werden nicht auf neue rekonstruierte Dateibytes übertragen.
Der aktuelle Teilbestand wurde aus dem exakten veröffentlichten f6-Quellstand
mit Git-Blob-/Byteprüfung wiederhergestellt. Alle ursprünglichen Tests und
Bildfixtures bleiben unverändert. Ein späterer vollständiger Quellabschluss
benötigt ein neues Dateiinventar und neue unabhängige Prüfberichte.

SDK-Helper16572B/SHA8925b7b41fada3c41fc80959c03fb71314f60530adbdc8e6614ea94e0c6a9c51
ist exakt aus veröffentlichtem7cff wiederhergestellt. Neue eigenständige
SDK-Tests:58 PASS/0 FAIL/0 SKIP, davon fünf kontrollierte lokale CLI-Prozesse.
Neue enge Emulator-Handoff-Probe: unveränderte neue15er-Probe f6 RED→15/0
GREEN; ursprüngliche Root23/Handoff13/Identity14/CompleteEvidence54 ebenfalls
PASS. Die neue Gas-Recovery besteht33 Guards plus82 unveränderte Originalguards;
identischer echter Funktions-Test f6 RED→GREEN. Die neue ganze Quellenprüfung
liefert448 Android-QA- und36 Scriptprüfungen PASS/0 FAIL/0 SKIP. Ein erster
Teilcheckout-Versuch hatte eine fehlende originale Dart-Datei; dieser Fehler
bleibt dokumentiert, die Originaldateien wurden bytegenau ergänzt. Unabhängige
Quellenpeers haben den14-Dateien-Checkpoint unabhängig mit448/36 bestätigt;
Recoverycommit `4fe583ff84756250cbd85188ea56360db5672a7d` ist gesichert.
Der finale Godot-Anschluss steht aus. Originalrunner/API35/36,
Emulator14472402, Java/Abhängigkeiten,45-Minuten-Job, Renn-/ACK-/Wallet-/Fold-
und Ressourcengates bleiben erhalten. Keine echte Android-Ausführung hier.

Der folgende neue Entwurf ergänzt einen eigenständigen typed Native-Guard
und die Zeitformatprobe als22. Prüfung; die ursprüngliche15er-GL-Schleife,
alle21 alten Marker und Modal37/14 sowie Countdown9 bleiben erhalten.
[Der Native-Vertrag](docs/handoffs/NATIVE_LAP_EVIDENCE_RECOVERY_1906_2026-10-09.md)
bindet neue Continuity104-/Formatter29-Quellen und echte JSON-/PNG-Dateien.
Flow bleibt wegen tatsächlicher ursprünglicher ACK-Assertion-Fehler und
Teardown-Reproduktion blockiert; seine geschlossene Rerun-Fixture belegt
ausschließlich das Schema. Keine finale Godot-/App-Pin- oder APK-Freigabe.
Dieser neue Entwurf besteht534 Android-QA- und36 Scriptprüfungen PASS ohne
Skips; darin86 neue Native-Guards. Die48 ursprünglichen Tests/Fixtures bleiben
bytegleich. Alle22 Bashsteps/sechs Inline-Python-Blöcke sind syntaktisch geprüft.

Der20-Dateien-Checkpoint ist unabhängig bestätigt und als Recoverycommit
`8abb01a6bf470e46bd279f637ba84f850d98fab0` gesichert. Eine weitere enge
Reparatur verhindert Kart-PASS bei fehlgeschlagenen Ressourcenaufnahmen:
beide vorhandenen Phasen, deren Source/API/Serial und drei rohe Reads sind
vor Final-PASS erforderlich. Identische neue15er-Probe: vorher62 negative
Kontrollfehler, danach ganze Suite549 PASS/0 FAIL/0 SKIP. Die zwei zulässigen
Kontrollen bestanden vorher; legitimes RSS-UNAVAILABLE bleibt zulässig.
Capture-/Rennfristen und originale48 Tests/Fixtures bleiben unverändert.
Keine echten neuen Ressourcenmessungen oder FPS-Konversionen.

Historische tatsächliche APK1905 wurde in Actions37846382465 gebaut und
byteweise geprüft (201691346B/SHAf06140353caa1f2d4c0038287b05918402324b26cc9dc5454ca1c13e9597f14c).
Der unveränderte Bauen-Diagnoselauf37861486692/7cff bestand sichtbar; Haus161
Teile/einmal3 Sterne24XP/Replay/finaler Offline-Neustart. Das ersetzt keinen
neuen Kart-/APK1906-/Fold-/Performance-Nachweis. Abbruch im unfertigen Spiel,
expliziter ACK-Payload und Bootstrap-Input-Contenthashes sind dabei nicht belegt.

Neue exakte APK1906, vollständige Androidläufe, physisches Fold, Geräte-FPS,
Referenzbewegung und verbleibende Modell-/Licht-/Audioabnahme: **NOT EXECUTED**.
Nächster Schritt: neue Gas-/Handoff-/SDK-Peers und gesamte Quellenprüfung,
neue Godot-Proben/Pin,22 Nativeprüfungen mit erhaltenen alten21, neue APK mit
eigenen Byte-/Runtimebelegen. Main und Releases bleiben unverändert.

Die folgende veröffentlichte1905-Anweisung ist historischer Kontext.

# Integrierter Lumo-Kandidat 1905 · historische Anweisung vom8. Oktober2026

Zuerst [die aktuelle 1905-Übergabe](docs/handoffs/LUMO_INTEGRATED_RUNTIME_1905_2026-10-08.md)
lesen. Maßgeblich sind der frische App-Branch-HEAD, der exakte Godot-Pin
`ad3ee9c9a1e2cfa60a6d2fe4970181b3150a1a1b` und die tatsächlich gebauten
APK-/PCK-Bytes. Quellversion: `0.12.3+1905`. Dieser freie Anschlussstand
verbindet die erhaltene App-/Spielarchitektur mit acht selektiv geprüften
Grafikdateien, der vollständigen 37er-Modalfixture und strenger Android-QA.

Eigene App1be/Godot6873 in Actions37833588822 scheiterte vor der APK am
belegten Gas-Modusfehler der Fixture: KEINE APK, Android SKIPPED. Die getrennte
App497/Godot7ded-APK `0.12.2+1904` wurde wirklich gebaut. Ihr vollständiger
API35-Lauf einschließlich Ergebnis, ACK, einmaliger Belohnung, Offline-Recovery
und sichtbarer Flutter-Rückkehr ist unabhängig bestätigt; API36 bleibt wegen
einer zusätzlichen übergroßen Raw-OCR-Fußzeilenbox FAIL. Beides ist historische
Provenienz und kein Ergebnis dieses neuen Pins.

Der neue Reader korrigiert ausschließlich die belegte OCR-Geometrie bei
unabhängiger Bestätigung. Zwei frische Flutter-Oberflächen samt exakter
MainActivity sind vor dem abschließenden Offline-Neustart verpflichtend.
Zwei begrenzte, rein lesende native Ressourcenaufnahmen erfassen CPU-Zähler
und Speicher bei beobachteter Fahrt und am Ergebnis vor Fold. Ihre Fehler
bleiben ausdrücklich FAIL; GPU, Framezeiten, FPS und physische Geräte werden
daraus nicht abgeleitet. Alle bisherigen Rennen-/Wallet-/ACK-Gates bleiben.

Die exakte neue APK1905, ihre API35/36-Wiederholung und Referenzabnahme sind
PENDING / NOT EXECUTED. **VISUAL_GAP / NOT FINISHED**. Main und Releases
bleiben unverändert. Folgende Übergaben sind historische Kontexte.

## Integrierter Kandidat 1904 · historische Übergabe

Zuerst [die aktuelle 1904-Übergabe](docs/handoffs/LUMO_INTEGRATED_RUNTIME_1904_2026-10-08.md)
lesen. Aktive Integrations-PRs sind App216 und Godot29. Maßgeblich sind der
jeweilige frische Branch-HEAD, `config/godot-source.json` und die tatsächlichen
APK-/PCK-Bytes. Version der Quelle: `0.12.1+1904`.

APK1903 aus App3e1d0eb3/Godot18238d48 wurde in Actions37817947080 wirklich
gebaut und unabhängig byteweise geprüft. Bauen/Puzzle/Rhythmus/Schatzsuche35
bestanden; beide vollständigen Kartläufe bleiben FAIL. Der kleinste Folgefix
repariert echte Touch-Weitergabe von Pause-/Ergebnisbuttons; identischer
BASE-Test strikt RED, Kandidat 35 Checks/sechs Drags/14 echte PNGs GREEN.
Eine getrennte QA-Reparatur prüft den bekannten Emulator vor Fullrace-Reads
und überbrückt ausschließlich den belegten initialen Offlinefehler begrenzt.
288 lokale QA-Guards/0 SKIP sind unabhängig bestätigt.

Die neue exakte APK1904 und ihre Android-Renn-/ACK-/Belohnungsprüfung müssen
im aktuellen Lauf erst gebaut und bestätigt werden. Native Software-GL-Bilder
sind keine APK-/Zielgeräte-/60-FPS-Nachweise. **VISUAL_GAP / NOT FINISHED**.
Keine Änderungen an Main oder Releases. Folgende 1903-/1900-Übergaben sind
historischer Kontext und ersetzen keine aktuelle Provenienzprüfung.

## Integrierter Kandidat 1903 · historische Übergabe

Lies zuerst [die1903-Übergabe](docs/handoffs/LUMO_INTEGRATED_RUNTIME_1903_2026-10-08.md).
Aktiv sind App-Integrationsbranch/PR216 und Godot-Integrationsbranch/PR29;
QA217/218 ist übernommen. Godotpin18238d48, Version0.12.1+1903.
Der erste 1903-Bau auf App76daa1fb ist am ungültigen NDK-Archiv gescheitert;
keine 1903-APK ist daraus entstanden. Dieser Folgecommit ergänzt eine frühe
Prüfung des exakten NDK und korrigiert die anhand echter Androidbilder belegte
Scrollprüfung innerhalb des Pausemodals. Die alten Fehler bleiben erhalten.
Build-/Android-Erfolg muss aus dem aktuellen CI-Lauf und dem tatsächlichen APK
belegt werden. Status beim Commit: VISUAL_GAP / NOT FINISHED.1902 wurde real
gebaut, hatte aber vier Android-Fails; bestätigter Pausefehler jetzt korrigiert.

Die folgende Übergabe dokumentiert den **historischen Stand vor Integration**.
Ihre alten Pins, offenen Merge-Schritte und1900-Abnahme ersetzen keine aktuelle
HEAD-/Claim-/Provenienzprüfung. Die vollständige ursprüngliche Übergabe bleibt
als Kontext erhalten.

## Direkte Übergabe an Claude Opus 5.5 · 8. Oktober 2026

Lies zuerst [die vollständige aktuelle Übergabe](docs/HANDOFF_CODEX_TO_OPUS_2026-10-08.md).
Sie enthält Änderungen an App, Lumo, Karts, Steuerung, Kamera und allen zwölf
Rennwelten, echte Prüfbelege, laufende Builds und konkrete nächste Arbeitsschritte.

## Aktuelle Koordination

- App: Referenz-/Kamerastand PR 214 auf `codex/lumo-reference-app-2026-10-08`
  und zusätzliche Runtimearbeit PR 215 auf `codex/lumo-runtime-apk-2026-10-08`.
- Godot: Referenz-/Kamerastand PR 27 auf `codex/lumo-reference-design-2026-10-08`
  und zusätzliche Speicher-/Kontaktarbeit PR 28 auf `codex/lumo-race-continuity-2026-10-08`.
- Die Paare sind noch nicht vollständig integriert. Frische Heads, Claims und
  deren Übergaben lesen. Meine letzte Kamerakorrektur in `30dc99b` / App `84ce0e3`
  mit der zusätzlichen Runtimearbeit verbinden; keinen fremden Pin überschreiben.
- APK `0.12.0+1900` hat alle sieben Jobs in Actions 37784807913 bestanden.
  Sie enthält die letzte Kamerakorrektur noch nicht. Neue 1901-Kandidaten sind
  separat zu prüfen; ein späterer kombinierter Build sollte mindestens 1902 sein.
- Referenzgleiche Produktionsmodelle, Tonabnahme, physisches Fold und belastbare
  60 FPS bleiben offen. Echte Screenshots und Clips statt Konzeptbilder als
  Runtime-Beleg liefern. Rennen enthalten keine Lernfragen/Antwort-Turbos.

Der vollständige Produktauftrag `docs/OPUS_ENTWICKLUNGSAUFTRAG.md` liegt in der
Lern-App; seine historischen Basis-SHAs nicht als heutige Heads übernehmen.
Die [alte Startanweisung](docs/OPUS_NEXT_ARCHIV_2026-10-07.md) bleibt als Archiv.
Diese Übergabe startet keine weitere KI-Sitzung automatisch.
