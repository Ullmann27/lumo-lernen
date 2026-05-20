// ════════════════════════════════════════════════════════════════════════
// LUMO COLORS — Warme Premium-Palette
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoColors {
  LumoColors._();

  // ── BRAND ─────────────────────────────────────────────────────────
  Color get lumoOrange => const Color(0xFFF97316);
  Color get lumoOrangeDeep => const Color(0xFFEA580C);
  Color get lumoOrangeLight => const Color(0xFFFFB780);

  Color get lumoLila => const Color(0xFF7C3AED);
  Color get lumoLilaDeep => const Color(0xFF5B21B6);
  Color get lumoLilaLight => const Color(0xFFA78BFA);

  Color get gold => const Color(0xFFFCD34D);
  Color get goldDeep => const Color(0xFFD97706);
  Color get goldLight => const Color(0xFFFEF3C7);

  // ── BACKGROUND ────────────────────────────────────────────────────
  Color get creme => const Color(0xFFFFFBEB);
  Color get cremeDeep => const Color(0xFFFEF3C7);
  Color get cremePaper => const Color(0xFFFDF6E3);

  Color get bgGradientTop => const Color(0xFFFFF7ED);
  Color get bgGradientBottom => const Color(0xFFFFEDD5);

  // ── SEMANTIC ──────────────────────────────────────────────────────
  Color get success => const Color(0xFF10B981);
  Color get successLight => const Color(0xFFD1FAE5);
  Color get successDeep => const Color(0xFF065F46);

  Color get errorSoft => const Color(0xFFFB7185); // Koralle, nicht aggressiv
  Color get errorSoftLight => const Color(0xFFFEE2E2);
  Color get errorSoftDeep => const Color(0xFF991B1B);

  Color get warning => const Color(0xFFFCD34D);
  Color get warningDeep => const Color(0xFF92400E);

  Color get info => const Color(0xFF06B6D4);
  Color get infoDeep => const Color(0xFF0E7490);

  // ── TEXT ──────────────────────────────────────────────────────────
  Color get textDark => const Color(0xFF2E1065); // Dark Purple - warm
  Color get textBody => const Color(0xFF4C1D95);
  Color get textMuted => const Color(0xFF6B7280);
  Color get textOnPrimary => Colors.white;

  // ── SURFACE ───────────────────────────────────────────────────────
  Color get surface => Colors.white;
  Color get surfaceMuted => const Color(0xFFFAFAFA);
  Color get surfaceGlass => Colors.white.withOpacity(0.85);
  Color get surfaceDim => const Color(0x33000000);

  // ── DIVIDER + OUTLINE ─────────────────────────────────────────────
  Color get outline => const Color(0xFFE5E7EB);
  Color get outlineSoft => const Color(0x14000000);

  // ── GRADIENTS (vordefiniert) ──────────────────────────────────────
  LinearGradient get heroOrange => const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroLila => const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroGold => const LinearGradient(
        colors: [Color(0xFFFCD34D), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroSuccess => const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get bgWarm => const LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5), Color(0xFFFEF3C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  LinearGradient get bgMagic => const LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFFE4D2), Color(0xFFFDD9C0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
