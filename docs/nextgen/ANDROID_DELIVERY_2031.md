# Android-Kandidat 0.13.19 (2031)

## Status vor Aktivierung

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

Kandidat 2030 endete mit **Validierung PASS, Build PASS, Android FAIL, Veröffentlichung SKIPPED**. Sein erster Modell-Tipp nach dem Gespräch bewahrte den Lernstand; das bestehende Aufnahmedauer-Gate stoppte anschließend die Tour. Die 225 Originaldateien und das vollständige Jobprotokoll bleiben verlustfrei archiviert: [ci-2030-android-resize-recording-failure](evidence/ci-2030-android-resize-recording-failure/README.md). Die getrennten 2029-Diagnosen sind ausdrücklich keine Freigabe für 2031.

**`fullModernizationComplete=false` bleibt bestehen.** Die inventarisierten Einstiege sind kein vollständiger Test aller generierten Aufgabenvarianten. Viele Bereiche verwenden eine gemeinsame native Aufgabenkarte; die 3D-Figur läuft über die vorhandene separate Godot-Activity. Praktische Beobachtungsaufgaben behalten ihren absichtlichen manuellen Journalnachweis.

Die erhaltene tatsächliche native 8+5-Diagnose im API-35-x86-Emulator mit nicht beschleunigtem llvmpipe ergab 45 Prozessintervalle mit einem gewichteten Mittel von rund **978 ms**; davon hatten 10 Stichproben gleichzeitig Figur, akzeptierte Audiowiedergabe und aktive Effekte. Das ist weit vom 60-FPS-Ziel entfernt und keine Prognose für ein physisches ARM64-Gerät. Herkunft, Messdefinition und Grenzen sind in [native-performance-interpretation.json](evidence/2031-qa-integration-20261116/native-performance-interpretation.json) dokumentiert.

Physisches Fold7-Falten, echte gesprochene Erkennung, akustische Qualität, gemessener gemeinsamer Ton-/Mund-/Gestenabbruch, native Langsamer-Wiedergabe, vollständige Upgrade-/Prozesstod-Erhaltung und ≥48 dp für sämtliche tatsächlich sichtbaren nativen Bedienelemente sind noch nicht vollständig belegt. Der Widgettest 430 → 1000 dp und emulierte Zielgrößen ersetzen diese Geräteprüfungen nicht.
