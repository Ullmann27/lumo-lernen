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


---

# ANHANG A — VOLLSTÄNDIGES LIVE-SCREENSHOT-PROTOKOLL

# VERBINDLICHES LIVE-SCREENSHOT- UND FREIGABEPROTOKOLL — LUMO
Stand 10.10.2026 · Gilt für Perplexity Computer, Claude Sonnet, Codex und andere Entwicklungsagenten.

## 1. Zweck

Der Auftraggeber muss während der Programmierung laufend selbst beurteilen können, ob neue Ansichten dem ursprünglichen Lumo-Design entsprechen. **Vorher-/Nachher-Bilder sind ein verbindliches Zwischenergebnis, nicht nur eine Beilage zur finalen APK.** Die originale Gestaltung ist unter `DESIGN_BESTANDSSCHUTZ.md` festgelegt; die zehn Originaldateien stehen unter `references/`.

## 2. Wann MUSS ein Bild erscheinen?

- **Ganz am Anfang:** ungeänderter Ist-Zustand der betroffenen Szene/Flutter-Seite plus das zugehörige Referenzbild; beschriftet mit Git-SHA, Bildschirmgröße, Renderer/Device und Datum.
- **Nach JEDER sichtbaren Änderung** an Lumo (Gesicht, Körper, Kart), Levelgeometrie, Streckendekoration, Licht, Shader, Menü, HUD, Knopfgrößen, Karte, Lernseite, Audio-Auswahloberfläche oder Ergebnisbildschirm: neues echtes Nachher-Bild, unmittelbar dem Vorher-Bild gegenübergestellt.
- **Bei umfangreicher visueller Arbeit mindestens nach jedem visuellen Meilenstein**, und zusätzlich ungefähr alle 10–15 Minuten aktiver Layout-/3D-Arbeit, sofern neue darstellbare Änderungen vorliegen: keine halbstündigen „unsichtbaren“ Grafikphasen.
- **Nach Fehlerbehebungen** (z. B. fünfter Rennmodus abgeschnitten, Wangenlücke, falscher Skalierungsfaktor) und **vor jedem Build/PR-Merge**: die reparierte Stelle sichtbar nachweisen.
- **Wenn Rendern gerade unmöglich ist:** sofort ein Problemprotokoll und die tatsächlich vorhandenen Logs/Fehlbilder zeigen; nicht aus KI-Generatoren Ersatz-Screenshots als „echte Godot Runtime“ ausgeben. Reparatur priorisieren und dann echte Bilder nachreichen.

## 3. Technische Herstellung

1. Vorher und Nachher müssen aus **derselben ausführbaren realen App/Szene** stammen: Flutter Screenshot über Emulator/integration_test, Godot Viewport `get_texture().get_image()` oder Android `adb exec-out screencap -p`. Kein Figma-, Text-to-Image- oder Canvas-Bild als Laufzeit-Nachweis.
2. Für den Vergleich feste **Kamera, Track, Fahrzeug, Lernstand/Test-Account, Bildschirmauflösung, Tages-/Lichtphase, UI-Zustand** und reproduzierbare Zufalls-Seed verwenden. Bei Bewegung mehrere kontrollierte Frames erfassen.
3. In den Format-Gates mindestens: **1280×720 Querformat**, **640×360 kompaktes Fold-Querformat**, **1200×896 großes Fold/Tablet**, **360×800 Android-Portrait** für die Lern-App. Weitere tatsächliche Displaymaße ergänzen. Bei Fold die echte nutzbare Fläche und Touchbedienung prüfen, nicht nur ein Bild skalieren.
4. Bildvergleich pro Szene als **zwei Einzelbilder + Side-by-Side-Kontaktabzug** (links Vorher, rechts Nachher), zusätzlich optional Alpha-Overlay und Bilddifferenz. Referenz-Illustrationen gesondert mit `SOLL (Konzeptgrafik)` kennzeichnen.
5. In GitHub versionierte Nachweise unter `docs/qa/visual/<feature>/<YYYY-MM-DD>/<commit>/` oder in GitHub Actions Artifacts mit unmittelbar anklickbarer URL sichern. **GitHub Actions Artifacts können verfallen:** maßgebliche Vorher-/Nachher-Bilder möglichst als dauerhaft versionierte, komprimierte PNG/WebP-Dateien ins Repository; große Sammlungen über Artefakte/Release mit Manifest und SHA256. Keine riesigen Dateien ungeprüft committen.
6. In jeder Fortschrittsmeldung **direkte Links pro Bild** und, soweit der Client es unterstützt, eingebettete Bildvorschauen liefern. Keine reine Dateipfad-Angabe ohne URL; keine Collage als einziger Beweis, damit der Nutzer hineinzoomen kann.

