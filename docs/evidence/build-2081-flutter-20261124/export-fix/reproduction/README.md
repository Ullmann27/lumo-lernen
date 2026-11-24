# Lokale Export-Reproduktion: Meshy-Allowlist 2081

## Ergebnis

Der konkrete Import-Cleanup-Blocker ist unter der unveränderten Godot-Engine 4.6.3 reproduziert behoben: Der vollständige Import lief durch; der korrigierte Exporter entfernte anschließend genau die 32 verifizierten, neu erzeugten Meshy-Importdateien. `git status --porcelain` war danach leer, und Commit und Tree blieben exakt auf dem geprüften Native-Pin.

**Der Export selbst wurde bei zuletzt gemeldeten 85 Prozent mit SIGKILL (Signal 9) beendet. Die Ursache ist nicht belegt. Es wurde kein fertiges PCK erzeugt und kein erfolgreicher APK-/PCK-Test behauptet.** Der direkte World-JSON-Zugriff aus dem fertigen PCK wurde deshalb lokal nicht ausgeführt und bleibt Gegenstand des abschließenden CI-Nachweises.

## Gebundene Eingaben

- Native-Commit: `c814e35249e4038f903d1fca3e19bb4751040a43`
- Native-Tree: `b37c1b3246bf0fa6554a0a562eca3a8ea1c0d38b`
- Exporter-SHA256: `6430daa7adecea327b516da01a9fc843f97e829357f015680b9e3f9f7b0a5a54`
- Engine: `4.6.3.stable.official.7d41c59c4`
- Engine-Binary-SHA256: `f64d4ed19fc9df9440321653fcc80df8c6e365ba7b6de0a29e2cfa9fa71bfeb3`
- Produktions-Assetbaum: `580fc843e0eb87a9c600fc8dd1dd0f8ec00cd4e6`, identisch mit dem bisherigen c3f459-Pin.
- Meshy-Manifest-SHA256: `763df5822780b995ceff8b87d927341374141fb3aa8b3a3d6dda4add49c25f31`.

Der Fix erweitert ausschließlich die bestehende Revisions-Allowlist um den exakten c814-Pin. Manifest-, GLB-, PNG-, Dateipfad-, Nur-neue-Dateien- und abschließende Quellstandprüfung wurden nicht abgeschaltet oder gelockert.

## Nachweise und Aufräumen

`RESULT.json` enthält die 32 entfernten Pfade, vollständige Eingabeidentitäten, Loghashes und die Identität des unvollständigen temporären Packrests. Die Import-/Exportlogs werden hier vollständig als GZIP-Dateien mitgeführt. RESULT.json enthält sowohl die Prüfsummen der GZIP-Dateien als auch die Prüfsummen der entpackten Originalausgaben. `source-after.txt` hält den sauberen abschließenden Quellstand fest.

Nach Sicherung dieser Nachweise wurden ausschließlich die isolierte, für diesen Versuch erstellte Native-Arbeitskopie und der unvollständige temporäre Packrest entfernt. Die ursprünglichen QA-Quellen, die verwendete Engine und sämtliche Nachweislogs bleiben erhalten. Es gab keine zweite Exportausführung und keine erneuten Spieltests.
