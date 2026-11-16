# Begrenzte Home-Beobachtung und unverdeckter Primärfehler

## Originalbefund

Der tatsächliche 2031-Lauf `43800892196`, Androidjob `133088843594`, scheiterte
nach einmaligem Home-Befehl in der Wortwerkstatt. Die erste unmittelbare
Activity-Prüfung meldete `App did not actually leave the foreground`. Das
Aufnahme-finally ersetzte diesen Fehler anschließend durch
`No decodable actual video was recorded`. Der ursprüngliche Fehler und Status
bleiben im unveränderten Resultat erhalten.

Originalbild 0271 zeigt die Wortwerkstatt mit Ba/na/ne und angehaltener Erklärung;
Originalbild 0272 zeigt später den Android-Launcher. Der frühe abgewiesene
Activity-Dump wurde nicht gesichert. Sein genauer Inhalt wird nicht behauptet.
Die vier kleinen Originalfixtures liegen unter
`tools/android_qa/tests/fixtures/nextgen_foreground_43800892196/`; ihr Manifest
bindet ZIP, Quelle, Run, Job, Größe und SHA-256. Das vollständige Archiv sichert
Root getrennt.

## Enger QA-Fix

Nach demselben einzigen Home-Befehl beobachtet die Probe höchstens 15 Sekunden
frische Activity-Dumps. Jeder vollständige Rückgabewert wird vor Parser und
Bewertung gespeichert. Akzeptiert wird nur eine eindeutig aus den tatsächlichen
ResumedActivity-Feldern gelesene Nicht-App-Komponente innerhalb der Frist.
Leere, unlesbare, widersprüchliche, weiter zur App gehörende oder verspätete
Beobachtungen erfüllen das Gate nicht. Ein zusätzlicher Home-Tap fehlt bewusst.
Rückstart, Profil-/Fortschrittsvergleich und Taskvergleich bleiben erhalten.

`recording` bewahrt eine bereits ausgelöste Body-/Setup-Exception. Ein weiterer
Fehler bei Abschluss oder Videoauswertung wird in `recording_errors` und einem
eigenen JSON samt Fehlerspur gesichert. Ohne Primärfehler bleibt die bisherige
Anforderung unverändert: genau ein Videostream und positive ffprobe-Videodauer.
Die reale Nullzeitaufnahme erfüllt sie weiterhin nicht.

## Tatsächliche lokale Prüfung

Auf der unveränderten Basis `9886f6637589c23cbae23ccca311090c35cdea8e` wurden
sechs neue Testmethoden ausgeführt: RED mit acht fehlgeschlagenen Assertions
(einschließlich Unterfällen) und einer durch die alte Frühprüfung ausgelösten
Exception. `red.log`, `red-provenance.json` und `red-test.py.txt` erhalten diesen
unveränderten Prüferstand. Der Primärfehler-/Videofall verwendet echte Original-
MP4-Bytes und reproduziert genau die Überdeckung.

Die endgültige gemeinsame Gruppe besteht aus sechs neuen Methoden und drei
bestehenden Resize-Prüfungen: **9/9 bestanden**, keine übersprungenen Fälle.
`final-green.log` ist maßgeblich; überlappende Zwischenläufe werden nicht addiert.
Der erste lokale Nachlauf hatte ausschließlich einen neuen Test-KeyError:
lokales ffprobe lässt bei diesem Nullzeitvideo `format.duration` weg. Der Test
verwendet nun dieselbe vorhandene `get(..., 0)`-Semantik wie das unveränderte
Videogate. Das ursprüngliche Zwischenprotokoll bleibt separat erhalten.

Die Home-Abläufe sind kontrollierte Zeit-/Transportpläne, keine neu beobachtete
Androidtransition. Produktcode, APK-Bytes, Quell-/Signatur-/Installationsgates,
Lerndaten und der ursprüngliche Android-FAIL werden nicht verändert. Kein
Remoteaufruf, CI-Start oder Release erfolgt durch diesen Patch.
