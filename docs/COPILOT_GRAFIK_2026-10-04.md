# Copilot-Anschlussauftrag: Lumo nach den zwölf Originalbildern

Auftrag von Heinz, Bestandsaufnahme 4. Oktober 2026: Nicht am vier Monate alten Stand weiterarbeiten. Schwerpunkt ist die tatsächliche Grafik des Kart-Rennspiels und der zugehörigen Lern-App. Die zwölf schon generierten Entwürfe sind das visuelle Qualitätsziel, nicht Anlass für weitere alternative Konzeptbilder oder bloß eine neue Farbgebung.

## 1. Richtige Ausgangspunkte

Flutter/Android: `Ullmann27/lumo-lernen`, PR #156, `codex/lumo-unified-android-2026-10-03`. Vor diesem Dokument frisch geprüfter Head: `bc9d9876b8e6ed9a1c6c91d3db2212d5a761c304`. Hier liegen die jüngeren Integrations-, Speicher- und QA-Arbeiten. Zuerst `CODEX_START.md`, `docs/ANDROID_LIVE_UI_2026-10-04.md` und `docs/UNIFIED_ANDROID_2026-10-03.md` lesen.

Neuere freie Kartfahrt/Grafik: `Ullmann27/lumo-godot`, Draft-PR #4, `codex/lumo-holographic-kart-2026-10-03`, geprüfter Head `08f3f3f60eb9712c7823faceec2350293d292ce5`. Der Bericht nennt vier frei fahrbare Welten, sechs Modi, Auswahlmenüs, Geisterfahrten, überarbeitete Figuren/Karts und eigene Musik. Das ist eine vorhandene Ausbaustufe, keine fertige Umsetzung der Konzeptbilder.

Der Flutter-Zweig `codex/lumo-holographic-2026-10-03` pinnt diesen Godot-Commit in `config/godot-source.json`, liegt im Livevergleich gegen `bc9d9876...` aber 47 Commits zurück und hat nur einen eigenen Commit: die Änderung des Godot-Pins. Seine `pubspec.yaml` enthält weiterhin `0.10.5+280`. „Build 281“ in der Godot-Übergabe ist eine geplante Folgeversion, keine hier nachgewiesene fertige APK.

Deshalb: Frische Heads lesen, Flutter auf dem aktuellen Integrationsstand fortführen und den neueren Godot-Grafikstand gezielt kompatibel anbinden. Nicht den veralteten Flutter-Abzweig als vollständigen aktuellen App-Stand behandeln. Neue Arbeitszweige von den jeweils passenden Heads verwenden. Keine Rücksetzung, kein Force-Push, kein ungeprüftes Überschreiben fremder Arbeit, kein automatischer Merge oder Release. Die alten April-/Juni-ZIPs und separate Godot-APKs bleiben historische Quellen. Ein Modellname ersetzt keine Commit-Zuordnung.

## 2. Nachweisgrenzen

Build 280 wurde als Testversion übergeben. Laut aktualisiertem PR #156 sind einzelne komplette Kart-, Lern- und Memory-Abläufe durch Originalnachweise dokumentiert; die vollständige Android-Gesamtprüfung einschließlich Cards/Fold/Offline war dort nicht bestätigt. Aktuellen Status und Originalnachweise bei Bedarf frisch lesen; historische Testzahlen nicht als neue Tests ausgeben.

Der Nutzer meldet, dass Kart nicht funktioniert. Ohne reproduzierten Start und Geräte-Logcat ist die Ursache unbewiesen. Die frühere Vermutung eines hängen gebliebenen `lumo_game`-Prozesses ist nur eine Hypothese. Nicht blind Startschutz entfernen oder Prozesse beenden. QA-Beobachtungsfehler sind kein automatischer App-Crash-Nachweis.

Live-KI war laut vorherigem Nachweis durch Provider-Kontingent blockiert; Grafik-/Mocktests belegen keine Aktivierung. Keine Schlüssel-/Abrechnungsänderungen. Keine behauptete Samsung-/ARM-/60-FPS-Prüfung ohne Messung.

## 3. Zwölf wiedergefundene und visuell geprüfte Originale

