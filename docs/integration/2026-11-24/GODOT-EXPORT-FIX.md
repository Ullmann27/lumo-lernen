# 2081: verifizierte Importausgaben des unveränderten Modellbestands

## Beobachteter Fehler

Der Original-Zwischenlauf [45433091440](https://github.com/Ullmann27/lumo-lernen/actions/runs/45433091440), Flutter-Quelle `5c086af2fa967f743d5801b4be23c15efbbb88ba`, bestand die vollständige Flutter-Suite und die Godot-Kern-/World-Prüfungen. Beim Verpacken am 24.11.2026 um 16:40:54 UTC verweigerte `export_embedded_game.py` den Kandidaten mit `Godot import changed sources; refuse exported candidate`.

Gemeldet wurden genau 32 neu erzeugte Importausgaben: je eine `.glb.import` und eine `_0.png` zu den 14 Produktions-Karts und den zwei Garagenmodellen. Das Spielpaket war zuvor erzeugt worden; der Kandidat blieb aufgrund der anschließenden Quellenprüfung gesperrt und wurde nicht als APK veröffentlicht.

## Tatsächliche Ursache und eng begrenzte Korrektur

`remove_generated_production_meshy_imports` akzeptierte ausdrücklich die geprüften älteren Revisionen, darunter `c3f459eca88f659da1a9e4af1c990c804e715528`. Der neue Pin `c814e35249e4038f903d1fca3e19bb4751040a43` fehlte in dieser Liste. Die Funktion kehrte daher vor jeder Manifestprüfung zurück und ließ die bekannten Importausgaben liegen.

Beide Pins besitzen denselben Produktions-Assetbaum `580fc843e0eb87a9c600fc8dd1dd0f8ec00cd4e6`. Das Manifest hat SHA-256 `763df5822780b995ceff8b87d927341374141fb3aa8b3a3d6dda4add49c25f31`; alle 16 GLBs entsprechen unverändert seinen Bytezahlen und Prüfsummen. `.gitignore`, `export_presets.cfg` und `project.godot` sind zwischen den beiden Pins unverändert. Die erzeugten PNG-Dateien entsprechen den eingebetteten PNG-Buffern, einschließlich der bereits geprüften zulässigen Alignment-Nullbytes.

Der Fix ergänzt ausschließlich den exakt geprüften Pin in der bestehenden Liste. Inventarprüfung, GLB-Prüfsummen, zulässige Ausgabepfade, PNG-/Importformatprüfung, Schutz bereits vorhandener Dateien und abschließende Prüfung auf veränderte Quellen bleiben erhalten. Der Godot-Pin und die Modelle werden nicht geändert.

## Prüfung

Die vorhandene Export-Vertragssuite wurde auf den tatsächlich verwendeten 2081-Pin aktualisiert: **45 Tests bestanden**. Sie prüft auch unveränderte Quellen nach Entfernung der 32 erzeugten Dateien, manipulierte GLBs, unbekannte Revisionen und unerwartete Ausgaben. Ein unmittelbar benachbarter, nicht geprüfter Commitwert bleibt ausdrücklich abgelehnt.

Die Suite ist jetzt Teil des frühen Quellstand-Schritts im APK-Workflow. Ihre vollständige Ausgabe wird unter `build-proof/GODOT-EXPORT-CONTRACT-TESTS.txt` gesichert. Lokaler Testbeleg: `docs/evidence/build-2081-flutter-20261124/export-fix/export-contract-tests.log`.
