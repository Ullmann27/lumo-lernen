# LUMO – transparente 3D-Szenen für Story, Sachunterricht und Mathematik

Stand: 18. Oktober 2026 · Status: **Entwicklungsbranch; Binärgrafiken noch nicht hochgeladen; ungeprüft**

## Zuordnung

| Anzeige | Assetpfad | Einbaupunkt |
|---|---|---|
| Sternenkarte, Seite 1 | `assets/lumo_design/fox/lumo_story_library_cutout.png` | `LumoStoryReaderScreen._buildPage` |
| Sternenkarte, Seite 2 | `assets/lumo_design/fox/lumo_story_starmap_cutout.png` | `LumoStoryReaderScreen._buildPage` |
| Welt-Abenteuer/Jahreszeiten | `assets/lumo_design/fox/lumo_seasons_cutout.png` | `JahreszeitenScreen.build` |
| Mathe-Abenteuer/Zahlen bis 100 | `assets/lumo_design/fox/lumo_math_cutout.png` | `ZahlenBis100Screen.build` |

Die vier transparenten PNG-Dateien werden separat als `Lumo_Artwork_Einbaupaket.zip` bereitgestellt. Die ZIP ist **keine** GitHub-Datei und muss noch in diesen Branch entpackt bzw. übertragen werden. Der Zielordner ist bereits in `pubspec.yaml` registriert.

## Technische Ausführung

- Neues `LumoSceneArtPanel`: 3D-artige Glasoberfläche, kontrastreiche Farben, semantische Bildbeschreibung und optionales transparentes PNG.
- Fallback auf vorhandenes `LumoFoxPose`, falls die Bilddateien noch fehlen.
- Originale Fragen, Antworten, Seitenzahlen, TTS, XP, Belohnungen, Lernprogress und Navigation bleiben dynamisch und unangetastet.
- Bei anderen Geschichten bleibt die vorhandene Fuchs-Illustration erhalten; die beiden erzählungsspezifischen Motive gelten zunächst ausschließlich für den Titel mit `Sternenkarte`.
- `Wer wird Lumo-Meister?` wurde nicht bearbeitet.

## Offene Freigabeschritte

1. PNGs aus dem ZIP in den angegebenen Pfad committen.
2. `flutter pub get`, `flutter analyze`, `flutter test`, Bild-/Overflow-Tests bei 360×800 und Fold-Layouts ausführen.
3. Echte App starten und beide Storyseiten sowie Jahreszeiten- und Mathe-Aufgaben in der UI überprüfen.
4. Erst anschließend eine APK generieren und den Build einschließlich SHA-256 dokumentieren.

**Keine** bestanden gemeldeten Build-, Widget- oder APK-Tests für diesen Branch; hier war kein Flutter-SDK und keine ausführbare Geräteumgebung verfügbar.
