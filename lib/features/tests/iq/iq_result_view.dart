import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/design/lumo_motion.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../shared/widgets/lumo_premium_effects.dart' show LumoConfettiBurst;
import 'iq_reward.dart';
import 'iq_start_view.dart';
import 'iq_style.dart';
import 'iq_widgets.dart';

// ---------------------------------------------------------------------------
// Sechseck-Diagramm
// ---------------------------------------------------------------------------

/// Maße des Sechsecks. Gemeinsam für das Zeichnen und die Plaketten an den
/// Ecken, damit beides genau aufeinander liegt.
class IqRadarGeometry {
  const IqRadarGeometry(this.size);

  final double size;

  double get radius => size * .345;
  Offset get center => Offset(size / 2, size / 2);
  double get medallion => math.max(38, size * .13);

  Offset direction(int i) {
    final angle = -math.pi / 2 + i * math.pi / 3;
    return Offset(math.cos(angle), math.sin(angle));
  }

  Offset point(int i, double fraction) => center + direction(i) * radius * fraction;

  Offset medallionCenter(int i) =>
      center + direction(i) * (radius + medallion * .5 + 6);
}

/// Malt Gitter, Achsen und die leuchtende Fläche der Stufen 0 bis 8.
class IqRadarPainter extends CustomPainter {
  const IqRadarPainter({required this.levels, required this.progress});

  final List<int> levels;

  /// 0 (Mitte) bis 1 (volle Länge) – für das Aufwachsen.
  final double progress;

