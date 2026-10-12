# Lumo 1934 – begrenzter Branch- und Asset-Abgleich

Stand: 12. Oktober 2026. Read-only-Audit gegen genau diese freigegebenen Quellen:

- Flutter: `91fc9e25b338bf593d7d17431e4c7aec895cec24` in `/workspace/lumo-games-1934`.
- Godot: `853175c634dcb62c325fbd9b272e2ebc791830ad` in `/workspace/lumo-kart-fold`; derselbe Wert steht im Flutter-Pin `config/godot-source.json`.
- GitHub: aktuelle offene PRs beider Repositories; vertieft die 17 angeforderten PRs sowie die besonders relevante Asset-PR #183 und Referenz-PR #248. Alte Jump-/Avatar-Alternativen wurden nur gezielt eingeordnet.

Methodik: GitHub-API-Metadaten und Dateilisten, lokale Commit-/Ancestry-Prüfung ohne Fetch, Vergleich der GitHub-Head-Blob-IDs mit den gepinnten Git-Bäumen, gezieltes Lesen vorhandener Laufzeitpfade und Art-/Lizenznachweise. Bei Godot #23 und Flutter #183 wurden sämtliche API-Dateiseiten berücksichtigt. Keine Codeänderung, kein Merge, kein Workflow, kein Provider-Auftrag und keine erneute Testsuite. Die einzige neue Datei ist dieser Bericht. Die parallele Kart-Menü-/Garage-Touchreparatur gehört nicht zu diesem Audit.

**Ergebnis:** Die vier nativen Kreativspiele und die neuere Kart-/Animationskette sind vorhanden. Die größten tatsächlichen Integrationslücken sind 142 vorhandene Originaltafel-Crops aus Flutter #183, einzelne Cards-Grafikänderungen aus #230 und noch nicht produzierte Gegner-Assets. Ein nicht vorhandener PR-Head im lokalen Git wurde ausdrücklich nicht als fehlende Umsetzung gewertet.

## Angeforderte PRs

