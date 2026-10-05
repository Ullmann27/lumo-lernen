# Lumo Visual Fidelity Recovery — echtes Fold-Gerät, 2026-10-05

## Status

**PR #186 ist visuell NICHT abgenommen.**

Heinz hat reale Laufzeitbilder vom geöffneten Fold geliefert. Diese sind maßgeblich für den Ist-Zustand. Die Zielbilder bleiben:
- `docs/design_targets/2026-10-04/10_fold_tablet_home.png` für Fold/Home,
- `01_start_home.png`, `02_lernen_mathe_aufgabe.png`, `03_lernen_uebersicht.png`, `05_tests.png`, `06_spielewelt.png`, `07_profil.png` für die visuelle Sprache der mobilen Screens.

## Reale Belege

- `current_home_fold.webp` — reales Home auf Heinz' Fold.
- `current_profile_fold.webp` — reales Profil auf Heinz' Fold.
- `runtime_vs_reference_contact_sheet.webp` — direkte Gegenüberstellung.

## Hauptabweichungen

### Fold/Home

1. Zielbild 10 hat linke Navigation + großen Szenenbereich + rechte Fortschritts-/Aufgaben-Spalte. Im Ist fehlt die rechte Spalte.
2. Die Shell bleibt im Ist dunkel/opaque; im Ziel liegt die Welt vollflächig hinter UI und Dashboard.
3. Hauptkacheln werden im Ist zu riesigen flachen Farbflächen. Ziel: vier kompakte hochwertige Kacheln.
4. Die breite Companion-Leiste unten widerspricht dem Ziel; auf breiten Zielseiten darf Lumo höchstens als kleiner schwebender Helfer erscheinen.
5. Lumo/Kart ist im Ziel klarer Hero-Fokus; im Ist konkurrieren Hintergrund und UI.
6. Fortschritt, Tagesaufgaben und Belohnungs-CTA fehlen rechts.
7. Zu große Karten erzwingen unnötiges Scrollen im ersten Fold-Viewport.

### Profil

1. Reales Gerät zeigt helle creme/weiße Dashboard-Karten; Zielbild 07 nutzt blau/cyanes Glassmorphism.
2. Hero-Lumo ist im Ist nicht der dominante visuelle Anker.
3. Badges/Rewards wirken generisch statt wie leuchtende Lumo-3D-Objekte.
4. Companion-Footer überlagert Inhalt.
5. Zielatmosphäre ist leuchtende Nachtwelt; Ist wirkt wie klassische Dashboard-App.

## Verbindliche Korrekturregeln

- Keine Poster-/Screenshot-Fakes.
- Echte Daten bleiben dynamisch; Zielbild-Beispielwerte nicht hardcoden.
- Verifizierte Lumo-Assets statt generischer Icons verwenden.
- Full-bleed Szene auf Fold für Home/Lernen/Tests/Spiele/Profil.
- Kein breiter Companion-Footer auf breiten Full-bleed-Zielseiten.
- Fold/Home mit Navigation + Hauptfläche + rechter Progress-Spalte.
- Vier kompakte Hauptkacheln im ersten sichtbaren Bereich.
- Dunkelblaue Glass-Panels mit Cyan-Kante, Glow und räumlichem Schatten.
- Referenz-vs-Runtime nach jedem Schritt; Widgettest allein ist keine visuelle Abnahme.

## Abnahme

Ein Candidate darf erst akzeptiert werden, wenn echte Runtime-Screenshots mindestens zeigen:
- Fold/Home mit rechter Progress-Spalte,
- vier kompakte Hauptkacheln,
- Full-bleed Szene,
- Profil in blau/cyaner Glass-Materialsprache,
- keine sichtbaren Platzhalter,
- keine abgeschnittenen Texte/Controls.
