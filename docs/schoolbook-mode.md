# Lumo Lernen – Heftmodus / schulnahes Aufgabendesign

## Ziel

Der Heftmodus sorgt dafuer, dass digitale Aufgaben in Lumo Lernen dem Denkweg aus Schule und Heft folgen. Die App soll keine Buchseiten kopieren, sondern allgemeine Grundschul-Methoden digital, eigenstaendig und kindgerecht darstellen.

## Grundsatz

Nicht erlaubt:

- Buchseiten scannen und als App-Aufgaben verwenden
- Verlag-Illustrationen kopieren
- konkrete Arbeitsblaetter 1:1 nachbauen
- geschuetzte Layouts oder Markenoptik imitieren

Erlaubt und gewuenscht:

- Zwanzigerfeld
- Rechenhaus / Zahlenhaus
- Zahlenstrahl mit Spruengen
- Schreiblinien
- Silben-/Lautfelder
- Blitzlicht-Raster
- eigene Lumo-Visualisierung dieser Methoden

## Neue Widgets

Datei:

`lib/features/schoolbook/widgets/schoolbook_task_widgets.dart`

Enthalten:

- `SchoolbookTaskCard`
- `TwentyFrameVisual`
- `NumberLineJumpVisual`
- `NumberHouseVisual`
- `BlitzlichtGrid`
- `WritingLineBox`
- `SoundChoiceCard`

## Aktuelle Integration

Datei:

`lib/features/learning/renderers/adaptive_task_renderer.dart`

Der bestehende AdaptiveTaskRenderer nutzt die neuen Widgets fuer:

- `VisualType.dots`
  - Plus/Mengenbild
  - Minus/Wegnehmenbild
  - Minus ueber 10: Zwanzigerfeld + Zahlenstrahl-Sprung

- `VisualType.tenOnes`
  - Zehner/Einer in schulnaher Darstellung

- `VisualType.numberLine`
  - Zahlenstrahl oder Minus-Spruenge

- `VisualType.syllables`
  - Schreiblinien-/Heftoptik

- Fallback
  - einfache Plus-/Minus-Ausdruecke im Prompt werden erkannt und schulnah visualisiert

## Didaktische Muster

### Minus ueber 10

Beispiel:

`15 - 8`

Denkweg:

1. Von 15 zuerst 5 weg bis zur 10.
2. Von 8 bleiben noch 3.
3. 10 - 3 = 7.

Digitale Darstellung:

- Zwanzigerfeld mit 15 aktiven Kugeln
- 8 werden markiert/weggestrichen
- Zerlegung `15 - 5 - 3 = 7`
- Zahlenstrahl mit zwei Sprungboegen

### Rechenhaus

Dachzahl bestimmt die Summe.

Beispiel:

- Dach: 10
- 5 + 5
- 6 + 4
- 2 + 8

Widget:

`NumberHouseVisual(target: 10)`

### Blitzlicht

Schnelle, kurze Aufgaben in Rasterform.

Widget:

`BlitzlichtGrid(items: [...])`

### Deutsch / Schreiben

Schreiblinien fuer Wort- und Silbenaufgaben.

Widget:

`WritingLineBox(placeholder: 'Haus', cells: 4)`

St/Sp und Lauttraining:

`SoundChoiceCard(word: 'Stern', choices: ['St', 'Sp'])`

## Naechste sinnvolle Schritte

1. `TaskType`/`VisualType` erweitern:
   - `twentyFrame`
   - `numberHouse`
   - `blitzGrid`
   - `writingLine`
   - `soundChoice`

2. `TaskInstanceGenerator` erweitern:
   - gezielte Aufgaben fuer Minus ueber 10
   - Zahlzerlegung mit Rechenhaus
   - Blitzlicht-Raster als Session-Aufgabe
   - Deutsch-Wortfelder und St/Sp

3. OCR/Fotoscan klassifizieren:
   - Rechenhaus erkennen
   - Zwanzigerfeld erkennen
   - St/Sp erkennen
   - Schreiblinien erkennen

4. Nachhilfe koppeln:
   - Wenn `tenTransitionWeak`, dann automatisch `TwentyFrameVisual`
   - Wenn `placeValueWeak`, dann Rechenhaus/Zehner-Einer
   - Wenn `soundMisread`, dann SoundChoiceCard

5. Ergebnisanalyse verbessern:
   - Fehler: bis 10 nicht erkannt
   - Fehler: Rest falsch abgezogen
   - Fehler: Rechenhaus-Partnerzahl falsch
   - Fehler: St/Sp verwechselt

## Zielbild

Das Kind soll sagen koennen:

"Das kenne ich aus der Schule. Lumo zeigt es mir nur klarer und hilft mir dort, wo ich Fehler mache."
