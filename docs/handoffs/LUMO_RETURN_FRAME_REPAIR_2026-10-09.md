# Sichtbare Flutter-Rueckkehr: begrenzte Quellreparatur

Status: DRAFT SOURCE PASS / ANDROID NOT EXECUTED / VISUAL_GAP / NOT FINISHED.
Basis-App: 2b60f28a558c4b2a414b100d73903fa6abb41ce1.
Branch: codex/lumo-return-frame-recovery-2026-10-09; Resultat ist dessen aktueller Git-Head.
Godot-Pin unveraendert: 3f9ff57b15e27b373e4baf696c43af3fa0ef9ca0.
Version unveraendert: 0.12.5+1908. Dieser Entwurf erzeugt keine neue APK-Version.

## Belegtes Problem und Wirkung

In den eigenen vier Nicht-Kart-Artefakten aus Run 37892031317 zeigen die ersten
Build/Puzzle-Dateien mit dem Namen returned-to-app noch das native Pausemenue.
Die ersten Treasure/Rhythm-Rueckkehrbilder sind gedreht. Spaetere echte Neustarts
zeigen auf allen vier Geraeten korrektes Flutter-Home und gespeicherten Fortschritt.
Damit ist ein unmittelbarer Bildnachweis fehlerhaft, kein Produktabsturz bewiesen.

creative.leave bewahrt den bisherigen Input, die 15 PID-Polls und den Check gegen
LumoGameActivity. Danach nutzt es den vorhandenen unveraenderten Flutter-Pruefer:
korrekte MainActivity, kein nativer Prozess, frische XML/PNG-Pfade, vier Host-Texte
in echten Captionpixeln und zwei komplette stabile Host-Frames. Eine pro Rueckkehr
neue Untermappe verhindert alte Aliasdateien. Das letzte gepruefte PNG wird nach
erneuter Hashpruefung unter dem bisherigen Dateinamen veroeffentlicht; eine dritte
ungepruefte Aufnahme entfaellt. UI-Navigation und Spielmechanik sind unveraendert.

## Grenzen und Pruefungen

18 neue Methoden pruefen dieselbe BASE und denselben Kandidaten: BASE hat 14
fehlgeschlagene Assertionzeilen und 5 Fehler innerhalb dieser 18 Methoden;
Kandidat besteht alle 18. Diese Zahlen sind keine 19 zusaetzlichen Tests.
Ganze Kandidatensuiten: 597 Android-QA (579 erhalten +18 neu) und 36 Scripts,
0 Fehler/Skips. Laufzeiten 11.867 beziehungsweise 4.954 Sekunden sind Host-Testzeiten.
Unabhaengiger Peer bestaetigt Byte-/Mode-/AST-Bindung und vorhandene Schutzbedingungen.
Das sind kontrollierte Callback-/Bild-/Fehlerfaelle, keine neue Android-Ausfuehrung.

Die Originalhilfe flutter_return_readiness.py bleibt bytegleich e5e7f4826b1e3a44c93e2d50d0545deec1ab5710d46851781190078e35a08ded.
Der komplette Rennpruefer bleibt bytegleich b25ad91938c5cdab61ff80690017ee1fffd22a0136d720a84a0e3074e4a950e6.
Workflow, Pin, Version, 1200-Sekunden-Vollrennlimit, 45-Minuten-Job sowie alle
Renn-/Resource-/ACK-/Wallet-/Offline-/Fold-Assertions bleiben unveraendert.
Der normale erfolgreiche Rueckkehrnachweis kostet zwei notwendige Host-Aufnahmen
und mindestens acht Caption-OCR-Reads; schnelleres Android wird nicht behauptet.

Eigenes geschlossenes Proof-ZIP: 131872 B, SHA256
899ba22fa0d5952cf977a66ecec8f14daadb5a226292f4283d45c737b9a6089a.
Unabhaengige Reviewdatei: SHA256
f0f1c3119d2beb8a305c691ec94e6898380c0805eecfcdeb29628bd5724ce846.
Git-Quellpaket wird nicht als Konzept-/Runtimebeweis ausgegeben.

## Eigene APK 1908: bestaetigter Stand

Buildjob 113694877999 erfolgreich. App-Quellstand 2b60; Godot/PCK-Pin 3f9.
APK 203796682 B, SHA256 dc71304c38249f3194d1041e936b1bf3e8ed8007e57c37f0d13efa68568b89ed.
Alle 89 eingebetteten kompilierten Skripte stimmen mit unabhaengigem Export
des aktuellen 915-Dateien-Godot-Stands ueberein. 25 erzeugte Szenen stimmen
bei Hierarchie, Geometrie, Materialien und gespeicherten Eigenschaften ueberein;
Knoten-IDs unterscheiden sich, kompletter UID-Cache bleibt unabgeglichen.
Native24/GL17, Profile24 und Finish16 bestanden separat.

Eigene Kartjobs 113700930487/API35 und 113700930543/API36 scheiterten beide am
unveraenderten 1200-Sekunden-Alarm im originalen 5-Sekunden-Driving-Poll, waehrend
die Runtime weiterfuhr. Setup bis Driving 520.729/580.715 s; letzte gespeicherte
Rennzeiten 60.20/50.17 s, Gate12/10. Finish, Ergebnis, ACK, Belohnung und finaler
Offline-Wiedereinstieg wurden in diesen zwei Laeufen NICHT erreicht. Dieser Entwurf
behebt diesen Timeout nicht. Inklusive verschachtelte Hostzeiten ueberlappen;
Restzeit wird nicht als CPU/GPU/FPS interpretiert. Physisches Fold/Zielgeraete: NOT EXECUTED.

## Koordination und naechste Integration

Scopeclaim: nur .github/probes/creative_android_probe.py::leave und neuer zugehoeriger
Test plus diese Uebergabe/OPUS-Praefix. Keine aktive Ref-Verschiebung oder Main-Aenderung.
Parallel PR223/5e5316 auf codex/lumo-action-android-qa-2026-10-09 behebt andere
1909-OCR/screencap-Probleme und wird nicht ueberschrieben. Seine 2400/65-Grenzen
waren bereits im originalen 1909-Workflow vorhanden und gelten nicht als PASS
unseres unveraenderten 1200/45-Vertrags. Action-Kontakt-/Rivalenversuche sind noch
unuebernommene isolierte Varianten. Spaeter selektiv integrieren, dann die eigene
APK erneut in echter Android-Runtime mit sichtbarer Rueckkehr belegen.
