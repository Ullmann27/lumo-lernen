# Lumo AppEdit – Vollintegrationsaudit und APK 1958 (16.10.2026)

**Basis:** Opus-Branch `fe6d543fc75071a30a09747e94abf1391f0fdb7f`; **Integrationsbranch:** `chatgpt/lumo-1958-visual-story-integration-2026-10-16`; **Godot-Pin** bleibt der zuvor auf Android getestete 3D-Rennstand `b5f19890f81971a72b703b4718aac4607999521c`. Dies ist kein Beleg, dass der strengere Flutter→Kart→Rennen-End-to-End-Test bereits erfolgreich wäre.

## Reale Integration in Build 1958

- **Story-Werkstatt**: vollständige kompatible Änderung aus [PR #306](https://github.com/Ullmann27/lumo-lernen/pull/306) übernommen. Wählbare Begleiter (Lumo, Sternenroboter, Eule, Delfin), Zaubergegenstände sowie sechs tatsächlich verschiedene Handlungsbögen. Rotierende Szenarios pro Kinderprofil/Klasse durch `ReadingStoryMemoryRepository`. Zwei neue Auswahlzeilen sind im echten Story-Setup verdrahtet. Story-Library-Header war in neuerer App schon enthalten und bleibt unberührt. Übernommen: `lib/core/lumo_story_generator.dart`, `lib/features/story/lumo_story_setup_screen.dart`, zwei Story-Regressionstests.
- **Opus M0 erhalten**: Gradle-Maven-Central-Mirror inklusive der verschärften Rennstart-, Fahrt-, Pause-, Fortschritt- und Rückkehr-Proben bleibt vollständig erhalten. `ripgrep` wird in der CI installiert, weil drei zuvor fehlgeschlagene Skripttests realen `rg` voraussetzen. Keine Testkriterien abgesenkt.
- **APK-Kandidat**: Versionsnummer auf `0.12.50+1958` erhöht. Flutter- und Godot-Quellpins werden im CI-Artefakt ausgewiesen; Android-ARM64-APK wird erst nach bestandenem Build als APK ausgeliefert.

## Fertige Grafikarbeiten, die im aktuellen Kandidaten bereits angeschlossen sind – KEIN Doppelimport

| Paket | Ergebnis der Git-Vergleiche |
|---|---|
| Neun echte 3D-Lerninseln und Premium-Quizbühne | Beide Entwicklungsbranches enthalten **0 Commits vor** dem Opus-Stamm: bereits integriert; Widget-Tests vorhanden. |
| Hologlas-Übungsfortschritt, reale Speichersicherung | `lib/features/learning/cross_grade_practice_screen.dart` und `widgets/cross_grade_visual_scene.dart` im Opus-Stand **identisch** zu PR #320 (inklusive Fortschritts-Widget). |
| Original-Lumo-Bildersammlung | Sämtliche 177 Lumo-Design-Assets aus `claude/design-tafeln` bereits im Opus-Stamm; letzterer enthält 238 Dateien unter `assets/lumo_design/`. Keine Binär-Dubletten importieren. |
| Grafik in Kart | Asphalt-PBR (#74), Wasser/Sonnenhafen (#72), filmische Umgebung (#71), Fold-Weltvorschau (#70), Bauwelt/Leitplanken (#69), Sonnenhafen-3D-Türme (#76/#77) in der Vorgeschichte des fest gepinnten Godot-Quellstands. |
| Lernhelfer-Hologlas, Fold-Journal, Story-Leser, Touch-/Stimmenavigation | Entsprechende Zweige sind Vorfahren des Opus-Stamms. Bestehende Kernmodule und UI ausdrücklich nicht überschreiben. |

## Weitere abweichende Entwicklungsarbeiten: nur neue, funktional zusätzliche Änderungen werden übernommen

- **Lumo-Meister Safe-Area (#305)**: Quiz-Quellcode hat sich auf neuerer Premium-Bühne substanziell verändert. Die drei Original-Patchhunks treffen dort nicht mehr zu. **Kein Blindimport**, weil dieser die bereits integrierte Quizbühne überschreiben könnte. Bestehende Layouttests beibehalten; visuellen Android-Befund als Integrationskriterium nutzen.
- **Eltern-Schulstufenwechsel (#313), Familien-Updates (#298), lokale Lernhilfe (#297), Agent-Hologlas (#294)**: Teile sind bereits identisch in der aktuellen Implementierung. Nur *fehlende, isolierbare Funktionen* als neue Änderungen integrieren; bisherige Integrationen und Datenmigration erhalten.
- **NVIDIA-Tutorpilot (#310)**: Nur experimenteller consent-gated Code; ohne elterliche Freigabe, Zugang/Datenschutz und verifizierte Laufzeit nicht im Kinderinterface automatisch aktivieren.
- **Sky-Halo-Looping**: echte 3D-Authoring-Geometrie, aber nicht mit befahrbarer Kollision/Physik/KI verbunden. Erst als vollständiges spielbares Feature integrieren.
- **AAA/60 FPS und physisches Galaxy Fold 7**: Ziel und Messaufgaben, keine verifizierte Zusage.
- **Autonomer Softwareagent**: Rollendefinitionen vorhanden, eine zuverlässig autonom ausführende PR-Pipeline ist damit noch nicht belegt.

## Maßgebliche Abnahme

1. `flutter analyze`, vollständiger Flutter-Testlauf, Python-Android-QA sowie `scripts/tests` alle erfolgreich.
2. ARM64- und x86_64-APKs aus derselben exakten Commitrevision bauen; eingebetteten Godot-Pin, Signatur und SHA-256 prüfen.
3. Android-Emulator: Profil, Lernen, Spiele, Kart-Garage, **echtes Rennen**, Gas und Weltbewegung, Pause, Rückkehr, Lerndatenerhalt und Neustart. Screenshots, echte Sitzungswerte und Logs nachweisen.
4. PR-/GitHub-Integrationsstatus als **vorläufig** ausweisen, solange einer dieser Tests fehlschlägt. Kein unfundiertes "alles fertig".

Zentrale Übersicht: [Issue #329](https://github.com/Ullmann27/lumo-lernen/issues/329).
