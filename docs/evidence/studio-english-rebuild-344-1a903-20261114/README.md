# Englische 3D-Wortzuordnung – neue Fassung nach Laufzeitverlust

Stand: 14. November 2026. Die fünf neuen Native-Dateien beruhen auf dem exakt wiederhergestellten Native-Commit `34421df83566dd4773420cc2a225887956459435`. Sie sind inzwischen unverändert in Feature-Commit `e4e5ce03e644a2f23b01a96f1d340a882a1798c4` enthalten. Der vollständige Git-Tree wurde erneut gelesen und alle fünf Blobs, Modi und Größen abgeglichen. Main und die veröffentlichte Kandidaten-Pinbindung wurden durch diesen Agenten nicht verändert.

Diese Fassung wurde neu implementiert. Die früheren, mit der alten Laufzeit verlorenen fünf Native-Dateien und deren 630 Prüfungen beziehungsweise zehn Bilder werden nicht als Beleg dieser neuen Bytes verwendet.

## Produktumfang

Die bestehende Lernwelt erhält den geschlossenen Aktivitätstyp `english_objects`. Die tatsächlich vom Host erzeugten Wörter sind **book, pen, ruler, ball, car, sun und apple**. Jeder zulässige Descriptor bindet ein englisches Wort, seine geprüfte deutsche Bedeutung und genau drei verschiedene Objekte aus diesem Katalog. Das Kind sieht unterscheidbare räumliche Modelle, Original-Lumo und das aktuelle Zielwort. Es wählt über einen echten 3D-Ray-Touch oder die gleichwertigen nummerierten Schaltflächen. Falsche Auswahl bleibt ein Lernversuch. Der erste Hinweis beschreibt den Gegenstand, der zweite markiert ihn; die Auswahl bleibt beim Kind.

Die Darstellung nutzt reale Godot-Meshes mit eigenen Buchseiten, Stiftspitze, Linealmarken, Ballstreifen, vier Autorädern, Sonnenstrahlen sowie Fruchtstiel und Blatt. Die bestehenden Original-Lumo-, Atelier- und Materialdateien bleiben unverändert. Die mobile Anordnung verwendet die vorhandene sichere Randmessung; kurze Queransichten erhalten eine kompakte Bedienzeile. Alle exponierten Aktionen werden mit mindestens 48 dp geprüft, die nominelle Mindesthöhe beträgt 52 dp. Zusätzliche Projektionsprüfungen verhindern, dass geometrisch unbedeckte Objekte lediglich als unlesbare Miniaturen erscheinen.

Die native Übung schreibt keine Antwort, Sterne, XP oder Lernfortschritte. `Zur Aufgabe` verwendet den unveränderten Rückkehrpfad mit derselben Session und `status=illustrated`. Die tatsächlich zu lösende Host-Aufgabe bleibt erhalten. Auch Pause, Stop und die bestehende Lizenz-/Elternfreigabe für Sprache bleiben im bisherigen Ablauf. Lediglich die sichtbare Beschriftung der Sprachschaltfläche wird in kurzer englischer Queransicht zu `Anhören` beziehungsweise `Stopp` verkürzt.

Die vorhandene Offline-Sprachschnittstelle ist deutsch. Sie erhält passende **deutsche Erklärungen**. Eine englische Zielwortaussprache, neue Stimme, neue Cloud-Anbindung oder Phonemsynchronität wird nicht behauptet.

## Tatsächlich ausgeführte Prüfungen

Die folgenden Zähler gehören zu verschiedenen Läufen und werden nicht addiert.

| Lauf | Tatsächliches Ergebnis | Grenze |
| --- | --- | --- |
| Neue Katalogprüfung, headless | 1.021 Prüfungen, Exit 0, 12,331 s | Native-Katalog, explizite Insets-/JNI-/Audiofixtures |
| Neue vollständige Renderprüfung | 1.051 Prüfungen, Exit 0, 235,546 s, zehn PNGs | Echter lokaler Godot-X11/Software-Renderer, Katalogfixture |
| Original-Dart-Producer in der Native-Szene | 1.012 Prüfungen, Exit 0, 12,060 s | Echtes unverändertes Host-JSON; headless, keine neuen PNGs |
| Unveränderte `learning_world_regression.gd` | 5.340 Prüfungen, Exit 0 | Testquelle identisch Native344 |
| Unveränderte `learning_studio_regression.gd` | 183 Prüfungen, Exit 0 | Testquelle identisch Native344 |
| Unveränderte `learning_sharing_regression.gd` | 1.811 Prüfungen, Exit 0 | Testquelle identisch Native344 |

