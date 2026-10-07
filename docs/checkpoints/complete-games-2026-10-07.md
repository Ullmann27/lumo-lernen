# Lumo: vier neue Spiele und vollständiger Lernpfad — 7. Oktober 2026

## Quellstand und Prüfung

Eigener Branch in beiden Repositories: `chatgpt/lumo-complete-games-2026-10-07`.
Flutter-Entwurf: https://github.com/Ullmann27/lumo-lernen/pull/210
Godot-Entwurf: https://github.com/Ullmann27/lumo-godot/pull/23

Die gebaute APK stammt exakt aus Flutter `5be37264a357bb8d2a6dd3171f42f42ed738d476`
mit Godot `9d99fd9b5a0f5383199675ba9213290f5b511f61` / Engine 4.6.3.
Nachfolgende Commits ändern ausschließlich Prüfskripte, CI und Dokumentation.
Der Build begann mit einem frischen Checkout; `tracked_source_clean` ist wahr.
Die Branches enthalten die bisher ungemergten Vorarbeiten; keine Hauptbranch wurde verändert.

Vollständiger Check und APK-Build:
https://github.com/Ullmann27/lumo-lernen/actions/runs/37644572864

- 707 Flutter-Tests bestanden, vier übersprungen, kein Fehler.
- 22 Backend-Tests und fünf Prüfungen zur nativen Vorbereitung bestanden.
- 40.960 Aufgabenvarianten auf Antworten, Optionen und Zahlenbereiche geprüft.
- Repair-Guard bestanden; Analyse ohne Fehler, 151 vorhandene Hinweise/Warnungen bleiben.
- 13 Bilder aus dem tatsächlichen Flutter-Render, kein generierter App-Ersatz.

Godot-Spiel- und Physikprüfung mit 27 echten Runtime-Bildern:
https://github.com/Ullmann27/lumo-godot/actions/runs/37644437370

## Konkretes Verhalten

Alle acht Spiele im Katalog haben spielbare Einträge. Bestehende Voraussetzungen
bleiben erhalten. Die neue Vorschau zeigt Bauwelt, Puzzle, Rhythm Party und
Schatzsuche mit Bildern ihrer tatsächlichen Szenen.

Alle 50 Lernlevel besitzen funktionierende Routen. Der zuvor fehlende Zahlenpfad,
Wörterwald und gemischte Aufgaben nutzen den neuen LessonTrailGame mit Feedback,
Pause, wiederholbaren Erklärungen, optionaler deutscher Sprachausgabe und
persistenten Ergebnissen. Sterne und XP werden gemeinsam gespeichert; ein
fehlgeschlagener Schreibvorgang muss erfolgreich wiederholt werden, bevor das
Ergebnis abgeschlossen wird. Ein sinnvoller UI-Test prüft diesen Fehlerfall
und die einmalige Vergabe beider Belohnungen.

Die einmalige Curriculum-Migration bewahrt bereits verdiente Sterne und zuvor
geöffnete alte Level pro Kind. Neue Profile folgen dem vollständigen Pfad.
Die Tier-Lebensraumfragen erlauben jeweils genau eine korrekte Antwort.

Native Spiele speichern unter einem zufälligen, dauerhaft erzeugten und
gehashten Profil-Schlüssel. Reset räumt nur die passenden kreativen Spielstände
auf, nachdem der Spielprozess beendet ist. Explizite native Sterne/XP werden
validiert und über die vorhandene dauerhafte Ergebnis-/ACK-Transaktion gebucht.
Der Launcher prüft Profil, Route und Generation nach dem Wallet-Flush erneut.

- Bauwelt: 28 Bauteile, 33×33 Grundfläche, Höhe 20, bis 768 Teile, sechs Welten
  pro Kind, Drehung, 64 Rückgängig/Wiederholen-Schritte und echte Kollisions-
  und Stützregeln. Sechs Ziele: Haus, durchgehende Brücke, Turm, Garten, Burg,
  Dorf. Die Startburg hat 161 Teile. Ein Ziel gibt je Kind einmal 3 Sterne/24 XP.
- Puzzle: tatsächliche verzahnte 3D-Teile mit gemeinsam passenden Kanten,
  12/24/48/96 Teile, Originalmotiv-Proportionen, Teileablage mit Seiten,
  Randfilter, Vorlage, Tipp, echtes Auswählen/Ziehen/Einrasten, atomare Spielstände.
- Rhythm Party: drei originale synthetisierte Stücke, vier Bahnen, Tap/Halten/
  Slide/Stern, drei Schwierigkeiten, Combo und gespeicherte Bestwerte. Eine
  ungespielte Runde verdient keine Sterne. Unfertige Lieder beginnen nach
  Prozessende neu; Bestwerte bleiben gespeichert.
