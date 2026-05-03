import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import 'lumo_modern_card.dart';
import 'lumo_stat_pill.dart';

class LumoMissionCard extends StatelessWidget {
  const LumoMissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.progressLabel,
    this.icon,
    this.iconEmoji,
    this.accentColor = LumoColors.orange,
    this.rewardValue = '+10',
    this.rewardLabel = 'Sterne',
    this.rewardIcon = Icons.star_rounded,
    this.rewardColor = LumoColors.gold,
    this.onTap,
  });

  final String title;
  final String description;
  final double progress;
  final String progressLabel;
  final IconData? icon;
  final String? iconEmoji;
  final Color accentColor;
  final String rewardValue;
  final String rewardLabel;
  final IconData rewardIcon;
  final Color rewardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = LumoModernCard(
      padding: const EdgeInsets.all(18),
      child: Row(children: <Widget>[
        _MissionIcon(color: accentColor, icon: icon, emoji: iconEmoji),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.heading3),
            const SizedBox(height: 6),
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: LumoTextStyles.body.copyWith(color: LumoColors.ink600)),
            const SizedBox(height: 12),
            Row(children: <Widget>[
              Expanded(child: LumoMiniProgressBar(progress: progress, color: accentColor)),
              const SizedBox(width: 10),
              Text(progressLabel, style: LumoTextStyles.label.copyWith(color: accentColor)),
            ]),
          ]),
        ),
        const SizedBox(width: 14),
        LumoStatPill(value: rewardValue, label: rewardLabel, icon: rewardIcon, color: rewardColor),
      ]),
    );
    if (onTap == null) return card;
    return Material(type: MaterialType.transparency, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(LumoRadius.xl), child: card));
  }
}

class LumoMiniProgressBar extends StatelessWidget {
  const LumoMiniProgressBar({super.key, required this.progress, this.color = LumoColors.orange, this.height = 8});

  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(LumoRadius.pill),
      child: SizedBox(
        height: height,
        child: Stack(children: <Widget>[
          Container(color: LumoColors.ink100),
          FractionallySizedBox(widthFactor: safeProgress, child: Container(color: color)),
        ]),
      ),
    );
  }
}

class _MissionIcon extends StatelessWidget {
  const _MissionIcon({required this.color, this.icon, this.emoji});

  final Color color;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withOpacity(.14), shape: BoxShape.circle, boxShadow: LumoShadow.hologram(color)),
      child: emoji != null ? Text(emoji!, style: const TextStyle(fontSize: 26)) : Icon(icon ?? Icons.flag_rounded, color: color, size: 28),
    );
  }
}
