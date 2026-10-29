# LUMO NEXT GEN 2026 – VERBINDLICHER CODEX-/ASTRA-GRAFIK- UND 3D-PRODUKTIONSAUFTRAG
**Stand:** 20.10.2026 · **Auftrag:** Umsetzung, nicht bloß Beratung · **Eigner:** Heinz · **Priorität:** Original-Lumo + echte Funktion + wiederaufnehmbare Arbeit

## 0. ZIEL UND VERBINDLICHE GRENZEN
Arbeite als Principal Flutter/UI Engineer, Godot Technical Artist, 3D/UI Art Director, Accessibility- und Android-Performance-Engineer. Du veredelst die **bereits funktionierende Lumo-Lern-App** und das **Lumo-Kart-Hauptmenü** durch eine konsistente, markentreue grafische Umsetzung der beigefügten Referenzbilder. Dies ist ausdrücklich **kein Rebuild der Lernlogik, keine neue App und kein Redesign in fremdem Stil**.

Absolute Identitätsregeln:
- **LUMO IST EIN ORANGE-WEISSER FUCHS**, kein menschliches Kind und kein beliebiger generischer Fuchs. Original: große freundliche Ohren, große Augen, flauschiger orange-weißer Schwanz, **blaue Piloten-/Fliegerbrille**, dunkelblaue Jacke mit leuchtenden Cyan-Details und „L“-Emblem. Gleiche originale Figur in Lernen, Kart, Story, Quiz, Hilfe und Avatarleisten.
- Orientierung an den *echten vorhandenen App-Assets und Screenshots* hat Vorrang vor Abweichungen in KI-Entwürfen. Wenn KI-Mockup Lumo, Text, Figur, Alter, Fortschritt, Mathematik oder Navigationsstruktur fehlerhaft darstellt: **Originalfigur, echte Daten, geprüfte UX und richtige Antwort gewinnen**.
- Existierendes Layout als Grundgerüst: nachtblaues Universum, Cyan/Blau und Gold als Markenakzente, gerundete dunkelblaue Panels, lesbare Typografie, Sterne, LUMO-Logo, bestehende Start/Lernen/Spielen/Tests/Profil-Navigation. Neonglanz und Tiefe hinzufügen – keine Produktidentität austauschen.
- Nicht die vollständigen UI-Screenshots als flache klickbare Hintergrundbilder missbrauchen: Hintergründe, Figuren, Story-Szenen, nicht-interaktive Ornamente und Illustrationen sind Grafiken; Texte, Antwortmöglichkeiten, Buttons, Barrierefreiheit, XP, Timer, Freigaben, Fokus, Hitboxen, Hover/Tap/Pressed und Navigation sind **echte Flutter-/Godot-Elemente**.
- Vorhandene Screens, Spielmodi, APIs, Schreibtrainer, Journal, Nutzerprofile, Lernstände, XP, Mehrfachversuche, Belohnungen, Elternfunktionen, Offline-Verhalten, Datenschutz, Authentifizierung, Vorlesefunktionen und Tests vollständig erhalten. Keine heimliche Inhaltskürzung.

## 1. ZUERST IST-ZUSTAND PRÜFEN: KEINE ALTEN BRANCHES ÜBERSCHREIBEN
Repos:
1. https://github.com/Ullmann27/lumo-lernen – Flutter/Android, APK-Integration, Screens und Design-System
2. https://github.com/Ullmann27/lumo-godot – Godot 4.6.3, Kart, 3D-Assets, Menüs

Am 20.10.2026 sichtbar: App-PR #389 „Premium-Navigation Home/LIVE/Mirror/Cosmos/Quest“, gestapelte App-PR #390 „zweiter Lernversuch“, und Godot-PR #108 Qualitätsprüfung. Alle PRs/Branch-Heads sind **Momentaufnahme, keine Merge-Freigabe**. Recherchiere jetzt selbst die tatsächlichen jüngsten Heads, neueren PRs, Änderungen der Start-/Lernnavigation, Pinnings, Design-Dateien und Build-Skripte. Beachte: #390 baut auf #389 auf, nicht umgekehrt. Die aktuellste zugängliche funktionale Basis bewahren. Schreib-/Arbeitszweig NIE per force-push, Arbeit nicht in main überschreiben.

