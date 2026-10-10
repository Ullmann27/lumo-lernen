# PRODUKTIONSAUFTRAG AN CLAUDE SONNET 5.5 – LUMO MARKENWELT (10.10.2026)

**Auftragsart:** Konkret implementieren, nicht nur über Konzepte sprechen. **Projektbasis:** Verifizierter gemeinsamer Flutter/Android-Stand 0.12.13+1920 plus separat in Arbeit befindlicher Kart-Menü-Kandidat 0.12.14+1921. Versionsnummern nicht ohne Abgleich mit GitHub ändern. Dies sind zwei reale Repositories:
- `https://github.com/Ullmann27/lumo-lernen` (Flutter-Lern-App, Lumo Cards, 4 Gewinnt, Godot-Integration)
- `https://github.com/Ullmann27/lumo-godot` (3D-Lumo-Kart, Bauwelt und andere Spiele)

## I. Unverhandelbarer Design-Bestandsschutz

Lies zuerst `docs/design/2026-10-10-lumo-games/DESIGN_BESTANDSSCHUTZ.md`, `REFERENZEN.md` und alle **zehn Originalbilder** unter `docs/design/2026-10-10-lumo-games/references/` auf dem Branch `codex/lumo-reference-assets-2026-10-10`.

Visuelle Hierarchie: **Originalbilder des Auftraggebers > bestehende Lumo-Bildsprache und Runtime > neue Designskizzen**. Bewahre die Lumo-Identität (orangefarbener Fuchs, Creme-Wangen und Kinn, braune Augen, blauer Rennanzug und blaue Goggles), Nachtblau, Magie-Inseln, Wasserfälle, Neon-Cyan, Sterne, goldgelbe Highlights, gerundete halbtransparente Glaspanele, die App-Navigation und ALLE inhaltlichen Lernelemente. Vorhandene Designbilder nicht durch generische SVG-Zeichnungen oder fremde Figurinspirationen ersetzen. Die drei SVG-Layouts unter `docs/design/2026-10-10-lumo-games/` sind nur technische Wireframes und NICHT der Zielstil.

Für die Lern-App müssen Home, Lern-Weltkarte, Mathematik, Deutsch, Sachunterricht, Logik, Belohnungsabschluss und Testbereich genauso hochwertig und wiedererkennbar bleiben wie in den Referenzen. Keine pauschale Umfärbung der App, keine Layout- oder Datenmigration wegen Grafiken.

## II. Arbeitsweise – Erhalten, gezielt erweitern, verifizieren

1. Prüfe beide GitHub-Repositories, den aktuellen Branch-/PR-Stand und alle bestehenden Tests. Vor jeder Änderung echten Runtime-Screenshot aufnehmen; nicht behaupten, ein statischer Bildentwurf sei bereits das Spiel.
2. In separatem GitHub-Branch und kleinen nachvollziehbaren PRs arbeiten. Bereits bestandene Renn-, Lern-, Update-, Offline-, Belohnungs-, Multiplayer-/Einzelspieler- und Profile-Tests erhalten. Jedes Feature per Composition/Decorator/Adapter anbinden, solange sinnvoll; ausdrücklich begründete Kernkorrekturen sind erlaubt, jedoch mit Regressionstests.
3. Selbstständig Fehler analysieren und Alternativen entwickeln, aber keine Produktions-Sicherheitskontrollen, berechtigten Zugriffsgrenzen oder Benutzerfreigaben umgehen. Nicht behaupten, System sei „uncrashbar“; defensive Fehlerbehandlung und degradierte Grafikprofile implementieren.
4. Niemals fälschlich 30/60 FPS, HDR, APK-Installation oder Testbestehen behaupten: nur belegte Messergebnisse, echte Screenshots und genaue GitHub-Run-IDs ausgeben.
5. Android: Smartphone, Galaxy-Fold-Querformat/Innenbildschirm, Hochformat, Tablet, Display-Scaling und vergrößerte Schriften; barrierearme Lesbarkeit, 48 dp+ Touch-Ziele wo möglich, sichere Ränder, externe Tastatur und Touch-Steuerung prüfen.

## III. Lumo Kart: das gewünschte Einstiegsmenü

Referenz `50666.gif` im GitHub-Referenzordner. **Beim Einstieg** fünf große, gut lesbare Karten links:
Einzelrennen / Zeitfahren / Kristall-Arena / Sternen-Cup / Freies Training. Rechts Lumo groß IM tatsächlich gerenderten blauen Kart mit cyan-leuchtenden Rädern und Lichtreflexen über transparenten kreisförmigen Hologrammringen. Hinten märchenhafte Insel-Schlosswelt. Oben Lumo-Kart-Logo, echtes Level/Sterne/XP, die Schritte Modus / Fahrer / Kart / Welt / Tempo. Unten links Spieleauswahl, unten rechts ein **einziger goldgelber „Weiter“-Button**. Keine zweite übergroße „Spielen“-Leiste. Alle fünf Modi müssen auch im Fold-Querformat sichtbar oder bewusst kompakt/scrollbar mit erreichbar bleibender fünfter Option sein. Keine Abweichung von Figur und Kart in den Referenzen.

