import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';

/// Level- und Belohnungs-Streifen nach Referenzbild.
///
/// Aufbau:
///   - "Level 3"-Badge mit hexagonaler Marke
///   - animierter Fortschrittsbalken in Orange
///   - aktueller XP-Stand (840 / 1200 XP)
///   - rechts: Schatzkisten-Icon + "Naechste Belohnung\nNoch 360 XP"
class LumoLevelStrip extends StatelessWidget {
  const LumoLevelStrip({
    super.key,
    required this.level,
    required this.currentXp,
    required this.xpForNextLevel,
    this.accent = LumoColors.orange,
  });

  final int level;
  final int currentXp;
  final int xpForNextLevel;
  final Color accent;

  double get _progress =>
      (currentXp / xpForNextLevel).clamp(0.0, 1.0).toDouble();

  int get _remainingXp =>
      (xpForNextLevel - currentXp).clamp(0, xpForNextLevel).toInt();

  @override
  Widget build(BuildContext context) {
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
          // Level label and hexagon
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Level',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: LumoColors.ink500,
                ),
              ),
              Text(
                '$level',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.ink900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Hexagonal level badge
          Container(
            width: 38,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LumoColors.gold, LumoColors.goldLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: LumoColors.gold.withOpacity(0.40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$level',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar + xp count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFFFEFE0),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentXp / $xpForNextLevel XP',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: LumoColors.ink500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Reward chest
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🎁', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nächste Belohnung',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: LumoColors.ink700,
                    ),
                  ),
                  Text(
                    'Noch $_remainingXp XP',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: LumoColors.ink500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
