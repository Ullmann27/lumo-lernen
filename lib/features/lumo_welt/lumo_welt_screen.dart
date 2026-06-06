// ════════════════════════════════════════════════════════════════════════
// LUMO WELT — Drei wachsende Inseln für Math / Deutsch / Sachkunde
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 36: Heinz' Innovations-Plan Schritt 4 von 5. Pro Schul-
// fach eine eigene Insel in einem Ozean, die mit den richtigen Antworten
// des Kindes waechst. Drei Wachstums-Stufen (Saemling → Wachsend →
// Bluehend). Jede Insel hat ein eigenes Theme + Lumo-Bewohner.
//
// Datenquelle: app_state.learningSkills() (vorhandenes SkillRecord-System).
// Sichtbar: pro Subject die Summe correct-Antworten der zugehoerigen Skills.
// Rendering: CustomPainter pro Insel mit Sea-Hintergrund, Insel-Boden,
// Decorations gemäß Wachstums-Stufe.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/progress_repository.dart';
import '../../widgets/premium/lumo_magic_background.dart';

class LumoWeltScreen extends StatelessWidget {
  const LumoWeltScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) {
    final skills = appState.learningSkills();
    final mathTotal = _sumCorrect(skills, 'Mathematik');
    final germanTotal = _sumCorrect(skills, 'Deutsch') +
        _sumCorrect(skills, 'Lesen') +
        _sumCorrect(skills, 'Rechtschreibung') +
        _sumCorrect(skills, 'Schreiben');
    final scienceTotal =
        _sumCorrect(skills, 'Sachunterricht') + _sumCorrect(skills, 'Sachkunde');

    final islands = <_IslandData>[
      _IslandData(
        subject: 'Mathematik',
        emoji: '🧮',
        theme: _IslandTheme.sunset,
        total: mathTotal,
      ),
      _IslandData(
        subject: 'Deutsch',
        emoji: '📚',
        theme: _IslandTheme.indigo,
        total: germanTotal,
      ),
      _IslandData(
        subject: 'Sachkunde',
        emoji: '🌿',
        theme: _IslandTheme.emerald,
        total: scienceTotal,
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Meine Lumo-Welt',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: LumoMagicBackground(
        intensity: 1.0,
        starCount: 22,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Hero(totalItems: mathTotal + germanTotal + scienceTotal),
                const SizedBox(height: 14),
                for (final island in islands) ...[
                  _IslandCard(data: island),
                  const SizedBox(height: 14),
                ],
                const _FooterTip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _sumCorrect(Map<String, SkillRecord> skills, String subject) {
    var total = 0;
    for (final s in skills.values) {
      if (s.subject == subject) total += s.correct;
    }
    return total;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.totalItems});
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF6366F1), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/companion/lumo_idle.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏝️ Meine Lumo-Welt',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalItems Antworten haben deine Inseln aufgebaut.',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0F2FE),
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
}

class _FooterTip extends StatelessWidget {
  const _FooterTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Jede richtige Antwort laesst deine Inseln wachsen. '
              'Loese 60 Aufgaben pro Fach, dann blueht es richtig!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── INSEL-CARD ────────────────────────────────────────────────────────

enum _IslandTheme { sunset, indigo, emerald }

class _IslandData {
  const _IslandData({
    required this.subject,
    required this.emoji,
    required this.theme,
    required this.total,
  });
  final String subject;
  final String emoji;
  final _IslandTheme theme;
  final int total;

  /// 0=Sämling, 1=Wachsend, 2=Blühend.
  int get growthStage {
    if (total >= 60) return 2;
    if (total >= 20) return 1;
    return 0;
  }

  String get stageName {
    switch (growthStage) {
      case 2:
        return 'Bluehend';
      case 1:
        return 'Wachsend';
      default:
        return 'Saemling';
    }
  }

  int get nextMilestone {
    if (growthStage == 0) return 20;
    if (growthStage == 1) return 60;
    return total;
  }
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({required this.data});
  final _IslandData data;

