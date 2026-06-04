// ════════════════════════════════════════════════════════════════════════
// LUMO ACHIEVEMENTS WALL — Premium Badge-Galerie
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-06-04: 'high end Ideen ausdenken und einbauen'.
//
// Vollbild-Screen mit Hero-Header (Total-Counter + Glow), 3 Tier-Sektionen
// (Bronze/Silber/Gold), animierte Badge-Karten, Progress-Ring an noch-
// nicht-freigeschalteten Badges, lockig wenn gesperrt.

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/achievements/achievement_tracker.dart';
import '../../core/achievements/lumo_achievement.dart';
import '../../widgets/premium/lumo_magic_background.dart';

class AchievementsWallScreen extends StatefulWidget {
  const AchievementsWallScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<AchievementsWallScreen> createState() => _AchievementsWallScreenState();
}

class _AchievementsWallScreenState extends State<AchievementsWallScreen> {
  final AchievementTracker _tracker = AchievementTracker.instance;

  @override
  void initState() {
    super.initState();
    _tracker.hydrate();
    _tracker.addListener(_onTrackerUpdate);
  }

  @override
  void dispose() {
    _tracker.removeListener(_onTrackerUpdate);
    super.dispose();
  }

  void _onTrackerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = _tracker.progressList();
    final unlockedCount = progress.where((p) => p.unlocked).length;
    final total = progress.length;
    final byTier = <AchievementTier, List<LumoAchievementProgress>>{
      AchievementTier.bronze:
          progress.where((p) => p.achievement.tier == AchievementTier.bronze).toList(),
      AchievementTier.silver:
          progress.where((p) => p.achievement.tier == AchievementTier.silver).toList(),
      AchievementTier.gold:
          progress.where((p) => p.achievement.tier == AchievementTier.gold).toList(),
    };
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF7C2D12)),
        title: const Text(
          '🏆 Achievements',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C2D12),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: LumoMagicBackground(
        intensity: 1.0,
        starCount: 24,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 32),
          children: [
            _hero(unlockedCount, total),
            const SizedBox(height: 18),
            _tierSection('🥉 Bronze', byTier[AchievementTier.bronze]!, const Color(0xFFCD7F32)),
            const SizedBox(height: 14),
            _tierSection('🥈 Silber', byTier[AchievementTier.silver]!, const Color(0xFFA8A8A8)),
            const SizedBox(height: 14),
            _tierSection('🥇 Gold', byTier[AchievementTier.gold]!, const Color(0xFFFFD700)),
          ],
        ),
      ),
    );
  }

  Widget _hero(int unlocked, int total) {
    final percent = (unlocked / total * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD166), Color(0xFFFF7A2F), Color(0xFFEF476F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: LumoColors.orange.withOpacity(0.36),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: unlocked / total,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.30),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '$unlocked/$total',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deine Sammlung',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percent% freigeschaltet - sammle weiter!',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierSection(String title, List<LumoAchievementProgress> items, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: accent.withOpacity(0.40), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: accent.withOpacity(0.92),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final p in items) ...[
            _BadgeCard(progress: p, accent: accent),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.progress, required this.accent});
  final LumoAchievementProgress progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.unlocked;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: unlocked ? accent.withOpacity(0.10) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(
          color: unlocked ? accent.withOpacity(0.50) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Emoji-Badge mit Glow wenn unlocked
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: unlocked ? accent.withOpacity(0.20) : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.40),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.35,
              child: Text(
                unlocked ? progress.achievement.emoji : '🔒',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.achievement.title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: unlocked ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progress.achievement.description,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.progressPercent,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            unlocked ? accent : const Color(0xFFFCA5A5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unlocked
                          ? '+${progress.achievement.rewardStars}★'
                          : '${progress.current}/${progress.achievement.target}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: unlocked ? accent : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
