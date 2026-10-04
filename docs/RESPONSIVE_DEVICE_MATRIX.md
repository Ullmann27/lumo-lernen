# Responsive Device Matrix – Lumo Lernen

## Grundprinzip

Die App wird **nicht** für S26, S27, Fold 7 oder ein bestimmtes Tablet separat gebaut. Sie wird anhand der jeweils verfügbaren Flutter-Layoutbreite adaptiv gerendert. Damit passt dieselbe Codebasis auch zu zukünftigen Geräten mit anderen Auflösungen, Pixeldichten oder Seitenverhältnissen.

Die zentrale Implementierung liegt in `lib/widgets/design/` (Breakpoints zentral dort anlegen, nicht pro Bildschirm).

## Fensterklassen

| Klasse | logische Breite | typische Nutzung | Navigation | Inhaltsaufbau |
|---|---:|---|---|---|
| Compact | bis 359 dp | sehr schmaler Handy-/Fold-Cover-Screen | unten | kompakte Abstände, reduzierte Sekundärtexte |
| Phone | 360–599 dp | normale und Ultra-Smartphones | unten | Hero oben, 2-spaltige Lern-/Game-Grids, 4 Hauptkacheln in einer Reihe |
| Medium | 600–839 dp | kleines Tablet, breiter Fold-Modus | links | 2–3 Inhaltsspalten, mehr Luft, größere Assets |
| Expanded | 840–1199 dp | Fold innen, Tablet Hoch-/Querformat | links | 3–4 Spalten, großzügiges Dashboard |
| Large | ab 1200 dp | große Tablets / Desktop-Vorschau | links + Insight Rail | Hauptbereich + Fortschrittsspalte |

Die Schwellenwerte sind keine Gerätemodell-Erkennung. Entscheidend ist immer die aktuell verfügbare Breite.

## Smartphone – S26/S27/S26 Ultra und vergleichbare Geräte

- Portrait ist primärer Modus.
- Untere Navigation mit fünf Hauptbereichen.
- Touch-Ziele mindestens ca. 44–48 dp.
- Der obere Hero skaliert, ohne dass Lumo abgeschnitten wird.
- Hintergründe verwenden `BoxFit.cover`; wichtige Bildmotive liegen im mittleren Safe-Zone-Bereich.
- Vier Hauptkacheln bleiben sichtbar, werden auf sehr schmalen Displays textlich verdichtet.
- Mathe-Antworten bleiben in einer Reihe, solange sie lesbar sind; bei späteren längeren Antworten auf 2×2 wechseln.
- Keine absolute Positionierung an physische Pixelwerte koppeln.

## Fold – Außendisplay

- Wird wie ein schmales Smartphone behandelt.
- Eine Aufgabe pro Fokusbereich.
- Wenig Text, große Interaktionselemente.
- Lumo kleiner und klar freigestellt.
- Kein dreispaltiges Dashboard erzwingen.

## Fold – Innendisplay

- Seitenleiste statt Bottom Navigation.
- Hauptinhalt erhält deutlich mehr Raum.
- Ab ca. 1060 dp kommt rechts eine Insight-/Fortschrittsspalte hinzu.
- Lernkarten dürfen 3–4 Spalten verwenden.
- Mathe-Hilfe kann Bild/Objekte und Lehrer-Lumo nebeneinander anzeigen.
- Für Geräte mit sichtbarem Hinge/Falz muss bei der finalen Geräteprüfung `MediaQuery.displayFeatures` ausgewertet werden. Kritische Interaktionen dürfen nicht genau auf einer trennenden DisplayFeature-Grenze liegen.

## Tablets

- Hochformat: seitliche Navigation, 2–3 Spalten.
- Querformat: seitliche Navigation + optionaler Fortschrittsbereich.
- Maximalbreite für den Kerninhalt verhindert überbreite Karten auf sehr großen Displays.
- Große Tablets sollen wie ein echtes Lern-Dashboard wirken, nicht wie eine hochskalierte Handy-App.

## Bild-Assets und Safe Zones

### Hochformat-Hintergründe

- Basis: 1080×1920.
- Kein Text und keine UI direkt im Bild.
- Wichtiges Motiv im mittleren 55–65-%-Bereich halten.
- Untere 35–40 % visuell ruhiger, weil dort Karten liegen.
- Seitenränder dürfen auf breiten oder schmalen Geräten beschnitten werden.

### Breitbild-Hintergrund

- `bg_wide.png`: 2400×1600.
- Für Fold/Tablet und Desktop-Vorschau.
- Wichtige Motive nicht direkt am linken/rechten Rand.

### Fuchs-Assets

- Transparente PNGs.
- `BoxFit.contain`, niemals `cover`.
- Keine harte Pixelbreite als einzige Größenregel; Höhe aus verfügbarem Layout ableiten.

## Testmatrix vor Abnahme

Mindestens diese Größen im Emulator/Golden-Test prüfen:

- 320×720 dp – sehr schmales Telefon/Fold Cover.
- 360×800 dp – Standard-Smartphone.
- 412×915 dp – großes/Ultra-Smartphone.
- 600×960 dp – kleines Tablet/Intermediate.
- 768×1024 dp – Tablet Portrait.
- 840×720 dp – Fold-Innendisplay-artig.
- 1024×768 dp – Tablet Landscape.
- 1280×800 dp – großes Tablet/Desktop-Vorschau.

Abnahme: kein Overflow, kein abgeschnittener Fuchs, keine unlesbaren Texte, keine Buttons unter 44 dp, Navigation stets erreichbar, SafeArea berücksichtigt.
