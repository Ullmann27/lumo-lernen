// ════════════════════════════════════════════════════════════════════════
// LUMO COMPANION REQUEST BUS
// ════════════════════════════════════════════════════════════════════════
// Heinz-Auftrag: 'Tap-to-move via Parent-Listener, keine Fullscreen-
// Overlay-GestureDetector die Buttons frisst'.
//
// Architektur:
//   1. App-Shell hat ein Listener-Widget (NICHT GestureDetector).
//      Listener ist passiv - es konsumiert KEINE Pointer-Events.
//      Buttons/Cards funktionieren weiterhin normal.
//   2. Listener.onPointerDown gibt die GLOBAL-Position weiter.
//   3. App-Shell ruft requestMoveTo(globalPosition) auf.
//   4. LumoFreeCompanion lauscht auf den Notifier und laeuft hin
//      - aber nur wenn die Position in einer Safe-Zone liegt.
//   5. So bleiben Buttons komplett bedienbar und Lumo wandert frei.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/widgets.dart';

enum LumoInteractionKind {
  taskOpened, answerChecked, helpRequested, readingStarted,
  gameRequested, lockedGameTapped,
}

/// Local visible task. Never carries the correct answer or child identity.
class LumoCompanionTaskContext {
  const LumoCompanionTaskContext({
    required this.subject,
    required this.unit,
    required this.prompt,
    this.isExam = false,
    this.answering = true,
    this.taskId = '',
    this.attempts = 0,
    this.helpLevel = 0,
    this.lastAnswer,
    this.lastCorrect,
    this.previousHelp,
    this.localHelp,
    this.activity = 'learning',
    this.ownerSection = 'exercises',
  });

  final String subject;
  final String unit;
  final String prompt;
  final bool isExam;
  final bool answering;
  final String taskId;
  final int attempts;
  final int helpLevel;
  final String? lastAnswer;
  final bool? lastCorrect;
  final String? previousHelp;
  final String? localHelp;
  final String activity;
  final String ownerSection;
}

class LumoCompanionRequests {
  LumoCompanionRequests._();
  static final LumoCompanionRequests instance = LumoCompanionRequests._();

  /// Position auf die der Companion hinwandern soll (in GLOBAL coords).
  /// Wenn null = keine aktive Anfrage. Nach Verarbeitung wieder auf null.
  final ValueNotifier<Offset?> moveTarget = ValueNotifier<Offset?>(null);

  /// The active lesson handles this request in place, keeping its answer state.
  final ValueNotifier<int> helpRequested = ValueNotifier<int>(0);
  final ValueNotifier<LumoCompanionTaskContext?> taskContext =
      ValueNotifier<LumoCompanionTaskContext?>(null);

  final ValueNotifier<int> appExplanationRequested = ValueNotifier<int>(0);
  /// Bounded semantic trace in RAM. Pointer coordinates remain in moveTarget
  /// only and are never copied into this trace or sent to a provider.
  final ValueNotifier<List<LumoInteractionKind>> recentInteractions =
      ValueNotifier<List<LumoInteractionKind>>([]);

  void recordInteraction(LumoInteractionKind kind) {
    final next = [...recentInteractions.value, kind];
    recentInteractions.value = List.unmodifiable(
        next.skip(next.length > 12 ? next.length - 12 : 0));
  }

  void requestTaskHelp() => helpRequested.value++;
  void requestAppExplanation() => appExplanationRequested.value++;

  /// Letzter Zeitpunkt einer Anfrage - fuer Cooldown.
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _cooldown = Duration(milliseconds: 1200);

  /// Fordere den Companion an, zu einer Position zu wandern.
  /// Globale Position (vom Listener.onPointerDown).
  /// Mit eingebautem Cooldown damit Kinder nicht spammen koennen.
  void requestMoveTo(Offset globalPosition) {
    final now = DateTime.now();
    if (now.difference(_lastRequest) < _cooldown) return;
    _lastRequest = now;
    moveTarget.value = globalPosition;
  }

  /// Companion ruft dies nach Verarbeitung auf - setzt Target zurueck.
  void clearRequest() {
    moveTarget.value = null;
  }
}
