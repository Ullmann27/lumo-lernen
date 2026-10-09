import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/progress_repository.dart';
import '../../../theme/lumo_visual_tokens.dart';

/// Kein Belohnungszähler: nur echte, gespeicherte Lernantworten.
class LumoTreeProgress {
  LumoTreeProgress(Map<String, SkillRecord> skills)
      : records = (skills.values.where((s) => s.attempts > 0).toList()
          ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen)));

  final List<SkillRecord> records;
  int get practiced => records.length;
  int get mastered => records.where(isMastered).length;
  int get needsPractice => records.where(needsReview).length;
  int get attempts => records.fold(0, (int n, SkillRecord s) => n + s.attempts);
  int get stageIndex => practiced == 0 ? 0
      : mastered >= 4 ? 3 : mastered >= 1 || practiced >= 5 ? 2 : 1;
  List<SkillRecord> get visibleSkills =>
      records.take(10).toList(growable: false);
  String get paintSignature => visibleSkills.map((r) =>
      r.skillId.toString() + ':' + r.correct.toString() + ':' +
      r.wrong.toString() + ':' + r.currentStreak.toString() + ':' +
      r.currentMisses.toString()).join('|');

  static bool isMastered(SkillRecord r) =>
      r.currentStreak >= 5 && r.mastery >= 75;
  static bool needsReview(SkillRecord r) =>
      r.currentMisses >= 3 ||
      (r.attempts >= 3 && r.weaknessScore >= 0.5);
  static String status(SkillRecord r) =>
      isMastered(r) ? 'Sicher geübt' : needsReview(r) ? 'Noch üben' : 'Im Aufbau';

  String get stage => practiced == 0
      ? 'Dein erster Keimling'
      : mastered >= 5
          ? 'Dein Baum blüht!'
          : mastered >= 2 ? 'Neue Zweige wachsen' : 'Dein Lernbaum wächst';
}

/// Ergänzende Kompetenzkarte in den vorhandenen Lernseiten; Fold = 2 Spalten.
class LumoLearningTreeCard extends StatelessWidget {
  const LumoLearningTreeCard({
    super.key, required this.skills, this.onOpenWorld, this.compact = false,
  });
  final Map<String, SkillRecord> skills;
  final VoidCallback? onOpenWorld;
  final bool compact;
  static const cyan = Color(0xFF4DDEFF);
  static const green = Color(0xFF56E4AF);
  static const gold = Color(0xFFFFD36A);

