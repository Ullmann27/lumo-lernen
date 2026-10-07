# Lumo – visueller Fortsetzungsstand am 7. Oktober 2026

## Auftrag und Ausgangspunkt
Heinz möchte in derselben App weiterarbeiten, alle bisherigen Funktionen erhalten,
Standardbilder unmittelbar verwenden, passende Bilder generieren und einfügen,
Lumo lebendig und einheitlich gestalten und während der Arbeit echte Screenshots
sehen. Dunkelblau, Weiß und Cyan, Glasflächen, keine orange Grundoberfläche.
Auf alte MVP-Dateien darf nicht zurückgegangen werden.

Quellen: lokale Projektanhänge, Produkt-/Copilotauftrag vom 04.10., aktuelle Git-
PRs sowie die bereitgestellten Projektgespräche. Der vollständige Abruf der letzten
zehn Chats war hier nicht verfügbar. Keine vollständige Chatlektüre behaupten.

Basis Flutter: PR210, da5b103c04eecfbe25b1f7bf82cb0dcf6a3bbe78.
Godot bleibt exakt auf dbd472e78ccb196c7492c4c842f8b85e3d642e2c / 4.6.3 gepinnt.
Damit bleiben die bereits integrierten 50 Lernlevel, Cards-Sitzungssicherung,
Start-/Rückkehrschutz, vier Kreativspiele und zwölf Rennwelten erhalten.
Diese Sitzung beansprucht Flutter-Oberfläche, neue Einzelgrafiken und zugehörige
Screenshot-/Layoutprüfungen; kein konkurrierender Renncontroller und kein Merge.

## Tatsächliche Änderungen
- Start mit neuer freigestellter Buchpose, ruhiger Inselkulisse und direktem Loslernen.
- Zwei gut lesbare Kacheln pro Zeile am Handy, vier erst bei genügend Platz.
- Einheitliche navyfarbene Glaskarten und blauer Lernakzent.
- Karteinstieg nach den Lern-/Navigationskacheln, breiter lesbarer Titel.
- Fortschrittskarten am schmalen Handy untereinander.
- Fuchs-Hilfe hat eine eigene Fläche außerhalb des Scrollinhalts. Die vorhandene
  Empfehlungs-/Hilfelogik bleibt aktiv; Antworten und Spielkarten werden nicht verdeckt.
- Bebilderte Cards-/Kart-Einstiege und neue Kartenpose mit derselben Rennjacke,
  Fliegerbrille und Augenfarbe wie die Lernpose.
- Die Akademie nutzt die neue Buchpose.
- Screenshotprüfung lädt echte Nunito-Schriften und wartet auf Bilddecoder.
  Vorher konnten Belegbilder fehlende Figuren oder Ahem-Textkästen zeigen.
- Versionsnummer 0.10.9+1600, bisherige Preview-Paket-/Signaturidentität bleibt.

## Bildherkunft
Drei neue Rasterbilder wurden mit dem integrierten Bildgenerator erzeugt und
wirklich im Projekt eingebaut, keine behaupteten Gameplay-Aufnahmen:
- assets/lumo_design/fox/fox_book_welcome.png
- assets/lumo_design/fox/fox_cards_welcome.png
- assets/lumo_design/bg/bg_glass_islands.png

Motivvorgaben: derselbe orange/cremefarbene Fuchs mit braunen Augen, blauer
Fliegerbrille, Navyjacke, Cyanpaspeln und L; sitzend mit Buch bzw. Spielkarten,
transparenter Hintergrund. Nachtlandschaft mit blauen Glasbibliotheken,
Inseln/Wasserfällen, cyanbeleuchteten Brücken und ruhiger Mitte ohne Text/UI.
Original-Identitätsreferenz: assets/lumo_design/fox/fox_avatar.png.
Der Begleiter animiert Rasterposen mit Transformationen. Kein neues skinned
3D-Fuchsmodell und keine nachgewiesene Mundsynchronisation.

## Prüfstand
Die fokussierten Home-, Shell-, Spielstart-, Cards-Rückkehr- und Creative-UI-Tests
wurden lokal ausgeführt. Echte Flutter-Renderbilder liegen unter
`docs/screenshots/2026-10-07-visual/`; Testdaten sind keine Nutzer-Spielstände.
Die Godot-Grafikprüfung lief lokal durch und erzeugte sechs echte 1280×720-Bilder
mit llvmpipe/OpenGL. Godot-Prüfrevision 2789b139 hat gegenüber dem gepinnten
Produkt nur eine Änderung am Android-Prüfharness, keine Spieländerungen.

Vollständige Flutter-Suite, endgültiger APK-Bau und Hash werden im Abschluss
nachgetragen. Alte CI-Zahlen gelten nicht als Prüfung dieses Kandidaten.

## Verbleibende Grenzen
Der Rennwelt-/Fuchsmodell-Detailgrad liegt weiterhin unter Heinz' Videovorlage.
60 FPS auf physischem Samsung/Fold, Geräteinstallation dieser neuen Version,
vollständiger nativer Langzeitspiel-/Updateablauf und Live-KI-Providerverfügbarkeit
sind nicht durch Flutter-Bildtests bewiesen. Kein Main-Merge, kein öffentlicher
Release, keine Änderung an Schlüsseln oder Abrechnung.

## Fortsetzen
Auf diesem Branch mit dem gespeicherten Ist-Stand starten, zuerst den gebauten
Kandidaten/Provenienz prüfen. Weitere Arbeit: räumliche Modell-/Streckendetails
anhand der Originalvideos und echter Kameravergleiche; physischer Fold-/60-FPS-
Nachweis. Keine weiteren losen Mockups als Ersatz für App-Integration.
