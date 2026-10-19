# Lumo Lernen und Kart – Meilensteinplan (19. Oktober 2026)

## Gesicherter Release-Status

- Android-Test-APK 1986 (0.12.74): veröffentlicht, bislang letzte grüne Gesamtabnahme.
- PR #380, APK 1987: hochwertiges Denkprofil, grafische Aufgaben und längerer Knobeltest. Es gibt echte Flutter-Vorher-Nachher-Screenshots; volle Android- und Regressionstests stehen noch aus.
- PR #381 (auf #380 aufgebaut): fairerer Lumo-Cards-Bot, Bauwelt vorläufig als In Entwicklung, detaillierte Play-Store-Sicherheitsprüfung. Diese Änderungen sind noch in keinem bestätigten Release enthalten.

## Stand nach Funktionsgruppen

| Bereich | Nachgewiesener Ist-Stand | Zu tun |
| --- | --- | --- |
| Haupt-Lern-App | Flutter-Kern für 1.–4. Schulstufe, lokale Lernstände, Journal, Schreibtrainer vorhanden | Alle Fachmodule einheitlich gestalten und testen; Bestand schützen |
| Denkprofil | 50 Fragen, fünf Bereiche, Premium-Start und neue Formen-/Zahlen-/Rotationsgrafik in PR #380 | Schwierigkeitskurven, Aufgabenvielfalt und Querformat abnehmen |
| Knobeltest | Sechs Bereiche mit bisher 24 Fragen und optionaler 36er-Entdeckerrunde | Eindeutige Lösungen, Adaptive-Logik und Vergleichsscreenshots überprüfen |
| Geschichten | Original-Lumo, aber einige szenische Umgebungen noch einfache geometrische Darstellungen | Für echte Geschichten spezifische Szenen und mehrere Lumo-Posen illustrieren |
| Vier Gewinnt | Bestehende Interaktions- und Engine-Tests | Behalten; auf Fold vollständig durchspielen und nachpolieren |
| Lumo Cards | Funktionierendes Regelwerk und echter Bot, Fairplay-Verbesserung PR #381 | Spielerisch testen, 2.–4. Klasse, abwechslungsreiche legale Züge, keine Ergebnismanipulation |
| Bauwelt | Visuell und animativ laut Gerätetest noch am Anfang | Im Katalog als In Entwicklung zeigen; nicht als fertiges Spiel bewerben |
| Lumo Kart Rennspiel | Godot eingebunden; Sonnenhafen und Fahrmechanik vorhanden | Grafik, Animation, Original-Lumo, echte Runde und reale Bildrate prüfen |
| Play Store | APK-Kanal, kein bestätigtes produktives AAB und keine Play-Console-Abnahme | Paketname, Produkt-Upload-Signatur, Bundle, Datenschutz, Families, 16KB, Testerphase |

## Reihenfolge und messbare Meilensteine

1. P0: Fehler in PR #380 beseitigen, vollständige Tests und Android-Emulatortour.
2. P0: Karten-Gegner und Bauwelt-Vorschau aus PR #381 testen, ohne Kinderdaten zu verändern.
3. P1: Mit echten Vorher-/Nachher-Screenshots alle relevanten Schul-App-Oberflächen angleichen.
4. P1: Lumo Kart inklusive 3D-Grafik, zwei vollständigen Rennen, Steuerung und FPS gesondert abnehmen.
5. P0 Play: Eigenständiges produktives App Bundle, API 36, Play-Package, Uploadsignatur, Buildgrößen- und 16-KB-Kompatibilität; Play-Release ohne Selbstinstallationsberechtigung.
6. P0 Familie: Öffentlich erreichbare zutreffende Datenschutzerklärung, Data Safety, SDK-/Netzprüfung, Kinderzielgruppe, Google-Play-Listung und geschlossener Test.

## Qualitätsregeln

Design-Fortschritt zählt nur mit echten Vorher-/Nachher-PNGs, unveränderlichen Git-Revisionsangaben und Sichtabnahme. Code-Fortschritt zählt mit bestandenen Regressionen, Freigabe eines Builds nur nach Android-Test und exaktem herunterladbarem Release-Asset. Play-Store-Freigabe darf erst behauptet werden, wenn tatsächliches produktives AAB, Play-Console-Eintrag, Familienrichtlinien und Kontoauflagen bestätigt sind.

Stand: Quellcodeaudit und GitHub-Status; kein Screenshot aus einer noch nicht gebauten APK. Work-Modus kann längere interaktive Play-Console- und Designproduktionen erleichtern; normale GitHub-Änderungen sind auch hier möglich.
