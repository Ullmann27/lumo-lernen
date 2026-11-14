# Host078: eingefrorene Workflowkorrekturen und Prüfbelege

Dieses Dokumentationspaket enthält die unveränderten Quellenmanifeste, Diffs, statischen Prüfprotokolle und zwei unabhängigen Quellenreviews der isolierten Studio-Workflowkorrektur. Es ändert weder Quellzweige noch Pins oder Freigaben.

## Quellen und Änderungen

Ausgang ist Host `078774ddaf64808addaa4c6406f6a3c85b1f239a`, Workflowblob `4987a607fd3bb1531eff243500ed05cfec50ec57`. Die historische erste Korrektur bleibt als Blob `bc1d497ab87a5211c13b0cafeb2a6e5493fe04d4` erhalten: `ffmpeg` wird im tatsächlich betroffenen Buildjob installiert, beide Werkzeuge werden vor dem Native-Prüfblock gesucht und ihre Versionen aufgezeichnet.

Die zweite Fassung ist Blob `b8e63e1841828cab1e75ef3896e47b2d4d6aa38f`, SHA256 `441ddceba899294f0c5a2c4657473251978b3be38704b31a692f39d786c377a7`. Sie ergänzt einen frühen zwingenden Aufruf des vorhandenen Kart-Vorschau-Vertrags und genau zwei explizite `--skip-observed-kart-preview`-Argumente an den tatsächlichen API35-/API37-Touraufrufen. Alle anderen Bytes sind gegenüber v1 nach inverser Entfernung dieses Deltas identisch.

Root muss die unveränderten Probe- und Testblobs `481c19f8c9b9ed15ee205a534d1cfc8797d06aa8` und `ca2477afc4708385e705645613d45e3374f829f7` aus QA-Commit `3f89e5f045171424e9187ebdfb9ec1900ab16df3` mitintegrieren. Diese Dateien gehören nicht zum hier erzeugten Workflowdelta.

## Tatsächlich erfolgte Prüfung

Beide Fassungen wurden mit der vorhandenen PyYAML-Version 6.0.3 syntaktisch eingelesen und gegen ihre vollständige Ausgangsstruktur verglichen. BaseLoader belässt skalare Werte als Zeichenfolgen; diese Prüfung ersetzt keine GitHub-Ausführung. Der vorhandene Actionlint 1.7.12 wurde für jede Fassung tatsächlich ausgeführt und beendete sich mit Exitcode 0. Die unveränderten Rohprotokolle liegen in den jeweiligen Einzelpaketen. C las beide vollständigen Blobdifferenzen unabhängig, ohne Tests erneut auszuführen.

Es gab in dieser Arbeit keine lokale Ausführung der Probeverträge, keine Installation und keine Android- oder Native-Ausführung. Der frühere API35-Gegenlauf erlaubt keine API37-Freigabe. Die separat veröffentlichte Native-Budgetkorrektur `34421df83566dd4773420cc2a225887956459435` und ihr von Root als laufend gemeldeter Pflichtlauf `43588220125` bleiben eine eigenständige, noch nicht abgenommene Quelle. Ein späterer Hostpin benötigt die tatsächliche Native-Abnahme.

## Erhaltung und Upload

Die beiden ursprünglichen Evidence-Manifeste bleiben bytegleich erhalten. Ihr Feld `not_uploaded` beschreibt den früheren Erstellungszeitpunkt; der separate Uploadabschluss dieses Pakets belegt die später tatsächlich bestätigten Blobs. Die sieben ursprünglichen Studio078-Closure-Dateien wurden bereits in Evidencecommit `946ed588e4976312bcfc67364a3bde3ffdaa55a8` aufgenommen und werden hier nicht dupliziert.

Der vollständige Ausgangsbaum `200e8e66d79bf8b23349a3d7c6057aadfb92dfe1` dieses Evidencecommits wurde gelesen. Alle Ziele dieses Pakets werden vor dem Upload auf fehlende bestehende Pfade geprüft. Es werden ausschließlich unveränderliche Gitblobs erstellt; Tree-, Commit-, Ref- und PR-Änderungen bleiben bei Root.
