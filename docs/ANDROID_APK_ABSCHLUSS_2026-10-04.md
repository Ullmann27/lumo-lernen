# Android-APK-Abschluss – 4. Oktober 2026

## Aktueller Status

**Build 280 ist weiterhin ein Prüfkandidat. Ein bestandener Android-Gesamttest wird hier noch nicht behauptet.**

Fortsetzung von PR #156 auf `codex/lumo-unified-android-2026-10-03`.
Es wurden ausschließlich das Android-Testwerkzeug, dessen Regressionstests und der gezielte Testaufruf geändert. Die App-Quellen, das APK, seine Signatur und seine gespeicherten Spielstände wurden nicht verändert.

## Behobene Schwachstelle

Der vorherige Lauf `37134817518` scheiterte vor dem eigentlichen App-Nutzungstest am Gate `Running QEMU process does not uniquely match the verified pinned emulator`.

Der alte Matcher berücksichtigte nur Prozesse mit einem `comm`-Namen beginnend mit `qemu-system`. Der korrigierte Matcher erkennt zusätzlich das tatsächliche `/proc/PID/exe`-Ziel. Ein umbenannter Hauptthread wird dadurch nicht übersehen. Es muss weiterhin genau ein Kandidat existieren und dessen tatsächliche ausführbare Datei exakt dem geprüften, gepinnten QEMU entsprechen. Falsche Dateien, fehlende Prozesse und mehrere Kandidaten bleiben Fehler. Auch ein fehlgeschlagenes Gate gibt seinen JSON-Nachweis jetzt in das Jobprotokoll aus.

Die Änderung behebt eine reproduzierte Schwachstelle. Der konkrete Prozessname des vorherigen CI-Abbruchs wurde nicht aus seinem Roh-Proof ermittelt; die Ursache dieses einzelnen Laufs wird daher nicht allein aus der Simulation als abschließend bewiesen bezeichnet.

## Tatsächlich ausgeführte lokale Prüfungen

- 12 unveränderte bestehende Diagnostiktests bestanden.
- 7 neue Identitätsregressionen bestanden: umbenannter Hauptthread, falsches gleichnamiges Programm in anderem SDK, zwei Prozesse derselben Datei, zweiter anders benannter QEMU, unabhängiger ADB-Prozess, vorgetäuschter QEMU-Threadname und verschwundener Prozess.
- Insgesamt **19 Tests bestanden**, keine Fehler; Python-Kompilierung ebenfalls erfolgreich.
- Identische synthetische Prozessdaten gegen beide Quellstände: alter Matcher lehnt den umbenannten, korrekten Prozess ab; neuer Matcher akzeptiert ihn. Die lokale Kopie des alten bzw. neuen Moduls wurde mit den Git-Blob-SHAs `9d81efeb984ac81b18d60e3d7a60a97b1b5ad830` bzw. `bc8ceae01f8a26cbde2ab3776c59649444d80dba` abgeglichen.

Dies sind gezielte Tests des Prüfwerkzeugs, keine vollständigen App-, Emulator- oder physischen Handytests. Frühere Flutter-, Backend- und Lerninhaltszahlen wurden bei dieser Fortsetzung nicht neu ausgeführt.

## Echter Android-Neulauf

Workflow: `Check unified Android APK in KVM`

Run: `37171368395`; Job: `111344809557`.

Getesteter QA-Stand: `6940f9453c9381b5f995b51af0e3c65138e5e851`.

Eingefrorener Entwurf: `unified-build-280` (Release `402540673`).

APK-SHA-256: `3c01ba849139583be0b41ef2195e67f68373ebb18d720ce2d1ad1bd638523f48`.

Der Lauf wurde tatsächlich per eng begrenztem Push-Auslöser gestartet: ausschließlich dieser Fortsetzungszweig, ausschließlich Änderungen der Workflowdatei, zusätzlich explizite Commitmarkierung `[lumo-qa-280]`. Manuelle Dispatch-Eingaben bleiben unverändert; der Wiederholungsaufruf verwendet ausschließlich Download-Modus und die oben festgelegten Bytes, keinen Neubau. Es wurden keine zusätzlichen Tokenberechtigungen eingerichtet.

Die 19 Regressionen werden zusätzlich auf dem CI-Runner vor dem Android-Test ausgeführt. Das bisherige vollständige Nutzungsskript bleibt unverändert. Nur ein erfolgreicher Gesamtlauf darf dieselben Bytes als `Lumo-Lernen-Neu.apk` in den bestehenden, unveröffentlichten Entwurf übernehmen. APK-Download, Signatur, Nutzungstest und erneuter Download müssen zusammenpassen. Kein automatisches Veröffentlichen und kein Überschreiben eines APK.

## Noch abzuschließen

Ergebnis des genannten Android-Laufs prüfen, insbesondere komplettes Memory, Kartenspiel, emulierte Fold-Größen und Offline-Neustart. Bei Fehlern den tatsächlichen Nachweis auswerten; keine Gates überspringen. Dieser Bericht ist erst nach Prüfung des tatsächlichen Endergebnisses zu aktualisieren. Ein 3D-Fuchs, endgültige Wunschgrafik und physische Samsung-Tests sind durch diesen QA-Schritt nicht nachgewiesen.
