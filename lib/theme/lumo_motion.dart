// ════════════════════════════════════════════════════════════════════════
// LUMO MOTION — Animation Durations + Curves
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoMotion {
  LumoMotion._();

  // ── DURATIONS ─────────────────────────────────────────────────────
  Duration get instant => const Duration(milliseconds: 100);
  Duration get fast => const Duration(milliseconds: 200);
  Duration get normal => const Duration(milliseconds: 350);
  Duration get slow => const Duration(milliseconds: 600);
  Duration get verySlow => const Duration(milliseconds: 1000);

  /// Spezielle Dauer fuer Page-Transitions.
  Duration get pageTransition => const Duration(milliseconds: 450);

  /// Spezielle Dauer fuer Hero-Animationen.
  Duration get hero => const Duration(milliseconds: 700);

  // ── CURVES ────────────────────────────────────────────────────────
  /// Standard Eingang - sanft, premium.
  Curve get easeOutBack => Curves.easeOutBack;

  /// Soft Bounce - fuer Karten, Reactions.
  Curve get easeOutCubic => Curves.easeOutCubic;

  /// Verspielt - leichter Bounce.
  Curve get elasticOut => Curves.elasticOut;

  /// Symmetrisch - hin und zurueck.
  Curve get easeInOutCubic => Curves.easeInOutCubic;

  /// Schnell rein, sanft raus.
  Curve get fastOutSlowIn => Curves.fastOutSlowIn;

  /// Linear fuer kontinuierliche Animationen.
  Curve get linear => Curves.linear;

  // ── REDUCE MOTION SUPPORT ─────────────────────────────────────────
  /// Liefert die Duration unter Beruecksichtigung von
  /// MediaQuery.disableAnimations (a11y).
  Duration safeDuration(BuildContext context, Duration normal) {
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disabled ? Duration.zero : normal;
  }

  /// Liefert die Curve unter Beruecksichtigung von disableAnimations.
  Curve safeCurve(BuildContext context, Curve normal) {
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disabled ? Curves.linear : normal;
  }
}