Bekannte Suchanker, **nicht blind als aktuell vorgeben**: 
- App: lib/app/app_shell.dart; lib/widgets/design/lumo_design_system.dart; lib/features/story; lib/features/games; assets/lumo_design/fox; assets/lumo_design/gameplay; pubspec.yaml; config/godot-source.json; CODEX_START.md.
- Kart: project.godot; scenes; scripts; assets; docs; CODEX_START.md. Godot-Menüskript und aktive MainScene zuerst über SceneTree/Projektdateien finden, nicht erraten.
- Prüfe bestehende 3D-Referenzfigur/Texture/GLB/PNG auf Echtheit, Wiederverwendung und Lizenz. Vorhandene originale Sprite-/Render- und Godot-Modelle als Source of Truth.

## 2. BILDREFERENZEN UND ASSET-WORKFLOW
Verzeichnis für autorisierte Referenzbilder: docs/design/lumo-nextgen-2026-10-20/references/
Verzeichnis für den verbindlichen Auftrag: docs/design/lumo-nextgen-2026-10-20/
Die Bildvorlagen zeigen **Soll-Gestaltung**, keinen beweisbaren Ist-Produktstand. Die in dieser ChatGPT-Sitzung erzeugten Original-PNGs müssen bei verfügbarer Original-Datei in den Referenzordner eingebracht werden; wenn ein Original nicht vorhanden ist, *NICHT* behaupten, es sei im Repository. Starte dann mit vorhandenen Original-Lumo-Assets; nutze eine dokumentierte Ersatzreferenz, bis das Bild verfügbar ist. Kein Pixel-skalierter Screenshot als finale Oberfläche.

**Zielscreen-Katalog (mindestens):**
1. Start-/Dashboard-Politur: „Lumo Lernabenteuer im Sternenhimmel“, echtes Hallo-Profil, echte XP, Hauptaktionen, bestehende Navigationsstruktur. Direkte Fortsetzung der neu vereinfachten Home-UX aus PR #389, **nicht zu vielen Kacheln zurückkehren**.
2. Lernwelten/Fachwahl: „Magische Lernwelt mit Lumo Fox“ bzw. „Lernwelt“ mit fünf Themenwelten; reines Rendering über der echten Fach-→Themen-→Aufgabe-Navigation, kein zusätzlicher erzwungener Klickpfad.
3. Deutsch / Leseabenteuer: „Lumo und die geheimnisvolle Sternenuhr“, Storybühne im magischen Archiv, unveränderte Geschichte aus dem Datenmodell, Absatzlesbarkeit, echte Vorlesetaste.
4. Sachunterricht / Jahreszeiten: „Lumo Jahreszeiten Quiz mit Fuchs“ – Vierbildkarten mit klaren Jahreszeitenbildern, Text und richtiger Lösung aus dem vorhandenen Aufgabenmodell.
5. Tests / Quizshow: „Lumo Meister magisches Quiz Abenteuer“ – Showbühne, Lumo am Moderatorpult, erreichbare Joker soweit bestehend, 4 sichtbare Antwortfelder, Feedback/Ergebnis/Weiter.
6. Profil/Avatar: „Lumo Avatar Studio im Zauberstadt Look“ – echtes Lernprofil, echte Avatar-/Figurenauswahl, Lumo bleibt der Fuchs, Avatar-Kind ist Benutzeravatar und DARF nicht Lumo ersetzen.
7. Eltern-/Fortschrittsbereich: „Leuchtendes Lumo Eltern Dashboard im Sternenhimmel“ – echte Daten oder sauber gekennzeichnete Empty States, keine erfundenen Charts, korrekter Elternzugang und Berechtigungen.
8. KI-/Sprachlernhelfer: „Magisches Lumo Lernabenteuer bei Nacht“ – Mikrofon, wirkliche Aufnahmezustände (bereit/hört/erkennt/verarbeitet/spricht/Fehler/kein Mikro), Audiowelle an Pegel nur wenn technisch vorhanden, keine falsche „KI funktioniert offline“-Behauptung.
9. Mathe-Abenteuer: „Magisches Mathe Abenteuer mit Lumo“ (vorhandene Referenz vom vorigen Satz) – begehbar wirkende Zahlensteine/Glas, Frage/Antwort/Feedback mathematisch korrekt, zweite Chance nicht zerstören.
10. **LUMO KART NEUES HAUPTMENÜ**: „Lumo Kart Neon Rennspaß am Sonnenhafen“ – zwingend hohes Produktionsziel: aktuelles Godot-/Flutter-Menü wirklich ersetzen/überarbeiten, nicht nur ein statisches Werbebild. Original Lumo als Fahrer im existierenden Kart, Sonnenhafen-Kulisse aus echten eigenständigen Assets; Hauptaktionen Grand Prix, Zeitrennen, Sonnenhafen, Garage, Einstellungen und sinnvoller Start, soweit tatsächliche Modusimplementierung besteht.

