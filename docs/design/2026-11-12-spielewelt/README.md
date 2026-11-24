# Spielewelt: ruhige Bühne und direkte Spieleauswahl

Stand: 12.11.2026. Umsetzung des freigegebenen Entwurfs A auf dem tatsächlichen Host-Stand `43f1d7c2b847be757123a59133967e85a58407dd` (0.13.4+2016). Dies ist der Flutter-UI-Anteil des folgenden Integrationskandidaten; Version, nativer Godot-Pin und APK-Auslieferung werden gemeinsam im bestehenden Buildpfad integriert.

## Sichtbares Ergebnis

Die bestehende Spieleübersicht erhält eine zusammenhängende dunkle Bühne, eine kleine Titelzeile mit dem tatsächlichen Sternestand, sechs hervorgehobene Spielkacheln und vier weitere direkt erreichbare Spiele. Breite Ansichten zeigen Lumo neben dem Raster, schmale Ansichten führen mit einer kompakten Begrüßung in das zweispaltige Raster. Die vorhandenen Original-Lumo-Grafiken bleiben erhalten. Einzelne Spielsymbole sind native Canvas-Grafiken; Karten, Bauklötze und Puzzle sind keine verkleinerten Menü-Screenshots.

Auf Spielen entfällt die zusätzliche obere AppShell-Titelleiste, weil die Spielewelt bereits Titel und Sternestand enthält. Die Hauptnavigation und der kompakte Hilfe-/Sprachzugang bleiben erreichbar. Auf anderen Bereichen bleibt die bestehende Kopfzeile erhalten.

Alle zehn Portal-Identitäten und ihre ursprünglichen Routen bleiben erhalten: Memory, Cards, Puzzle, Jump & Run, Rhythm, Schatzsuche, Bauwelt, Lumo Kart, 4 Gewinnt und Quizshow. Zusätzliche bereits vorhandene Modi bleiben über den bisherigen Bereich erreichbar. Profile, Speicherstände, Belohnungslogik, Lernmodule, Schreibtrainer und Journal werden durch diese UI-Änderung nicht verändert.

## Tatsächliche Aufnahmen

Die PNGs sind unretuschierte Flutter-Rasterausgaben der echten Widgets bei zweifacher Rasterauflösung. `shell-*` enthält die produktive `AppShell` einschließlich Navigation, Hilfeleiste und simulierten Safe Areas. Die übrigen Aufnahmen zeigen den tatsächlichen `GamesContent` ohne Shell. Sie sind keine Gerätefotos, Emulatoraufnahmen oder FPS-Nachweise. Die 0 Sterne stammen vom leeren Testprofil; der angezeigte Wert ist im Produkt an den echten App-Zustand gebunden.

| Ansicht | Logische Größe | Aufnahme |
| --- | --- | --- |
| Fold geschlossen, vollständige AppShell | 344 × 882 | [shell-fold7-cover.png](after/shell-fold7-cover.png) |
| Fold offen, Portrait, vollständige AppShell | 690 × 829 | [shell-fold7-open-portrait.png](after/shell-fold7-open-portrait.png) |
| Fold offen, Landscape, vollständige AppShell | 840 × 560 | [shell-fold7-open-landscape.png](after/shell-fold7-open-landscape.png) |
| Spieleinhalt, vorher | 690 × 829 | [before/fold7-open-portrait.png](before/fold7-open-portrait.png) |
| Spieleinhalt, nachher | 690 × 829 | [after/fold7-open-portrait.png](after/fold7-open-portrait.png) |

Alle sieben Inhaltsgrößen und die drei Shell-Größen liegen unter `after/`. `capture-manifest.json` enthält Abmessungen, Dateigrößen und SHA-256. Die beiden Vorher-Aufnahmen wurden aus einem separaten Worktree des oben genannten exakten Basiskommits mit demselben vorhandenen Capture-Test aufgenommen. Sie belegen den unmittelbaren Ausgangsstand; daraus wird keine vollständige historische Wiederherstellung einer älteren Spielewelt behauptet.

## Validierung

21 gezielte Widget-Tests bestanden:

