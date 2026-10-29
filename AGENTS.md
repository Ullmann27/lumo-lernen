# AGENTS.md – Lumo Lernen · Cloud-Checkpoint-Pflicht

## Aktuelle Wiederaufnahme: Living Intelligence (29.10.2026)

**Vor neuen Änderungen zuerst [CONTINUE.md](CONTINUE.md) und die
[vollständige Übergabe](docs/audit/2026-10-29/HANDOFF.md) lesen.**
Der Handoff-Zweig `docs/lumo-living-intelligence-verification-20261029`
enthält den kompletten 2002-Kandidaten, die geprüfte Tutor-Implementierung,
echte CI-Bilder und Nachweise. Nichts davon neu erfinden oder durch ältere
Checkouts ersetzen. Die fachlichen Quellstände von PR #414 und #415 sind
absichtlich eingefroren; laufende Android-Gates nicht durch Dokumentations-
Commits abbrechen. Zuerst deren tatsächlichen aktuellen GitHub-Status prüfen.

Letzte Nutzersteuerung: verbleibende Arbeit abschließen, sofort committen/pushen
und eine in zwei Wochen nutzbare Übergabe mit Regeln, offenen Punkten und den
nächsten Schritten sichern. Neue große Funktionsblöcke wurden deshalb gestoppt.
Die ursprüngliche Mission bleibt in der Übergabe dokumentiert. Keine neue
APK-Freigabe behaupten, bevor echte Android-/Update-/Veröffentlichungsgates
bestanden sind. Bestehende Regeln darunter gelten weiterhin.

**Geltung:** Alle KI-/Codex-/Astra-/Claude-/Sol-Coding-Aufgaben in diesem Repository.
**Zweck:** Keine unerreichbaren, ausschließlich im Cloud-Workspace liegenden Implementierungen mehr.
**Stand:** 2026-10-20. Aktuelle Arbeitsaufträge/PR-Ketten weiterhin vor Änderungen prüfen.

## Verbindliche Auslieferungsregel: Android-APK direkt für Google Chrome

**Ausdrücklicher dauerhafter Auftrag des Projektinhabers vom 22.10.2026.**
Wenn ein Entwickler oder KI-Modell Änderungen an Lumo Lernen/Lumo Kart erhält, gehören **ohne gesonderte Nutzer-Nachfrage** die vollständigen Schritte zur Lieferung: Quellcode integrieren, relevante Tests korrigieren/ausführen, vollständige signierte ARM64-Test-APK bauen, APK-Provenienz und -SHA-256 prüfen, echte Android-Emulator-Tour durchlaufen und **eine unveränderliche neue .apk per öffentlich erreichbarem direkten HTTPS-Link** bereitstellen. Ausnahmen/Blockaden unverzüglich exakt dokumentieren; nie eine alte APK als neuen Stand ausgeben oder bestandene Tests vortäuschen.

**Auslieferung ausschließlich für den Anwender per Chrome:** Bevorzugter Download ist ein öffentliches GitHub-Release-Asset `https://github.com/Ullmann27/lumo-lernen/releases/download/<version-tag>/<dateiname>.apk`, ausdrücklich eine einzelne `.apk` ohne ZIP, GitHub-Actions-Anmeldung, ChatGPT-Sandbox oder Python-Interpreter. Vor Link-Ausgabe prüfen, dass Release, Asset und Datei-Größe tatsächlich existieren. Die Version muss inkrementiert sein; ältere Releases unverändert lassen. Versionsname, versionCode, Commit, Godot-Revision, Signaturfingerprint und SHA-256 mitliefern. Keine unbestätigte öffentlich erreichbare URL erfinden.

**Keine halbfertige Entwicklerantwort als Abschluss:** Die Beschreibung „wir brauchen noch einen Build“ ersetzt nicht den automatischen Buildversuch. Arbeite weiter bis zur verifizierten APK und zum direkten Link, sofern technisch/zeitlich verfügbar; wenn ein Systemlimit die Ausführung stoppt, hinterlasse einen gepushten reproduzierbaren Wiederaufnahmezustand. Keine Kostenauslösung ohne Freigabe. Installierte Kinderprofile und Daten erhalten; Debug/Preview-Signaturen niemals mit Play-Produktionssignierung verwechseln.