## 4. Jedes sichtbare Update muss enthalten

**Bildschirm/Funktion:** [z. B. Kart – Moduswahl]
**Vorher:** [direkt öffnbarer Bildlink]
**Nachher:** [direkt öffnbarer Bildlink]
**Referenz:** [exaktes Originalbild/Link]
**Änderung:** [knappe technische Beschreibung]
**Vergleich:** [was sichtbar besser ist / was sichtbar noch abweicht]
**Quelle:** [Repository, Branch, Commit]
**Format & Laufzeit:** [Größe, Android/Godot-Version, Renderer]
**Tests:** [belegt bestanden / fehlgeschlagen / offen]
**Nutzerentscheidung:** [freigegeben / Korrekturwunsch / noch nicht geprüft]

## 5. Eingriff durch den Auftraggeber

Der Auftraggeber muss **jederzeit** einen visuellen Korrekturwunsch formulieren können. Bei eingehendem Feedback zu Szene X:
- die weitere visuelle Änderung an **X** anhalten,
- Zustand und Bildlinks sichern,
- Feedback als verbindliche Akzeptanzbedingung konkretisieren,
- Korrektur entwickeln und **erneut Vorher/Nachher-Bilder ausgeben**,
- bis dahin nicht behaupten, X entspreche dem Bild und keine ungeprüfte APK als finale Auslieferung kennzeichnen.
Unabhängige Code-/Testarbeiten können weiterlaufen; sie dürfen die strittige Szene nicht überschreiben. Für größere Änderungen an originalen Markenassets oder Shell-Strukturen **ausdrückliche Zustimmung vor Integration** einholen. „Keine Rückfragen“ gilt für normale technische Routineentscheidungen, NICHT für entgegenstehende Designrückmeldungen und unumkehrbare Eingriffe.

## 6. Freigabebedingung

Ein „visuell fertig“ oder „APK final“ ist unzulässig, solange ein wesentlicher Screenshotvergleich fehlt, wichtige Referenzabweichungen ungelöst sind, Buttons nicht erreichbar sind oder Android-Installation/Spielablauf nicht nachgewiesen wurden. Eine grüne CI allein bedeutet NICHT „wie Referenz“.


---

# ANHANG B — ÜBERNOMMENE UNIVERSAL-LUMO-DESIGNANWEISUNG DES AUFTRAGGEBERS

**Auftrag:** Programmiere und erweitere Lumo Kart sowie jede weitere beauftragte Spielkomponente innerhalb des bestehenden Projekts. Nicht bei null beginnen. Entscheidungen zu Architektur, visueller Umsetzung, Testing und Integration im vorhandenen GitHub-Code eigenständig treffen, solange die Markenidentität und Nutzerdaten geschützt bleiben. Parallel laufende Agenten dürfen einander nicht überschreiben.

**Universal Style:** Mitternachtsblau #0B1528 bis #020714; Cyan #00C8FF; Goldgelb für Stars, Ergebnisse und primäre Aktionen; Glasflächen mit 24–32 px visueller Rundung und ungefähr rgba(0,160,255,.20) feiner Kontur; optionaler Blur als Qualitätsprofil; selektiver Glow ungefähr 15 px rgba(0,200,255,.60). Jedes echte interaktive Element benötigt einen klar erkennbaren Fokus- und Pressed-Zustand. Niedrigere Grafikprofile dürfen aus Performancegründen auf teure Effekte verzichten, ohne Funktionen zu beeinträchtigen.

