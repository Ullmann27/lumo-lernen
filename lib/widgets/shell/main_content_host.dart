import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';
import '../cards/kpi_card.dart';

class MainContentHost extends StatelessWidget {
  const MainContentHost({
    super.key,
    required this.title,
    required this.body,
    required this.stars,
    required this.xp,
    required this.level,
    required this.progress,
    this.onVoice,
  });

  final String title;
  final Widget body;
  final int stars;
  final int xp;
  final int level;
  final int progress;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 28, 26, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hallo, Lena! 👋', style: LumoTextStyles.headline),
                    SizedBox(height: 5),
                    Text('Bereit für ein neues Lernabenteuer?', style: LumoTextStyles.subtitle),
                  ],
                ),
              ),
              if (onVoice != null) IconButton.filledTonal(onPressed: onVoice, icon: const Icon(Icons.volume_up_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                KpiCard(icon: const Text('⭐', style: TextStyle(fontSize: 31)), label: 'Sterne', value: '$stars /50', accentColor: LumoColors.pinkLavender, progress: (stars / 50).clamp(0, 1).toDouble()),
                const SizedBox(width: 16),
                KpiCard(icon: const Text('🏅', style: TextStyle(fontSize: 31)), label: 'XP Punkte', value: '$xp', accentColor: LumoColors.softGold, progress: .62),
                const SizedBox(width: 16),
                KpiCard(icon: const Text('💎', style: TextStyle(fontSize: 31)), label: 'Level', value: '$level Einsteiger', accentColor: LumoColors.mint, progress: .70),
                const SizedBox(width: 16),
                KpiCard(icon: const Text('🌊', style: TextStyle(fontSize: 31)), label: 'Lernfortschritt', value: '$progress%', accentColor: LumoColors.sky, progress: progress / 100),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: LumoColors.warmText)),
          const SizedBox(height: 15),
          AnimatedSwitcher(
            duration: LumoDurations.normal,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(key: ValueKey(title), child: body),
          ),
        ],
      ),
    );
  }
}
