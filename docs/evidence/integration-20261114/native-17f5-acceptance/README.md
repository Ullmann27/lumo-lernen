# Native 17f5 — kompakter Annahmenachweis

Dieser Pack bewahrt die unveränderten Originalnachweise der Native-Quelle
`17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845` und des Trees `b8ea9b1777e8d0b6302156330d4d1b298a316aea` für den bevorstehenden Host-Commit.
Nextgen-Run **43532048311** und Graphics-Run **43532048253** sind tatsächlich
erfolgreich abgeschlossen. Die Originalpacks wurden vor und nach der Verpackung
gegen ihre eingefrorenen Manifeste geprüft und nicht verändert.

## Inhalt und Wiederherstellung

`originals.tar.gz` enthält **482 reguläre Nicht-Bild-/Nicht-ZIP-Dateien**
unter den getrennten Präfixen `nextgen/` und `graphics/`. Originale API-Antworten,
elf vollständige Joblogs, sämtliche bereits gesicherten Artefaktlogs,
Quell-/Parserbindungen, Archivbelege, vollständige ZIP-/PNG-Hashindizes und die
Freeze-Manifeste bleiben bytegleich erhalten. Insbesondere wurden keine
Zeilenenden, BOMs, ANSI-Sequenzen oder Abschlussleerzeilen bereinigt.

Archiv: **1,892,708 Bytes**; SHA-256
`51fed950d4c0e213cc35f602a28386d51e0950cc2ee416829f380d9c0fcb128f`. Damit bleibt es unter 8 MiB.

Zur Wiederherstellung das Archiv in ein neues Verzeichnis entpacken und die
Einträge anhand von `original-inventory.json` prüfen. Die darin enthaltenen
ursprünglichen Manifeste beschreiben auch ausgeschlossene PNGs/ZIPs und können
deshalb erst mit diesen separat erhaltenen Payloads wieder vollständig erfüllt
werden. `roundtrip-verification.json` belegt den vollständigen gzip-CRC-/Trailer-
und tar-Inhaltsdurchlauf sowie den direkten Bytevergleich aller Archivdateien.

## Bewusst externe Payloads

**35 materialisierte PNG-Dateien und zehn große Original-ZIPs** sind nicht erneut
kopiert. `excluded-payloads.json` enthält für jede Datei Hash, Größe, ursprünglichen
Pfad und Artefaktbezug. Zusätzlich sind alle **415 PNG-Mitgliedseinträge** der zehn
Originalarchive erfasst; darin sind Bundleduplikate und ausdrücklich markierte
historische Baselines enthalten. Diese Zahl bezeichnet keine zusätzlichen Tests
oder Sichtungen. Vollständige sonstige ZIP-Mitgliederindizes liegen bytegleich im
Archiv.

Alle **29 Nextgen- und fünf Graphics-Reviewbilder** liegen bereits in den normalen
Host-Evidenzpfaden. `stored-review-references.json` bindet deren tatsächlich
vorhandene Bytes an die beiden aktuellen Root-Receipts, ohne Bilder zu duplizieren.
Auch das zusätzliche Previewbild ist darüber an die identischen finalen
Learning-Bildbytes gebunden. Gleiche Bildhashes übertragen keine Prüfung auf eine
andere Quelle oder historische Baseline.

Actions-Artefakte haben die im Original gespeicherten Ablaufdaten. Für den
finalen Native-Bundle ist zusätzlich der verifizierte öffentliche Evidenzarchiv-
Verweis vorhanden. Dessen API-Feld `immutable` ist **false**; belegt ist die
konkrete beobachtete Byteidentität, keine serverseitige Unveränderlichkeit.
Der Pack enthält keine APK.

## Nachgewiesene Abdeckung und Grenzen

Der unveränderte eingefrorene Host-Verifier hat 48 Core-Paare, 24 Studio-, vier
Village-, sechs Puzzle-Menü- und sieben Safe-Area-Bilder, drei Cards-Layoutsidecars,
zwei Safe-Area-Reports sowie sechs Touch-Paare/32 Touch-Bilder angenommen. Alle vier
Quellbäume entsprechen dem veröffentlichten Tree. Graphics belegt drei erfolgreiche
Jobs, 62 dekodierte PNGs und 40 Artefaktlogs; seine sieben ursprünglichen
Projektstrukturwarnungen bleiben in den Originalen erhalten.

Die aktuellen Root-Receipts sind über ihre vorhandenen Hostpfade und Hashes
referenziert: Nextgen `b41471c3cb90df69b99228f6da7057851af224528004872215f36332efb1804d`,
Graphics `355b6878f5d833aed4010fa49c5efb49759bbe9f8e4f185a75ca894ad9c6bf99`.
Die ursprünglichen Sammlerpakete behalten ihren damaligen Stand: Nextgen enthält
vier frühe Root-Belege; die abschließenden 29 Sichtungen wurden später durch Root
gesondert aufgezeichnet. Dieser Pack schreibt keine dieser Aussagen nachträglich um.

Safe-Area-Reports sind Plattformgrenzen-Fixtures und Rendererbelege. Sie sind keine
Android-Geräteausführung. Statische Bilder belegen keine natürlichen Gesten,
Geräte-FPS oder Eingabelatenz. Die gesicherten CI-Logspannen sind keine unabhängig
instrumentierten Prozesslaufzeiten. Die Android-Laufzeitabnahme bleibt separat.

## Transportdaten und Integrität

482 Nicht-Bild-/Nicht-ZIP-Dateien wurden vor dem Verpacken auf temporär
signierte URLs und Zugangsdaten geprüft; **0 Dateien** mussten
als ganze, nicht publizierte Transportmetadaten ausgeschlossen werden. Eine solche
Datei würde ausschließlich mit Pfad, Hash und Grundklasse inventarisiert; ihre
Originalbytes würden erhalten, ihre Werte weder kopiert noch redigiert. Hier wurde
keine Datei wegen Transportzugangsdaten ausgelassen.

`manifest.json` und `SHA256SUMS` binden die fertigen Commit-Dateien. Während dieser
Verpackung wurden keine Produktdateien, Tests, Pins, Receipts, Refs oder Git-Indizes
verändert. Es wurden ausschließlich vorhandene Nachweisbytes verpackt und geprüft.