**Spielfläche:** Echte plastische Objekte und funktionierende Spielmechaniken statt unechter, nur gemalter Elemente. Die Maskottchen Lumo, Pandi und Giraffe nur anhand vorhandener Originalgrafiken und passender 3D-Assets verwenden. Ein animiertes Startampel-Motiv mit drei grünen Lichtern kann gezielt eine Rennsequenz einleiten, jedoch nicht jede Lernaufgabe oder jeden Kartenspielzug verzögern.

**Audio:** Warme, sympathische, nicht steife kindgerechte Stimmen, moderne geeignete Musik, präzise Sounds für korrekte/inkorrekte Aktionen und echte Rennereignisse. Alle Audio-Ausgaben mit Stummschaltung, Lautstärke, Android-Audiofokus und Lizenzen abstimmen.

**Ergebnisse und Dashboard:** Ergebnisse im Lumo-Stil mit vertikaler Auflistung und großer Detailkarte. Bei tatsächlichem Platz 1 im Rennen ein goldener Lorbeerkranz mit „1. PLATZ!“; niemals anderen Platzierungen oder bloßen Simulationen einen Sieg anzeigen. Leistungsstatistiken mit cyanfarbenen Balken wie in der Kart-Garage, echte Zeit- und Rangdaten verwenden. Andere Spiele erhalten ihr passendes 7×6-Brett/Karten-/Bauwelt-Ergebnis, kein allgemeines vorgetäuschtes Rennranking.

**Qualität und Veröffentlichung:** Vor finalem Commit unbenutzte Importe und toten Code nur löschen, wenn nachvollziehbar unreferenziert und migrationssicher. Echte Testläufe, echte GitHub-Commits und echte Android-Installation; kein behaupteter APK-Link ohne nachgewiesenes Artefakt. Alle wesentlichen Vorher-/Nachher-Aufnahmen während des Programmierens mit direktem Link posten. Bei Nutzerkritik den betroffenen Designbereich pausieren, andere unabhängige Aufgaben dürfen fortfahren.

**Prioritäten:** 1. Originalbilder und Lumo-Identität. 2. Wirklich spielbarer Godot-/Flutter-Code. 3. Automatisch und visuell bestandene Tests. 4. Android-Kompatibilität/Fold. 5. Freigegebene APK. Screenshots sind wiederholt schon in den Phasen 1–4 zu liefern; niemals erst ganz zum Schluss.



---

# ANHANG C — AAA-ART-PRODUCTION-PIPELINE, INTELLIGENTES WERKZEUG-ROUTING UND CREDIT-CONTROLLING
**Dieser Anhang ist Bestandteil des AUSFÜHRUNGSAUFTRAGS. Er ergänzt die Kapitel über Figuren, Strecken, Audio, Rendering, Android und Screenshots. Bei Widerspruch gelten Nutzer-Originalbilder, Markenschutz, sichere Nutzerdaten und echte Runtime-Abnahme zuerst.**

## C.1 KI-ORCHESTRATOR: DAS BESTE GEEIGNETE WERKZEUG PRO TEILAUFGABE
Du bist Perplexity Computer. Erstelle zu Beginn ein Tool Capability Inventory aus den tatsächlich verbundenen Diensten und installierten bzw. ausführbaren Werkzeugen: Name, Version, Ausführungsort, Lizenzstatus, API/CLI, Exportformat, mögliche GPU/VRAM-Grenzen, geschätzte Credit-/Cloud-Kosten. Behaupte keine Integration, bis ein Testaufruf erfolgreich ist. Perplexity-Computer-Subagents und Cloud-Computer nur nach tatsächlicher Verfügbarkeit verwenden. Wenn ein Werkzeug nicht verfügbar ist: kostenlose/Open-Source-Alternative wählen; bezahlte Anmeldung oder Lizenz ausdrücklich vorher genehmigen lassen. Never spend third-party paid credits, install unsafe plug-ins or register third-party accounts autonomously.

