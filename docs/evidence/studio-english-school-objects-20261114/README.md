# Englische Schulsachen: Quellenfreeze vom 14. November 2026

Der geschlossene Wort-/Objektkatalog enthält jetzt 14 Gegenstände, darunter alle zehn tatsächlich erzeugten Schulsachenwörter aus Klasse 1 und dem bestehenden Klasse-2-Fallback. Die sieben Ergänzungen sind Tasche, Radiergummi, Schultasche, Schreibtisch, Sessel, Federpennal und Papier. `pen` bleibt in dieser echten Einheit `Kugelschreiber`; der bestehende Alias `Stift` für andere tatsächliche Aufgaben bleibt erhalten. Abstrakte Aufgaben der Klassen 3/4 werden dadurch nicht als native 3D-Aufgaben ausgegeben.

## Konkrete Ergebnisse

- Echte lokale Produktionsszene, explizite Plattform-/JNI-/Audiofixtures: Headless 7.177 Prüfungen / 0 Fehler; Renderer 7.228 / 0 mit 17 Original-PNGs und 196 Godot-Touchereignissen. Keine Addition dieser Zahlen.
- Renderer Exit 0 nach 867,538 Sekunden im unveränderten 900-Sekunden-Budget. Alle 17 Originalbilder wurden einzeln geöffnet. Der unabhängige Python-Readback derselben 17 Sidecars und Bilder bestätigt Kamera-/Meshprojektion, Geometrie und sichtbares Pixeldetail; das ist keine automatische semantische Bilderkennung.
- Die kleinste exponierte Aktionsfläche misst im erklärten Fixture 52 dp. Alle 14 Fälle führen exakt einmal zum Fixture-Host zurück; keine Rewardaufrufe.
- 28 reine Python-Validatorfälle bestanden ohne Skip. Neue Dart-/Flutterquellen wurden lokal nicht ausgeführt. Root hat ihre Integration in Host `50503fef8e93700d9a889e33c3d2c37fccb46e42` gemeldet; dessen tatsächlicher Producerlauf bleibt erforderlich.

Der erste Gegenlauf bleibt erhalten: drei strikte Projektionsfehler bei langen Ersthinweisen im kleinen Querformat. Die einzige ergänzende Layoutänderung reduziert im kompakten Englischheader den vertikalen Innenabstand von 14 auf 8 dp; Schriftgröße, voller Hinweistext und 48-dp-Grenze bleiben erhalten. Die neue Lesefassung hält außerdem sämtliche bestehenden Task-, Profil-, Eltern-/Voice-, Rückkehr- und Fortschrittsgrenzen.

## Exakte Integrationslisten

`native-source-upload-manifest.json` enthält vier Native-Dateien, `host-product-source-upload-manifest.json` drei Dart-/Flutterdateien. `host-probe-source-upload-manifest.json` enthält die zwei neuesten Probe-/Testdateien und die vier unveränderten ursprünglichen JSONfixtures. `source-upload-manifest.json` listet die neun tatsächlich geänderten Dateien. Die neun frühen Gitblobs wurden vollständig als UTF-8 zurückgelesen und blieben bis nach Renderer und Bildprüfung bytegleich. Historische frühe Manifeste werden nicht umgeschrieben.

## Tatsächlicher Producer-/Native-CI-Aufruf

Im gepinnten neuen Hostcheckout:

```sh
mkdir -p feature-evidence
dart tool/check_native_english_activity.dart --out feature-evidence/english-activity.json
```

Der Producer muss mit Exit 0 und `NATIVE_ENGLISH_DART_PASS` abschließen. Das exportierte JSON muss `failures: 0`, alle 14 tatsächlichen `examples` und beide zehnteiligen `school_examples` enthalten. Die neue Nativeprüfung akzeptiert keinen unvollständigen alten Siebenerkatalog.

Im eigenen Nativecheckout, mit realem Display/X11 und dem tatsächlichen Host-JSON:

```sh
godot --path . --rendering-method gl_compatibility --script res://scripts/tests/learning_english_regression.gd -- --capture --task-fixtures=/absolute/host/feature-evidence/english-activity.json --output=/absolute/evidence/english-native
```

Erforderlich sind Exit 0, `LEARNING_ENGLISH_PASS`, `learning-english-report.json` mit `failures: []`, `fixture_kind: actual_dart_producer_report`, echter Renderer, aktuelle Quellhashes und alle 17 benannten PNG-/Layoutpaare. Lokale Zahlen können bei anderen tatsächlich erzeugten Ablenkobjekten abweichen; keine alte Prüfzahl erzwingen oder übertragen. Ohne `--task-fixtures` heißen die Daten ausdrücklich `native_catalogue_fixture`, wie im hier vorliegenden lokalen Lauf. `--capture` mit Headless wird verworfen. Kein zusätzliches Environment nötig; Plattform/JNI/Audio bleiben im Desktoptest deklarierte Randfixtures.

## Grenzen

Keine Androidausführung der neuen Englischprobe, keine englische Aussprache-/Hörabnahme, keine Fold7-/60-FPS-/Thermikaussage. Der vorhandene lizenzierte Offlinepfad liest deutsche Erklärungen. Die lokale Datenquelle ist nicht der neue Dartproducer. Reale Fortschrittsvergabe, Journal, Schreibtrainer, Zwei-Kind-Wechsel und Gerätespeicherstände werden durch dieses Paket nicht zusätzlich freigegeben. Originale Renderwarnungen zu VSync, Screen-space-AA und volumetrischem Nebel sowie die vorhandene Pillow-Deprecation bleiben dokumentiert.

`final-review.json`, `evidence/final-image-review.json` und `evidence/final-runtime-source-binding.json` binden die tatsächlichen Quellen, Bilder und den begrenzten privaten Runtimegraphen. Keine Main-/Ref-/Workflowmutation durch diesen Freeze.
