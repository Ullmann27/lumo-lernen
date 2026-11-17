# Aktuelle Native-Originale: unabhängige Leser- und Bildprüfung

## Bindung

Dieser Nachweis gehört ausschließlich zu Host `aab09275ec6b5808de9be539ca4e1a7e70921249`, Native `e2d15dbc5f3709306decb139eeb70a1cf30c0b73` (Tree `ea0f73ae6aad8792a963cadaa483c290a2f2a62e`) und Run `43590864772`, Attempt 1, Artifact `14114314120`.

Der ReleaseLead hat das Originalarchiv einmal über den offiziellen Download übertragen und vollständig auf Größe, SHA-256, CRC und zulässige Pfade geprüft: 192.077.445 Bytes, SHA-256 `d57188fcd09673444f3670c41378b444d6295e9934a4d9a1b760c5945027510c`, 5.035 Originaldateien. Sein separater Handoff `bbf55d8605b788ed6754e4448e86908f9e077f4a` enthält den vollständigen komprimierten Archivindex und die originalen Gesamtprotokolle.

## Tatsächlich ausgeführte unabhängige Leserprüfung

`python3 -B reader-replay.py` wurde mit Python 3.12.14 und Pillow 13.0.0 tatsächlich ausgeführt und endete mit Exit 0. Nur die gebundenen, aus den unveränderlichen Git-Quellen gelesenen Prüfmodule wurden geladen. Die archivierte Python-Datei wurde als Originalbeleg verglichen, nicht als fremdes Programm ausgeführt.

- Der exakte Host-Reader bestätigte alle 52 Moduszeilen in der erwarteten Reihenfolge sowie die ursprünglichen Einzel- und Gesamtprotokolle.
- Der exakte Studio-Reader mit `write=False` reproduzierte das originale Ergebnis für 17 PNGs, drei Berichte und ein Facial-Video unverändert.
- Der exakte Dream-Reader mit `write=False` reproduzierte das originale Ergebnis für fünf Probes, sieben PNGs und zwei Berichte unverändert.
- Die 3.649 getrackten Native-Dateien wurden vor und nach dem CI-Gate gegen den unveränderlichen Remote-Tree abgeglichen. Beide originalen Quellinventare sind bytegleich; je Inventar sind 345 erzeugte UID-Dateien und 604 Import-Metadaten erfasst, keine sonstigen ungetrackten Dateien.
- 116 für diese Prüfung benötigte Originaldateien sowie die geladenen Reader blieben vor und nach der lokalen Prüfung unverändert.

Die unveränderten Originalmanifeste und ihre frischen Lesergebnisse haben identische Git-Blobs. Beide originalen Sourceinventare, die unverändlichen erwarteten Tree-Einträge, die drei Studio-Sidecars, zwei Dream-Berichte sowie Quelle-/Engine-Stempel sind im Handoff gebunden.

## Unabhängige Sichtprüfung

Der bestehende TouchWorker öffnete genau sieben tatsächliche Original-PNGs: Treasure-Portrait und -Querformat, Kart-Rampe, Lumo-Gesicht, C4-Gewinnansicht und zwei Dream-Ansichten. Alle sieben sind hier unverändert mit Hashes gesichert. Der Bericht `independent-selected-visual-review.json` benennt die einzeln sichtbaren Inhalte und die Grenzen.

In dieser Auswahl wurde keine sichtbare funktionale Überdeckung der beschriebenen wesentlichen Inhalte und Steuerflächen gefunden. Die aktuelle Kart-Aufnahme bei 1280×720 zeigt die Minimap vollständig innerhalb des Bildes und mit Abstand zum SPEED-Knopf. Im schmalen Treasure-Portrait ist der Titel mit Auslassungspunkten verkürzt. Beim schmalen Dream-Garden ist der äußere dekorative rechte Brettrand angeschnitten; die gezeigten Aufgabeninhalte und Schaltflächen bleiben sichtbar.

## Grenzen

Hier wurde keine Engine, kein Renderer, kein Spielprobe-Lauf, kein FFmpeg/FFprobe und kein Flutter-/Android-/APK-Test gestartet. Die Facial-Datei wurde durch die vorhandenen Reader-/Originaldatensätze geprüft; eine neue lokale Filmdecodierung oder Hörprobe ist nicht enthalten. Stillbilder belegen keine dynamische Eingabe, keine Android-Ausschnitte, keine gemessene Bildrate und keine Lernwirksamkeit. Die getrennte R3-Bedienprüfung des kleinen Ergebnisdialogs wird nicht erneut als Teil dieser Bildprüfung ausgegeben.

Der gesamte Mainjob endete später am bestätigten 90-Minuten-Joblimit während des APK-Schritts. Die erfolgreichen Native-Teilschritte sind deshalb kein erfolgreicher Gesamtbuild und keine Play-Store-Freigabe. Der spätere Kandidat mit geändertem Jobbudget und sein neuer CI-Lauf sind von diesem unveränderten Originalnachweis getrennt.
