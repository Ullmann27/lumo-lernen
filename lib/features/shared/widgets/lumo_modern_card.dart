import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Soft, warm base card used by the modern Lumo learning surfaces.
///
/// This widget is intentionally presentation-only: no navigation, no app state,
/// no learning logic and no network calls.
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
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color ?? Colors.white.withOpacity(.86) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(.76),
          width: 1.2,
        ),
        boxShadow: shadows ?? LumoShadow.card,
      ),
      child: child,
    );
  }
}
