import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Schulbuchnahe, aber eigenstaendige Lumo-Visuals.
///
/// Diese Widgets bilden allgemeine Grundschul-Strategien digital nach
/// (Zwanzigerfeld, Rechenhaus, Zahlenstrahl, Schreiblinien), ohne Layouts,
/// Illustrationen oder Aufgaben konkreter Buecher zu kopieren.
class SchoolbookTaskCard extends StatelessWidget {
  const SchoolbookTaskCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.ribbonLabel,
    this.helperText,
    this.accentColor = LumoColors.orange,
  });

  final String title;
  final String? subtitle;
  final String? ribbonLabel;
  final String? helperText;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.ink100, width: 1.3),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _PaperLinesPainter())),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: LumoColors.ink500,
                      height: 1.25,
                    ),
                  ),
                ],
              ]),
            ),
            if (ribbonLabel != null) _Ribbon(label: ribbonLabel!, color: accentColor),
          ]),
          const SizedBox(height: 14),
          child,
          if (helperText != null) ...[
            const SizedBox(height: 14),
            _HelperBox(text: helperText!, color: accentColor),
          ],
        ]),
      ]),
    );
  }
}

class TwentyFrameVisual extends StatelessWidget {
  const TwentyFrameVisual({
    super.key,
    required this.start,
    required this.takeAway,
    this.showBridge = true,
  });

  final int start;
  final int takeAway;
  final bool showBridge;

  int get _firstStep => start > 10 ? start - 10 : takeAway;
  int get _secondStep => (takeAway - _firstStep).clamp(0, 20).toInt();
  int get _result => (start - takeAway).clamp(0, 20).toInt();
  bool get _bridgesTen => start > 10 && takeAway > start - 10;

  @override
  Widget build(BuildContext context) {
    final firstStep = _bridgesTen ? _firstStep : takeAway;
    final secondStep = _bridgesTen ? _secondStep : 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _TwentyDots(start: start, crossed: takeAway),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        _MathChip('$start - $takeAway = $_result'),
        if (showBridge && _bridgesTen) ...[
          _MathChip('$start - $firstStep - $secondStep = $_result', soft: true),
          _TenShield(),
        ],
      ]),
      if (showBridge && _bridgesTen) ...[
        const SizedBox(height: 8),
        Text(
          'Erst bis zur 10, dann den Rest wegnehmen.',
          style: LumoTextStyles.body.copyWith(fontSize: 12, color: LumoColors.ink600),
        ),
      ],
    ]);
  }
}

class NumberLineJumpVisual extends StatelessWidget {
  const NumberLineJumpVisual({
    super.key,
    required this.start,
    required this.takeAway,
  });

  final int start;
  final int takeAway;

  @override
  Widget build(BuildContext context) {
    final first = start > 10 ? start - 10 : takeAway;
    final second = (takeAway - first).clamp(0, 20).toInt();
    final result = (start - takeAway).clamp(0, 20).toInt();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 96,
        child: CustomPaint(
          painter: _NumberLineJumpPainter(
            start: start.clamp(0, 20).toInt(),
            via: second > 0 ? 10 : result,
            result: result,
            firstJump: first,
            secondJump: second,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        second > 0 ? '$start - $first - $second = $result' : '$start - $takeAway = $result',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: LumoColors.ink900,
        ),
      ),
    ]);
  }
}

class NumberHouseVisual extends StatelessWidget {
  const NumberHouseVisual({
    super.key,
    required this.target,
    this.rows = const <List<int>>[],
    this.missingIndex,
  });

  final int target;
  final List<List<int>> rows;
  final int? missingIndex;

