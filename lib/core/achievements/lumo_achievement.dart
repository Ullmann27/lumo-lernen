// ════════════════════════════════════════════════════════════════════════
// LUMO ACHIEVEMENTS — Badge-System
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-06-04: 'mach was du willst in meiner App aber hebe sie bitte ab'.
//
// 14 handkuratierte Achievements als Sammelziele. Pro Achievement:
//   - id (stabil, fuer Persistence)
//   - emoji (Badge-Icon)
//   - title + description (kindgerecht)
//   - target (Schwelle - z.B. 10 Aufgaben gelöst)
//   - rewardStars (was es bei Unlock gibt)
//   - tier (bronze/silber/gold - bestimmt Glow-Farbe)
//
// Tracker-Logik in achievement_tracker.dart.
// Persistence in achievement_repository.dart.

enum AchievementTier { bronze, silver, gold }

enum AchievementMetric {
  totalTasks,
  correctTasks,
  streakDays,
  mathCorrect,
  germanCorrect,
  readingMinutes,
  questsCompleted,
  starsTotal,
  kiQuestions,
  liveSnaps,
  loginsConsecutive,
  perfectMissions,
}

class LumoAchievement {
  const LumoAchievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.rewardStars,
    required this.tier,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
  final AchievementMetric metric;
  final int target;
  final int rewardStars;
  final AchievementTier tier;
}

class LumoAchievementProgress {
  const LumoAchievementProgress({
    required this.achievement,
    required this.current,
    required this.unlocked,
    this.unlockedAt,
  });

  final LumoAchievement achievement;
  final int current;
  final bool unlocked;
  final DateTime? unlockedAt;

  double get progressPercent =>
      (current / achievement.target).clamp(0.0, 1.0);
}

class LumoAchievementCatalog {
  const LumoAchievementCatalog._();

  static const List<LumoAchievement> all = <LumoAchievement>[
    // ─── BRONZE (sofort erreichbar) ─────────────────────────────
    LumoAchievement(
      id: 'first_steps',
      emoji: '👣',
      title: 'Erste Schritte',
      description: 'Loese deine erste Aufgabe.',
      metric: AchievementMetric.totalTasks,
      target: 1,
      rewardStars: 5,
      tier: AchievementTier.bronze,
    ),
    LumoAchievement(
      id: 'ten_tasks',
      emoji: '🎯',
      title: '10er-Knacker',
      description: 'Loese 10 Aufgaben - egal welches Fach.',
      metric: AchievementMetric.totalTasks,
      target: 10,
      rewardStars: 15,
      tier: AchievementTier.bronze,
    ),
    LumoAchievement(
      id: 'first_ki_chat',
      emoji: '🤖',
      title: 'Lumo gefragt',
      description: 'Stelle Lumo deine erste Frage im KI-Chat.',
      metric: AchievementMetric.kiQuestions,
      target: 1,
      rewardStars: 8,
      tier: AchievementTier.bronze,
    ),
    LumoAchievement(
      id: 'login_3days',
      emoji: '📅',
      title: '3-Tage-Helfer',
      description: 'Lerne 3 Tage in Folge.',
      metric: AchievementMetric.loginsConsecutive,
      target: 3,
      rewardStars: 12,
      tier: AchievementTier.bronze,
    ),
    LumoAchievement(
      id: 'live_first',
      emoji: '📸',
      title: 'Lumo LIVE',
      description: 'Fotografiere oder sprich zum ersten Mal mit Lumo LIVE.',
      metric: AchievementMetric.liveSnaps,
      target: 1,
      rewardStars: 10,
      tier: AchievementTier.bronze,
    ),

    // ─── SILVER (Mittelfeld) ────────────────────────────────────
    LumoAchievement(
      id: 'math_master_25',
      emoji: '🧮',
      title: 'Mathe-Meister',
      description: 'Loese 25 Mathe-Aufgaben richtig.',
      metric: AchievementMetric.mathCorrect,
      target: 25,
      rewardStars: 30,
      tier: AchievementTier.silver,
    ),
    LumoAchievement(
      id: 'german_master_25',
      emoji: '📖',
      title: 'Sprach-Profi',
      description: 'Loese 25 Deutsch-Aufgaben richtig.',
      metric: AchievementMetric.germanCorrect,
      target: 25,
      rewardStars: 30,
      tier: AchievementTier.silver,
    ),
    LumoAchievement(
      id: 'streak_7',
      emoji: '🔥',
      title: 'Wochen-Streaker',
      description: '7 Tage Streak. Du bist nicht zu stoppen!',
      metric: AchievementMetric.streakDays,
      target: 7,
      rewardStars: 50,
      tier: AchievementTier.silver,
    ),
    LumoAchievement(
      id: 'first_quest',
      emoji: '⚔️',
      title: 'Quest-Held',
      description: 'Bestehe deine erste Lumo Quest.',
      metric: AchievementMetric.questsCompleted,
      target: 1,
      rewardStars: 25,
      tier: AchievementTier.silver,
    ),
    LumoAchievement(
      id: 'stars_100',
      emoji: '⭐',
      title: '100-Sterne-Sammler',
      description: 'Sammle insgesamt 100 Sterne.',
      metric: AchievementMetric.starsTotal,
      target: 100,
      rewardStars: 25,
      tier: AchievementTier.silver,
    ),

    // ─── GOLD (Endgame) ─────────────────────────────────────────
    LumoAchievement(
      id: 'perfect_mission',
      emoji: '🏆',
      title: 'Perfekte Mission',
      description: 'Beende eine Tages-Mission ohne einen einzigen Fehler.',
      metric: AchievementMetric.perfectMissions,
      target: 1,
      rewardStars: 60,
      tier: AchievementTier.gold,
    ),
    LumoAchievement(
      id: 'streak_30',
      emoji: '👑',
      title: 'Monats-Legende',
      description: '30 Tage Streak. Lumo ist stolz auf dich!',
      metric: AchievementMetric.streakDays,
      target: 30,
      rewardStars: 150,
      tier: AchievementTier.gold,
    ),
    LumoAchievement(
      id: 'all_quests',
      emoji: '🦊',
      title: 'Quest-Champion',
      description: 'Bestehe alle 4 Lumo Quests deiner Klasse.',
      metric: AchievementMetric.questsCompleted,
      target: 4,
      rewardStars: 100,
      tier: AchievementTier.gold,
    ),
    LumoAchievement(
      id: 'stars_500',
      emoji: '🌟',
      title: '500-Sterne-Galaxie',
      description: 'Sammle insgesamt 500 Sterne.',
      metric: AchievementMetric.starsTotal,
      target: 500,
      rewardStars: 100,
      tier: AchievementTier.gold,
    ),
  ];

  static LumoAchievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static List<LumoAchievement> ofTier(AchievementTier tier) =>
      all.where((a) => a.tier == tier).toList(growable: false);
}
