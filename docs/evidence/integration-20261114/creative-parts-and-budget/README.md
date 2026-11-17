# Creative-Artefaktteilung und unverändertes Host-Budget

Dieses Paket erhält die drei eingefrorenen Nachweisbereiche vollständig: `repair/`, `independent-review/` und `build-budget-17f5/`. Alle Originalbytes, Freeze-Metadaten und das vorhandene kleine Reparaturarchiv sind unverändert in `original-evidence.tar.gz` enthalten. `index.json` bindet jeden Originalpfad an Größe und SHA256; `verification.json` dokumentiert den vollständigen Byte-Roundtrip und die erneute Kontrolle sämtlicher Eingabedateien.

## Creative-Transport

Die vier geprüften Quellen ergänzen einen verlustfreien Export mit höchstens acht Teilen, jeweils höchstens 256 MiB Nutzdaten, einem identischen vollständigen Index bis 4 MiB und einem Teilmanifest bis 16 KiB. Die bisherigen Gesamt-Uploads und Produkt-/Quellen-/Publisher-Gates bleiben erhalten. Pipeline hat **20 gezielte Testmethoden bestanden: 14 neue und 6 bestehende, ohne Fehler oder Skips**, zusätzlich beide Workflows mit actionlint geprüft. Die vollständigen ursprünglichen Logs und Vorher-/Nachherquellen bleiben enthalten.

Der unabhängige Review fand keinen konkreten Blocker. Er führte keine Tests erneut aus und erteilte keine Android- oder Gameplay-Freigabe. Der bestehende CLI-/lokale ZIP-Roundtrip verwendet kleine Transportfixtures. Das alte d2c-Original mit 1.747 Mitgliedern dient als konkret gebundene Inventur und Größenplanung; es wurde für dieses Paket weder erneut exportiert noch kopiert. **Neue tatsächliche Actions-Teilartefakte, ihre Größen/Digests und die vollständige Rekonstruktion bleiben zu beobachten.** Ein Export nach dem bisherigen Gesamt-Upload ist ein eigener konsistenter Zeitpunkt; bei zwischenzeitlichen Hintergrundlogschreibvorgängen darf keine ungeprüfte Bytegleichheit zum früheren Upload behauptet werden.

## Host-Budget bleibt bei 90 Minuten

Der Quellenreview verändert keine Frist. Der historische Host848-Build dauerte 69:06; die vergleichbare Nextgen-Sequenz stieg vom damaligen Host-Log zum abgeschlossenen Native17f5-Log um rund 7:20. Nur unter den ausdrücklich dokumentierten Annahmen unveränderter übriger Phasen und übertragbarer Laufzeit ergibt sich das Szenario 76:25,9 mit 13:34,1 Rest. Dies ist **kein gemessener neuer Hostlauf und keine Fertigstellungs- oder Leistungsgarantie**. Parallele Native-/Graphics-/Touch- und separate Android-/Creative-Jobs werden nicht fälschlich zum sequenziellen Host-Build addiert. Es liegt kein beobachteter Host-Timeout vor, der eine Anhebung begründet; **90 Minuten bleiben unverändert**.

## Umfang und sichere Veröffentlichung

Das Paket enthält keine APK, kein großes ursprüngliches CI-ZIP und keine duplizierten Bildpayloads. Große Originale und vollständige ältere Logs bleiben über ihre vorhandenen quellengebundenen Referenzen dokumentiert. Alle Texte sowie die Inhalte der eingebetteten kleinen Archive und gzip-Antworten wurden auf signierte Download-URLs und Zugangsdaten geprüft; es wurden keine solchen Transportantworten gefunden, daher ist keine Originaldatei ausgeschlossen. Workflow-Variablen wie `${{ github.token }}` sind unveränderte Variablenreferenzen und keine Zugangsdaten.

Der später aktualisierte Native-Pin, aktuelle Receipts und die letzte vollständige Scripts-Suite gehören nicht zum Prüfgegenstand dieses Pakets. Hier entstehen keine neuen Source-, Pin-, Receipt-, Commit-, Ref-, CI- oder Releaseentscheidungen.

Zum vollständigen erneuten Datenabgleich:

```bash
python3 -B verify_pack.py
```