Die neue Hauptprüfung führt je Lauf 98 tatsächliche Godot-`ScreenTouch`-Ereignisse aus. Sie prüft richtige und falsche Auswahl, beide Hilfestufen, Pause/Resume, Neustart, Rückkehr, Sessionbindung, unveränderte Aufgaben-/Profilfelder und ausbleibende native Belohnungs-/Fortschrittswrites. Die Zahl der Mesh-Prüfungen hängt von den tatsächlich gewählten Gegenständen ab. Die 1.012 Prüfungen mit echten Dart-Distraktoren sind deshalb kein abgeschwächter 1.021er-Vertrag.

Das echte Producer-JSON stammt unverändert aus Host `bdd86f289a165ea5140a01607d78fcf4c31c98c6`, Artefakt `14115223622`. Das vorhandene Original-ZIP wurde für die Quellenbindung nochmals gestreamt: 343.010.045 Bytes, SHA256 `22eebaca28f20260013060cf9d31503370b1f157c4bb075f2f94076bcae6adae`. Genau die zwei Originalmitglieder `feature-evidence/english-activity.json` und `feature-evidence/HOST-SOURCE.txt` wurden vollständig gelesen und gegen die vorhandene Extraktion verglichen. Die JSON-Datei hat SHA256 `4f3df3fe61f45c2b899d1e50e71ea3f4980c1d78b92547fb7ca676be0a6f198b`, auch nach dem Lauf. Sie enthält acht bestandene Dart-Szenarien, 1.060 Dart-Assertions und sieben reale Beispiele. Dieser Dart-Lauf wurde hier nicht erneut ausgeführt.

## Tatsächlich geöffnete Bilder

Alle zehn nachstehenden PNGs wurden einzeln geöffnet. `evidence/visual-review.json` bindet die tatsächlichen Bytes, Abmessungen und Befunde. Die Bilder stammen aus `evidence/renderer-compact-captures/`.

| Datei | Größe | Geprüfter Zustand |
| --- | --- | --- |
| `english-ball-960x540-start.png` | 960×540 | Zielwort und drei getrennte Gegenstände |
| `english-ball-960x540-hint.png` | 960×540 | Gezielte Umrandung, weiterhin eigene Auswahl |
| `english-ball-960x540-complete.png` | 960×540 | Sichtbare Wort-/Bedeutungszuordnung und Rückkehr |
| `english-book-412x915-start.png` | 412×915 | Hochformat mit getrennten Gegenständen |
| `english-book-412x915-complete.png` | 412×915 | Vollständiger Abschluss- und Rückkehrtext |
| `english-ruler-640x360-start.png` | 640×360 | Korrigierte Mindestgröße und kompakte Bedienung |
| `english-car-2400x1080-start.png` | 2400×1080 | Deklarierte linke/untere Cutoutfixture |
| `english-pen-1080x2400-start.png` | 1080×2400 | Deklarierte obere/untere Cutoutfixture |
| `english-sun-960x540-start.png` | 960×540 | Unterscheidbares Sonnenmodell |
| `english-apple-960x540-start.png` | 960×540 | Unterscheidbare Frucht mit Stiel/Blatt |

Die ersten Zwischenläufe bleiben erhalten: drei echte Hochformat-Überlappungen wurden über tatsächlich projizierte Modellgrenzen korrigiert. Der erste Renderlauf hatte einen numerischen PASS, wurde aber wegen der zu kleinen 640×360-Szene visuell verworfen. Derselbe Stand fällt im nachgetragenen Größenvertrag an fünf konkreten Stellen. Die finale kompakte Darstellung besteht denselben Vertrag. Keine Fehlerdatei wurde durch eine spätere PASS-Datei ersetzt.

## Direkter Prüfaufruf und CI-Anschluss

