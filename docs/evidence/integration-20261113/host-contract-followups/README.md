# Lokale Host-Vertragsläufe: Village-Followup und historischer Stand

Dieses Paket bewahrt zwei bereits abgeschlossene lokale Vertragsläufe.
Beim Sichern wurden keine Tests erneut ausgeführt und keine Quelldateien,
Refs oder Freigaben verändert.

| Nachweis | Ergebnis | Gebundene Dateien | Einordnung |
|---|---|---:|---|
| current-village/ | 414 PASS, 0 Skips, Exit 0 | 1.705 | Aktueller lokaler Village-Followup-Lauf |
| historical-9e285e1/ | 409 PASS, 0 Skips, Exit 0 | 1.849 | Eigener historischer Quellstand |

Die vollständigen Quellenlisten vor und nach jedem Lauf sind jeweils
identisch. Die verschiedenen Dateianzahlen stammen aus den jeweiligen
Original-Erfassungsumfängen; daraus wird kein Vergleich von Dateilöschungen
oder eine gemeinsame Quellidentität abgeleitet.

## Aktueller Village-Followup

Der aktuelle Lauf fand am 13.11.2026 von 17:19:55 bis 17:21:57 UTC statt.
Sein vollständiges Originalprotokoll hat SHA256:
a3613c9a4bd8608a21bfb1c128e45ae527b8b479133689173f259ee9fee500eb.

Das Originalresultat nennt den Basiscommit
3deae002a9930bfc7bef7afeaed6ba4861125ec1. Die tatsächlich geprüfte lokale
Kombination wird durch die 1.705 vollständigen Quellhashes gebunden. Der
Basiscommit wird nicht nachträglich als Commit der veränderten Kombination
oder als Identität des historischen Remote-Stands ausgegeben.

## Historischer eigener Stand

Der frühere Lauf fand am 13.11.2026 von 16:48:55 bis 16:50:31 UTC statt.
Seine ursprüngliche Bindung bleibt erhalten:

- Remote: 9e285e17a8cbd54f73cf5a14ccdad07c0ad29199
- Lokal: 3deae002a9930bfc7bef7afeaed6ba4861125ec1
- Tree: a62c2186c5a5f4b9d89b172f67a0625d8736098c
- Log-SHA256: 528b05d7f5180a1a65fe2833dfb3d3575960236689b766140c4e2db743b0b3c0

Dieser 409-Test-Lauf wird ausschließlich als historischer Nachweis geführt.

## Verlustfreie Originale

In beiden Unterordnern bleibt result.json bytegleich. Die vollständigen Logs
sowie die vollständigen Quellenlisten sind deterministisch gzip-komprimiert:
mtime 0, kein Dateiname im gzip-Header, Kompressionsstufe 9. Entpackte Bytes
wurden exakt gegen die jeweiligen Originale geprüft; Original- und
gespeicherte Hashes sowie Bytegrößen stehen im Manifest. SHA256SUMS bindet
jede gespeicherte Datei.

Es handelt sich um lokale Python-Vertragsprüfungen. Das Paket behauptet
keinen tatsächlichen Android-Gerätelauf, keine APK-/AAR-Abnahme, keine
Rendererabnahme und keinen späteren CI-Gesamterfolg. Auch vorbereitende
Host-Ausgaben innerhalb der Testlogs ändern diese Grenze nicht.
