import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../widgets/lumo/lumo_design_kit.dart';

/// Soft, warm base card used by the modern Lumo learning surfaces.
///
/// This widget is intentionally presentation-only: no navigation, no app state,
/// no learning logic and no network calls.
///
/// **Polish-Runde:** Standardwerte uebernehmen Figma-Tokens
/// (LumoKit.radiusLg, LumoKit.softCard). API ist rueckwaertskompatibel —
/// alle bestehenden Aufrufer funktionieren weiter.
class LumoModernCard extends StatelessWidget {
  const LumoModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = LumoRadius.xl,
    this.shadows,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // Polish: Default-Border nur noch sehr dezent (Figma cards haben
    // keine sichtbare Border, nur soft shadow). Wenn `borderColor`
    // explizit gesetzt ist, respektieren wir das.
    final useBorder = borderColor != null;
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color ?? Colors.white : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: useBorder
            ? Border.all(color: borderColor!, width: 1.2)
            : null,
        // Polish: softer shadow per Figma spec (alpha 0.08, y 4, blur 12)
        // statt der alten LumoShadow.card (warmer aber lauter).
        boxShadow: shadows ?? LumoKit.softCard,
      ),
      child: child,
    );
  }
}