Der Testpfad ist `scripts/tests/learning_english_regression.gd`. Er braucht `--output=<Verzeichnis>`; CI übergibt zwingend das tatsächliche Producer-JSON über `--task-fixtures=<Datei>`. Es gibt keine zusätzlichen produktspezifischen Umgebungsvariablen. Private XDG-Verzeichnisse trennen lokale Testdaten von bestehenden Spielständen.

Der folgende Aufruf dokumentiert den tatsächlich ausgeführten Lauf. Eine spätere Wiederholung muss ein neues Ausgabeverzeichnis verwenden, damit die Originalbelege unverändert bleiben.

```bash
godot --headless --path /tmp/lumo-english-rebuild-344-1a903 \
  --rendering-method gl_compatibility \
  --script res://scripts/tests/learning_english_regression.gd -- \
  --output=/workspace/scratch/5987865ae883/qa/studio-english-next-20261114/rebuild-344-1a903/evidence/actual-producer-headless/captures \
  --task-fixtures=/workspace/scratch/5987865ae883/qa/feature-bdd86-flutter-artifact/extracted/feature-evidence/english-activity.json
```

Ein echter Renderer verwendet denselben Skriptaufruf ohne `--headless` und zusätzlich `--capture`. Headless-Capture wird ausdrücklich abgewiesen. Der lokale tatsächliche X11-Aufruf und sein 420-Sekunden-Budget stehen unverändert in `evidence/renderer-compact/run.json`; das bestehende Werkzeug `tools/run_local_renderer.py` bleibt Native344-identisch.

Erfolg verlangt Prozess-Exit 0, Marker `LEARNING_ENGLISH_PASS` und den Originalbericht `learning-english-report.json` mit leerem `failures`-Array. Für tatsächliche Hostdaten muss `fixture_kind=actual_dart_producer_report` und `task_fixture_sha256` dem Original-Producer entsprechen. `source_sha256` bindet alle fünf ausgeführten Dateien. Der Bericht enthält sieben Fälle, zehn Beobachtungszustände und die echten Inputereignisse. Im Renderlauf werden zusätzlich PNG-Namen und SHA256 pro Bild gespeichert. Die positive Prüflogik wurde für die Größenkorrektur erweitert, keine bisherige Bedingung entfernt.

## Quellen- und Abnahmegrenzen

Die private Laufzeit ist ausdrücklich ein geprüfter Teilgraph mit 40 Native344-Basisdateien, neun unveränderten Autoloads und Originalassets. Nur die private `project.godot`-Startszene wurde auf die bestehende Lernwelt gesetzt. Ungenutzte dynamische Routerziele sind nicht vollständig kopiert. `runtime-source-binding.json`, `runtime-current-source-binding.json` und `runtime-source-final-check.json` dokumentieren diese Grenze und alle benutzten Bytes. Shared Router/HostBridge und Android-Hooks gehören der separaten Rootintegration.

Es gibt keine neue Android-, Fold7-, 60-FPS- oder Gesamtfreigabe aus diesen lokalen Läufen. Insets sind klar gekennzeichnete Layoutfixtures; der gemeinsame MobileRuntime-Logtext ist kein neuer JNI-Messbeleg. Die JNI-/Audio-Gegenstelle ist ein benannter Testadapter. Ein-Kind-Scope und unveränderte Fortschrittsdatei ersetzen keine Zwei-Kind-, Journal-, Schreibtrainer- oder Altspielstandmigration. Die entsprechenden Produktmodule wurden nicht geändert.

Die Originalprotokolle behalten die tatsächlich ausgegebenen Warnungen zu Compatibility-AA, Volumetric Fog und beim lokalen Renderer V-Sync. In den abschließenden Läufen wurden keine `ERROR`-Zeilen beobachtet; daraus wird keine Fehlerfreiheit anderer Jobs abgeleitet. Die neue Pflicht-CI auf dem Feature-Commit sowie spätere echte APK-Prüfungen sind gesonderte Belege.

`source-candidate-manifest.json` und `source-upload-manifest.json` bleiben historische Zwischenstände. Maßgeblicher Quellenabschluss ist `final-source-upload-manifest.json`; `evidence-upload-manifest.json` listet ausschließlich explizite Dokumentationsziele.