- Schatzsuche: sieben Hinweise, tatsächliche Nähe, Antworten und Inventar-
  Voraussetzungen, gesperrte Brücke, Laufen/Springen, Kapitel- und Positions-
  Spielstände. Vollständiger Abschluss gibt 3 Sterne/40 XP.
- Kart: zwölf Welten, davon acht unterschiedliche neue Rundkurse mit 691–803 m.
  Fünf Rampenstrecken, drei optionale physikalische Loopings mit echtem Überkopf-
  Fahren, unzureichender Geschwindigkeit und sicherer Rückkehr. Kamera bleibt
  aufrecht. Rivalen-Warnungen/Schilde bleiben erhalten. Keine Lernfragen im Rennen.

Die Kart-Garage wurde zusätzlich für 1280×720, 800×480 und 640×320 mit
simulierten Display-Rändern geprüft. Fünf echte Touch-Schritte starten den Cup.
Die 3D-Vorschau und Fußleiste bleiben sichtbar; Mindestgrößen werden nicht mehr
von einer älteren Skalierung überschrieben. Die zwölf Welten stehen kompakt in
der Cup-Zusammenfassung, ohne die Ansicht seitlich zu strecken. Safe Insets
werden in der eingebetteten Garage nur einmal angewendet.

Der Übergang aus der Garage ins Rennen berechnet die Fahrsteuerung erneut.
Kurzes Querformat erhält zwei Reihen großer Fahrknöpfe und kurze, einzeilige
Hinweise. Nach Änderung der Mindestgrößen wird die volle HUD-Fläche wieder
an den sicheren Bildschirmbereich gebunden. Dadurch verbleiben keine alten,
vergrößerten Container-Ränder. Zusätzliche echte Tests prüfen alle Fahrknöpfe
nach dem Menüstart und liefern drei weitere Renn-Screenshots. Der Bildlauf
`37644437370` prüft den gleichen Godot-Pin wie APK 1601. Die vollständigen
Beschriftungen werden anhand der wirklichen Schriftbreite und Zeilenhöhe
eingepasst. Der Regressionstest prüft neben den Touch-Flächen jedes ganze Wort
und die mehrzeiligen Texte. Die Begrüßung auf der Startseite erhält ebenfalls
genügend Höhe für vollständigen Text auf dem Telefon.

## Integrierte grafische Verbesserungen

Der geprüfte Grafikstand `36969d8bf87346544ef28a43be2547ce4913c2d3` enthält
den vollständigen Spielstand von Version 1502 sowie drei neue Raster-Assets:
Glas-Insel-Hintergrund, Lumo mit Buch und Lumo mit Karten. Original-Fuchs,
Navy/Cyan-Farbwelt und bisherige Avatar-Identität bleiben erhalten. Lernkacheln
haben lesbare zweispaltige Telefonansichten; Karten- und Rennspiel eigene
grafische Einstiege. Die Lernhilfe steht außerhalb der Inhaltsfläche, sodass
sie Antworten und Startknöpfe nicht mehr überdeckt. Spielstände, Freigaben und
Spiel-Callbacks bleiben erhalten. Die neuen Fuchsposen sind Rastergrafiken.

## Herkunft der Integration

Flutter-Basis: PR207 `b6a0afa421e5e854345bfac5cc2be1813a7c3e50`.
Godot-Basis: PR22 `06d27c33f2273ecd3d32bb863c62303c7e51ad44` mit PR21/PR18.
Übernommen wurden die fest geprüften PR204- und PR206-Stände sowie die begrenzten
Elternoberflächen aus `4abda8dda053d9bf77764669d258c6a9fdfe4a2b`.
Die aktive Puzzle-Lane wurde nicht überschrieben; neue Szenen verwenden `creative`.
Originale Opus-Fuchs-/Fahrzeugbilder und die gelieferten Candy-/Vulkan-Referenzen
bleiben maßgebend. Neue Sandstein-Grafik wurde als originale Grafik generiert;
alle Spielnachweise wurden dagegen von Flutter/Godot/Android aufgenommen.

## Nachgereichte Projektdateien

Die 19 am 7. Oktober bereitgestellten Dateien wurden direkt aus den beigefügten
lokalen Kopien abgeglichen. `_bundle(1).zip` und `_bundle.zip` sind identisch;
die beiden `voice_plus_fluessig`-HTML-Dateien ebenfalls. Die MVP-, Blueprint-,
HTML/PWA- und Implementierungsbericht-Stände sind frühere Grundlagen. Der
Perplexity-Arbeitsauftrag und das Review-Paket dienen weiterhin als Anforderungen
an 3D-Wirkung, Stimme, Fold-Layout, sichere Lernhilfe und echte Eltern-Gutscheine.
Sie ersetzen nicht den inzwischen implementierten Flutter-/Godot-Quellstand.
Eine professionelle Sprecheraufnahme und ein vollständig geriggtes Produktions-
modell sind damit nicht nachträglich als umgesetzt belegt.

