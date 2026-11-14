# LUMO: verfügbare Fähigkeiten und belegte Grenzen

Stand: 2026-11-14 18:45:46 UTC. Host `28462a75`, Native `29080ef8`. Eine verfügbare Fähigkeit ist keine Abnahme einer konkreten Funktion oder eines Endgeräts.

| Bereich | Einordnung | Tatsächlicher Stand |
| --- | --- | --- |
| Godot-Szenen, GDScript, Shader und Materialien bearbeiten | **direkt umsetzbar** | Godot 4.6.3 ist lokal wieder erreichbar. Produktionsquellen werden mit expliziten Gitständen bearbeitet und durch echte Engineprüfungen kontrolliert. |
| Original-GLB, Rig und Bewegungsclips bearbeiten | **direkt umsetzbar** | Blender 4.3.2 ist lokal erreichbar. Die gesicherte Charakterarbeit verwendet den Original-Lumo mit 65 Knochen und erhaltenen Originalclips; zusätzliche Bewegungsclips und Gesichtserweiterungen sind in den verwendeten Charakterpfaden angeschlossen. |
| Neue geometrische Lern- und Spielobjekte erzeugen | **direkt umsetzbar** | Programmatische Meshes und Blender stehen zur Verfügung. Die aktuelle Englischgalerie verwendet echte dreidimensionale Gegenstände in der Godot-Lernszene. |
| Animation, Kamera, Kollision und Eingaben integrieren | **direkt umsetzbar** | Die bestehenden Godot-Produktpfade und Eingabeverträge sind zugänglich. Aktuelle Rendererbilder und tatsächliche Dart-/Godot-Prozesspaare liegen vor. |
| Flutter und Godot zusammenführen | **mit vorhandenen Werkzeugen umsetzbar** | Die vollständige Flutter-Suite auf dem korrigierten Host hat 2.632 Tests bestanden, ohne Fehler oder Skips. Alle 24 neuen ASR-/Memoryfälle wurden einzeln in den Originalergebnissen geprüft. Lokal wurde weder Flutter noch Dart ausgeführt. |
| Android-Host und vollständiges APK erstellen | **mit vorhandenen Werkzeugen umsetzbar** | Tatsächliche Android-Klassenkompilierung ist auf diesem Host sowohl im Feature- als auch im Studio-Lauf erfolgreich. Der neue Studio-Lauf muss Verpackung und seine Androidprüfungen noch abschließen. |
| Szenen rendern und Bilder/Videos prüfen | **direkt umsetzbar** | Godot, Blender und FFmpeg 7.1.5 sind erreichbar. Der aktuelle Nativequellstand besitzt 49 geprüfte Originalaufnahmen; neue Host-/Native-Autoritätsläufe werden separat gesichtet und gebunden. Software-Rendererbilder beweisen keine Hardwarebildrate. |
| GitHub, CI und drei Entwicklungsagenten | **direkt umsetzbar** | Root arbeitet mit den drei vorhandenen Agenten learning_worlds, character_animation und games_worlds. Getrennte Dateieigentümer, vollständige Text-Readbacks, Bildhashbindungen und kontrollierte Refbewegungen verhindern unbemerkte Überschreibungen. |
| Physische Fold7-Prüfung auf Android 17 | **derzeit blockiert** | In dieser Umgebung steht kein angeschlossenes Zielgerät zur Verfügung; lokal ist adb nicht vorhanden. CI-Emulatoren können die echte Gerätebildrate, Temperatur, Energieaufnahme und Touchlatenz nicht bestätigen. |
| Vollständige Viseme und umfangreiche Gestik | **mit vorhandenen Werkzeugen umsetzbar** | Diese Erweiterung ist technisch möglich, aber nicht vollständig implementiert. Vorhanden ist unter anderem amplitudenabhängige Verformung der geschlossenen Schnauze. Eine offene Mundhöhle oder vollständige Phonemsynchronität wird nicht behauptet. |
| Hörabnahme auf dem Zielgerät | **derzeit blockiert** | Die lokale Sprachintegration besitzt erfolgreiche Kompilierungs- und Vertragstests. Diese ersetzen weder tatsächliche Modellinferenz noch angehörte Ausgabe auf einem Fold7. |

## Tatsächliche Zuständigkeiten

- **Root:** Quellstände, Integration, kontrollierte Gitbewegungen, Build, APK-, API35-, Update- und Publisherprüfung.
- **learning_worlds:** Lernvisualisierung, Englisch, Aufgabenbindung, Lesebelege und aktuelle Flutterprüfung.
- **character_animation:** Original-Lumo, Animation, Quiz, unabhängige Reviews und API37-Abnahme.
- **games_worlds:** Bau-/Spielmechanik, Memory, Save-/Interaktionsprüfungen und Creative-Androidabnahme.

Die lokale Umgebung war zwischenzeitlich ausgefallen und wurde wieder erreichbar. Die begleitenden Versionsprüfungen belegen den gegenwärtigen Werkzeugstand; sie werden nicht als neuer Renderlauf ausgegeben. Die produktiven Main-Zweige wurden nicht verändert.

## Belege

- [Aktueller Featurelauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/43624674585)
- [Laufender Studio-Kandidat](https://github.com/Ullmann27/lumo-lernen/actions/runs/43626348519)
- [Geprüfter Native-Gesamtlauf](https://github.com/Ullmann27/lumo-godot/actions/runs/43611803408)
- [Tatsächliche 24 neue Flutterergebnisse](https://github.com/Ullmann27/lumo-lernen/blob/e048e1f61b22e04424244a23bbd99591443e5977/docs/evidence/host-28462-flutter-acceptance-20261114/actual-new-cases-review.json)
- [Original-Lumo-Herkunft](https://github.com/Ullmann27/lumo-godot/blob/29080ef8cd1a5b385eeeec97976fbefd31280427/assets/characters/lumo_facial/ATTRIBUTION.md)