Optionale zusätzliche Referenzen: „Lumo Lernabenteuer bei Nacht“, „Magisches Lumo Lernabenteuer bei Nacht“, „Lumo und die Sternenkarte“, „Lumo Meister Quiznacht im Sternenglanz“, „Lumo Lernabenteuer im Sternenhimmel“.

## 3. WIEDERVERWENDBARES PREMIUM-DESIGNSYSTEM – ZUERST BAUEN, DANN 10 SCREENS
Baue keine zehn unabhängigen UI-Implementierungen. Erstelle/designiere Token und wiederverwendbare Flutter-Widgets samt Godot-Theme-Parität:
- Farb-Tokens (Nachtblau, Tiefblau, Cyan, Türkis, Warmgold, Weiß, positive Grün/negative Rot nur wenn didaktisch korrekt, ausreichender Kontrast).
- Design-Tokens für Schatten, Glow, transparente Flächen, Konturen, Abstände, Rundungen, Textebenen, Fokusindikatoren, pressed states, deaktivierte Schaltflächen und Motion-Profile; keinerlei teure dauerhafte Shader-Berechnungen ohne Profilgrenze.
- Wiederverwendbare GlassCard / LumoHeroStage / MainAction / LearningSubjectCard / AnswerCard / ProgressRibbon / LumoSpeechBubble / StarBurst / VoiceVisualizer / StoryPanel / KartMenuTile und passende Godot-Controls. Existierende Widgets *erweitern* statt duplizieren.
- 3D-Look über geschichtete 2D-Assets, 2.5D-Parallaxe und gezielt vorhandene echte 3D-Szenen; **kein schwerer Echtzeit-3D-Renderer für jede Flutter-Textkarte**. Fuchs-Rig nur nutzen, wenn real vorhanden und gemessen; ansonsten animierbare Layer (Kopf, Pfote, Blinzeln) aus originalen Assets, ohne Identitätsabweichung.
- Alle Beschriftungen und Fortschrittsdaten sind Flutter-/Godot-Text, kein im Bild eingebrannter deutscher Text. Referenz-Texte wie „Mia“, „0/400 XP“, „5000 Sterne“, „Welche Farbe hat das Gras?“ sind nur Beispiele und NIE hartcodierte Nutzerdaten.
- Echte Bilder/Animationen technisch freigestellt: WebP/PNG-Alpha für Fuchs, Kulissen als WebP/AVIF nur sofern Flutter/Android tatsächlich unterstützt, 9-patch-/Shader-/Vektor-UI, vernünftige Assetgrößen, korrekt deklarierte pubspec-Assets, kein Testbild oder Mockup in Release als UI-Overlay.
- 48×48 dp mindestens für alle Touchflächen; fold/Tablet/normaler 360–430 dp Phone, Landscape für Kart, Großschrift/Textskalierung, TalkBack-Semantics, reduced motion, niedrige GPU-/Akku-Last, Offline-Navigation.

## 4. KONKRETE UX- UND VISUAL-AUFGABEN
**Home:** Dunkle Sternenlandschaft als ruhig animiertes Hintergrundlayer, Original-Fuchs als gewohnte Figur, leichte Buch-/Schwanzbewegung, Cyan-Hauptbutton, dynamische kindgerechte Begrüßung; neue Zwei-Hauptaktionen-UX aus #389 respektieren. Sekundäre Lernrubriken sollen erreichbar, aber nicht alles gleichzeitig überladen sein.

**Lernwelt:** Die Fachwelt darf hinter der 2-stufigen echten Lernnavigation als große Illustration erscheinen. Vier Kernfächer sofort leicht erkennbar; Englisch/kreative Bereiche unter „weitere Bereiche“. Klare Kapitel-/Themenzuordnung, echte Empfehlungen, keine Pseudo-Karten ohne Aktion. Animation von Inseln/Sternpfaden nur bei sichtbarem Bereich und reduziert bei Low-Profil.

