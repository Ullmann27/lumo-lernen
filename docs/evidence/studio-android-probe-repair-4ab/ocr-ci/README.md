# Originaler OCR-CI-Beleg auf a446f3c1

Der abgeschlossene Job **132285430053** im [Run 43542310963](https://github.com/Ullmann27/lumo-lernen/actions/runs/43542310963/job/132285430053) lief auf QA-Commit `a446f3c1a320ad5297e17606727d801c5e993ce1` und endete am 14. November 2026 um 01:44:53 UTC erfolgreich.

| Ausgeführter Bereich | Tatsächliches Ergebnis | Reichweite |
| --- | --- | --- |
| Originale Caption-Tests | 12 PASS, 0 Skip; 22,180 s | Vier unveränderte Originalbilder aus API35/API37 mit echtem Tesseract plus acht Fehlergrenzen |
| Quellen- und Binärbinder | 17 PASS, 0 Skip; 2,340 s | Isolierte Vertrags- und Gegenfalltests; kein Androidlauf |
| OCR-Version/Sprachen | Tesseract 5.3.4; deu, eng und osd vorhanden | Unveränderte Originalausgaben im Artefakt |

Das unveränderte Originalarchiv `original-artifact.zip` ist 2.613 Byte groß und hat SHA256 `54b7887130b9868e70132439c6604b59b233111cc7e4818a90fce3340b842687`. Der Digest stimmt mit GitHub-Artefakt **14091419071** und dem Upload-Eintrag im vollständigen Joblog überein. CRC und alle vier extrahierten Dateien wurden gegen die ZIP-Mitglieder geprüft.

`review.json` enthält die genaue Quellenbindung und Grenzen. `artifact-byte-verification.json` bindet alle Artefaktdateien. `evidence-upload-manifest.json` listet die ausschließlich hierfür vorgesehenen Dateien mit Größe, SHA256, Git-Blob-ID und vorgesehenem Repositorypfad.

Der vollständige Originaljoblog bewahrt auch Node-/punycode-/url.parse-Deprecationwarnungen. Die drei absichtlichen FAIL-JSONs im Binderlog gehören zu erfolgreich erkannten Negativfällen. Es wurden weder neue Tests gestartet noch APKs heruntergeladen. Dieses Paket bestätigt keine Android-Tour, keine erfolgreiche Berührung des Lernknopfs, keine Cards-Abnahme und keine Geräteperformance. Die API35-/API37-Matrix wird getrennt anhand ihrer eigenen Ergebnisse bewertet.
