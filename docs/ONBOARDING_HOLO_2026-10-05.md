# Lumo Onboarding Hologlass — 2026-10-05

## Ziel
Den bisherigen warm/orangefarbenen First-Run-Flow durch dieselbe dunkelblaue Cyan-Glas-/Hologramm-Sprache ersetzen, die Heinz für die aktuelle Lumo-App verlangt.

## Generierte Designvorlage
Vor der Implementierung wurde eine neue Onboarding-Konzeptserie erzeugt und in einzelne Screen-Referenzen zerlegt:
- Splash / Start
- Willkommen
- Wer bist du? / Name
- Schulklasse
- Interessen
- Ziel
- Elternbereich
- Fertig
- Übergang
- Homescreen-Referenz

Die Laufzeitimplementierung rendert Text, Eingabefelder, Buttons, Alter und Klassenwahl absichtlich nativ in Flutter. Dadurch bleiben Accessibility, Lokalisierung und Fold-Responsivität erhalten; die generierten Bilder dienen als Art-Direction statt als starre Vollbild-Screenshots.

## Aktueller Code
- `lib/features/onboarding/lumo_onboarding_holo_screen.dart`
- `lib/main.dart` nutzt diesen Flow im First Run.
- Der alte `lumo_onboarding_screen.dart` bleibt vorerst als Vergleich und Fallback im Repo.

## Funktionsvertrag unverändert
Persistiert werden weiterhin ausschließlich die vorhandenen `UserProfile`-Felder:
- Name
- Alter
- Klasse

Keine Migration bestehender Profile, keine Wallet-/Reward-Änderung.

## Pflichttexte für bestehende QA
Folgende Captions bleiben sichtbar:
- `Willkommen`
- `Wie heißt du?`
- `Wie alt bist du?`
- `In welche Klasse gehst du?`
- `Weiter`
- `Profil speichern`

## Visuelle Regeln
- Midnight Blue / Cyan / Electric Blue
- Glasflächen mit Blur und dünner Cyan-Kante
- Orange nicht mehr als dominierende Onboarding-Farbe
- Lumo bleibt klarer Mittelpunkt
- große, einfache Touch-Ziele
- Compact/Fold: vertikal
- breite Innenansicht: Lumo links, Formular rechts

## Nächste Prüfung
1. `flutter analyze`
2. bestehende Onboarding-Widget-/Android-QA
3. 360x800, 480x800, Fold innen und breite Tabletansicht
4. Tastatur bei Namenseingabe
5. lange Namen
6. sehr kleine Höhe / Landscape
7. bestehendes Profil darf den Onboarding-Flow nicht erneut sehen

Keine Behauptung eines echten Fold-Gerätetests, bevor dieser tatsächlich ausgeführt wurde.
