import 'package:flutter/material.dart';
import '../core/school_exercise_generator.dart';
import '../features/shared/widgets/lumo_premium_effects.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  LUMO LERNEN — ProfileScreen
//  Zeigt: Hero-Card, Stats, Fach-Fortschritt, Test-Note,
//         Übungs-Schwächen, Achievements
// ═══════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.stars,
    required this.xp,
    required this.level,
    required this.progress,
    required this.solved,
    required this.practice,
    required this.lastGrade,
    required this.childName,
  });

  final String childName;
  final int stars;
  final int xp;
  final int level;
  final int progress;
  final Map<String, int> solved;
  final Map<String, int> practice;
  final int lastGrade;

  int get _totalSolved => solved.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileHeroCard(stars: stars, xp: xp, level: level, totalSolved: _totalSolved, childName: childName),
        const SizedBox(height: 18),

        // ── Stats ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _MiniStatCard(label: 'Sterne', value: '$stars / 50', emoji: '⭐',
                color: const Color(0xffb455f6), percent: stars / 50),
            const SizedBox(width: 12),
            _MiniStatCard(label: 'XP Punkte', value: '$xp XP', emoji: '🏅',
                color: const Color(0xffffb000), percent: ((xp % 1000) / 1000).clamp(0.0, 1.0)),
            const SizedBox(width: 12),
            _MiniStatCard(label: 'Level', value: 'Level $level', emoji: '💎',
                color: const Color(0xff12bfa6), percent: ((level - 1) % 5) / 5),
            const SizedBox(width: 12),
            _MiniStatCard(label: 'Fortschritt', value: '$progress %', emoji: '📈',
                color: const Color(0xff3b8dff), percent: progress / 100),
          ]),
        ),
        const SizedBox(height: 24),

        // ── Fach-Fortschritt ──
        _SectionTitle(title: 'Fach-Fortschritt 📚', subtitle: '$_totalSolved Aufgaben gelöst'),
        const SizedBox(height: 10),
        _SubjectProgressBars(solved: solved),
        const SizedBox(height: 24),

        // ── Letzte Note ──
        const _SectionTitle(title: 'Letzter Test 📝'),
        const SizedBox(height: 10),
        _TestGradeCard(lastGrade: lastGrade),

        // ── Noch üben ──
        if (practice.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Noch üben 💪'),
          const SizedBox(height: 10),
          _PracticeAreasList(practice: practice),
        ],
        const SizedBox(height: 24),

        // ── Achievements ──
        const _SectionTitle(title: 'Erfolge 🏆'),
        const SizedBox(height: 10),
        _AchievementsGrid(stars: stars, xp: xp, totalSolved: _totalSolved),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(subtitle!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff9ca3af))),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile hero card
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.stars,
    required this.xp,
    required this.level,
    required this.totalSolved,
    required this.childName,
  });
  final String childName;
  final int stars;
  final int xp;
  final int level;
  final int totalSolved;

  @override
  Widget build(BuildContext context) {
    // Heinz-Bugfix: Profil-Name war "Lena" hardcoded.
    // Jetzt: echter childName aus App-State (z.B. Alina, Zoe).
    final displayName = childName.trim().isEmpty ? 'Lumo-Freund' : childName.trim();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffffd190), Color(0xffffe2af), Color(0xfffff6e8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(.72), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xffffb96b).withOpacity(.30), blurRadius: 28, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.white.withOpacity(.90), blurRadius: 8, offset: const Offset(-4, -4)),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle - schwebt sanft mit Glow.
          LumoFloating(
            amplitude: 3,
            duration: const Duration(seconds: 3),
            child: LumoGlowPulse(
              color: const Color(0xffff6d00),
              minBlur: 12,
              maxBlur: 26,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xffff9a5c), Color(0xffff6d00)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffff6d00).withOpacity(.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(child: Text('🦊', style: TextStyle(fontSize: 36))),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _LevelBadge(level: level),
                    const _ClassBadge(),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  _MicroStat(emoji: '⭐', value: '$stars'),
                  const SizedBox(width: 14),
                  _MicroStat(emoji: '✅', value: '$totalSolved'),
                  const SizedBox(width: 14),
                  _MicroStat(emoji: '🏅', value: '$xp XP'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xffff7a2f), Color(0xffff9a5c)]),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [BoxShadow(color: const Color(0xffff7a2f).withOpacity(.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text('Level $level Einsteiger',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

class _ClassBadge extends StatelessWidget {
  const _ClassBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.70),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(.80)),
      ),
      child: const Text('Klasse 2',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xff766a61))),
    );
  }
}

