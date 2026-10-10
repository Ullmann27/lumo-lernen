# PERPLEXITY COMPUTER — AUTONOMER LUMO MASTER-AUSFÜHRUNGSAUFTRAG
## Lumo Kart, Lumo Cards, Bauwelt und 4 Gewinnt – echte Android-Runtime, nicht bloß Bildentwürfe
Stand 10.10.2026

**Führe Programmierarbeit aus. Entwickle iterativ, teste selbstständig, verwende vorhandene GitHub-Arbeit und liefere echte Zwischenergebnisse.** Setze Perplexity Computers Computer-/Terminalfunktionen, Webrecherche, spezialisierte parallele Agenten, GitHub, Bild- und Mediengenerierung nach Verfügbarkeit ein. Prüfe zuerst verfügbare Dienste, Kontingente, Installationen und Berechtigungen. Konstruiere keine nicht vorhandenen Tool-Fähigkeiten. Befolge das Screenshot-Protokoll ohne Ausnahme.

## 0. Bestandsaufnahme & SOURCE OF TRUTH
- Flutter / Android / Lern-App: https://github.com/Ullmann27/lumo-lernen
- Godot / Kart / Bauwelt: https://github.com/Ullmann27/lumo-godot
- Auf dem Flutter-Branch `codex/lumo-reference-assets-2026-10-10` zwingend lesen: `docs/design/2026-10-10-lumo-games/DESIGN_BESTANDSSCHUTZ.md`, `REFERENZEN.md`, alle zehn Originalbilder in `references/`, `CLAUDE_SONNET_5_5_PRODUKTIONSAUFTRAG.md` und `PERPLEXITY_COMPUTER_SCREENSHOT_PROTOCOL.md`.
- Existing: Kart-Menü PR #45, Renderer-Prototyp PR #46, Designreferenzen PR #248. Der Perplexity-Cards/4-Gewinnt-Branch `computer/lumo-cards-connect-four-2026-10-10` und GitHub Actions 38050111200 sind separat zu prüfen. Es ist kein automatisches Merge und kein Beweis für installierte APK allein durch grüne CI.
- Aktuelle Branches, Quellstände, Flutter-Version, Godot-Pin, Android-Signing, vorhandene QA und eventuell parallel laufende Entwickleragenten ermitteln. Eigener Feature-Branch. Funktionierenden Code nur in klar begründeten Fällen ändern; additive Adapter/Composition bevorzugen.

## 1. VISUELLE HAUPTVORGABE
Die Nutzerbilder sind VERBINDLICHER SOLL-Zustand: originale orange/cremefarbene Lumo-Figur mit braunen Augen, blauer Fliegerbrille und blauem Outfit; große leuchtende Augen, originale Schnauze, keine generischen Füchse; fantastische schwebende Inseln, Wasserfälle, Burgen, Lichtbrücken; gläserne tiefblaue Panels mit Cyan-Glow, weiche Neonschattierungen und goldene Sterne.

Universal-Lumo-Design-Tokens als Ausgangspunkt (die Bilder haben Vorrang): Hintergrund #0B1528–#020714; Aktiv Cyan #00C8FF; Gold #FFD75A; rundes Glas 24–32 px; feine blaue Kontur rgba(0,160,255,.20); Hintergrundunschärfe ungefähr 16 px auf geeigneten Renderern; selektiver Glow ~15 px rgba(0,200,255,.60). Keine flachen Standardbuttons als endgültige UI. Hover/Tap-Easing sanft (ca. 130–180 ms), Druck-Reaktion/Glanz und reduzierte Bewegung bei `reduceMotion`. Kein unlesbar grelles Glow auf allen Elementen gleichzeitig.

**CSS ist nur Stilinspiration:** Flutter: `ThemeExtension`/Tokens, `BackdropFilter` wo performant, `DecoratedBox`, `BoxShadow`, `AnimationController`; Godot: `Control`, `PanelContainer`, `StyleBoxFlat`, `ShaderMaterial`, `Tween`, `SubViewport`. Kein CSS direkt in GDScript übernehmen. Mobile- und GL-Fallback ohne teure Unschärfe/SSR.

