# Android-Kandidat 0.13.19 (2031)

## Tatsächliche Aktivierung

### Aktueller Nachtrag: Androidtour unterbrochen, Veröffentlichung übersprungen

Androidjob **`133088843594` ist FAILURE**, Publisher **`133091481323` ist SKIPPED**. Alle vier emulierten Größenwechsel erhielten denselben Bridge-Checkpoint und positive Videodauern. Danach scheiterte in der Wortwerkstatt die einmalige unmittelbare Vordergrundabfrage nach Home; die spätere Originalaufnahme zeigt den Android-Launcher. Die frühe fehlgeschlagene Rohabfrage wurde vom damaligen Code nicht gespeichert. Zusätzlich scheiterte beim Aufräumen das bestehende positive Videodauer-Gate. Ein Produkt-Relaunch ist daraus nicht belegt. Die Wort-Rückkehr und die anschließenden nativen Referenzen sind noch nicht abgenommen. Alle **335 Originaldateien**, das gesamte geteilte ZIP und das vollständige Joblog bleiben verlustfrei erhalten: [Originalfehler und genaue Grenze](evidence/ci-2031-android-home-transition-failure/README.md). Build und unabhängige vollständige APK-Byteprüfung bleiben bestanden; ein öffentlicher 2031-Download ist weiterhin nicht freigegeben.

### Nachtrag: signierte APKs gebaut und überprüft

Buildjob **`133085378884` ist SUCCESS**. Die tatsächliche ARM64-APK hat **535.026.362 Bytes**, SHA-256 **`e6ca8e512ddc56755ae8664b3438b0e78b87a7f0e77f1cd55cac592b20b316d7`**. Die x86-APK hat **538.191.823 Bytes**, SHA-256 **`8e96a05c51fc12504a19831cee14b64c6a8e9a35a8a36863db455bed0e2cec1a`**. Beide enthalten dieselbe native PCK `94b0a84b8715537fff9ff84e451c889ca1fe1b8440a4448ded93989b3feb0aef`. Paket, Version, bestehendes Testzertifikat, ABI, Ausrichtung und Sprachassets sind am tatsächlichen Paket geprüft. Root hat außerdem das vollständige ARM64-Artifact und die gesamte APK unabhängig heruntergeladen und bytegeprüft; die Originalmetadaten stimmen mit der aktiven APK-Quelle überein. [Vollständiger Buildbeleg](evidence/ci-2031-build/README.md). Der Androidjob **`133088843594`** läuft; eine öffentliche Downloadfreigabe liegt zu diesem Nachtrag noch nicht vor.

