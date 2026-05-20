// ════════════════════════════════════════════════════════════════════════
// FORMEN ERKENNEN — Klasse 1 Mathematik (Geometrie-Basis)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentyp: 'Welche Form ist das?' mit visueller Form als Hauptbild
// und 4 Multiple-Choice-Antworten (alle als Wort).
// Formen: Kreis, Quadrat, Dreieck, Rechteck, Stern, Herz.
// 12 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

enum _Shape { kreis, quadrat, dreieck, rechteck, stern, herz }

extension _ShapeName on _Shape {
  String get displayName {
    switch (this) {
      case _Shape.kreis:
        return 'Kreis';
      case _Shape.quadrat:
        return 'Quadrat';
      case _Shape.dreieck:
        return 'Dreieck';
      case _Shape.rechteck:
        return 'Rechteck';
      case _Shape.stern:
        return 'Stern';
      case _Shape.herz:
        return 'Herz';
    }
  }
}

class FormenScreen extends StatefulWidget {
  const FormenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<FormenScreen> createState() => _FormenScreenState();
}

class _FormenScreenState extends State<FormenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 12;
  static const List<Color> _gradient = [
    Color(0xFFEC4899),
    Color(0xFFDB2777),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  _Shape? _selectedAnswer;

  late _Shape _correctShape;
  late List<_Shape> _answers;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _generateTask();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakTask());
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _generateTask() {
    final all = List.of(_Shape.values);
    all.shuffle(_rng);
    _correctShape = all.first;
    _answers = all.take(4).toList()..shuffle(_rng);
    if (!_answers.contains(_correctShape)) {
      _answers[0] = _correctShape;
      _answers.shuffle(_rng);
    }
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('Welche Form ist das?');
    } catch (_) {}
  }

  void _onAnswer(_Shape s) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = s;
      _answered = true;
    });
    final isCorrect = s == _correctShape;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(5);
      try {
        LumoVoice.instance
            .speak('Richtig! Das ist ein ${_correctShape.displayName}!');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(
            'Schau nochmal - das ist ein ${_correctShape.displayName}!');
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    _nextTask();
  }

  void _nextTask() {
    if (_taskIdx + 1 >= _totalTasks) {
      _showFinish();
      return;
    }
    setState(() {
      _taskIdx++;
      _generateTask();
    });
    _entryCtrl.forward(from: 0);
    _speakTask();
  }

  void _showFinish() {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correctCount * 8);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Geschafft!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Aufgaben richtig!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.star_rounded,
                    size: 38,
                    color: i < stars
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFD1D5DB)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(LumoPhrases.celebrate(),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Fertig',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: _gradient[0])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, child) {
                  return Opacity(opacity: _entryCtrl.value, child: child);
                },
                child: Column(children: [
                  _buildTaskHeader(),
                  const SizedBox(height: 24),
                  _buildShapeVisualization(),
                  const SizedBox(height: 32),
                  _buildAnswerGrid(),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _gradient),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Column(
            children: [
              Text('Aufgabe ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Formen erkennen',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFFCD34D), size: 18),
            const SizedBox(width: 4),
            Text('$_correctCount',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _buildTaskHeader() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(
            offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
        ),
        child: Text('Welche Form ist das?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _gradient[1])),
      ),
    );
  }

  Widget _buildShapeVisualization() {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: CustomPaint(
        painter: _ShapePainter(shape: _correctShape, color: _gradient[0]),
      ),
    );
  }

  Widget _buildAnswerGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _answers.map((s) => _buildAnswerButton(s)).toList(),
    );
  }

  Widget _buildAnswerButton(_Shape s) {
    final isSelected = _selectedAnswer == s;
    final isCorrect = s == _correctShape;
    Color bgColor = Colors.white;
    Color textColor = _gradient[1];
    Color borderColor = _gradient[0].withOpacity(0.3);
    if (_answered && isSelected) {
      if (isCorrect) {
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        borderColor = const Color(0xFF10B981);
      } else {
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        borderColor = const Color(0xFFEF4444);
      }
    } else if (_answered && isCorrect) {
      bgColor = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFFCD34D);
    }
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final scale = isSelected && isCorrect
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.08
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: _answered ? null : () => _onAnswer(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 3),
          ),
          child: Center(
            child: Text(s.displayName,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
          ),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.shape, required this.color});
  final _Shape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    switch (shape) {
      case _Shape.kreis:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.4, paint);
        break;
      case _Shape.quadrat:
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(w / 2, h / 2), width: w * 0.8, height: w * 0.8),
            paint);
        break;
      case _Shape.rechteck:
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(w / 2, h / 2), width: w * 0.85, height: h * 0.55),
            paint);
        break;
      case _Shape.dreieck:
        final path = Path()
          ..moveTo(w / 2, h * 0.1)
          ..lineTo(w * 0.1, h * 0.85)
          ..lineTo(w * 0.9, h * 0.85)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case _Shape.stern:
        _drawStar(canvas, Offset(w / 2, h / 2), w * 0.42, paint);
        break;
      case _Shape.herz:
        _drawHeart(canvas, Offset(w / 2, h / 2), w * 0.7, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = (i % 2 == 0) ? r : r * 0.5;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final w = size;
    final h = size * 0.9;
    final left = center.dx - w / 2;
    final top = center.dy - h / 2.5;
    path.moveTo(center.dx, top + h * 0.3);
    path.cubicTo(
        center.dx, top, left, top, left, top + h * 0.35);
    path.cubicTo(
        left, top + h * 0.65, center.dx, top + h * 0.95, center.dx, top + h);
    path.cubicTo(center.dx, top + h * 0.95, left + w, top + h * 0.65,
        left + w, top + h * 0.35);
    path.cubicTo(left + w, top, center.dx, top, center.dx, top + h * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.color != color;
}
