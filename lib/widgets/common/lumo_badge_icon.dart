import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';

class LumoBadgeIcon extends StatelessWidget {
  const LumoBadgeIcon({
    super.key,
    required this.icon,
    required this.accentColor,
    this.size = 40,
    this.iconSize = 23,
    this.backgroundColor,
  });

  final IconData icon;
  final Color accentColor;
  final double size;
  final double iconSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: LumoSurfaces.softCard(
        color: backgroundColor ?? Colors.white.withOpacity(.94),
        radius: LumoRadius.small,
        shadowColor: accentColor,
      ),
      child: Icon(icon, color: accentColor, size: iconSize),
    );
  }
}
