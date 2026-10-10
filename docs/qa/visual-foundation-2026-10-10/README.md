# Lumo: Grafik-Grundgerüst und Astra-Übergabe

Die technische Vorarbeit dieser Phase ist abgeschlossen. Grundlage ist der
neuere Build-1926-Stand, nicht der frühere Build 1922. Die Grafik ist damit
noch nicht als referenzgleiche AAA-Produktion abgenommen. Dafür sind die
Originalbilder, echte Laufzeitaufnahmen, editierbare 3D-Quellen und ein enger
Arbeitsauftrag vorbereitet.

## Quellen und unveränderter Bestand

- Ausgangs-App: [dcebfbc, Build 1926](https://github.com/Ullmann27/lumo-lernen/commit/dcebfbc469c3f6d2fdee39cc33e3c5eef0b6cf7e).
- Neuer Cards-Produktstand: [63fae077](https://github.com/Ullmann27/lumo-lernen/commit/63fae07783b5458b9ea66e3798bc29c610e41546).
- Godot-Laufzeit-Pin bleibt [ec1040c2](https://github.com/Ullmann27/lumo-godot/commit/ec1040c2ab18f2ed207eee6c8490608cbb6a5518).
- 3D-Export und Godot-Aufnahmen: [Werkzeugstand 884441b](https://github.com/Ullmann27/lumo-godot/commit/884441bc53b76ae72fc7d9397bd2238f2d585b40).

Der Godot-Produktcode wurde in dieser Phase nicht verändert. Bestehende
Kart-Änderungen, Audio-Schutz, Sulafat-Einstellungen, Schreibcoach,
Namenseingabe, Profile, Wallet und Fortschrittsdaten werden nicht auf einen
älteren Stand zurückgesetzt. Keine Datenmigration, keine neue globale
Farbwelt, kein Austausch der Original-Illustrationen, kein Merge in Main.

## Umgesetzte technische Grafikvorarbeit

- Cards bekommt im kurzen Querformat eine reservierte Spielfläche. Die
  Zugnachricht wandert links neben den Tisch; die redundante zweite
  Zuganzeige entfällt nur in diesem platzkritischen Layout.
- Der Titel bleibt vollständig lesbar. Ton-, Pause- und Avatar-Symbolbuttons
  haben explizite 48-Pixel-Touchflächen statt themeabhängiger 40 Pixel.
- Ruhemodus beziehungsweise reduzierte Bewegung stoppen die Tischstaub-
  Animation und den Zug-Puls; der Puls stoppt auch beim Gegnerzug.
  Dies ist keine Behauptung, dass damit sämtliche vorhandenen App-Animationen
  neu geprüft wurden.
- Die Aufnahme-/Export-Werkzeuge erfassen Quellcommit, lokale Änderungen,
  Renderer, Kamera-/Poseparameter und SHA-256-Prüfsummen.
- Das Paketwerkzeug weist veraltete oder schmutzige Aufnahmen, falsche
  Dimensionen, geänderte Originalreferenzen und unpassende Godot-Pins zurück.
  Dokumentationsänderungen allein erzwingen keinen neuen 3D-Export.

## Echte Bilder

Die Bilder im Unterordner `screenshots/` wurden aus den echten Flutter-Widgets
mit den gebündelten Nunito-Schriften erzeugt, nicht durch Bildgenerierung.
`cards-before-640x360.png` stammt vom unveränderten Build-1926-Ausgangscode;
`cards-after-640x360.png` vom Cards-Commit 63fae077. Der nebeneinandergelegte
Vergleich ergänzt nur Beschriftungsstreifen und verändert keine Bildinhalte.

Das vollständige Astra-Paket enthält außerdem echte Cards-/Avatar-/Pause-
Aufnahmen bei 360×800, 640×360, 1280×720 und 1200×896 sowie drei Godot-Menü-
und vier 900×900-Modellansichten. Godot verwendet Software-OpenGL;
die Einzelmodellansichten sind ausdrücklich ein separates Inspektionsstudio.
Diese Bilder sind weder Android-Gerätetests noch ein Gameplay-Nachweis.

## Ausgeführte Prüfungen

- 54 gezielte Flutter-Tests für Regeln, Deck, Controller-Lebensdauer,
  Pause/Fold, Eingaben und das neue Layout: bestanden.
- Vier Screenshot-Tests, jeweils Spiel, Avatar und Pause: bestanden.
- Analyse der sechs betroffenen Flutter-Dateien/Testdateien: keine Probleme.
- Neun Offline-Prüfungen des Übergabewerkzeugs: bestanden, einschließlich
  negativer Kontrollen für veraltete Bilder und geänderte Exportquellen.
- Geänderte GDScript-Werkzeuge und Capture-Fixtures: Godot-Parseprüfung
  bestanden; echte Menü- und Modell-Capture-Läufe mit striktem Fehlerprüfer
  bestanden.
- Godot-Export, Blender-Import/Archiv/GLB-Export und Godot-Reimport: bestanden.
  Inventar: 24 Mesh-Objekte, 124.210 Dreiecke, 62 Materialressourcen,
  vier Bilder, keine Armature; gleiche Geometrieanzahl und Materialbelegung.

Der Blender-Build meldet eine nicht verfügbare optionale Draco-Bibliothek.
Der tatsächlich verwendete unkomprimierte GLB-Export und Godot-Reimport
funktionieren; eine Draco-Kompression wird nicht behauptet. Gleiche
Geometrieanzahl bedeutet keine abschließende Material-, UV-, Rig- oder
Android-Performance-Freigabe.

Die vorherigen [Fold-Prüfungen](https://github.com/Ullmann27/lumo-godot/actions/runs/38055937553)
und [Stage-2-Prüfungen](https://github.com/Ullmann27/lumo-godot/actions/runs/38055934253)
sind für denselben Kart-Produktcommit f672e02 grün. Sie wurden lokal nicht
ohne Produktänderung erneut gestartet.

## Astra jetzt gezielt einsetzen

### Hoch zuerst

Die Moduswahl anhand von Original `50666.gif` und der echten Kart-Aufnahme
prüfen. `50294.png` nur für Garagen-/Materialdetails verwenden, nicht als
Ersatz der Moduswahl. Kameraframing, Figur-/Kart-Größe, Lichtführung,
Materiallesbarkeit, Glas und Cyan-/Gold-Akzente gezielt verfeinern.
Zuerst nur Original-Lumo mit Comet und die Moduswahl, keine neue Konzeptserie
und kein gleichzeitiger Neuaufbau aller Welten.

### Sehr hoch nur für die schwierige 3D-Arbeit

Die echte Figur/Kart unterscheiden sich noch sichtbar von den Referenzen.
Die vorbereitete `.blend`-/GLB-Quelle für gezielte Gesicht-/Wangen-/
Augenproportionen, Ohren, Brille, Fellübergänge, Kart-Silhouette und
Materialkonsolidierung verwenden. Bei belegtem Bedarf Topologie/UVs/Rig oder
komplexe Shader bearbeiten. Originalidentität und funktionierende
Animation-/Fahr-/Kollisionspfade erhalten.

Die Modellquelle ist ein statischer Snapshot des vorhandenen Bestands,
kein neu geriggter, mobileoptimierter AAA-Charakter. Die Laufzeit wurde
absichtlich noch nicht durch diesen Snapshot ersetzt.

### Technische Arbeit weiter bei Sol

Gewöhnliche Programmierung, Fehlerbehebung, Tests, Godot-Pin-Integration und
Android-Builds benötigen keinen neuen Astra-Grafikauftrag. Nach der
visuellen Überarbeitung genau einen neuen Produktkandidaten prüfen und
anschließend eine Android-APK bauen.

## Übergabedateien

- `Lumo-Grafik-Grundgeruest-Astra-Uebergabe.zip`: zehn Originalreferenzen,
  19 echte Aufnahmen, vorheriger Cards-Stand, `.blend`, Original-/Roundtrip-
  GLB, Prüfberichte, Logs, Metadaten und enger Astra-Auftrag.
- `ASTRA_HANDOFF.md` im Archiv: Referenzprioritäten, wiederverwendbare
  Code-/Asset-Einstiege, High-/Very-High-Abgrenzung und Integrationsregeln.
- `handoff-manifest.json`: exakte App-/Godot-Quellen, Bild- und Assetprüfsummen
  sowie ausdrücklich offene Art-/Android-Abnahme.

In dieser Grundgerüst-Phase wurde keine neue APK gebaut und keine
Pixelgleichheit oder Geräte-FPS versprochen. Es gab keine neue
Bildgenerierung, keine kostenpflichtige Assetbestellung und keinen Release.
