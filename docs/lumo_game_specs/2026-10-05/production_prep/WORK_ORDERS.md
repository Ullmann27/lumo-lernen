# Verbindliche Anschlussaufträge: vorhandene Arbeit nutzen

## Gemeinsamer Arbeitsrahmen

Lies zuerst `README.md`, `render_contract.json`, die Bildreferenzen und die aktuellen Issue-/PR-Kommentare. Jede Zahl in diesem Plan ist entweder Bildinhalt oder ausdrücklich technische Testvorgabe, niemals Produktionspreis oder Freischaltschwelle. Technische Vorschläge sind prüfbare Arbeitsannahmen und dürfen ohne Stilwechsel an den nachgewiesenen Bestand angepasst werden.

Ein aktiver Writer je Pfad; Quoten nicht durch identische Zweitsitzungen umgehen. Keine automatische Modellwahl. Keine ungeprüften Merges, kein neuer APK-Build nur für Dokumentation. Ein Modellname im Prompt ist kein Nachweis einer gestarteten Sitzung. Bei fehlenden Tools/Modellen konkret BLOCKED melden und unabhängig davon mögliche Arbeit fortsetzen. Fehlende Antworten sind keine Freigabe.

## A — Claude Sonnet 5.5 / Lumo Learning Sonnet / lumo-lernen #172

**Jetzt ausführen, nicht einen weiteren Gesamtplan schreiben:** Prüfe read-only den vorhandenen Weg von bestätigtem Lernabschluss zu persistentem Profilfortschritt und Spielberechtigung. Verwende reale Call-Sites, vorhandene Tests und den bestehenden Repository-/Wallet-Code. Nimm die offenen Reading-/Writing-/Adventure-Beiträge #184/#185/#187 nicht als bereits gemergt an; deren Dateien ohne Übergabe nicht ändern.

Erstes Ergebnis: ein testbarer, kleiner Vertrag für die Oberfläche. Die UI benötigt: stabile Profil-ID, dauerhaft berechtigte Spiele, tatsächlichen Freischaltgrund, aktuellen Speicherzustand, bestehenden Sternsaldo. **Keine erfundenen Produktionsschwellen.** Lernfortschritt und ausgegebene Währung getrennt halten. Bereits erteilte Berechtigungen bleiben bei Sterneausgabe erhalten. Fehlende Konfiguration muss klar angezeigt werden statt eine fiktive Bedingung zu zeigen.

Testfälle für den kleinsten anschließenden Claim: Offline-Neustart; zwei Kinder; Namens-/Klassenwechsel; doppeltes Lernereignis; Sterneausgabe; Speicherausnahme; alter Spielstand. Namen/Klassen nicht als stabile Identität voraussetzen. Migration muss bestehende Daten erhalten. Änderungen erst nach echter unabhängiger Gegenprüfung und genauer Dateiliste; keine UI-Neugestaltung und kein neuer paralleler Fortschrittsdienst.

An Luna übergeben: exakte vorhandene/vereinbarte Schnittstelle und Test-SHA. Sonnet darf das domänenseitig vollständig abschließen, sofern reale Tests es tragen; ein späterer Opus-Einsatz ist kein Vorwand, überprüfbare Arbeit unvollständig zu lassen. TTS/Lesen/Schreiben danach als separater Block, nicht gleichzeitig mit dem Grafikumbau.

## B — Lumo UI Luna / GPT-5.6 Luna / lumo-lernen #175

Read-only zuerst #186 und #187 an `learning_content.dart` gegeneinander prüfen. Bestehende #188-Bilddateien nicht neu importieren. Echte UI-Elemente aus dem Board bauen, nicht unsichtbare Touchflächen über ein Poster. Spielportale, Text, Fokus, Sperrstatus, zurück zur Lern-App bleiben echte Widgets und beruhen auf dem Sonnet-Vertrag. Dekorative Key-Art darf dekorativ sein.

Erster konkreter Bildschirm: Spielewelt mit denselben Farben, Lichtgewichten, Fuchsproportionen und Cyan-Glasportalen. Referenzgetreue Gestaltung ohne feste Beispielnamen/XP/Preise. Verfügbare und noch nicht implementierte Spiele ehrlich unterscheiden. Kein unangefragter Wechsel der Spielauswahl oder Warenwirtschaft.

Abnahmefälle als **synthetische Layoutvorgaben**, nicht physische Fold7-Nachweise: 393×852 dp, 840×700 dp und beide mit 1,4-facher Schrift. Safe Areas, Zurücknavigation, echte Beschriftungsbreiten und Touchflächen testen. Physische Fold7-Aufnahmen gesondert. Eltern-/TTS-/Datenschutzoptionen nicht verändern.

## C — Lumo 3D Codex / GPT-5.3-Codex / lumo-godot #10

**Konkrete Startkorrektur:** Nicht mit einer zweiten generischen Character-Foundation beginnen. Der gelesene Kart-Kandidat hat bereits echte prozedurale Geometrie und Gelenke. Jump lädt eine bestehende Character-Szene mit öffentlicher API. Ein fehlendes GLB bedeutet nicht, dass keine nutzbare 3D-Basis vorhanden ist.