Verteile unabhängig voneinander: (1) Repo-/Gameplay-Audit, (2) Character & Kart, (3) World/track environment art, (4) Materials/VFX, (5) Flutter HUD/result UI & audio, (6) Godot/Android integration, (7) QA screenshot comparison. Steuere Abhängigkeiten per gemeinsamem Art-Bible/Asset-Manifest und gesperrten Merge-Gates; keine Agenten editieren dieselben Zielassets gleichzeitig. Für einfache Code-/Testjobs kosteneffizientes Coding-Modell; leistungsstarkes Reasoning-Modell nur für komplexe Architektur/Shader-Bottlenecks; spezialisiertes visuelles Modell nur für Originaltreue/Lookdev; Bild-/3D-KI nur mit klarer Asset-Lücke. `Sol 6.1` oder `Astra` nur verwenden, wenn diese Modellnamen im Perplexity-Konto tatsächlich angeboten werden und Credits/Abrechnung bekannt sind; keine erfundenen Preisfaktoren.

## C.2 PROFESSIONELLE TOOLS – TASK-BASED, NIE BLIND ODER ALLE GLEICHZEITIG
**3D-Modellierung/Hard Surface:** Blender bevorzugt für reproduceable .blend, Python-Automation, Modelling, Bevels, Rigging, UV und Geometry Nodes; Autodesk Maya und 3ds Max als optionale lizenzierte Alternativen, wenn tatsächlich verfügbar und der Nutzen klar ist. Rennkart als echter High-Poly/Low-Poly-Workflow, separate bewegliche Räder, Lenkrad, Scheinwerfer, Motor-/Boost-Geometrie, Cockpit und Sitz mit korrekt positioniertem Lumo. Bevel + weighted normals, UV2/Lightmaps, Material-IDs, pivot/origin, collision proxy.

**Charakter-Sculpt/Rigging:** Maxon ZBrush (lizenziert) für Sculpt/Retopology oder Blender Sculpt kostenlos. Topologie gesichts- und animationsgerecht; Konsistenz mit `assets/characters/lumo/reference/01_master_character_sheet.png`. Outfits, Brille, Ohr-, Schwanz-, Mimik- und Griffanimation korrekt riggen. Ergänzend gegebenenfalls Autodesk Maya Animation, Cascadeur oder Mixamo nach Prüfung der Nutzungsrechte; Blender Rigify/NLA als bevorzugte offene Alternative. Keine eigenmächtige Neugestaltung Lumos.

**PBR-Texturen/Materialien:** Adobe Substance 3D Painter für Layered 3D-Painting und Baking, Substance 3D Designer für prozedurale Materialien, Substance Sampler für Material-Rekonstruktion; nur mit gültiger Lizenz. Blender Texture Paint, Material Nodes, Baking, Krita/GIMP als Open-Source-Fallback. Erstelle BaseColor, ORM (Occlusion/Roughness/Metallic), Normal (korrekte Tangent-/Y-Konvention), Emission und ggf. Alpha-Masks; Farbmanagement mit sRGB/linear beachten. Für mobil sinnvolle Atlas-Größen (z. B. 512–2048, nach Sichtgröße und Speicherbudget), komprimierte Texturen; keine überflüssigen 4K/8K-Maps.

**Bake/Lookdev:** Optional Marmoset Toolbag für Material-Lookdev/Baking, Blender Cycles/Eevee als solide verfügbare Alternative. Cinema-Render („Konzept / Offline-Render“) immer eindeutig von **Godot Runtime (echtes Spiel)** trennen. Der Offline-Render ist keine Abnahme.

**Prozedurale Welten:** SideFX Houdini/Indie/Labs bei Lizenz und CLI-Verfügbarkeit für art-directable Strecken, Felsinseln, Brücken, Wasserfälle, Kurven, Geländer, Fassaden, Turmhäuser, Tunnel, neonfarbene Tore, Loops, Scatter/Heightfield; alternativ Blender Geometry Nodes plus Python Generatoren/Godot MultiMesh. Optionale Terrain-Tools Gaea/World Machine nur bei Lizenz/GPU-Verfügbarkeit. SpeedTree nur bei Lizenz für Bäume; frei gestaltete Blender-Geometry-Nodes-Foliage als Fallback. Exporte als GLB/Textures/Heightmaps, Houdini-HDA ist nicht direkt mit einem Godot-Release gleichzusetzen. Realitätschecks: befahrbare Fahrbahn, Renn-Kollision, Kamerakorridor, KI-Navigation, Abkürzungen, Landmarken und Wiedererkennung aus den Originalbildern.

