# Lumo: aktuelle Arbeitsanweisungen für Copilot

**Vorrang ab 4. Oktober 2026:** Zuerst `docs/DESIGN_ZIEL_2026-10-04.md` lesen. Heinz will, dass die komplette App genau wie die elf Bilder in `docs/design_targets/2026-10-04/` aussieht. Die Bilder liegen jetzt als Dateien im Repo. Etappen, Abnahmepunkte und Regeln stehen in diesem Dokument. Claude koordiniert und prüft jede Etappe.

Vor Änderungen `docs/COPILOT_GRAFIK_2026-10-04.md` und `CODEX_START.md` lesen. Der aktuelle Auftrag ist die echte Kart-/App-Grafik nach zwölf vorhandenen Originalbildern, nicht die Wiederaufnahme alter April-/Juni-Prototypen oder nur eine weitere QA-Helferrunde.

Flutter-Ausgangspunkt: aktueller Head von `codex/lumo-unified-android-2026-10-03`, PR #156. Kart-/Grafikquelle: `Ullmann27/lumo-godot`, `codex/lumo-holographic-kart-2026-10-03`, PR #4; zuletzt geprüfter Commit `08f3f3f60eb9712c7823faceec2350293d292ce5`. Der separate Flutter-Zweig `codex/lumo-holographic-2026-10-03` enthielt beim Vergleich nur einen neueren Godot-Pin und lag bei der Android-Integration 47 Commits zurück. Nicht blind auf diesen Stand zurücksetzen. Frische Heads vergleichen und passende neue Arbeitszweige verwenden.

Die vollständige Übergabe ordnet alle zwölf Bildnamen konkreten Ansichten zu. Die PNG-Originale wurden in ChatGPT angesehen, konnten aber nicht als Rohdateien nach GitHub übertragen werden. ChatGPT-Library-IDs oder dieser Text ersetzen keine Bildanhänge. Fehlenden Bildzugang einmal klar benennen; keine exakte Bildgleichheit ohne Sicht auf Originale behaupten. Die vier älteren Bilder in `docs/design_references/` sind nicht die neue Zwölferserie.

Visuelles Ziel: orange/cremefarbener ausdrucksstarker Lumo, navy/weißes Outfit, blau-weiße detaillierte Karts, dunkelblaue/Cyan/weiße Glasoberflächen, räumlich dichte eigene Hafen-/Wald-/Schnee-/Holo-Welten. Kein orangefarbenes Grundtheme, keine flachen Platzhalter als Endzustand, kein Coverbild als Ersatz für echtes Gameplay. Referenznamen von Figuren/Fahrzeugen über migrationssichere Zuordnungen umsetzen.

Zuerst einen echten verbesserten Ablauf liefern: Spiele → Kartmenü → Garage/Fahrer → Sonnenhafen-Rennen → Ergebnis → Rückkehr. Echte Vorher-/Nachher-Aufnahmen, gleiche Vergleichsansichten, Codeänderungen und Regressionstests beilegen. Danach das visuelle System auf die übrigen Ansichten übertragen.

Bestehende Lernmodule, freie Kartfahrt, Speicherstände, idempotente Belohnungen, PIN-freie Navigation und die gemeinsame Flutter-/Godot-APK erhalten. Startfehler nur nach Reproduktion/Logs diagnostizieren; die frühere Prozess-Lock-Erklärung ist eine unbewiesene Hypothese. Keine unbelegten KI-, APK-, Android- oder FPS-Erfolge. Keine Schlüssel-/Abrechnungsänderung, kein Force-Push, automatischer Merge oder Release.

Build-Einstieg: `bash scripts/build_unified_apk.sh`; dokumentierte Engine-Versionen Flutter 3.44.9 / Godot 4.6.3 vor dem Bau mit der aktuellen Konfiguration abgleichen. Godot-Prüfung: `GODOT_BIN=/pfad/zu/godot bash tools/validate_project.sh`. Ein installiertes und geprüftes SDK verwenden oder die konkrete fehlende Voraussetzung nennen. Tests der vergangenen Sitzung sind keine neu ausgeführten Tests. Berichte und Nutzerkommunikation auf Deutsch.