Wichtige vorhandene Stellen: `scripts/games/kart_garage_menu.gd`, `kart_stage.gd`, `kart_vehicle.gd`, `kart_menu_choice.gd`, `scripts/tests/kart_premium_menu_capture.gd`. Baseline ist PR #45; ergänzender Grafiklayer PR #46. Die 3D-Vorschau ist ein echtes SubViewport; darauf liegen native bedienbare Control-Nodes. Gestalte Frosted-Glass-Shader und Glanz **additiv**, mit leistungsfähigem Fallback ohne Screen-Read auf schwachen Geräten. Definierte Hover/Tap-Tweens (Scale max. 1.03, ca. 130–180 ms), Drag-to-Rotate, ruhig schwebender Ring, sanfte Kamera, reduzierte Animationen respektieren. Renderpfad mit realen Screenshots und Menütest nachweisen.

## IV. Godot-Rendering und Strecken – differenziert nach Gerät

Nutze die in PR #46 angelegten Dateien (falls CI grün): `assets/shaders/kart_frosted_glass.gdshader`, `kart_glass_lite.gdshader`, `scripts/games/visual/kart_environment_polish.gd`, `kart_neon_gates.gd`, `kart_neon_gate_pulse.gd`. Das sind **erste Erweiterungen**, kein vollständig abgenommener AAA-Renderer.

Erweitere Materialsystem und Qualitätspfade statt alles pauschal zu aktivieren:
- Forward+ Desktop: selektiver Bloom HDR-Threshold > 1, SSAO nur nach Profiling, SSR nur bei messbarer vertretbarer GPU-Zeit, optional gebackene GI statt teurer dynamischer SDFGI;
- Mobile Vulkan: reduzierte Materialien/Instancing, sorgfältig begrenzte Schatten, Glow; SSR/SDFGI nicht voraussetzen;
- GL Compatibility: Ersatzglasshader ohne teure Bildschirmunschärfe, gebackene Lichtstimmung.
Die vorhandenen Strecken dürfen farblich und strukturell verbessert, **nicht neu erfunden** werden. MultiMesh für Gras, Blumen, kleine Pilze, Pylone und Variationen. Holografische Lichtbögen aus einem MultiMesh, Path3D + PathFollow3D für begrenzte sanfte Marker; Collisions nur für echte Spielobjekte. Geometrie/Materialien wie im Produktivspiel, nicht reine Screenshots. Nutze LOD, Culling und Obergrenzen, reduziere Effekte bei GPU-Budgetüberschreitung. Messwerte protokollieren.

## V. Fahrphysik, Rampen und Luftlenkung – volle Spielerkontrolle

`scripts/games/kart_island.gd::_drive_player`, `_move_vertically`, `kart_physical_loop.gd` und passende Tests zuerst untersuchen. In der EXISTIERENDEN Implementierung gibt es freie horizontale Bewegung mit reduzierter Lenkung im Flug, Gravitation und Landung; nicht durch Splines oder Cutscene-Steuerung ersetzen.

Die **frei lenkbaren Sprünge** bleiben eine Gameplay-Invariante: kein automatisch vorgegebenes Sprungziel, Spieler kann Luftlage (visuellen Pitch/Roll und begrenzte Side-Steering) kontrollieren. Bei schlechter Landung ggf. moderater Geschwindigkeitsmalus statt plötzlich erzwungener Teleport. Physik in festem Delta, deterministische Tests für Start/Schräglage/Landung/Respawn, Rampe, Looping, Rückwärtsfahrt, Gegnerkontakte und Pausen. Core-Fahrverhalten nur mit messbarer Rückwärtskompatibilität modifizieren.

## VI. Figuren, Kart, Blender und PBR-Produktion

Nutze die Original-Character-Sheets in `assets/characters/lumo/reference/`, nicht ungeprüfte fremde Links. Vom Auftraggeber genannte `googleusercontent.com/generated_image_content/0` und `/1` nur nutzen, wenn sie tatsächlich erreichbar, überprüft und visuell identisch sind; andernfalls Quellen offen als fehlend dokumentieren.

Blender (.blend Source, `.glb`/glTF Export) mit Quad-Modelling, sauberem UV-Mapping und exportiertem trianguliertem GPU-Mesh. Mobil-Kontrollwerte: Lumo etwa 15–25k Dreiecke nur als oberes LOD-Ziel; Kart maximal ca. 30k Dreiecke für das Hero-Modell, weitere deutlich kleinere LODs. Facial Blendshapes, Ohren und Schweif-Bones, Gesicht und Körper müssen originalgetreu sein. Fell als stylized-PBR mit Baked Normals/anisotroper Anmutung ohne teures Echtzeit-Hair. Ohrspitzen mit subtilem Transluzenz-Look nur wenn Materialprofil es ermöglicht. Rennanzug Klarlack, metallic blaues Kart mit Roughness etwa 0.15, leuchtend cyanfarbene Emissive-Akzente, Gummi Roughness etwa 0.85. Warmes Key-, kühles Fill- und kräftiges Cyan-Rim-Light in der Showroom-Bühne.