**Referenz-/Grafikproduktionswerkzeuge:** PureRef als optionales Moodboard, Figma/Adobe Illustrator als optionale UI-Designtools, Inkscape/Krita/GIMP als Open-Source-Alternativen. Spezial-KI-Modelle für Referenzbilder/Turnarounds, einzelne Decals oder neue Props nach Qualitätskontrolle; mögliche 3D-Generierungsdienste (z. B. Meshy/Tripo) nur nach Verfügbarkeits-, Lizenz-, Kosten- und Geometrieprüfung. Keine Wasserzeichen, unklare Stock-Assets, kopierten Mario-Kart-/Nintendo-Content oder private Bilduploads an ungeprüfte Anbieter. Bildentwurf ist niemals GLB, Material oder lauffähige Szene.

**Bewegung/Cinematics:** Blender NLA/Action Editor, Godot AnimationPlayer/AnimationTree, Camera3D und Timeline-Easing; optional Cascadeur, Maya oder iClone bei Lizenz. Für Fuchsbewegung Ohr-Twitch, Blickrichtung, Lächeln, blinkende Augen, Schwanz-Spring-Bone/Follow-Through, Lenkradgriffe, Turbo-Reaktion; mobileperfomantes Skeleton. Optional Intro-Sequenz, Podest-Kamerafahrt, Siegespose und Streckeneinflug, aber jederzeit überspringbar und nicht auf Kosten der Steuerbarkeit.

**VFX & Audio:** Godot GPU/CPU-Partikel, Animation, Shader, Flipbooks, Flowmaps; Houdini-FX nur für Offline-gebakene Effekte. Audacity/Reaper für Sounds/Schnitt nach tatsächlicher Verfügbarkeit; FMOD/Wwise nur mit durchgängig getesteter Engine-Integration und geklärten Lizenzen; sonst Godot AudioStreamPlayer/Bus-Effekte. Originale kindgerechte Stimme und moderne lizenzierte Musik, Mute/Volume/AudioFocus.

**Performance-/Profiling-Werkzeuge:** Godot Profiler/Monitors, Android Studio/ADB/Logcat, Perfetto/Android GPU Inspector wenn verfügbar, RenderDoc wenn Engine/Device kompatibel. Pillow/OpenCV/ImageMagick (je nach Installation) nur zum Vergleichen/Komprimieren von echten Screenshots; Playwright für Web-Preview, Flutter integration_test/Android emulator für reale App. Blender/Python CLI für Batch-Export, Headless Godot für Importtests und Reproduzierbarkeit, GitHub Actions für Android-Artefakte.

## C.3 PROFESSIONELLE ASSET-PRODUKTIONSKETTE (NICHT NUR PROMPT-TO-IMAGE)
Für jedes Hero-Asset (Lumo, Standardkart, Siegerpodest, Sonnenhafen-Landmarke, Looping, Eisbrücke) den vollständigen Pfad durchführen:
1. **Originalreferenz** mit Name und eindeutigen Merkmalen (Gesicht, Brille, Farben, Silhouette, Maße) verankern.
2. **Blockout/Proxy** maßstabsgerecht in der vorhandenen Godot-Szene; erste reale Kamera- und Gameplay-Screenshots.
3. **High-Poly-Sculpt/Hard-Surface** unter Beachtung des originalen Stils, als editierbare Quelle abspeichern.
4. **Low-Poly/Retopology + UV** inklusive funktionierender Collision-Proxies, Rig/Pivots und Instanzierbarkeit.
5. **Texture Bake/PBR**: Normal/AO/Metallic/Roughness/Emission; kontrollierte Textur-Atlanten und LODs.
6. **Animation/Technical Rig**: sauberer Bone-Rig, Rad- und Fahrwerksbewegung, Schweif, Fahrerarme; Blend-States.
7. **Export GLB/glTF 2.0** mit allen nötigen Animationen; automatisierter Import/Material-Sanity-Test in Godot; Lizenz- und Quelleintrag ins Asset-Manifest.
8. **Echte Runtime-Prüfung** mit repräsentativem Kamera-FOV, Helligkeit, Art-Direction und Android-GPU; JPEG/PNG/WebP-Grafik und PBR-Maps dürfen nicht falsch interpretiert werden.
9. **Referenz-Vorher/Nachher-Screenshots öffentlich zugänglich**; vom Auftraggeber kritisierte Stellen bearbeiten, nicht ohne Review final deklarieren.
10. **QA/Performance**: Frame-Time, Draw Calls, Geometrie, VRAM, Installationsgröße, thermische Stabilität, Offlineverhalten; richtige Quality-Tier-Zuordnung.

