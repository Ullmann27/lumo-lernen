# LUMO – verbindliche visuelle Identität (Design-Bestandsschutz)

Stand: 10.10.2026 · Vorgabe des Auftraggebers. Gilt für Flutter-App, Godot, Lumo Kart, Cards, Bauwelt und 4 Gewinnt.

## Priorität der Referenzen

1. **Die vom Auftraggeber am 10.10.2026 erneut hochgeladenen Originalbilder** sind die visuelle Zielvorgabe. Die Screenshots sind Designreferenzen, nicht automatisch bereits lauffähige Ansichten.
2. Die im Projekt vorhandenen Lumo-Markenbilder und aktuellen Funktionen bleiben erhalten. Neue Implementierung muss in diese Identität integriert werden.
3. Die drei SVG-Schemata in `docs/design/2026-10-10-lumo-games/` sind **nur technische Layout-Skizzen**. Ihre einfachen Formen, generische Füchse oder vereinfachten Hintergründe dürfen NICHT die Originalgestaltung ersetzen.
4. Generierte Konzeptbilder dienen allenfalls als ergänzende Inspiration; ohne visuelle und funktionale Abnahme dürfen sie nicht als fertiges UI, 3D-Asset oder Runtime-Screenshot ausgegeben werden.

## Originalreferenzen (im Chat; für andere Agenten gesondert mitsenden)

| Datei | Verbindlicher Bildschirminhalt |
| --- | --- |
| `50666.gif` | Lumo-Kart-Moduswahl: Schlosswelt, Lumo im blauen Kart, fünf Moduskarten, Glas-Cyan, holografisches Podest. |
| `50610.png` | Lernwelt/Weltkarte mit schwebenden Inseln, Deutsch/Mathe/Sachunterricht/Logik, XP und großem Lumo. |
| `50608.png` | Matheaufgabe mit Lumo, Sprechblase, großflächigem dunkelblauem Glas, Cyan-Auswahl. |
| `50609.png` | Belohnungs- und Levelabschluss mit Sternen, Abzeichen, Flammenserie und freischaltbarer Welt. |
| `50607.png` | Deutschaufgabe (Apfel) mit gleicher Lumo-Gestalt, identischem Header und Touch-Buttons. |
| `50632.jpg` | Vorhandene Kart-Laufzeitbeispiele inklusive Renn-HUD, Strecken und aktuell unzureichendem Menü. Dies ist für den Ist/Soll-Vergleich, nicht als neue Stilvorlage gedacht. |
| `50294.png` | Kart-Garage als zusätzliche visuelle Designidee; nicht die gewünschte Moduswahl überschreiben. |
| `50297.png` | Bestehende Lumo-Lern-App mit Start, Lernen, Spielen, Tests, Belohnungen, Profil. |
| `50288.png` | Kart-Erlebnis einschließlich Strecken-, Renn-, Werkstatt-, Ergebnis- und Introansichten. |
| `50502.png` | Test- und Kategorieauswahl der Lern-App. |

**Stand nach dem geprüften GitHub-Import:** Alle zehn Originalbilder liegen unverändert unter `docs/design/2026-10-10-lumo-games/references/`; jede Datei wurde im CI-Lauf 38045270201 mit `references/SHA256SUMS` gegen das originale Chat-Attachment geprüft. Die Bilder sind Referenzen, keine Behauptung über vorhandene Pixelidentität der App-Runtime.

## Verbindliche Designelemente

