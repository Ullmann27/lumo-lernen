# Separater Runtime-Nachlauf für die unveränderte APK 2032

Dieser neue QA-Einstieg baut und veröffentlicht keine APK. Die vier Pflichtfälle
sind die wirkliche 9+7-Abgabe 15 falsch /16 unterstützt richtig, ein aktiver
Silben-Aufgabenwechsel, native Banane mit vier aktuellen Langsamer-Segmenten und
native Mustererklärung mit anschließend ausdrücklicher fachlicher Core-Abgabe.

## Herkunft und Schutzgrenzen

Die gebaute x86-APK bleibt Quelle `9b38360ca5f21919dce4a2b99e605ee39bbbf454`,
Native `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`, Version 0.13.20+2032,
Buildrun 43837592237, Artifact 14213246542. Neue QA-Commit-/Runidentität sind getrennt.
Der Downloader prüft die feste ZIP-/APK-Bytezahl, SHA-256, ursprüngliche Jobs,
Native-PCK, Paket und Signatur über die bestehenden tatsächlichen Installations-
und Manifestprüfer. Git-Tree-Diff erlaubt nur die neuen QA-Dateien und Dokumentation.
Alle historischen und aktuellen gemeinsamen Probe-/Publisherdateien bleiben
unverändert. `release_eligible=false`; der Nachlauf ersetzt keine Volltour.

Die vorhandenen Numeric-/Wortwechsel-Fallmethoden und fachlichen Prüfer werden
unverändert geerbt. Die bestehende native Banane-/Muster-Navigation wird benutzt.
45 Sekunden aktive Beobachtung, höchstens eine Sekunde XML-Erfassung bis zum
angeforderten Tap, einmaliges Replay, echte aktuelle Ziele und vollständige
positive Videodauer bleiben erhalten. AutoRead und temporär 320 dpi bei 1080×2340
werden ausschließlich über die vorhandenen UI-/Emulatorwege verändert und
vor dem nativen Teil exakt zurückgestellt. Keine privaten Appdaten werden geschrieben.

## Enger aktueller Muster-Fix

Acht bytegleiche XMLs aus dem bereits abgeschlossenen Androidjob 133221738048
zeigen die exakte Antwortüberschrift als vollständige Zeile im mehrzeiligen
Aufgaben-ImageView. Die alte Ganzfeldprüfung übersieht sie. Nur der neue Adapter
liest diese Zeile, bindet sie an die aktuelle exakte Musterfrage, verlangt vier
eindeutige aktive vollständig sichtbare Karten und beobachtet nach dem Screenshot
noch einmal frisch vor dem einzigen Tap. Die native Rückkehr bleibt zuvor ungewertet.
`verify_core_submission` bewertet weiterhin die echte neue gespeicherte Abgabe.
Der neue Endvalidator akzeptiert `NOT_EXERCISED` ausdrücklich nicht.

Original-XMLs behalten einschließlich CRLF ihre Bytewerte; `git diff --check`
wird deshalb mit `core.whitespace=cr-at-eol` ausgeführt. Die Auswahl vergangener
2031-Teilfälle ist nur Herkunfts-/Hosttestfixture, kein neuer 2032-Lauf.

## Langsamer-Metadaten

Der übernommene Fall liefert historische beschreibende e05/678-Metadaten. Sie
bleiben unter `inherited_metadata_not_current_runtime_evidence` ausdrücklich
historisch. `source_rate_contract` bindet stattdessen die tatsächlich gepinnte
9b/9d-Quelle, PCK und gelesene Quellfingerprints. Die Hostblobs werden auf dem
Runner erneut aus dem Quellcommit geprüft; der native Funktionsfingerprint ist
an das zuvor gelesene exakte Gitobjekt gebunden und wird nicht als erneute
Runner-Lektüre ausgegeben. Keine akustische Rate, Wortqualität oder Phonemzeit
wird aus MediaPlayer-Callbacks abgeleitet.

## Tatsächliche Prüfungen dieses Patches

Die unveränderte historische Core-Methode ist an der aufgezeichneten XMLfolge
rot (0 statt 1 ausdrückliche Abgabe). Der neue Adapter besteht denselben Fall.
13 neue gezielte Hostprüfungen; gemeinsam mit den beiden tatsächlich eingebundenen
bestehenden Fallmodulen 64/64 bestanden. AST/YAML, sechs Shellblöcke und vier
CLI-Help-Einstiege sind geprüft. Ein erster gemeinsamer Import scheiterte nur
an einer im Sparsecheckout fehlenden Testhilfe; das separate Rohlog bleibt im
Scratch-Handoff. Das ist kein Produkt-RED und wird nicht als Test-PASS gerechnet.

Kein neuer Androidlauf, kein Download und keine Remote-/CI-Aktivierung wurden
in dieser Arbeitskopie vorgenommen. Der erwartete Workflow ist
`.github/workflows/lumo-nextgen-2032-runtime-cases.yml`, Branch
`qa/lumo-nextgen-2032-runtime-cases-20261116`, Config
`.github/probes/lumo_nextgen_2032_runtime_cases.json`. Root aktiviert nach Review.
