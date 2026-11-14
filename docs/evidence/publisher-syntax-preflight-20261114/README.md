# Syntaxprüfung des überholten Publisher-Entwurfs

## Ergebnis

Am 14.11.2026 um 12:47:09 UTC wurde die unveränderte Workflowquelle aus Commit `bb5aa0e58355d29258392693674c5144079b9e6b` tatsächlich geprüft:

- YAML: erfolgreich geparst; keine doppelten Mapping-Schlüssel.
- Sämtliche sieben Bash-Runblöcke aus elf Workflow-Schritten: `bash --noprofile --norc -n`, jeweils Exit 0.
- Sämtliche drei eingebetteten Python-Heredocs: `ast.parse` und `compile` erfolgreich; kein Python-Block ausgeführt.
- Prüfdriver: Exit 0 unter Python 3.12.14, PyYAML 6.0.3 und GNU Bash 5.2.37.

Originalpfad: `.github/workflows/lumo-live-2020-publish.yml`  
Originalblob: `04247c39f61e138bcca767447b1b0bec5aeac611`  
SHA256: `78c923eda6436ebffa073c519b226e7e3f33c973b34b792429340e9277bf55ab`  
Größe: 16.753 Bytes.

## Status und Grenze

Dieser Publisher ist ausdrücklich **SUPERSEDED**. Er bleibt unverändert an Host `07cac7225e2f7b6451665dfda9c38841f51c758b`, Run `43586101225`, Attempt 1 gebunden. Dieser alte Gesamtjob endete abgebrochen und ist keine Freigabe für eine Veröffentlichung. Die Syntaxprüfung ändert diese Bindung nicht und aktiviert nichts.

Es wurden keine Shellblöcke des Workflows, Actions, Netzwerk- oder Releaseoperationen ausgeführt. Die Bash-Prozesse erhielten nur die Syntaxoption `-n`, deaktivierte Profile und eine Umgebung ohne `BASH_ENV` oder importierte Funktionen. Python-Code wurde ausschließlich in einen Syntaxbaum und anschließend in ein unbenutztes Codeobjekt übersetzt.

YAML-Parsen ersetzt keine GitHub-Actions-Ausdrucksprüfung oder Actionlint-Prüfung. Bash-Syntaxprüfung belegt keine verfügbaren Programme oder Laufzeitwirkungen. Python-Kompilierung löst keine Importe auf und führt weder Datenprüfungen noch APK-Verifier aus. Es wird keine neue Build-, Android-, Signatur- oder Veröffentlichungsabnahme behauptet.

## Enthaltene Originalbelege

`original-publisher.yml` ist bytegleich mit dem oben genannten Gitblob. `preflight.py` ist der tatsächlich ausgeführte Prüfdriver. `original-run.log` enthält dessen unveränderte Standardausgabe und Fehlerausgabe. `invocation.json` hält Aufruf und tatsächlichen Exitcode fest. `result.json` enthält alle sieben Shell-Ergebnisse und drei Python-Ergebnisse mit Quellzeilen und Hashes. Die Verzeichnisse `bash/` und `python/` enthalten exakt die aus den YAML-Runwerten gewonnenen Prüfeingaben.

`manifest.json` enthält Byteanzahl, SHA256 und Gitblob-SHA jeder übrigen Belegdatei. `source-binding.json` und `original-commit-response.json` binden die Herkunft an den unveränderlichen Reviewcheckpoint. Dieser eigene Evidenzbranch verändert weder den zentralen Integrationsbranch noch irgendeinen Workflowpfad.
