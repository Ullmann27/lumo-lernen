# Lumo Lernen + Lumo Kart – Integrationskandidat 1956 (16.10.2026)

**Integration auf Basis der bereits getesteten Flutter-Version 1955.** Keine Änderung am UI, an Lernaufgaben, Schreibtrainer, Journal, Sprach-/Audio-Engine, Kinderprofilen, Spielständen oder an der Steuerung.

## Nachvollziehbare Quellkette

- Flutter-Basis: `3287a458308699b5a790093ed718ec9652179f0d` aus Lumo Lernen PR #327 (Version `0.12.47+1955`).
- Vorheriger Godot-Quellpin: `268c9b327a8f81ba08c55e1b4bccd3664ce12f88`.
- Neuer exakter Godot-Quellpin: `41aa76a28565faa21ea93d3d31d74836c38005a9` aus Lumo Godot PR #76, mit drei echten Sonnenhafen-Aussichtstürmen und Android-`adb logcat`-Diagnosekorrektur.
- GitHub-Commitvergleich bestätigt: Neuer Godot-Commit ist ein Nachfahre des alten Pins (9 zusätzliche Commits, 0 zurück).
- Engine unverändert Godot 4.6.3; Flutter/Android-Version `0.12.48+1956`.

## Abnahme, kein Schein-Erfolg

Der existierende `lumo-1955-original-ui-feedback.yml`-Workflow läuft auch für den 1956-Zweig: vollständige Flutter-Tests und Szenen-Screenshots; danach **signierte** arm64- und x86_64-APKs mit SHA-256 und Quellprovenienz; anschließend Installation der exakten x86_64-APK auf dem Emulator samt echter Navigation und Godot-Kartstart.

Ein grüner Flutter-Unit-Test gilt **nicht** als Nachweis für ein lauffähiges Android-Kart. Eine Grafikvorschau gilt **nicht** als tatsächlich gestartetes Spiel. Den neuen Godot-Pin erst nach erfolgreichen Flutter-/APK-/Emulatorprüfungen übernehmen; bis dahin Draft-PR und keine Übernahme in `main`.

## Gefahren und Bestandsschutz

Die vorausgehende Godot-Buildprüfung meldete funktionierenden Android-Appstart, aber beim direkten Kart-Deep-Link einen `adb logcat`-Fehler 255 ohne stderr. PR #76 enthält jetzt eine gezielte, höchstens dreimalige Wiederholung nur für diesen konkreten Transportfall und Regressionstests. Native Abstürze, Scriptfehler und dauerhaft gescheiterte Logcat-Erfassung bleiben harte Testfehler. Separate offene Features und Artwork-PRs werden nicht pauschal übernommen; ihr tatsächlicher Inhalt muss vor Integration einzeln geprüft werden.