Der normale vollständige Lauf [43800892196](https://github.com/Ullmann27/lumo-lernen/actions/runs/43800892196) wurde am **16.11.2026 um 03:54:29 UTC** auf dem exakten APK-/QA-Quellcommit **`e05a96a52aaf57e466e79831f15aaffd144284ee`**, Tree **`037ec0108fb41e13b59e73ac2514220099e9548a`**, gestartet. Run-Head und veröffentlichter Quellstand stimmen überein. Beobachteter Anfangsstatus: **in_progress**, kein abschließender Test-, APK-, Android- oder Download-PASS. Die unveränderte Native-Quelle steht unten; maschinenlesbare Bindung: [activation.json](evidence/2031-build-activation-20261116/activation.json).

## Status vor Aktivierung

### Nachtrag: vollständige Validierung bestanden

Job **`133080632526`** des exakten neuen Laufs ist erfolgreich abgeschlossen: **2.896 Fluttertests bestanden, 202 vorhandene Skips, 0 fehlgeschlagen; 143 Host-Python-Testmethoden bestanden; echter Godot-Import; 12 native Prüfprogramme mit 55.552 Assertions; 118 Projektprüfungen bestanden**. Die Analyse enthält 0 Fehler, 4 Warnungen und 274 Hinweise. Alle 359 erfassten Quellhashes und 18 geschützten Dateien stimmen. Die 56 Original-Mitglieder des Validierungsartefakts sowie das vollständige unveränderte Jobprotokoll sind bytegeprüft erhalten: [ci-2031-validation](evidence/ci-2031-validation/README.md). Zum Zeitpunkt dieses Nachtrags läuft der APK-Build; ein Android- oder Download-PASS ist noch nicht festgestellt.

Der tatsächlich integrierte Produktstand ist auf `integration/lumo-nextgen-learning-20261115` gesichert: **`cc4197e622c42dc5387ba06b7e57ac4964e1a07b`**, Tree **`6a1b4009969bdb1ad04aefbe00bd3730372b8aa7`**. Der neue vollständige APK-/QA-Lauf wird erst durch die anschließende Änderung von `config/nextgen-release.json` aktiviert. Seine exakte Quelle wird nach dem beobachteten Start ergänzt. Zu diesem Vorlaufzeitpunkt sind noch kein 2031-APK-Build, Android-PASS oder öffentlicher Download belegt.

Native bleibt **`678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`** aus `Ullmann27/lumo-godot`, Branch `integration/lumo-nextgen-learning-20261115`, Engine **Godot 4.6.3**. `main` wurde nicht verändert; Kart- und native Dschungel-Folgearbeiten bleiben ausgeschlossen.

## Eingebundene Korrekturen

- Der tatsächliche Core-Aufgabenbesitzer führt jetzt Header-Fragedialog, mobiles Fuchs-Menü und breite Frage-/Hilfetasten. Exakte eigene Route, Task-ID, Sitzung und Profil bleiben gebunden; fremde Routen erhalten keine pauschale Ausnahme.
- Beim Wechsel zwischen schmaler und breiter AppShell bleibt derselbe Core-State mit derselben Aufgabe erhalten. Der bestehende fachliche `ValueKey` bleibt bestehen; tatsächliche Navigation erneuert den äußeren Schlüssel.
- Menüschließen wartet auf die abgeschlossene Route und eine erneute Veröffentlichung des aktuellen Tasks. Eine monotone Lifecycle-Kennung sowie die erneute kanonische Identitätsprüfung nach dem Hostframe verwerfen alte Auswahlen auch nach `inactive → resumed` während des Schließens.
- Die deutsche öffnende Anführungsmarke U+201E der tatsächlichen Banane-Anweisung wird im bestehenden Offline-Sprachtokenizer in das unterstützte ASCII-Zeichen überführt. Ein begrenzter technischer Fehlercode macht Abbrüche sichtbar; keine beliebigen Äußerungsinhalte werden dafür protokolliert.
- Der Android-Prüfleser erkennt die vollständige tatsächlich umgebrochene Musterfrage anhand zusammengehöriger benachbarter Zeilen. Versuchszahl, Wartefristen und fachliche Prüfschritte bleiben unverändert.
- Die bestehende Größenwechsel-Aufzeichnung beginnt vor der tatsächlichen WM-Änderung. Das ursprüngliche Ein-Frame-Video bleibt ein negativer Beleg; das positive Dauerkriterium bleibt unverändert.

Der Core-Komponentenbranch `fix/lumo-core-conversation-scope-20261116` ist als **`5194401517a3a0882cb50635ddecd788703cd07c`** veröffentlicht. Sein Tree **`151239945191d8edcfd03cd143911aa70808c28d`** ist bytegleich zur geprüften Produzentenspitze `a8b5093ea14acacf241e8590be187cd180fb27d8`. Die getrennte Presenter-Komponente liegt auf `fix/lumo-core-menu-presenter-20261116` bei **`2c91bc7245005602b1649bf42dced8b918c2c4c5`**. Selektive Übernahmen, Quellhashes, Reviews und Original-Handoffs stehen unter [2031-qa-integration-20261116](evidence/2031-qa-integration-20261116/).

## Tatsächlich ausgeführte Vorprüfungen

- **20 Core-/Shell-/Navigations-Widgettests bestanden, 0 fehlgeschlagen, 0 übersprungen** am finalen Komponentenstand. Die früheren 14-, 15- und 19-Test-Läufe überlappen und werden nicht addiert. Die fünf geprüften Dateien melden in der Analyse „No issues found“. Echte Routing-/Controllerlogik mit ausdrücklich synthetischem Assettransport und Ersatzfonts; kein Android-, Audio- oder Bildqualitätsbeleg. Beide ursprünglichen Produktfehler sind unverändert unter [core_companion_menu_scope_20261116](evidence/core_companion_menu_scope_20261116/) erhalten.
- **38 betroffene Host-Testmethoden bestanden** am zuvor dokumentierten integrierten Stand `b49cf9c7e1e60c4e3901883d1c6bfc4a46e9ede4`: Offline-Tokenisierung, Sprachfehlervertrag, Android-Vorlagenkopie, Musterleser und Aufnahmevertrag. Originalprotokoll und genaue Java-/Kotlin-/Python-Grenze: [joined-host-contracts.json](evidence/2031-qa-integration-20261116/joined-host-contracts.json). Kein neuer Android-PASS.
- **40 bestehende Versions-/Pin-Tests bestanden** und der reale Prüfer akzeptiert `0.13.19+2031` mit dem unveränderten Native-Pin. Alle alten Freigabepins bleiben erhalten. [Release-Pin-Provenienz](evidence/coverage_refresh_20261116_2031/release-pin-provenance.json).
- **Frischer tatsächlicher Dart-Katalogexport an `cc4197e622c42dc5387ba06b7e57ac4964e1a07b`**: 61 Inventareinträge, 55 Screen-Dateien, 236 Curriculumfamilien, 19 aktive Spezialrouten auf 18 Screens, 6 Labs mit 35 Problem-IDs und 12 native Lernarten. Alle **359 erfassten Quellhashes** wurden überprüft. Alle **18 geschützten Schreib-/Journaldateien sind bytegleich** zur Basis `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`. Vollständige Bestandsaufnahme: [COVERAGE.md](COVERAGE.md), [COVERAGE.json](COVERAGE.json); Rohkatalog, Befehl, Log und Hashnachweis: [coverage_refresh_20261116_2031](evidence/coverage_refresh_20261116_2031/).

Diese Nachweise haben unterschiedliche Quellen und Prüfumfänge. Sie sind keine zusammengezählte vollständige Prüfung des späteren APK-Quellcommits. Die normale Pipeline führt dafür alle Flutter-, Host- und nativen Prüfungen neu aus.

## Identität und unveränderte Auslieferungskriterien

- Version **`0.13.19+2031`**; vorgesehener neuer Tag **`lumo-nextgen-learning-0.13.19-2031`**.
- Bestehendes Paket **`dev.ullmann.lumo.lumo_lernen.coachpreview`**.
- Bestehendes Testzertifikat SHA-256 **`a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`**; keine Play-Produktionssignatur behauptet.
- Der normale Workflow prüft exakte Quellen und geschützte Module, vollständige Fluttertests, Host-Verträge, echten Godot-Import und native Regressionen. Danach baut und prüft er die signierten ARM64- und x86-APKs samt PCK, Sprachartefakten, ABI und Ausrichtung.
- Beide vorhandenen Android-Prüfstrecken müssen am tatsächlichen aktuellen APK-/QA-Commit bestehen. Eine frühere APK, getrennte Diagnose oder korrigierte Offline-Lesefunktion ersetzt diesen Nachweis nicht.
- Der Publisher verlangt ein noch nicht vorhandenes Release und Tag. Erst nach bestandenen Gates wird ein neues unveränderliches Prerelease erstellt; anschließend werden echte Metadaten und der vollständige anonym heruntergeladene APK-Bytehash geprüft. Vor diesem Nachweis wird kein erwarteter Downloadpfad als vorhandener Link ausgegeben.

## Erhaltene Fehlerbelege und konkrete Grenzen

Eine zusätzliche rein lesende Auswertung der vier tatsächlichen Flutter-Modell-XMLs zeigt 29 von 35 aktivierten sichtbaren Klickrechtecken mit mindestens 48 × 48 dp. Sechs weitere Rechtecke sind am unteren Scrollrand teilweise abgeschnitten. Dies ist keine Vollabnahme aller Berührungsflächen und kein nativer 3D-Nachweis; alle Einzelwerte und Originaldateihashes stehen in [ci-2031-layout-touch-inspection](evidence/ci-2031-layout-touch-inspection/README.md).

Kandidat 2030 endete mit **Validierung PASS, Build PASS, Android FAIL, Veröffentlichung SKIPPED**. Sein erster Modell-Tipp nach dem Gespräch bewahrte den Lernstand; das bestehende Aufnahmedauer-Gate stoppte anschließend die Tour. Die 225 Originaldateien und das vollständige Jobprotokoll bleiben verlustfrei archiviert: [ci-2030-android-resize-recording-failure](evidence/ci-2030-android-resize-recording-failure/README.md). Die getrennten 2029-Diagnosen sind ausdrücklich keine Freigabe für 2031.

**`fullModernizationComplete=false` bleibt bestehen.** Die inventarisierten Einstiege sind kein vollständiger Test aller generierten Aufgabenvarianten. Viele Bereiche verwenden eine gemeinsame native Aufgabenkarte; die 3D-Figur läuft über die vorhandene separate Godot-Activity. Praktische Beobachtungsaufgaben behalten ihren absichtlichen manuellen Journalnachweis.

Die erhaltene tatsächliche native 8+5-Diagnose im API-35-x86-Emulator mit nicht beschleunigtem llvmpipe ergab 45 Prozessintervalle mit einem gewichteten Mittel von rund **978 ms**; davon hatten 10 Stichproben gleichzeitig Figur, akzeptierte Audiowiedergabe und aktive Effekte. Das ist weit vom 60-FPS-Ziel entfernt und keine Prognose für ein physisches ARM64-Gerät. Herkunft, Messdefinition und Grenzen sind in [native-performance-interpretation.json](evidence/2031-qa-integration-20261116/native-performance-interpretation.json) dokumentiert.

Physisches Fold7-Falten, echte gesprochene Erkennung, akustische Qualität, gemessener gemeinsamer Ton-/Mund-/Gestenabbruch, native Langsamer-Wiedergabe, vollständige Upgrade-/Prozesstod-Erhaltung und ≥48 dp für sämtliche tatsächlich sichtbaren nativen Bedienelemente sind noch nicht vollständig belegt. Der Widgettest 430 → 1000 dp und emulierte Zielgrößen ersetzen diese Geräteprüfungen nicht.
