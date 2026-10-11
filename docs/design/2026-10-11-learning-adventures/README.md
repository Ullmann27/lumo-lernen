# Lumo Lernmodule: echte Modernisierung und Prüfstand

Stand: 11. Oktober 2026. Dieser Meilenstein modernisiert die vorhandenen direkten Lernmodule auf Basis von „Plus bis 10“. Er ist keine neue App, keine neue Aufgabenarchitektur und noch keine neue Android-Version.

## Verbindliche Quelle und Integrationsgrenze

- **Produktcommit:** `91388c3b463f4dae4590cdf76251d531259d8a0a`.
- **Eigener Branch:** `computer/lumo-learning-adventures-2026-10-11`.
- **Geprüfte Ausgangsbasis:** `bef1403ed5d0243f8c6daca2717e998081cab15e` aus [Android-Integrations-PR #259](https://github.com/Ullmann27/lumo-lernen/pull/259).
- **Neue Version:** keine. Die vorhandene APK 1928 enthält diese Lernoberflächen noch nicht.
- **Godot:** Produktpin unverändert. Das neuere geprüfte Menü aus [Godot-PR #56](https://github.com/Ullmann27/lumo-godot/pull/56) ist nicht durch diesen UI-Meilenstein in eine APK übernommen worden.
- **Main:** kein Merge, kein Force-Push, keine Änderung fremder Entwicklungsbranches.

Die vollständigen Quelländerungen dieses Produktcommits umfassen 38 Dateien. Nachfolgende Nachweis-/Dokumentationscommits ändern diese geprüfte UI-Implementierung nicht.

## Tatsächlich implementiert

- **Gemeinsamer Rahmen:** Original-Lumo aus dem bestehenden Designsystem, vorhandene Bibliothekswelt, blaue Hologlas-Flächen, Nunito, echte Aufgaben- und Erfolgszähler sowie die vorhandene App-Navigation.
- **Smartphone:** vollständiger Lumo-Kopf unter dem Profilbereich, große Antwortflächen, ausreichend kurze Karten und nötigenfalls scrollbar erreichbare Inhalte bei großer Schrift.
- **Fold und breite Flächen:** Lumo mit Begleithinweis links, gut lesbare Lernkarte rechts. „Plus bis 10“ nutzt dort ebenfalls diese Zweiteilung, behält am Smartphone seinen bisherigen Aufbau und verwendet seinen vorhandenen Charaktercontroller.
- **Mengen:** Originale lokal modellierte Apfel- und Bonbongrafiken statt Emoji-Platzhaltern. Alle tatsächlichen Objekte bleiben erhalten, bei Minus ist genau die weggenommene Anzahl markiert.
- **Zahlenfolge:** native Material-Pfeile statt von Emoji-/Unicode-Ersatzschriften abhängiger Glyphen.
- **Uhr:** proportional angepasste Uhrgröße, lesbare Ziffern, kürzere Zeiger und disponierte TextPainter. Die tatsächliche Uhrzeit und Antwortbewertung bleiben unverändert.
- **Jahreszeiten:** vier eigene lokal in Blender modellierte und gerenderte Dioramen. Bildaufgaben verwenden gebündelte PNGs statt des früheren externen Bildaufrufs.
- **Ereignisbezogene 2D-Reaktionen:** Öffnen einer Aufgabe, ermutigende Fehlerreaktion und Jubel nach tatsächlich abgeschlossener Speicherung. Bestehende Ruhe-/Reduktionsoptionen bleiben berücksichtigt.

Die Lernoberfläche verwendet gerenderte 2D-Bilder und den vorhandenen 2D-Charakter. Sie wird nicht als live gerenderte 3D-Lernszene, neues Skelett, Lippensynchronisation oder bereits angeschlossener intelligenter Unterrichtsassistent bezeichnet.

## Wo die Funktionen zu finden sind

Die vorhandenen direkten Themenmodule sind über die Akademie/Lernübersicht und deren bestehende Modul-Registry erreichbar. Eine geänderte Bildschirmdatei allein beweist nicht, dass jeder alternative Lernweg denselben Bildschirm verwendet.

| Bereich | Direkte modernisierte Module |
| --- | --- |
| Mathematik | Plus bis 10, Minus bis 10, Zahlen bis 10, Formen, Uhrzeit, Geld, Zahlen bis 100, kleines und großes Einmaleins, Brüche |
| Deutsch | Artikel, Mehrzahl, Wortarten, Zeitformen, vorhandenes Wort-Diktat |
| Sachunterricht | Tiere, Farben, Jahreszeiten, Wetter, Verkehr |

Das sind 19 direkte Bildschirmdateien und 20 Registry-Varianten, weil beide Einmaleins-Varianten dieselbe Bildschirmdatei verwenden. Bei `d1_woerter` öffnet die Akademie mit aktivem Wortmodus weiterhin zuerst den geschützten Schreibcoach; der modernisierte ältere Diktatbildschirm wird dadurch nicht fälschlich als dessen neuer Standardweg ausgewiesen.

## Tatsächliche Prüfungen

| Prüfung | Ergebnis | Aussagegrenze |
| --- | --- | --- |
| Vollständige Flutter-Suite | 991 bestanden, 107 übersprungen, 0 Fehler | Linux-Testlaufzeit, keine vollständige Android-Abnahme |
| Strenge Layout-/Mengenmatrix | 70 bestanden | Smartphone, Safe Areas, Fold, breite Fläche, große Schrift, alle Minusmengen 3–10 und Zählmengen 1–10 |
| Fortschritts-/Modulregressionen | 47 bestanden; ebenfalls in der vollständigen Suite enthalten | Tatsächliche Antworten, Speicherung, Fehler-/Retrypfade, Bonus-/Daily-Zuordnung und Navigation |
| Neue aktuelle Capture-Matrix | 80 bestanden, 80 echte PNGs | 20 Varianten × vier Bildschirmformate |
| Rekonstruierte Altversion | 20 bestanden, 20 echte PNGs | Fünf Altmodule × vier Formate aus Original-Gitquellen |
| Geschützte Methoden | 91 unverändert | Kommentar-/Whitespace-normalisierter Vergleich; einzige erlaubte Bewertungsmethodenänderung ist die UI-Zähler-Aktualisierung mit `setState` |
| Analyse des geänderten Bereichs | keine Probleme | Lernmodule, Rahmen, Mengenbilder, Tokens und zugehörige Tests |
| Gesamte Flutter-Analyse | 20 bestehende Info-Lints, keine Errors/Warnings | Standardkommando liefert deswegen weiterhin Exit 1; nicht als vollständig bereinigte Analyse ausgeben |
| Whitespace-/Python-Prüfung | erfolgreich | `git diff --check`, Syntaxprüfung des Nachweiswerkzeugs |

Die 107 Skips werden ausdrücklich nicht als bestandene Tests gezählt. Darunter sind 80 optionale neue Screenshot-Cases, die separat mit aktiviertem Capture-Verzeichnis vollständig ausgeführt wurden; die übrigen 27 vorhandenen Skips bleiben offen bzw. abhängig von ihren bisherigen Voraussetzungen. Kein bestehender Test wurde deaktiviert, um grün zu werden.

Die vollständigen Dateien für Fortschrittsgrenze, Sulafat-Stimme/-Client, App-Zustand, Companion-Host und Schreibcoach sind in diesem Meilenstein unverändert. Bestehende Kinderprofile wurden nicht bearbeitet, gelöscht oder zurückgesetzt.

## Tatsächliche Fehlerursachen und Reparaturen

- **Überläufe:** der erste strenge Layoutlauf fand zu große Zeiger-/Formflächen, zu hohe Antwortkacheln und horizontale Plus-Bedienelemente bei großer Schrift. Die endgültige Darstellung berücksichtigt die tatsächlich verfügbare Panelhöhe, nicht einen global geschätzten Bildschirmwert.
- **Zufällige größere Mengen:** spätere vollständige Läufe fanden weitere schmale Smartphone-Randfälle mit zweizeiligen Bonbons und Punktmengen. Normale Aufgaben bleiben unverändert zufällig; eine optionale RNG-Eingabe ermöglicht ausschließlich reproduzierbare Testaufgaben. Alle relevanten Mengen werden nun ausdrücklich überprüft.
- **Falsche Testannahme:** der Zahlenvergleich hat absichtlich genau zwei gültige Wahlmöglichkeiten. Der Test erwartet deshalb die vom echten Aufgabentyp vorgesehene Anzahl und verlangt weiterhin vollständig bedienbare Antworten; es wurden keine zusätzlichen falschen Optionen erfunden.
- **Veraltete UI-Selektoren:** Deutsch-/Sachtests suchten frühere GestureDetector-Strukturen und einen alten Toolbar-Pfeil. Sie suchen nun die echten neuen Antwort- und Zurückelemente. Die Prüfung der gespeicherten Fächer, Themen, Fehlantworten, Zähler und Belohnungen wurde nicht abgeschwächt.
- **Diktat-Zielwort:** eine überbreite Suche nach beliebigem Großbuchstabentext konnte auch eine Überschrift treffen. Ein stabiler Schlüssel bezeichnet nun genau das tatsächlich aufgedeckte Zielwort, dessen Wortformat weiterhin geprüft wird.
- **Externe Jahreszeitenbilder:** die bisherige Netzwerk-Bildabhängigkeit war im strengen Offline-Test fehlerhaft. Vorhandene Aufgaben nutzen jetzt eigene gebündelte Bilder, ohne neue externe Kindertexte oder kostenpflichtige Generierung.
- **Testinfrastruktur:** ein vollständiger Lauf scheiterte zuerst am vollen Datenträger beim Kopieren des Dart-Compilers. Der fehlgeschlagene Lauf wurde nicht als App-Ergebnis gewertet. Wiederherstellbare eigene Zwischendateien wurden entfernt; Compiler-Tempdateien verwenden die vorhandene RAM-Tempfläche. Danach wurde die gesamte Suite tatsächlich vollständig erneut ausgeführt.

## Echte Bilder und Originalreferenz

Die verbindliche visuelle Referenz ist das vom Nutzer bereitgestellte `51024.jpg` mit „Plus bis 10“. Die Gegenüberstellungen zeigen jeweils **VORHER – ORIGINALREFERENZ – NACHHER** für Plus, Minus, Formen, Uhrzeit und Zahlen bis 10, jeweils am Smartphone und in der Fold-Konfiguration.

Die Bilder stammen aus den tatsächlich gestarteten Flutter-Modulwidgets mit originalen Nunito-/Material-Schriften. Im Vergleich wurden ausschließlich gleichmäßige Skalierung, separate Ränder und Beschriftungen verwendet; keine Lernansicht wurde retuschiert oder durch einen Entwurf ersetzt. Rohbilder im Download bleiben bytegleich.

- **Smartphone:** 360 × 800 logische Pixel, Dichte 1.
- **Kompaktes Querformat:** 640 × 360 logische Pixel.
- **Breite Fläche:** 1280 × 720 logische Pixel.
- **Fold:** konfigurierter Viewport 2176 × 1812 physische Pixel bei Dichte 2,25; PNG-Aufnahme mit Pixelratio 1, daher rund 968 × 806 logische Bildpixel.
- **Wichtige Grenze:** dies sind echte Flutter-Testlaufzeitframes, keine Aufnahme eines physischen Samsung-Geräts und noch kein Nachweis einer auf Android installierten neuen Version.
- **Altversion:** der Linux-Host besitzt keine vollständige historische Emoji-Ersatzschrift. Sichtbare alte leere Emoji-Glyphen sind ein Testhost-Grenzfall und werden nicht dem ursprünglichen Android-Gerät zugeschrieben.
- **Aufgaben:** Generatoren wählen zufällige Aufgaben. Vorher und Nachher zeigen deshalb nicht zwingend dieselben Zahlen, Formen oder Uhrzeiten.

Das CRC-geprüfte ZIP enthält 100 Rohbilder, zehn Vergleiche, die Originalreferenz sowie SHA-256-/Quellmetadaten. Es ist 59.013.175 Bytes groß; SHA-256 `b812f9c15e681b5ecef313ca168afbc14dfbb0a4af49fb048c6b150640afb7d9`. Dieses ZIP enthält keine APK.

## Betroffene Dateien

- **19 vorhandene Bildschirmdateien:** `lib/features/learning_modules/` für die oben genannten direkten Module.
- **Neue Präsentationswidgets:** `lib/widgets/design/lumo_learning_module_frame.dart`, `lib/widgets/design/lumo_quantity_art.dart`.
- **Tokens:** `lib/theme/lumo_visual_tokens.dart`.
- **Regressionsselektoren:** `test/learning_modules/deutsch_sach_module_progress_test.dart`.
- **Neue Prüfungen:** `test/design/learning_adventure_layout_test.dart`, `test/design/learning_adventure_capture_test.dart`.
- **Lokale Art:** sechs PNGs unter `assets/lumo_design/icons/`; zwei editierbare `.blend`-Quelldateien in `source/`.
- **Reproduzierbare Werkzeuge:** `tools/migrate_learning_adventure_ui.mjs`, `tools/prepare_learning_baseline.mjs`, `tools/package_learning_adventure_evidence.py`, `tools/render_learning_objects.py`, `tools/render_learning_seasons.py`.
- **Nachweise:** diese Dokumentation, Originalframes, Vergleichsbilder, Metadaten und tatsächliche Logs in diesem Dokumentationsordner.

Die Logs liegen bytegetreu als `.log.gz` vor. Mit `gzip -cd logs/<dateiname>.log.gz` lässt sich die unveränderte ursprüngliche Konsolenausgabe einschließlich historischer Fehlermeldungen lesen.

## Reproduzieren

```bash
node tools/migrate_learning_adventure_ui.mjs --verify
flutter test --concurrency=1 test/design/learning_adventure_layout_test.dart
flutter test test/learning_modules
flutter test --concurrency=2
LUMO_LEARNING_CAPTURE_DIR=/tmp/lumo-after \
  flutter test --concurrency=1 test/design/learning_adventure_capture_test.dart
```

Die echte Altversion wird nur für Aufnahmen rekonstruiert:

```bash
node tools/prepare_learning_baseline.mjs
LUMO_LEARNING_CAPTURE_DIR=/tmp/lumo-before \
  flutter test --concurrency=1 test/design/learning_adventure_baseline_1928_test.dart
```

Danach ausschließlich die generierte, nicht eingecheckte Datei `test/design/learning_adventure_baseline_1928_test.dart` wieder entfernen. Der dauerhaft eingecheckte Baseline-Generator und sämtliche normalen Tests bleiben erhalten.

Die Baseline verwendet Original-Gitquellen aus `bef1403...`; nur relative Import-URIs werden mechanisch für den Capture-Kontext aufgelöst. Ein Manifest hält deren Original-SHA-256 fest. Die gemeinsame Fortschritts-/Sprachlogik war während dieser UI-Phase unverändert.

## Noch nicht abgeschlossen

- **Android:** kein neuer Build, keine neue Installation, kein Update-/Audio-/Gerätetest dieses UI-Commits. APK 1928 bleibt eine ältere technische Vorabversion.
- **Sulafat:** das vollständige produktive `/speech`-/Authentifizierungs-/Playback-Audit und die 50 echten Sprachsituationen folgen als nächster Arbeitsstream. Vorhandene Stimme und Provider sind nicht ersetzt worden.
- **Intelligenter Begleiter:** dieser Meilenstein verbindet einfache echte UI-Ereignisse mit vorhandenen 2D-Reaktionen; er implementiert noch nicht die neue einheitliche Aufgabenereignisschnittstelle.
- **Vorlernen und Unterricht:** „Mit Lumo Neues entdecken“ und „Lumo erklärt es mir“ sind noch nicht implementiert bzw. abgenommen.
- **Gesamte App:** weitere alternative Lernwege, alte Dialoge, noch vorhandene Emoji-Motive ohne passende Originalillustration und der gesamte App-Rundgang brauchen weiterhin eine eigene Prüfung.
- **Pädagogik:** keine vollständige österreichische Lehrplanabdeckung oder externe Pädagogenfreigabe behaupten. Ein systematischer Inhalts-/Curriculumaudit steht aus.
- **Marktreife:** Datenschutz-, Sicherheits-, Familienrichtlinien-, Store-/AAB-/Signatur- und externe Freigaben sind noch nicht als vollständig erfüllt nachgewiesen.
- **Performance:** keine gemessenen 60 FPS, keine Hardware-Frame-Time- oder Speichergrenzabnahme.

## Sofortiger nächster Schritt

Die neueste Nutzeranweisung macht **Lumo Lernen zu Priorität 1**. Nach Sicherung dieses Meilensteins folgt die Prüfung der bestehenden Sulafat-Kette und der aktuellen Backend-Konfiguration; anschließend die vorhandene Companion-/Nachhilfeintegration und das getrennte freiwillige Vorlernen. Große zusätzliche Kart-Strecken und Fahrzeuge dürfen dies nicht verzögern. Die bestehende Kart-Integration, Sulafat-Identität, Profile und Lernstände bleiben geschützt.
