# Android-APK-Abschluss – 4. Oktober 2026

## Status

**Der vollständige Android-Nutzungstest ist noch nicht als bestanden bestätigt. Build 280 bleibt bis dahin ein Prüfkandidat.**

Projekt: `Ullmann27/lumo-lernen`, PR #156, Zweig `codex/lumo-unified-android-2026-10-03`.

Aktueller Gesamtlauf: `37172929269`, Job `111349433409`, QA-Commit `74113f56b41582cbfc341943e27d7b2c49d8364a`.
Die vorangestellten Android-Testhelfer, Download- und Signaturprüfung sind in diesem Lauf bestanden. Der eigentliche Android-Nutzungstest läuft noch. Ein fertiger Gesamtnachweis darf erst nach Prüfung seiner Originaldateien eingetragen werden.

## Eingefrorene APK

Entwurf `unified-build-280`; Version 0.10.5, Build 280.

SHA-256: `3c01ba849139583be0b41ef2195e67f68373ebb18d720ce2d1ad1bd638523f48`.

Die App-Quellen, APK-Bytes, Signatur und Spielstände wurden bei dieser Fortsetzung nicht verändert. Die Änderungen betreffen die Android-Prüfung und die nachvollziehbare Dateiübertragung. Kein Release wurde veröffentlicht und PR #156 wurde nicht zusammengeführt.

## Verifiziert behobene Prüfprobleme

Die Emulatorprüfung erkennt jetzt das tatsächliche `/proc/PID/exe`-Ziel. Bei `-no-window` wird ausdrücklich das separat verpackte `qemu-system-x86_64-headless` geprüft, einschließlich dessen Bibliotheksabhängigkeiten. Es muss weiterhin genau ein passender Prozess existieren; falsche und doppelte Prozesse werden abgewiesen. Das Original-Proof des Laufs `37171778921` bestätigt diese Prüfung mit `passed: true`.

Im selben Lauf endete die Original-Nutzungsprüfung bei der Erkennung des Kart-Lernfragenwechsels. Der Rohbericht nennt `Später touch did not close the real learning pause`. Die Bilder zeigen zunächst `7 − 2 = ?`, später `3 − 3 = ?` und eine veränderte Rennposition. Die Texterkennung lieferte daneben die fehlerhaften Varianten `7-22?` und `3-35?`.

Der bisherige Parser behandelte die fehlerhaften Lesarten ohne Gleichheitszeichen wie eine gleichwertige vollständige Frage. Außerdem versuchte der Später-Zweig, die vorherige Frage erneut aus einem bereits gescheiterten Antwort-Matcher zu gewinnen. Der Nachweis eines Fragenwechsels konnte damit fehlen, obwohl die Bildschirmfolge einen Wechsel zeigt.

Die Korrektur bevorzugt vollständige beobachtete Fragen mit `= ?` gegenüber der toleranten Ersatzlesart ohne Gleichheitszeichen, behält aber widersprüchliche gleichwertige Lesarten als Fehler bei. Die Frage wird unabhängig vom lesbaren Antwortknopf identifiziert; gleiche Fragen mit anderer Leerzeichen- oder Minusdarstellung zählen nicht als Wechsel. Korrekte Antworten erfordern weiterhin den tatsächlich erkannten passenden Antwortknopf. Die vollständigen Rennen, Speicherprüfungen, Fehlerlog-Prüfungen und übrigen Nutzungsanforderungen werden nicht übersprungen.

Geänderter Kart-Helfer: Commit `ae3810ac47dc906d89cd1fadfc1e0e6ad67facb1`, Git-Blob `a036db4f937a6573925c84e348138755481171e6`. Die Übernahme war auf den exakten vorherigen Blob `62394336829476558ffcf8174263ca5ef291ca56` und diesen nach lokalem Test festgelegten Ergebnis-Blob begrenzt. Der Übernahmelauf `37172812444` hat zuvor die Android-Helfertests ausgeführt und erfolgreich abgeschlossen.

## Tatsächlich ausgeführte lokale Prüfungen

78 gezielte Tests bestanden: 26 Emulatorprüfungen, 45 Kartprüfungen einschließlich 12 neuer Fragenidentitätsregressionen und 7 Übertragungsprüfungen. Vier Originalbilder wurden mit ihren bereits gespeicherten OCR-Tabellen erneut ausgewertet, ohne eine neue OCR-Abfrage oder Android-Eingabe. Die ursprünglichen Falschlesarten wurden damit reproduziert und die Korrektur an denselben Rohdaten geprüft.

Ein lokaler Lauf der damals vorhandenen 137 Helfertests hatte zwei Fehler, weil in der ausschließlich übertragenen Helferkopie die Flutter-App-Quelldateien fehlten. Dieser Lauf wird nicht als vollständig bestanden angegeben. Die gezielten 78 Tests liefen ohne diese fehlenden Dateien erfolgreich; im Repository-Runner ist die vollständige Quelldateistruktur vorhanden.

Frühere Flutter-, Backend- und Lerninhalts-Testzahlen wurden bei dieser Fortsetzung nicht neu ausgeführt.

## Maßgebliche Rohdaten und Korrektur der ersten Diagnose

Der heruntergeladene Originaltransfer `Lumo-Android-Aktuelle-Diagnose.zip` hat SHA-256 `2393e55c245675994d15d8b52d759b5b03817b1f2ca7265868137c91687c5b9c`. Sein verschachteltes Proof `android-api35-qa-37171778921-1.zip` enthält 161 Einträge. `result.json` meldet `passed: false`; es enthält keine freigegebene APK.

Die zuvor angezeigte Protokollansicht hatte einen Fehler `Can't create ViewModelProvider for detached fragment` und weiter fortgeschrittene Prüfschritte genannt. Diese Darstellung wird durch die heruntergeladenen Originaldateien dieses Laufs nicht bestätigt. Sie ist deshalb nicht Grundlage einer Änderung an der Godot-/Android-Activity. Maßgeblich sind die geprüften Originaldateien und Screenshots; entsprechend wurde die erste Diagnose korrigiert.

## Übergabegrenze

Der Übertragungsweg bis zu einer tatsächlich herunterladbaren Chat-Datei wurde geprüft. Eine finale APK darf dieser Weg nur übernehmen, wenn Gesamtlauf, Laufnummer, QA-Commit, Original-Proof, erfolgreicher Nutzungstest, erneuter APK-Download und SHA-256 zusammenpassen. Fehlgeschlagene Prüfungen exportieren nur Diagnoseunterlagen. Die zusätzliche lokale Verpackungsprüfung hat einen solchen fehlgeschlagenen Transfer ohne APK-Ausgabe abgewiesen.

Noch nicht nachgewiesen: vollständiger aktueller Memory-/Kartenspiel-/Offline-/Fold-Nutzungstest, physisches Samsung-Gerät, ein vollständig neuer 3D-Fuchs oder die endgültige gewünschte Premium-Grafik. Diese Punkte werden durch die Reparatur der Testwerkzeuge nicht als erledigt ausgegeben.
