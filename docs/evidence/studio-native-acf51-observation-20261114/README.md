# Native 2020: erfolgreicher CI-Lauf acf51

Der tatsächlich beobachtete Lauf **43565059832**, Versuch **1**, auf Commit **acf51d3bd2997c4b731e9a48e1791e05e756a132** ist abgeschlossen und erfolgreich. Alle **acht Pflichtjobs plus Archivierung** sind erfolgreich. Die sechs zusätzlichen automatischen PR-Workflows auf demselben Commit sind ebenfalls erfolgreich.

Dieser Bericht ist eine CI-/Metadatenprüfung. Die spätere Sichtprüfung der frischen Bilder und die Android-Abnahme bleiben getrennte Schritte.

## Tatsächliche Pflichtjobs

| Job | ID | Ergebnis |
|---|---:|---|
| studio | 132356963309 | SUCCESS |
| touch-workshop | 132356963350 | SUCCESS |
| learning-preview | 132356963356 | SUCCESS |
| touch-build | 132356963390 | SUCCESS |
| gameplay | 132356963393 | SUCCESS |
| touch-treasure | 132356963462 | SUCCESS |
| new-worlds | 132360620371 | SUCCESS |
| bundle-evidence | 132365328812 | SUCCESS |
| archive-evidence | 132365478747 | SUCCESS |

Der veröffentlichte Workflow ist bytegleich zum vorherigen Stand 8be3. Seine Pflichtjobs, Abhängigkeiten, Fristen und Archivbedingungen wurden nicht gelockert.

## Konkrete Korrekturen im neuen Originalprotokoll

- Attention-/Landing-Test: **1.846 Prüfungen, 0 Fehler**. Der historische Original-GLB-Hash und der ausdrücklich verwendete Facial-Ableiter sind beide bestätigt. Der maximale Handkontaktfehler beträgt weiterhin 1,145121 mm.
- Tatsächlicher Gesichtsfilm: `LUMO_FACIAL_CAPTURE_PASS frames=144`; der Engine-Log nennt **148 aufgezeichnete Filmbilder bei 24 Bildern/s**. Der anschließende unveränderte Studio-Roster ist erfolgreich. 24 Bilder/s bezeichnet das Aufnahmeformat, keine Android-Leistungsmessung.
- Treasure-Titel: **137 Prüfungen, 0 Fehler** im tatsächlichen neuen Studio-Job.
- Der zusätzliche Stage-2-Lauf **43565062655**, Job **132356972145**, hat den zuvor betroffenen Import-/Anatomie-/Startmenü-Schritt tatsächlich erfolgreich abgeschlossen.

Die vollständigen Studio-, Gameplay- und Archivierungslogs sind unverändert gespeichert. Frühere fehlgeschlagene Läufe bleiben separat erhalten.

## Originalarchiv und öffentliche Identität

| Feld | Tatsächlicher Wert |
|---|---|
| Actions-Artefakt | `14103142984` |
| Name | `lumo-studio-2020-native-evidence` |
| Größe | **225.382.332 Bytes** |
| SHA256 | `4c1e6705f952efe789b0f5eb17d0bcf26cc369c4411b52a6ec5a4567a9b26aac` |
| Release | `445082804` |
| ZIP-Asset | `746588807` |
| Tag-Ziel | Commit `acf51d3bd2997c4b731e9a48e1791e05e756a132` |
| Release-Eigenschaften | öffentlich, Prerelease, `immutable: false` |

Die öffentliche URL ist:

https://github.com/Ullmann27/lumo-godot/releases/download/studio-2020-evidence-acf51d3bd2997c4b731e9a48e1791e05e756a132-14103142984/native-evidence.zip

Artefakt und Release-Asset weisen dieselbe Größe und denselben Digest aus. Der originale Archivierungsjob bestätigt die SHA256-Prüfung und den erfolgreichen öffentlichen Rückdownload mit anschließendem `cmp`. Die Tag-Ref wurde separat gegen den tatsächlichen Commit geprüft.

`final-artifact-selected.json` enthält das unverändert ausgewählte Artefaktobjekt aus `final-artifacts-original.json`; es ist kein erfundener oder umgebundener Datensatz. Seine Bytes besitzen denselben SHA256 wie das tatsächlich veröffentlichte `native-artifact.json`-Asset.

## Abnahmegrenze

Dieser Beobachter hat **keine große ZIP heruntergeladen**, keine vollständige lokale CRC-Prüfung ausgeführt und noch keine neuen Bilder geöffnet. Root übernimmt den einzigen vollständigen Originaldownload und die ZIP-/Source-Stamp-Prüfung. Erst danach beginnt die zugewiesene unabhängige Prüfung der 15 aktuellen Cards-, Puzzle- und Rhythmusbilder. Die Metadatenprüfung allein erteilt weder eine APK-/Androidfreigabe noch einen Geräte-FPS-Nachweis.