Zuerst read-only den tatsächlichen Szenen-/API-Pfad nachweisen. Dann in einem konfliktfreien, kleinen Claim eine isolierte Abnahmeszene vorbereiten: vorhandene Figur, neutraler Boden, referenzgerechte Mond-/Cyan-/Laternen-Lichtrollen, Orbitansichten und benannte Zustände. Keine neue Figur erfinden, keinen Kart-Code überschreiben. Kontrollierte Kamera darf eine technische Testszene sein, darf aber nicht als finales Spiel verkauft werden.

Der Visual-Adapter erhält `play_behavior`, `set_eye_state`, `set_brow_state`, `set_mouth_shape`, `start_speaking`, `stop_speaking`, `get_current_behavior`. Aktueller `jump_hop` ersetzt nicht `jump_start → air → fall → land`. Vorhandene Tween-Aliase nicht löschen, bevor alle Nutzer nachvollziehbar migriert und getestet sind.

Falls ein qualitätsgerechtes geriggtes Asset verfügbar ist, tatsächliche Datei, Import, Skelett, Clips, Deformation und Rechte prüfen. Sonst das offene Art-Gap präzise benennen, aber Kamera, Inputvertrag, Speicher-/Navigationsprüfung und Messszene nicht unnötig blockieren. Prozedurale Zwischenfassung bleibt als solche markiert. Kein Sprite-Flipbook als frei drehbaren Charakter ausgeben.

## D — Fahrzeug-/Strecken-Art für Opus später / lumo-godot #6/#4

Verbindlich bleibt `docs/DESIGN_ZIEL_KART_2026-10-04.md` auf Flutter-SHA `89bebcb09995a6eed64038c5445c33a08f8eca5c`. `k10_kart_uebersicht.png` ist Fahrzeug-/Fuchs-/Lichtreferenz; `k02_welt_bausteine.png` Bausteine; `k03_gameplay_elemente.png` Spielobjekte. `k01_garage.png`, `k08_cup_streckenauswahl.png` und `k09_modus_waehlen.png` binden die Menüs. Die Dokumentation regelt ausdrücklich, welche Lern-Boost-Banner und Lerntore entfallen.

Fahrzeugarbeit getrennt von Physik: gleiche Kamera/FOV, Silhouette vorne/seitlich/hinten, Radstand/Radgröße, Karosseriewölbung, Scheibe, Scheinwerfer/Cyan-Emission, Sitzhaltung, Hände am Lenkrad, Reifenrotation, Federung und Karosserie-Neigung. Erst Referenz-Vergleich bei stillstehendem Kart, danach Lenken/Drift/Boost, ohne Checkpoints/Kollision/ACK zu brechen. Maße aus den Bildern sind nicht technisch vermessen; vor Festlegung kalibrierte Referenzkamera und einheitliche Skalierung dokumentieren.

Welten: Wissenswald/Bibliothek, Lichterstadt, Wasserfallklippen, Himmelsinseln; vorhandene vollständige Runde erhalten. Eine Strecke optisch fertigstellen, dann aus demselben Baukasten erweitern. Wetter, volumetrische Effekte und echte Echtzeitreflexionen nicht pauschal erzwingen: Look ist verbindlich, konkrete Rendertechnik nach vorhandenem Backend/Profiling wählen. Bücher dürfen Kulisse sein, Lernfragen/-Cups/-Antworttimer/Richtig=Turbo nicht.

Bekannter `kart_vehicle_regression`-Vorbefund bleibt offen, bis er mit SHA/Logs reproduziert, unabhängig geprüft und von genau einem Reparateur behoben ist. Keine Testabschwächung als Grafikfortschritt verkaufen.

## E — Unabhängige Prüfungen und spätere Opus-Übergabe

#176 prüft echte Runtime-Bilder gegen die Referenzen; Godot #11/#12 erst bei tatsächlichem Kandidaten. Integration #189 prüft den akzeptierten Godot-SHA und das tatsächlich exportierte PCK. Vor Übergabe alte/aktuelle Claims erneut lesen. Keine neue gemeinsame Wallet/kein zweiter Fortschrittsdienst.

Die Aufgabenverteilung ist eine Arbeitsaufteilung, kein belegter Modellvergleich. Berichte sachlich, was jedes Modell real geliefert hat. Opus erhält später nur offene, benannte Art-/Rig-/Animations-/Integrationspunkte und soll bereits akzeptierten Code nicht neu schreiben.

Übergabeformat pro Block:

```text
ROLE / ACTUAL MODEL EVIDENCE:
BASE SHA / RESULT SHA:
CLAIMED FILES / RELEASED CLAIM:
EXISTING API PRESERVED:
REFERENCE PATHS / HASHES:
RUNTIME FILES / CAPTURE ORIGIN:
COMMANDS / PASS / FAIL / SKIP:
VISUAL GAPS:
DEVICE / FRAME-TIME P50 P95 P99 / NOT EXECUTED:
FOR SONNET:
FOR LUNA:
FOR OPUS LATER:
```

Prüfaufnahmen müssen Zustandswechsel zeigen: Atmen/Blinzeln reicht nicht als Nachweis für Lauf-/Sprungqualität. Physikwerte und Animationstempo verbinden, kein Root-Motion plus doppelte Controllerbewegung, kein sichtbares Foot Sliding. Kameraumrundung muss räumliche Rückseite zeigen. Standbild kann weder flüssige Animation noch 60 FPS beweisen.
