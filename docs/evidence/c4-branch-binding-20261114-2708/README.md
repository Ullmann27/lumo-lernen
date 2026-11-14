# C4-Branchbindung: tatsächlicher Fehler und enger Rot-/Grün-Nachweis

## Ausgangspunkt

Der vollständige Lauf [43578509499, Versuch 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43578509499) gehört zu Host 803a4e960ffb804a46b6d09417731c031f00f680 und Native 0e26153f0e58cc05739e72923b4c563a4cf380b8. Sein Android-C4-Job 132415120342 endete am 14.11.2026 mit:

    ValueError: Candidate source/event/workflow differs
    observations: 0
    transitions: 0

Die ursprüngliche C4-Ergebnisdatei enthält acht erfolgreiche APK-Identitätsprüfungen. Der Fehler tritt in artifact_binding auf, vor dem C4-Start und vor den ersten C4-Eingaben. Dieser Lauf prüfte deshalb die separate native Rücksprungreparatur nicht. Der ursprüngliche CI-Fehler bleibt ein Fehler; der lokale Metadaten-Replay ändert seinen Status nicht.

Die vollständigen 803a-Originalbelege sind zusätzlich im getrennten Checkpoint [6a5ae5327570fc60434672074f246c95e1c59283](https://github.com/Ullmann27/lumo-lernen/commit/6a5ae5327570fc60434672074f246c95e1c59283) erhalten.

## Ursache und Änderung

Die Originalmetadaten nennen den Branch work/lumo-play-quality-20261114. Quelle, Ereignis und Workflow stimmen mit der erwarteten Identität überein. Der C4-Metadatenprüfer akzeptierte jedoch ausschließlich integration/lumo-c4-connections-20261114, während Workflow und Delivery-Prüfer beide Branches bereits ausdrücklich zuließen.

Die Reparatur basiert auf dem isoliert ausgecheckten Folgestand f4df466ed004879fc56284b024475a0ab0661259, Tree 350c713c20e58d17991d8bd09a160206e97dd119. Der bisherige C4-Produktionsblob war dort bytegleich mit 803a: 5bc2336a8da1f71e6c64a2efdcb29d6965a1d8aa.

In **tools/android_qa/connect_four_android_evidence.py** werden genau die beiden bereits erlaubten Branches als feste Menge geführt. Ausschließlich die Branchprüfung wechselt von Gleichheit mit dem einzelnen Integrationsbranch zu Mitgliedschaft in dieser Menge. Die genaue Source-SHA, das Repository, Ereignis, Workflow, Run, Versuch, Artefakt-ID, Digest, Verfügbarkeit und alle drei erforderlichen vorherigen Jobs werden weiterhin geprüft. Die zurückgegebene Bindung bleibt unverändert.

Die direkten Produktionsnutzer sind **.github/probes/lumo_connect_four_android_probe.py** und **scripts/verify_connect_four_candidate.py**. Der abschließende Deliverypfad ruft den Kandidatenprüfer erneut auf. **scripts/verify_connect_four_delivery.py** enthält bereits die richtige Zweigmenge und die genaue Gleichheit zwischen Run-Branch und aktuellem PR-Head. Dieser Code und seine Tests wurden nicht verändert.

## Tatsächliche Ausführungen

Vier Originaldateien wurden aus dem einmal heruntergeladenen Androidartefakt 14110022118 bytegleich übernommen: run.json, artifacts.json, jobs.json und c4-result.json. Das sind Originaleingaben, keine nachgebauten Metadaten. Der Run-Snapshot enthält den damaligen Status in_progress.

**replay_original_metadata.py** führt die tatsächliche Python-Funktion artifact_binding mit diesen unveränderten Dateien und den originalen erwarteten Source-, Native-, Run-, Versuch-, Artefakt- und Digestwerten aus. Vor und nach dem Aufruf werden die Originaldateien und beide eingelesenen Produktionsmodule gehasht.

| Ausführung | Originalmetadaten-Replay | Dieselben 15 Testmethoden |
|---|---|---|
| Bisheriger Produktionsblob 5bc2336a… | Exit 1, exakt derselbe ValueError | Exit 1, genau ein Fehler beim erlaubten Qualitätsbranch |
| Reparierter Produktionsblob 9f39b85f… | Exit 0, gültige Bindung | Exit 0, 15 bestanden |

Die Testdatei blieb zwischen Rot und Grün bytegleich: Git-Blob b64071e3c99ebe6529a3fa9237192208e03a16ee, SHA256 daec2473fccb4e1785bf7e8ef884be5c484bbb1b86163f73f40314b9abc64ad5.

Die 15 Methoden bestehen aus sechs C4-Bindungstests und neun unveränderten Delivery-Akzeptanztests. Die drei bisherigen C4-Bindungstests bleiben unverändert. Die neuen Fälle prüfen beide ausdrücklich erlaubten Branches, fremde beziehungsweise nur ähnlich benannte Branches sowie ungültige Quellen-, Run-, Artefakt- und Jobdaten auf dem Qualitätsbranch. Die unveränderten Deliverytests prüfen weiterhin die Run-/PR-Head-Gleichheit, fremde Repositories und Branches sowie fehlende, übersprungene oder fehlgeschlagene Pflichtprüfungen.

Die Metadaten-Testfälle in den Unit-Tests sind ausdrücklich synthetisch. Der separate Replay verwendet dagegen die tatsächlichen Originaldateien. In beiden Läufen blieben alle geprüften Eingaben während der Ausführung unverändert. git diff --check bestand ebenfalls.

## Originalprotokolle und Wiederholung

Unter red/ und green/ liegen jeweils:

- **original-metadata.log**: vollständig empfangene Prozessausgabe des tatsächlichen Replays.
- **original-replay.json**: vom Replay selbst geschriebener Bericht mit Eingabe- und Quellhashes.
- **contracts.log**: vollständiges ursprüngliches Unittest-Protokoll.
- **execution.json**: tatsächliche Befehle, Rückgabecodes, Laufzeiten sowie Hashes vor und nach der Ausführung.

Die beiden Replaydateien eines Laufs sind absichtlich bytegleich: Der Prozess schreibt und druckt denselben Bericht. Der genaue ausgeführte Modulinhalt ist durch seinen Git-Blob und SHA256 gebunden; die Arbeitskopie behielt während der gezielten Prüfung den Basis-HEAD f4df466.

Die grünen Prüfungen lassen sich im Repository mit einem frischen Ausgabepfad wiederholen:

    python3 docs/evidence/c4-branch-binding-20261114-2708/replay_original_metadata.py --source-root . --out /tmp/lumo-c4-branch-replay-new.json
    PYTHONPATH=tools/android_qa/tests:scripts/tests python3 -m unittest test_connect_four_android_evidence.BindingTests test_connect_four_delivery.OriginalAcceptanceTests -v

Dieser Nachweis führt keine Engine, keinen Android-Emulator, keinen APK-Bau und keinen abschließenden Kandidaten-/Deliverylauf erneut aus. Er belegt genau die reproduzierte Fehlablehnung und deren Reparatur im Metadatenprüfer. Der neue kombinierte Quellstand benötigt weiterhin seine tatsächliche Android-C4- und finale Kandidaten-/Delivery-Abnahme.
