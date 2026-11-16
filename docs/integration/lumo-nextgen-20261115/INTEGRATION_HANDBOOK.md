# LUMO NextGen 2026-11-15 · Integrationsleitstand Chat 1

**Status: QUELLCHECKPOINT.** Keine vollständige Lernabdeckung, kein geprüfter Android-Build oder Fold7-FPS-Nachweis. Bestehende Kart-/Dschungelarbeit bleibt unverändert.

## Exakte Ausgangsquelle
- Flutter: \`Ullmann27/lumo-lernen\`, Start \`delivery/lumo-2023-complete-update-20261115\` bei \`6f4a8c4753f4d06d0b392da0789b8162b2faa71b\` (0.13.11+2023).
- Godot: \`Ullmann27/lumo-godot\` mit gepinnter Revision \`d38967f6d39bc20188afe525b0af122d80634029\` (4.6.3).
- Neu: \`PROTOCOL_V1.md\` – versionierter zusätzlicher Nachrichtenvertrag; \`COVERAGE_BASELINE.json\` – Quellinventar. Diese zwei Dokumente ändern weder bestehende persistente Daten noch Bewertungslogik.

## Vier getrennte Arbeitszweige / keine automatische Chatzusammenarbeit

| Team | Repository / Zweig | Schreibzuständigkeit | Nachweis |
|---|---|---|---|
| Chat 1 – Integration | \`lumo-lernen:integration/lumo-learning-nextgen-20261115\` | \`docs/integration/lumo-nextgen-20261115/**\`, \`tools/learning_nextgen/**\`, vereinbarte Host-Routing-/APK-Akzeptanz | Dieser Branch |
| Chat 2 – Inhalt/Didaktik | \`lumo-lernen:feature/lumo-nextgen-learning-tasks-20261115\` | \`lib/features/learning/**\`, \`lib/features/learning_modules/**\`, \`lib/domain/learning/**\`, bestehende Aufgaben-/Lernmodule/Renderer; eigene Tests | \`CHAT2_TASKS_HANDOFF.md\` auf Teamzweig |
| Chat 3 – Fuchs/3D | \`lumo-godot:feature/lumo-nextgen-fox-20261115\` | \`scripts/characters/lumo/**\`, \`scenes/characters/lumo/**\`, \`scripts/learning/**\`, \`scenes/learning/**\`, \`assets/learning_nextgen/**\`; Godot-/Blender-Proofs | \`CHAT3_FOX_HANDOFF.md\` auf Teamzweig |
| Chat 4 – Sprache/Gespräch | \`lumo-lernen:feature/lumo-nextgen-voice-20261115\` | \`lib/core/lumo_conversation_controller.dart\`, \`lumo_voice.dart\`, \`lumo_speech_listener.dart\`, dedizierte Voice-Host-Methoden/Tests | \`CHAT4_VOICE_HANDOFF.md\` auf Teamzweig |

Konflikte: Gemeinsame \`learning_content.dart\`-Aufgaben dürfen nur Chat 2 verändern; Chat 1 verbindet nach kontrolliertem Merge-Review über klar getrennte Host-Adapter. Godot \`learning_world.gd\` gehört Chat 3. Chat 4 liefert bei nativer Sprachmethodenerweiterung ein kleines abgegrenztes Patch, das Chat 1 gezielt integriert, nicht eigenmächtig dort überschreibt. Produkt-Android- und Build-Dateien gehören Chat 1; Chat 4 liefert kompatible JNI-/TTS-Methodenvorschläge plus Tests. Alle Änderungen am v1-Vertrag sind additive, dokumentierte Änderungen auf Chat 1.

## Tatsächliche Quellenabdeckung (kein End-to-End-Nachweis)
- **36** akademische Topic-IDs aus \`TopicCurriculum._data\`, davon **20** direkte Registry-Zuordnungen; einige Themen verwenden statt eigener Module vorhandene Schreibtrainer-/Story-/Generatorpfade. Akzeptanz nur wenn alle Einstiege real per Touch geprüft sind.
- **5** Lernatelier-Themen (Zehnerbrücke, Silben, Englisch, Pflanzen, Brüche), mit grade-spezifischer Freischaltung.
- **8** Generator-Fachfamilien. \`Curriculum.unitsForGrade(grade,subject,currentGradeOnly:true)\` ist dynamisch; die Anzahl einzelner Einheiten steht erst nach reproduzierbarem Lauf von \`tools/audit_learning_tasks_all_grades.dart\` fest. Bereits vorhandene statische Familien zählen nicht als geprüfte Routen.
- Weitere Spezialpfade: Lesen/Lesebuddy, geführte Lektionen, Schreiben, CrossGrade, Tests/Schularbeiten, Foto-Lernen. Schreibtrainer-/Journal-Interna unverändert.
- Vorhandene native Lern-Aktivitäten: Rechenoperationen, Zehnerübergang, Silben, Pflanzen, Gleichverteilung, Brüche, Englischobjekte. Bereits vorhandener Fuchs und lokaler Audio-Rückkanal **sind nicht** freie In-Godot-Sprachkonversation.

## Frühestmögliche gekoppelte Probe
1. Chat 2 stellt eine geprüfte 8+5 Aufgabe mit festen zehn Zehnerfeldern/Fünfergruppe, zwei sichtbaren Bewegungsobjekten und Hilfe-/Bewertungsgrenzen bereit.
2. Chat 3 integriert genau diese IDs in die bereits existierende Godot-Lernszene und setzt Fuchs-Target plus visuelle Handlung.
3. Chat 4 liefert echte ankommende Kinderrückfrage mit zurückvalidierter Erklärung, gestarteter Stimme, synchronisiertem Fuchsmund und harter \`Stopp\`-Abbruchquittung.
4. Chat 1 überprüft zusammen Version, Besitzer-/Aufgabengeneration, Audio-/Rendering-/Bewertungslogik und Android-Rückweg, danach erst die übrige Inventarliste. Vor diesem Schnittstellenbeweis keine Vollständigkeitsfreigabe.

## Freigabegates
1. \`python3 -m unittest discover -s tools/learning_nextgen -p 'test_*.py'\`, Quellregister-/Protokollvertrag.
2. \`dart run tools/audit_learning_tasks_all_grades.dart\` und separate Spezialmodul-/Lesen-/Schreiben-/Lab-Coverage; jede Klasse/Fach/Unit hat einen erreichten Touch-Einstieg plus Evaluationsfall.
3. \`flutter analyze\`, \`flutter test\` und native Godot-4.6.3-Import/Regression; echte Referenz-Animationen und Asset-Hash-Import.
4. Vollständiger Flutter ↔ Godot ↔ ASR/AI ↔ echter Audio-Playback/Abbruch/Untertitel ↔ Originalfuchs mit richtigen, falschen und verspäteten Antworten, App-Pause, Wechsel/Wiederaufnahme.
5. Android-Emulator, dann physisches Fold7 außen/innen plus normales Smartphone. 60-FPS-Ziel nur bei tatsächlich gemessenen Framezeiten, RAM, Temperatur und Audio-/Animationslast.
6. Eine neue, exakt quellengebundene, signierte ARM64-APK mit unveränderter Paket-/Zertifikatsidentität, nachvollziehbarem SHA256, echter Installation und Erhaltung der alten Profile/Schreib-/Journal-Daten. Keine neue Versionsnummer ohne realen APK-Inhalt, kein Release-/Main-Merge ohne Freigabe.

## Übergabedisziplin
Bei jedem Team: **Repository, Ref, SHA, geänderte Pfade, geprüfte Szenen/IDs, Start-/Endtests, tatsächliche Bilder/Audios, blockierte Pfade**. Unbestätigte Arbeit bleibt \`UNVERIFIED\`. Team-Branches sind ausschließlich Git-Container; ihre Erzeugung startet keine separaten KI-Sessions. Andere Chats müssen den veröffentlichten Link/Branch explizit übernehmen.
