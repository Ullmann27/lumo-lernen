# Unabhängige C4-Runtime-Abnahme auf aab09275 – 14. November 2026

## Exakter Umfang

- Host: `aab09275ec6b5808de9be539ca4e1a7e70921249`, Tree `baaa84b40b09e61d144f158e5b35a1c4dc5d2ef0`.
- Native: `e2d15dbc5f3709306decb139eeb70a1cf30c0b73`, Tree `ea0f73ae6aad8792a963cadaa483c290a2f2a62e`.
- Tatsächlicher Run: [43590864772](https://github.com/Ullmann27/lumo-lernen/actions/runs/43590864772), Versuch 1.
- Abgeschlossener Job: `connect-four-runtime`, ID `132435073772`, Ergebnis `success`.
- Originalartefakt: `14112302039`, `lumo-connect-four-2020-desktop-runtime`, 22.153.295 Bytes.
- ZIP-SHA256: `77a8c42b2674c1a5de875b9ded796fd17f6778dbf2aa4a4f9f893ab62614962f`.

Das Artefakt wurde einmal mit dem offiziellen GitHub-Artefaktdownload geladen. Archiveinträge, CRC, sichere Pfade und Archivhash wurden geprüft. Beide Prüfer verwendeten dieselbe extrahierte Kopie. Der vollständige Host-Run war bei der gesicherten Statusabfrage noch aktiv; dieser Bericht erteilt keine vollständige Kandidatenfreigabe.

## Tatsächlich nachgeprüft

[artifact-verification.json](artifact-verification.json) hält die unabhängige Prüfung fest. Alle 259 PNGs – 250 lückenlos nummerierte Frames und neun benannte Stillbilder – stimmen in SHA256, Bytezahl und PNG-Abmessungen mit dem unveränderten [Runtime-Manifest](originals/runtime/runtime-gate.json) überein.

Die Quelleninventare vor und nach der originalen Ausführung sind bytegleich. Sämtliche erfassten 447 Host- und 1.256 Native-Einträge passen in Pfad, Modus, Git-Blob und Größe zu den exakten, vollständig abgefragten GitHub-Trees. Die Abdeckung entspricht den Quellbereichen des echten Runtime-Runners, nicht jedem Dateiinhalt beider Repositories. Der [komplette abgeschlossene Joblog](api/completed-runtime-job.log) bestätigt die tatsächlichen Checkouts beider SHAs.

Die Originalberichte nennen Dart/Godot Exit 0, 170 native Checks ohne Fehler, 90 Frames mit beobachteter fallender Geometrie und 43 Frames mit vier Gewinnringen. Diese Zählungen wurden aus den vorhandenen Beobachtungen mit dem Manifest abgeglichen. Die Zahl 24 ist die feste Aufnahmeformat-Vorgabe. Sie ist keine gemessene Gerätebildrate. Der originale Backendumfang bleibt Produktions-Dart-Controller, SharedPreferences-Testbackend und lokaler Dateitransport; kein Android-Binder- oder echter Disk-Persistenznachweis.

Die separaten Originalprotokolle enthalten genau einmal `CONNECT_FOUR_RETURN_PASS checks=21` und `[TreasureWisp] PASS checks=14`. Alle 399 extrahierten Originaldateien blieben während der Prüfung unverändert. [original-evidence-index.json](original-evidence-index.json) enthält deren Pfade, Bytezahlen, SHA256 und Git-Blob-Identitäten. Binäre PNGs und Caches bleiben im identifizierten Originalartefakt; ihre Inhalte werden hier nicht nachgebaut.

## Vier tatsächlich geöffnete aktuelle Originalbilder

Der unabhängige [Sichtbericht](independent-visual-review.json) umfasst genau Empty, Win, Phone-Portrait und Small-Landscape. Er bestätigt sichtbare Beschriftungen und Gewinnmarkierungen innerhalb dieses begrenzten Bildumfangs. Das Portraitbild zeigt den Gewinndialog, nicht das frei sichtbare aktive Spielfeld.

### Offene, konkret abgegrenzte Bedienabdeckung bei 640×360

Im kleinen Gewinndialog sind „Neue Runde“ und „Gegen Lumo spielen“ im aufgenommenen Scrollausschnitt nicht sichtbar. Die bloße Scrollleiste gilt nicht als Erreichbarkeitsnachweis.

Der [Zusatzbericht zur tatsächlichen Eingabespur](small-landscape-action-evidence.json) bindet dies an:

- Native-Probe `scripts/tests/connect_four_runtime_regression.gd`, Blob `94c32597c0170c5c3199e39ca6fbfcc1caf25f99` auf exakt e2d15, insbesondere Zeilen 274–296.
- [originals/runtime/connect_four_small_landscape.layout.json](originals/runtime/connect_four_small_landscape.layout.json), Revision 29 / ACK 19.
- [originals/runtime/native-result.json](originals/runtime/native-result.json), nullbasierte Inputs 36–47 und Target 19.
- [originals/runtime/dart-result.json](originals/runtime/dart-result.json), Revision 29 → 30 / ACK 19 → 20.

Nach acht aufgezeichneten Drag-Ereignissen wird ausschließlich „Brett ansehen“ freigescrollt und betätigt. Die beiden unteren Aktionen haben im gesicherten Layout ein leeres effektives Trefferrechteck. Ein gezieltes Betätigen dieser beiden Aktionen in diesem Viewport ist nicht belegt. Das ist eine Abdeckungslücke, kein daraus nachgewiesener Produktfehler.

Die späteren Größenprofil-Eingaben tragen `frame=250`, weil die Videoaufnahme zuvor beendet wurde. Die Positionsfolge reicht von 0 bis 249. Die spätere Eingabe-/ACK-Spur ist ein eigenständiger Nachweis und kein Film dieser kleinen Aktionen.

## Grenzen und Persistenz

Für diese Abnahme wurden keine Tests, neuen Engine-/Rendererläufe, Android-Aktionen, Produktänderungen oder Refupdates ausgeführt. Die gespeicherten Metadaten und Textoriginale stammen aus dem aktuellen Run; frühere 803a-/32e-Ergebnisse wurden nicht übertragen. Die kommenden Native-52/Dream-5- und Android-Nachweise bleiben getrennt. Auch deren Abschluss würde die hier konkret fehlende Bedienhandlung nur dann schließen, wenn die Handlung dort tatsächlich ausgeführt wird.

Die Dateien wurden als Git-Blobs zur separaten Integration durch Root gesichert. Der eingefrorene Kandidat wurde nicht verändert.