## C.4 AAA-ART-DIRECTION IN EINER MOBILEN GODOT-RUNTIME
Entwickle eine priorisierte Shot-/World-Bible: (A) Lumo + Standardkart 3/4-Profil im Garage-Menü, (B) Sonnenhafen-Startgerade, (C) Skyline-Looping, (D) Eisbrücke, (E) Ziel- und 1.-Platz-Sieg; je Referenz absolute Formen/Farbverhältnisse/Lichtachsen/Kamera-FOV/HUD-Abstände. Erst einen kleinen **vertikalen Qualitätsschnitt**, der nachweislich in der App läuft, bis zur Referenzqualität bringen; danach denselben Asset-/Shader-Pfad auf weitere Strecken übertragen. Keine vier halbfertigen Rennwelten statt einer vollständigen.

Godot-Mobile unterstützt nicht alle Desktop-Forward+-Funktionen: SSR, SDFGI, SSIL und SSAO nicht blind im Mobile-Renderer voraussetzen. Nutze gebakene Lightmaps wo sinnvoll, ReflectionProbes, Shadow-/Light-Budget, Tonemapping, Emission/Glow, bezahlbare Wasser-/Glas-Shader, LOD, Occlusion Culling, MultiMesh/Instancing. Für Vulkan/GL Compatibility passende Shader-Fallbacks programmieren. Ziel: möglichst stabiler 60-FPS-Modus auf geeigneter Hardware; 30-FPS-Grenze nur transparent als fallback und nicht durch versteckte feste Zeitdilatation. Miss reale Frame-Times auf Zielgerät/Emulator; keine erfundenen FPS-Angaben. Regelmäßig Wärmeentwicklung, Crash-Logs, Touchflächen und Fold-Skalierung prüfen.

## C.5 SPIEL-EXPERIENCE UND GRAFIK ERGÄNZEN SICH
Nach jedem visuellen Upgrade die funktionalen Invarianten prüfen: Fahrbahn- und Collision-Kongruenz, Steuerbarkeit in der Luft, Rampen-Sprung-Landung, echtes Timing/Position, 5 Rennmodi, Gegner-KI, Boost/Item/Shield, echte Speicherstände, Sieg/Ergebnis, weiterführende Navigation und Fold-Touchtargets. Neue Details dürfen die Strecke weder visuell unlesbar noch spielerisch unfahrbar machen. Implementiere die Features in echten Godot-Szenen/GDScript, nicht nur als erzählte Teststory.

## C.6 LIVE-SCREENSHOTS UND UNMITTELBARES NUTZER-REVIEW
Das frühere LIVE-SCREENSHOT-PROTOKOLL gilt wörtlich, verschärft für große Grafikjobs:
- Start: Originalbild + aktuelles Godot/Flutter VORHER.
- Bei jeder sichtbaren Änderung und ungefähr alle 10–15 Minuten aktiver Grafikarbeit mit darstellbarem Fortschritt: echter Laufzeit-NACHHER-Screenshot, möglichst mehrere Frames für fahrende Kamera/Animation. Einzelbilder direkt öffnbar, Side-by-Side zusätzlich.
- **Nicht erst nach Build und nicht nur Collagen/ZIPs**. Eingebettete Vorschaubilder im Perplexity-Chat plus dauerhafte GitHub-Dateilinks (oder korrekt zugängliche CI-Artifacts).
- Fortschrittsmeldung nennt Kamera, feste Seed/Welt, Auflösung, Renderer, Branch/SHA, exakte Veränderung, offene Abweichung, Teststatus und verbrauchte/erwartete Credit-Kosten, soweit messbar.
- Wenn der Nutzer etwas beanstandet, sofort Arbeit an diesem visuellen Bereich pausieren, Korrektur vornehmen, neue Runtime-Bilder zeigen; nur unabhängige Aufgaben weiterarbeiten.

