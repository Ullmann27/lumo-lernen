// ════════════════════════════════════════════════════════════════════════
// LUMO TYPOGRAPHY — Premium Schrift-System
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoTypography {
  LumoTypography._();
  static const String fontFamily = 'Nunito';

  // ── DISPLAY (Hero-Texte) ──────────────────────────────────────────
  TextStyle get displayLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -0.5,
      );

  TextStyle get displayMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.15,
        letterSpacing: -0.3,
      );

  // ── HEADLINE (Karten-Titel) ───────────────────────────────────────
  TextStyle get headlineLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.2,
      );

  TextStyle get headlineMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        height: 1.25,
      );

  TextStyle get headlineSmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.3,
      );

  // ── TITLE (Sektionen) ─────────────────────────────────────────────
  TextStyle get titleLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        height: 1.3,
      );

  TextStyle get titleMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        height: 1.35,
      );

  // ── BODY (Lesetext) ───────────────────────────────────────────────
  TextStyle get bodyLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  TextStyle get bodyMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  TextStyle get bodySmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ── LABEL (Buttons, Tags) ─────────────────────────────────────────
  TextStyle get labelLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  TextStyle get labelMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      );

  TextStyle get labelSmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      );

  // ── NUMBER (Sterne, XP, grosse Zahlen) ───────────────────────────
  TextStyle get numberHero => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 56,
        fontWeight: FontWeight.w900,
        height: 1.0,
      );

  TextStyle get numberLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        height: 1.0,
      );

  TextStyle get numberMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.0,
      );
}
