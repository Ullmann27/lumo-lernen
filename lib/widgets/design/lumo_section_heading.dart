import 'package:flutter/material.dart';
import '../../theme/lumo_visual_tokens.dart';

/// One chapter hierarchy for learning, games, stories and the parent area.
/// This widget is display-only: existing actions, progress and storage stay put.
class LumoSectionHeading extends StatelessWidget {
  const LumoSectionHeading({super.key, required this.title, required this.icon,
    this.subtitle, this.accent = LumoVisualTokens.cyanBright,
    this.padding = EdgeInsets.zero});

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Semantics(
      header: true,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        ExcludeSemantics(child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(colors: [
              accent.withValues(alpha: .30), accent.withValues(alpha: .09),
            ]),
            border: Border.all(color: accent.withValues(alpha: .65)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: .14),
              blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Icon(icon, size: 24, color: accent),
        )),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, softWrap: true, style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 19, fontWeight: FontWeight.w900,
              height: 1.12, color: LumoVisualTokens.white)),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(subtitle!, softWrap: true, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12.5,
                fontWeight: FontWeight.w700, height: 1.32,
                color: LumoVisualTokens.muted)),
            ],
          ],
        )),
      ]),
    ),
  );
}
