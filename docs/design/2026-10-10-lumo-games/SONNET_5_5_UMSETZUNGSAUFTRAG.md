# Ausführungsauftrag für Claude Sonnet 5.5 – Lumo: bestehendes Design bewahren und Spiele verbessern

**DIES IST EIN IMPLEMENTIERUNGS- UND QUALITÄTSSICHERUNGSAUFTRAG, KEIN NEUENTWURF DER LERN-APP.**

Du arbeitest als Principal Flutter-Engineer, Godot-4.6.3-Entwickler, Senior UI/UX-Director, Technical Artist, Game Designer, QA-/Android-Release-Engineer am bestehenden Projekt **Lumo Lernen** von Ullmann27.

## Unverrückbare Designvorgabe

**Die Gestaltung in den vom Auftraggeber bereitgestellten Screenshots muss erhalten bleiben.** Betrachte die Bilddateien `50666.gif`, `50610.png`, `50608.png`, `50609.png`, `50607.png`, `50632.jpg`, `50294.png`, `50297.png`, `50288.png` und `50502.png` als **verbindliche visuelle Richtlinie**. Bitte fordere das Referenz-ZIP an, falls du diese Bilder nicht direkt siehst. Lies zwingend `docs/design/2026-10-10-lumo-games/DESIGN_BESTANDSSCHUTZ.md` vor jeder Änderung.

Das bestehende LUMO-Branding, der orange-weiße Fuchs mit blauer Fliegerbrille, die dunkelblaue magische Schwebewelt mit Schlössern, Wasserfällen und Lichtbrücken, die cyanfarbenen Glaspanels, goldenen Sterne, Lernpfade, das bestehende Lernmenü, Aufgabendesign, Belohnungs- und Profilansichten dürfen **nicht** ersetzt, vereinfacht, gelöscht oder grundlegend umgestaltet werden. Neue Ideen ergänzen genau diese Bildsprache; sie sind kein Freibrief für einen grafischen Neustart. Die drei einfachen SVG-Dateien unter `docs/design/2026-10-10-lumo-games/` sind nur **schematische Anordnungsentwürfe** und dürfen keinesfalls anstelle der vorhandenen Markenassets als fertige UI verwendet werden.

## Technischer Ausgangsstand – VORHER selbst verifizieren