  @override
  Widget build(BuildContext context) {
    final safeRows = rows.isEmpty ? _defaultRows(target) : rows;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(children: [
          CustomPaint(
            painter: _HouseRoofPainter(color: LumoColors.orange),
            child: SizedBox(
              height: 72,
              child: Center(
                child: Text(
                  '$target',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.9),
              border: Border.all(color: LumoColors.ink500, width: 1.2),
            ),
            child: Column(
              children: List.generate(safeRows.length, (rowIndex) {
                final row = safeRows[rowIndex];
                return Row(children: [
                  Expanded(child: _HouseCell(value: row.isNotEmpty ? row[0] : 0, hide: missingIndex == rowIndex * 2)),
                  Expanded(child: _HouseCell(value: row.length > 1 ? row[1] : 0, hide: missingIndex == rowIndex * 2 + 1)),
                ]);
              }),
            ),
          ),
        ]),
      ),
    );
  }

  List<List<int>> _defaultRows(int target) {
    final safeTarget = target.clamp(1, 20).toInt();
    final a = safeTarget ~/ 2;
    return <List<int>>[
      <int>[a, safeTarget - a],
      <int>[(a + 1).clamp(0, safeTarget).toInt(), (safeTarget - a - 1).clamp(0, safeTarget).toInt()],
      <int>[0, safeTarget],
    ];
  }
}

class BlitzlichtGrid extends StatelessWidget {
  const BlitzlichtGrid({
    super.key,
    required this.items,
    this.columns = 2,
  });

  final List<String> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final safeColumns = columns.clamp(1, 4).toInt();
    return LayoutBuilder(builder: (context, constraints) {
      final spacing = 8.0;
      final itemWidth = (constraints.maxWidth - spacing * (safeColumns - 1)) / safeColumns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(items.length, (index) {
          return SizedBox(
            width: itemWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.82),
                borderRadius: BorderRadius.circular(LumoRadius.sm),
                border: Border.all(color: LumoColors.ink100),
              ),
              child: Text(
                items[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.ink900,
                ),
              ),
            ),
          );
        }),
      );
    });
  }
}

class WritingLineBox extends StatelessWidget {
  const WritingLineBox({
    super.key,
    required this.placeholder,
    this.cells = 5,
  });

  final String placeholder;
  final int cells;

  @override
  Widget build(BuildContext context) {
    final safeCells = cells.clamp(1, 12).toInt();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        placeholder,
        style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900, color: LumoColors.ink700),
      ),
      const SizedBox(height: 8),
      Row(
        children: List.generate(safeCells, (index) {
          return Expanded(
            child: Container(
              height: 48,
              margin: EdgeInsets.only(right: index == safeCells - 1 ? 0 : 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: LumoColors.ink100),
                  right: BorderSide(color: LumoColors.ink100),
                  bottom: BorderSide(color: LumoColors.ink500, width: 1.4),
                ),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

class SoundChoiceCard extends StatelessWidget {
  const SoundChoiceCard({
    super.key,
    required this.word,
    required this.choices,
    this.icon = Icons.volume_up_rounded,
  });

  final String word;
  final List<String> choices;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: LumoColors.orangeSurface,
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: LumoColors.orange.withOpacity(.22)),
        ),
        child: Icon(icon, color: LumoColors.orange, size: 32),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            word,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: choices
                .map((choice) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LumoRadius.pill),
                        border: Border.all(color: LumoColors.ink100, width: 1.4),
                      ),
                      child: Text(
                        choice,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: LumoColors.ink700,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ]),
      ),
    ]);
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _HelperBox extends StatelessWidget {
  const _HelperBox({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.lightbulb_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: LumoColors.ink700,
              height: 1.30,
            ),
          ),
        ),
      ]),
    );
  }
}

class _MathChip extends StatelessWidget {
  const _MathChip(this.text, {this.soft = false});

  final String text;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: soft ? LumoColors.goldSurface : Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        border: Border.all(color: soft ? LumoColors.gold.withOpacity(.35) : LumoColors.ink100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: LumoColors.ink900,
        ),
      ),
    );
  }
}

class _TenShield extends StatelessWidget {
  const _TenShield();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        border: Border.all(color: LumoColors.orange, width: 1.6),
      ),
      child: const Text(
        '10',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: LumoColors.orange,
        ),
      ),
    );
  }
}