## ZUERST: Zugang und Wiederaufnahme (vor umfangreicher Entwicklung)
1. \`git status --short --branch\`, \`git branch --show-current\`, \`git log -1 --oneline\`, \`git remote -v\` prüfen. Bevor eine ältere Checkout-Version aktualisiert oder ein Branch gewechselt wird, ALLE eventuell vorhandenen lokalen Änderungen sichern. **Niemals \`git reset --hard\`, \`git clean -fd\` oder Force-Push als "Reparatur".**
2. Bei fortgesetzten Cloud-Tasks zuerst die aktuell vorhandenen uncommitteten Dateien prüfen (z. B. \`lumo_home_hero.dart\`, \`lumo_materials.dart\`, \`lumo_scene_atmosphere.dart\`, \`lumo_design_system.dart\`). Falls sie noch im Workspace vorhanden sind, sind das priorisierte Rettungsobjekte! Nicht durch altes GitHub-Checkout überschreiben.
3. \`python3 tools/lumo_autosave.py check\` ausführen; bei gefilterten Dateien Auswahl prüfen. Vor dem ersten größeren Arbeitsblock den Cloud-Checkpoint-Wächter starten:
   \`\`\`bash
   nohup python3 -u tools/lumo_autosave.py watch --interval 120 > /tmp/lumo-autosave.log 2>&1 < /dev/null &
   \`\`\`
   Der Watcher ist **Best Effort**; Cloud-Aussetzung kann ihn stoppen. Nicht darauf verlassen.
4. **Nach jedem nützlichen abgeschlossenen Patch und mindestens einmal ungefähr alle 5 Minuten** ausdrücklich \`python3 tools/lumo_autosave.py once\` aufrufen. Das ist eine Ausführungsregel, nicht bloß ein Vorschlag. Bei Push-Fehlern arbeiten nicht einfach fortsetzen, sondern zuerst Schreibzugang oder einen anderen sicher zugänglichen Handoff wiederherstellen.
5. Vor einem langen Test/Flutter-Build, bei drohendem Limit und vor jeder Antwort über "fertig" nochmals \`once\` aufrufen und den tatsächlich gepushten Commit-SHA ausgeben. Läuft ein Test länger, die vorhandene Remote-Sicherung vorher erstellen.

## Grenzen der automatischen Sicherung
- Das Skript darf ausschließlich in \`Ullmann27/lumo-lernen\` oder \`Ullmann27/lumo-godot\` pushen.
- Es wechselt von \`main\`/\`master\`/detached HEAD auf einen neuen \`checkpoint/lumo-cloud-...\`-Branch. Kein Merge nach \`main\`, kein Force-Push.
- Es sichert **nur bekannte Projekt- und Grafikdateitypen**. Geheimnisse, signierte Schlüssel, sensible Konfiguration, große/unbekannte Dateitypen, fremde Verzeichnisse und bereits von Hand gestagte Inhalte dürfen nicht automatisch eingecheckt werden. \`[LUMO-CHECKPOINT]\`-Meldungen genau lesen; wichtige ausgeschlossene Originalgrafiken sicher und geprüft nachtragen.
- Commits heißen ausdrücklich \`checkpoint(...)[skip ci]\`; es sind Zwischenstände und **keine funktionalen/visuellen Qualitätsfreigaben**.
- Automatisches Pushen hängt vom GitHub-Schreibzugang im aktuellen Workspace ab. Ein GitHub-PR kann keine nicht gepushten lokalen Änderungen abrufen.
- Vor einem finalen Draft-PR: neuen Commit ohne \`[skip ci]\` erzeugen, echte Screenshots/Tests veröffentlichen und \`STATUS.md\`/\`CONTINUE.md\` aktualisieren.

## Aktuelle visuelle Produktionspriorität
Die **Lumo-Lern-App** und die vorgegebenen originalen Fuchs-/Lernwelt-/Mathe-/Story-/Quiz-/Eltern-Referenzbilder sind vorrangig. Original-Lumo (orange-weißer Fuchs, blaue Fliegerbrille, dunkelblaue Jacke) bleibt. Bestehende Lernmodule/Schreibtrainer/Journal/Lernstände erhalten. Erst danach das eigenständige Godot-Projekt Lumo Kart weiter gestalten. Keine fremde Figur, keine harte Umstellung auf überholte Oktober-Bases.

## Notfall, wenn die Session nicht mehr erreichbar ist
1. Andere Sitzung: letzten \`checkpoint/lumo-cloud-...\`-Branch in GitHub suchen, Sha prüfen, auf eigenem Rettungszweig fortsetzen.
2. Ursprüngliche Session ist wieder zugänglich: \`git status\`, vorhandene Scratch-Dateien/Änderungen retten, \`python3 tools/lumo_autosave.py once\` ausführen, erst danach bauen.
3. Fehlt jeder Cloud-Commit, ist der genaue lokale Code über GitHub nicht nachweisbar und muss anhand des letzten gesicherten Commits und der Testprotokolle rekonstruiert werden. Niemals eine Cloud-Wiederherstellung erfinden.

Ausführlicher Ablauf: \`docs/CLOUD_RECOVERY_PROTOCOL_2026-10-20.md\`.
