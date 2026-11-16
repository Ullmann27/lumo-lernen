# Begrenzter Transfer derselben fertigen Aufnahme

## Originalbefund und Grenze

Unveränderte APK: `e05a96a52aaf57e466e79831f15aaffd144284ee`, 0.13.19/2031,
Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`.
QA `c2518e4bad105fcc3d867ae54a5fc93744e03842`, Run 43811505799.
Artefakt 14201128406: 74.671.895 Bytes, SHA-256
`cbd6a659a292804df4c81928c6c4b942c94a67c969055f05b556393788253609`.

Die Originaltour meldet separat PASS_WITH_LIMITATIONS. Die Referenztour bleibt
FAIL beim `adb pull` der Aufnahme `0091-banana-guided-navigation.mp4`:
Exit 1, Fortschrittszeile `[  7%]`, kein vorheriger Fehler im UI-Block.
Der Recorderlog ist leer. Bild 0110 zeigt den Flutter-Schritt Ba–na–ne und
ist bytegleich mit dem unmittelbar zuvor aufgenommenen Bild 0109
(SHA-256 `73851a96c4c4bf068d4f30018cfc345cdd6d86e2da8b8864455e6070cd223695`).
Ein Recorderstartfehler, ein nicht vorhandenes Remote-Video oder ein
Produktabbruch sind damit nicht nachgewiesen. Die tiefere Transportursache
bleibt offen. Die vollständigen Originale bleiben bei Root unter
`docs/nextgen/evidence/ci-2031-replay-video-transfer-failure/` erhalten.

## Enger QA-Delta

Basis dieses Komponentenbranches: `428619f45ccd945a11b806765245302aee9bcffb`.
Geändert werden nur die aktuelle gemeinsame Androidprobe und ihr bestehendes
Python-Testmodul; hinzu kommen drei kleine Originalfixtures, deren Manifest
und diese Evidenz. Kein Produkt-, Workflow-, Pin- oder Publisherdelta.

`LearningProbe._pull_recording` übernimmt genau die Aufnahme, deren eigener
Recorder zuvor gestoppt und abgewartet wurde. Er prüft zusätzlich, dass dessen
PID nicht mehr läuft, und liest positive Remotegröße sowie SHA-256. Höchstens
zwei Transfers teilen sich das bisherige Gesamtbudget von 90 Sekunden, jetzt
einschließlich der Metadatenprüfungen. Nach einem Abbruch darf nur dieselbe
unveränderte Datei erneut übertragen werden. Auch nach einem vollständigen
Transfer müssen Remotegröße/-Hash und lokale Größe/-Hash übereinstimmen.

Fehlgeschlagene Teilkopien und der erste Fehler bleiben in eigenen Dateien
und im Transferjournal erhalten. Es gibt keine erneute Aufnahme, keine
Wiederholung der Lernhandlung, keinen ADB-Reset und kein Löschen von Originalen.
Fehlende, leere, noch geschriebene oder geänderte Remote-Dateien schlagen fehl.
Ein erfolgreicher Pull mit unvollständigen lokalen Bytes schlägt ebenfalls fehl.
Der bestehende `ffprobe`-Nachweis mit positiver Videodauer und das 180-Sekunden-
Aufnahmelimit bleiben unverändert. Der bestehende Schutz des ursprünglichen
UI-/Bodyfehlers bleibt erhalten.

## Tatsächliche lokale Prüfung

- `red.log`: **2 Tests, 1 erwarteter Fehler** am unveränderten Shared-QA-Helper;
  der neue Transportfall bricht mit dem bytegleich übernommenen Originalfehler
  ab. `red-source.json` und `red-test.patch` binden diesen Zustand.
- `green.log`: **15/15 bestanden, 0 Fehler/Skips**. Sechs Transferprüfungen,
  drei bestehende Resize-Prüfungen und sechs bestehende Foreground-/Primärfehler-
  Prüfungen. Konstruierter ADB-/Zeittransport bleibt getrennt von den echten
  historischen Nullzeitvideos und deren `ffprobe`-Auswertung.
- `first-green-missing-sparse-fixtures.log`: Erster enger Lauf mit 9 Erfolgen
  und 6 Setupfehlern, weil ein vorhandenes Fixtureverzeichnis noch nicht im
  Sparse-Checkout lag. Dieses Verzeichnis wurde anschließend unverändert
  ausgecheckt; keine Testanforderung wurde geändert oder übersprungen.

Quellhashes, Fixture-/Loghashes und die genauen Befehle stehen in `source.json`.
Es fand kein Androidlauf statt. Der historische Fehler wird nicht umgedeutet,
und die neue Transferbehandlung ist noch kein Beleg für eine erfolgreiche
Referenztour oder eine veröffentlichungsfähige APK.
