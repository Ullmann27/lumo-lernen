# Lumo Android 1904 · aktuelle Entwicklungsiteration

Basis-App: 3e1d0eb3c08cb2472b12f08eeae11bb663af62c0, integriert mit Godot 18238d48f96b76c4175b705a9bf05e82e339bdd0. Neue Änderungen liegen auf `codex/lumo-visual-fidelity-2026-10-08`; Basis-PRs 216/29 bleiben erhalten. Aktueller eingebetteter Godot-Pin: `7ded3f51cffc265e790d4f1a4c2e91e6d38407eb`. Version 0.12.2+1904.

Die neue APK übernimmt den tatsächlichen Touch-Scrollfix für die native Pause sowie neue Lumo-Farben/feinere Fellsträhnen, braune Iris, saubere Schwanzspitze, kompakte Hecköffnungen, Cyanfelgen/Leuchten, Hauben-L und Küstengelände-Materialkörnung. Die hohe separate Comet-Heckflügelgeometrie entfällt gemäß Kartreferenz. Keine Änderungen an Konten, Profilen, echten Wallets, Lernlogik oder bestehenden Spielständen.

## Beobachtete1903-Fehler und eng begrenzte Korrekturen

Original Actions37817947080 bleibt mit zwei tatsächlichen Kartfehlern dokumentiert: API 35 (`adb get-serialno`: rc1/device offline zwischen den Proben), API 36 (vier dokumentierte Swipes im Pausemodal ohne Scrollfortschritt). Die vier anderen Android-Spielprüfungen und die allgemeine Kartprüfung auf beiden APIs bestanden; das ist keine erfolgreiche Vollrennen-Abnahme.

Der neue Handoff-Check verifiziert zunächst die vorherige erfolgreiche Probenidentität einschließlich exakt gleicher APK, App-/Godot-SHAs, API und Root-/Boot-Beleg. Nur der exakt aufgezeichnete rc1/offline-Fehler darf mit dem einen bereits bekannten Emulator und keinem weiteren Gerät zu einer einzigen `reconnect offline`-Anfrage führen. Anschließend müssen die echte gleiche Seriennummer, Gerätebereitschaft, UID0, Boot1, API und eindeutige Geräteinventur stimmen. Keine Wiederholung bei anderen Fehlern, kein Neustart, keine Neuinstallation und kein Schreiben von Appdaten. Sämtliche Versuchsausgaben bleiben im Beleg erhalten. Die Spiel-/Renn-/Wallet-/ACK-Prüfungen laufen unverändert weiter.

## Verifikation

Lokal: 282 Android-Prüfwerkzeugtests (darunter acht neue Handoff-Tests), 29 Vorbereitungstests, 22 Backendtests bestanden. Native Geometrie/Farben/LOD, neun Kartdetails mit höchstens 61 Materialflächen, 11700 Lenkradkontaktmessungen mit 0,2777mm Maximalabweichung, Armverbindungen, echter Touch-Scroll-/Tap-Ablauf, Fold-/Pause-/Countdown-Layout, vollständige Kartkamera in neun Fällen und nativer 16-Tore-Ablauf mit genau einer Belohnung bestanden.

Der Build-Workflow ist für diesen Branch aktiviert, baut das exakte Commit mit dem deklarierten Godot-Pin, prüft die ganze Flutter-App und liefert tatsächliche App-/Godot-Aufnahmen. API 35/36 müssen die komplette offline gefahrene Zwei-Runden-Fahrt mit Checkpoints, gespeicherter Pause, Fold-Oberflächenwechseln, Hostereignis, Walletänderung, ACK und deduplizierter Ergebniswiederholung erneut bestehen. STATUS BEIM COMMIT: diese neue CI/Android-Abnahme ist noch ausständig; Belege der späteren Actions-Läufe prüfen.

## Weiterarbeiten

Zuerst einen tatsächlich roten Check beheben. Alle fünf nativen Spiele, Profil-/Wallet-/Update-Erhalt und die aktuelle Lern-App bewahren. Danach weitere Fahrzeug-/Gesichts-/Wangen-/Fell-/Streckengeometrie anhand der zehn Originalreferenzen verbessern; echte Laufzeitbilder und Fahrclips vergleichen. Die prozedurale Figur bleibt visuell noch von der Produktionsreferenz abweichend. Kein fertiges referenzidentisches Rig, physischer Samsung/Fold-Hinge-Test oder 60-FPS-Nachweis liegt vor. Kein Merge nach main und kein Release ohne Heinz.

Der erste native CI-Lauf37828516691 bestand die Touch-/Scroll-Aussagen, meldete beim sofortigen Beenden aber zwei noch vom Audiomixer gehaltene Ogg-Ressourcen. Die Testbereinigung wartet nun0,6Sekunden nach dem Szenenausstieg auf den Audiothread; zwei strikte Wiederholungen ohne Leaks bestanden. Der Fehlerfilter bleibt vollständig aktiviert. Die neuen Scrollbilder und -protokolle werden auch im Stage2-Artefakt gesichert.
