# Studio078: Werkzeuge und beobachtete Kart-Preview — v2

Einziger geänderter Quellpfad ist `.github/workflows/lumo-studio-2020.yml`. Die veröffentlichte Ausgangsquelle ist Host `078774ddaf64808addaa4c6406f6a3c85b1f239a`. Die getrennte ffmpeg-v1-Fassung `bc1d497ab87a5211c13b0cafeb2a6e5493fe04d4` bleibt unverändert erhalten.

## Enges Delta

Die v1-Installation und tatsächliche ffmpeg-/ffprobe-Vorprüfung im verify-and-build-Native-Step bleiben vollständig enthalten. Dazu kommen ausschließlich:

- `--skip-observed-kart-preview` bei den beiden tatsächlichen modernization_android_tour.py-Aufrufen der API35- und API37-Zweige. Alle APK-/Provenienz-/Hash- und Ausgabeparameter, Surface-/C4-Aufrufe, ursprünglichen Gates und Budgets bleiben erhalten.
- Ein verpflichtender früher CI-Schritt nach dem Quellen-/Pincheck und vor Java/Flutter. Er verlangt die vorhandene Testdatei mit `test -s` und führt `python3 -B -m unittest discover -s tools/android_qa/tests -p test_kart_preview_skip.py -v` unter `set -euo pipefail` aus. Er besitzt weder ein überspringendes if noch continue-on-error.

Die Probe und ihre vorhandenen Verträge müssen unverändert aus QA-Commit `3f89e5f045171424e9187ebdfb9ec1900ab16df3` integriert werden: Probe-Gitblob `481c19f8c9b9ed15ee205a534d1cfc8797d06aa8`, Test-Gitblob `ca2477afc4708385e705645613d45e3374f829f7`. Beide wurden über ihre veröffentlichten Blobs gelesen und zusätzlich gegen die vorhandenen eingefrorenen lokalen Bytes geprüft. Sie wurden hier nicht geändert. Insbesondere wurden die 150-/55-Sekunden-Regeln nicht editiert.

## Tatsächliche Prüfung und Grenze

Die inverse Entfernung genau des neuen Testschritts und der beiden Argumente stellt die vollständige v1-Datei exakt wieder her. PyYAML6.0.3/BaseLoader hat die ganze YAML-Struktur gelesen; nach Rückersatz sind sämtliche übrigen Knoten einschließlich Jobs, Abhängigkeiten, Rechte, Matrix, Budgets und Aufrufe identisch. BaseLoader bewahrt Skalare als Strings; diese Prüfung simuliert keinen GitHub-Runner. Actionlint1.7.12 wurde genau einmal auf v2 ausgeführt: Exit0, leere stdout/stderr.

Es wurde hier kein Unittest, kein Androidlauf, keine Installation und kein ffmpeg-/ffprobe-Kommando ausgeführt. Aus früheren QA-Resultaten wird kein Erfolg dieser neuen Workflowfassung abgeleitet. Der neue Pflichtschritt und beide Androidzweige müssen im tatsächlichen nächsten CI-Lauf ausgeführt werden.

Der neue Sourceblob `b8e63e1841828cab1e75ef3896e47b2d4d6aa38f` ist bereits bestätigt in GitHub vorhanden und vollständig UTF-8-bytegleich zurückgelesen. Die Quelle ist 59.128 Bytes groß, SHA256 `441ddceba899294f0c5a2c4657473251978b3be38704b31a692f39d786c377a7`. Es wurden keine Pins, Produktmodule, andere Workflowdateien, Trees, Commits oder Refs verändert.