## 2. KONTINUIERLICHE ECHTE SCREENSHOTS – ABSOLUTE VORRANGREGEL
**WÄHREND DER PROGRAMMIERUNG IMMER WIEDER SICHTBARE BILDER VERÖFFENTLICHEN.** Nicht erst nach stundenlanger Arbeit oder nach dem APK-Build. Zu Beginn jeder Szene echtes VORHER-Bild. Nach jeder wesentlichen Änderung an 3D-Figur, Kart, Strecken, Menü, HUD, Shop, Spielmodulen, Belohnungen, neuen Effekten oder Lern-App ein echtes NACHHER-Bild und mindestens einen direkt öffnbaren Vorher-/Nachher-Vergleich. Während langer Grafikarbeit etwa alle 10–15 Minuten mit neuem sichtbar geändertem Zustand melden. Wenn etwas noch nicht rendert: Diagnose + Fehlbild statt fantasierter fertiger Screenshots.

Erzeuge Screenshots aus echter Godot-/Flutter-/Android-Runtime; identische Kamera/Seed/Viewport und bekannte Testdaten. Pflichtformate: 1280×720, 640×360, 1200×896, 360×800 (Lernen). Dateien einzeln auf GitHub oder Actions/Release ablegen, **anklickbare direkte URLs und eingebettete Vorschau** im Perplexity-Chat ausgeben; Collage nur zusätzlich. Jede Meldung: Referenz, Vorher, Nachher, Abweichungen, GitHub-Commit, Teststatus. **Der Nutzer kann jederzeit einschreiten:** Bei Feedback betroffenen visuellen Teil stoppen, Änderungswunsch umsetzen, erneut rendern und zum Vergleich zeigen. Nur unabhängige Arbeiten parallel fortsetzen. Niemals einen Nutzerkommentar ignorieren und automatisch ein neues Hauptlayout über die gewünschte Vorlage legen.

Vollständige technische Bildregeln: `PERPLEXITY_COMPUTER_SCREENSHOT_PROTOCOL.md`.

## 3. LUMO KART – MENÜ
Referenz `50666.gif`: echtes großes 3D-Lumo im blau/cyan/orange glänzenden Kart RECHTS über holografischen Kreisen; Burgen, Wasserfälle, Brücken; links fünf vollständig sichtbare Moduskarten: Einzelrennen, Zeitfahren, Kristall-Arena, Sternen-Cup, Freies Training; oben fünf Schritte Modus/Fahrer/Kart/Welt/Tempo, korrekt angebundene Sterne/Level/XP; unten rechts EIN goldener Weiter-Button, unten links Spieleauswahl. Keine zweite Schnellstart-Leiste, kein flacher Bildschirmersatz, kein abgeschnittenes fünftes Menü im Fold. Echte Funktionen/Buttons/Garage/Modi bleiben angeschlossen; Hintergrund und 3D-Vorschau in SubViewport, Flutter-Bridge intakt.
Wichtige vorhandene Dateien: `scripts/games/kart_garage_menu.gd`, `kart_menu_choice.gd`, `kart_stage.gd`, `kart_vehicle.gd`. Beginne mit realen Ist-Screenshots und korrigiere in PR #45/46 dokumentierte offene visuelle Regressionen nach Logs, ohne die vorigen erfolgreichen Rennprüfungen zu zerstören.

## 4. STRECKEN, PHYSIK & ERGEBNISSE
Vollwertige Original-Lumo-Rennen: Sonnenhafen (Wasser, Palmen, Häuser, Seegelboote), Schneeberge, Wolkeninseln, Süßigkeitenwelt, Nachtvulkan/Neon-City. Konkrete Wiedererkennbarkeit gegenüber den gelieferten Streckenbildern erarbeiten: richtige Streckenbreite/Kurven/Hänge, Brücken/Tunnel, Vegetation, Beleuchtung, dynamische Neon-Bögen, Rampen und spielbare Loopings. MultiMesh für effiziente Detaildichte. Optische Komponenten, Renn-Collision-Meshes und Gameplay getrennt. `WorldEnvironment`/PBR pro Renderer profilieren: Desktop Forward+ Bloom/optionales SSAO, GPU-budgetiertes SSR/gebaktes GI; Android Mobile/GL mit leichterem Licht, Materials und Culling. Nicht blind Forward+-Funktionen auf Android erzwingen.
**Keine erzwungene Sprung-Autonomie:** das Kart bleibt während Rampen/Sprüngen steuerbar; Gravity/Air-Steering/Pitch-Roll visuell und die Landung müssen funktionsfähig bleiben; keine Spline-Übernahme über Flugbahn. `kart_island.gd`, `kart_physical_loop.gd` und Tests sind fachliche Basis.
**Ergebnisbildschirm:** echtes Rennranking mit goldener 1.-Platz-/Lorbeerkranz-Krone bei echtem Platz 1, leuchtende Statistiken im Stil der Garage (Tempo, Handling, Drift, Bestzeit, Rundendauer, Sterne/XP). Ergebniswerte müssen aus echten Renndaten stammen, keine statischen Demo-Zahlen. Für andere Spiele dieselbe Ergebnis-Theme-Komponente mit passenden Kategorien verwenden.

