# Originalbeobachtung Native 2020: 8be3

Der tatsächliche Lauf `43561885899`, Versuch 1, auf `8be3a95d5d948d457c4c39bc6694138d60b70027` ist **fehlgeschlagen**. Diese Dateien sichern die unveränderten GitHub-Metadaten und die vollständigen Originalprotokolle der konkret fehlgeschlagenen Jobs. Es wurde weder ein Wiederholungslauf noch eine Ref-, Workflow- oder Produktänderung vorgenommen.

## Tatsächlicher Endstand

| Pflichtjob | GitHub-Job | Ergebnis |
|---|---:|---|
| learning-preview | 132347187467 | SUCCESS |
| touch-treasure | 132347187626 | SUCCESS |
| touch-workshop | 132347187633 | SUCCESS |
| touch-build | 132347187642 | SUCCESS |
| gameplay | 132347187683 | FAILURE |
| studio | 132347187651 | FAILURE |
| new-worlds | 132351755638 | SKIPPED |
| bundle-evidence | 132352628571 | SKIPPED |
| archive-evidence | 132352629414 | SKIPPED |

Es gibt deshalb kein erfolgreiches Gesamtarchiv und keine daraus freigegebene öffentliche `native-evidence.zip`-URL. Die sechs tatsächlich vorhandenen Teilarchive sind einzeln in `final-artifacts-original.json` erfasst. Ein hochgeladenes Teilarchiv ist keine Gesamtabnahme.

## Originale Fehler

1. **Gameplay / Attention-Landing:** Eine von 1.843 Bedingungen scheitert, weil der Test den bewusst ausgewählten Facial-Ableiter gegen den historischen Original-GLB-Hash prüft. Der lokale identische Gegenlauf und die getrennte Original-/Ableiterkorrektur liegen im eigenen Paket `qa/attention-landing-8be3-contract-fix-20261114/`. Dieses Beobachtungspaket verändert den alten Fehler nicht.
2. **Studio / Filmroster:** Die echte neue Treasure-Titelprobe meldet 137 Prüfungen ohne Fehler. Anschließend scheitert der abschließende Roster in `face_report` an `lumo_facial_capture/movie.json`. Der vollständige Joblog sowie sechs echte Film-Sidecars bleiben erhalten. Die gesonderte Ursachenprüfung und Korrektur des Filmvertrags erfolgen unabhängig; aus dem Fehler allein wird kein defekter Gesichtsrig abgeleitet.
3. **Zusätzlicher Stage-2-PR-Workflow:** Lauf `43561889426`, Job `132347198131`, scheitert beim unveränderten `git diff --quiet HEAD --` nach den gemeldeten Anatomie-/Startmenüprüfungen. Der Originaljoblog nennt keine konkreten veränderten Pfade. Eine separat ausgeführte Importgegenprobe belegt die Normalisierung der neuen GLB-Importdatei; sie wird nicht ohne CI-Diffliste als Nachweis ausgegeben, dass im damaligen Job ausschließlich dieser eine Pfad geändert war.

Die fünf anderen auf demselben Commit erfassten automatischen PR-Workflows sind erfolgreich. `final-commit-workflows-original.json` enthält die sieben tatsächlich beobachteten Runs; es wird keine pauschale Aussage gemacht, dass alle Workflows grün seien.

## Einmaliger Film-Sidecartransfer

Das originale Studio-Teilarchiv `14100974125` wurde vollständig als Stream gelesen: **78.023.259 Bytes**, SHA256 `46db85923551b9e6508047fba6d8d096540e081b2d1ac3680e753476936f3ce1`, exakt identisch zur GitHub-Metadatenbindung. Es wurde keine vollständige ZIP-Datei gespeichert.

Danach wurde der zentrale ZIP-Katalog mit 2.432 Einträgen ausschließlich lesend über HTTP-Range geprüft. HTTP 206, exakte Content-Range, Größe und unveränderte ETag wurden bei jeder Bereichsabfrage verlangt. Nur sechs Original-Sidecars mit zusammen **94.641 Bytes** wurden dekomprimiert und durch `zipfile` CRC-geprüft. Die Auswahl umfasst `movie.json`, `movie-ffprobe.json`, `runtime-frames.json` und drei Encode-/Decode-/ffprobe-Logs. Jeder ausgewählte Eintrag besitzt einen eigenen SHA256 im Transferbericht.

Die beiden leeren Decode-/ffprobe-Stderr-Dateien sind echte leere Originaldateien. Das AVI mit 10.780.514 Bytes und das MP4 mit 1.573.938 Bytes sind im Originalkatalog belegt; sie wurden in dieser Beobachtung nicht extrahiert, decodiert oder visuell geprüft. Es wird ausdrücklich keine vollständige Member-CRC-Prüfung für die übrigen Archiveinträge behauptet. Temporäre Download-URLs sind in keinem Bericht gespeichert.

## Grenzen

Dieses Paket belegt den fehlgeschlagenen CI-Stand und die Herkunft der ausgewählten Diagnoseoriginale. Es erteilt keine Host-Pin-, Release-, Android-, Geräte-FPS- oder vollständige visuelle Freigabe. Neue Testkorrekturen und ihre späteren Läufe bleiben getrennte Quellenstände.