**Mathe:** 3D-Glassteine und dekorative magische Ziffern, echter aktiver Recheninhalt vorne lesbar. 2-Versuche-Didaktik aus #390 beibehalten: nach erstem Fehler Hilfestellung, dann erneuter Versuch; nicht vorschnell Lösung oder Sternbelohnung ausgeben. Reaktionszeit begrenzen, Feedback darf die Antwort nicht verdecken.

**Deutsch/Story:** Lesekarte wie auf Referenz, Lumo in einer variierenden Szene zum Kapitel, authentische Story-Textquelle, Vorlese-Button mit echtem Status; korrektes Umblättern, Kapitel-Speicherstand, Textskalierung. Illustrationen müssen zur aktuellen Geschichte passen, Fuchs/Pose konsistent. Nicht die vorhandene Story-Engine ersetzen.

**Sachunterricht/Jahreszeiten:** Illustration von Frühling/Sommer/Herbst/Winter und große transparente Antwortfelder; pädagogisch zutreffende, abwechslungsreiche Aufgaben. Bei Winter/Dezember kultursensibel und ohne verwirrende ikonografische Zuordnung. Das Lernmodell bestimmt richtig/falsch.

**Tests/Quizshow:** Moderatorenbühne mit der echten Lumo-Figur und heller vierfarbiger Antwortarena; die korrekte Antwort nicht vor Auswahl hervorheben. 50:50 / Publikum / Lumo-Tipp nur aktiv, wenn Implementierung existiert; sonst gar nicht oder sauber deaktivieren. Stage VFX nach richtigem Ergebnis kurz und GPU-sparsam.

**Profil:** Das Nutzerprofil kann menschliche Avatare besitzen; Lumo als Fuchs bleibt Assistent. „Profil“/„Eltern“ sind verschiedene Rollen. XP/Abzeichen/Streaks nur aus echten Stores. Avatare freischalten nur vorhandene Berechtigungen und Besitz prüfen.

**Elternbereich:** ruhigere seriöse Hierarchie, Datenvisualisierung ohne erfundene Werte, echte Klassen- und Lernzeitdaten, elterliche Sperren/Einwilligungen bewahren. Keine Belohnungs-/Kaufirreführung.

**KI-Stimme:** fesselnder Voice-Visualizer, aber Audiobalken müssen wirkliches Mikrofon-/Sprachausgabe-Signal bzw. explizite Animation des Zustands anzeigen, niemals generische Wellen bei Stille als scheinbaren Live-Beweis. Klare Fehler- und Permission-Fälle, Textalternative. Kein Cloud-/API-Feature implementieren, das nicht beauftragt ist.

**Belohnungen/Tests/sonstige Rubriken:** visuellen gleichen Qualitätsstandard über ALLE bestehenden sichtbaren Routen tragen; die 10 Zielbilder sind Prioritätsliste, keine Erlaubnis, übrige Bildschirme inkonsistent zu lassen. Visuell fehlende Screens über wiederverwendbare Tokens harmonisieren, ohne fremde Inhalte zu erfinden.

## 5. LUMO KART – HAUPTMENÜ WIRKLICH ZUM HIGH-END-PRODUKT AUFWERTEN
Das aktuelle Kart-Menü benötigt einen eigenständigen **realen** Designumbau. Das Referenzbild zeigt Zielqualitäten: ruhige Sonnenhafen-Abendstimmung, glaubwürdige Brücken/Wasser/Strecke, großer eigener Fuchs im blauen/goldenen Kart, hellgoldener Start-CTA, Cyan-Karten, Pokal/Zeitrennen/Garage/Einstellungen, visuelle Tiefe. **Nicht Nintendo-Figuren, Mario-Kart-Grafiken, Strecken, Logos oder Musik kopieren.** Eigenständige Lumo-Marke, gleiche Spielfreude.

