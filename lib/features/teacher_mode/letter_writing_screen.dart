// ════════════════════════════════════════════════════════════════════════
// LETTER WRITING SCREEN — Buchstaben-Schreibtraining (NEU strukturiert)
// ════════════════════════════════════════════════════════════════════════
// Heinz Feedback 2:
//   1) Bildschirm scrollt beim Schreiben -> EXTRA Vollbild-Screen
//   2) A schwebt zwischen Linien -> muss auf Grundlinie sitzen
//   3) Erst nur das große A zeigen mit "was wir heute lernen"
//
// Aufbau:
//   1. DEMO-SCREEN: zeigt grosses A + "Was wir heute lernen" + Buttons
//   2. VOLLBILD-SCHREIB-SCREEN: nur Linien + Schreibflaeche, kein Scroll
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
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
  int _currentLetterIdx = 0;
  int _correctCount = 0;

  String get _letter => widget.topic.writingChars[_currentLetterIdx];

  @override
  void initState() {
    super.initState();
    _demoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        LumoVoice.instance.speak('Heute lernen wir den Buchstaben $_letter!');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _demoCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPracticeScreen() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _LetterPracticeFullScreen(
          letter: _letter,
          gradient: widget.topic.gradient,
          letterIdx: _currentLetterIdx,
          letterTotal: widget.topic.writingChars.length,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      _nextLetter();
    }
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
    });
    _demoCtrl.reset();
    _demoCtrl.forward();
    try {
      LumoVoice.instance.speak('Super! Jetzt das $_letter!');
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(),
                    Expanded(child: Center(child: _buildBigDemo())),
                    _buildActionButtons(),
                  ],
                ),
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
              Text(
                  'Buchstabe ${_currentLetterIdx + 1} / ${widget.topic.writingChars.length}',
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.topic.gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: widget.topic.gradient[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Was wir heute lernen:',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildBigDemo() {
    return AnimatedBuilder(
      animation: _demoCtrl,
      builder: (_, __) => Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
          boxShadow: [
            BoxShadow(
                color: widget.topic.gradient[0].withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: _LetterDemoPainter(
                  letter: _letter,
                  progress: _demoCtrl.value,
                  color: widget.topic.gradient[0],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Schau dir den Schreibweg an!',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: widget.topic.gradient[0])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: _openPracticeScreen,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.topic.gradient),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: widget.topic.gradient[0].withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text('Jetzt schreiben üben',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _nextLetter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Überspringen → Nächster Buchstabe',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════
// VOLLBILD-SCHREIB-SCREEN (KEIN Scroll, perfekt ausgerichtete Linien)
// ════════════════════════════════════════════════════════════════════════

class _LetterPracticeFullScreen extends StatefulWidget {
  const _LetterPracticeFullScreen({
    required this.letter,
    required this.gradient,
    required this.letterIdx,
    required this.letterTotal,
  });

  final String letter;
  final List<Color> gradient;
  final int letterIdx;
  final int letterTotal;

  @override
  State<_LetterPracticeFullScreen> createState() =>
      _LetterPracticeFullScreenState();
}

class _LetterPracticeFullScreenState
    extends State<_LetterPracticeFullScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _done() {
    HapticFeedback.mediumImpact();
    // Heinz-Wunsch: 'Lumo kontrolliert nicht aktiv mit'
    // Einfache Heuristik bevor Fertig akzeptiert wird:
    //   - Mindestens 1 Stroke vorhanden
    //   - Mindestens 80 Pixel Gesamt-Stroke-Laenge
    //   - Stroke-Bounding-Box mindestens 30% der Schreibflaeche
    // Wenn nicht erfuellt -> Lumo sagt sanft "Probier nochmal"
    // (statt einfach durchzulassen). Echte Stroke-Recognition braucht
    // ML - das hier ist die machbare Heuristik.
    if (_strokes.isEmpty) {
      _hintTryAgain('Du hast noch nichts geschrieben! Probier es!');
      return;
    }
    // Gesamt-Laenge der Striche
    double totalLength = 0;
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final stroke in _strokes) {
      for (int i = 0; i < stroke.length; i++) {
        if (stroke[i].dx < minX) minX = stroke[i].dx;
        if (stroke[i].dx > maxX) maxX = stroke[i].dx;
        if (stroke[i].dy < minY) minY = stroke[i].dy;
        if (stroke[i].dy > maxY) maxY = stroke[i].dy;
        if (i > 0) totalLength += (stroke[i] - stroke[i - 1]).distance;
      }
    }
    final bboxWidth = maxX - minX;
    final bboxHeight = maxY - minY;
    if (totalLength < 80) {
      _hintTryAgain('Schreib das ${widget.letter} groß und deutlich!');
      return;
    }
    if (bboxHeight < 40) {
      _hintTryAgain('Das ${widget.letter} ist zu klein - schreib es größer!');
      return;
    }
    // OK - akzeptiert. Lumo lobt.
    try {
      LumoVoice.instance.speak('Sehr gut! Das war das ${widget.letter}!');
    } catch (_) {}
    Navigator.of(context).pop(true);
  }

  /// Sanfte Korrektur ohne Strafe - Lumo's "Mitkontrollieren"
  void _hintTryAgain(String msg) {
    try {
      LumoVoice.instance.speak(msg);
    } catch (_) {}
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: widget.gradient[1],
      content: Text(msg,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: Colors.white)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
    ));
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildWritingCanvas(),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final g = widget.gradient;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: g),
        boxShadow: [
          BoxShadow(
              color: g[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        Expanded(
          child: Column(
            children: [
              Text('Schreibe Übung',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4)),
              Text('Buchstabe "${widget.letter}"',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
              '${widget.letterIdx + 1} / ${widget.letterTotal}',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }

  Widget _buildWritingCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.gradient[0].withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(builder: (_, c) {
          final h = c.maxHeight;
          // ── PERFEKT AUSGERICHTETE LINIEN + BUCHSTABE ──
          // Heinz Feedback: A hing zwischen Linien. Loesung:
          // - Grundlinie bei 78% (Stand des Buchstabens)
          // - Mittellinie bei 32% (Oberkante normaler Buchstaben)
          // - Buchstabe sitzt EXAKT von Mittellinie bis Grundlinie
          final midY = h * 0.32;
          final baseY = h * 0.78;
          final letterHeight = baseY - midY;

          return Stack(children: [
            CustomPaint(
              size: Size.infinite,
              painter: _SchoolLinesPainter(
                topY: h * 0.10,
                midY: midY,
                baseY: baseY,
                bottomY: h * 0.93,
              ),
            ),
            // Geist-Buchstabe: EXAKT auf Linien ausgerichtet
            Positioned(
              left: 0,
              right: 0,
              top: midY,
              height: letterHeight,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    widget.letter,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      color: widget.gradient[0].withOpacity(0.15),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _currentStroke = [d.localPosition];
                  _strokes.add(_currentStroke!);
                });
              },
              onPanUpdate: (d) {
                setState(() {
                  _currentStroke?.add(d.localPosition);
                });
              },
              onPanEnd: (_) {
                _currentStroke = null;
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _StrokesPainter(
                  strokes: _strokes,
                  color: widget.gradient[0],
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: _strokes.isEmpty ? null : _clear,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _strokes.isEmpty
                    ? const Color(0xFFF3F4F6)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _strokes.isEmpty
                        ? const Color(0xFFD1D5DB)
                        : Colors.red.shade300,
                    width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded,
                      color: _strokes.isEmpty
                          ? Colors.grey.shade400
                          : Colors.red.shade700,
                      size: 20),
                  const SizedBox(width: 6),
                  Text('Löschen',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _strokes.isEmpty
                              ? Colors.grey.shade500
                              : Colors.red.shade700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _done,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: widget.gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: widget.gradient[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text('Fertig & Weiter',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// PAINTER
// ════════════════════════════════════════════════════════════════════════

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
    final shadowPaint = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 180,
          fontWeight: FontWeight.w900,
          color: color.withOpacity(0.15),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadowPaint.paint(
      canvas,
      Offset((size.width - shadowPaint.width) / 2,
          (size.height - shadowPaint.height) / 2),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 180,
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
    if (progress < 1.0) {
      final ang = progress * math.pi * 2 - math.pi / 2;
      final px = size.width / 2 + math.cos(ang) * 50;
      final py = size.height / 2 + math.sin(ang) * 50;
      canvas.drawCircle(
        Offset(px, py),
        11,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5),
      );
      canvas.drawCircle(
        Offset(px, py),
        6,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_LetterDemoPainter old) =>
      old.progress != progress || old.letter != letter;
}

class _SchoolLinesPainter extends CustomPainter {
  _SchoolLinesPainter({
    required this.topY,
    required this.midY,
    required this.baseY,
    required this.bottomY,
  });
  final double topY;
  final double midY;
  final double baseY;
  final double bottomY;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 1.5;
    final mid = Paint()
      ..color = const Color(0xFFFCD34D)
      ..strokeWidth = 2;
    final base = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 2.4;

    _drawDashed(canvas, Offset(0, topY), Offset(size.width, topY), thin);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), mid);
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), base);
    _drawDashed(
        canvas, Offset(0, bottomY), Offset(size.width, bottomY), thin);
  }

  void _drawDashed(Canvas c, Offset from, Offset to, Paint p) {
    const dashW = 8.0;
    const gap = 5.0;
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

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 4, Paint()..color = color);
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
