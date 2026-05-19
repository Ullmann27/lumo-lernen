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

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class LumoCompanionRequests {
  LumoCompanionRequests._();
  static final LumoCompanionRequests instance = LumoCompanionRequests._();

  /// Position auf die der Companion hinwandern soll (in GLOBAL coords).
  /// Wenn null = keine aktive Anfrage. Nach Verarbeitung wieder auf null.
  final ValueNotifier<Offset?> moveTarget = ValueNotifier<Offset?>(null);

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
