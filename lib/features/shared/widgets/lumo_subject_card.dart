import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import 'lumo_mission_card.dart';
import 'lumo_modern_card.dart';

class LumoSubjectCard extends StatelessWidget {
  const LumoSubjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.progressLabel,
    required this.accentColor,
    required this.onTap,
    this.emojiAsset,
    this.iconAsset,
    this.backgroundColor,
  });

  final String title;
  final String description;
  final double progress;
  final String progressLabel;
  final Color accentColor;
  final VoidCallback onTap;
  final String? emojiAsset;
  final IconData? iconAsset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LumoRadius.xl),
        child: LumoModernCard(
          color: backgroundColor ?? LumoColors.cardBg,
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 170, maxHeight: 220),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
              Flexible(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Expanded(child: _SubjectText(title: title, description: description, accentColor: accentColor)),
                  const SizedBox(width: 12),
                  LumoAssetPlaceholder(emoji: emojiAsset, icon: iconAsset, color: accentColor),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: <Widget>[
                Expanded(child: LumoMiniProgressBar(progress: progress, color: accentColor)),
                const SizedBox(width: 10),
                Text(progressLabel, style: LumoTextStyles.label.copyWith(color: accentColor)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class LumoAssetPlaceholder extends StatelessWidget {
  const LumoAssetPlaceholder({super.key, this.emoji, this.icon, required this.color, this.size = 88});

  final String? emoji;
  final IconData? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[color.withOpacity(.18), LumoColors.cardBg.withOpacity(.02)]),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: color.withOpacity(.12)),
        boxShadow: LumoShadow.hologram(color),
      ),
      child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: size * .42)) : Icon(icon ?? Icons.auto_awesome_rounded, color: color, size: size * .44),
    );
  }
}

class _SubjectText extends StatelessWidget {
  const _SubjectText({required this.title, required this.description, required this.accentColor});

  final String title;
  final String description;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: LumoTextStyles.heading3.copyWith(color: LumoColors.ink900, height: 1.12)),
      const SizedBox(height: 8),
      Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: LumoTextStyles.body.copyWith(color: LumoColors.ink600, height: 1.28)),
      const SizedBox(height: 10),
      Container(width: 34, height: 4, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(LumoRadius.pill))),
    ]);
  }
}
