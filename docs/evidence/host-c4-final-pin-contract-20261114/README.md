# Finaler 2020/504c-Kandidatenvertrag

Dieser enge Folgepatch betrifft ausschließlich `scripts/tests/test_candidate_2011_pin.py` auf Host `3857966d5b88a10b0309d5e93a9591ec7fe31e9d` / Tree `23c7e9d89eb88530cee9477200f6292bab8d717c`.

## Ursache und Umfang

Der veröffentlichte Host besitzt bereits `0.13.8+2020` und Native `504c8ba70d02702cbccc370d0d96c36a292c5d27`. Drei Erwartungen im bestehenden Kandidatentest waren noch auf den früheren Stand ausgerichtet:

1. Der aktuelle Kandidat muss jetzt exakt 2020/504c und den vollständigen Versionsstring enthalten.
2. Der bereits festgeschriebene historische Hash bleibt unverändert. Der neu separat geprüfte Pin 2020 wird wie 2011–2019 aus diesem älteren historischen Teilbestand ausgeschlossen.
3. Beide bisherigen falschen Quellen für Build 2020 bleiben abgelehnt. Der erwartete Grund wechselt präzise von unbekannter Version zu `revision mismatch for build 2020`; alle übrigen privaten/unbekannten Versionsfälle bleiben identisch.

Alle 24 vorhandenen Testmethoden bleiben bestehen, 21 davon AST-identisch. Sämtliche bisherigen Pin-Konstanten und die gesamte produktive `APPROVED`-Tabelle bleiben unverändert. Es werden keine zusätzlichen allgemeinen Tests und keine Gate-Ausnahmen eingeführt.

## Validierungsstand

Nur Quellen-, Hash- und AST-Vergleich; **noch kein Testlauf**. `before/` enthält den unveränderten ursprünglichen Test, `final-source/` den engen Kandidaten und `pin-contract.patch` den vollständigen Diff. Der bestehende historische Hash wurde aus den tatsächlichen Policy-Literalen statisch nachvollzogen. Die Worktree-Dateien, Git-Index und Referenzen wurden nicht verändert.

Der gezielte einmalige Vorabcheck folgt erst auf Roots veröffentlichtem und exakt importiertem Nachfolger. PCM- oder Native-Läufe gehören nicht dazu.