class _MicroStat extends StatelessWidget {
  const _MicroStat({required this.emoji, required this.value});
  final String emoji;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 3),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini stat card
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
    required this.percent,
  });
  final String label;
  final String value;
  final String emoji;
  final Color color;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(.76)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.white.withOpacity(.75), blurRadius: 8, offset: const Offset(-3, -3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(99)),
              child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xff2d2621))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 7,
              color: color,
              backgroundColor: color.withOpacity(.13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subject progress bars (grouped by Curriculum)
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectProgressBars extends StatelessWidget {
  const _SubjectProgressBars({required this.solved});
  final Map<String, int> solved;

  static const _subjectMeta = <String, (String, Color)>{
    'Mathematik':      ('🔢', Color(0xffff8700)),
    'Deutsch':         ('📖', Color(0xff8b5cf6)),
    'Englisch':        ('🌍', Color(0xff10a894)),
    'Rechtschreibung': ('✏️', Color(0xffec4899)),
    'Schreiben':       ('🖊️', Color(0xff3b82f6)),
    'Sachkunde':       ('🌿', Color(0xff22c55e)),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Curriculum.subjects.keys.map((subject) {
        final meta = _subjectMeta[subject] ?? ('📚', const Color(0xff6b7280));
        // Sum all solved units that belong to this subject
        final units = Curriculum.subjects[subject] ?? <String>[];
        final count = units.fold<int>(0, (sum, u) => sum + (solved[u] ?? 0));
        final goal = units.length * 3; // rough goal: 3 correct per unit
        final percent = goal > 0 ? (count / goal).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(.76)),
              boxShadow: [
                BoxShadow(color: meta.$2.withOpacity(.10), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.white.withOpacity(.75), blurRadius: 6, offset: const Offset(-2, -2)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: meta.$2.withOpacity(.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(meta.$1, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(subject,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: meta.$2)),
                    Text('$count Aufgaben',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff9ca3af))),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      color: meta.$2,
                      backgroundColor: meta.$2.withOpacity(.13),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test grade card
// ─────────────────────────────────────────────────────────────────────────────
class _TestGradeCard extends StatelessWidget {
  const _TestGradeCard({required this.lastGrade});
  final int lastGrade;

  Color get _color {
    if (lastGrade == 0) return const Color(0xff9ca3af);
    if (lastGrade <= 2) return const Color(0xff10b981);
    if (lastGrade == 3) return const Color(0xffffb800);
    return const Color(0xffef4444);
  }

  String get _label {
    switch (lastGrade) {
      case 0: return 'Noch kein Test';
      case 1: return 'Ausgezeichnet! 🎉';
      case 2: return 'Sehr gut! 🌟';
      case 3: return 'Gut gemacht! 👍';
      case 4: return 'Weiter üben! 💪';
      default: return 'Nicht genügend 📚';
    }
  }

  String get _gradeText => lastGrade == 0 ? '–' : '$lastGrade';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color.withOpacity(.12), _color.withOpacity(.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _color.withOpacity(.28), width: 1.5),
        boxShadow: [BoxShadow(color: _color.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        // Grade badge
        Container(
          width: 66, height: 66,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_color.withOpacity(.28), _color.withOpacity(.12)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _color.withOpacity(.35)),
          ),
          child: Center(
            child: Text(_gradeText,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _color)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_label,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _color)),
            const SizedBox(height: 4),
            Text(
              lastGrade == 0 ? 'Starte deinen ersten Test!' : 'Weiter so – du machst das super!',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff766a61)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Practice areas (weak units)
// ─────────────────────────────────────────────────────────────────────────────
class _PracticeAreasList extends StatelessWidget {
  const _PracticeAreasList({required this.practice});
  final Map<String, int> practice;

  @override
  Widget build(BuildContext context) {
    final sorted = practice.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: top.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xffffe8d6), Color(0xffffd6ba)]),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xffffb96b).withOpacity(.4)),
          boxShadow: [BoxShadow(color: const Color(0xffff8700).withOpacity(.12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('💪', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(e.key,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xffb45309))),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xffff8700).withOpacity(.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('${e.value}×',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xffb45309))),
          ),
        ]),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achievements grid
// ─────────────────────────────────────────────────────────────────────────────
class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.stars, required this.xp, required this.totalSolved});
  final int stars;
  final int xp;
  final int totalSolved;

  static const List<_AchievDef> _all = [
    _AchievDef('Erster Stern',   '⭐', 'Deinen ersten Stern gesammelt',   1,    'stars'),
    _AchievDef('Sternsammler',   '🌟', '10 Sterne gesammelt',              10,   'stars'),
    _AchievDef('Sternenregen',   '🌠', '25 Sterne gesammelt',              25,   'stars'),
    _AchievDef('XP Starter',     '🏅', '100 XP erreicht',                 100,  'xp'),
    _AchievDef('XP Meister',     '🥇', '500 XP erreicht',                 500,  'xp'),
    _AchievDef('XP Legende',     '👑', '1000 XP erreicht',                1000, 'xp'),
    _AchievDef('Fleißige Biene', '✅', 'Erste Aufgabe gelöst',             1,    'solved'),
    _AchievDef('Lernprofi',      '🧠', '10 Aufgaben gelöst',               10,   'solved'),
    _AchievDef('Überflieger',    '🚀', '25 Aufgaben gelöst',               25,   'solved'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _all.map((a) {
        final unlocked = switch (a.type) {
          'stars'  => stars >= a.threshold,
          'xp'     => xp >= a.threshold,
          _        => totalSolved >= a.threshold,
        };
        return _AchievBadge(def: a, unlocked: unlocked);
      }).toList(),
    );
  }
}

class _AchievDef {
  const _AchievDef(this.title, this.emoji, this.desc, this.threshold, this.type);
  final String title;
  final String emoji;
  final String desc;
  final int threshold;
  final String type;
}

class _AchievBadge extends StatelessWidget {
  const _AchievBadge({required this.def, required this.unlocked});
  final _AchievDef def;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white.withOpacity(.90) : Colors.white.withOpacity(.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unlocked
              ? const Color(0xffffb96b).withOpacity(.45)
              : Colors.grey.withOpacity(.18),
          width: 1.2,
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: const Color(0xffffb96b).withOpacity(.22), blurRadius: 16, offset: const Offset(0, 8))]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorFiltered(
            colorFilter: unlocked
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      0.35, 0,
                  ]),
            child: Text(def.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            def.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: unlocked ? const Color(0xff2d2621) : const Color(0xffbbbbbb),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            def.desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: unlocked ? const Color(0xff766a61) : const Color(0xffcccccc),
            ),
          ),
          if (!unlocked) ...[
            const SizedBox(height: 5),
            Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade400),
          ],
        ],
      ),
    );
  }
}
