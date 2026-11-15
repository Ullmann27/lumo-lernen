# Frage-Coach: Flutter-Prüfung vom 15.11.2026

Geprüfter Quellstand: `ca3f48ef961b4a50e95c6dffca2785d818191842`, aufbauend auf
`aba1b9d16dae17141b9b3fc2908a705834fdeee3` und der gemeinsamen Basis `8e100d4`.
Flutter 3.44.9, Dart 3.12.2; kein neuer SDK und keine geänderten Paketversionen.

## Tatsächlich ausgeführte Prüfungen

Der gemeinsame gezielte Lauf in `focused-tests.log` umfasst **56 erfolgreiche
Tests** und endete mit Exit 0:

- Coach: Stopp, ersetzter Kandidat einschließlich altem Button-Callback,
  Aufgaben-/Schrittwechsel, App-Pause, eigener Audio-Owner und verzögerte Ausgabe.
- Native-Einstieg: echter Flutter-Launcher über seinen kontrollierten Android-
  MethodChannel, bestehender Hilfeverbrauch, mindestens 48 dp hoher Button und
  erhaltene Aufgabenidentität während der nativen Activity-Pause.
- Flame: die im tatsächlichen Spiel installierten Frage- und Truhen-Callbacks.
  Bestätigen wählt nur eine Karte. Der bestehende Prüfknopf bewertet; die Truhe
  öffnet erst nach drei aufeinanderfolgenden richtigen Prüfungen. Die Spielwelt
  ist für diese gezielte Prüfung pausiert; dies ist keine neue Physik-Tour.
- LivePro: endgültiger STT-Text statt Partial, editierbarer Kandidat, explizite
  Bestätigung, vorhandene Teilnahme-/Safari-Bewertung, Stopp, Moduswechsel,
  verspätetes Initialisieren, Kamera-/Mikrofon-Freigaben und Profilwechsel.
- Gemeinsame Narration: eigener Transport bei Pause/Stopp/Dispose, neuere
  Ausgabe bleibt erhalten; verspäteter nativer Stopp startet keinen alten Text.

`focused-analysis.log` enthält die Analyse der zwölf betroffenen Dart-Dateien:
keine Fehler und keine Warnungen. Ein bereits vorhandener Hinweis zum
ungenutzten `dart:typed_data`-Import in `lumo_voice.dart` bleibt unverändert.

## Renderbilder

Die PNGs entstanden durch die tatsächliche Flutter-RenderBoundary im Test
`test/games/learning_question_coach_flow_test.dart`. Die Namen bezeichnen
logische Testflächen:

| Datei | Logische Testfläche |
|---|---|
| `phone-320-cards.png` | 320 × 780 dp |
| `fold-cover-cards.png` | 344 × 882 dp |
| `fold-open-cards.png` | 840 × 900 dp |

Das sind Renderbilder des sichtbaren Ausschnitts der scrollbaren Kartenfrage.
Die Mindestgröße der Antwort- und Coach-Buttons wurde zusätzlich direkt an den
gerenderten Widgets geprüft. Diese Flächen sind keine Behauptung über die
physische Auflösung oder Dichte eines Galaxy Fold7.

Die Sprachprüfungen verwenden kontrollierte Callback-/Transport-Futures. Sie
belegen keine reale Mikrofonaufnahme, Android-Spracherkennung, native hörbare
Wiedergabe oder Android-FPS. Die vollständige APK-/Emulator-Abnahme bleibt im
gemeinsamen Release-Workflow.
