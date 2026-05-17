import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import 'game_level_model.dart';
import 'lumo_level_map.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key, required this.appState});

  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    final unlockedLevels = kInitialGameLevels.where((level) => level.unlocked).toList(growable: false);
    final doneLevels = unlockedLevels.where((level) => level.stars >= kMinimumStarsForProgress).length;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        _GamesHeader(childName: appState.state.childName),
        const SizedBox(height: 16),
        _WeekPreviewCard(
          done: doneLevels,
          total: unlockedLevels.isEmpty ? 1 : unlockedLevels.length,
        ),
        const SizedBox(height: 16),
        const LumoLevelMap(levels: kInitialGameLevels),
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