## Identität der APK

Datei: `Lumo-Lernen-0.10.9-1601.apk`; 184.668.366 Bytes.
Version: `0.10.9+1601`, Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
SHA-256: `7d7883122fb1f487723d2489c64401a9741ff3edde5cd87f2ab734ddaea5e83d`.
Bestehende Zertifikatsidentität:
`a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
ABIs: arm64-v8a und x86_64; Android minSdk 24 / targetSdk 36.
ELF-16-KiB- und Ressourcen-Ausrichtung geprüft; nicht debuggable.
PCK: 28.253.072 Bytes,
SHA-256 `2786696a58c49847a342cc49b0059630d31eab93c2304daee17193b4397ed614`.

## Android-Nachweis

Vier native Spiele haben auf dem unmittelbar vorangehenden APK 1600
(Flutter `36969d8…`, Godot `148decd…`) bestanden:
https://github.com/Ullmann27/lumo-lernen/actions/runs/37642422225.

- Bauwelt: tatsächliches Hausziel, 3 Sterne/24 XP, gespeicherte Wiederaufnahme,
  erneute Prüfung ohne doppelte Belohnung.
- Puzzle: zwölf Teile, ein echter Tipp, freie/platzierte Teile gespeichert und
  exakt wieder aufgenommen.
- Rhythmus: echtes Lied gestartet, Pause und Rückkehr; keine Belohnung ohne
  abgeschlossene, gespielte Runde.
- Schatzsuche: Inventar, gespeichertes Kapitel und Wiederaufnahme.

Jeder dieser Läufe hat ein wirkliches Profil auf Version 1400 erstellt, dann
mit `adb install -r` ohne Deinstallation oder Datenlöschen aktualisiert, die
gleiche UID/Erstinstallation und das gleiche Profil überprüft und die Spiele
offline gestartet. Auch vollständiger App-Neustart erhält Profil/Belohnungen.

APK 1601 ändert ausschließlich die Startseitenhöhe und Kart-Beschriftungen
sowie Version/Engine-Pin. Die vier kreativen Spielimplementierungen bleiben
identisch zum bestandenen Lauf. Die gezielte APK-1601-Kartprüfung läuft unter
https://github.com/Ullmann27/lumo-lernen/actions/runs/37645581564.
Dieser Durchlauf hat bestanden: echtes Update 1400 → 1601 ohne Löschen,
gleiches Profil/UID/Erstinstallation, Offline-Start, fünf native Menü-Schritte,
Rennen mit tatsächlicher 640×320-Fläche, Pause, Rückkehr in die Flutter-Spielewelt
und abschließender App-Neustart. Kein App-Eintrag im Crash-Puffer.
Die unveränderten Android-Bilder wurden zusätzlich direkt geprüft: alle fünf
Aktionen liegen sichtbar im Bild, die Rückkehr zeigt die App, die Begrüßung
ist vollständig. Kleine farbige Wörter im Kreis sind kein zuverlässiger OCR-
Nachweis; daher werden die tatsächlichen Bilder und die separate Sichtprüfung
beigefügt. Ganze Wortbreite und Zeilenhöhe sind zusätzlich im Engine-Test geprüft.

## Verbleibende Abnahme und Wiederaufnahme

Die Szene ist spielbar, aber noch nicht visuell gegen Heinz' Videos abgenommen.
Candy und Vulkan brauchen weitere Modell-Details, dichtere Umgebung, Licht-
und Animationsarbeit; der dokumentierte Status bleibt VISUAL_GAP. Der erhaltene
Fuchs ist ein animiertes prozedurales Modell, kein verifiziertes Produktions-GLB.
Keine Aussage über physische Samsung/Fold-Geräte oder gemessene 60 FPS.

Bei der nächsten Bearbeitung zuerst die beiden PR-Heads und issue #170 erneut
lesen. Die APK-Quell-SHAs von späteren Test-/Dokumentations-Commits unterscheiden.
Neue sichtbare Grafikstände immer aus der laufenden App fotografieren und dem
Nutzer während der Bearbeitung zeigen. Candy-/Vulkan-Videos und vorhandene
Track-Boards erneut direkt daneben prüfen; kein Austausch des Opus-Stils.
Hauptbranch-Merge und Veröffentlichungen bleiben außerhalb dieses Entwurfs.