- **Figur:** derselbe orangefarbene Lumo-Fuchs mit großer Ohrenform, weiß-cremefarbenen Wangen, großen warmbraunen Augen, dunkler Nase, blauer Fliegerbrille, blauem Outfit mit cyanfarbenem L-Emblem. Kein generischer Ersatzfuchs, keine neu interpretierte Figur, keine nicht zugehörigen Charaktere.
- **Welt:** tiefblauer, sternklarer Himmel; farbig leuchtende Schwebewelten, Wasserfälle, Brücken, Schlösser, Bäume, Kristalle, magische Lernpfade; räumliche Tiefe, hochwertige weiche Lichter. Bestehende Motive nicht durch einfachen Farbverlauf austauschen.
- **Oberflächen:** abgerundete halbtransparente dunkelblaue Glas-Panels, Türkis/Cyan-Lichtkante, sanfter Glanz, goldene Belohnungseffekte, großer klarer Text, ausgewogenes dunkles Fundament.
- **Navigation:** die aktuelle Startseite, fünf Haupttabs, Lern-Weltkarte, Aufgaben, Belohnungen, Testergebnisse, Spielehub, Profil und bestehende Spielintegration bleiben funktional und im Erscheinungsbild wiedererkennbar.
- **Lehrer-/Eltern-/Kinderprofile:** Lernstände und Zuordnung, Sterne, XP und Belohnungssystem werden nicht durch eine Grafikänderung zurückgesetzt oder zusammengelegt.
- **Bewegung:** sanfte, sparsame, kontrollierte Animationen; `reduceMotion`/Ruhemodus respektieren; Funktionen dürfen nie durch Dekoration blockiert werden.
- **Fold:** Tablet- und Smartphone-Layouts sowie Fold innen und außen einschließlich Quer-/Hochformat ohne Textüberlagerung, abgeschnittene Karten, unsichtbare Hauptaktion oder unlesbar kleine Tasten.
- **Wahrhaftigkeit:** Ein visuell erzeugtes Standbild ist kein fertig implementiertes Menü. Abnahme nur nach **echten** Flutter-/Godot-/Android-Screenshots und bedienbaren Funktionen.

## Vorhandene wichtige Asset-Anker

Flutter `Ullmann27/lumo-lernen`:
- `assets/lumo_design/logo/logo_lumo.png`, `logo_lumo_kart.png`
- `assets/lumo_design/fox/fox_avatar.png`, `fox_kart_wave.png`, `fox_thumb_wink.png`
- `assets/lumo_design/bg/bg_home.png`, `bg_learn.png`, `bg_kart.png`, `bg_glass_islands.png`
- `assets/lumo_design/learning_world/learning_world_night.jpg`
- `assets/lumo_design/cards_game/logo_cards.png`, `assets/lumo_design/gameplay/build.png`

Godot `Ullmann27/lumo-godot`:
- `assets/characters/lumo/reference/01_master_character_sheet.png`
- `assets/kart/menu/lumo-world.webp`, `assets/kart/menu/*.svg`
- `scripts/games/kart_garage_menu.gd`, `scripts/games/kart_vehicle.gd`
- `scripts/creative/build_world.gd`, `scenes/creative/build_world.tscn`

## Änderungs- und Prüfregeln für Sonnet/Codex/andere Implementierer

1. Vor jeder UI-Änderung den vorhandenen Bildschirm **in der echten Runtime** aufnehmen und ein unveränderbares Vorher-Bild sichern.
2. Visuelles Ziel und betroffene Widgets/Szenen benennen; nur gezielte Änderungen im tatsächlichen Bestand durchführen.
3. **Keine** Umfärbung/Neuanordnung des gesamten Appshells; Markenfiguren, Hintergründe, Screens und funktionierende Daten nicht löschen oder durch SVG-Mockups ersetzen.
4. Änderungen an identitätsstiftenden Asset-Dateien nur in einem gesonderten, nachvollziehbaren Review mit direkten Vorher/Nachher-Vergleichen und ausdrücklicher Freigabe.
5. Jede relevante Änderung als echte Bildschirmaufnahme bei mindestens 360×800, 640×360, 1280×720 sowie einer großen Fold-/Tablet-Ansicht prüfen; falls Orientierung/maßstäbliche Entsprechung nicht verfügbar, Abweichung offen dokumentieren.
6. Flutter/Godot-Analyse, Unit-/Widget-/Gameplay-Tests, Android-Installation/Navigation und Golden-/Screenshot-Vergleich soweit verfügbar ausführen. Nicht vorhandene Tests und nicht erfolgte APK-Builds offen ausweisen.
7. Ergebnis ist erst fertig, wenn Bildsprache, echte Funktion, Lesbarkeit, Bedienbarkeit, Performance und Bestandsdaten zugleich stimmen.

**Abnahme:** Wenn Referenz und Runtime deutlich voneinander abweichen, gilt der Designauftrag als **offen**, selbst wenn der CI-Build technisch grün ist.