Quelle: ChatGPT-Projekt/Library `App Lumo`, 3. Oktober 2026, 18:33:28–18:33:57 UTC. Nummerierung nach Erstellungsreihenfolge; bei Zweifeln gilt der genaue Dateiname.

**Wichtige Transfergrenze:** Die zwölf Bilder wurden in ChatGPT vollständig angesehen. Der Rohdateiexport der ersten fünf wurde mangels autorisiertem Materialisierungspfad abgewiesen. Dieses Dokument enthält den Bildindex und die Auswertung, NICHT die PNG-Dateien. Copilot hat nicht automatisch Zugang zur ChatGPT-Library. Für den pixelbezogenen Vergleich müssen die Originale als Bildanhänge oder regulär exportierte Assets im Copilot-Arbeitsraum vorliegen. Ohne diese Sicht keinen exakten Bildabgleich behaupten. Technische Bestandsaufnahme und Integration dürfen trotzdem weitergehen.

| Nr. | Exakter Dateiname | Zielansicht |
|---|---|---|
| 01 | Lumo Lernen im magischen Glasgarten.png | Hochformat-Home, Fuchs auf Glasplattform, schwebende Inseln/Wasserfälle, Loslernen, Rechnen/Lesen/Schreiben/Spiele, untere Navigation. |
| 02 | Lumos Lernabenteuer auf schwebenden Inseln.png | Vier Lerninseln mit transparentem Sternenweg, Fuchs und Weiterlernen. |
| 03 | Lumo zählt bis zwölf.png | Kristallgruppen, große Rechnung/Antwortfelder auf dunkler Glastafel, Fuchs mit aufgabenbezogener Hilfe. |
| 04 | Lumos Sternenwelt voller kleiner Belohnungen.png | Belohnungsinseln, echter Sternestand und Kart-/Geschichte-/Zimmerkarten. |
| 05 | Lumo Kart am sonnigen Hafen.png | Hauptreferenz Hafen: großes blau-weißes Kart und Fellfuchs rechts, sechs Glasmenüeinträge links, dichter Hafen mit Steinbrücke/Booten/Häusern. |
| 06 | Lumo Kart: Magische Garage voller Freunde.png | Hauptreferenz Garage: Fuchs/Kart auf cyanbeleuchtetem Glasdrehteller, tiefe Werkstatt, Freunde, Weltvorschauen, sechs große Bildbuttons unten. |
| 07 | Lumo Kart auf der Abenteuerinsel.png | Kart vorn links, Hafen/Wald/Schnee/Holo-Stadt, rechts Losfahren/Meine Garage/Strecken/Lernen. Tatsächlicher Titel Abenteuerinsel, nicht Spielzeugwelt. |
| 08 | Lumo Kart: Fahrmodi auswählen.png | 2×3-Bildkarten: Einzelrennen, Cup, Zeitfahren, Training, Lern-Cup, Arena. |
| 09 | Lumos gläserne Fahrerauswahl.png | Großer Fuchs auf Glasbühne, Wertepanel, Portraits Lumo/Mila/Nova/Timo/Bruno. |
| 10 | Lumos Kartgarage mit dem Sternenflitzer.png | Großes drehbares Kart, Sternenflitzer/Wolkenhüpfer/Blitzmobil links, Tempo/Grip/Boost und Farben rechts. |
| 11 | Lumo Kart: Vier fantastische Rennstrecken.png | Sonnenhafen, Zauberwald, Wolkenpass, Holo City; jede Welt eigenständig ausgestaltet. |
| 12 | Lumo Kart am Sonnenhafen.png | Gameplay: Verfolgerkamera, erkennbarer Fuchs/Kart, dichter Hafen, Mitfahrer, Glas-HUD/Minimap, Lenkung links und Drift/Boost rechts. Nicht Bild 05. |

Die vier älteren Dateien `01_mathe_mit_lumo_target.png` bis `04_pixar_scene_portrait.png` im bisherigen `docs/design_references/` sind nicht diese zwölf neuen Originale.

## 4. Verbindliche Grafikarbeit

Priorität: Bilder 05/06/12 für Kart, Bild 01 für die Lern-App; 07/11 für die Weltübersicht, 08–10 für Auswahlabläufe. Die Referenzen zeigen nicht nur blaue Farben, sondern vollständige Figur-, Fahrzeug-, Welt-, Licht- und Materialgestaltung.

