import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';

class LumoSurfaceCard extends StatelessWidget {
  const LumoSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LumoSpacing.lg),
    this.radius = LumoRadius.card,
    this.color,
    this.shadowColor = LumoColors.brandOrange,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color shadowColor;
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white.withOpacity(.82)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(.76), width: 1),
        boxShadow: LumoShadows.soft(shadowColor),
      ),
      child: child,
    );
  }
}
