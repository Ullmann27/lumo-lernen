# Zweiter vollständiger 2028-Replay: geprüfter QA-Startstand

Die Komponentenbäume der minimalen XML-Korrektur und des engen Postgrant-Lesers wurden getrennt veröffentlicht und in den Integrationszweig übernommen. Der Postgrant-Produzentencommit ist `752fb29ee369e54b951ead4d5cfc672d9e7f3185`, sein bytegleicher veröffentlichter Baum liegt auf `qa/lumo-mic-postgrant-reader-20261116` als `6cd862b820c09dd3cafec98c9f55bf25c3c7dd52`. Originalübergabe, echte RED-/GREEN-Protokolle und Veröffentlichungskarte sind enthalten.

Im integrierten Root-Stand liefen alle fünf unveränderten Testsammlungen: 72 Originalprobe-, 27 Reference-, zwölf Current-, 14 Replay- und sieben Veröffentlichungstests, zusammen **132 PASS, keine Fehler**. Jeder vollständige Log ist mit Bytezahl und SHA-256 erfasst. Das sind Host-Prüfungen des QA-Programms, keine 132 Androiddurchläufe.

Ein unabhängiger Read-only-Review fand keinen Blocker: Der zusätzliche Sprechen-Tap setzt einen eigenen beobachteten Grant-Tap, eine frische dialogfreie eigene Aufgabenansicht, exakte Aufgabenanker, genau einen deutschen Bereitschaftsstatus und einen eindeutigen aktiven Knopf voraus. Er erfolgt höchstens einmal im ursprünglichen 35-Sekunden-Budget. Bereitschaft allein ist niemals PASS. Das bisherige Listening-/Limitierungs-Gate entscheidet weiterhin. Es gibt keinen direkten Recorder-Aufruf und keine Produktänderung. Die Testzustände sind synthetisch, der tatsächliche Postgrant-Zustand ist erst im folgenden Replay zu beobachten.

APK-Quelle `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242`, Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`, Version 0.13.16+2028, APK-Hashes, Signatur, Paketerkennung und vollständige Ergebnisgates bleiben unverändert. Ausschließlich `replayAttempt` wird von 1 auf 2 erhöht. `config/nextgen-release.json` bleibt bytegleich; es wird keine APK neu gebaut. `main` bleibt geschützt.

Die ursprüngliche Androidtour und der erste Replay bleiben getrennte FAIL-Originale. Eine Veröffentlichung ist erst nach zwei vollständig erfolgreichen tatsächlich neu ausgeführten Touren auf derselben installierten APK zulässig. Bis dahin kein Android-PASS und kein öffentlicher Download.
