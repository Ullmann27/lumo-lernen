// ════════════════════════════════════════════════════════════════════════
// LUMO DESIGN TOKENS — Master Token File
// ════════════════════════════════════════════════════════════════════════
// Single Source of Truth fuer das gesamte Premium UI System.
// Alle anderen Module importieren von hier statt eigene Werte zu erfinden.
// Heinz' Auftrag: 'lebendige, warme, hochwertige Lernwelt'.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'lumo_colors.dart';
import 'lumo_motion.dart';
import 'lumo_shadows.dart';
import 'lumo_typography.dart';

class LumoTokens {
  LumoTokens._();

  // ── SPACING (4-Punkt-Grid) ────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;
  static const double space64 = 64;

  // ── BORDER RADIUS ─────────────────────────────────────────────────
  static const double radiusSmall = 8;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusXLarge = 32;
  static const double radiusPill = 9999;

  static const BorderRadius brSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius brMedium = BorderRadius.all(Radius.circular(16));
  static const BorderRadius brLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius brXLarge = BorderRadius.all(Radius.circular(32));
  static const BorderRadius brPill =
      BorderRadius.all(Radius.circular(9999));

  // ── BORDER WIDTHS ─────────────────────────────────────────────────
  static const double borderThin = 1;
  static const double borderRegular = 2;
  static const double borderThick = 3;
  static const double borderHero = 4;

  // ── ICON SIZES ────────────────────────────────────────────────────
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;

  // ── DAS GROSSE ZIEL: Aliase fuer schnellen Zugriff ────────────────
  // 'final' statt 'const' weil die Subklassen Methoden/Getter haben.
  static final LumoColors colors = const LumoColors._();
  static final LumoShadows shadows = const LumoShadows._();
  static final LumoMotion motion = const LumoMotion._();
  static final LumoTypography typo = const LumoTypography._();
}
