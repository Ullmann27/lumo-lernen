import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Compact statistic pill for stars, streaks, XP and small dashboard counters.
class LumoStatPill extends StatelessWidget {
  const LumoStatPill({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconEmoji,
    this.color = LumoColors.gold,
    this.backgroundColor,
  });

  final String value;
  final String label;
  final IconData? icon;
  final String? iconEmoji;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(.88),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: Colors.white.withOpacity(.78), width: 1.1),
        boxShadow: LumoShadow.card,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        _StatIcon(icon: icon, emoji: iconEmoji, color: color),
        const SizedBox(width: 9),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: LumoColors.ink500,
              height: 1,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatIcon extends StatelessWidget {
  const _StatIcon({this.icon, this.emoji, required this.color});

  final IconData? icon;
  final String? emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withOpacity(.20), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 20))
          : Icon(icon ?? Icons.star_rounded, color: color, size: 22),
    );
  }
}