  @override
  Widget build(BuildContext context) {
    final progress = LumoTreeProgress(skills);
    return Container(
      key: const ValueKey('lumo-learning-tree'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xF20E3A75), Color(0xF7081E46), Color(0xF00A345C)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cyan.withValues(alpha: .65), width: 1.4),
        boxShadow: [
          BoxShadow(color: cyan.withValues(alpha: .2), blurRadius: 24),
          const BoxShadow(color: Color(0x55000000), blurRadius: 22,
              offset: Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF1A8DAC), Color(0xFF1254A1),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cyan.withValues(alpha: .7)),
            ),
            child: const Icon(Icons.park_rounded, color: green, size: 28),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mein Lernbaum', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 19,
                fontWeight: FontWeight.w900, color: Colors.white)),
              Text(progress.stage, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Nunito',
                  fontSize: 12, fontWeight: FontWeight.w800, color: cyan)),
            ],
          )),
          if (onOpenWorld != null)
            IconButton(
              key: const ValueKey('lumo-tree-open-world'),
              tooltip: 'Lernwelt öffnen',
              onPressed: onOpenWorld,
              icon: const Icon(Icons.open_in_new_rounded, color: cyan),
            ),
        ]),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          final picture = _LearningTreeWorldArt(
            progress: progress, compact: compact, wide: wide,
          );
          final details = _details(progress);
          if (wide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(flex: 5, child: picture),
              const SizedBox(width: 14),
              Expanded(flex: 6, child: details),
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            picture, const SizedBox(height: 6), details,
          ]);
        }),
        const SizedBox(height: 7),
        const Text('Jeder Leuchtpunkt entspricht einem wirklich geübten Thema '
             '(maximal 10 sichtbar). Der Baum wächst durch echte Lernantworten.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 10.5,
              height: 1.35, fontWeight: FontWeight.w700,
              color: LumoVisualTokens.muted)),
      ]),
    );
  }

  Widget _details(LumoTreeProgress p) {
    final recent = p.records.take(compact ? 3 : 6);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        _counter(Icons.school_rounded, p.practiced, 'Themen', cyan,
            'lumo-tree-practiced'),
        _counter(Icons.verified_rounded, p.mastered, 'Sicher', green,
            'lumo-tree-mastered'),
        _counter(Icons.replay_circle_filled_rounded, p.needsPractice, 'Üben',
            const Color(0xFFF8A4CE), 'lumo-tree-review'),
      ]),
      const SizedBox(height: 12),
      if (p.records.isEmpty)
        const Text('Noch kein Thema gespeichert. Starte eine Lernaufgabe – '
          'dann wächst der erste Zweig.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w800, height: 1.3,
            color: Colors.white)),
      for (final record in recent)
        Padding(padding: const EdgeInsets.only(bottom: 7),
          child: _SkillRow(record: record)),
    ]);
  }

  Widget _counter(IconData icon, int value, String label, Color color,
      String keyName) => Container(
    key: ValueKey(keyName),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xC2062047),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .5)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 3),
      Text(value.toString() + ' ' + label, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 10.5, fontWeight: FontWeight.w900,
        color: Colors.white)),
    ]),
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.record});
  final SkillRecord record;

  @override
  Widget build(BuildContext context) {
    final mastered = LumoTreeProgress.isMastered(record);
    final review = LumoTreeProgress.needsReview(record);
    final color = mastered
        ? const Color(0xFF56E4AF)
        : review ? const Color(0xFFF8A4CE) : const Color(0xFF4DDEFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xC0062047),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(children: [
        Icon(mastered ? Icons.verified_rounded
                : review ? Icons.refresh_rounded : Icons.auto_awesome_rounded,
          color: color, size: 19),
        const SizedBox(width: 7),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.unit, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                color: Colors.white, fontWeight: FontWeight.w900)),
            Text(record.subject + ' · ' + record.correct.toString() +
                    '/' + record.attempts.toString() + ' richtig',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 10,
                color: LumoVisualTokens.muted, fontWeight: FontWeight.w700)),
          ])),
        const SizedBox(width: 4),
        Text(LumoTreeProgress.status(record), style: TextStyle(
          fontFamily: 'Nunito', fontSize: 10,
          color: color, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

/// Four separately rendered 3D stages plus live, truthful competence overlays.
class _LearningTreeWorldArt extends StatelessWidget {
  const _LearningTreeWorldArt({
    required this.progress, required this.compact, required this.wide,
  });
  final LumoTreeProgress progress;
  final bool compact;
  final bool wide;
  static const _points = <Offset>[
    Offset(.37, .35), Offset(.53, .30), Offset(.65, .38),
    Offset(.34, .46), Offset(.62, .47), Offset(.47, .41),
    Offset(.54, .53), Offset(.27, .43), Offset(.70, .42),
    Offset(.44, .26),
  ];

  @override
  Widget build(BuildContext context) {
    final height = wide ? 290.0 : (compact ? 246.0 : 310.0);
    final resource = 'assets/lumo_design/learning_world/'
        'learning_tree_stage_' + progress.stageIndex.toString() + '.png';
    final a11y = 'Lernbaum: ' + progress.practiced.toString() +
        ' Themen begonnen, ' + progress.mastered.toString() +
        ' sicher geübt, ' + progress.needsPractice.toString() +
        ' zum Wiederholen. ' + progress.visibleSkills.length.toString() +
        ' unterschiedliche Leuchtpunkte sichtbar.';
    return Semantics(
      label: a11y,
      child: ExcludeSemantics(child: SizedBox(
        height: height,
        child: Center(child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, c) {
            final dim = c.biggest.shortestSide;
            return Stack(fit: StackFit.expand, children: [
              DecoratedBox(decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0x663DCFC8), Color(0x27267DAF), Color(0x00081B40)
                  ], stops: [0, .60, 1],
                ),
                borderRadius: BorderRadius.circular(24),
              )),
              Image.asset(
                resource,
                key: const ValueKey('lumo-tree-3d-image'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                // Visible fallback until the real 3D art decodes.
                frameBuilder: (context, child, frame, synchronous) =>
                    frame == null && !synchronous
                        ? CustomPaint(painter: _TreePainter(progress))
                        : child,
                errorBuilder: (context, error, stackTrace) =>
                    CustomPaint(painter: _TreePainter(progress)),
              ),
              for (var i = 0; i < progress.visibleSkills.length; i++)
                Positioned(
                  left: dim * _points[i].dx - 11,
                  top: dim * _points[i].dy - 11,
                  child: _TreeSkillBeacon(
                    index: i, record: progress.visibleSkills[i],
                  ),
                ),
            ]);
          }),
        )),
      )),
    );
  }
}

