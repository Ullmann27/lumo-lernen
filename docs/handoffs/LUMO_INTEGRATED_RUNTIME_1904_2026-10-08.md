# Lumo-Kandidat 1904 · kontrollierte Fortsetzung nach echten Android-Fehlern

Status vor der neuen Abnahme: **VISUAL_GAP / NOT FINISHED**. Diese Datei dokumentiert
ein überprüfbares Folgepaket. Eine gebaute oder bestandene APK1904 wird erst mit
ihrem tatsächlichen Buildlauf, ihren Bytes und den neuen Laufzeitbelegen bestätigt.

## Tatsächliche Basis

- App-BASE: `3e1d0eb3c08cb2472b12f08eeae11bb663af62c0`.
- Godot-BASE: `18238d48f96b76c4175b705a9bf05e82e339bdd0`, Engine 4.6.3.
- Neuer exakter Godot-Pin: `6873c0723d6e6c0587cdf06d990cb6c49502a33a`.
  Tree `112f4c89204f76796c9b52edcfc822f4f8580aeb`; vier Dateien, davon
  sieben Produktzeilen, eine neue echte Touchprobe und zwei Übergabedateien.
- APK1903 wurde in Actions `37817947080` gebaut: 201683678 Bytes,
  SHA256 `d7da83efaefe41d4cff9438c41b916bf1d419549d94a11a603690b5eedde0896`.
- Der tatsächliche PCK hat SHA256
  `de83652add51e1bf18f03c1e989dad9327dcd4fe4490d3d23b0568309f0ce140`;
  864 Mitglied-MD5s und 14 ELF-Bibliotheken wurden unabhängig geprüft.
- Bauen, Puzzle, Rhythmus und Schatzsuche API35 bestanden. Beide Kart-Läufe
  scheiterten. Diese Fehler werden durch spätere Erfolge nicht umetikettiert.

## Beobachtetes Problem und Versuch

API36 zeigt im Pausemenü vier tatsächlich gesendete Gesten
`[912,559 → 912,322]`, jeweils auf dem sichtbaren Button „Ton: an“.
Die Originalbilder und der Scrollbalken bleiben unverändert; die Gas-Einstellung
wird nicht sichtbar. Der Test hat deshalb weder Gas umgeschaltet noch ein Rennen
oder Ergebnis erfolgreich gemeldet. Ein separater echter GL-Frontend-Versuch
mit Touchscreen-Emulation reproduziert auf unverändertem Godot-BASE:
Button-Drag 0→0, Drag auf freiem Padding 0→166/165.

Der kleine Produktversuch erlaubt Touch-Weitergabe ausschließlich bei Buttons
im scrollbaren Modalinhalt. Normale Taps müssen einmal wirken, Scrollgesten
dürfen keine Aktion auslösen. Slider, feste Navigation und Rennsteuerung müssen
weiterhin korrekt reagieren. Der strikte neue Test verlangt echte Eingaben und
Renderbilder; eine direkte Zuweisung des Scrollwerts ist kein Drag-Nachweis.

Verwerfen, wenn Drags versehentlich Einstellungen ändern, Taps verloren gehen,
Eingaben hinter dem Modal ankommen oder die tatsächliche Android-Wiederholung
den Nutzen nicht bestätigt. Der vorherige Godot-Stand und die APK1903 bleiben
erhalten. Emulationsflags gehören ausschließlich zur Testfixture.

API35 scheitert bereits beim ersten Fullrace-`adb get-serialno` mit
`error: device offline`, unmittelbar nach bestandenem Creative-Probe. Die
getrennte QA-Reparatur darf nur diesen exakt beobachteten Fehler anhand der
vorher tatsächlich geprüften Emulatoridentität begrenzt überbrücken. Ein
fremdes, zusätzliches oder unklar identifiziertes Gerät bleibt ein Fehler.
Keine Installation, Rücksetzung oder Änderung von Spielzustand/Belohnung
ersetzt die erforderliche UID0-/Boot1-/APK-Byteprüfung.

## Erforderliche neue Abnahme

Unveränderter BASE muss den echten Touchfehler strikt reproduzieren; der neue
Pin muss denselben Test und bestehende Pause-, Countdown-, Mehrfinger- und
Spielablaufprüfungen bestehen. Die Buildpipeline verlangt 21 strikte native
Prüfungen des exakten Pins. App-Tests und der saubere APK-Quellcheckout bleiben
unverändert verpflichtend.

Der finale native A/B-Versuch ist ausgeführt: identische Probe SHA256
`41db7836226d254732f9338d1afb1df4f6c5698c619ce56b2883742b03c63a5c`;
BASE Exit1/echter Drag 0→0, Kandidat Exit0/35 Prüfungen/sechs Drags/14 PNGs.
Ein unabhängiger echter GL-Vergleich bestätigt normale Ton-Taps jeweils genau
einmal, auch direkt nach Scrollbewegung und nach beobachtetem Stillstand.
Die QA-Frühprüfung ist als `fa2da691741a817f087484986c57be05acf351f1`
mit drei QA-Dateien separat erhalten: 288 lokale Guards/0 SKIP, unabhängig
bestätigt; die 23 Root-Guards sind darin enthalten. Das belegt keine neue
Android-Ausführung oder APK.

Die neue Android-Abnahme braucht zwei tatsächliche Runden, 16 geordnete Gates,
ein sichtbares Ergebnis, Host-ACK, genau einmal verarbeitete Belohnung,
Offline-Wiederaufnahme sowie Rückkehr zur Lern-App. Originalbilder und
unveränderte Videoabschnitte müssen an die tatsächlich installierten APK-Bytes
und den separaten QA-Quellstand gebunden werden.

Produktionsmodelle, Fell-/Stoffwirkung, vollständige Referenztreue, akustische
Abnahme, physisches Fold und Geräteprofiling bleiben offen. Die YouTube-Referenz
lieferte bislang keine dekodierten Frames; zeitliche Referenzgleichheit ist
**NOT EXECUTED**. Emulator- und Software-GL-Prüfungen belegen keine physischen
GPU-Framezeiten und keine 60 FPS. Main, fremde Claims und Releases bleiben
außerhalb dieses Pakets.