Technischer Umsetzungsweg:
1. Projekt-Einstiegsszene, Hauptmenü-Script, vorhandene UI-Szene, Player-/Kart-Modelle, Track Preview, Godot-Autoload/Qualitätsprofile identifizieren.
2. Gemeinsames Lumo DesignTokens/Theme-Konzept mit Flutter vereinbaren; Original-Kart-Modell und echtes Character-Asset bevorzugen.
3. Vor dem Umbau Screenshot vom derzeitigen Menü erzeugen. Sichtbare Overlay-Hierarchie aus Controls/Containers/TextureRects/Label/Button/ShaderMaterial oder vorhandenen Materialkonventionen zusammenbauen; Bilder sind nur dekorativer Hintergrund, Controls bleiben echte Buttons.
4. Kamerawinkel: Lumo-Kart groß und erkennbar; keine falsch perspektivierte Figur, keine fremden Gegenstände. Hintergrund darf statischer Render/2.5D sein, solange das Menü 60fps-kompatibel bleibt.
5. Fingerfreundliches Layout im Handy-Landscape und Fold-Display; Button-Hitboxen ≥48dp analog zur projektspezifischen Godot-Viewport-Skalierung. Nicht auf Menübild fixieren.
6. Jede Aktion aus dem Menü muss an eine tatsächlich bestehende Szene/einen bestehenden Modus anschließen. Fehlende nicht fertiggestellte Spielmodi nicht als spielbar darstellen. Keine neue Strecken-Gameplay-Implementierung in dieser Grafikrunde.
7. Godot GUI and 3D states beim Szenenwechsel korrekt freigeben; vor allem Low/Medium/High-Profile/Glow-State, GUI-Skalierung, Speicher, Loading und Android-Back prüfen.
8. Kein hartes Asset-Duplikat in Flutter und Godot. Wenn die echte Kart-Hauptszene in Godot liegt, Godot ist Owner. Flutter zeigt bestenfalls korrekt integrierten Launch/Handoff, nicht ein konkurrierendes zweites Menü.

**Optionaler 5-Sekunden-Intro-Effekt (nur nach Fertigstellung wichtiger Screens):**
Sekunden 0.0–0.6: Nachtblau + Sternenschweif (reduzierte Effekte).
0.6–2.2: Original Lumo-Kart rast seitlich auf einer geschwungenen Leuchtspur durch die Szene; nur vorhandenes Modell / sauberer Layer-Render.
2.2–3.5: LUMO KART Logo mit kurzer Gold-/Cyan-Aufleuchtung, freundlich gesprochener Satz „Lernen mit Spaß!“ **nur bei vorhandener zulässiger Stimme/Audiodatei**; sonst Text oder stumm, keine erfundene Sprachausgabe.
3.5–5.0: weicher Übergang in **spielbares Kart-Hauptmenü**, keine Sperrwartezeit, direkt überspringbar, reduced-motion-skip, keine volle Video-Pflicht. Falls Performance/Export-Budget: auf statisches Titelbild + kurze Tween-Animation reduzieren. Wenn Risiko für die Hauptaufgabe, jetzt nicht implementieren.

## 6. BITTE REALISTISCH INNERHALB EINER CODEX-SITZUNG ARBEITEN
Prioritäten strikt:
P0 (zuerst fertig): Verifikation aktueller App-/Kart-Basis und vorhandener Markenassets, Screenshots IST, DesignTokens + Original-Fuchs.
P1: Live-Startscreen und **Lumo Kart Hauptmenü** als echte funktionierende UI – inklusive Touchs, Smartphone/Fold/Landscape-Bildnachweis.
P2: Ein hochqualitatives exemplarisches Lernaufgaben-Template (Mathe) und ein Story-Template, an echter Aufgabe verbunden; Wiederverwendung für Tests/Sachkunde/Deutsch.
P3: Restliche Rubriken der 10 Referenzen über Shared Components, Profile/Eltern/Voice, Show-Animationen.
P4: Optionales 5-Sekunden-Kart-Intro nur wenn P0–P3 sauber und ausführbar.

Nicht behaupten „alles fertig“, wenn keine reale APK und kein Screenshot existiert. Wenn Restbudget knapp wird: nutzbare Produktionsänderungen committen, Tests protokollieren und sauber an nächste Sitzung übergeben. **Keine Zeit mit 10 weiteren losgelösten Konzepten, General-Rewrites, ungetesteten Assets oder Tutorial-Text verschwenden.**

