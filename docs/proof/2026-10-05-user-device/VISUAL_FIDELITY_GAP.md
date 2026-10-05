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

1. **Layout-Hierarchie falsch:** Zielbild 10 hat linke Navigation + großen Szenenbereich + rechte Fortschritts-/Aufgaben-Spalte. Im Ist fehlt die rechte Spalte vollständig.
2. **Zentrale Fläche zu opaque:** Im Ist ist der Shell-Container dunkel/abgeschlossen. Im Ziel lebt die Szene vollflächig hinter UI und Dashboard.
3. **Kacheln falsch proportioniert:** Lernen/Spielen werden zu riesigen flachen Farbflächen. Ziel: vier kompakte, hochwertige Kacheln mit großen 3D-Symbolen.
4. **Lumo-Companion-Leiste falsch:** Unten liegt eine breite CompanionHost-Leiste mit Idee/Erklären/Fragen über dem Inhalt. Im Fold-Zielbild existiert diese Leiste nicht; Lumo ist Teil der Hero-Komposition.
5. **Hero-Komposition schwach:** Ziel: Lumo/Kart als klarer visueller Fokus mit Glass-Overlay, Glow und räumlicher Tiefe. Ist: Hintergrundbild und UI konkurrieren, Lumo wirkt sekundär.
6. **Rechte Progress-Komposition fehlt:** Lernfortschritt, tägliche Aufgaben, Belohnung und CTA fehlen in der Zielposition.
7. **Dichte/Abstände:** Ist-Karten verbrauchen zu viel vertikale Fläche und erzwingen unnötiges Scrollen im sichtbaren Fold-Bereich.

### Profil

1. **Materialsprache nicht konsistent:** Das reale Profil zeigt helle creme/weiße Karten und generische Symbolik. Zielbild 07 nutzt durchgehend tiefblaues/cyanes Glassmorphism.
2. **Hero-Lumo fehlt als dominanter visueller Anker.**
3. **Badge-/Reward-Präsentation zu generisch:** Ziel sind leuchtende Hex-Badges und hochwertige 3D-Belohnungsobjekte.
4. **Footer-Companion überlagert Inhalt.**
5. **Kontrast/Atmosphäre:** Ziel hat eine magische, leuchtende Nachtwelt; Ist wirkt wie eine klassische Dashboard-App.

## Verbindliche Korrekturregeln

- Keine Poster-/Screenshot-Fakes als interaktive Oberfläche.
- Echte Daten bleiben dynamisch; keine Beispielwerte aus Zielbildern hardcoden.
- Keine generischen Emoji-/Material-Icons, wenn ein verifiziertes Lumo-Asset vorhanden ist.
- Full-bleed Szene auf Fold für Home/Lernen/Tests/Spiele/Profil.
- CompanionHost auf breiten Full-bleed-Zielseiten nicht als breite Footer-Leiste rendern.
- Fold/Home ab geeigneter Breite mit linker Navigation + Hauptfläche + rechter Progress-Spalte.
- Home-Hauptkacheln auf Fold als **vier kompakte Kacheln** im ersten sichtbaren Bereich.
- Transparente dunkelblaue Glass-Panels mit Cyan-Kante, Glow und räumlichem Schatten.
- Referenz-vs-Runtime nach jedem Schritt; kein PASS nur aufgrund von Widgettests.

## Erster Reparaturumfang

Claim in #175:
- `lib/app/app_shell.dart`
- `lib/features/home/home_content.dart`
- `lib/widgets/design/lumo_design_system.dart`
- `lib/widgets/profile_screen.dart`

Keine Lern-/Domain-/Godot-/Pin-/Workflow-Änderungen.

## Abnahme

Ein Candidate darf erst visuell akzeptiert werden, wenn echte Runtime-Screenshots mindestens zeigen:

- Fold/Home mit rechter Progress-Spalte und ohne Footer-Companion-Leiste,
- vier kompakte Hauptkacheln,
- Full-bleed Szene,
- Profil in derselben blau/cyanen Glass-Materialsprache,
- keine sichtbaren Platzhalter,
- keine abgeschnittenen Texte/Controls.

