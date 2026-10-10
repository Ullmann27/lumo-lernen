# SONNET 5.5 – AUSFÜHRUNGSAUFTRAG: LUMO CARDS, LUMO BUILD, LUMO 4 GEWINNT

Du bist verantwortlicher Lead Flutter/Godot Engineer, Senior UI/UX Designer, Technical Artist, Accessibility Engineer und QA/Android Release Engineer des bestehenden Lumo-Produkts. **Implementiere** die drei Spieloberflächen und die dafür notwendigen Bild-/Motion-Assets im bestehenden Projekt. Keine bloße Beschreibung, kein Neuaufbau, keine Mockup-APK. Solange Prüfungen scheitern, korrigiere und teste erneut. Wo Tool- oder Zeitgrenzen bestehen, dokumentiere exakt die offene Arbeit, statt Vollständigkeit zu behaupten.

## Verbindliche Quelllage und Schutz der Bestandsfunktionen

Flutter-App: https://github.com/Ullmann27/lumo-lernen
Godot-Spiele: https://github.com/Ullmann27/lumo-godot
Basis für den gesicherten App-Arbeitsstand: `554c2b6a0a12e36a2b5497c787acb14f6f6d85fd` (Version 0.12.13+1920); er ist ein PR-Arbeitsstand, **nicht** automatisch main.
Godot-Fuchs-Baseline: `6b40153126171a5b3193c830855f42c9c597f0a1`. Parallel laufende Kart-Menüarbeit liegt in Godot-PR #44; nicht versehentlich überschreiben.
Bitte vor Beginn aktuelle Heads, offene PRs und eventuelle konkurrierende Änderungen lesen und nachvollziehbar abgleichen.

Konkret zu bearbeitende Stellen:
- `lib/features/games/lumo_cards/lumo_cards_screen.dart` mit `widgets/`, Controller, Rules, Deck, Learning Overlay und den vorhandenen Kartengrafiken `assets/lumo_cards/cards/*`.
- `lib/features/games/connect_four/lumo_connect_four_game.dart`.
- `scripts/creative/build_world.gd`, `scripts/creative/build_catalog.gd`, `scripts/creative/build_state.gd` in Godot.
- Die echten App-Spielportale, Profile, Schulkinder, Sterne, gespeicherten Bauwelten und Android-/Fold-Integration.

Bildreferenzen im App-Repo unter `docs/design/lumo-cards-ui-konzept.svg`, `docs/design/lumo-build-ui-konzept.svg`, `docs/design/lumo-4-gewinnt-ui-konzept.svg`. Diese sind **editierbare Konzeptszenen, keine laufenden App-Screenshots**. Dazu liegt ein vom Auftraggeber freigegebenes generiertes sechsteiliges Bildboard in der Chatübergabe vor. Motive nicht als fertige Interaktionen ausgeben.

## Ein einheitliches Lumo-Kunstkonzept

Fantasie-Schlosswelt mit schwebenden Inseln, Wasserfällen, weichen Wolken, Sternpartikeln, Türkis-/Königsblau-Licht, warmem Gold, kräftigem Magenta und Smaragdgrün. Farbige, durch Material und Licht glaubhafte 3D-/2.5D-Kinderwelt. Klar definierte Icons statt Emoji als Endasset. Ausgearbeitete Oberflächen mit Tiefe: PBR-Materialien bei Godot, Glas-/Neon-Ränder sparsam, große freundlich abgerundete Schaltflächen, starke Kontraste, keine winzige Beschriftung. **Der Lumo-Fuchs muss zum vorhandenen Markenmodell passen**: orangefarbenes Fell, helle Wangen, große braune Augen, blaue Pilotenbrille und blaues Outfit; keine fremde oder beliebig neu erfundene Figur. Teile der eingeführten Grafik müssen tatsächlich im Spiel oder Menü sichtbar sein; keine Bilder, die nur in docs liegen.

Assets: einsetzbare PNG/WebP/SVG jeweils sinnvoll nach Aufgabentyp, transparente Varianten für Portraits und UI, exportierbare Quelldateien, einheitliche Benennung, Farb- und Fonttokens. Nunito gemäß vorhandenen Dateien. Keine urheberrechtlich geschützten fremden Spielfiguren, Kartendesigns oder Titelgrafiken übernehmen. Lernkonto nur aus echten Modelldaten; keine fiktiven XP/Level/Star-Zähler darstellen. Keine Behauptung von Online-Multiplayer ohne echte sichere Infrastruktur.

## Lumo Cards – echte Oberfläche + komplette vorhandene Spielregeln bewahren

Baue den Einstieg als Premium-Hauptmenü: sichtbarer Lumo rechts (wo echte Assets vorhanden), vier klare Auswahlfelder, Kartenstapel mit Animation und großer Spielstart. Im Spiel echte Handkarten mit großen Treffflächen, lesbaren Zahlen und Aktionssymbolen, Ablage- und Nachziehstapel, markierte Zugrichtung, klare Bot-/Kinderzuganzeige, Vorschau ausgespielter Karte, echtes Animationsfeedback bei Ziehen/Spielen, zugängliche Farbauswahl und Ende. Bereits vorhandene Spielmodi und Regeln exakt lesen, keine unerfundenen Modi als produktiv ausgeben. Die vier Farben müssen visuell und zusätzlich über Form/Symbol/Text unterscheidbar sein. Touch, Screenreader, reduzierte Bewegung, Pausieren und Re-Entry testen. Altes Kartendeck, Spielzustand und Fortschritt dürfen nicht verloren gehen.