  static const _areas = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final g = IqRadarGeometry(size.shortestSide);
    Path ring(double fraction) {
      final path = Path();
      for (var i = 0; i < _areas; i++) {
        final p = g.point(i, fraction);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    canvas.drawPath(
      ring(1),
      Paint()
        ..shader = ui.Gradient.radial(
          g.center,
          g.radius,
          const [Color(0x330F4A8C), Color(0x1A0A2A55)],
        ),
    );
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .12);
    for (final level in const [2, 4, 6]) {
      canvas.drawPath(ring(level / 8), thin);
    }
    for (var i = 0; i < _areas; i++) {
      canvas.drawLine(g.center, g.point(i, 1), thin);
    }
    canvas.drawPath(
      ring(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = LumoVisualTokens.cyan.withValues(alpha: .45),
    );
    // Stufenzahlen entlang der oberen Achse.
    for (final level in const [2, 4, 6, 8]) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$level',
          style: iqText(9.5,
              weight: FontWeight.w800,
              color: Colors.white.withValues(alpha: .42)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = g.point(0, level / 8);
      tp.paint(canvas, at + Offset(5, -tp.height / 2));
    }

    final data = Path();
    final points = <Offset>[];
    for (var i = 0; i < _areas; i++) {
      final level = i < levels.length ? levels[i] : 0;
      final fraction = math.max(level / 8, .07) * progress;
      final p = g.point(i, fraction);
      points.add(p);
      i == 0 ? data.moveTo(p.dx, p.dy) : data.lineTo(p.dx, p.dy);
    }
    data.close();
    canvas.drawPath(
      data,
      Paint()
        ..shader = ui.Gradient.radial(
          g.center,
          g.radius,
          [
            const Color(0xFF9170FF).withValues(alpha: .35),
            LumoVisualTokens.cyan.withValues(alpha: .62),
          ],
        ),
    );
    canvas.drawPath(
      data,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round
        ..color = LumoVisualTokens.cyanBright.withValues(alpha: .75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      data,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: .95),
    );
    for (var i = 0; i < _areas; i++) {
      final color = iqAreaStyle(IqArea.values[i]).color;
      canvas.drawCircle(
        points[i],
        8,
        Paint()
          ..color = color.withValues(alpha: .7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(points[i], 5, Paint()..color = color);
      canvas.drawCircle(
        points[i],
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IqRadarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      !_sameLevels(oldDelegate.levels, levels);

  static bool _sameLevels(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Das Sechseck mit den Symbolen der sechs Bereiche an den Ecken.
class IqRadarChart extends StatelessWidget {
  const IqRadarChart({super.key, required this.scores, this.maxSize = 340});

  final List<IqAreaScore> scores;
  final double maxSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final size = math.min(maxSize, c.maxWidth);
        final g = IqRadarGeometry(size);
        final levels = [for (final s in scores) s.bestLevel];
        final spoken = [
          for (final s in scores) '${s.area.title} Stufe ${s.bestLevel}',
        ].join(', ');
        final reduced = LumoMotion.reduced(context);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Semantics(
              image: true,
              label: 'Denk-Profil als Sechseck von 0 bis 8: $spoken',
              excludeSemantics: true,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: reduced ? 1 : 0, end: 1),
                duration: reduced ? Duration.zero : const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: IqRadarPainter(levels: levels, progress: progress),
                        ),
                      ),
                    ),
                    for (var i = 0; i < scores.length; i++)
                      Positioned(
                        left: g.medallionCenter(i).dx - g.medallion / 2,
                        top: g.medallionCenter(i).dy - g.medallion / 2,
                        child: IqAreaMedallion(scores[i].area, size: g.medallion),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// Stufenanzeige und Vergleich
// ---------------------------------------------------------------------------

/// Acht kleine Felder, so viele leuchten wie die erreichte Stufe.
class IqLevelMeter extends StatelessWidget {
  const IqLevelMeter({super.key, required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduced = LumoMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduced ? level.toDouble() : 0, end: level.toDouble()),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Row(
        children: [
          for (var i = 0; i < IqTestResult.maxLevel; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Color.lerp(
                    Colors.white.withValues(alpha: .1),
                    color,
                    (value - i).clamp(0.0, 1.0).toDouble(),
                  ),
                  boxShadow: value - i > .5
                      ? iqGlow(color, alpha: .55, blur: 8)
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Beschreibung des Vergleichs zum letzten Mal (für Screenreader).
String iqTrendLabel(int delta) => delta > 0
    ? 'besser als letztes Mal'
    : delta < 0
        ? 'etwas weniger als letztes Mal'
        : 'so wie letztes Mal';

/// Pfeil: besser, gleich oder etwas weniger als beim letzten Mal.
class IqTrend extends StatelessWidget {
  const IqTrend({super.key, required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = delta > 0
        ? (Icons.arrow_upward_rounded, const Color(0xFF5BE39A))
        : delta < 0
            ? (Icons.arrow_downward_rounded, const Color(0xFFFFB067))
            : (Icons.drag_handle_rounded, LumoVisualTokens.muted);
    return Semantics(
      label: iqTrendLabel(delta),
      excludeSemantics: true,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .16),
          border: Border.all(color: color.withValues(alpha: .6)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ergebnisseite
// ---------------------------------------------------------------------------

/// „Dein Denk-Profil“: Denkpunkte, Sechseck, Ehrentitel, Stufen je Bereich,
/// Übungstipp, Vergleich zum letzten Mal und Belohnung.
class IqResultView extends StatefulWidget {
  const IqResultView({
    super.key,
    required this.result,
    required this.onReview,
    required this.onDone,
    this.previous,
    this.reward = IqReward.none,
    this.alreadyRewardedToday = false,
    this.saveFailed = false,
  });

  final IqTestResult result;

  /// Das Ergebnis davor (für die Pfeile); null, wenn es keins gibt.
  final IqTestResult? previous;
  final IqReward reward;
  final bool alreadyRewardedToday;
  final bool saveFailed;
  final VoidCallback onReview;
  final VoidCallback onDone;

  @override
  State<IqResultView> createState() => _IqResultViewState();
}

class _IqResultViewState extends State<IqResultView> {
  final _lumo = LumoCharacterController();
  int _burst = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (LumoMotion.reduced(context)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lumo.cheer();
      setState(() => _burst = 1);
    });
  }

  @override
  void dispose() {
    _lumo.dispose();
    super.dispose();
  }

  IqTestResult get _result => widget.result;

  String _praise() {
    final ratio = _result.total == 0 ? 0 : _result.solved / _result.total;
    if (ratio >= .75) return 'Wow, das war richtig stark!';
    if (ratio >= .4) return 'Toll gemacht! Du hast viele Rätsel gelöst.';
    return 'Mutig durchgehalten! Knobeln wird mit jedem Mal leichter.';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 760 && c.maxWidth >= c.maxHeight * 1.1;
        final left = <Widget>[
          _hero(),
          if (_badge() case final badge?) badge,
          _radarCard(),
        ];
        final right = <Widget>[
          _barsCard(),
          _practiceCard(),
          _rewardCard(),
          const IqParentNote(),
        ];
        Widget column(List<Widget> children, int startIndex) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  LumoEntrance(index: startIndex + i, child: children[i]),
                ],
              ],
            );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IqRoundButton(
                    key: const ValueKey('iq-back'),
                    icon: Icons.arrow_back_rounded,
                    label: 'Fertig',
                    onPressed: widget.onDone,
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Dein Denk-Profil',
                        textAlign: TextAlign.center,
                        style: iqText(24, weight: FontWeight.w900, shadows: iqScrim),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('iq-result-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1040 : 600),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: column(left, 0)),
                              const SizedBox(width: 16),
                              Expanded(child: column(right, 2)),
                            ],
                          )
                        : column([...left, ...right], 0),
                  ),
                ),
              ),
            ),
            IqBottomBar(
              maxWidth: 560,
              child: Row(
                children: [
                  Expanded(
                    child: IqPrimaryButton(
                      key: const ValueKey('iq-result-review'),
                      label: 'Rückblick',
                      icon: Icons.fact_check_rounded,
                      outlined: true,
                      fontSize: 17,
                      onPressed: widget.onReview,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IqPrimaryButton(
                      key: const ValueKey('iq-result-done'),
                      label: 'Fertig',
                      icon: Icons.check_rounded,
                      fontSize: 17,
                      onPressed: widget.onDone,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      });

  // ---------------------------------------------------------------- Teile

  Widget _hero() {
    final points = _result.thinkingPoints;
    final previous = widget.previous;
    final diff = previous == null ? null : points - previous.thinkingPoints;
    return IqPanel(
      strong: true,
      accent: LumoVisualTokens.gold,
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 14),
      child: Stack(
        children: [
          if (_burst > 0)
            Positioned.fill(
              child: LumoConfettiBurst(trigger: _burst, particleCount: 36),
            ),
          Row(
            children: [
              LumoCharacter(
                pose: LumoDesignFoxPose.trophyWink,
                size: 124,
                controller: _lumo,
                reduceMotion: LumoMotion.reduced(context),
                intro: !LumoMotion.reduced(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _praise(),
                      style: iqText(16.5, weight: FontWeight.w900, height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: IqCountUp(
                              value: points.toDouble(),
                              builder: (context, v) => Text(
                                '${v.round()}',
                                key: const ValueKey('iq-points'),
                                style: iqText(
                                  58,
                                  weight: FontWeight.w900,
                                  color: LumoVisualTokens.gold,
                                  height: 1,
                                  shadows: [
                                    Shadow(
                                      color: LumoVisualTokens.gold.withValues(alpha: .6),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Denkpunkte',
                      style: iqText(15, weight: FontWeight.w900, color: LumoVisualTokens.gold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_result.solved} von ${_result.total} Rätseln gelöst',
                      style: iqText(13.5, color: LumoVisualTokens.muted),
                    ),
                    if (diff != null) ...[
                      const SizedBox(height: 6),
                      // Ein kleineres Ergebnis wird nicht als Minus gezeigt: Jeder
                      // Test hat andere Rätsel.
                      IqChip(
                        key: const ValueKey('iq-points-diff'),
                        label: diff > 0
                            ? '+$diff mehr als beim letzten Mal'
                            : diff == 0
                                ? 'so viele wie beim letzten Mal'
                                : 'Letztes Mal: ${previous!.thinkingPoints}',
                        icon: diff > 0
                            ? Icons.trending_up_rounded
                            : diff == 0
                                ? Icons.trending_flat_rounded
                                : Icons.history_rounded,
                        color: diff >= 0 ? const Color(0xFF5BE39A) : LumoVisualTokens.cyan,
                        dense: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _badge() {
    final strongest = _result.strongest;
    if (strongest.bestLevel == 0) return null;
    final style = iqAreaStyle(strongest.area);
    return Semantics(
      container: true,
      label: 'Dein Ehrentitel: ${strongest.area.badge}',
      excludeSemantics: true,
      child: IqPanel(
        key: const ValueKey('iq-badge'),
        strong: true,
        accent: style.color,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(
          children: [
            IqAreaMedallion(strongest.area, size: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dein Ehrentitel',
                      style: iqText(12.5, color: LumoVisualTokens.muted)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strongest.area.badge,
                      style: iqText(
                        26,
                        weight: FontWeight.w900,
                        color: LumoVisualTokens.gold,
                        shadows: [
                          Shadow(
                            color: LumoVisualTokens.gold.withValues(alpha: .5),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'Stärkster Bereich: ${strongest.area.title}',
                    style: iqText(12.5, color: LumoVisualTokens.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.workspace_premium_rounded,
                color: LumoVisualTokens.gold, size: 34),
          ],
        ),
      ),
    );
  }

  Widget _radarCard() => IqPanel(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        child: Column(
          children: [
            Text('Deine sechs Stärken', style: iqText(17, weight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(
              'Je weiter außen, desto höher die Stufe (1 bis 8).',
              textAlign: TextAlign.center,
              style: iqText(12.5, color: LumoVisualTokens.muted),
            ),
            const SizedBox(height: 4),
            IqRadarChart(scores: _result.areaScores),
          ],
        ),
      );

  Widget _barsCard() {
    final previousScores = widget.previous?.areaScores;
    return IqPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Stufe je Bereich', style: iqText(17, weight: FontWeight.w900)),
          if (previousScores != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Die Pfeile zeigen den Unterschied zum letzten Mal.',
                style: iqText(12.5, color: LumoVisualTokens.muted),
              ),
            ),
          const SizedBox(height: 10),
          for (final score in _result.areaScores) ...[
            _AreaRow(
              score: score,
              delta: previousScores == null
                  ? null
                  : score.bestLevel -
                      previousScores
                          .firstWhere((p) => p.area == score.area)
                          .bestLevel,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _practiceCard() {
    final practice = _result.practice;
    final strongest = _result.strongest;
    final balanced = practice.area == strongest.area;
    final style = iqAreaStyle(practice.area);
    return IqPanel(
      key: const ValueKey('iq-practice'),
      accent: balanced ? LumoVisualTokens.cyan : style.color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IqAreaMedallion(practice.area, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        size: 18, color: LumoVisualTokens.gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hier hilft Üben',
                        style: iqText(17, weight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  balanced ? 'Du bist überall ähnlich stark' : practice.area.title,
                  style: iqText(14.5, weight: FontWeight.w900, color: style.color),
                ),
                const SizedBox(height: 4),
                Text(
                  iqPracticeTip(practice.area),
                  style: iqText(13.5,
                      weight: FontWeight.w700,
                      color: LumoVisualTokens.muted,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardCard() {
    final reward = widget.reward;
    final Widget content;
    if (widget.saveFailed) {
      content = _message(
        Icons.info_rounded,
        'Dein Ergebnis konnte nicht gespeichert werden. '
        'Du kannst den Test später noch einmal machen.',
      );
    } else if (widget.alreadyRewardedToday) {
      content = _message(
        Icons.check_circle_rounded,
        'Für heute hast du die Sterne fürs Knobeln schon bekommen. '
        'Morgen gibt es wieder welche!',
      );
    } else if (reward.isEmpty) {
      content = _message(
        Icons.favorite_rounded,
        'Diesmal gibt es keine Sterne. Probier es morgen noch einmal – '
        'jedes Rätsel macht dich schlauer!',
      );
    } else {
      content = Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (reward.stars > 0)
            IqChip(
              key: const ValueKey('iq-reward-stars'),
              label: '+${reward.stars} ${reward.stars == 1 ? 'Stern' : 'Sterne'}',
              icon: Icons.star_rounded,
              color: LumoVisualTokens.gold,
            ),
          if (reward.xp > 0)
            IqChip(
              key: const ValueKey('iq-reward-xp'),
              label: '+${reward.xp} XP',
              icon: Icons.bolt_rounded,
              color: LumoVisualTokens.cyanBright,
            ),
        ],
      );
    }
    return IqPanel(
      key: const ValueKey('iq-reward'),
      accent: LumoVisualTokens.gold,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deine Belohnung', style: iqText(17, weight: FontWeight.w900)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _message(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: LumoVisualTokens.cyanBright),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: iqText(13.5,
                  weight: FontWeight.w700, color: LumoVisualTokens.muted, height: 1.4),
            ),
          ),
        ],
      );
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.score, this.delta});

  final IqAreaScore score;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final style = iqAreaStyle(score.area);
    final level = score.bestLevel == 0
        ? 'Hier üben wir noch'
        : 'Stufe ${score.bestLevel} von ${IqTestResult.maxLevel}';
    return Semantics(
      container: true,
      label: '${score.area.title}: $level, ${score.solved} von ${score.total} gelöst'
          '${delta == null ? '' : ', ${iqTrendLabel(delta!)}'}',
      excludeSemantics: true,
      child: Row(
        children: [
          IqAreaMedallion(score.area, size: 42, glow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        score.area.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: iqText(14.5, weight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      '${score.solved}/${score.total} gelöst',
                      style: iqText(12.5, color: LumoVisualTokens.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                IqLevelMeter(level: score.bestLevel, color: style.color),
                const SizedBox(height: 4),
                Text(level, style: iqText(12.5, color: LumoVisualTokens.muted)),
              ],
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 10),
            IqTrend(key: ValueKey('iq-trend-${score.area.name}'), delta: delta!),
          ],
        ],
      ),
    );
  }
}