## 5. CHARAKTER, KARTS, AUDIO
Original Lumo, Pandi und Giraffe nur dort verwenden, wo passende, lizenzierte Assets vorhanden sind. Für Lumo den Original-Character-Sheet unter `assets/characters/lumo/reference/` verwenden. Blender für Quad-Mesh, UV und GLB, gebackene Normal-/Roughness-/Emissive-Maps, stilisiertes PBR, hochwertige bekrönte Showroom-Reflexe (nicht mobile-teures Echtzeit-Hair); zielgerechte LODs. Beginne mit funktionsfähigem vorhandenem Modell, keine teuren Blind-Neuentwicklungen. Kart: saubere Bevel-Kanten, Metallic-Paint mit Emissive Cyan/Orange, matte profilierte Reifen. Licht-Setup warmes Key, kühles Fill, starkes Rim. Alle 3D-Assets als tatsächliche GLB/GLTF mit Importprüfung, keine Bildbehauptung.
Stimmen: freundlich, warm, lebendig, kindgerecht; sparsame Soundeffekte, moderne lizenzierte oder eigens erzeugte Musik, Mute/Volume, keine unklare Rechteübernahme. Startampel als eigene Animationskomponente zur EINLEITUNG geeigneter Rennen, nicht als sinnloser Zwang vor jedem Kartenzug. Respect audio focus, `reduceMotion` und Stummschaltung.

## 6. LUMO CARDS, BAUWELT, 4 GEWINNT – DAS GLEICHE UNIVERSALE DESIGN
Implementiere als neue Komponenten/Adapter **im bestehenden Code**, nicht als neue unabhängige Apps:
- Cards in `lib/features/games/lumo_cards/`: richtige Kartenspielregeln und bestehende Bot-, Sprach-/Lernsysteme beibehalten, glossy Karten mit 3D-Anmutung, Lichtreflexen, Handeingaben, korrektes Ziehen/Ablegen/Farbwahl, kein Marken-/Urheberrechtsimitat.
- Bauwelt in `scripts/creative/build_world.gd` und `scenes/creative/build_world.tscn`: echte platzierbare Blöcke, Brücken, Türme, kleine Landschaftsdetails, Snap/Grid/Undo/Redo, sicheres Speichern. Kein statisches Schlossbild als „fertige Bauwelt“.
- 4 Gewinnt in `lib/features/games/connect_four/lumo_connect_four_game.dart`: EXAKT 7×6 echte Spiellogik, korrektes Einwerfen, Gegnerzug, Gewinn horizontal/vertikal/diagonal, Remis/Neustart; gläsernes 3D-wirkendes Board und beleuchtete Chips. Ergebnisse, Spielerstatistiken und Fortschritt wie die übrige Lumo-App behandeln.
- Alle Start-, Sieges-, Niederlagen-, Pausen- und Belohnungsansichten konsistent im Lumo-System; kein flaches oder fremdes UI. Bei jedem einzelnen sichtbar geänderten Screen gilt das Live-Screenshot-Protokoll.

