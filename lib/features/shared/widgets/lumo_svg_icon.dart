// ════════════════════════════════════════════════════════════════════════
// LUMO SVG ICON — Wrapper-Widget (Material-Icon-Modus, Build 199+)
// ════════════════════════════════════════════════════════════════════════
// CI-Rescue 2026-05-25: das flutter_svg-Package wurde voruebergehend aus
// pubspec.yaml entfernt (siehe lumo_lottie.dart). Das Widget bleibt
// API-kompatibel - es zeigt nur statt eines SVG einen Material-Fallback-
// Icon (oder Icons.help_outline wenn kein Fallback gesetzt ist).
//
// Aufrufstellen die bisher 'svgPath: LumoIconPaths.xyz' uebergeben haben
// koennen schrittweise auf direkte Material-Icons migriert werden, ohne
// dass das Layout bricht.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoSvgIcon extends StatelessWidget {
  const LumoSvgIcon({
    super.key,
    required this.path,
    this.size = 24,
    this.color,
    this.semanticLabel,
    this.fallbackIcon,
  });

  /// Wird im Material-Modus nicht geladen (siehe Datei-Kopf).
  final String path;

  final double size;
  final Color? color;
  final String? semanticLabel;

  /// Optionales Material-Icon. Wenn null: Icons.help_outline.
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final tintColor = color ?? IconTheme.of(context).color;
    return Icon(
      fallbackIcon ?? Icons.help_outline,
      size: size,
      color: tintColor,
      semanticLabel: semanticLabel,
    );
  }
}
