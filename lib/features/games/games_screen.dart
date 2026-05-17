import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key, required this.appState});

  final LumoAppState appState;
  static const int _minimumStarsForCompletedLevel = 2;
  static const List<_LevelData> _levels = <_LevelData>[
    _LevelData(1, 'Sterne sammeln', 'Mengen bis 10', unlocked: true, stars: 3),
    _LevelData(2, 'Sterne sammeln', 'Plus bis 10', unlocked: true, stars: 2),
    _LevelData(3, 'Rechenhaus bauen', 'Zahlzerlegung', unlocked: true, stars: 1),
    _LevelData(4, 'Zahlenweg', 'Zahlenfolge', unlocked: true, stars: 0),
    _LevelData(5, 'Zahlenweg', 'Plus-Schritte', unlocked: true, stars: 0),
    _LevelData(6, 'Wörterwald', 'Silben erkennen', unlocked: false, stars: 0),
    _LevelData(7, 'Wörterwald', 'Wort-Bild', unlocked: false, stars: 0),
    _LevelData(8, 'Rechenhaus bauen', 'Fehlende Zahl', unlocked: false, stars: 0),
    _LevelData(9, 'Sterne sammeln', 'Minus bis 10', unlocked: false, stars: 0),
    _LevelData(10, 'Lumo-Challenge', 'Gemischt', unlocked: false, stars: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        _GamesHeader(childName: appState.state.childName),
        const SizedBox(height: 16),
        _WeekPreviewCard(
          done: _levels.where((level) => level.unlocked && level.stars >= _minimumStarsForCompletedLevel).length,
          total: _levels.length,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final itemWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _levels
                  .map((level) => SizedBox(
                        width: itemWidth,
                        child: _LevelCard(level: level),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _GamesHeader extends StatelessWidget {
  const _GamesHeader({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    final name = childName.trim().isEmpty ? 'Lumo-Freund' : childName.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: LumoColors.orangeSurface,
              borderRadius: BorderRadius.circular(LumoRadius.lg),
            ),
            child: const Center(
              child: Icon(Icons.sports_esports_rounded, color: LumoColors.orange, size: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lumos Spielewelt', style: LumoTextStyles.heading2),
                const SizedBox(height: 4),
                Text(
                  'Hallo $name! Schaffe Level mit Lumo und sammle Sterne.',
                  style: LumoTextStyles.body.copyWith(color: LumoColors.ink700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPreviewCard extends StatelessWidget {
  const _WeekPreviewCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(color: Colors.white.withOpacity(.94)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wochen-Challenge Vorschau', style: LumoTextStyles.heading3),
          const SizedBox(height: 6),
          Text('Diese Woche: 10 Level · lokal/offline vorbereitet', style: LumoTextStyles.body),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: LumoColors.orange,
              backgroundColor: LumoColors.orange.withOpacity(.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final _LevelData level;

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

class _LevelData {
  const _LevelData(
    this.number,
    this.title,
    this.subtitle, {
    required this.unlocked,
    required this.stars,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool unlocked;
  final int stars;
}