Lumo: orange/cremefarbene weiche Fellform, große blaue Augen, freie vollständige Silhouette, klare Schnauze, großer weißer Schweifabschluss, dunkelblaues Outfit mit weißen Nähten und Cyanstern. Kein eingeklemmter Kopf, abgehackte Gelenke oder starrer Bildausschnitt als angebliches 3D-Modell. Atmen, Blinzeln, Winken, Lenken, Ohren/Schweif und Mimik mit flüssigen Übergängen. Sprachsynchronisation nur bei tatsächlichem Nachweis behaupten.

Karts: geformte Karosserie statt Ersatzklötzen, blau-weißer Lack, Stern, detaillierte Reifen/Felgen, Fahrwerk, Sitz, Lenkrad, Leuchten und Auspuff; korrekt sitzender Fahrer mit Händen am Lenkrad. Lack, Metall, Gummi, Stoff und Fell erkennbar unterscheiden. Garage und Gameplay verwenden erkennbar dasselbe Fahrzeug.

Welten: Hafen mit Tiefenstaffelung, Küstenfelsen, Terrassenhäusern, Markisen/Fenstern, Pflanzen, Lampen, Booten, bewegtem Wasser, Leuchtturm und Steinbrücken. Keine kahle Straße vor einem schönen Einzelbild. Wald mit organischen Stämmen/Kronen, Unterholz, Lichtpilzen und Brücken; Wolkenpass mit Schnee/Bergen/Tunnel; Holo City mit erhöhten Straßen, Glasgebäuden und Cyan/Violett-Licht. Fahrbahn und Blickführung bleiben klar.

Menüs: Dunkelblau/Weiß/Cyan, nicht orange Grundoberflächen. Orange bleibt natürliches Fell und punktuelles Motiv. Glaspaneele mit Tiefe, Glanzkanten, klarer Schrift, echten Auswahl-/Druckzuständen und großer kindgerechter Bedienung. Fold-/Querformat sicher abbilden. Atmosphärische vorgerenderte Hintergründe sind möglich, ersetzen aber kein interaktives Modell oder echtes Gameplay.

Konkrete Abweichungen: Der Codebericht beschreibt `rabbit`/Nova, `otter`/Milo, Dachs/Katze. Bild 09 zeigt Mila als Häsin, Nova als Eule, Timo als Waschbär, Bruno als Bär. Figuren und sichtbare Namen an den Bildauftrag angleichen, aber gespeicherte IDs/Aliase nicht ohne Migration umbenennen. Bild 11 nennt Wolkenpass statt des bisherigen Berichtsnamens Kristallalpen (`bergwelt`). Referenzfahrzeuge nicht nur als neue Namen über fast identische Modelle legen.

Beispieldaten wie Lena, 127/24 Sterne, 7+5 und Runde 1/3 sind keine fest zu programmierenden Nutzerwerte oder neuen Spielregeln. Aufgaben/Belohnungen bleiben korrekt und dynamisch. Unterschiedliche Hauptmenüentwürfe auf sinnvolle Screens verteilen, nicht übereinanderlegen. Die Kennzeichnung DESIGNENTWURF ist kein Nachweis einer fertigen Funktion.

## 5. Code-Einstieg

Godot: `CODEX_START.md`, `docs/HOLOGRAPHIC_CHARACTERS.md`, `docs/KART_WORLDS_2026-10-03.md`; `scripts/games/kart_vehicle.gd` für Figuren/Karts/Node-Rig/LOD, `kart_world.gd`, `kart_world_meshes.gd`, `kart_tracks.gd` für Welten und Fahrbahnvertrag, `kart_island.gd` plus tatsächlich aktive Menüs/HUD/Controller. Aktive Szenenreferenzen prüfen, nicht nur ähnlich benannte alte Dateien ändern. Echte Bilder: `docs/screenshots/`. Hilfen: `tools/art/render_kart_portrait.gd`, `tools/art/verify_kart_geometry.gd`, `tools/validate_project.sh`.