## 7. PERPLEXITY-COMPUTER-WORKFLOW – OPTIMIERT FÜR PARALLELE SPEZIALISTEN
A. **Project Auditor:** liest beide Repos, Commits, offene PRs, Codepfade, Versionen, Tests, Referenzbilder; erstellt genaues Baselineprotokoll.
B. **Technical Artist:** arbeitet an Original-Lumo-Fuchs/Kart, PBR, 3D-Shading, Renderprofil, Strecke; erzeugt tatsächliche Screenshots.
C. **Godot Gameplay Engineer:** testet Steuerung, Runden-/Rangwertung, Rampen, Landung, Drift, Item- und Gegnerlogik.
D. **Flutter/UX Engineer:** universal Theme, Buttons, Cards, 4 Gewinnt, Eltern-/Lerndaten, Fold-Bedienung.
E. **QA/Android Release:** CI, Pixel-/Visionsvergleich, Tests, Build-Signing, APK-Installations-/Updatecheck.
F. **Review Agent:** vergleicht jede tatsächliche Runtime mit den Originalen, protokolliert sichtbare Abweichungen und verhindert voreilige Releasefreigabe.
Das sind ROLLEN; benutze tatsächliche parallele Teilagenten nur, wenn Perplexity sie im Konto anbietet. Koordiniere Git-Branches, vermeide paralleles Schreiben an dieselbe Datei, merge erst nach Tests.

## 8. SICHERE AUTONOMIE & RELEASE-GATES
Treffe technische Entscheidungen selbstständig, keine Routine-Nachfragen. Ersetze nicht die visuelle Freigabe des Nutzers. Repariere Bugs durch Logs, minimalen Fix, Regressionstest, neuen echten Screenshot. Bei 3D-Leistungsproblemen Qualität zurückregeln; never pretend “self-healing” prevents all crashes. Respektiere sichere Datenmigration, API-/OS-Grenzen, Softwarelizenzen, Kinderdatenschutz.
Test-Mindestumfang: Flutter Analyze und bestehende Tests; Godot-Import und Full-Regressions; reale Testfahrten durch Menü, Kart-Auswahl, 3D-Strecke, Sprung, Loop, Pause/Resume, Zieleinlauf und Rennresultat; Fold Außen/Innen, 640×360, 1280×720; API-35/36, Offline/Upgrade, Ergebnis-/XP-Speicherstand. CI grün ≠ exakte Grafik. Erst nach erfolgreich signierter, installierter APK GitHub-Release oder GitHub-Artifact-Link mit Version, SHA-256, Package-Name, Git-SHA, Godot-Pin und Testergebnissen liefern.

## 9. VERPFLICHTENDE FORTSCHRITTSMELDUNGEN
**JEDER** sichtbare Meilenstein: eine neue Perplexity-Computer-Nachricht mit folgenden Angaben:
- Funktion + was du technisch verändert hast;
- **[Referenz öffnen] [VORHER öffnen] [NACHHER öffnen] [Vergleich öffnen]** als direkt anklickbare, verifizierte Links; Einzelbilder nicht nur ZIP;
- Was zum Referenzbild noch fehlt, selbstkritisch und konkret;
- Repo/Branch/Commit und Laufzeit-Viewport/Godot/Android;
- welche Tests bestanden/offen/fehlgeschlagen sind;
- eine klare Möglichkeit zum Eingreifen: „Wenn du Änderungen möchtest, schreibe es direkt hier; ich stoppe diesen visuellen Bereich und korrigiere ihn.“

Warte bei visuellen Grundsatzabweichungen und erheblichen Designänderungen auf die Korrektur/Freigabe. Bei rein technischen, unabhängigen Aufgaben kannst du ohne Wartezeit weiterarbeiten. Kein stundenlanges Weiterdesign ohne echte Zwischenbilder. Schlussabnahme nur mit echter Laufzeit, nicht mit Konzeptgrafiken.

**AUSFÜHRUNG JETZT:** 1) Aktuellen GitHub-Stand samt vorherigen Perplexity-Arbeiten prüfen. 2) Erste Referenz-/Runtime-Bildpaare für Kart-Startmenü, tatsächliche Rennen, Cards, 4 Gewinnt und Bauwelt posten. 3) Die wichtigste sichtbare Abweichung mit minimalem Patch korrigieren, erneut rendern und dir direkt das erste Vorher-/Nachher-Paar zeigen. 4) Iterieren, mit laufenden Bildern, allen Tests und abschließender APK.
