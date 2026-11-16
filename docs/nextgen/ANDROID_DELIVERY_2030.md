# Android-Kandidat 0.13.18 (2030)

## Abgeschlossenes Ergebnis des ursprünglichen Laufs

Der Lauf [43790915460](https://github.com/Ullmann27/lumo-lernen/actions/runs/43790915460) auf **c4e330faa61e231dd3fd44c21085c95ddcd5b7c9** ist abgeschlossen: **Quellprüfung PASS, Build PASS, Android FAIL, Veröffentlichung SKIPPED**. Es gibt aus diesem Lauf keinen freigegebenen öffentlichen APK-Download. Die nachfolgenden Vorlaufabschnitte dokumentieren den damaligen Plan; diese abgeschlossene Beobachtung ist der aktuelle Stand für 2030.

Die tatsächliche Quellprüfung umfasst 2.887 bestandene Fluttertests und 202 vorhandene Skips, 109 bestandene Host-Testmethoden, echten Godot-4.6.3-Import, 55.552 native Assertions und 118 bestandene Projektprüfungen. Alle 248 erfassten Quellenhashes und 18 geschützten Dateien stimmen. Die Analyzer-Ausgabe enthält 0 Fehler, 4 Warnungen und 274 Hinweise; die isolierte native ObjectDB-Abschlusswarnung bleibt im Originalprotokoll erhalten. Die vollständigen ursprünglichen Belege stehen unter [ci-2030-validation](evidence/ci-2030-validation/summary.json).

Die tatsächlich gebaute und in CI geprüfte ARM64-APK ist 535.021.298 Bytes groß, SHA-256 `96e4bcd060df8f18b015532f7a58f2073d6a9225e7c6d32af50bd219b6a01fa3`. Für den Emulator wurde die 538.184.607-Byte-x86-APK mit SHA-256 `66870e9232eaf05e5cad893d410cb8046318ae6d226c0bd0e90e1af0a178a4f2` tatsächlich installiert und zurückgelesen. Der Buildbeleg enthält die Prüfungen von Paket, Version, vorhandenem Testzertifikat, ABI, 16-KiB-Ausrichtung, PCK und Offline-Sprachassets. Das ist kein lokaler Root-Download der ganzen ARM64-Datei und keine Downloadfreigabe. Vollständiger Beleg: [ci-2030-build](evidence/ci-2030-build/summary.json).

Im Android-API-35-Emulator bewirkt der erste Stein-Tipp nach dem Gespräch jetzt `moved: 0 → 1`. Pause, Rückkehr und die kompakte Zielansicht bewahren diesen Aufgabenstand und das Testprofil. Die Kompaktansicht erreicht tatsächlich 720 × 1600 Pixel bei 320 dpi. Der Lauf scheitert anschließend am bestehenden positiven Videodauer-Gate: Die Aufnahme enthält einen lesbaren H.264-Frame, aber keine positive Dauer. Erweiterte/Fold7-Ansichten und die nachfolgenden nativen Referenzen wurden in diesem Lauf nicht erreicht. Alle 225 Originaldateien und das vollständige Jobprotokoll sind verlustfrei archiviert: [ci-2030-android-resize-recording-failure](evidence/ci-2030-android-resize-recording-failure/README.md).

Die separate 2029-Diagnose ist ebenfalls abgeschlossen: 8+5 wurde diagnostisch durchlaufen; Banane scheiterte vor akzeptierter Wiedergabe und Muster an einem später bestätigten Leserproblem bei der umgebrochenen Überschrift. Sie verwendet die älteren APK-Bytes und hat keine Releaseberechtigung. Originale: [Bridge](evidence/ci-2029-native-diagnostic-bridge/summary.json), [Banane](evidence/ci-2029-native-diagnostic-banana/summary.json), [Muster](evidence/ci-2029-native-diagnostic-pattern/summary.json).

## Belegter Defekt und Produktänderung

Die2029-APK hatte erfolgreiche vollständige Quell- und Buildprüfungen, scheiterte aber im tatsächlichen Androidlauf43785937519 beim ersten Stein-Tap nach Gesprächsrückkehr. Die Original-XMLs boten den Stein aktiv an, während die normalen Lab-Aktionen noch deaktiviert waren. Das spätere Bild zeigte wieder aktive Aktionen, aber keinen bewegten Stein. Tappunkt und verschwundenes Modal wurden unabhängig geprüft. Alle260 Originaldateien und der vollständige Log bleiben unter `evidence/ci-2029-android-bridge-return-failure/` als FAIL erhalten.

Die verschärften Tests mit dem tatsächlichen Flutter-Systemanimationsflag reproduzieren auf unveränderter2029-Quelle eine aktiv angebotene Modelleingabe ohne Aufgabenidentität. Der minimale Fix gibt alle sechs Lab-Modellanschlüsse nur mit gültiger eigener erfasster Coach-Identität frei. Der bestehende spätere Callback-Check bleibt erhalten. Zusätzlich fordert die Rückkehrveröffentlichung ihren Frame ausdrücklich an; eine dauerhafte Frame-Starvation wird nicht als separat reproduziert behauptet.

Der Test beobachtet jeden tatsächlich angeforderten Rückkehrframe und tippt genau einmal im ersten freigegebenen Frame. moved1 muss im Modell und vorhandenen Checkpoint erscheinen; Aufgabe, Sitzung, Phase, Hilfestand, Versuchszähler und Belohnungen bleiben erhalten, alte Rückrufe bleiben abgewiesen.27 gezielte Flutterfälle bestehen, Analyse ohne Befunde. Dieser Nachweis ist noch kein kompletter neuer Root-/Androidlauf.

## Exakte Quellen und Schutz

- Flutter-Repository: `Ullmann27/lumo-lernen`, Branch `integration/lumo-nextgen-learning-20261115`.
- Veröffentlichter Produktcheckpoint/Katalogquelle: `83038afc19365196eeaa49432e0025bba0975518`, Tree `6e84466a5b441076249f3b194aaef9d907be4477`.
- Teamlieferung: Produzent `5f2020a49a4ea9bd935bbd582ef44201e6058ca1`, API-Publikation `a4e73ccf5b7ea0686d941d9160957230a94b93a6`, identischer Tree `c63544ea2271b18555e498f5b360ecabb5d82a7e`.
- Native-Repository: `Ullmann27/lumo-godot`, unveränderter Pin `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`, Godot4.6.3.
- Version `0.13.18+2030`; neuer vorgesehener Tag `lumo-nextgen-learning-0.13.18-2030`.
- Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`; bestehendes Testzertifikat SHA-256 `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Keine Play-Produktionssignierung.
- Tatsächlicher neuer Dart-Katalogexport:1 PASS.248 Quellenhashes geprüft;18 geschützte Schreib-/Journaldateien bytegleich gegenüber `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`.40 Versionspolicy-Fälle bestehen.

Der endgültige Aktivierungscommit und die echte neue Run-ID werden nach ihrer tatsächlichen Entstehung separat protokolliert. Nach dem Katalog-Snapshot werden nur Versions-/Liefermetadaten und Dokumentation geändert; ein weiteres Produktdelta erfordert eine neue Bindung.

## Verpflichtender vollständiger Lieferlauf

Die unveränderten normalen Gates verlangen vollständige aktuelle Flutter-/Host-/Nativeprüfung, tatsächlichen Godotimport, neue ARM64- und x86-APKs mit unabhängiger Artefaktprüfung und anschließend die vollständige originale Androidtour sowie Banane-/Musterreferenzen. Keine zweite automatische Eingabe, kein manipulierter Checkpoint und keine schwächere Bereitschafts-/Ergebnisbedingung ersetzt den fehlgeschlagenen ersten Tap. Die normalen QA-Skripte sind durch diesen Produktfix unverändert.

Der Publisher verlangt weiterhin denselben tatsächlichen QA-/APK-Quellcommit. Ein neues Release/Tag muss fehlen. Erst bestandene vollständige Androidergebnisse gestatten die Erstellung des neuen Prerelease; danach müssen reale Release-/Tag-/Assetmetadaten und der vollständige anonyme APK-Bytehash passen. Die2029-APK oder ihre Ergebnisse werden nicht als2030 ausgegeben.

## Ergänzende Diagnose und verbleibende Grenzen

Ein eigener reiner Diagnosebranch auf `e04e29437e2c28f40e492191f430cd49ddc456fa` verwendet ausschließlich die bereits gebauten2029-Bytes. Banane, Muster und8+5 laufen unabhängig in frischen UI-angelegten Testprofilen, maximal zwei Jobs gleichzeitig. Zwölf Prüfertests und ein unabhängiger Quellreview bestätigen die Bindung und Trennung. Ergebnisstatus bleibt auch bei kompletter Szene `DIAGNOSTIC_ONLY`; `release_eligible=false` und das ursprüngliche Android-FAIL bleiben erhalten. Die eigentlichen Laufbeobachtungen werden separat gesichert. Die Diagnose hat keinen Publisher und ersetzt keine Abnahmetour.

Beim Schreiben dieses Vorlaufdokuments sind noch kein2030-Build, Android-PASS oder öffentlicher Download nachgewiesen. `fullModernizationComplete=false` bleibt zutreffend. Die Inventarzahlen sind keine komplette Prüfung aller Varianten; viele Einstiege nutzen eine gemeinsame native Aufgabenkarte, der Fuchs läuft über die vorhandene separate Godot-Activity. Physische Fold7-/ARM64-Nutzung, tatsächliche gesprochene Erkennung, akustische Qualität, gemessener gemeinsamer Ton-/Mund-/Gestenabbruch, native Langsamer-Wiedergabe, dauerhaft60FPS und vollständige Upgrade-/Prozesstod-Erhaltung benötigen ihre eigenen Belege. Kart- und native Dschungel-Folgearbeiten bleiben außerhalb dieser Runde.

## Tatsächliche Aktivierung2030

Der vollständige Lauf [43790915460](https://github.com/Ullmann27/lumo-lernen/actions/runs/43790915460) wurde am exakten neuen APK-/QA-Quellcommit **c4e330faa61e231dd3fd44c21085c95ddcd5b7c9** gestartet. Der beobachtete Run-Head stimmt mit dem veröffentlichten, lokal per identischem Tree geprüften Stand überein. Native bleibt `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Laufstatus bei diesem Eintrag: **in_progress**; noch kein Gesamt-/Android-/Download-PASS. Aktivierungsbindung: `evidence/2030-build-activation-20261116/activation.json`.

Die getrennte Diagnose [43790709991](https://github.com/Ullmann27/lumo-lernen/actions/runs/43790709991) läuft auf QA `e04e29437e2c28f40e492191f430cd49ddc456fa` mit den bestehenden2029-Bytes. Tatsächlich beobachtet: Banane- und Musterjob sind in ihrer Android-Szenenstufe, Bridge ist gemäß max-parallel2 noch eingereiht. Daraus folgt keine Freigabe für2029 oder2030.
