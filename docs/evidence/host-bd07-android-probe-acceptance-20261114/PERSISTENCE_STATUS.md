# Sicherungsstand der OCR-Prüfung bd07

Dieser neu verfasste Nachtrag dokumentiert den Sicherungsstand nach dem Ausfall der lokalen Arbeitsumgebung. Er ersetzt keine Originaldatei.

Der CI-Job [132585421795](https://github.com/Ullmann27/lumo-lernen/actions/runs/43640054345/job/132585421795) wurde für den tatsächlichen Feature-Commit bd07b82fd01fcb8ceecb21894bf825d7c5ff0761 erfolgreich beendet. Agent C hatte vor dem Ausfall das Originalartefakt 14132180002 vollständig heruntergeladen (20.573.695 Bytes, SHA256 f106b1ab381f6645152a2148bb2d8374774b287189c3e4ae754e6ce4db8af7e5) und alle 76 ZIP-Mitglieder geprüft. Die berichtete Auswertung umfasst 11 Connect-Four-, 25 Kart- und 15 Creative-Prüffälle, insgesamt 51 ohne Fehler oder Skips. Diese Auswertung wird hier als zuvor ausgeführte Agentenprüfung ausgewiesen; der nachstehende Sicherungsumfang ist enger.

Von dem damals vorbereiteten Paket mit 71 Zielen sind in diesem Verzeichnis zunächst nur zwölf vollständige Originaltexte bzw. exakte Quellkopien gesichert: CI-Joblog, anfänglicher lokaler Übertragungsfehler, terminale Jobmetadaten, Artefaktmetadaten und acht Quellen. Die zwölf Blobs wurden jeweils erstellt und vollständig als UTF-8 zurückgelesen. Ihr Gesamtumfang beträgt 275.221 Bytes. Die Quellkopien entsprechen den Git-Blobs des geprüften Commits.

59 weitere Inhalte einschließlich des vollständigen ursprünglichen Uploadmanifests konnten nach dem Ausfall nicht mehr bytegenau aus der lokalen Umgebung gelesen werden. Sie sind in diesem Checkpoint ausdrücklich nicht enthalten. Aus Zusammenfassungen wurden keine fehlenden Originale rekonstruiert. Das ursprüngliche vorbereitete Manifest war mit SHA256 ca8215f676b82de23fa03123043c76b342668e07f8885f9cb8dd13d5103717cf gebunden; dieser Hash allein ersetzt das fehlende Originalmanifest nicht.

Der zusätzliche Fixture-Commit 16442f286fd1b5cd8b40a5c6b402f54fe345391b verändert nur scripts/tests/test_studio_creative_clock_calibration.py. Seine erneute CI-Abnahme wird getrennt geführt. Diese OCR-Prüfung liest vorhandene Originalpixel; sie ist kein neuer Android-Gerätetest und kein Leistungsnachweis.