class _TreeSkillBeacon extends StatelessWidget {
  const _TreeSkillBeacon({required this.index, required this.record});
  final int index;
  final SkillRecord record;

  @override
  Widget build(BuildContext context) {
    final mastered = LumoTreeProgress.isMastered(record);
    final review = LumoTreeProgress.needsReview(record);
    final glow = mastered ? const Color(0xFFFFE38B)
        : review ? const Color(0xFFF4A7CE) : const Color(0xFF6EFFE4);
    return Tooltip(
      message: record.subject + ': ' + record.unit + ' – ' +
          LumoTreeProgress.status(record),
      child: Container(
        key: ValueKey('lumo-tree-skill-node-' + index.toString()),
        width: 22, height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            Colors.white, glow, glow.withValues(alpha: .22),
          ], stops: const [0, .3, 1]),
          border: Border.all(color: glow.withValues(alpha: .78)),
          boxShadow: [BoxShadow(
            color: glow.withValues(alpha: .88),
            blurRadius: 15, spreadRadius: 3,
          )],
        ),
        child: Center(child: Icon(
          mastered ? Icons.star_rounded
              : review ? Icons.refresh_rounded : Icons.circle,
          size: mastered ? 11 : 7,
          color: const Color(0xFF103057),
        )),
      ),
    );
  }
}

