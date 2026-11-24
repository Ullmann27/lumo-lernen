# Team B: tatsächlicher Prüfstand 2070

Stand: 23. November 2026. **Zurückgehalten; keine fertige APK dieses Kandidaten.**

## Quellen und Originalbelege

| Merkmal | Nachweis |
| --- | --- |
| Flutter | `404d6bcaaff0ac47bf1326551381110126daf9e4` |
| Godot | `93557b3ca206916a39fdeaa6ae6ce05442b08846` |
| Engine | Godot 4.6.3 |
| Supportprüfung | [45181487860](https://github.com/Ullmann27/lumo-lernen/actions/runs/45181487860), beide Jobs success |
| APK-Bauversuch | [45181487984](https://github.com/Ullmann27/lumo-lernen/actions/runs/45181487984), Job 137716310183 |
| Originales vollständiges Prüfartefakt | [14822952038](https://github.com/Ullmann27/lumo-lernen/actions/runs/45181487984/artifacts/14822952038) |
| ZIP-Größe | 17284079 Bytes |
| Unabhängig bestätigter ZIP-SHA-256 | `4bb0ecc616cfa0b78a5337b1231ad4be923cee335e0dac36762e5899810a94b4` |

## Bestandene Prüfungen

Der separate Supportlauf besteht Flutter-Analyse, 53 Flutter-Tests und 20 Tests des SHA-geprüften JAR-Helfers. Der umfassende APK-Lauf besteht 119 JVM-Tests (79 gemeinsame, 12 Connect Four, 28 Table Games) und 180 Flutter-Tests.

Native Prüfaussagen: World 169, Freundepost-Modell 289, Controller 22, tatsächliche World-Methoden 27, gerenderte Karte 152, ursprüngliche Schatzsuche 92 und NativeTableBoot 26. Die HostBridge-Prüfungen sind ebenfalls erfolgreich. Diese Prüfaussagen sind keine ebenso große Zahl unabhängiger End-to-End-Tests.

Die fünf World-Aufnahmen wurden tatsächlich mit GL Compatibility und Mesa llvmpipe erzeugt. Root und Design-Agent haben die Originalbilder angesehen. Die Karte nutzt jetzt die tatsächliche Produktionsskalierung und füllt ihre 600 Pixel breite Darstellung; Touchziele werden in Bildschirmkoordinaten auf mindestens 48 dp geprüft.

## Bestätigte sichtbare Mängel

- `world-kart_driving.webp`: Blattwerk verdeckt nahezu die komplette Fahransicht.
- `world-saved_village.webp`: ein Baum verdeckt die Figur und Teile des Dorfportals.
- `world-village_walking.webp`: der textabhängig verbreiterte Knopf „Ansprechen“ überschreitet den rechten Rand.
- `world-school_portrait.webp`: der Weg trifft optisch auf die hohe Fundamentwand; der Zugang ist unklar.
- `world-treasure_foundation.webp`: der sehr große Schriftzug liegt über der zentralen Figuren-/Wegachse.

Das erfolgreiche Erzeugen der Bilder ist keine visuelle Freigabe. Diese Mängel stimmen mit dem inzwischen übernommenen [Hauptteam-Befund 2069](../logic-games/QUALITY_2069.md) überein. Dessen Agents korrigieren Kamera, HUD, Vegetation, Schule und Schild. Team B verändert diese Besitzbereiche währenddessen nicht.

Die gemessenen Bildzeiten stammen ausschließlich von einem CPU-Software-Renderer. Daraus folgt keine Aussage über ein physisches Fold 7 oder eine 60-FPS-Zusage.

## Zusätzlicher Buildfehler

Nach den erfolgreichen World-Prüfungen startet das vorhandene Verpackungsskript einen zweiten, unabhängigen kalten Import in `build/godot-source`. Beim ersten Font-Reimport `Nunito-Variable.ttf` erscheinen `double free or corruption (out)`, ein ungültiger Variant-Index und SIGABRT (6). Der Prozess scheitert tatsächlich; APK-Bau, Android-Tour und Veröffentlichung wurden nicht erfolgreich abgeschlossen.

`--single-threaded-scene` ist bereits gesetzt. Ein gesonderter Ressourcenimport-Schalter wird anhand der exakten Godot-4.6.3-Quellen geprüft. SIGABRT wird nicht pauschal als Erfolg behandelt oder in die bisherige SIGSEGV-Ausnahme aufgenommen.

## Fortsetzung

1. Kamera-/HUD-Korrekturen des Hauptteams anhand des exakten nativen Commits integrieren.
2. Separaten Importfix mit unveränderten Quellstand-, Parser-, Paket- und Signaturprüfungen übernehmen.
3. Gemeinsamen Kandidaten 2071 vollständig neu bauen und prüfen; Originalaufnahmeorte beibehalten.
4. Die neue visuelle Prüfung sowie Android- und SAF-Backup-Runde tatsächlich abschließen.
5. Erst die real vorhandene, geprüfte APK ausliefern. Fehlende Veröffentlichungsberechtigungen offen dokumentieren; keine URL erfinden und keine Zugriffsgrenzen umgehen.

Die drei zusätzlichen Agents und Root arbeiten tatsächlich in dieser Sitzung. Die Abstimmung mit dem vorherigen Chat erfolgt nachvollziehbar über gemeinsame Quellen und PR-Kommentare; daraus wird keine unbelegte direkte Verbindung zweier Chat-Laufzeiten behauptet.
