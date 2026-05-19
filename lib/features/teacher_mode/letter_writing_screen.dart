// ════════════════════════════════════════════════════════════════════════
// LETTER WRITING SCREEN — Buchstaben-Schreibtraining
// ════════════════════════════════════════════════════════════════════════
// Heinz: 'A wird vorgezeichnet, dann gibt's Zeilen wo das Kind üben kann,
// wie in einem Schulheft, visualisiert und schön dargestellt.'
//
// Aufbau:
//   1. Großer Demo-Bereich: Buchstabe wird Schritt-für-Schritt animiert
//   2. 4 Übungszeilen mit Hilfslinien (Volksschul-Heft-Optik)
//   3. Kind zeichnet mit dem Finger
//   4. Reset/Weiter/Lumo-Lob
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_voice.dart';
import 'lumo_akademie_screen.dart';

class LetterWritingScreen extends StatefulWidget {
  const LetterWritingScreen({
    super.key,
    required this.appState,
    required this.topic,
    required this.subject,
  });

  final LumoAppState appState;
  final LearningTopic topic;
  final LearningSubject subject;

  @override
  State<LetterWritingScreen> createState() => _LetterWritingScreenState();
}

class _LetterWritingScreenState extends State<LetterWritingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _demoCtrl;
  late final AnimationController _bounceCtrl;
  int _currentLetterIdx = 0;
  int _correctCount = 0;
  // Strokes pro Übungszeile (4 Zeilen, je eine Liste von Strokes)
  final List<List<List<Offset>>> _practiceStrokes = [
    <List<Offset>>[],
    <List<Offset>>[],
    <List<Offset>>[],
    <List<Offset>>[],
  ];
  List<Offset>? _currentStroke;
  int _currentRow = 0;

  String get _letter => widget.topic.writingChars[_currentLetterIdx];

  @override
  void initState() {
    super.initState();
    _demoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        LumoVoice.instance.speak('Heute lernen wir den Buchstaben $_letter!');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _demoCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _nextLetter() {
    HapticFeedback.mediumImpact();
    setState(() {
      _correctCount++;
      if (_currentLetterIdx + 1 >= widget.topic.writingChars.length) {
        _showFinish();
        return;
      }
      _currentLetterIdx++;
      _resetPractice();
    });
    _demoCtrl.reset();
    _demoCtrl.forward();
    _bounceCtrl.forward(from: 0);
    try {
      LumoVoice.instance.speak('Super! Jetzt das $_letter!');
    } catch (_) {}
  }

  void _resetPractice() {
    for (final row in _practiceStrokes) {
      row.clear();
    }
    _currentStroke = null;
  }

  void _showFinish() {
    final stars = (_correctCount / widget.topic.writingChars.length * 5)
        .round()
        .clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correctCount * 10);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFEF3C7),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Alle Buchstaben!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              'Du hast ${widget.topic.writingChars.length} Buchstaben geschrieben!',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
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
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Weiter zur Akademie',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: widget.topic.gradient[0])),
          ),
        ],
      ),
    );
  }

  void _clearRow(int row) {
    setState(() => _practiceStrokes[row].clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _buildDemo(),
                  const SizedBox(height: 24),
                  _buildPracticeSheet(),
                  const SizedBox(height: 20),
                  _buildBottomActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final g = widget.topic.gradient;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: g),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: g[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
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
              Text('Buchstabe ${_currentLetterIdx + 1} / ${widget.topic.writingChars.length}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              Text(widget.topic.title,
                  style: const TextStyle(
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

  Widget _buildDemo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.topic.gradient[0].withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.topic.gradient),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('LUMO ZEIGT',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _demoCtrl.forward(from: 0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(Icons.replay_rounded,
                    size: 16, color: widget.topic.gradient[0]),
                const SizedBox(width: 4),
                Text('Nochmal',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: widget.topic.gradient[0])),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // Großer Demo-Buchstabe mit animierter Schrift-Linie
        AnimatedBuilder(
          animation: _demoCtrl,
          builder: (_, __) => SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(300, 200),
              painter: _LetterDemoPainter(
                letter: _letter,
                progress: _demoCtrl.value,
                color: widget.topic.gradient[0],
              ),
            ),
          ),
        ),
        Text('"$_letter" - sieh dir an wie es geht!',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.topic.gradient[0])),
      ]),
    );
  }

  Widget _buildPracticeSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('JETZT DU!',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Color(0xFF92400E),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
          const Spacer(),
          Text('Mit dem Finger schreiben',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600)),
        ]),
        const SizedBox(height: 12),
        // 4 Übungszeilen
        for (int row = 0; row < 4; row++) ...[
          _buildPracticeRow(row),
          if (row < 3) const SizedBox(height: 8),
        ],
      ]),
    );
  }

  Widget _buildPracticeRow(int row) {
    final hint = row == 0; // Nur erste Zeile zeigt Geist-Buchstabe als Hilfe
    return Stack(children: [
      Container(
        height: 84,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1),
        ),
        child: Stack(children: [
          // Hilfslinien (Schulheft-Style)
          CustomPaint(
            size: const Size(double.infinity, 84),
            painter: _SchoolLinesPainter(),
          ),
          // Geist-Buchstabe in erster Zeile als Vorlage
          if (hint)
            ...List.generate(
                3,
                (i) => Positioned(
                      left: 20.0 + i * 90,
                      top: 8,
                      child: Opacity(
                        opacity: 0.15,
                        child: Text(_letter,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 60,
                                fontWeight: FontWeight.w900,
                                color: widget.topic.gradient[0])),
                      ),
                    )),
          // Mal-Fläche
          GestureDetector(
            onPanStart: (d) {
              setState(() {
                _currentRow = row;
                _currentStroke = [d.localPosition];
                _practiceStrokes[row].add(_currentStroke!);
              });
            },
            onPanUpdate: (d) {
              if (_currentRow != row) return;
              setState(() {
                _currentStroke?.add(d.localPosition);
              });
            },
            onPanEnd: (_) {
              _currentStroke = null;
            },
            child: CustomPaint(
              size: const Size(double.infinity, 84),
              painter: _StrokesPainter(
                strokes: _practiceStrokes[row],
                color: widget.topic.gradient[0],
              ),
            ),
          ),
        ]),
      ),
      // Clear-Button
      if (_practiceStrokes[row].isNotEmpty)
        Positioned(
          right: 6,
          top: 6,
          child: GestureDetector(
            onTap: () => _clearRow(row),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 16, color: Colors.red.shade700),
            ),
          ),
        ),
    ]);
  }

  Widget _buildBottomActions() {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => setState(_resetPractice),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
            ),
            child: const Center(
              child: Text('Alles löschen',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280))),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: _nextLetter,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.topic.gradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: widget.topic.gradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Center(
              child: Text('Nächster Buchstabe ✓',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Demo-Painter: zeigt Buchstabe mit Schrift-Pfeil ─────────────────────
class _LetterDemoPainter extends CustomPainter {
  _LetterDemoPainter({
    required this.letter,
    required this.progress,
    required this.color,
  });
  final String letter;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Buchstabe mit Schatten-Effekt
    final shadowPaint = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 160,
          fontWeight: FontWeight.w900,
          color: color.withOpacity(0.12 + progress * 0.12),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadowPaint.paint(
      canvas,
      Offset((size.width - shadowPaint.width) / 2,
          (size.height - shadowPaint.height) / 2),
    );
    // Vordergrund
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 160,
          fontWeight: FontWeight.w900,
          color: color.withOpacity(progress),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
    // Schreibrichtungs-Punkt (Pfeil der dem Buchstaben folgt)
    if (progress < 1.0) {
      final ang = progress * math.pi * 2;
      final px = size.width / 2 + math.cos(ang) * 40;
      final py = size.height / 2 + math.sin(ang) * 40;
      canvas.drawCircle(
        Offset(px, py),
        9,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
      );
      canvas.drawCircle(
        Offset(px, py),
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_LetterDemoPainter old) =>
      old.progress != progress || old.letter != letter;
}

// ── Schulheft-Hilfslinien (4 Linien wie Volksschule Österreich) ─────────
class _SchoolLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 4 Linien: Oberlinie (gestrichelt), Mittellinie (durchgehend, dicker),
    // Grundlinie (durchgehend), Unterlinie (gestrichelt)
    final thin = Paint()
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 1;
    final mid = Paint()
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 1.5;
    final base = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 1.8;

    // Linien-Positionen relativ zur Höhe 84:
    final h = size.h(0);
    // 4 Linien in Schulheft-Standard
    _drawDashed(canvas, Offset(0, h * 0.15), Offset(size.width, h * 0.15), thin);
    canvas.drawLine(Offset(0, h * 0.45), Offset(size.width, h * 0.45), mid);
    canvas.drawLine(Offset(0, h * 0.75), Offset(size.width, h * 0.75), base);
    _drawDashed(canvas, Offset(0, h * 0.95), Offset(size.width, h * 0.95), thin);
  }

  void _drawDashed(Canvas c, Offset from, Offset to, Paint p) {
    const dashW = 6.0;
    const gap = 4.0;
    final dx = to.dx - from.dx;
    final n = dx ~/ (dashW + gap);
    for (int i = 0; i < n; i++) {
      final x1 = from.dx + i * (dashW + gap);
      c.drawLine(Offset(x1, from.dy), Offset(x1 + dashW, to.dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

extension on Size {
  double h(double _) => height;
}

// ── Strokes-Painter: zeichnet die Striche des Kindes ────────────────────
class _StrokesPainter extends CustomPainter {
  _StrokesPainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 3, Paint()..color = color);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) =>
      old.strokes.length != strokes.length || old.color != color;
}