- 7 Inhaltsgrößen mit tatsächlicher PNG-Erzeugung: 412 × 915, 344 × 882, 412 × 2400, 690 × 829, 840 × 560, 768 × 1024 und 1024 × 768.
- 2 neue Zustand-/Zugänglichkeitstests: Sternestand 317 → 322 und Größenwechsel mit 180 % Text. Alle zehn Spielziele bleiben vorhanden und mindestens 48 × 48 dp groß.
- 7 bestehende Spielelayout-/Routingtests einschließlich aller Portalziele.
- 3 echte AppShell-Größen mit erreichbarem Kart-Ziel, einmaliger Titel-/Sternenzeile und weiter vorhandenem Hilfezugang.
- 2 bestehende Tests der Lern-Zurücknavigation als Schutz der games-only Shell-Anpassung.

Flutter-Analyse der geänderten Produktions- und Testdateien: keine Befunde. Rohprotokolle liegen unter `validation/`.

```sh
LUMO_HUB_CAPTURES="$PWD/docs/design/2026-11-12-spielewelt/after" flutter test --no-pub test/games/spielwelt_hub_capture_test.dart test/games/spielwelt_stage_test.dart test/games/games_world_layout_test.dart test/games/spielwelt_routing_test.dart
LUMO_HUB_CAPTURES="$PWD/docs/design/2026-11-12-spielewelt/after" flutter test --no-pub test/games/spielwelt_shell_capture_test.dart test/design/learning_shell_back_navigation_test.dart
flutter analyze --no-pub lib/features/games/spielwelt lib/features/games/games_content.dart lib/app/app_shell.dart test/games/spielwelt_stage_test.dart test/games/spielwelt_shell_capture_test.dart test/games/spielwelt_hub_capture_test.dart
```

Ein während der Validierung beobachteter Hänger beim Landscape-Rasterbild wurde vor Abschluss behoben: Die konkaven Canvas-Spielzeichen benötigen keine weichen `drawShadow`-Schatten. Eine versetzte gefüllte Silhouette erhält die räumliche Tiefe ohne diese Schatten-Tessellierung. Anschließend bestanden sämtliche Capture-Größen wieder bei unverändertem Rasterfaktor 2; es wurde keine Prüfung durch Reduzieren der Aufnahmequalität umgangen.

## Native Kart-Grenze und Buildumgebung

Der Flutter-Kart-Launcher startet über den bestehenden `lumo_lernen/bridge`-Kanal die native Godot-Activity. Das auf den Nutzerbildern sichtbare schmale 3D-Fenster und dessen doppelte Navigation stammen aus dem nativen Godot-Menü. Dieser UI-Commit verändert den Bridge-/Save-Vertrag nicht. Die neue große echte 3D-Inszenierung wird im zugehörigen Godot-Quellstand umgesetzt. Die Lumo-Figur in dieser Flutter-Spieleübersicht bleibt die vorhandene animierte Originalgrafik; sie ist kein neu eingebettetes 3D-Modell.

Die vorhandene lokale portable/unified Buildkette ist vorbereitet: Flutter 3.44.9 / Dart 3.12.2, Android-Plattform 36, Build Tools 36.0.0, NDK 28.2.13676358 und Android-Precache. `scripts/portable-android.sh doctor` beendet sich mit Exit 0. Verwendet wird der bereits vorhandene unveränderte öffentliche Lumo-Testschlüssel; Paketidentität und Signierungsregeln bleiben unverändert. JDK 21.0.13 ist vorhanden, während die geprüfte CI JDK 17 verwendet. Lokale Emulator-/Displayprüfung ist durch die in dieser Umgebung blockierten Socket-/Displayfunktionen begrenzt; daraus wird kein bestandener Android-Gate abgeleitet. Gradle-/Maven-Caches werden erst vom gemeinsamen Build gefüllt.

Der normale Git-CLI-Push war mangels CLI-Schreibauth nicht möglich. Die Quellstände werden stattdessen über den autorisierten GitHub-Connector mit Git-Tree/Commit und geprüftem erwarteten Branchkopf gesichert. Das ist eine Quell-/UI-Prüfung; APK-Provenienz, Signaturprüfung, Android-Emulator-Tour und direkte Release-APK benötigen den anschließend gemeinsam integrierten Godot-Pin und Build.
