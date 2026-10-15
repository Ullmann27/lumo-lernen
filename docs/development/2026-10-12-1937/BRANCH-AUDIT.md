# Erneuter Vergleich mit dem tatsächlichen Stand 1936

Zeitpunkt: 12.10.2026. Flutter-Basis PR278 `2dedb4045c6daea1de8af19052d51003191df8c8`, Version 0.12.29+1936. Godot-Pin `82b53fc02b9f2ad7e025433499c4c23f256fe734`. Der erfolgreiche 1936-Build ist Run38230588380; die separate Aufnahme-Runde38232145721 verwendet Flutter-Test-Runtime. Sie ist kein Android-Kart-Rennnachweis.

Inventar vollständig paginiert: **297 Flutter-Zweige, 262 PRs; 62 Godot-Zweige, 56 PRs**. Im Git-Graph sind 96 Flutter-/41 Godot-Heads enthalten; 201/21 sind nicht Vorfahren des aktuellen Pins. Für jeden divergenten Zweig wurden Merge-Basis, seine eigenen geänderten Pfade und die Blob-IDs mit dem aktuellen Stand verglichen. Die komprimierten JSON-Dateien enthalten den vollständigen Vergleich. Zusätzlich wurden 50 frühere Flutter-PR-Heads und ein früherer Godot-PR-Head geprüft, die nicht mehr aktuellen Branch-Heads entsprechen. Zehn ältere Flutter-Heads sind nicht Vorfahren, ihre nachfolgenden Versionen/Reimplementierungen liegen heute vor. Historische Game-/Schreibcoach-/Lesen-Architektur wird nicht zurückgesetzt. Gleicher Inhalt und enthaltene Funktion bedeuten nicht zwingend gleicher Git-Vorfahre.

## Tatsächlich fehlend und jetzt selektiv übernommen

| Ursprung | Fehlender Beitrag | Integration |
|---|---|---|
| Godot `chatgpt/kart-brake-reverse-2026-10-07` | Bremse bei Auto-Gas blockiert Rückwärtsfahren, Bremslampen fehlen | Aktuelle Physik und Fahrzeug-Batching ergänzt; ursprünglicher Fehler reproduziert, Bremse/Lenken gleichzeitig getestet |
| Godot `codex/lumo-cup-finish-regression-2026-10-09` | physischer Zieleinlauf und freie Ergebnis-Kamera | Patch3f9ff57 mit originalen16 Kontrollfällen, vor Integration12 Fehler, nachher0 |
| Flutter `claude/design-tafeln` |15 noch fehlende Original-WebP-Ausschnitte | unveränderte Bytes, SHA256-Manifest, Lesekarte verwendet das Original-Buchsymbol |

## Enthalten, ersetzt oder bewusst nicht zurückgemerged

Die aktuellen 1936-Änderungen aus PR273–277 enthalten bereits die 123 wiederhergestellten Grafikdateien, Hologlas, Cards-/Audio-Design und neuere Lernbaum-/Fold-/Schreibcoach-Fixes. Godot59–64 zeigen historische Quelllinien; Menü/Figur/Fahrzeuge/Sulafat sind im aktuellen Projekt vorhanden oder weiterentwickelt. Die beiden oben belegten Funktionslücken bestanden trotzdem und sind jetzt repariert. Aktuelle Touch-Weiterleitung/Fold-Spalten und animierter GLB-Lumo bleiben erhalten.

Weitere ältere `feat/*`, `copilot/*`, `claude/*`-Module mit anderen Klassennamen (etwa AI-Orchestrator, Kart-Flutter-Prototyp, Jump-Prototyp, Cards-Board-Entwurf, Widget-Barrels) sind keine fehlende zweite Runtime-Architektur. Die heute verwendeten Lernereignisse, lokale Lernhilfe, Schreibanalyse, Godot-Kart, Spiele-Controller, Kartenregeln und gespeicherten Daten bleiben verbindlich. Main enthält weiterhin nicht den gesamten Integrationsstand. Die alten Main-Schreibanalyse-Erweiterungen (`_isBent`, Strichsegmentierung, zuVieleStrokes) sind in der neueren Engine vorhanden.

Unreife Figurenreferenzen ohne laufzeitbereites Modell/Rig werden nicht als fertige Fahrer eingebunden. Gesonderte 4K-Upload-/Hand-off-Zweige sind Quellen-/Inventararbeit, kein Nachweis für integrierte Strecken. Keine neuen kostenpflichtigen Meshy-/Voice-/API-Aufträge; keine öffentliche Veröffentlichung oder Main-Merge.

Ein Blob-Vergleich prüft keine Pädagogik, Laufzeit oder Lizenz automatisch. Die dokumentierten Reparaturen benötigen die unten getrennte Android-Abnahme. Weitere Design-/Lehrplan-/Figurenarbeit bleibt eine nachfolgende Produktionsetappe; dieses Dokument behauptet keine endgültige Vollständigkeit des gesamten Produkts.
