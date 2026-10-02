# Lumo Lernen v0.2 – Implementierungsbericht

## Was konkret gebaut wurde

- Modulare Flutter-Struktur mit `app/`, `core/models/`, `core/engines/`, `core/services/`, `screens/`, `widgets/`, `assets/`, `test/`
- Adaptive `AppShell`:
  - `<700dp`: kompakte Ansicht mit NavigationBar und kleinem Floating-Lumo
  - `>=700dp`: Split-Panel mit NavigationRail, Hauptinhalt und Lumo-Seitenpanel
  - `>=1050dp`: erweiterte NavigationRail
- Voll verdrahtete Screens:
  - Home
  - Lernen
  - Lumo-Agent
  - Erkennen
  - Kognitiver Lern-Check
  - Bonus/Gutscheine
  - Eltern
  - Memory
  - Einstellungen
- EventBus / Companion Loop:
  - UserAction → EventBus → SchoolMomentEngine → LearningBrain/Reward/Agent → AvatarDirector → VoiceDirector → MemoryGraph → UI
- AvatarDirector-State-Machine mit Rive-Input-Mapping-Vorbereitung
- VoiceDirector mit SpeechPlan, Segmenten, VoiceMode, Anti-Wiederholung der letzten 80 Sätze
- TtsService mit `flutter_tts` und Debug-Fallback
- SpeechInputService mit Elternfreigabe-Gate
- PhotoScanService als ML-Kit-Stub mit Elternfreigabe-Gate
- RecognitionEngine für:
  - Addition/Subtraktion
  - Zahlenreihen
  - Anfangslaute
  - Silben
  - Reime
  - Sachunterrichtsfragen
  - Noteneinträge
- LearningBrain:
  - begründete Aufgabenwahl
  - Schwächenbezug
  - 3-Fehlversuche-Logik
  - richtige Antwort + Erklärung + ähnliche Folgeaufgabe
- ExplanationStyleEngine:
  - Text
  - Schrittfolge
  - Zahlenstrahl
  - Silbenklatschen
  - Bild-/Mini-Geschichten-Platzhalter
- MemoryGraph:
  - SkillMemory
  - ErrorTypeCounts
  - HelpStrategyEffect
  - LearnedStrategy-Regel: ab 5 Nutzungen und >65 % Erfolg
  - ExerciseHistory
  - RewardHistory
  - ParentConsent
  - ReportHistory
  - RecognizedTaskHistory
  - lokale Persistenz via SharedPreferences
- RewardOrchestrator:
  - Sterne
  - XP
  - Level
  - Achievements
  - digitale Zimmeritems vorbereitet
  - Eltern-PIN-Gutscheine
- ParentDashboard:
  - PIN-Schutz
  - Warum-Erklärung
  - Noteneintrag
  - Datenschutzfreigaben
  - Export
  - lokale Löschung
- CognitiveGames:
  - Förderprofil ohne IQ- oder Diagnosebehauptung
- Tests:
  - RecognitionEngine
  - CompanionAgent
  - RewardOrchestrator
  - LearningBrain
  - MemoryGraph

## Nicht ausgeführt

In dieser Umgebung ist kein Flutter/Dart-SDK installiert. Daher konnten `flutter pub get`, `flutter test` und `flutter run` nicht ausgeführt werden. Die Dateien wurden statisch erstellt und auf konsistente Importstruktur vorbereitet.

## Nächster lokaler Prüfpfad

```bash
cd lumo_lernen_flutter
flutter create .
flutter pub get
flutter test
flutter run
```

Für ein bestehendes Projekt: `lib/`, `test/`, `pubspec.yaml`-Dependencies und `assets/` übernehmen.