## 7. VERPFLICHTENDER CHECKPOINT- UND RESTART-VERTRAG – UNTERBRECHBAR!
Der Eigentümer will jederzeit ohne Verlust mit einem neuen Modell/Codex weitermachen. Darum nach jedem kohärenten Arbeitspaket:
- Direkt im eigenen Arbeitsbranch committen; niemals auf große uncommittete Patches warten.
- Fortschrittsdatei docs/design/lumo-nextgen-2026-10-20/STATUS.md kontinuierlich aktualisieren (IST-Stand, Repo/Branch/HEAD, Screens abgeschlossen/Offen, erzeugte Assets mit Lizenz/Origin, betroffene Flutter/Godot-Dateien, Prüfungen mit tatsächlichem PASS/FAIL/SKIP, Screenshot-Links, bekannte Fehler, nächster *konkreter* Befehl).
- docs/design/lumo-nextgen-2026-10-20/CONTINUE.md als maschinenlesbare Wiederaufnahme pflegen, inklusive aktiver Branches, SHA, tatsächlichem Base-Pin, Testbefehlen und offenen Konflikten.
- Assets mit eindeutigen Dateinamen statt anonyme imagegen.png, Herkunft und Zielbild zuordnen. Unter docs/design/.../references Referenzen halten; produktive Assets unter bereits etabliertem assets-Baum mit Verzeichnisstruktur.
- Je Arbeitspaket Screenshots aus **echtem Flutter/Godot-Render und wenn möglich Android-Runtime**, nicht aus Bildgenerator, ablegen. Vorher-Nachher paarweise; screenshot test wenn möglich. Kein behauptetes Hardware-PASS ohne Hardware.
- Für Godot-Kart-Änderungen eigenen Branch und PR im lumo-godot-Repo; Flutter-Pin nur nach wirklich geprüftem Kart-Commit durch geplante APK-Integrationsarbeit aktualisieren. KEIN willkürlicher Pin-Update.
- Repo-PRs immer draft bis CI/Abnahme; main geschützt; kein automatisches Merge.
- Jeder Checkpoint liefert: abgeschlossener Scope, geänderte Dateien, Testresultate, nächster Schritt, PR/Commit-Link. Niemals sagen ein unerreichbares Tool hätte gearbeitet.

## 8. QUALITÄTSABNAHME – WAS ALS „FERTIG“ ZÄHLT
A. Charakteridentität: direkter Bildvergleich mit Original-Lumo; blaue Brille, Ohren, Gesicht, Schwanz und Jacke konsistent.
B. UI-Funktion: Jede primäre Karte und Starttaste führt zur richtigen echten Route, keine Dead Buttons, keine unberechtigten Modi.
C. Didaktik: Aufgaben lesen ihre echten Daten, richtige/falsche Antworten unverfälscht, zweiter Versuch, Speichern/Resume, Tests/Belohnungen erhalten.
D. Handy: Android 360/393/430 dp, mindestens ein Fold-Layout (geöffnet/geschlossen), Accessibility/Text-Scale 1.3–1.5 und Portrait-/Landscape-Screens je relevant.
E. GPU/Qualität: Build und UI-Runtime unter Low/Medium/High testen soweit möglich; Ziel flüssige 60fps auf leistungsfähigen Geräten, keine ungemessene Garantie. Particle Count, Alpha Overdraw, große Texturen, Shader Compilation, Transitions und RAM überwachen. Low-End erhält reduzierte Effekte.
F. Testreport: flutter analyze, passende Flutter/Widget/Integrationtests, Godot 4.6.3 headless tests/scene startup sofern installiert, Android build bzw. CI und tatsächliche Bildnachweise. Ergebnis genau als PASS/FAIL/SKIP begründen.
G. Originalität/Lizenz: ausschließlich eigene/autorisiert genutzte Charaktere, kein Mario-Kart-IP-Klon, keine externen Assets ohne Provenienz.
H. Teamübergabe: STATUS/CONTINUE aktuell, alle Code- und Assetänderungen versioniert, keinem Nachfolger durch lokale-only-Dateien versperrt.

## 9. ERGEBNISSE UND STARTANWEISUNG
**JETZT** echte Repositories inspizieren, Ausgangsscreenshots produzieren, einen gemeinsamen wiederverwendbaren Designkern implementieren und die ersten zwei sichtbaren Meilensteine (Lern-Start + Kart-Hauptmenü) in den passenden Projekten realisieren. Kein zusätzlicher Prompt erforderlich. Bis zur Sitzungsgrenze so weit arbeiten, wie Zeit, Rechte, Tools und Tests tatsächlich erlauben; alles versionieren und nach jedem Meilenstein die Fortsetzung sichern. Erfolg ist Code + echte Screenshots + Prüfbericht, nicht bloße Absicht.

**Richtlinie zum Bildmaterial:** Die Designreferenzen wurden in ChatGPT generiert. Beschreibungen und konkrete lokale Originaldateien sind kein Beweis für eine GitHub-Einbindung. Die Umsetzung darf sich nur auf im Repo vorhandene oder tatsächlich bereitgestellte Bilder stützen; fehlende Referenzen ehrlich in STATUS.md auflisten.