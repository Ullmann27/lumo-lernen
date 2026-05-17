import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'game_level_model.dart';

class LumoLevelMap extends StatelessWidget {
  const LumoLevelMap({super.key, required this.levels});

  final List<GameLevelModel> levels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final itemWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: levels
              .map((level) => SizedBox(
                    width: itemWidth,
                    child: _LevelCard(level: level),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final GameLevelModel level;

  @override
  Widget build(BuildContext context) {
    final locked = !level.unlocked;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: lumoCard(
        color: locked ? const Color(0xFFF8F6F3) : Colors.white,
        border: Border.all(
          color: locked ? LumoColors.ink100 : LumoColors.orange.withOpacity(.22),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: locked ? LumoColors.ink100 : LumoColors.orangeSurface,
                  borderRadius: BorderRadius.circular(LumoRadius.sm),
                ),
                child: Center(
                  child: Text(
                    '${level.number}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: locked ? LumoColors.ink500 : LumoColors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  level.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LumoTextStyles.heading3.copyWith(color: locked ? LumoColors.ink500 : LumoColors.ink900),
                ),
              ),
              Icon(locked ? Icons.lock_rounded : Icons.play_arrow_rounded, color: locked ? LumoColors.ink300 : LumoColors.orange),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            level.subtitle,
            style: LumoTextStyles.body.copyWith(color: locked ? LumoColors.ink400 : LumoColors.ink700),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (index) {
              final filled = index < level.stars;
              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
                child: Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: filled ? LumoColors.gold : LumoColors.ink100,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
