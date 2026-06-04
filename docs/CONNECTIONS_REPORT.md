# Lumo Lernen — Verbindungs-Inventar

Stand: 2026-06-04

Heinz' Auftrag: „Geh auf die Suche nach Verbindungen wie zb meine KI die noch nicht fertig sind und angeschlossen gehören."

## ✅ Frisch angeschlossen (build-225)

### Lumo KI Chat
- **Was**: `lib/features/agent/lumo_agent_content.dart` (624 Zeilen, voll implementiert) — Voice-Recognition, ChatGPT-Proxy, History, Sicherheits-Filter, lokales Fallback
- **War**: nirgendwo aufrufbar
- **Jetzt**: Bottom-Nav-Mitte mit `auto_awesome`-Sparkle-Icon „Lumo KI". Master-Toggle im Eltern-Bereich (1-Tap-Aktivierung).
- **AI-Server verifiziert**: `lumo-ai-proxy.onrender.com` live + OpenAI konfiguriert + `/chat` antwortet kindgerecht.

### Lumo LIVE
- **Was**: `lib/features/live/lumo_live_pro_screen.dart` — Voice → Pollinations-Bild → Lumo erklärt; Foto → Lumo fragt „Was siehst du?"
- **War**: nur über versteckten Magic-Hub-FAB
- **Jetzt**: prominente Subject-Tile im Home (🎤📸 Lumo LIVE)

## ❌ Noch nicht angeschlossen (Iterationen 12+)

### LumoMissionEngine — komplett tot
- **Wo**: `lib/core/lumo_mission_engine.dart`
- **Was**: Tagesplan-Generator mit Mission, Belohnung, Progress-Tracking
- **Status**: Klasse existiert, `LumoMission` + `LumoMissionProgress` definiert, `dailyMissions()` Methode da — aber **keine Aufrufe außer Selbst-Referenzen**.
- **Anschluss-Plan**: `LumoDailyMissionCard` im Subject-Dashboard zeigt statischen Text. Sollte echte `LumoMission` aus `LumoMissionEngine.dailyMissions(grade)` ziehen.

### Magic-Hub-Features (10 versteckt)
- **Wo**: `lib/features/magic_hub/lumo_magic_hub_screen.dart`
- **Versteckte Premium-Tiles**:
  1. ~~Lumo Live~~ (jetzt prominent)
  2. **Lumo Story** — Bibliothek + neue erstellen (über Lumo Quest teilweise erreichbar, Library nicht)
  3. **Meine Welt / LumoCosmosScreen** — Tag/Nacht + 4 Jahreszeiten + Garten
  4. **Lumo Mirror** — 8 Emotionen, reagiert auf dich
  5. **Lumo Brain Chat** (separat von Agent)
  6. **Lumo Teacher** (Akademie-Pendant)
  7. ... +4 weitere
- **Anschluss-Plan**: 2-3 davon als Subject-Tiles im Home, Rest bleibt im Hub.

### LumoTutorEngine
- **Wo**: `lib/core/lumo_tutor_engine.dart`
- **Was**: Tutor-Logik für adaptive Aufgaben-Schwierigkeit
- **Status**: Nur in `learning_content.dart` referenziert — Eltern-Diagnose-UI fehlt.
- **Anschluss-Plan**: Verzahnen mit `LumoInsightDashboard` (Iter 9).

### LumoVisualAidService
- **Wo**: `lib/core/lumo_visual_aid_service.dart`
- **Was**: Visuelle Erklär-Hilfen für schwierige Aufgaben (mit AI-Bildgenerierung?)
- **Status**: Existiert, wird in `learning_content.dart` referenziert. Frage: triggern Aufgaben wirklich Visual-Aid?
- **Anschluss-Plan**: Iteration 13+ nach Gerätetest.

### LumoCompanionAgent
- **Wo**: `lib/core/lumo_companion_agent.dart`
- **Was**: Lumo's Persönlichkeits-Engine (separat von ChatGPT-Proxy)
- **Anschluss-Plan**: Prüfen ob im Agent-Screen aktiv.

### Quiz-Show / QuizQuestionBank
- **Wo**: `lib/domain/quiz/quiz_question_bank.dart` (96 Fragen statisch befüllt)
- **Status**: Wird vom Home via QuizShowContent aufgerufen — angeschlossen ✓
- **Aber**: Pool ist hartkodiert, könnte AI-erweitert werden.

## Bridge zur 3D-Welt
- ✅ `dev.ullmann.lumo3d` ↔ `dev.ullmann.lumo.lumo_lernen` via Intent-Filter (Iter 2+4, verifiziert mit aapt)
- ✅ Section-Routing (Iter 4)

## Backend-Status
| Service | URL | Status |
|---|---|---|
| AI-Proxy | `lumo-ai-proxy.onrender.com` | ✅ live, OpenAI konfiguriert |
| GitHub Pages (Godot Web) | `ullmann27.github.io/lumo-godot` | ✅ live, Build aus gh-pages |
| Render Cold-Start | beim ersten Call ~30s | Warmup im Agent-initState aktiv |

## Stop-Kriterium für diese Iteration
- 2 von 6+ unangeschlossenen Komponenten frisch verdrahtet
- Nächste Schritte brauchen Heinz' Gerätetest:
  - Funktioniert KI-Chat nach Aktivierung?
  - Ist Lumo LIVE im Home klickbar?
  - Welche Magic-Hub-Features sollen weiter prominent werden?
