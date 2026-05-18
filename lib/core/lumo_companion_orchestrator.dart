import 'dart:async';

import '../app/app_state.dart';
import 'lumo_voice.dart';

/// Proaktiver Lumo-Begleiter-Orchestrator.
///
/// Zentrale Schicht, die entscheidet:
/// - wann Lumo spricht
/// - welche Emotion angezeigt wird
/// - wie auf Lernereignisse reagiert wird
///
/// Verbindet: Lernereignisse ↔ AppState ↔ Avatar ↔ Voice
///
/// Regeln:
/// - Kein Voice-Spam (min. 8s zwischen Sprechen)
/// - Kindgerecht und sicher
/// - Offline-First (kein Absturz ohne Netz)
/// - Keine echten personenbezogenen Daten weitergegeben
class LumoCompanionOrchestrator {
  LumoCompanionOrchestrator._internal();
  static final LumoCompanionOrchestrator instance = LumoCompanionOrchestrator._internal();

  LumoAppState? _appState;
  DateTime? _lastSpoke;

  /// Mindestpause zwischen zwei Lumo-Sprachausgaben (Anti-Spam).
  static const Duration _minSpeechGap = Duration(seconds: 8);

  /// Orchestrator mit dem zentralen AppState verbinden.
  void attach(LumoAppState appState) {
    _appState = appState;
  }

  void detach() {
    _appState = null;
  }

  // ── Öffentliche Ereignisse ─────────────────────────────────────────────

  /// Wird aufgerufen, wenn das Kind eine Aufgabe richtig gelöst hat.
  void onCorrectAnswer({required int earnedStars}) {
    final state = _appState?.state;
    if (state == null) return;
    final name = _name(state);
    _speak(
      message: earnedStars > 1
          ? 'Fantastisch$name! $earnedStars Sterne auf einmal! 🌟'
          : 'Richtig$name! Weiter so! ⭐',
      mood: LumoMood.celebrate,
      style: VoiceStyle.celebrate,
    );
  }

  /// Wird aufgerufen, wenn das Kind eine Aufgabe falsch beantwortet hat.
  void onWrongAnswer({required int consecutiveErrors}) {
    final state = _appState?.state;
    if (state == null) return;
    final name = _name(state);
    final message = consecutiveErrors >= 3
        ? 'Mach dir keine Sorgen$name. Wir schauen es uns gemeinsam an.'
        : consecutiveErrors >= 2
            ? 'Fast$name! Versuch es nochmal.'
            : 'Das war knapp. Schau genau hin!';
    _speak(
      message: message,
      mood: consecutiveErrors >= 2 ? LumoMood.comfort : LumoMood.think,
      style: consecutiveErrors >= 2 ? VoiceStyle.comfort : VoiceStyle.warm,
    );
  }

  /// Wird aufgerufen, wenn der Abschnitt wechselt.
  void onSectionChanged(LumoSection section) {
    final state = _appState?.state;
    if (state == null) return;
    final name = _name(state);
    final (msg, mood, style) = switch (section) {
      LumoSection.learn      => ('Gleich geht es los$name!', LumoMood.point, VoiceStyle.greeting),
      LumoSection.exercises  => ('Auf gehts$name! Du schaffst das!', LumoMood.point, VoiceStyle.greeting),
      LumoSection.games      => ('Spielzeit$name! Und dabei lernen.', LumoMood.celebrate, VoiceStyle.celebrate),
      LumoSection.agent      => ('Hallo$name. Was kann ich für dich tun?', LumoMood.greet, VoiceStyle.greeting),
      LumoSection.reading    => ('Wir lesen gemeinsam$name.', LumoMood.think, VoiceStyle.explain),
      LumoSection.rewards    => ('Schau dir deine Sterne an$name!', LumoMood.celebrate, VoiceStyle.celebrate),
      LumoSection.home       => ('Schön, dass du da bist$name!', LumoMood.greet, VoiceStyle.greeting),
      _                      => (null, LumoMood.idle, VoiceStyle.warm),
    };
    if (msg != null) {
      _speak(message: msg, mood: mood, style: style);
    }
  }

  /// Wird aufgerufen, wenn das Kind lange inaktiv ist (> 60s).
  void onInactivity() {
    final state = _appState?.state;
    if (state == null) return;
    final name = _name(state);
    _speak(
      message: 'Hey$name, ich bin noch hier! Soll ich dir eine Aufgabe suchen?',
      mood: LumoMood.wave,
      style: VoiceStyle.warm,
    );
  }

  /// Wird aufgerufen, wenn ein Level-Aufstieg stattfindet.
  void onLevelUp(int newLevel) {
    final state = _appState?.state;
    if (state == null) return;
    final name = _name(state);
    _speak(
      message: 'Level $newLevel$name! Das ist großartig! 🎉',
      mood: LumoMood.celebrate,
      style: VoiceStyle.celebrate,
    );
  }

  // ── Interne Logik ──────────────────────────────────────────────────────

  String _name(LumoSessionState state) {
    final n = state.childName.trim();
    return n.isEmpty ? '' : ' $n';
  }

  bool _canSpeak() {
    if (_lastSpoke == null) return true;
    return DateTime.now().difference(_lastSpoke!) >= _minSpeechGap;
  }

  void _speak({
    required String message,
    required LumoMood mood,
    required VoiceStyle style,
  }) {
    if (!_canSpeak()) return;
    final state = _appState?.state;
    if (state == null) return;

    _lastSpoke = DateTime.now();

    _appState!.update(state.copyWith(
      lumoMessage: message,
      mood: mood,
    ));

    if (state.settings.voiceEnabled) {
      unawaited(LumoVoice.instance.speak(message, style: style));
    }
  }
}