## C.7 CREDIT-BUDGET- UND LIZENZDISZIPLIN
Bilde zuerst einen Arbeitsplan und Prioritäten, aber **beginne nach Baseline ohne weitere Routinefragen direkt**. Tool-Routing nach Zweck, nicht Prestige. Vor teuren Bild-/Video-/3D-Generierungen den konkreten Asset-Bedarf nachweisen und vorhandene Originale/Assets wiederverwenden. Billige Modell-Tasks für Routinecode, fokussierte teurere Analysen nur für echte Engpässe. KI-Vorschauen zunächst in geringer Auflösung und kleinem Batch, hochauflösende finale Produktion nach Art-Review. Cache Zwischenergebnisse/Buildtools/Texturen, vermeide identische Wiederholungsjobs. Nicht mehrere parallele Build-/Renderjobs ohne Anlass auslösen. Reporte gemessenen Creditverbrauch und verbleibende Credits, wenn die Plattform dies zuverlässig zugänglich macht; **niemals Abrechnung erfinden**.

**Keine Käufe:** Für Autodesk Maya/3ds Max, Maxon ZBrush, Adobe Substance, SideFX Houdini, SpeedTree, Gaea, World Machine, Marmoset, kostenpflichtige 3D-Generatoren oder Cloud-GPU-Laufzeit niemals kostenpflichtige Lizenzen, Trials mit Zahlungsmethode, Konto-Neuanlagen oder externe Zahlungen ohne separate Nutzerfreigabe auslösen. Nutze zunächst Blender, Godot, Krita, GIMP, Inkscape und frei verwendbare Asset-Generatoren. Ein Lizenzname ist kein Beweis für automatisierbare Installation. Beachte Lizenzbedingungen für kommerzielle Apps, Kinderinhalte und Redistribution.

## C.8 MEILENSTEINE, VERIFIKATION, LIEFERGEGENSTÄNDE
M0: Tool-Inventar + echter alter Screenshot + Referenzen + Repo-SHA + CI-Situation.
M1: Hochwertige Menü-Hero-Ansicht (Lumo-Gesicht/Kart/Podest, alle fünf Modi auf Fold) + echtes Vorher/Nachher.
M2: Sonnenhafen-Spielstrecke mit Landmarken, Licht, Kart-Handling und 2–3 nachvollziehbar durchgespielten Runden; Screenshots und Kurzvideo/GIF soweit tatsächlich herstellbar.
M3: Rampen/Looping/Air-Steer/Boost + 3D-VFX + Fahrphysiktests + Bildvergleich.
M4: Ergebnis/1.-Platz-Lorbeer, Garage/Stats und Audio + Fold + Screenshots.
M5: Styles für Cards/Bauwelt/4 Gewinnt ohne Lern-App-Regressions.
M6: Flutter/Godot/Android volle Tests, tatsächlich installierte und gestartete APK, GitHub-Artefakt und protokollierte verbleibende Grafikabweichungen.

In jedem Meilenstein sichtbare Nutzerkontrolle: Referenzlink, VORHER-Link, NACHHER-Link, VERGLEICH-Link, Commit und Screenshots aus echten Runtime-Fenstern. Release nur als 'fertig', wenn die Funktion vollständig läuft, keine großen unkorrigierten Abweichungen zum gewünschten Stil verbleiben, die Interaktion auf Fold nicht abgeschnitten ist und die Android-Installation verifiziert wurde.

**SOFORT AUSFÜHREN:** Tool Capability Inventory, GitHub-Status und echten Kart-Menü-Vorher-Screenshot ermitteln, direkt zeigen, einen markentreuen 3D-/HUD-Fix implementieren und das erste Nachher-Bild zur Nutzerkontrolle ausgeben.