Flutter: `lib/features/home/home_content.dart`, `lib/features/games/games_content.dart`, `lib/features/lumo3d/lumo3d_launcher.dart`, `lib/core/embedded_game_service.dart`, `tools/auto_install/MainActivity.kt`, `tools/auto_install/LumoGameActivity.kt`, `scripts/prepare_android.py`, `config/godot-source.json`, `scripts/build_unified_apk.sh`, `scripts/verify_unified_apk.py`. Die Renn-Grafik gehört ins eingebettete Godot-Spiel, nicht nur in eine alte Flutter-Kartvorschau oder ein Coverbild.

## 6. Ausführung und Abnahme

1. Tatsächliche Heads, aktive Szenen, Pin, Version und Bildzugang kurz feststellen. Keine erneute große lose Planungsrunde.
2. Echte Ausgangsaufnahmen von Home, Kartmenü, Garage, Fahrer und Sonnenhafen-Fahrt aufnehmen. Referenz/Ist/Lücke pro Ansicht festhalten.
3. Zuerst einen vollständigen visuell ausgearbeiteten Ablauf bauen: Spiele → Hauptmenü → Garage mit Lumo/Sternenflitzer → Sonnenhafen-Rennen → Ergebnis → Rückkehr. Figur/Kart, Glas-UI, Kamera, Licht und einen repräsentativen dichten Hafenabschnitt tatsächlich verbessern. Nicht wieder nur Testwerkzeuge reparieren; blockierende Funktionsfehler trotzdem gezielt beheben.
4. Gleiche Kamerapositionen mit Originalen vergleichen; Abweichungen bei Silhouette, Material, Licht, Umgebungsdichte und Layout offen ausweisen. Keine geratenen Ähnlichkeitsprozente. Danach das visuelle System auf weitere Welten, Fahrer, Modi und Lernseiten übertragen.
5. Freie Lenkung, Drift/Boost, Kollisionen, komplette Rennen/Modi, Lernantworten/Hilfen, Pause/Rückkehr, Speicherstände und idempotente Belohnungen prüfen. PIN-freie Navigation erhalten. Kein Löschen alter Lerndaten als Standardlösung.
6. 60 FPS als Ziel behandeln, erst mit Gerät/Auflösung/Profil/Frame-Zeiten als Ergebnis bestätigen. LOD/Batches/Lichtkosten optimieren, ohne die Schlüsselfiguren zu Platzhaltern zurückzustufen. Desktop-Software-Rendering ist kein Samsung-Benchmark.
7. Validierten Godot-Commit pinnen, passende nächste Version festlegen, gemeinsame signierte APK bauen. Paket/Signatur/Daten erhalten; die tatsächlich eingebettete Revision, Installation und Start prüfen. Identische Build-280-Bytes nicht als neue Grafikversion anbieten.

Jede Etappe liefert Code, nachvollziehbare Tests und unveränderte echte Screenshots, möglichst eine kurze echte Bildschirmaufnahme. Commit/Szene/Auflösung/Renderer zuordnen; Konzeptbilder, Desktop und Android unterscheiden. Grüner Build allein genügt nicht; schönes Standbild allein ebenfalls nicht. Die Endabnahme verlangt Referenztreue UND funktionierende Spiel-/Lernabläufe.

Diese Übergabe selbst ist keine App-Reparatur, neue APK, bestätigte laufende Copilot-Sitzung oder Übertragung der Original-PNGs.

## Quellen

- https://github.com/Ullmann27/lumo-lernen/pull/156
- https://github.com/Ullmann27/lumo-godot/pull/4
- https://github.com/Ullmann27/lumo-godot/blob/08f3f3f60eb9712c7823faceec2350293d292ce5/CODEX_START.md
- https://github.com/Ullmann27/lumo-godot/blob/08f3f3f60eb9712c7823faceec2350293d292ce5/docs/HOLOGRAPHIC_CHARACTERS.md
- https://github.com/Ullmann27/lumo-godot/blob/08f3f3f60eb9712c7823faceec2350293d292ce5/docs/KART_WORLDS_2026-10-03.md
- https://github.com/Ullmann27/lumo-lernen/blob/codex/lumo-holographic-2026-10-03/config/godot-source.json
- https://github.com/Ullmann27/lumo-lernen/blob/codex/lumo-holographic-2026-10-03/pubspec.yaml
- Originalbildquelle: zwölf oben exakt benannte ChatGPT-Library-Dateien; kein externer GitHub-Bildlink nachgewiesen.
