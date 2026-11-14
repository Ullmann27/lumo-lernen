# Android-PCK-Verpackungsnachweis: baf → 2281

## Tatsächliches Ergebnis

Der neue veröffentlichte Native-Stand `2281d990fb584db6f2cf786da8fec3badc2d9585` wurde genau einmal mit Godot4.6.3 importiert und über den vorhandenen Android-Preset als PCK exportiert. Alle drei originalen Notice-Dateien sind darin vorhanden und vollständig bytegleich. Der getrennt genau einmal aus `baf148b03a7a32c6ad9f737d731f900eb9113ea1` erzeugte Vorher-PCK enthält keinen dieser drei Pfade.

Beide Importe, beide Exporte und beide PCK-Leseinspektionen endeten mit Exit0 und leerem stderr. Die vollständigen Originalstreams bleiben unverändert. Die Quellenprüfung bindet HEAD, Tree, jeden getrackten Pfad mit Bytes/Hash/Modus sowie den vollständigen Git-Index vor und nach der Ausführung. Beide Quellstände blieben unverändert. Je357 erzeugte UID-Dateien wurden separat inventarisiert und verlustfrei archiviert; nichts wurde bereinigt.

## Nachweismethode

`inspect_pack_notices.gd` läuft in einem eigenen minimalen Inspektionsprojekt ohne Autoloads oder Native-Szene. Alle drei res-Pfade müssen vor dem Laden fehlen. Erst dann lädt Godot den tatsächlich erzeugten PCK. Die Extraktionen werden als rohe Bytes gespeichert und unabhängig mit den Original-Gitblobs verglichen. Ein Zugriff auf Notice-Dateien im Native-Quellcheckout ist damit kein Ersatz für den PCK-Inhalt.

`report.json` enthält die vollständigen Befunde. `source-file-index.json` bindet jede kopierte Originaldatei an ihren unveränderten Herkunftspfad. `actual-source-delta.json` bestätigt genau die drei veröffentlichten Quellenänderungen,14 neue Belegdokumente und3686 unveränderte Basisdateien. Die zwei `before/` und `after/`-Inventare je Exportfall binden sämtliche3703 beziehungsweise3689 getrackten Dateien.

## Aufbewahrung und Grenzen

Die zwei vollständigen PCK-Originale bleiben lokal unverändert erhalten. Ihre exakten Pfade, Größen und SHA256 stehen in `excluded-pck-originals.json`; sie werden gemäß Root-Auftrag nicht in diesen kompakten Gitbeleg kopiert. Quelldateikopien/Gitobjekte, erzeugte Importcaches und XDG-Laufzeitdateien bleiben ebenfalls außerhalb des technischen Archivs unverändert am Ursprungsort.

Der Vorherbefund beschreibt einen frischen Export aus exakt baf. Er behauptet keine nachträgliche Untersuchung eines historischen APK-/CI-Artefakts. Diese Prüfung liefert weder einen Android-Geräte-, Spiel-, Renderer-, FPS-, Release- noch einen vollständigen52/17-Regressionsnachweis. Web/Linux wurden nicht exportiert.
