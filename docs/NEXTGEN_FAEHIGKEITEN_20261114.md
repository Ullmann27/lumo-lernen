# LUMO Next Generation – geprüfte Fähigkeiten und Ausführungsgrenzen

Stand: 14. November 2026. Diese Übersicht beschreibt die tatsächlich benutzbare Entwicklungsumgebung und die in diesem Auftrag ausgeführte Arbeitsverteilung. Eine Fähigkeit ersetzt keinen Nachweis für ein bestimmtes APK oder Endgerät.

## Fähigkeitsmatrix

| Aufgabe | Einordnung | Tatsächlicher Nachweis / Grenze |
| --- | --- | --- |
| Vorhandene Godot-Szenen, GDScript, Shader und Ressourcen direkt ändern | **direkt umsetzbar** | Godot 4.6.3 ist lokal vorhanden. Produktionsdateien wurden aus den konkreten GitHub-Quellen bearbeitet, importiert und in echten Engine-Prüfungen ausgeführt. |
| Vorhandene GLB-Modelle und Originalrigs untersuchen und bearbeiten | **direkt umsetzbar** | Blender 4.3.2 ist lokal vorhanden. Die Charakterarbeit baut auf dem Original-Lumo mit 65 Knochen auf; Bewegungsclips und Gesichtserweiterungen sind am gemeinsamen Charakterpfad angeschlossen. |
| Neue echte geometrische Objekte erzeugen | **direkt umsetzbar** | Native Englischobjekte, Lernatelier und Spielgeometrie werden als Meshes erstellt und in den produktiven Godot-Szenen benutzt. Die sichtbaren Belege stammen aus dem Renderer. |
| Körperanimationen, Zustände, Kamera und Eingaben integrieren | **direkt umsetzbar** | Gemeinsame Charakter-/Plattformanbindung und echte Godot-ScreenTouch-Abläufe sind implementiert. Eine einzelne Bildschirmaufnahme ersetzt keine Bewegungs- oder Kollisionsprüfung. |
| Flutter-/Godot-Verbindung bearbeiten und mit echten Komponenten prüfen | **mit vorhandenen Werkzeugen umsetzbar** | Quelländerungen erfolgen über die GitHub-Verbindung; die CI enthält Flutter/Dart und Android-Werkzeuge. Die tatsächlichen Dart-/Godot-Paare laufen als getrennte Prozesse. Lokales Flutter und Dart sind in dieser Umgebung nicht installiert. |
| Android-Host kompilieren | **mit vorhandenen Werkzeugen umsetzbar** | Der aktuelle Host2e20 hat den tatsächlichen Android-Host-Kompilierjob erfolgreich abgeschlossen. Das ist getrennt vom vollständig gepackten, installierten APK. |
| APK bauen und auf API35/API37 prüfen | **mit vorhandenen Werkzeugen umsetzbar** | Die bestehenden CI-Emulatorläufe bauen und installieren echte APKs; Quelle, PCK, Signatur, Version, Spielstand, Eingaben und Rückkehr werden gebunden. Ein neuer vollständiger Kandidat ist erst nach seinen eigenen bestandenen Gates freigegeben. |
| Rendererbilder und Bewegungsdateien prüfen | **direkt umsetzbar** | Godot-Renderer, Blender und FFmpeg7.1.5 stehen lokal zur Verfügung. CI-Originalarchive werden anhand Größe/SHA256/ZIP-CRC geprüft; ausgewählte aktuelle Originalbilder werden tatsächlich geöffnet. Ein Test-„PASS“ allein gilt nicht als Bildreview. |
| GitHub-Commits, getrennte Zweige, Draft-PRs und CI | **direkt umsetzbar** | Beide Repositories sind les- und schreibbar. Änderungen verwenden explizite Blobs, vollständige Text-Readbacks, rekursive Treevergleiche und erwartete Zweigköpfe. Der produktive Main wurde nicht verändert. |
| Drei zusätzliche Entwicklungsagenten | **direkt umsetzbar** | Genau drei Agenten arbeiten neben Root: learning_worlds, character_animation und games_worlds. Die tatsächlichen Zuständigkeiten stehen unten. |
| Physisches Samsung Galaxy Z Fold7: 60FPS, GPU-/CPU-Framezeiten, Temperatur und Touchlatenz | **derzeit blockiert** | Kein physisches Zielgerät und kein lokales adb stehen zur Verfügung. Software-Renderer, Headless-Läufe, Simulatorprofile und Emulatoren liefern keinen solchen Gerätenachweis. |
| Weiterer Ausbau der Gesichts- und Lippenanimation | **mit vorhandenen Werkzeugen umsetzbar** | Vorhanden ist amplitudenabhängige Artikulation der geschlossenen Schnauze. Ein vollständiges Visemsystem und eine offene Mundhöhle sind noch nicht implementiert. Eine tatsächlich angehörte Tonabnahme wird ebenfalls nicht behauptet. |

## Tatsächliche Teamaufteilung

| Verantwortlicher | Ausgeführte Bereiche |
| --- | --- |
| Root | Quellstände, Flutter-/Godot-Integration, Quellpins, CI-/APK-Gates, kontrollierte Gitintegration, gemeinsame Evidenz und Endabnahme. |
| learning_worlds | Mathematik-/Lernvisualisierung, Englischobjekte und Vertragsdaten, Touch-/Layoutkorrekturen, Werkstattbeiträge und unabhängige Reviews. |
| character_animation | Original-Lumo, Blender-Body-/Gesichtsarbeit, Quizstudio, Kamera-/Eingabeanschlüsse, unabhängige Integrationsreviews und Modulübersicht. |
| games_worlds | Bauwelt, Puzzle, Schatzsuche, C4 und Memory, Spiel-/Speicherabläufe, Android-Prüfer und Bildreviews. |

Die Aufteilung verwendet keine fünf erfundenen Teams. Gemeinsam genutzte Dateien werden von einem Eigentümer bearbeitet und anschließend von Root kontrolliert integriert.

## Gemeinsame Abnahmegrenzen

- Produktion, lokale Fixtures, echte Dart-/Godot-Paare, JVM-/Python-Verträge, CI-Emulatoren und physische Hardware werden getrennt ausgewiesen.
- Ein alter bestandener Lauf oder ein altes Bild genehmigt keinen neuen Quellstand.
- Die vorhandenen Grafikprofile sind belegt; ihre Budgets sind keine gemessene Fold7-Freigabe.
- Die früher gemessenen CPU-Kosten einzelner Animationspfade sind kein aktueller Gesamtframe- oder GPU-Nachweis.
- Main bleibt geschützt. Entwicklungskandidaten und Originalbelege liegen in getrennten GitHub-Zweigen und Draft-PRs.
