import 'dart:async';
import 'package:flutter/material.dart';
import 'lumo_voice.dart';
import '../widgets/free_lumo_fox.dart';

/// Ein einzelner Schritt der Lumo-Tour.
class LumoTourStep {
  const LumoTourStep({
    required this.targetKey,
    required this.message,
    this.mood = 'point',
    this.facing,
    this.holdMs = 3500,
  });

  /// GlobalKey des UI-Elements, zu dem der Fuchs hinlaufen soll.
  final GlobalKey targetKey;

  /// Was Lumo dazu sagt (TTS).
  final String message;

  /// Stimmung waehrend dieses Schritts.
  final String mood;

  /// Blickrichtung (auto, falls null - aus Position berechnet).
  final FoxFacing? facing;

  /// Wie lange Lumo bei diesem Element verweilt.
  final int holdMs;
}

/// Steuert eine gefuehrte Tour: der Fuchs laeuft zu jedem Schritt,
/// dreht sich, zeigt drauf, und spricht die Erklaerung.
///
/// Nutzung:
/// ```
/// final tour = LumoTour(
///   homePosition: Offset(800, 300),
///   onUpdate: (pos, mood, facing, msg) => setState(() { ... }),
/// );
/// tour.start([LumoTourStep(...), ...]);
/// ```
class LumoTour {
  LumoTour({
    required this.homePosition,
    required this.onUpdate,
    required this.onFinish,
  });

  /// Position, zu der Lumo am Ende zurueckkehrt.
  Offset homePosition;

  /// Callback bei jedem State-Wechsel.
  final void Function(
    Offset target,
    String mood,
    FoxFacing facing,
    String message,
  ) onUpdate;

  /// Wird gerufen wenn die Tour fertig ist.
  final VoidCallback onFinish;

  Timer? _timer;
  bool _running = false;
  bool get isRunning => _running;

  /// Startet die Tour mit den gegebenen Schritten.
  Future<void> start(List<LumoTourStep> steps) async {
    if (_running) return;
    _running = true;
    Offset lastPos = homePosition;

    for (final step in steps) {
      if (!_running) break;
      final ctx = step.targetKey.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      // Globale Position des Ziels (Mitte des Elements)
      final pos = box.localToGlobal(Offset.zero) + Offset(box.size.width / 2, box.size.height / 2);

      // Blickrichtung: schau zum Ziel
      final facing = step.facing ?? (pos.dx < lastPos.dx ? FoxFacing.left : FoxFacing.right);

      onUpdate(pos, step.mood, facing, step.message);
      LumoVoice.instance.speak(step.message);

      lastPos = pos;
      await Future.delayed(Duration(milliseconds: step.holdMs));
      if (!_running) break;
    }

    // Zurueck zum Home
    if (_running) {
      onUpdate(homePosition, 'greet', FoxFacing.right,
          'Was moechtest du als erstes machen?');
      LumoVoice.instance.speak('Was moechtest du als erstes machen?');
    }

    _running = false;
    onFinish();
  }

  /// Bricht eine laufende Tour ab.
  void stop() {
    _running = false;
    _timer?.cancel();
    LumoVoice.instance.stop();
  }
}
