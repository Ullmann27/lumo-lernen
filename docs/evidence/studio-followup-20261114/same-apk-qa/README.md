# Gebundene OCR-/Cards-Gegenprüfung am bestehenden 4ab-APK

Stand: 14. November 2026. Dieses Paket bereitet ausschließlich einen neuen QA-Durchlauf vor. Es enthält keinen neuen Android-PASS und erzeugt keine APK oder Veröffentlichung.

## Quellen und Zweck

Die Basis ist der veröffentlichte QA-Commit `a446f3c1a320ad5297e17606727d801c5e993ce1` (PR478, ursprünglicher Lauf 43542310963). Der folgende Commit wird auf demselben Branch `chatgpt/lumo-studio-4ab-ocr-recheck-20261114` vorbereitet. Die vorherigen Ergebnisse bleiben historisch erhalten.

Die getestete Binärdatei bleibt ausschließlich Host `4ab96666f954baf258422d6ed277fc297b7ddeef` mit Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Der getrennte neu gebaute Studio-Kandidat `c081cfaaa3e7ddedbca21a46f63dbe4a8cc0d111` wird hier nicht geprüft.

Der Binder verlangt Originalrun 43530667812, Attempt 1, erfolgreichen Builder 132247240154 und Artefakt 14089507933. Er misst die tatsächlichen APK-Bytes und das eingebettete PCK vor und nach beiden Touren:

- x86-APK: `7c647296c57ffce9950e117889685360ec024407dead35486eecc1331db3f9b6`, 325.295.610 Bytes.
- PCK: `28032ec5f08db510d5baa1e10b7cbf8cade072081c5d8be8f40181c65d7aa01e`, 66.234.596 Bytes.

## Eng begrenzte Prüfänderung

Gegenüber dem Produkt sind genau 16 konkrete QA-Pfade zulässig. Gegenüber a446 ändern sich 10 davon; die sechs bestehenden OCR-Quelldateien und Originalbilder bleiben dessen exakte Gitblobs und Modi. Der neue QA-HEAD muss von a446 abstammen.

Die Modernisierungstour bleibt bytegleich. Die Studio-Oberflächenprüfung erhält ausschließlich die bereits geprüfte Änderung in `read_cards_layout`: Eine tatsächlich gelesene, gespeicherte Antwort, die noch kein vollständiges JSON ist, wird als Bereitschaftsfehler an die bestehende begrenzte Beobachtungsschleife weitergegeben. Diese Schleife verlangt weiterhin die ursprünglichen Zustands-, Sitzungs-, Geometrie-, Pixel- und zwei stabilen Frameprüfungen. Dauerhaft fehlende, fremde oder veraltete Daten können keinen PASS erzeugen. Laufzeitbudgets und Appaktionen bleiben unverändert.

Die gesamte Oberflächen-Datei wird zusätzlich auf beide vollständigen SHA256 gebunden:

- Original 4ab/a446: `9f2ceaa25b356f01377681fd8aba5fc6cd04bde74fbdc56d9ddffe57dc29ded6`.
- Freigegebene Korrektur: `5d802f475d0b844bd720e67b53798816ff61f034a21bafb2a74d247e4c5137ed`.

Auch ein sauber commitierter anderer Inhalt am erlaubten Dateipfad wird abgewiesen. Alle übrigen Produktdateien und Modi werden gegen den separaten sauberen 4ab-Checkout geprüft; tatsächliche Arbeitsdateien werden unabhängig vom Gitstatus gehasht. Beide Touraufrufe kommen absolut aus dem gemessenen QA-Baum, ihr Arbeitsverzeichnis bleibt der echte Produktcheckout. Die Produkt- und QA-Quellen werden getrennt protokolliert.

## Tatsächlich lokal ausgeführt

- 18 Binderverträge bestanden, 0 Skip, 1,103s laut unittest: die bisherigen 17 Fälle bleiben erhalten beziehungsweise auf die exakte 16-Pfad-Bindung angepasst; ein zusätzlicher Fall manipuliert die erlaubte Oberflächen-Datei in einem sauberen synthetischen Gitcommit und verlangt Ablehnung.
- 6 freigegebene Cards-Bereitschaftsverträge bestanden, 0 Skip, 1,064s laut unittest. Die Tests verwenden historische Originalbilder und Layoutdaten mit synthetischem Transport und Zeitgeber. Sie sind kein neuer Android-Ziehvorgang.
- 11 tatsächliche `run`-Shellblöcke durch `bash -n` geprüft; GitHub-Ausdrücke wurden dafür durch einen Syntaxprüfwert ersetzt, nicht ausgeführt.
- Actionlint 1.7.12: Exit 0; ShellCheck wurde hierbei nicht ausgeführt.

Die sechs Cards-Verträge sind vor beiden Androidmatrixjobs als zusätzliche Pflichtprüfung eingebunden. Die vorhandenen 12 OCR-Tests und die Binderverträge bleiben ebenfalls Voraussetzungen. Die API 35-/API 37-Ausführung ist bis auf Job-/Artefaktbezeichnungen gegenüber a446 unverändert; insbesondere bleiben der echte Android 17-CLI22-/Frameworkstart, SDK 37/Release 17 und alle Appgates bestehen. Die tatsächliche nächste CI-Ausführung bleibt offen.

## Übergabe

`source-upload-manifest.json` ist die einzige Quelldateiliste für den Diagnosebranch: 16 Pfade, davon 10 neue/geänderte Blobs gegenüber a446. Keine lokalen Baselines, Logs, Dokumente oder Validierungsabhängigkeiten auf diesen strikt gebundenen Branch hochladen.

`evidence-upload-manifest.json` beschreibt einen getrennten Dokumentationsnachtrag. `baseline-a446/` enthält direkt am vollständigen veröffentlichten Commit gelesene Originaldateien; `validation/` die unveränderten lokalen Rohlogs und den nachvollziehbaren Quellenvergleich. Die zwei lokalen Pixel-/Readiness-Abhängigkeiten wurden für die sechs Tests aus vorhandenen Dateien übernommen und separat auf die identischen veröffentlichten 4ab/a446-Gitblobs geprüft. Sie sind keine weiteren Quelldeltas.
