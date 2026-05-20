// ════════════════════════════════════════════════════════════════════════
// LUMO SHADOWS — Premium Schatten-System
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoShadows {
  LumoShadows._();

  /// Weicher Karten-Schatten - fuer Premium-Cards.
  List<BoxShadow> get softCard => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Schwebender Effekt - fuer Floating-Cards.
  List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  /// Hero-Schatten - fuer grosse Premium-Karten.
  List<BoxShadow> get hero => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 64,
          offset: const Offset(0, 24),
        ),
      ];

  /// Glow-Effekt - tinted nach Brand-Color.
  List<BoxShadow> glow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withOpacity(0.3 * intensity),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: color.withOpacity(0.15 * intensity),
          blurRadius: 48,
          offset: const Offset(0, 16),
        ),
      ];

  /// Eingedrueckter Button-Schatten.
  List<BoxShadow> get pressed => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Subtler Hint-Schatten fuer inline-Elemente.
  List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}
