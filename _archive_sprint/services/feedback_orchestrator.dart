import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../widgets/effects/confetti_overlay.dart';
import '../widgets/effects/star_burst.dart';
import '../widgets/effects/xp_float.dart';

/// Zentrale Effekt-Steuerung.
///
/// Orchestriert alle Reward-Effekte (Konfetti, +XP, Stern-Burst)
/// in einem einzigen Aufruf — damit überall in der App identisch reagiert wird.
class FeedbackOrchestrator {
  FeedbackOrchestrator._();

  /// Großer Erfolg — Konfetti, +XP, Sterne fliegen.
  ///
  /// [origin] = Punkt im Screen, von dem alle Effekte ausgehen.
  static void celebrate(
    BuildContext context, {
    required Offset origin,
    int xpAmount = 20,
    int starCount = 7,
    bool withConfetti = true,
  }) {
    if (withConfetti) {
      ConfettiOverlay.fire(context, origin: origin);
    }
    StarBurst.show(
      context,
      origin: origin,
      starCount: starCount,
      color: LumoColors.gold,
    );
    XpFloat.show(
      context,
      origin: origin,
      amount: xpAmount,
      color: LumoColors.gold,
    );
  }

  /// Kleiner Erfolg — nur Stern-Burst ohne Konfetti
  static void success(
    BuildContext context, {
    required Offset origin,
    Color color = LumoColors.teal,
  }) {
    StarBurst.show(
      context,
      origin: origin,
      starCount: 5,
      color: color,
      spreadRadius: 60,
    );
  }

  /// Falsche Antwort — sanftes „Plop"-Burst in Rosa
  static void wrong(BuildContext context, {required Offset origin}) {
    StarBurst.show(
      context,
      origin: origin,
      starCount: 4,
      color: const Color(0xFFEF4444),
      spreadRadius: 40,
    );
  }

  /// Level-Up — riesiger Konfetti-Sturm
  static void levelUp(
    BuildContext context, {
    required Offset origin,
    required int newLevel,
  }) {
    ConfettiOverlay.fire(
      context,
      origin: origin,
      particleCount: 120,
      colors: const [
        LumoColors.gold,
        LumoColors.orange,
        LumoColors.purple,
        LumoColors.teal,
        Color(0xFFEC4899),
      ],
    );
    StarBurst.show(
      context,
      origin: origin,
      starCount: 12,
      color: LumoColors.gold,
      spreadRadius: 140,
    );
    XpFloat.show(
      context,
      origin: origin,
      amount: newLevel,
      color: LumoColors.purple,
      label: 'LEVEL!',
    );
  }
}
