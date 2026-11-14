# Reichweite der sieben statischen Native-Warnungen

## Feste Quellen und Grenze

Diese Auswertung ist ausschließlich eine Quellenprüfung auf Host `198dd3d1a5862797a37f0d1d638ea929009b8848` (Tree `e17540fd0c9d047d72a67fa05c0ca5d2edfe70a6`) und Native `bebf7bba48f09afc834469db0ea3c5541a184f55` (Tree `35492eec16cac6774bc546b6e57628900bef61cb`). Sie führt weder Godot noch einen Android-/Produkttest aus und ersetzt keine neue APK-Abnahme.

Vollständig nach Modell-IDs, Modellpfaden und `get_model` durchsucht wurden sämtliche 503 im Native-Gitbaum vorhandenen GDScript-Dateien, alle 30 Szenendateien, `project.godot` und `assets/manifests/assets.json`. Die 535 gelesenen Dateien wurden einzeln gegen ihre Git-Blob-SHAs geprüft. Die erste Zwischenmeldung hatte zunächst nur 492 Skripte unter `scripts/` erfasst; die eine Skriptdatei unter `assets/` und zehn archivierte Skriptdateien unter `docs/` wurden vor diesem Abschluss ausdrücklich ergänzt. Der ergänzte Suchlauf ergab keinen weiteren Modellaufrufer.

## Ergebnis

Die sechs GLB-Dateien fehlen tatsächlich im gepinnten Gitbaum. Ihre IDs werden beim Godot-Start in den globalen Asset-Katalog eingelesen. **Das Einlesen des Katalogs lädt die sechs Modelle jedoch nicht.** Der einzige gefundene Codepfad, der diese Modellkategorie laden und bei einem fehlenden Modell die magentafarbene Box erzeugen kann, ist `AssetLoader.get_model(id)`. Für diesen Pfad existiert in der oben vollständig benannten Suchmenge kein ausführbarer Aufrufer: die Treffer sind die Methodendefinition sowie Kommentare. Insbesondere der vermeintliche Aufruf mit `lumo_fox` in `lumo_companion.gd:5` ist eine auskommentierte Umbauanleitung.

Die Warnung des Projektprüfers ist daher ein statischer Katalogbefund. Der Text „AssetLoader nutzt Placeholder“ wird durch das bloße Fehlen der Datei erzeugt; er beweist keine tatsächlich ausgeführte Placeholder-Instanziierung.

## Die sechs Einträge

Alle Angaben stammen aus `assets/manifests/assets.json:3–10`.

| ID | Fehlender Pfad | Festgestellter aktiver Ladeaufruf |
|---|---|---|
| lumo_fox | res://assets/models/lumo_fox.glb | Keiner in der geprüften Suchmenge; ein Kommentar in lumo_companion.gd nennt einen zukünftigen Umbau. |
| hub_island | res://assets/models/hub_island.glb | Keiner in der geprüften Suchmenge. |
| portal_learn | res://assets/models/portal_learn.glb | Keiner; mat_portal_learn ist eine getrennte Material-ID. |
| portal_games | res://assets/models/portal_games.glb | Keiner; mat_portal_games ist eine getrennte Material-ID. |
| portal_parent | res://assets/models/portal_parent.glb | Keiner; mat_portal_parent ist eine getrennte Material-ID. |
| star_collectible | res://assets/models/star_collectible.glb | Keiner in der geprüften Suchmenge. |

## Tatsächlicher Loader und Warnungsursprung

- `project.godot:20,24–34`: Hauptszene ist `scenes/app/boot.tscn`; `AssetLoader` ist globaler Autoload. Der Loader selbst ist damit auch im eingebetteten Android-Prozess vorhanden, nicht nur in einer alten eigenständigen Szene.
- `scripts/systems/asset_loader.gd:42–53,157–176`: `_ready()` liest JSON und weist den Kategoriedictionaries ihre Inhalte zu. Hier findet keine Schleife zum Laden von GLBs statt.
- `scripts/systems/asset_loader.gd:57–73`: Erst `get_model` prüft den Modellpfad, lädt ein PackedScene und instanziiert es. Fehler verzweigen zu `_make_placeholder`.
- `scripts/systems/asset_loader.gd:181–202`: Der Fallback erzeugt tatsächlich eine magentafarbene Box mit „missing: <ID>“. Diese Funktion ist ausschließlich innerhalb `get_model` aufgerufen.
- `tools/validate_project.py:106–123`: Die sechs Warnungen entstehen unabhängig von der Erreichbarkeit durch Iteration über `data["models"]` und Dateiexistenzprüfung.

## Welche alten Szenen tatsächlich verwenden

Auch die alten Szenen laden diese sechs Katalogmodelle nicht:

