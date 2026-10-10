# Lumo-Spielgrafik: Designgrundlage statt Redesign

**Die vorhandene Lumo-Lern-App und die wiederkehrende Lumo-Markenidentität sind unverändert die Grundlage.**

Die Nutzerbilder vom 10.10.2026 sind die visuell maßgebende Referenz für App, Kart, Cards, Bauwelt und 4 Gewinnt. Die Entwürfe in diesem Ordner sind nur **bearbeitbare Ablauf-/Layoutdiagramme**; sie liefern weder ein neues Branding noch eine neue Lumo-Figur. Nicht unmittelbar in Flutter/Godot als finales Design übernehmen.

- [Verbindlicher Bestandsschutz und Referenzindex](DESIGN_BESTANDSSCHUTZ.md)
- [Konkreter Ausführungsauftrag an Claude Sonnet 5.5](SONNET_5_5_UMSETZUNGSAUFTRAG.md)
- SVG-Skizzen: `lumo-cards-ui.svg`, `lumo-build-ui.svg`, `lumo-4-gewinnt-ui.svg` (nur Anordnung, keine künstlerische Zieloptik).

Zur visuell korrekten Umsetzung benötigt der ausführende Agent zusätzlich das aus dem Chat bereitgestellte **Lumo_Designreferenzen_2026-10-10.zip** mit den zehn unveränderten Referenzbildern. Ohne diese Bilder darf er keinen Anspruch erheben, die Bildvorlage getroffen zu haben. Neue generierte Vorschläge sind Ergänzungen, nie ein Ersatz für die primäre Vorlage.

**Aktuelle App-Bestandteile:** `assets/lumo_design/`, `lib/features/games/lumo_cards/`, `lib/features/games/connect_four/` und `lib/features/games/shared/`. **Godot:** `scripts/creative/build_world.gd` und `scripts/games/kart_garage_menu.gd`.

**Abnahme:** echte Vorher/Nachher-Runtime-Screenshots auf Fold, Smartphone und Tablet plus interaktive Tests. Konzeptgrafiken sind kein Ersatz für lauffähige Spiele.