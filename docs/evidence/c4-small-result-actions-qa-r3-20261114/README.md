# R3: enge JSON-Geometriekorrektur im separaten QA-Lauf

## Eingefrorener Vierersatz

Der QA-Commit 51d05896aec9bced8c789504161f2255441cd07f (Tree 1c95ba11ba980ed01bd3e76c91a66fdfcb23b8a4) hat genau einen Parent: Host aab09275ec6b5808de9be539ca4e1a7e70921249. Der tatsächliche GitHub-API-Vergleich weist genau vier hinzugefügte QA-Dateien und keine Produktänderung aus.

| Datei | Finaler Git-Blob | Unterschied zu R2 |
| --- | --- | --- |
| .github/workflows/lumo-c4-small-result-actions-qa.yml | 5c02a9274bf91b428e1080ff58884af9e89d46a8 | Zwei Branchstrings von r2 zu r3 |
| scripts/run_connect_four_small_result_actions_qa.py | 3ad5492989e2dcdee4303699e0fbbd2f04f3bbe3 | Bytegleich |
| test/games/connect_four_small_result_actions_qa.dart | 0585ee1b83725a588ea2ed6f6d4ec87ffc525d7e | Bytegleich |
| tools/qa/connect_four_small_result_actions_qa.gd | 1b474002b3b93db9cae53a19c90fe75cb80c0604 | Nur die drei Geometrie-Erwartungsarrays verwenden FLOAT-Literale |

Der unveränderte Produktstand bleibt Host aab09275ec6b5808de9be539ca4e1a7e70921249 / Native e2d15dbc5f3709306decb139eeb70a1cf30c0b73. Koordinaten, Toleranzen, Scroll-/Touch-Eingaben, ACK-/Zustandsprüfungen, Captures, Belohnungsanforderungen und Quellinventare bleiben erhalten. Im Runner existiert keine anzupassende Branchzeichenfolge.

## Tatsächliche minimale Gegenprobe

Die vorhandene offizielle Godot-Engine 4.6.3.stable.official.7d41c59c4 führte zweimal eine kleine SceneTree-Reproduktion mit der vollständig aus dem QA-Overlay extrahierten Funktion aus. Eingaben kamen durch Godots tatsächlichen JSON-Parser; keine Appszene, kein Assetimport und keine Bedien-/Bildaufnahme wurde gestartet.

- Alte INT-Erwartungen: Exit 1; 15 Fälle, genau ein Fehler. Numerisch exakt richtige JSON-Geometrie wird abgelehnt.
- Neue FLOAT-Erwartungen: Exit 0; dieselben 15 Fälle bestanden.
- Alle 14 falschen Geometrie- oder Strukturvarianten bleiben abgelehnt, einschließlich Bruchteilen. JSON-Eingaben und erwartete Resultate sind zwischen den Läufen identisch.
- Beide stderr-Dateien sind leer. Die Quellen blieben vor und nach der Ausführung bytegleich.
- Der getestete neue Funktionskörper stimmt exakt mit dem finalen vollständigen Overlay überein.

Die 14 ursprünglichen Reproduktionsdateien einschließlich Kommandos, Engineidentität, stdout/stderr und Runberichten sind im Manifest json-array-reproduction.json gebunden. Der unabhängige vollständige Vierer-Diffreview ist in independent-source-review.json erhalten.

## Enge Syntaxprüfung und Grenzen

Python 3.12.14 kompilierte den unveränderten Runner mit compile(), ohne ihn auszuführen. Die Workflowdatei wurde als YAML gelesen; alle fünf tatsächlichen run-Blöcke bestanden /usr/bin/bash -n mit Bash 5.2.37. Die vier QA-Quelldateien blieben dabei unverändert. Der Syntaxlog kennzeichnet die Shellblöcke ausdrücklich als nicht ausgeführt.

Actionlint war nach dem Umgebungsreset nicht auf PATH und wurde nicht neu installiert oder als erneut bestanden ausgegeben. Die Workflowänderung besteht ausschließlich aus den zwei Branchstrings.

Die vollständigen R2-Originale und die R2-Diagnose stehen getrennt unter ../c4-small-result-actions-r2-ci-20261114/; deren Handoff ist d3bce68c301ca53b3cc4467eba586c447e00b99a. Die minimale Gegenprobe belegt die QA-Typkorrektur. Sie ersetzt keinen erfolgreichen tatsächlichen Scroll-/Touch-Nachweis, keine Original-PNG-Prüfung und keine Android-/Leistungsabnahme.

Der Autor dieser Vorbereitung erstellte den Commit ohne Refänderung. Root bestätigte danach seine unabhängige Prüfung und das Anfordern des separaten R3-Triggers. Das konkrete CI-Ergebnis gehört in einen nachfolgenden Originalbeleg.
