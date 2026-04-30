import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';

/// Tagesmissions-Karte nach Referenzbild.
class LumoDailyMissionCard extends StatelessWidget {
  const LumoDailyMissionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progressDone,
    required this.progressTotal,
    required this.rewardStars,
    required this.rewardXp,
    this.accent = LumoColors.orange,
  });

  final String title;
  final String subtitle;
  final int progressDone;
  final int progressTotal;
  final int rewardStars;
  final int rewardXp;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = progressTotal > 0
        ? (progressDone / progressTotal).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E0CC)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Target icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: LumoColors.ink500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$progressDone / $progressTotal',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFFFEFE0),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Rewards
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RewardChip(
                icon: '⭐',
                label: '+$rewardStars',
                color: LumoColors.gold,
              ),
              const SizedBox(height: 4),
              _RewardChip(
                icon: 'XP',
                label: '+$rewardXp',
                color: LumoColors.blue,
                isText: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isText = false,
  });
  final String icon;
  final String label;
  final Color color;
  final bool isText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isText)
            Text(
              icon,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            )
          else
            Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
