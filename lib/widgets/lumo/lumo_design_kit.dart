// ════════════════════════════════════════════════════════════════════════
// LUMO DESIGN KIT — Bruecke zwischen Figma-Tokens und Flutter-Widgets
// ════════════════════════════════════════════════════════════════════════
//
// Diese Datei enthaelt KEINE Tokens (die sind in app/app_theme.dart und
// theme/lumo_design_tokens.dart), sondern *Helper-Functions* die unsere
// Figma-Komponenten 1:1 in Flutter nachbauen.
//
// Workflow:
//   Figma-Designsystem (MKdAIJ3B45RJbIebQoHNbU)
//     ↓ Tokens als Source of Truth
//   app/app_theme.dart (LumoColors, LumoRadius, LumoShadow)
//     ↓ verwendet von
//   lumo_design_kit.dart (kits.softCardDecoration, kits.heroGradient, …)
//     ↓ verwendet von
//   LumoChip, LumoPromptCard, LumoModernCard, …
//
// Konvention: ALLE neuen oder verbesserten Widgets nutzen `LumoKit` statt
// ad-hoc Magic-Numbers.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

class LumoKit {
  LumoKit._();

  // ── SPACING (4pt grid wie in Figma) ─────────────────────────────────
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ── RADIUS (deckt sich mit LumoRadius aus app_theme.dart) ───────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  // ── SHADOWS (Figma Spec: soft card, hero, glow) ─────────────────────

  /// Sanfter Schatten fuer Standard-Karten (alpha 0.08, y 4, blur 12).
  static List<BoxShadow> get softCard => [
        BoxShadow(
          color: const Color(0x00000000).withOpacity(0.08),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  /// Subtiler Schatten fuer Inline-Karten (alpha 0.06, y 2, blur 8).
  static List<BoxShadow> get subtleCard => [
        BoxShadow(
          color: const Color(0x00000000).withOpacity(0.06),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  /// Brand-getoenter Glow fuer Hero-Karten (alpha 0.40, y 8, blur 20).
  /// Wir nutzen das fuer Magic-Hub-Cards und Premium-CTAs.
  static List<BoxShadow> heroGlow(Color brand) => [
        BoxShadow(
          color: brand.withOpacity(0.40),
          offset: const Offset(0, 8),
          blurRadius: 20,
        ),
      ];

  /// Press-State Schatten (kleiner, naeher dran).
  static List<BoxShadow> get pressed => [
        BoxShadow(
          color: const Color(0x00000000).withOpacity(0.10),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];

  // ── GRADIENTS (alle aus Figma uebernommen) ──────────────────────────

  /// 45°-Gradient (Figma transform [[0.7,0.7,0],[-0.7,0.7,0]]).
  static LinearGradient diagonal(Color start, Color end) => LinearGradient(
        colors: [start, end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get heroOrange =>
      diagonal(const Color(0xFFF97316), const Color(0xFFFBA94C));

  static LinearGradient get heroLila =>
      diagonal(const Color(0xFF8B5CF6), const Color(0xFF6D28D9));

  static LinearGradient get heroGold =>
      diagonal(const Color(0xFFFCD34D), const Color(0xFFD97706));

  static LinearGradient get heroGreen =>
      diagonal(const Color(0xFF10B981), const Color(0xFF047857));

  // ── DECORATIONS (1-Liner BoxDecorations fuer Karten/Chips) ──────────

  /// Standard-Karte: weiss + soft shadow + radius lg.
  static BoxDecoration get cardDefault => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: softCard,
      );

  /// Subtile Karte: weiss + subtle shadow + radius lg.
  static BoxDecoration get cardSubtle => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: subtleCard,
      );

  /// Premium-Karte mit Brand-Border (z.B. Prompt-Card im Schreibcoach).
  static BoxDecoration cardWithBorder(Color border, {double width = 2}) =>
      BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: border, width: width),
        boxShadow: subtleCard,
      );

  /// Hero-Karte mit Gradient + Glow.
  static BoxDecoration heroCard(LinearGradient gradient, Color glowColor) =>
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: heroGlow(glowColor),
      );

  /// Pill / Chip (kleine bunte Markierung).
  static BoxDecoration pill(Color bg, {Color? border}) => BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radiusPill),
        border:
            border == null ? null : Border.all(color: border, width: 1.4),
      );

  // ── TYPOGRAPHY HELPERS ──────────────────────────────────────────────

  /// Display-Style (32, Black) - nur fuer Welcome/Greeting.
  static TextStyle get display => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: LumoColors.ink900,
        height: 1.1,
      );

  /// Heading 1 (24, Black).
  static TextStyle get heading1 => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: LumoColors.ink900,
      );

  /// Heading 2 (20, Black).
  static TextStyle get heading2 => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: LumoColors.ink900,
      );

  /// Title (18, ExtraBold).
  static TextStyle get title => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: LumoColors.ink900,
      );

  /// Body (15, SemiBold, ink700).
  static TextStyle get body => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: LumoColors.ink700,
        height: 1.35,
      );

  /// Label (13, ExtraBold, ink600) - fuer Chips, Tags, Pills.
  static TextStyle get label => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: LumoColors.ink600,
        letterSpacing: 0.3,
      );

  /// Caption (12, SemiBold, ink500) - fuer kleine Sub-Texte.
  static TextStyle get caption => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: LumoColors.ink500,
      );
}
