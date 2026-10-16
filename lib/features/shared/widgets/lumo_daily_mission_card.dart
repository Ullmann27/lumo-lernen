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
    final progress = progressTotal > 0 ? (progressDone / progressTotal).clamp(0.0, 1.0).toDouble() : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth.isFinite && constraints.maxWidth < 500;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                accent.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.20), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.65),
                blurRadius: 6,
                offset: const Offset(-2, -2),
                spreadRadius: -2,
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MissionMain(title: title, subtitle: subtitle, progressDone: progressDone, progressTotal: progressTotal, progress: progress, accent: accent),
                    const SizedBox(height: 10),
                    _RewardsRow(rewardStars: rewardStars, rewardXp: rewardXp),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _MissionMain(title: title, subtitle: subtitle, progressDone: progressDone, progressTotal: progressTotal, progress: progress, accent: accent)),
                    const SizedBox(width: 10),
                    _RewardsColumn(rewardStars: rewardStars, rewardXp: rewardXp),
                  ],
                ),
        );
      },
    );
  }
}

class _MissionMain extends StatelessWidget {
  const _MissionMain({required this.title, required this.subtitle, required this.progressDone, required this.progressTotal, required this.progress, required this.accent});

  final String title;
  final String subtitle;
  final int progressDone;
  final int progressTotal;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7A2F).withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🎯',
              style: TextStyle(fontSize: 26, height: 1.0),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.ink900,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: accent.withOpacity(0.30), width: 1.0),
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
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFFFEFE0),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardsColumn extends StatelessWidget {
  const _RewardsColumn({required this.rewardStars, required this.rewardXp});
  final int rewardStars;
  final int rewardXp;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _RewardChip(icon: '⭐', label: '+$rewardStars', color: LumoColors.gold),
      const SizedBox(height: 4),
      _RewardChip(icon: 'XP', label: '+$rewardXp', color: LumoColors.blue, isText: true),
    ]);
  }
}

class _RewardsRow extends StatelessWidget {
  const _RewardsRow({required this.rewardStars, required this.rewardXp});
  final int rewardStars;
  final int rewardXp;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 6, children: [
      _RewardChip(icon: '⭐', label: '+$rewardStars', color: LumoColors.gold),
      _RewardChip(icon: 'XP', label: '+$rewardXp', color: LumoColors.blue, isText: true),
    ]);
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.icon, required this.label, required this.color, this.isText = false});
  final String icon;
  final String label;
  final Color color;
  final bool isText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isText)
            Text(icon, style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w900, color: color))
          else
            Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