  @override
  Widget build(BuildContext context) {
    final colors = _palette(data.theme);
    final pct = data.growthStage >= 2
        ? 1.0
        : (data.total / data.nextMilestone).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.accent],
                ),
              ),
              child: Row(
                children: [
                  Text(data.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data.subject}-Insel',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${data.stageName} · ${data.total} Antworten',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stage-Indicator
                  Row(
                    children: List<Widget>.generate(3, (i) {
                      final filled = i <= data.growthStage;
                      return Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? Colors.white
                                : Colors.white.withOpacity(0.30),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            // Insel-Render
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _IslandPainter(
                  theme: data.theme,
                  growthStage: data.growthStage,
                  totalAnswers: data.total,
                ),
                size: Size.infinite,
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: colors.primary.withOpacity(0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(colors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.growthStage >= 2
                            ? 'Max!'
                            : '${data.total} / ${data.nextMilestone}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hintFor(data),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: LumoColors.ink500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintFor(_IslandData d) {
    switch (d.growthStage) {
      case 2:
        return 'Deine Insel blueht! Lumo schaut zufrieden aus.';
      case 1:
        return 'Noch ${d.nextMilestone - d.total} Antworten zur naechsten Stufe.';
      default:
        return 'Beantworte ${d.nextMilestone - d.total} Aufgaben um Pflanzen wachsen zu lassen!';
    }
  }
}

class _IslandColors {
  const _IslandColors({
    required this.primary,
    required this.accent,
    required this.sea,
    required this.skyTop,
    required this.skyBottom,
    required this.ground,
    required this.foliage,
  });
  final Color primary;
  final Color accent;
  final Color sea;
  final Color skyTop;
  final Color skyBottom;
  final Color ground;
  final Color foliage;
}

_IslandColors _palette(_IslandTheme theme) {
  switch (theme) {
    case _IslandTheme.sunset:
      return const _IslandColors(
        primary: Color(0xFFEA580C),
        accent: Color(0xFFFCD34D),
        sea: Color(0xFF60A5FA),
        skyTop: Color(0xFFFED7AA),
        skyBottom: Color(0xFFFB923C),
        ground: Color(0xFF92400E),
        foliage: Color(0xFF15803D),
      );
    case _IslandTheme.indigo:
      return const _IslandColors(
        primary: Color(0xFF4338CA),
        accent: Color(0xFFA78BFA),
        sea: Color(0xFF38BDF8),
        skyTop: Color(0xFFC4B5FD),
        skyBottom: Color(0xFF818CF8),
        ground: Color(0xFF6D28D9),
        foliage: Color(0xFFC4B5FD),
      );
    case _IslandTheme.emerald:
      return const _IslandColors(
        primary: Color(0xFF047857),
        accent: Color(0xFFA7F3D0),
        sea: Color(0xFF67E8F9),
        skyTop: Color(0xFFA7F3D0),
        skyBottom: Color(0xFF34D399),
        ground: Color(0xFF166534),
        foliage: Color(0xFF22C55E),
      );
  }
}

// ── PAINTER ───────────────────────────────────────────────────────────

class _IslandPainter extends CustomPainter {
  _IslandPainter({
    required this.theme,
    required this.growthStage,
    required this.totalAnswers,
  });
  final _IslandTheme theme;
  final int growthStage;
  final int totalAnswers;

  @override
  void paint(Canvas canvas, Size size) {
    final c = _palette(theme);
    // Sky
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.skyTop, c.skyBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Sea (untere Hälfte)
    final seaTop = size.height * 0.6;
    final seaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.sea, c.sea.withOpacity(0.7)],
      ).createShader(Rect.fromLTWH(0, seaTop, size.width, size.height - seaTop));
    canvas.drawRect(
        Rect.fromLTWH(0, seaTop, size.width, size.height - seaTop), seaPaint);

    // Sea-Wellen
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rand = math.Random(theme.index * 31);
    for (var i = 0; i < 5; i++) {
      final y = seaTop + 14 + i * 14;
      final path = Path();
      path.moveTo(rand.nextDouble() * size.width * 0.1, y);
      for (var x = 0.0; x < size.width; x += 18) {
        path.lineTo(x, y + math.sin(x * 0.05 + i) * 2.5);
      }
      canvas.drawPath(path, wavePaint);
    }

    // Sonne / Mond
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.25),
      28,
      Paint()..color = c.accent.withOpacity(0.65),
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.25),
      18,
      Paint()..color = c.accent,
    );

    // Insel
    final islandCenter = Offset(size.width / 2, seaTop + 8);
    final islandPath = Path();
    islandPath.moveTo(size.width * 0.18, seaTop + 12);
    islandPath.quadraticBezierTo(
      size.width * 0.32,
      seaTop - 50,
      size.width * 0.5,
      seaTop - 60,
    );
    islandPath.quadraticBezierTo(
      size.width * 0.68,
      seaTop - 50,
      size.width * 0.82,
      seaTop + 12,
    );
    islandPath.close();
    canvas.drawPath(islandPath, Paint()..color = c.foliage);

    // Insel-Boden (Sand)
    final groundPath = Path();
    groundPath.moveTo(size.width * 0.18, seaTop + 12);
    groundPath.lineTo(size.width * 0.82, seaTop + 12);
    groundPath.quadraticBezierTo(
      size.width * 0.5,
      seaTop + 36,
      size.width * 0.18,
      seaTop + 12,
    );
    groundPath.close();
    canvas.drawPath(groundPath, Paint()..color = c.ground);

    // Decorations basierend auf Stage
    _drawDecorations(canvas, size, c, growthStage, islandCenter);

    // Lumo-Bewohner (immer sichtbar)
    final tp = TextPainter(
      text: const TextSpan(
        text: '🦊',
        style: TextStyle(fontSize: 30),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        islandCenter.dx - tp.width / 2,
        seaTop - 30,
      ),
    );
  }

  void _drawDecorations(Canvas canvas, Size size, _IslandColors c,
      int stage, Offset center) {
    // Pro Stage mehr Items
    final itemCount = stage == 0 ? 0 : (stage == 1 ? 3 : 7);
    final seaTop = size.height * 0.6;
    final emoji = switch (theme) {
      _IslandTheme.sunset => '🌳', // Math = Baum
      _IslandTheme.indigo => '🏛️', // Deutsch = Buecher-Tempel
      _IslandTheme.emerald => '🌸', // Sachkunde = Blume
    };
    final extras = switch (theme) {
      _IslandTheme.sunset => ['⛰️', '🌲', '🌳'],
      _IslandTheme.indigo => ['📖', '🗿', '🏛️'],
      _IslandTheme.emerald => ['🌺', '🦋', '🐦'],
    };
    final positions = <Offset>[
      Offset(size.width * 0.30, seaTop - 24),
      Offset(size.width * 0.66, seaTop - 24),
      Offset(size.width * 0.40, seaTop - 40),
      Offset(size.width * 0.58, seaTop - 38),
      Offset(size.width * 0.28, seaTop - 40),
      Offset(size.width * 0.70, seaTop - 38),
      Offset(size.width * 0.50, seaTop - 50),
    ];
    final rand = math.Random(theme.index * 17 + totalAnswers);
    for (var i = 0; i < itemCount && i < positions.length; i++) {
      final e = i % 2 == 0 ? emoji : extras[rand.nextInt(extras.length)];
      final tp = TextPainter(
        text: TextSpan(
          text: e,
          style: const TextStyle(fontSize: 22),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, positions[i] - Offset(tp.width / 2, tp.height / 2));
    }
    // Stage 2: extra Sparkles
    if (stage == 2) {
      for (var i = 0; i < 4; i++) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '✨',
            style: TextStyle(fontSize: 14),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
          canvas,
          Offset(
            size.width * (0.20 + i * 0.18),
            seaTop - 70 - i.toDouble() * 4,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_IslandPainter old) =>
      old.growthStage != growthStage || old.totalAnswers != totalAnswers;
}
