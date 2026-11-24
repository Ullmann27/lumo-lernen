# Direkt weiterarbeiten

Branch `design/lumo-nextgen-home-math-20261021`; neuesten Remote-SHA prüfen.
Basis enthält #395, #396, #397. Nicht auf ältere Home-/Rechentrickstände wechseln.

Home-Code und Render sind gesichert. Nächstes Paket: gemeinsame Antwortkristalle
mit neutralem Ausgangszustand und echte Mathe-Szene, zuerst Zahlen bis 100 und
Cross-Grade-Mathe mit unverändertem zweiten Lernversuch. Generator, Bewertung,
Speicherung und Belohnungswerte bleiben außerhalb der Grafikkomponenten.

Wichtig: Der direkte Zahlen-bis-100-Modus hat in dieser Basis einen bewerteten
Versuch pro Aufgabe; der zweite Versuch existiert im Cross-Grade-Modus.
Keine stillschweigende Änderung dieser vorhandenen Lernlogik.
Rechentrick-Werkstatt aus #397 erhalten und nur passende Hilfe verknüpfen.

Dateien Home: `lumo_home_hero.dart`, `lumo_character_stage.dart`,
`lumo_adventure_card.dart`, `home_content.dart`, `lumo_design_system.dart`.
Belege und Einschränkungen stehen in STATUS.md. Vor langen Tests und zum Ende
`python3 tools/lumo_autosave.py once`, Remote-SHA prüfen. Watcher in diesem
Cloud-Executor als verwaltete laufende Session starten; nohup allein genügte nicht.


## ChatGPT-Übernahme nach Astra-Limit – 21.10.2026

Aktuell separat gesicherter QA-Branch: `repair/lumo-nextgen-math-recovery-20261021`, Draft-PR #398 gegen `design/lumo-nextgen-home-math-20261021`. Er basiert direkt auf dem Astra-Checkpoint `a3f2d6ad0efbd390e6d8178b77be58957a51855d`, der selbst neun Commits nach PR #397 umfasst.

**Zuerst auf GitHub schauen**: Branch-Head und PR #398 vergleichen; wenn Astra in der ursprünglichen Cloud noch ungesicherte Änderungen hat, diese zuerst dort sichern und nicht durch Checkout überschreiben. Keine Änderungen von PR #395–#397 zurücksetzen.

**Nachweisbare Entwicklung von Astra**: Startseite auf neuem Bildschirmsystem, Original-Fuchs, eigenständige CharacterStage, AdventureCard, vergrößerte Icons, Home-/Fold-/Motion-Tests (20 laut Home-Protokoll), neu implementierte KristallPainter-, LumoMathStage- und ZahlenBis100-Anbindung. Diese Mathe-Etappe war noch nicht freigegeben.

**Behobene und abgegrenzte Probleme**: `curly_braces_in_flow_control_structures` im Lernmodulrahmen repariert. Screenshots der ursprünglichen Session nannten `assets/lumo_design/fox/lumo_math_cutout.png`, eine Datei, die im GitHub-Assetordner nicht existiert. In den bereits gesicherten produktiven Mathe-Bausteinen taucht diese Pfadangabe nicht auf; sie kann aus einem lokalen, nicht gepushten Zwischenstand stammen. Die produktive Mathe-Bühne benutzt `fox_book_point.png`, das existiert. Keine Fantasie-Assets hinzugefügt und den ursprünglichen Fehler nicht als lokal reproduziert behauptet.

**Grün:** GitHub Actions `39560082053`: gezielter Mathematik-Analyzer, neutraler Kristallzustand, echte Mathe-Lernmodul-Widgettests auf 360×800 und 320×740 sowie der zuvor gescheiterte `learning_adventure_capture_test.dart` für `zahlen-bis-100 phone-360x800`. Screenshots intern als GitHub-Artifact, nicht ungefragt im Chat. **Großer Android-Integrationslauf:** `39560082039`, Status separat kontrollieren, nicht als grün behaupten, solange noch aktiv.

**Nächste verifizierbare Schritte**: die übrigen Mathe-Aufgabentypen (Vorgänger, Vergleich mit 2 Antworten, Zehner/Einer) an mehreren Bildschirmgrößen prüfen, den Unterschied zwischen dem direkten „Zahlen bis 100“-Einversuch und Cross-Grade-Zweitversuch bewusst erhalten, danach die echte APK bauen. Materialien und Original-Lumo beibehalten. Höhere visuelle Referenztreue nach einem tatsächlichen Renderer-Vergleich, keine pixelgenaue Umsetzung behaupten.

**Sicherung:** Änderungen auf PR #398 direkt zu GitHub gepusht, `main` bleibt unverändert. Bevor längere Tests starten, auf der tatsächlichen Cloud-Maschine den 120-Sekunden-Watcher starten und mit `python3 tools/lumo_autosave.py once` Remote-Push nachweisen. GitHub-Zweig reicht zum Aufgreifen der hier gesicherten Änderungen.
