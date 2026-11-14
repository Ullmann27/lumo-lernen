# Unabhängige Integration der 49 aktuellen Native-Bilder

**Ergebnis: Alle 49 eingebauten PNGs stimmen exakt mit den vier bestätigten Bildübergaben, dem finalen 2020-Receipt und ihren Mitgliedern im aktuellen Originalarchiv überein.**

Die Prüfung ist rein lesend. Es wurden keine neuen Bilder visuell abgenommen, keine Tests oder Renderer gestartet und keine Uploads vorgenommen. Die bestehenden Einzelreviews bleiben ihren tatsächlichen vier Reviewern zugeordnet.

| Bindung | Tatsächlich geprüft |
|---|---|
| Native | 785413d395292a243eaa0a0748671eb15d3f80ff|
| Run / Artefakt | 43570887024 / 14105224381|
| Original-ZIP | 227.410.428 B; SHA256 31c926ae589073839dd4e89c955a0b59644c23e355e7685a4e31149d22d32c4e|
| Receipt | 43.034 B; SHA256 12ffaba3dac821f480aaeb3a9392f2f6fbfdf669535d6b6351026ec22fef70b7|
| Finale Bilder | 49 Dateien, 40.540.692 B, 10 Module|
| Übergaben | Root 13, learning_worlds 9, character_animation 12, games_worlds 15|

Die tatsächlichen Zielpfade wurden mit dem vorhandenen Helper `reviewed_relative_path(..., studio_version=2020)` berechnet. Für jede Datei stimmen SHA256, Gitblob, Modus, PNG-Abmessungen und Zuordnung zum ZIP-Mitglied. Alle 49 Mitglieder wurden vollständig aus dem aktuellen ZIP gelesen und mit den eingebauten Bytes verglichen. Die fünf Quellenstempel nennen 785413 und haben leere Dirty-Stempel. Es gibt keine fehlenden, zusätzlichen oder doppelten Bildpfade und keine Hashabweichungen.

Ein inhaltlich unverändertes Bild kann auch in einem älteren Lauf dieselben Bytes besitzen. Entscheidend ist hier die tatsächlich geprüfte Zugehörigkeit zum aktuellen 785413-Originalarchiv; ältere acf51-Dateien oder Zuordnungen wurden nicht als Ersatzquelle benutzt.

`review.json` enthält die vollständige Tabelle aller 49 Dateien-Tabelle und die Hashes aller vier Übergaben. Receipt, Helper und Eingabemanifeste waren nach der Prüfung unverändert. Diese Integrationsprüfung erteilt keine zusätzliche Android-, APK-, Spielmechanik-, Geräte-, FPS- oder Wärmeabnahme. Roots bereits gemeldete Visual-/Pinprüfungen wurden nicht erneut ausgeführt.