- `scenes/app/home_3d.tscn:7,57` verwendet eine PlaneMesh für die Insel; `scripts/app/home_controller.gd:38–44` weist ihr das separate Material `mat_stone_warm` zu.
- `home_controller.gd:8–10,57–59,75–85` instanziiert direkte Szenen für Figur, Portale und Sterne. Die Figur ist `scenes/characters/lumo/lumo_character.tscn`, deren sichtbare Grundkörper als CapsuleMesh/SphereMesh/BoxMesh in der Szene definiert sind.
- `scenes/hub/hub_portal.tscn:5,34` besitzt eine TorusMesh. `scripts/hub/portal_interaction.gd:23–26,46–72` setzt Ringfarben und lädt ausschließlich die getrennten generierten Portal-Materialien.
- `scripts/hub/star_field.gd:33–53` erstellt SphereMesh und MultiMesh direkt. Auch `scripts/games/star_collect_game.gd:33–68` erzeugt seine Sammelsterne direkt.
- Aktuelle geriggte Figuren benutzen einen anderen Adapter: `scripts/characters/lumo/lumo_rigged_actor.gd:6–7,41–58` lädt `assets/characters/lumo_facial/Lumo-Facial-Mobile.glb` mit dem separaten Originalmodell `assets/characters/lumo_animated/Lumo-Animated-Mobile.glb` als Rückfall. Das ist keine Nutzung der Katalog-ID `lumo_fox`. Diese Quellenfeststellung ist keine pauschale Qualitäts- oder Vollständigkeitsprüfung aller Figurenassets.

## Verbindung zu den eingebetteten Android-Einstiegen

Der tatsächliche Hostpfad auf 198dd3 ist:

1. `lib/features/lumo3d/lumo3d_launcher.dart:140–166` ruft `launch3D` mit dem gewählten `scene` auf.
2. `tools/auto_install/MainActivity.kt:174–234` erlaubt die neun Ziele `kart, jump, puzzle, build, rhythm, treasure, learning, cards, connect_four`; ein anderer Wert wird zu `kart`. Der Host stellt daraus `game` und die Sitzungsoptionen zusammen. C4 startet `ConnectFourGameActivity`, alle anderen Ziele `LumoGameActivity`. Ein vom Flutter-Aufrufer angefordertes `home` oder `games` wird hier nicht direkt gestartet.
3. Beide Aktivitäten übergeben denselben Pack `res://lumo_game.pck` und veröffentlichen ihre echten Optionen über den Plugin `LumoHost`: `LumoGameActivity.kt:189–197,229–236`, `ConnectFourGameActivity.kt:78–80,137–147`. `scripts/prepare_embedded_games.py:102–139` deklariert beide Aktivitäten privat (`exported=false`) im isolierten `:lumo_game`-Prozess.
4. Native `scripts/systems/host_bridge.gd:19–40,50–51` liest diese Optionen. `scripts/app/app_boot.gd:64–79` lässt die eingebetteten Hostoptionen etwaige CLI-/Weboptionen überschreiben. Die geladene Zielszene wird über `SceneRouter.SCENES` bestimmt und in `app_boot.gd:275` übergeben.
5. Die alten Routen `home`, `intro` und `games` existieren weiterhin im Native-Router (`scene_router.gd:12–37`). Ohne eingebetteten Host ist der Standardstart heute `games`; eine explizite eigenständige `--scene=home`-Option erreicht Home. Im eingebetteten Zustand führt `SceneRouter.goto("home"/"games"/"learn")` nach dem Boot stattdessen zurück nach Flutter (`scene_router.gd:95–99`). So ist etwa der Home-Zurückknopf des nativen Game-Hubs eingebettet ein Host-Return, keine unbedingte Home-Instanziierung.
6. `scripts/build_unified_apk.sh:38–47` verwendet die gelesenen Hostvorlagen und den Exporter. `scripts/export_embedded_game.py:134–169` exportiert den sauberen konfigurierten Native-Pin; der gelesene Exportpfad ändert weder die Hauptszene noch den Autoload und lehnt einen nachträglich schmutzigen Native-Quellstand ab.

## Siebte Warnung und verbleibende Grenzen

`tools/build_web_bundle.sh` ist im exakten Native-Gitbaum mit Modus `100644` gespeichert. Der Projektprüfer meldet dafür das fehlende Ausführungsbit (`tools/validate_project.py:272–282`). Das ist keine fehlende Android-Modellressource; der gelesene Unified-APK-Pfad verwendet `export_embedded_game.py`, nicht dieses Web-Bundleskript. Es wurde kein Web-Build getestet und keine Aussage über sämtliche anderen Web-Aufrufstellen getroffen.

Die belastbare Aussage lautet: **In den vollständig benannten aktuellen Quellpfaden ist keine ausführbare Verwendung der sechs fehlenden Katalogmodelle nachgewiesen; die sieben statischen Warnungen bleiben reale, dokumentierte Quell-/Katalogwarnungen.** Die Quellenprüfung ist weder ein vollständiger dynamischer Erreichbarkeitsbeweis gegen beliebig konstruierte reflektive Methodenaufrufe noch ein Binary-/PCK- oder Gesamtrenderaudit. Sie gibt keine pauschale Entwarnung für sämtliche Assets und behauptet keinen neuen Android-Lauf. Beide echten Checkouts bleiben unverändert.
