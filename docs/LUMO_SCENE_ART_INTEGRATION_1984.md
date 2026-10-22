# Lumo – transparente Szenen, Integration auf geprüfter Quizshow-Basis

Stand: 18. Oktober 2026. Entwicklungszweig auf Build 1983, **kein veröffentlichter Build 1984**.

Die vorbereitete Integration aus PR #372 wurde für die neuere Lern-/Kart-Basis übernommen. Es gibt keine automatische Übernahme der älteren Basis oder der älteren Story-Dateien; die neue Story-Reader-Struktur mit `LumoStoryScene`, Kapitelseiten und Quizfragen bleibt erhalten.

| Szenenplatzierung | Erwarteter Grafikpfad |
| --- | --- |
| Sternenkarte – Seite 1 | `assets/lumo_design/fox/lumo_story_library_cutout.png` |
| Sternenkarte – Seite 2 | `assets/lumo_design/fox/lumo_story_starmap_cutout.png` |
| Jahreszeiten | `assets/lumo_design/fox/lumo_seasons_cutout.png` |
| Zahlen bis 100 | `assets/lumo_design/fox/lumo_math_cutout.png` |

**Wichtiger Ist-Zustand:** Diese vier transparenten Binär-PNGs sind noch nicht im GitHub-Zweig vorhanden und wurden nicht als integriert ausgegeben. `LumoSceneArtPanel` zeigt bis dahin vorhandene native Lumo-Fuchsposen statt leerer oder unsichtbarer Inhalte. Es handelt sich um optionale Dekorationen ohne Antwort-/Touch- oder Lernstandslogik.

## Prüfgrenzen

- Bereits verbunden: vier Anzeigeorte, Semantikbeschreibungen, PNG-/Fallback-Anzeige, eigener Widgettest.
- Noch zu prüfen: vollständiger Flutter-Test-/Analyse-Durchlauf auf dem neuen Head, Bilder auf echten 320dp-/Fold-Abmessungen, Android-Emulatortour, performance impact, die tatsächlichen PNGs auf Transparenz/Hintergrund/Größe.
- Alte Daten, Journal, Schreibtrainer, PIN von Godot 4.6.3, Kart-Quellen und bisherige Veröffentlichungen werden nicht geändert.
- PR #372 als Herkunft der vorbereiteten Anzeigeorte weiterhin erhalten. Ein Merge des älteren PR ist für diese Stufe nicht erforderlich.
- Erst nach Originaldatei-Einbau und erfolgreicher Android-Gesamtprüfung eine neue Versionsnummer sowie eine eigenständige APK freigeben.