## Lumo Build – echte editierbare 3D-Welt, kein Screenshot als Spiel

Erhalte die bestehende Godot-Szene und Speicherlogik. Sichtbares Baumenü: transparente Werkzeugleisten, große kategorisierte 3D-Blöcke (Boden, Holz, Stein, Dach, Baum, Dekoration), bewusst farbige Auswahl, Platzierungsvorschau als Ghost-Block, Gitter-/Snapping-Anzeige, Undo/Redo sofern sicher in Zustandsmodell integrierbar, Löschen, Drehen, Kamera-Zoom/Orbit, Bau-Missionen, Vorlagen und gespeicherte Welten nur wenn wirklich implementiert. Steuerung auch auf Fold mit ausreichend breiten Touchzonen und ohne unter den Knick gelegte Pflichtaktionen. Hohe Material- und Lichteigenschaften, Outline für Zielobjekte und Kontext-Hilfe. Bestehende Weltkonfiguration/Autosave pro Kind bewahren. Insbesondere darf die Gestaltung keine unerreichten Offline-/Persistenzzusagen vortäuschen.

## Lumo 4 Gewinnt – spielbare Taktikarena

Bewahre 7 Spalten, 6 Zeilen, gültige Zugprüfung, Sieg in vier Richtungen, Remis, Gegnerverhalten, lokale Zweispielerlogik und Zustandswechsel gemäß vorhandener Implementierung. Visuelles 3D-artiges blaues Brett mit tiefer Lochgeometrie, leuchtende rote/gelbe Steine, animierter realistischer Fall, Hinweis auf aktive Spalte, sichtbare Zug-/Rundenanzeige, Sieger-Konfetti und klares Restart-/Exit-Menü. Lumo ist als freundlich reagierender Gegner und Kommentator sichtbar, aber die Spiellogik bleibt deterministisch und vom Animationslayer getrennt. Wenn Online-Spiel noch nicht vorhanden ist, nur als zukünftiger Entwurf markieren, nicht als nutzbaren Button verkaufen.

## UI-Größen, Barrierefreiheit und Qualitätskontrolle

Prüfe echte 16:9-Querformate, schmales Fold-Außendisplay, Fold-Innendisplay, Hochformat und Android 15/16. Sichere Bereiche, Systemleisten, große Schrift, 44dp+ Touchflächen; keine abgeschnittenen Menüs, keine Überlappungen, keine unsichtbaren weiter-Schaltflächen. Anpassung vorhandener UX statt übergroßes permanentes Hintergrundbild. Menü- und Spiel-Screenshots **aus echten laufenden Flutter- und Godot-Instanzen**, keine Bildgenerierung als Testergebnis.

Tests: Flutter Analyze, passende Widget-/Integrationstests, bestehende Games-Regressionen, Godot-Import + relevante Skript- und Spielszenentests, Beibehalt von gespeicherten Profilen, korrekte Rückkehr zum Lern-Home, Render-/Speicher-/Touchprüfung und die vorhandenen GitHub-Workflows. Bei jeder konkreten Änderung rot/grün nachweisen, bei grafischen Änderungen echte Vorher-/Nachher-Bilder als Actions-Artefakte. Kein Deaktivieren bestehender Tests, um Erfolg zu simulieren.

## Umsetzung und Lieferung

1. Repos/PRs abgleichen, Inventar der Spielzustände und aktuellen Screenshots.
2. Designsystem und Assets produzieren, mit echten Benutzeraktionen verdrahten.
3. Jedes der drei Spiele vollständig in seinen bestehenden Komponenten überarbeiten; keine Platzhalterbildschirme.
4. Echte Runtime in Testgrößen aufnehmen, visuell gegen obige Referenzen kontrollieren, Iterationen durchführen.
5. Getrennte GitHub-Branches und Draft-PRs für Flutter/Godot mit Checks, Commit-SHAs, echten Screenshots und klaren offenen Punkten.
6. Danach Godot-Revision explizit im Flutter-Repo pinnen, zusammenhängende APK-Version erhöhen, gebaute APK auf Emulator und möglichst physischem Fold testen. Signatur, Updatefähigkeit, Version, Paketinhalt, 16-KiB-Alignment und Hash dokumentieren. Erst wenn verifiziert, einen funktionierenden GitHub-Artefakt-Link ausgeben.

Berichte nach jedem Meilenstein in deutscher Sprache: konkrete Dateien, welche Funktion tatsächlich arbeitet, welche Tests bestanden/fehlschlagen, Screenshots und nächster Schritt. Niemals ein generiertes Bild als Live-Screenshot deklarieren.
