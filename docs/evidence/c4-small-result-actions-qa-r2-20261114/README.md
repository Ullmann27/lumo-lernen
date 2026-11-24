# Eng begrenzte QA-Wiederaufnahme: Godot-UID-Metadaten

## Originaler Fehllauf bleibt vollständig erhalten

Der tatsächlich abgeschlossene Run [43594135818](https://github.com/Ullmann27/lumo-lernen/actions/runs/43594135818), Attempt 1, verwendete QA-Commit `dc2e1b50ebeadb895aa691d809f2c457e0142633`. Job `132444932236` scheiterte nach erfolgreicher Quellen-Vorprüfung und erfolgreichem Godot-Import.

Der neue QA-Runner lehnte 334 zusätzliche UID-Sidecars ab: 329 `.gd.uid` und fünf `.gdshader.uid`. Alle aufgeführten Basisnamen sind im originalen Native-Quelleninventar vorhanden. Das Originalarchiv enthält keine Sidecar-Inhalte; ihre konkreten CI-Bytes werden deshalb nicht aus der lokalen Cachekopie abgeleitet.

Der Fehler entstand vor dem Start des Dart-Harness und des Renderers. Beide Exitcodes stehen im Originalresultat auf `null`, es sind keine Laufzeitbefehle protokolliert, und das Archiv enthält **null PNGs**. Der Lauf belegt weder einen Flutter-Compilererfolg des neuen Harness noch die Bedienung der zwei Zielaktionen. Er ist kein Beleg für einen Produktfehler.

Originalartefakt `14113587571` wurde einmal über den offiziellen Download übernommen, ZIP-CRC und kompletter Hash wurden geprüft:

- Umfang: **146.035 Bytes**
- SHA256: `38bdeb870ce8c681d7663038decbfb4f29ca35986659ed248fde487e32014481`
- Vier unveränderte Archivmitglieder: Originalimportlog, Quelleninventar, grüne Vorprüfung und fehlgeschlagener Runtime-Start.
- Alle 447 Host- und 1.256 Native-Einträge entsprechen bytegleich dem bereits unabhängig gegen die exakten Remote-Gitbäume geprüften Quelleninventar desselben `aab09275/e2d15`-Paares. Auch die vier QA-Dateien wurden gegen die tatsächlich eingefrorenen Dateien verglichen.

Der Handoff bindet das vollständige Original-ZIP, sämtliche vier extrahierten Originale, den vollständigen abgeschlossenen Joblog sowie API-Metadaten und den engen Fehlerreview unter `docs/evidence/c4-small-result-actions-qa-failure-20261114/`.

## R2-Änderung

Die Produktquellen bleiben **Host `aab09275ec6b5808de9be539ca4e1a7e70921249` / Native `e2d15dbc5f3709306decb139eeb70a1cf30c0b73`**.

Nur der QA-Runner und die beiden wörtlichen Branchnamen im separaten Workflow ändern sich. Der neue normale QA-Branch lautet `qa/lumo-c4-small-result-actions-20261114-2708-r2`; er erhält einen eigenen direkten Child des eingefrorenen Hosts. Der bestehende QA-Branch wird nicht zurückgesetzt oder überschrieben.

| Datei | Finaler Git-Blob |
|---|---|
| `.github/workflows/lumo-c4-small-result-actions-qa.yml` | `b480b4664efa0d2d9dcd04c09d50a74848b9d9ca` |
| `scripts/run_connect_four_small_result_actions_qa.py` | `3ad5492989e2dcdee4303699e0fbbd2f04f3bbe3` |
| `test/games/connect_four_small_result_actions_qa.dart` | `0585ee1b83725a588ea2ed6f6d4ec87ffc525d7e` |
| `tools/qa/connect_four_small_result_actions_qa.gd` | `cc9ef04069bb2d73d2953a725e7ee5974e5b496f` |

Der Runner nimmt zusätzliche Dateien nur als reguläre Godot-UID-Metadaten an, wenn sie direkt neben einer exakt getrackten `.gd`- oder `.gdshader`-Quelldatei liegen. Der tatsächliche Quellblob muss zum HEAD passen. Die Sidecardatei muss eine einzelne LF-terminierte ASCII-Zeile in der kanonischen Darstellung des tatsächlichen Godot-4.6.3-Generators enthalten: Alphabet `a–y, 0–8`, höchstens 13 Zeichen, Wert höchstens `2^63−1`, keine redundante führende Nullziffer.

Dies folgt aus der offiziellen [ResourceUID-Implementierung](https://github.com/godotengine/godot/blob/4.6.3-stable/core/io/resource_uid.cpp), Git-Blob `4a03a4b83430af226b16481cdb4945b823b9b21e`. Der permissivere Engine-Leser allein gilt nicht als ausreichende Prüfung. Bereits versionierte historische UID-Dateien bleiben unter den unveränderten Quellhashprüfungen und werden nicht nachträglich auf ein neues Format umgedeutet.

Die zusätzlich angenommenen UID-Dateien werden als sortierte eigene Liste mit Basis-Quellblob, UID-Text, Byteumfang, Gitblob und SHA256 in die Quellen-Snapshots aufgenommen. Die bestehende vollständige Vorher-/Nachher-Gleichheitsprüfung bindet damit auch Ergänzungen, Entfernungen oder Änderungen dieser Metadaten. Andere untracked Inputs, fremde Scripts und nicht reguläre Dateien erhalten keine neue Ausnahme.

Dart-Harness `0585ee1…` und nativer QA-Overlay `cc9ef040…` bleiben vollständig unverändert. Keine Eingabe-, ACK-, Belohnungs-, Zielgrößen-, Capture- oder Zustandsassertion wurde abgeschwächt. Auch die bisherigen Quellen-/Index-/Branch-/Releaseprüfungen bleiben bestehen.

## Tatsächliche lokale R2-Prüfungen

Die Originalausgaben und die ausführbare Testdatei liegen im Handoff. Es wurden neun Methoden gegen die tatsächlichen neuen Runnerfunktionen und isolierte temporäre Git-Repositories ausgeführt: **9/9 erfolgreich, 0,282 Sekunden, Exit 0**.

Die Fälle prüfen passende reguläre UID-Dateien bei Script und Shader, unerwartete Scripts, fehlerhafte bzw. nicht kanonische UID-Inhalte einschließlich Überlauf, fehlende/untracked oder byteabweichende Basisquellen, Symlinks, andere Dateiendungen und Änderungen bzw. Entfernen nach dem Vorher-Snapshot. Ein weiterer Fall bewahrt die Trennung bereits getrackter historischer UID-Dateien von neu erzeugten Metadaten. Das sind gezielte Metadatenverträge mit klar benannten Fixtures; kein simuliertes Godot-Spiel und keine Bedienbestätigung.

Python-`compile()`, Actionlint und `bash -n` auf allen fünf tatsächlichen Workflow-Runblöcken endeten jeweils mit Exit 0. Die vier QA-Dateien blieben während dieser Prüfungen bytegleich. Identische Dart-/GDScript-Dateien wurden nicht erneut geparst; ihre vorliegenden Parsernachweise und der weiterhin offene lokale Dart-Paketblocker bleiben unverändert gültig.

Der unabhängige Quellenreview ist unter `independent-uid-review.json`, Blob `8306bef90672946976f6714e91ce9ee148a94d86`, gebunden. Er las die tatsächlichen Enginequellen und beobachtete zusätzlich 334 passende untracked Sidecars in der vorhandenen lokalen Parserkopie. Das wird ausdrücklich nicht mit den ungesicherten CI-Sidecar-Inhalten gleichgesetzt.

Root hat den engen Diff und die Originalprüfergebnisse gelesen. Dieser Beleg bereitet die separate R2-Ausführung vor; er behauptet kein Ergebnis eines noch nicht abgeschlossenen R2-Bedienlaufs.
