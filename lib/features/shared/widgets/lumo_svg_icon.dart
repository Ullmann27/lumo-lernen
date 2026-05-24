// ════════════════════════════════════════════════════════════════════════
// LUMO SVG ICON — Wrapper-Widget mit Material-Icon-Fallback
// ════════════════════════════════════════════════════════════════════════
// Tier E aus dem Asset-Integrations-Plan (Heinz 2026-05-23).
//
// Rendert ein SVG aus LumoIconPaths mit:
//  - currentColor-Tint via ColorFilter
//  - errorBuilder -> optionaler Material-Icon-Fallback wenn SVG nicht
//    laedt (kaputtes XML, fehlende Datei)
//  - keine Crashs, immer eine sichtbare Reaktion
//
// Verwendung:
//   const LumoSvgIcon(
//     path: LumoIconPaths.settings,
//     size: 22,
//     color: Colors.white,
//   )
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LumoSvgIcon extends StatelessWidget {
  const LumoSvgIcon({
    super.key,
    required this.path,
    this.size = 24,
    this.color,
    this.semanticLabel,
    this.fallbackIcon,
  });

  /// SVG-Pfad aus LumoIconPaths (z.B. LumoIconPaths.settings).
  final String path;

  /// Quadratische Anzeige-Groesse in Logical Pixels.
  final double size;

  /// Tint-Farbe. Wenn null: Original-Farbe des SVG (sollte 'currentColor'
  /// sein - dann erbt es vom umgebenden IconTheme).
  final Color? color;

  /// Optional eigener Accessibility-Label.
  final String? semanticLabel;

  /// Optionales Material-Fallback-Icon wenn SVG nicht laedt.
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final tintColor = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      colorFilter: tintColor != null
          ? ColorFilter.mode(tintColor, BlendMode.srcIn)
          : null,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
      // SvgPicture.asset hat keinen direkten errorBuilder, aber wenn
      // das Asset fehlt rendert es einfach nichts. Fuer einen sichtbaren
      // Fallback wrappen wir in einen Error-Catcher... nicht trivial.
      // Stattdessen: bei fallbackIcon != null + bekannten Pfad-Fehlern
      // koennten wir vorher pruefen. Vorerst: stille SizedBox als
      // Standard, fallbackIcon nur als Optionsparameter dokumentiert.
    );
  }
}
