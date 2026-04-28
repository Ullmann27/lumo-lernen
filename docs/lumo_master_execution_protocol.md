# Lumo Lernen – Master-Execution-Protokoll

Dieses Dokument ist der verbindliche Umsetzungsrahmen fuer die naechsten Entwicklungsphasen. Es verhindert chaotische Umbauten und schuetzt das Referenzlayout.

## Phase 1 – Referenz als Designvertrag

Die Referenz ist kein Moodboard. Sie ist der Zielzustand fuer Shell, Home und visuelle Wirkung.

### Unveraenderliche Hauptstruktur

1. Linke Navigationsspalte
   - Logo oben
   - feste Menuepunkte
   - Profilblock unten
   - bleibt immer sichtbar

2. Mittlere Dashboard-Spalte
   - Begruessung
   - KPI-Zeile
   - Titelbereich
   - Kartenraster oder eingebetteter Content
   - nur dieser Bereich darf inhaltlich wechseln

3. Rechte Lumo-Buehne
   - Sprechblase
   - grosse Lumo-Figur
   - Tageszielkarte
   - bleibt immer sichtbar

### Elemente, die sich nie verschieben duerfen

- linke Navigation
- rechte Lumo-Buehne
- aeussere Premium-App-Flaeche
- Spaltenlogik
- warme Farbwelt
- Kartenfamilie
- KPI-Familie
- Tageszielmodul

### Dominante Stimmung

- warm
- hell
- weich
- hochwertig
- freundlich
- sicher
- kindgerecht, aber nicht kindisch
- premium soft glass / soft clay

### Was das Referenzbild zerstoert

- Fullscreen-Seitenwechsel
- Standard-Flutter-Optik
- dunkle oder kalte Farbwelten
- harte graue Flaechen
- wechselnde Navigation
- verschwindende Lumo-Buehne
- einfache Iconlisten statt plastischer Karten
- Base64-Bilder im Code
- Feature-Logik direkt in UI-Widgets

## Phase 2 – Architektur zuerst

Vor neuen Features wird die Architektur stabilisiert.

### Zielarchitektur

- eine persistente AppShell
- linke Navigation persistent
- rechte Lumo-Stage persistent
- mittlerer ContentHost als einziger Wechselbereich
- zentrale Design-Tokens
- Lumo als eigenes Character-System
- Scanner als eigenes Feature
- Analyse und Lernlogik als Services

### Verbotene Muster

- mehrere Scaffolds fuer Hauptbereiche
- hart verdrahtete Featurelogik in Widgets
- neue Stilwelt pro Feature
- schnelle Workarounds im UI
- grosse Bilddaten direkt im Dart-Code

## Phase 3 – Designsystem vor Fachlogik

Neue UI darf nur ueber zentrale Tokens und Komponenten wachsen.

Pflicht-Tokens:

- Farben
- Typografie
- Radien
- Schatten
- Spacing
- Surfaces
- Buttons
- Cards
- Lumo-Stage
- Animationen

## Phasen-Gate

Nach jeder Phase pruefen:

- Bleibt die Shell stabil?
- Bleibt die linke Navigation sichtbar?
- Bleibt die rechte Lumo-Buehne sichtbar?
- Ist nur die mittlere Zone gewechselt?
- Gibt es keine roten Flutter-Fehler?
- Gibt es keine Asset-/Base64-Probleme?
- Wirkt die App noch wie die Referenz?

Wenn nein: nicht weiterbauen, sondern Ursache reparieren.