| Quelle / Head | Einstufung am freigegebenen Baum | Konkreter Nachweis / Integrationsentscheidung |
|---|---|---|
| Flutter [#260](https://github.com/Ullmann27/lumo-lernen/pull/260), `7d33604e` | **Äquivalent enthalten** | Alle sechs Marktstart-Dokumente haben exakt dieselben Blob-IDs. Enthält Planung, keine implementierte Kaufabwicklung. Nicht erneut übernehmen. |
| Flutter [#258](https://github.com/Ullmann27/lumo-lernen/pull/258), `7cb18f10` | **Tatsächlich fehlende Übergabe; kein fehlendes Spiel** | Drei Handoff-Dokumente und `tools/upload_lumo_kart_assets.sh` fehlen. Der PR selbst enthält keine ZIPs und keinen Spielcode. Zehn inventarisierte 4K-ZIP-Bände sind unter `/workspace` nicht vorhanden; 4K-Bilder wären Referenzen, keine 3D-Modelle. |
| Flutter [#256](https://github.com/Ullmann27/lumo-lernen/pull/256), `5d7a675b` | **Enthalten** | Head ist Vorfahr. Cards-Querformat, 48-dp-Aktionsflächen, Turn-/Table-Widgets und Layout-Regression liegen im Baum. Neuere Layoutarbeit beim Übertragen älterer Grafik erhalten. |
| Flutter [#255](https://github.com/Ullmann27/lumo-lernen/pull/255), `1dd6a3f7` | **Historische Implementierung enthalten, später weiterentwickelt** | Head ist Vorfahr; Client-/Proxy-Dateien und Sprachumstellung sind vorhanden. Spätere freigegebene lokale Stimme ist maßgeblich; diesen älteren Gesamtstand nicht zurücksetzen. |
| Flutter [#253](https://github.com/Ullmann27/lumo-lernen/pull/253), `b2882f46` | **Äquivalent enthalten** | Alle sechs geänderten Runtime-Dateien plus neuer Ink-Surface-Test sind bytegleich. Nur der weiterentwickelte Wortfortschrittstest unterscheidet sich. Keine Schreibreparatur fehlt. |
| Flutter [#247](https://github.com/Ullmann27/lumo-lernen/pull/247), `790ad36f` | **Tatsächlich fehlende Designunterlagen; visuelle Umsetzung teilweise offen** | Drei editierbare SVGs für Cards/Build/Vier gewinnt und der Auftrag fehlen. Sie sind ausdrücklich Konzeptszenen. Die Spiele selbst existieren; Vier-gewinnt-Weiterentwicklung aus #249 ist enthalten. SVGs sind Vergleichsgrundlage, kein fertiges Runtime-Asset. |
| Flutter [#245](https://github.com/Ullmann27/lumo-lernen/pull/245), `b39ed83b` | **Durch neuere Integration ersetzt** | Nur Workflow, Versionsnummer und älterer Godot-Pin geändert. Aktueller Pin enthält die spätere #57-Kette. Alten Pin/Versionscode nicht zurückbringen. |
| Flutter [#232](https://github.com/Ullmann27/lumo-lernen/pull/232), `b41cfc54` | **Enthalten** | Head ist Vorfahr; Denkprofil-/Datenschutzaudit und Runtime-/Testdateien vorhanden. |
| Flutter [#231](https://github.com/Ullmann27/lumo-lernen/pull/231), `9b6127f3` | **Titelverhalten äquivalent, alter Stil/Test fehlt** | Aktueller ScoreHeader zeigt `Lumo Cards`, nutzt `LayoutBuilder` und trennt unter 320 px Aktionen in eine zweite Zeile; 48-dp-Flächen bleiben. Älteres Hologlas-/Brand-Testfile fehlt. Kein Beleg für fehlenden Titel aus bloßer SHA-Abwesenheit. |
| Flutter [#230](https://github.com/Ullmann27/lumo-lernen/pull/230), `fa9f5557` | **Teilweise tatsächlich fehlende Grafik** | Aktueller Cards-Intro hat weiterhin violetten Hintergrund und keinen `fox_cards_welcome`-Einsatz; Header ohne Original-Fuchsavatar; Ablage-Leerfläche beige, Ziehstapeltext braun. Vierstufiger Glass-Gradient und zugehöriger Capture-Workflow/Test fehlen. Einzelne Farblabel-/Lesbarkeitskorrekturen existieren bereits. Grafik selektiv übernehmen, neuere Layout-/`surfaceOpacity`-Schnittstellen bewahren. |
| Godot [#47](https://github.com/Ullmann27/lumo-godot/pull/47), `f672e02c` | **Enthalten** | Head ist Vorfahr; Lifetime-/Renderer-/Hero-Implementierung und Nachweise vorhanden. |
| Godot [#46](https://github.com/Ullmann27/lumo-godot/pull/46), `ff67107c` | **Enthalten** | Head ist Vorfahr; Glas-Shader, Neon-Gates, Environment-Polish und Tail-Adapter vorhanden. |
| Godot [#49](https://github.com/Ullmann27/lumo-godot/pull/49), `08767330` | **Enthalten** | Head ist Vorfahr; Blender-Roundtrip-/GLB-/Reference-Packet-Werkzeuge vorhanden. Diese statische Exportpipeline ist nicht selbst ein neues Produktionsrig. |
| Godot [#48](https://github.com/Ullmann27/lumo-godot/pull/48), `d434f931` | **Schutz äquivalent und verstärkt; Aufnahmeproduktion offen** | Aktueller AudioManager blockiert Legacy-WAVs ohne Sulafat-Manifest, prüft SHA-256 sowie freigegebenes Modell/Profil. Vorhandener Generator ist stärker validiert als der PR-Head. Die separate Workflowdatei und das Sulafat-Manifest fehlen; die angekündigten 52 freigegebenen neuen Aufnahmen sind damit nicht auslieferbar. Keine Provider-Erzeugung in diesem Auftrag. |
| Godot [#32](https://github.com/Ullmann27/lumo-godot/pull/32), `8542c0bb` | **Enthalten** | Head ist Vorfahr; `kart_harbor_aquarium.gd`, `kart_workshop.gd` und ihre gezielten Regressionen vorhanden. |
| Godot [#30](https://github.com/Ullmann27/lumo-godot/pull/30), `7ded3f51` | **Kern äquivalent / weiterentwickelt** | Terrain-Grain-Material und Tint-Shader bytegleich; `ground_grain`/`grain_strength`, Bonnet-Lumo-Badge und Character-Finish-Verbindung vorhanden. Pauseeingabe ist inzwischen anders umgesetzt; der alte eigenständige Touch-Test und Fidelity-Text fehlen. Kein Grund, alte Fahrzeugdateien über die spätere Animation zu kopieren. |
| Godot [#23](https://github.com/Ullmann27/lumo-godot/pull/23), `329b10cc` | **Äquivalent enthalten** | Von 24 relevanten Creative-/App-Dateien sind 22 bytegleich; nur Boot/Router weiterentwickelt. Alle vier Szenen und State-Dateien existieren, ebenso gleiche Puzzle-/Sandsteinbilder. Flutter `games_content.dart:332` verbindet Puzzle/Build/Rhythm/Treasure mit `_launch3D`; Godot SceneRouter registriert dieselben vier Szenen. |

Zusätzlich bestätigt: Flutter #257 und #249 sind Vorfahren; Godot #50–#57 und #42 sind Vorfahren. Bei Flutter #248 sind 21 von 27 nicht zum Workflow gehörenden Dateien bytegleich, darunter Originalreferenzen und Bestandsschutz; sechs spätere Gesamtprompts/Store-Dokumente fehlen. Das ist kein fehlender Charakterbestand.

Historische Flutter #37/#39/#40/#42/#43/#44/#45/#48 sind eigenständige ältere Alternativen. Die gegenwärtigen Mini-Spiel-Routen, Flame-Jump-Welt und neuere Companion-/Voice-Architektur sind vorhanden. Beispielsweise fehlt #43s alte `game_task_factory.dart`, aber die aktuelle Routingstelle nennt alle vier Mini-Spieltypen. Solche alten Gesamtbranches sind ohne gezielten Behavior-Abgleich keine sicheren Merge-Kandidaten.

## Wichtigster zusätzliche Asset-Kandidat: Flutter #183

[PR #183](https://github.com/Ullmann27/lumo-lernen/pull/183), Head **`8344c10f1401d6516194e45e565695e968c9b47e`**, enthält **142 WebPs mit insgesamt 5.318.986 Bytes**. Keiner ihrer exakten Assetpfade existiert im freigegebenen Flutter-Baum; 138 Motive haben auch keinen gleichnamigen lokalen Dateistamm. Drei vorhandene Icons sind andere Pfad-/Formatvarianten, `star_burst.json` ist keine entsprechende Bilddatei. Das beweist eine fehlende Assetlieferung, nicht das Fehlen der entsprechenden Spielmechanik.

Die Metadaten nennen die Quelle ausdrücklich: **„Heinz, 4. Oktober 2026: zehn transparente Bildtafeln (RGBA, 1448x1086)“**. `docs/design_targets/2026-10-04/tafeln/manifest.json` dokumentiert Motiv, Ursprungstafel, Crop-Nummer, Pixelgröße und SHA-256 je Bild; alle zehn Originaltafeln liegen im selben PR. Format: WebP Qualität 90, Alpha verlustfrei. Für diese eigenen Referenz-Crops ist keine gesonderte CC0-/Stocklizenz ausgewiesen; Originalnachweise erhalten, keine externe Lizenz behaupten.

| Direkter Pfad am PR-Head | Geeigneter Einsatz | Maße / Bytes | Originaltafel |
|---|---|---|---|
| `assets/lumo_design/ui/avatar_fox.webp` | Original-Lumo-Marker in Würfel/StarsPath | 256×256 / 27.370 | `t04_ui_symbole.png`, Nr. 5 |
| `assets/lumo_design/ui/star.webp` | Sterne/Spielpfad/Ergebnis | 256×256 / 22.882 | `t04_ui_symbole.png`, Nr. 7 |
| `assets/lumo_design/ui/trophy.webp` | Ziel/Ergebnis, Würfel-Wettlauf | 256×256 / 31.656 | `t04_ui_symbole.png`, Nr. 4 |
| `assets/lumo_design/icons/flag_checkered.webp` | Zielflagge statt Emoji | 256×256 / 19.026 | `t06_strecken_deko.png`, Nr. 12 |
| `assets/lumo_design/deco/wood_sign.webp` | Kontext-/Richtungsschild in UI | 350×267 / 31.310 | `t06_strecken_deko.png`, Nr. 11 |
| `assets/lumo_design/nature/island_castle.webp` | Dekoration, Puzzle-Motiv oder Portal | 384×344 / 62.512 | `t07_natur.png`, Nr. 1 |
| `assets/lumo_design/buildings/town_house.webp` | Zahlenhaus-Dekoration, ohne echte Zahlen zu überdecken | 338×384 / 57.082 | `t05_gebaeude.png`, Nr. 3 |
| `assets/lumo_design/characters/fox_wave.webp` | Wiederverwendeter Original-Lumo | 408×486 / 65.558 | `t09_figuren_karts.png`, Nr. 1 |

Weitere passende kleine Quellen: `assets/lumo_design/nature/tree.webp` (48.908 Bytes), `nature/waterfall.webp` (64.188 Bytes), `ui/{heart,book,check,shield}.webp`. **Keine Würfelgrafik** ist in diesem PR enthalten. Die vier erstgenannten UI-/Zielbilder summieren sich auf 100.934 Bytes. 2D-Crops können Originalformen zeigen, ersetzen keine begehbaren 3D-Objekte und keine Collider. Selektiver Dateitransfer ist sicherer als der alte vollständige `pubspec.yaml`-/Appstand.

## Bereits lokal vorhandene Grafikquellen

| Quelle | Vorhanden / bereits angeschlossen | Wert für schwache Spiele |
|---|---|---|
| Flutter `assets/lumo_design/icons/{apple_red,candy_blue}.png` | 512×512; originale lokale Blender-Renders; `LumoQuantityArt` nutzt 128-px-Decodes | Zählbare Objekte für ColorBoxes/Zahlenhaus, wo die Aufgabe das pädagogisch verlangt. Keine Veränderung der Anzahl oder Bewertung. |
| Flutter `assets/lumo_design/icons/{star_gold,trophy_gold,treasure_chest,crystal}.png` und `fox/fox_avatar.png` | Lokale Originalgrafik; Star/Apfel wurden visuell geprüft | Höchster kleiner Gewinn: Emoji-Marker in Dice/StarsPath und Ergebnisflächen ersetzen. Dice enthält aktuell Emoji für Pokal/Stern/Flagge/Fuchs/Kind, StarsPath Stern/Fuchs. |
| Flutter `assets/lumo_design/memory/` | Echte Face-/Stickerbilder; `MemoryMotif.path` und Kartenrenderer verbunden | Memory besitzt bereits echte Motive. Oberflächen/Lesbarkeit verbessern, bestehende Figuren erhalten. Keine neue Rivalenidentität aus generischen Tierbildern ableiten. |
| Flutter `docs/design/2026-10-11-learning-adventures/source/{learning_quantity_objects,learning_season_dioramas}.blend` | Zwei editierbare lokale Blender-Quellen; sechs gebündelte Icon-Renders | Kostenfreie neue Renderwinkel/-größen, originale Objektfamilie erhalten. Blend-Dateien außerhalb der APK lassen. |
| Godot `assets/generated/lumo3d_assets/` | 176 PNG-Dateien; alle manifestierten Pfade vorhanden. Manifest: eigene für Heinz/Lumo generierte Bilder, keine Drittquellbilder | 12 Albedos + 12 Normalmaps, Emissionskarten, Partikel, Portale, Sky-/UI-Bilder. Geeignet für Build-/Treasure-/Rhythm-Oberflächen und kleine Effekte. Keine GLBs. |
| Godot `scripts/creative/creative_kit.gd` | Stein/Gras/Holz-Materialcache und Originalgeometrie bereits verbunden, ebenso Wasser-/Sterngeometrie | Materialqualität lokal weiterführen. Stein/Holz auf passenden Bauteilen sind bereits texturiert; reine Texturexistenz nicht als neue Verbesserung zählen. |
| Godot `assets/creative/puzzle/{moonlight,candy,volcano}.webp` | Alle drei tatsächlich von `puzzle_world.gd` vorgeladen; proportionserhaltende Puzzle-Geometrie vorhanden | Ein neues originales Motiv wäre zusätzliche Variation; die existierenden Motive sind nicht unverbunden. |
| Flutter `assets/lumo_design/gameplay/{build,puzzle,treasure,rhythm}.png` | Bestehende echte Spielansichten, 1280×720; Build-Bild visuell geprüft | Eintritts-/Auswahlbilder und Vergleichsnachweise. Keine neue interaktive Spielfläche daraus machen. |
| Godot `assets/characters/lumo_animated/Lumo-Animated-Mobile.glb` und `docs/design/2026-10-10-animation/editable/Lumo-Animated-Mobile.blend` | 30.000 Dreiecke, 65 Knochen, neun Clips, drei 1024er Texturen; Kart-Renn-/Menükette vorhanden | Ein vorhandener originaler Charakter. Für Flutter wären daraus lokale Sprite-/Portrait-Renders möglich; keine neue Modellgenerierung nötig. CC-BY-4.0-Attribution und Modifikationshinweis erhalten. |

Das existierende ungeriggte Modell unter `docs/design/2026-10-10-rivals/existing-lumo/candidate/` ist ein älterer technischer Prototyp. Es darf die aktuelle animierte Datei nicht versehentlich ersetzen. Die animierte Runtime-Datei hat SHA-256 `3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5`; Lizenz-/Änderungsnachweis: `assets/characters/lumo_animated/ATTRIBUTION.md`. Nunito-Lizenz und Godot `THIRD_PARTY_NOTICES.md` bleiben erhalten.

## Nachweislich offene Entwicklung

- **Fünf neue Gegner:** Löwe, Eule, Nova/Hase, Eichhörnchen und Schildkröte sind im gemeinsamen Katalog und den Originalreferenzen vorhanden. Alle fünf haben `runtimeReady: false`; die angekündigten `driver.glb`-/Flutter-Portraitpfade fehlen. `assets/characters/rivals/reference/originals/` und `reference-input-manifest.json` sind die vorhandene Quelle. Nicht durch fremde Tiere oder ungeprüfte statische Meshes ersetzen.
- **Lumo-Gesicht und Lernbegleitung:** Das aktuelle Rig besitzt keine Gesichts-Morphs, Lidmechanik oder Viseme. Der Audio-Pegeladapter ist kein produktiv verbundener Lippen-Sync. Eine aus dem Rig abgeleitete Flutter-Atlasdarstellung ist Vorschlag, kein bereits angeschlossenes Feature. Kart-Lenk-/Sitzanimation ist dagegen integriert.
- **Treasure-Figur:** Die native Schatzsuche nutzt `FOX.new()` / `configure_companion("fox")` aus der bestehenden prozeduralen Fahrzeugfamilie. Ein vollständig geprüfter neuer Geh-/Sprungzyklus aus dem animierten Rig ist dort nicht angeschlossen. Lokale Überarbeitung muss Bewegung/Collision/Saves erhalten.
- **Kreativspielqualität:** Playable Scenes/Save-/Reward-Struktur sind vorhanden. Rhythm speichert Bestwerte; ein unfertiges Lied startet nach Prozessverlust erneut. Geometrie-/Materialdichte und echte Geräteabnahme sind nicht aus den alten Headless-/Desktopnachweisen abzuleiten.
- **Marktstart:** Die enthaltene #260-Kette ist Produkt-/Datenschutz-/Premium-Planung. Sie verlangt zuerst die laufende Kart-/Fold-Arbeit. Kaufvalidierung/Play-Testabos sind kein bereits implementierter Bestandteil dieses APK-Auftrags.

## Priorität für die integrierte APK

1. Bestehende Lumo-/Lern-/Save-/Voice-Kette und den gepinnten Kart-Unterbau erhalten; Kart-Fold-Reparatur separat abschließen.
2. Dice/StarsPath/kleine Spiele mit vorhandener Originalgrafik und lokalen Blender-Würfeln/-Spielfiguren sichtbar verbessern; Regeln/Zahlen/Trefferflächen unverändert halten.
3. Aus #183 nur tatsächlich verwendete originale UI-/Deko-Crops plus Provenienz übernehmen. Kein fremdes App-/Pubspec-/Godot-Pin-Reset.
4. #230s Cards-Intro/-Pile-Grafik bei Bedarf selektiv mit den neueren 48-dp-/Narrow-Layouts kombinieren. #247-SVGs als Designreferenz behandeln.
5. Native Kreativspiele mit ihren bereits verwendeten Material-/Geometriequellen verfeinern. Fünf noch nicht vorhandene Rivalen-Rigs sowie Gesicht-/Speech-Arbeit ausdrücklich als offen belassen; dafür keinen Providerjob starten.

Dieser Bericht belegt Quell-/Assetzustand und sichere Kandidaten. Er enthält keine Behauptung, eine neue APK gebaut, ein Spiel auf einem physischen Fold vollständig gespielt oder die genannten historischen Tests erneut ausgeführt zu haben.