/// Skalierbarer 2,5D-Baum: Leuchtblätter aus realen Skill-Daten statt
/// eingebrannter Bilder mit falschen Fortschrittszahlen.
class _TreePainter extends CustomPainter {
  const _TreePainter(this.progress);
  final LumoTreeProgress progress;
  static const leaves = <Offset>[
    Offset(104, 101), Offset(138, 61), Offset(181, 39),
    Offset(222, 66), Offset(252, 103), Offset(96, 73),
    Offset(149, 97), Offset(203, 95), Offset(248, 60),
    Offset(124, 128), Offset(222, 130), Offset(179, 117),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 350, size.height / 218);
    canvas.drawOval(
      const Rect.fromLTWH(25, -8, 300, 210),
      Paint()..shader = const RadialGradient(colors: [
        Color(0x8842DFFF), Color(0x2242DFFF), Color(0x0042DFFF)
      ]).createShader(const Rect.fromLTWH(25, -8, 300, 210)),
    );
    for (var i = 0; i < 20; i++) {
      canvas.drawCircle(Offset(((i * 71 + 23) % 340).toDouble() + 5,
        ((i * 39 + 12) % 167).toDouble()), i.isEven ? 1.7 : 1,
        Paint()..color = i % 3 == 0
          ? const Color(0xFFFFD883) : const Color(0xFF9DEAFF));
    }
    final rock = Path()
      ..moveTo(73, 180)
      ..quadraticBezierTo(176, 151, 282, 179)
      ..lineTo(258, 190)..lineTo(206, 215)
      ..lineTo(156, 211)..lineTo(96, 194)..close();
    canvas.drawPath(rock, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF69DAF5), Color(0xFF264B91), Color(0xFF171E53)],
    ).createShader(const Rect.fromLTWH(70, 164, 215, 52)));
    canvas.drawOval(const Rect.fromLTWH(65, 162, 224, 31),
      Paint()..shader = const LinearGradient(colors: [
        Color(0xFF1A957B), Color(0xFF57DD87), Color(0xFF217B6A)
      ]).createShader(const Rect.fromLTWH(65, 161, 225, 35)));
    final trunk = Path()
      ..moveTo(169, 169)..cubicTo(172, 144, 162, 115, 166, 94)
      ..cubicTo(168, 70, 182, 67, 190, 76)
      ..cubicTo(179, 111, 187, 148, 191, 171)..close();
    canvas.drawPath(trunk, Paint()..shader = const LinearGradient(colors: [
      Color(0xFFB97B56), Color(0xFF643A54), Color(0xFF9C654D)
    ]).createShader(const Rect.fromLTWH(155, 76, 40, 103)));
    void branch(Offset from, Offset to, double width) {
      final p = Path()..moveTo(from.dx, from.dy)
        ..quadraticBezierTo((from.dx + to.dx) / 2, to.dy + 15,
            to.dx, to.dy);
      canvas.drawPath(p, Paint()
        ..color = const Color(0xFF8B6254)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);
    }
    branch(const Offset(175, 106), const Offset(123, 78), 8);
    branch(const Offset(179, 117), const Offset(233, 82), 8);
    branch(const Offset(177, 89), const Offset(170, 56), 7);
    branch(const Offset(175, 133), const Offset(106, 116), 5);
    branch(const Offset(187, 138), const Offset(249, 119), 5);

    final count = progress.practiced == 0
        ? 2 : math.min(leaves.length, 3 + progress.practiced);
    for (var i = 0; i < count; i++) {
      final r = progress.records.isEmpty
          ? null : progress.records[i % progress.records.length];
      final color = r == null ? const Color(0xFF3C9A80)
          : LumoTreeProgress.isMastered(r) ? const Color(0xFFFFD36A)
          : LumoTreeProgress.needsReview(r) ? const Color(0xFFF3A3D1)
          : const Color(0xFF42DDBE);
      final p = leaves[i];
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate((i.isEven ? 1 : -1) * .15);
      final mastered = r != null && LumoTreeProgress.isMastered(r);
      final review = r != null && LumoTreeProgress.needsReview(r);
      // Mehrlagige Blätterbüschel statt einzelner schematischer Ellipsen.
      // Wachstum orientiert sich an echten Lernversuchen.
      final leafCount = r == null
          ? 3 : math.min(9, 4 + (r.attempts ~/ 2));
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 53, height: 44),
        Paint()
          ..color = color.withValues(alpha: mastered ? .40 : .24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      for (var k = 0; k < leafCount; k++) {
        final angle = 2 * math.pi * k / leafCount;
        final dx = math.cos(angle) * 12;
        final dy = math.sin(angle) * 9;
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(angle * .33);
        final leafColor = Color.lerp(
          color, k.isEven ? const Color(0xFF75EFCB) : const Color(0xFF157E78),
          k.isEven ? .36 : .24,
        )!;
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 26, height: 19),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(leafColor, Colors.white, .38)!,
                leafColor,
                Color.lerp(leafColor, Colors.black, .33)!,
              ],
            ).createShader(const Rect.fromLTWH(-13, -10, 26, 20)),
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(-3, -4), width: 7, height: 3),
          Paint()..color = Colors.white.withValues(alpha: .34),
        );
        canvas.restore();
      }
      // Der Kern markiert die diagnostische Kompetenzstufe.
      if (r != null) {
        canvas.drawCircle(Offset.zero, mastered ? 8 : 5.5,
          Paint()
            ..color = color.withValues(alpha: .60)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        canvas.drawCircle(Offset.zero, mastered ? 5.5 : 3.5,
          Paint()..color = mastered
              ? const Color(0xFFFFF3AB)
              : review ? const Color(0xFFFFB4D9)
                  : const Color(0xFF8CFFF0));
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) =>
      oldDelegate.progress.paintSignature != progress.paintSignature;
}
