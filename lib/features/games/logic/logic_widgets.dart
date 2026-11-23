import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/logic/logic_games.dart';
import '../../tests/iq/iq_style.dart';

const logicNavy = Color(0xFF071C38);
const logicCyan = Color(0xFF68E5FF);
const logicGreen = Color(0xFF95FF79);
const logicMuted = Color(0xFFB9CEE5);

Color logicColor(LogicGameKind kind) => switch (kind) {
  LogicGameKind.sudoku => logicCyan,
  LogicGameKind.words => const Color(0xFFC3A7FF),
  LogicGameKind.maths => const Color(0xFFFFD388),
};

IconData logicIcon(LogicGameKind kind) => switch (kind) {
  LogicGameKind.sudoku => Icons.grid_on_rounded,
  LogicGameKind.words => Icons.abc_rounded,
  LogicGameKind.maths => Icons.calculate_rounded,
};

/// The existing Knobeltest palette and typography, with a quiet spatial grid.
class LogicBackdrop extends StatelessWidget {
  const LogicBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF163D61), logicNavy, Color(0xFF211940)],
      ),
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: _RoomGrid())),
          ),
        ),
        child,
      ],
    ),
  );
}

class LogicGlass extends StatelessWidget {
  const LogicGlass({
    super.key,
    required this.child,
    this.color = logicCyan,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: color.withValues(alpha: .35)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF0204262), Color(0xF00B203D)],
      ),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .08), blurRadius: 24),
        const BoxShadow(
          color: Color(0x3D00081C),
          offset: Offset(0, 8),
          blurRadius: 16,
        ),
      ],
    ),
    child: child,
  );
}

class LogicAction extends StatelessWidget {
  const LogicAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      backgroundColor: primary ? logicGreen : const Color(0xFF254D70),
      foregroundColor: primary ? logicNavy : Colors.white,
      disabledBackgroundColor: const Color(0xFF263850),
      disabledForegroundColor: const Color(0xFF9CB1CA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: iqText(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 21), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

/// Exact decorative preview drawn from an actual level, not generated glyphs.
class LogicBoardPreview extends StatelessWidget {
  const LogicBoardPreview({super.key, required this.kind, required this.grade});
  final LogicGameKind kind;
  final int grade;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        height: 156,
        child: CustomPaint(
          painter: _BoardPreview(
            LogicCatalog.puzzle(kind, grade, 1),
            logicColor(kind),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _BoardPreview extends CustomPainter {
  _BoardPreview(this.puzzle, this.color);
  final LogicPuzzle puzzle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width - 24, size.height - 18);
    final step = side / math.max(puzzle.rows, puzzle.columns);
    final width = step * puzzle.columns;
    final height = step * puzzle.rows;
    final origin = Offset(
      (size.width - width) / 2,
      (size.height - height) / 2 - 3,
    );
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx - 8, origin.dy - 8, width + 16, height + 16),
      const Radius.circular(17),
    );
    canvas.drawRRect(
      plate.shift(const Offset(0, 7)),
      Paint()..color = const Color(0xFF07162D),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0xFF244763));
    canvas.drawRRect(
      plate,
      Paint()
        ..color = color.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    for (final cell in puzzle.cells) {
      if (cell.blocked) continue;
      final row = cell.index ~/ puzzle.columns;
      final column = cell.index % puzzle.columns;
      final rect = Rect.fromLTWH(
        origin.dx + column * step + 1.5,
        origin.dy + row * step + 1.5,
        step - 3,
        step - 3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 2)),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF07162D),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..color = cell.given
              ? const Color(0xFFECF4FF)
              : const Color(0xFF315A7B),
      );
      if (cell.given || cell.isOperator) {
        final text = TextPainter(
          text: TextSpan(
            text: cell.answer,
            style: iqText(
              (step * .47).clamp(8, 21),
              color: cell.given ? logicNavy : color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width);
        text.paint(
          canvas,
          rect.center - Offset(text.width / 2, text.height / 2),
        );
        text.dispose();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPreview old) =>
      old.puzzle.id != puzzle.id || old.color != color;
}

class _RoomGrid extends CustomPainter {
  const _RoomGrid();
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x0C8CCFFF)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x125BDFFC), Color(0x005BDFFC)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .8, size.height * .15),
              radius: 250,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _RoomGrid oldDelegate) => false;
}