In PR #46 existiert `kart_tail_spring_adapter.gd` als **noch nicht integriertes** Federungsmodell; integriere erst, wenn die bisherige TailJoint-Animation exklusiv ersetzt werden kann. Keine Konkurrenz zweier Animatoren auf derselben Transform und kein Einfluss auf Kollisionsgeometrie. Typische optional freie Werkzeugketten: Blender, ArmorPaint, ComfyUI/Stable Diffusion für PBR-Texturreferenzen und Meshy/Tripo nur als Prototyping. Keine ungeklärten externen Lizenzen in ein vermarktetes Kinderprodukt übernehmen.

## VII. Lumo Cards, Lumo Bauwelt, Lumo 4 Gewinnt

Die Spiele existieren bereits:
- Cards: `lib/features/games/lumo_cards/`, vorhandenes Deck, Bot, Lernfragen, Spiellogik und `widgets/lumo_card_table.dart`. Ergänze magischen Lumo-Spielkartentisch, Kartenflug, leuchtenden Ablegestapel, kindgerechte Animationen. Bestehende Regelmechanik erhalten. Kein unzulässiges Nachzeichnen fremder Kartenmarken.
- 4 Gewinnt: `lib/features/games/connect_four/lumo_connect_four_game.dart`. Bleibe bei **exakt sieben Spalten und sechs Reihen**, echte Fall-/Gewinnlogik, Lumo als Gegenspieler; gib Board und Spielsteinen Glas/Kristall-3D-Look, validierte Touch-Spalten und verständliches Endergebnis. Regeln, Gegner und gespeicherte Fortschritte dürfen nicht verlorengehen.
- Bauwelt: `scenes/creative/build_world.tscn`, `scripts/creative/build_world.gd`. Ein echtes 3D-Bausystem mit Raster-Snapping, Vorschau-Ghost, Auswahl, Drehen, Undo/Redo, dekorativen Dächern, Brücken, Türmen und kindersicherem Speichern; kein starres Hintergrundbild als „fertige Bauwelt“.

Die vorhandenen originalen UI-Bilder und `assets/lumo_design/` werden wiederverwendet. Drei zusätzliche SVGs in `docs/design/2026-10-10-lumo-games/` zeigen ausschließlich Interaktionszonen, nicht die finale Kunst. Jede Ergänzung muss optisch zur Lern-App passen.

## VIII. Technischer Abnahmeplan

Nutze die vorhandenen Flutter-/Godot-Workflows, keine stillen Testdeaktivierungen. Konkrete Ergebnisse liefern:
1. Belege der identischen Lumo-Figur und Kart-Silhouette direkt aus Runtime (Menü, Garage, Rennen, Lerneinheit, Spielwelt).
2. Echte Vorher-/Nachher-Aufnahmen in 1280×720, 640×360 und Fold-Innenformat, plus Smartphone-Portrait für Lernen.
3. Feature-Gates für Glow/SSAO/SSR, Render-Downgrade, Memory- und Frame-Time-Budgets (Ziel 30 FPS unter reellen Geräten, nicht behauptete Zahl).
4. Prüfe alle fünf Rennmodi, Rennen auf API 35/36, Pausen/Save-Resume/Offline/Update, kartregelkonforme Gameplay-Tests; Lernfortschritt und Elternzuordnung bleibt je Kind erhalten.
5. Erzeuge **erst nach erfolgreichem echten Android-Build** eine signierte installierbare APK, prüfe Package-ID, Versionscode, Signatur, Spielintegration und die zugehörigen GitHub-Quellpins; Screenshots und APK-Verweis direkt zu GitHub-Artefakten.
6. Fehlgeschlagenes Test-Gate explizit dokumentieren und reparieren, bis es bestätigt bestanden ist. Keine Freigabe durch rein kosmetische Standbilder.

## IX. Übergabeformat – ohne Behauptungen oder Stillstand

Bei jedem sinnvollen Fortschritt:
- betroffene Dateien/Änderungen,
- echte Vorher/Nachher-Screenshots,
- getestete Bildschirmgrößen,
- GitHub-Commit, PR und CI-Lauf,
- was wirklich funktioniert und was offen ist,
- messbare nächste technische Aufgabe.

Du bist der verantwortliche ausführende Entwickler. Beginne mit der Abnahme von PR #45 und #46 und der Originalbildreferenz, danach mit dem premium Kart-Menü inklusive korrekt großen realen 3D-Lumo, anschließend Cards, Bauwelt und 4 Gewinnt. Arbeite so, dass die Lern-App weiterhin Hauptbestandteil des Produkts bleibt.
