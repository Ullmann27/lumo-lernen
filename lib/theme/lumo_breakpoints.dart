// ════════════════════════════════════════════════════════════════════════
// LUMO BREAKPOINTS — Responsive Layout-System
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

enum LumoBreakpoint {
  /// Phone (< 600px)
  compact,

  /// Tablet portrait, large phones landscape (600-840)
  medium,

  /// Tablet landscape, foldables (840+)
  expanded,
}

class LumoBreakpoints {
  LumoBreakpoints._();

  static const double compactMax = 600;
  static const double mediumMax = 840;

  /// Aktueller Breakpoint basierend auf Bildschirm-Breite.
  static LumoBreakpoint of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < compactMax) return LumoBreakpoint.compact;
    if (w < mediumMax) return LumoBreakpoint.medium;
    return LumoBreakpoint.expanded;
  }

  /// Ist Landscape-Orientierung aktiv?
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Kompaktes Phone?
  static bool isCompact(BuildContext context) =>
      of(context) == LumoBreakpoint.compact;

  /// Tablet oder grosses Phone?
  static bool isMedium(BuildContext context) =>
      of(context) == LumoBreakpoint.medium;

  /// Tablet landscape / Foldable?
  static bool isExpanded(BuildContext context) =>
      of(context) == LumoBreakpoint.expanded;

  /// Liefert einen Wert basierend auf Breakpoint.
  /// T mediumValue/expandedValue fallen auf compactValue zurueck wenn null.
  static T value<T>(
    BuildContext context, {
    required T compactValue,
    T? mediumValue,
    T? expandedValue,
  }) {
    switch (of(context)) {
      case LumoBreakpoint.compact:
        return compactValue;
      case LumoBreakpoint.medium:
        return mediumValue ?? compactValue;
      case LumoBreakpoint.expanded:
        return expandedValue ?? mediumValue ?? compactValue;
    }
  }
}
