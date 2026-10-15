# Spiele- und Fold-Kandidat 1934

Produktbasis: Flutter PR270 (91fc9e25), Godot PR57 (853175c6). Die bestehende Lern-, Stimmen-, Profil- und Spielkette bleibt erhalten. Der Zweigvergleich steht in BRANCH-ASSET-AUDIT.md; nur die vier tatsächlich verwendeten originalen UI-Crops aus PR183 wurden übernommen und gegen ihr Originalmanifest gehasht.

## Nachgewiesene Reparaturen

- Garage: Native Auswahlbuttons lassen Drag-Ereignisse zum ScrollContainer durch. Scrollbeginn bricht den Button-Tap ab; normale Taps wählen weiterhin den tatsächlichen Fahrer/das Kart/die Welt.
- Kartspalten werden nach der Auswahlbreite in dp angeordnet. Titel und gesperrte Hinweise dürfen keine angrenzenden Karten überdecken.
- Würfel-Wettlauf verwendet bei kurzem Querformat auch unter700dp eine seitliche Bedienfläche. Vergrößerte Schrift und Rückmeldungen bleiben erreichbar.
- Mengen-Anmalen und Buchstaben-Lücke scrollen auch im kurzen Querformat. Sämtliche10 Mengenfelder beziehungsweise4 Buchstaben bleiben echte Eingabeflächen. Rechenhaus und Sternepfad verwenden dieselbe ruhige Originalwelt-Oberfläche.
- Cards-Intro erhält den originalen Lumo vor der bestehenden Kartenrückseite; Sammlungen, Kartenregeln und Decks bleiben unverändert.

## Asset-Pipeline

`tools/render_board_game_objects.py` modelliert Würfel mit korrekten gegenüberliegenden Augenzahlen (Summe7), zwei Spielsteine und eine Spielkachel. Blender4.3/Cycles liefert neun transparente384px-PNGs, vier GLBs und eine editierbare.blend-Datei unter source/. Diese Flutter-Spiele verwenden **vorgerenderte 3D-Grafiken**, keine neue3D-Runtime. Die Würfelzahl wird vom vorhandenen Zufalls-/Zugsystem bestimmt, nicht vom Bild.

Godot enthält zusätzlich echte GLB-Truhe und Laterne aus `tools/create_creative_objects.py`, jeweils eine zusammengefasste Mesh-Instanz mit3PBR-Materialien und UVs. Originale wood-Grain-Textur und editierbareQuelle bleiben im Godot-Projekt. Laterne952Dreiecke, Truhe2376Dreiecke; öffentliche Bauteil-IDs, Grundflächen und Collider sind erhalten.

Keine Meshy-Aufträge, bezahlten Generierungen oder Sprach-API-Aufrufe. Das bereits lizenzierte Meshy-Lumo-Rig und dessen Attribution bleiben erhalten. Der hier fehlende Meshy-Login wurde nicht umgangen.

## Prüfumfang und offene Punkte

Belege unterscheiden Flutter-Testbilder, echte Godot-GL-Aufnahmen und spätere Android-Emulator-Aufnahmen. Die Fold-Matrix nutzt ausdrücklich simulierte Pixelgrößen und Dichten; kein physischesFold wurde geprüft. Godot-Szenenzähler im Software-Renderer sind keine AndroidFPS-Messung. Lokale Stimme: technische Wiedergabeprüfung, keine menschliche Hörabnahme.

Die neue APK folgt erst vom eingefrorenen, überprüften gemeinsamenCommit. Offene Gegner-Rigs, Gesichtsmorphs, vollständige3D-Neuentwicklung allerMinispiele, weitereLehrplanlücken und Play-Veröffentlichung sind nicht als fertig deklariert.
