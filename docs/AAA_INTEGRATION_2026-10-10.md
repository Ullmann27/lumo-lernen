# Lumo: AAA-Integration und überprüfbare Android-Abnahme

## Arbeitsbasis

Flutter-Basis `8b308aeec8a6858b93a5b4626c4dd136d1e17ced`, bisher Build 1922.
Branch `computer/lumo-aaa-integration-2026-10-10`.
Getrennter Integrationszweig, keine Main-Änderung, kein Release.
Godot-Arbeit in [PR 47](https://github.com/Ullmann27/lumo-godot/pull/47).

## Echte Flutter-Baseline

Dateien unter `docs/qa/visual/aaa/2026-10-10/before/`.
Screenshot-Tests rendern vorhandene App-Widgets, keine nachgezeichneten
Bildschirmbilder. Mitgelieferte Nunito-Schriften statt des früheren
Roboto-Alias im Cards-Capture. Die Produktions-App verwendete bereits Nunito.
Alle Bilder mit Pixelverhältnis 1 aufgenommen, nicht nachträglich skaliert.
Cards-Zufallsseed 10, Vier Gewinnt Seed 1 und sechs echte Einwurf-Taps.
Lernen: synthetisches Testprofil Mia, Klasse 2, keine echten Nutzerdaten.

31 Screenshot-/Widget-Prüfungen bestanden, darunter die zusätzlichen Formate
360×800, 640×360, 1280×720 und 1200×896. Dies sind Flutter-Testengine-Aufnahmen,
noch kein Beleg für eine Installation auf Android.

## Erkannte Farbinkonsistenz

Die vorhandenen Karten-PNGs und der Farbwähler zeigen Rot/Gelb/Blau/Grün.
Historisch heißen die unveränderten Domain-Enums orange/purple/blue/green.
Der Ablagestapel bezeichnet eine gelbe Karte deshalb fälschlich als „Lila“,
der aktive Richtungspfeil ist lila, und die Sprachansage verwendet ebenfalls
den historischen statt sichtbaren Namen. Die Korrektur muss rein präsentativ
sein; IDs, Enum-Reihenfolge, Regelverhalten und gespeicherte Daten bleiben.

## Freigabe

IN_ARBEIT / VISUAL_GAP. Keine finale Grafik- oder APK-Freigabe.
Geräteinstallation, Update und Gameplay auf identischer APK müssen getrennt
von erfolgreichen Unit- und Screenshot-Tests nachgewiesen werden.
