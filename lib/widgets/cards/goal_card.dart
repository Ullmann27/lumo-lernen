import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';
import '../common/lumo_surface_card.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completedSteps,
    required this.totalSteps,
    this.rewardIcon,
  });

  final String title;
  final String subtitle;
  final int completedSteps;
  final int totalSteps;
  final Widget? rewardIcon;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps <= 0 ? 1 : totalSteps;
    final safeCompleted = completedSteps.clamp(0, safeTotal);
    return LumoSurfaceCard(
      padding: const EdgeInsets.all(18),
      radius: LumoRadius.bubble,
      color: Colors.white.withOpacity(.74),
      shadowColor: LumoColors.apricot,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: LumoColors.warmText)),
                const SizedBox(height: LumoSpacing.xs),
                Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: LumoColors.mutedText)),
                const SizedBox(height: LumoSpacing.sm),
                Row(
                  children: [
                    for (var i = 0; i < safeTotal; i++) ...[
                      i < safeCompleted
                          ? const Icon(Icons.check_circle_rounded, color: LumoColors.success, size: 24)
                          : CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.white.withOpacity(.84),
                              child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xffb77c46))),
                            ),
                      if (i < safeTotal - 1) const SizedBox(width: LumoSpacing.sm),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: LumoSpacing.md),
          rewardIcon ?? const CircleAvatar(radius: 32, backgroundColor: Color(0xfffff3c7), child: Text('🎁', style: TextStyle(fontSize: 27))),
        ],
      ),
    );
  }
}
