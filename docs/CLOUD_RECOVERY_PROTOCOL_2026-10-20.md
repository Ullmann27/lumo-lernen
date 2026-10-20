# Astra/Codex Cloud: rettbarer Arbeitsstand statt isolierter Scratch-Dateien

**Datum:** 20.10.2026 · **Anlass:** Astra Sehr hoch endete bei Lumo NEXT GEN während einer Flutter-Render- und Testiteration; laut Screenshot lief die Arbeit noch in \`/workspace/lumo-lernen\`, mit Dateien unter \`/workspace/scratch\`. Der letzte Remote-Task wurde als fehlgeschlagen markiert. Screenshots von Befehlen sind **kein Nachweis** für publizierte Commits.

## Konkrete Wiederaufnahme der unterbrochenen Sitzung (PRIORITÄT 1)
Wenn **dieselbe** Code-/Cloud-Aufgabe noch geöffnet werden kann, NICHT zuerst \`git pull\`, \`git reset --hard\`, \`git clean -fd\` oder einen neuen Branch auschecken. Zuerst:
\`\`\`bash
cd /workspace/lumo-lernen
git status --short --branch
git diff --stat
git diff --check
find /workspace/scratch -maxdepth 3 -type f \( -name 'lumo-*-render.log' -o -name '*.png' \) -print | head -40
\`\`\`
Bekannte aus Benutzerscreenshots sichtbare Arbeitsdateien:
- \`lumo_home_hero.dart\`: Startbildschirm, Platz des gesamten Lumo-Fuchses, Breiten-/Skalierungstests
- \`lumo_materials.dart\`: Premium-Materialien
- \`lumo_design_system.dart\`: gemeinsamer grafischer Baustoff
- \`lumo_scene_atmosphere.dart\`: visuelle Atmosphäre
- \`cross_grade_practice_screen.dart\`: vorhandene Lernnavigation, nicht blind umarbeiten
- Testlauf \`LUMO_NEXTGEN_CAPTURES=/workspace/scratch/lumo-second-render/ /workspace/flutter/bin/flutter test --no-pub --reporter expanded test/home_hero_accessibility_test.dart test/nextgen_premium_tiles_test.dart test/lumo_scene_atmosphere_test.dart test/design/home_nextgen_capture_test.dart\`

WENN die Änderungen wirklich im Workspace vorhanden sind: **sichere sie vor jeder Reparatur**. Nutze auf dieser Sitzung zuerst einen eigenen \`checkpoint/lumo-cloud-...\`-Branch und \`python3 tools/lumo_autosave.py once\` (Skript muss in diesem Checkout tatsächlich vorliegen). Bei Schreibproblemen \`git diff > <sicherer Pfad>\` und die nicht gestagten Assets separat sichern, dann eine überprüfbare PR-/ZIP-Übergabe erstellen. Push-Rückmeldung mit SHA ist zwingend.

## Bereits über GitHub fortgesetzter Zustand
- PR #389: Premium Navigation/Home/LIVE/Mirror/Cosmos/Quest
- PR #390: pädagogisch erhaltener zweiter Lernversuch
- PR #392: tatsächliche Premium-Lernkacheln
- PR #393: weitere gezielte Reparaturen und erfolgreicher Flutter-Testlauf; zur Laufzeit separate verifizierte Android-1992-APK
- Kein Nachweis, dass der um ca. 20:49 Uhr per Screenshot sichtbare Cloud-Hero-/Materials-/Atmosphere-Patch im Code von PR #393 gelandet ist.

Historisch hat ChatGPT Lumo über **GitHub-PRs/Commits, Worktrees, geordnete Patch-Übernahmen und CI-Artefakte** fortgesetzt. Es gab keinen verifizierten Trick, fremde nicht gepushte Cloud-Dateien einfach über den GitHub-Connector auszulesen. Die neue Sicherung soll genau diesen Fehler künftig seltener machen.

## Ausführbarer Schutz für zukünftige Cloud-Codeaufgaben
Eine neue Session muss den Code dieses PRs kennen bzw. in ihrem echten Checkout besitzen. Erste Aktion: \`python3 tools/lumo_autosave.py check\`.

Auf einem regulären Entwicklungsbranch wird alle ~120 Sekunden ein Snapshot versucht:
\`\`\`bash
nohup python3 -u tools/lumo_autosave.py watch --interval 120 > /tmp/lumo-autosave.log 2>&1 < /dev/null &
\`\`\`
Wichtig: Das ist ein Prozess der jeweiligen Cloud-Maschine. Wird die Instanz angehalten, gekündigt oder beendet, gibt es **keine Dauerlaufgarantie**. Deshalb **nach jedem kleinen Arbeitsabschnitt**, vor langer Test-/Screenshot-Schleife und vor Nutzungslimit zusätzlich:
\`\`\`bash
python3 tools/lumo_autosave.py once
git log -1 --format='%h %s'
git branch --show-current
\`\`\`
\`[LUMO-CHECKPOINT] REMOTE SAVED\` ist der benötigte Beleg. \`LOCAL SAVED\` ohne \`REMOTE SAVED\` ist für andere Sessions weiterhin unerreichbar.

Ausgeschlossen werden geheimer Schlüsselinhalt, Key-/Credential-Dateien, bekannte Tokenmuster, Symlinks, unbekannte Dateitypen und Dateien über 16 MiB. Ein Artefakt, das zu Recht nicht automatisch veröffentlicht werden darf, muss separat und kontrolliert gesichert werden. Bei Staging-Konflikten (Astra hat selbst schon \`git add\` ausgeführt) muss sie zuerst den gestagten Patch nachvollziehbar committen.

## Nach dem Rettungs-Push
1. Eigenen PR von dem gesicherten Checkpoint-Branch eröffnen.
2. Gegen den aktuellen Flutter-Branch von PR #393 vergleichen, ohne den bildlich hochwertigeren Stand zu verlieren.
3. Reale Flutter-Fuchs-/UI-Screens auf 393/840dp und Fold erzeugen.
4. Erst wenn Analyse, relevante Tests, Asset-Inklusion, echte UI-Screens und Android-Build passen, neue APK bereitstellen.
5. Vor Arbeiten an Lumo Kart Godot-Branch/Pin separat prüfen. Keine PR-Ketten blind zusammenführen.

Diese Datei garantiert kein Wiederherstellen eines bereits zerstörten Cloud-Workspaces; sie dokumentiert einen sofort durchführbaren Rettungsweg und einen überprüfbaren Schutz für folgende Sessions.