class _TwentyDots extends StatelessWidget {
  const _TwentyDots({required this.start, required this.crossed});

  final int start;
  final int crossed;

  @override
  Widget build(BuildContext context) {
    final safeStart = start.clamp(0, 20).toInt();
    final safeCrossed = crossed.clamp(0, safeStart).toInt();
    return Wrap(
      spacing: 5,
      runSpacing: 7,
      children: List.generate(20, (index) {
        final active = index < safeStart;
        final crossed = index >= safeStart - safeCrossed && index < safeStart;
        return SizedBox(
          width: 22,
          height: 22,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? LumoColors.orange.withOpacity(.22) : Colors.white,
                border: Border.all(color: active ? LumoColors.orange.withOpacity(.75) : LumoColors.ink100, width: 1.5),
              ),
            ),
            if (crossed)
              Transform.rotate(
                angle: -.72,
                child: Container(width: 27, height: 2.2, color: LumoColors.ink700.withOpacity(.80)),
              ),
          ]),
        );
      }),
    );
  }
}

class _HouseCell extends StatelessWidget {
  const _HouseCell({required this.value, required this.hide});

  final int value;
  final bool hide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: LumoColors.ink100),
          bottom: BorderSide(color: LumoColors.ink100),
        ),
      ),
      child: Center(
        child: Text(
          hide ? '___' : '$value',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: hide ? 15 : 20,
            fontWeight: FontWeight.w900,
            color: hide ? LumoColors.orange : LumoColors.ink900,
          ),
        ),
      ),
    );
  }
}

class _PaperLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LumoColors.ink100.withOpacity(.24)
      ..strokeWidth = 1;
    for (var y = 52.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperLinesPainter oldDelegate) => false;
}

class _HouseRoofPainter extends CustomPainter {
  const _HouseRoofPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(.12)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = LumoColors.ink500
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .08, size.height)
      ..lineTo(size.width * .50, 6)
      ..lineTo(size.width * .92, size.height)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _HouseRoofPainter oldDelegate) => oldDelegate.color != color;
}

class _NumberLineJumpPainter extends CustomPainter {
  const _NumberLineJumpPainter({
    required this.start,
    required this.via,
    required this.result,
    required this.firstJump,
    required this.secondJump,
  });

  final int start;
  final int via;
  final int result;
  final int firstJump;
  final int secondJump;

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * .72;
    final left = 14.0;
    final right = size.width - 14;
    final step = (right - left) / 20;
    final linePaint = Paint()
      ..color = LumoColors.ink500
      ..strokeWidth = 2;
    final tickPaint = Paint()
      ..color = LumoColors.ink500
      ..strokeWidth = 1.2;
    final jumpPaint = Paint()
      ..color = LumoColors.orange
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(left, baseY), Offset(right, baseY), linePaint);
    for (var i = 0; i <= 20; i++) {
      final x = left + i * step;
      final tickHeight = i % 5 == 0 ? 13.0 : 8.0;
      canvas.drawLine(Offset(x, baseY - tickHeight / 2), Offset(x, baseY + tickHeight / 2), tickPaint);
      if (i % 2 == 0 || i == start || i == result || i == via) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 9, fontWeight: FontWeight.w800, color: LumoColors.ink500),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, baseY + 10));
      }
    }

    void arc(int from, int to, String label, double height) {
      final fromX = left + from * step;
      final toX = left + to * step;
      final rect = Rect.fromLTRB(toX, baseY - height, fromX, baseY + height * .30);
      canvas.drawArc(rect, 3.14, 3.14, false, jumpPaint);
      final painter = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.orange)),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset((fromX + toX) / 2 - painter.width / 2, baseY - height - 2));
    }

    arc(start, via, '-$firstJump', 34);
    if (secondJump > 0) arc(via, result, '-$secondJump', 24);
  }

  @override
  bool shouldRepaint(covariant _NumberLineJumpPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.via != via || oldDelegate.result != result || oldDelegate.firstJump != firstJump || oldDelegate.secondJump != secondJump;
  }
}