- Flutter/Android und Lernen: `https://github.com/Ullmann27/lumo-lernen`.
- Godot-Kart, Bauwelt, 3D-Assets: `https://github.com/Ullmann27/lumo-godot`.
- Stand 10.10.2026: App-Arbeitszweig `codex/lumo-kart-menu-1921-2026-10-10` (Entwurf PR #246), letzte freigegebene gemeinsame APK Build 1920. Ein neuer 1921-Build ist nicht automatisch abgenommen.
- Godot-Menü-Richtungsarbeit: `codex/lumo-kart-reference-final-2026-10-10` (PR #45); visueller Screenshot-Test für Fold und 1280×720 vorhanden.
- Die Lern-App selbst ist vorrangig: Keine Änderungen daran ohne klaren funktionalen Grund.
- Erhalte die im Android-Paket bestehende Flutter-Godot-Integration sowie alle freigeschalteten Spielmodi und Lern-/Profildaten.

## A. Lumo Cards – Bestehendes Flutter-Spiel verbessern, nicht ersetzen

Beginne mit der Ist-Aufnahme und der tatsächlichen Struktur:
`lib/features/games/lumo_cards/lumo_cards_screen.dart`, `lumo_cards_game_controller.dart`, `lumo_cards_rules.dart`, `widgets/lumo_card_table.dart`, `widgets/lumo_player_hand.dart`, `widgets/lumo_discard_pile.dart`, `widgets/lumo_draw_pile.dart` sowie `assets/lumo_cards/` und `assets/lumo_design/cards_game/`.

Ziel: hochqualitativer, präzise bedienbarer Kinder-Spielbildschirm in **derselben** leuchtenden Lumo-Schwebewelt. Erhalte die vorhandenen echten Spielkarten, Avatare, Farben, Bot-/Zweispielermodus, Lernfragen, Punkte, Klang- und Animationseffekte sowie Regeln. Verbessere schrittweise Lesbarkeit, Licht, Kartenmaterial, räumliche Tischdarstellung, Kartenflug, Ziehen/Ablegen, Auswahlanimation, Zuganzeige, Farbwahl und Lumo-Reaktionen. Karten müssen tatsächlich spielbar bleiben; keine gezeichneten Fake-Handkarten im Hintergrund. Nutze bestehende PNG-Assets, respektiere `reduceMotion` und Touch-/Semantikgrenzen. Teste `+2`, Richtungswechsel, Aussetzen, Farbwahl, Sieg, App-Pause, Neustart und zwei Spieler.

## B. Lumo Bauwelt/Build – Bestehendes Godot-Spiel weiterentwickeln

Beginne bei `scripts/creative/build_world.gd`, `scripts/creative/build_state.gd`, `scripts/creative/build_catalog.gd`, `scenes/creative/build_world.tscn` und der bereits vorhandenen Flutter-Godot-Hostintegration.

Ziel: räumlich glaubhafte, freundliche Bauwelt mit schwebenden Inseln, hochwertigem Spielzeug-/3D-Material, subtiler Rasterplatzierung, animiertem Lumo als Begleiter sowie kindgerecht großen Werkzeugbuttons. Die Bedienung muss reale Bausteine/Brücken/Dach-/Dekoelemente erzeugen und ihre Position speichern. Ergänze gezielt Schatten, plastisches Licht, Placement-Ghost, Snapping, Rotieren, Undo/Redo und klare Rückmeldung, **soweit die Mechanik tatsächlich anschließbar ist**. Keine fiktiven Buttons. Die bestehende Lern-App und vorhandene Bauzustände bleiben unangetastet. Prüfe Spielstart, Bauteilwahl, Platzieren, Rückgängig, Speichern/Laden, Exit/Resume, Fold-Layout, Leistungsprofil.

## C. Lumo 4 Gewinnt – Bestehendes Flutter-Spiel visuell aufwerten

Beginne mit `lib/features/games/connect_four/lumo_connect_four_game.dart`. Erhalte das korrekte **7-Spalten-/6-Reihen-Spielfeld**, vier in Reihe horizontal/vertikal/diagonal, Botlogik, Spielerwechsel, Sperren während der Botanimation, Sieg-/Remisabwicklung und bestehenden Dialog. Ergänze gegebenenfalls animierte, plastische cyan- und goldfarbene Spielsteine, deutliche Einwurfanzeige, gläsernen Spielfeldrahmen, Lumo als Begleiter, nachvollziehbare Turn-/Sieg-Effekte, größere Touch-Ziele und Fold-responsive Positionierung. Übernehme dabei Farben und Design von den bestehenden Lernscreens; baue keine beliebige neue Spielmarke. Keine UNO-/Mario-Kart-/Fremdmarkenelemente.

## D. Lumo Kart – Menü und vorhandene Spielwelt schützen

Referenz `50666.gif` ist das gewünschte Einstiegslayout: fünf vollständig sichtbare farbige Spielmodi, oben fünf Schritte, große echte 3D-Figur im blauen Kart rechts, dieselbe magische Lumo-Welt, holografische Ringe, unten **eine** gelbe Weiter-Schaltfläche. Keine doppelte Schnellstart-Leiste. Noch vorhandene Modell-/Größenabweichungen **an der realen 3D-Szene** beheben und echte Godot-Renderings liefern; keine aufgezeichnete Konzeptillustration als interaktives Menü deklarieren. Rennstrecken-/Physikarbeit nur isoliert und regressionsgesichert.

## E. Querschnitt: Bestandssicherung und Qualitätsabnahme

1. **Vorbereitung:** `git status`, aktuelle Branch-/Commit-/Godot-Pin-Werte, relevante Szenen/Widgets und gegenwärtige Testlage dokumentieren. Fremde, unfertige Änderungen niemals ungeprüft überschreiben. Separaten Arbeitsbranch verwenden.
2. **Vorher-Aufnahmen:** echte Runtime-Screens der betroffenen App-Seiten und Spiele erstellen; sie sind der Ausgangspunkt für den Vergleich. Referenzbilder sind Sollzustand, keine Beweise für Runtimequalität.
3. **Änderungen:** kleine, reviewbare Commits getrennt je Spiel/UI. Originaldateien bei Bedarf ergänzen, nicht unnötig neu bauen. Keine Markenassets unter `assets/lumo_design/` ohne ausdrückliche Freigabe ersetzen. Bestehende Layoutstruktur von Startseite, Lernwelt, Mathematik, Deutsch, Erfolgsbildschirm und Testauswahl nicht umbauen.
4. **Screenshots:** bei jeweils 360×800, 640×360, 1280×720 und großem Tablet/Fold Hoch-/Querformat (soweit technisch möglich) reale Screenshots anfertigen; sichere Dateien, Commit-ID, Gerätemaße und Renderer nennen. In den Screens alle relevanten Touch-Targets und Texte kontrollieren.
5. **Qualität:** `flutter analyze`, Flutter-Tests für Cards und Connect Four, Godot-Import/Headless-Tests, echte Godot-Aufnahmen für Kart/Build und Android-Integrations-/Installationsprüfungen nach verfügbarer CI. Behauptete Performance nie ohne Messung angeben.
6. **Daten:** kein Reset von Kinderprofilen, Lernkosmos, Sternen, XP, Spielsitzungen, Wallet oder vorhandenen gespeicherten Daten. Update von der zuvor geprüften APK testen.
7. **Erfolgskriterien:** Designidentität sichtbar bewahrt; kein generischer Ersatzfuchs; nichts abgeschnitten; alle Knöpfe echt funktional; Spiele vollständig spielbar; Daten erhalten; keine neuen regressiven Tests; gültige APK erst nach grüner Android-Abnahme.
8. **Übergabe:** PR-Links, genauer Source-Commit, Unterschiede Vorher/Nachher, echte Bildschirmaufnahmen, Testergebnisse, Risiken und ggf. signierte APK bereitstellen. Noch nicht Implementiertes als offen benennen; NICHT durch schöne Konzeptbilder als erledigt darstellen.

**Arbeitsmodus:** autonom reparieren, überprüfen, erneut aufnehmen und iterieren. Bei jeder substanziellen visuellen Änderung einen nachvollziehbaren Vergleich sichern. Wenn die Runtime nicht wie die Lumo-Referenz wirkt, gilt die Grafikarbeit als noch nicht fertig. Vor einem größeren Designwechsel explizite Freigabe einholen; im Zweifel Bestand erhalten und nur gezielt polieren.
