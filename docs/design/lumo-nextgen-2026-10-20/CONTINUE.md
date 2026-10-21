# Fortsetzung nach der Cloud-Rettung

Zuerst den neuesten `checkpoint/lumo-cloud-...`-Branch und dessen Remote-SHA
prüfen. Die ursprünglichen elf Dateien sind im
[eindeutigen Dateiinventar](evidence/cloud-rescue-2026-10-21/original-manifest.json)
erfasst. Nicht vom älteren Designbrief oder Main neu beginnen.

1. Vor jeder Aktualisierung `git status --short --branch` prüfen und lokale
   Änderungen sichern. `AGENTS.md` und das
   [Rettungsprotokoll](../../CLOUD_RECOVERY_PROTOCOL_2026-10-20.md) beachten.
2. `python3 tools/lumo_autosave.py check` ausführen. Den Watcher je aktivem
   Workspace einmal starten: `python3 -u tools/lumo_autosave.py watch --interval 120`.
   Ein suspendierter Workspace führt ihn nicht garantiert weiter aus.
   Nach Arbeitspaketen und vor langen Tests zusätzlich `once` ausführen;
   Push-Erfolg mit Remote-SHA bestätigen.
3. PR #393 und den aktuellen Integrationsstand lesen und mit dem gesicherten
   Code vergleichen. Keine blinde Übernahme: Home-/Material-/Atmosphäre-Code
   aus dieser Sitzung und der zweite Lernversuch müssen erhalten bleiben.
4. Vor weiteren Designänderungen die gesicherten PNGs unter
   `evidence/cloud-rescue-2026-10-21/lumo-second-render/` tatsächlich ansehen
   und mit den jetzt im Chat verfügbaren Originalreferenzen vergleichen.
5. Kategorie 1 weiter prüfen: Ohren, Textfaktor 2, Fold, kleine Breiten,
   Touchziele, Navigation, gemeinsame Materialien und reduzierte Bewegung.
   Noch keine visuelle Abnahme, Android-Messung oder 60-FPS-Zusage.
6. Relevante Home-/Navigation-/Wallet-/Zweitversuch-Regressionen und Analyse
   ausführen. Bei #392 waren ein kompakter Kachel-Overflow und drei
   Cross-Grade-Tests rot; kompakte Kacheln bestehen im erhaltenen zweiten
   Lauf. Die Cross-Grade-Tests berücksichtigen den zweiten Lernversuch
   möglicherweise noch nicht; zuerst untersuchen, keine Lernlogik entfernen.
7. Echte neue Render, Tests, Abweichungen und nächsten Schritt dokumentieren,
   committen und pushen. Kategorie 2 erst nach dem Qualitätsgate für Home.

Der Rettungscheckpoint ist ein vollständiger Zwischenstand, keine Freigabe.
