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
          final picture = Semantics(
            label: 'Lernbaum: ' + progress.practiced.toString() +
                ' Themen begonnen, ' + progress.mastered.toString() +
                ' sicher geübt, ' + progress.needsPractice.toString() +
                ' zum Wiederholen.',
            child: ExcludeSemantics(child: SizedBox(
              height: wide ? 220 : (compact ? 162 : 206),
              width: double.infinity,
              child: CustomPaint(painter: _TreePainter(progress)),
            )),
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
        const Text('Jedes Blatt steht für ein wirklich geübtes Thema. '
            'Die Einschätzung stammt aus Lernantworten auf diesem Gerät.',
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
      canvas.rotate((i.isEven ? 1 : -1) * .38);
      canvas.drawOval(const Rect.fromCenter(
          center: Offset.zero, width: 40, height: 25),
        Paint()..color = color.withValues(alpha: .27)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13));
      canvas.drawOval(const Rect.fromCenter(
          center: Offset.zero, width: 29, height: 16),
        Paint()..shader = LinearGradient(colors: [
          Color.lerp(color, Colors.white, .35)!,
          color, Color.lerp(color, Colors.black, .2)!
        ]).createShader(const Rect.fromLTWH(-15, -8, 30, 16)));
      canvas.drawLine(const Offset(-9, 0), const Offset(9, 0),
        Paint()..color = Colors.white.withValues(alpha: .4)..strokeWidth = 1);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) =>
      oldDelegate.progress.practiced != progress.practiced ||
      oldDelegate.progress.mastered != progress.mastered ||
      oldDelegate.progress.needsPractice != progress.needsPractice ||
      oldDelegate.progress.attempts != progress.attempts;
}
