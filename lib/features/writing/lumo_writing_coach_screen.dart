// ════════════════════════════════════════════════════════════════════════
// LUMO SCHREIBCOACH LIVE — Screen
// ════════════════════════════════════════════════════════════════════════
// Heinz' Premium-Feature: Lumo schaut beim Schreiben zu und korrigiert.
//
// MVP 1 Flow:
//   1. Lumo sagt 'Schreib ein A!' (Buchstabe nicht sichtbar)
//   2. Kind zeichnet auf Canvas mit Finger
//   3. Kind drueckt 'Fertig' -> WritingFeedbackEngine analysiert
//   4. Wenn richtig -> Sterne + naechster Buchstabe
//   5. Wenn fast -> 'Probier nochmal'
//   6. Wenn falsch -> Lumo malt richtigen Buchstaben vor + Erklaerung
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_voice.dart';
import '../learning_modules/lumo_phrases.dart';
import 'writing_engine.dart';

class LumoWritingCoachScreen extends StatefulWidget {
  const LumoWritingCoachScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoWritingCoachScreen> createState() => _LumoWritingCoachScreenState();
}

class _LumoWritingCoachScreenState extends State<LumoWritingCoachScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 8;
  static const List<Color> _gradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
  ];

  late final AnimationController _demoCtrl;
  late final AnimationController _bounceCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  late String _currentLetter;
  late LetterTemplate _currentTemplate;
  final List<WritingStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  WritingFeedback? _lastFeedback;
  bool _showDemo = false;

  @override
  void initState() {
    super.initState();
    _demoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _pickNextLetter();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  @override
  void dispose() {
    _demoCtrl.dispose();
    _bounceCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _pickNextLetter() {
    final letters = LetterTemplates.availableLetters;
    _currentLetter = letters[_rng.nextInt(letters.length)];
    _currentTemplate = LetterTemplates.all[_currentLetter]!;
    _strokes.clear();
    _currentPoints = [];
    _lastFeedback = null;
    _showDemo = false;
  }

  void _speakPrompt() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('Schreib ein ${_currentLetter}!');
    } catch (_) {}
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _currentPoints = [d.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _currentPoints = [..._currentPoints, d.localPosition];
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentPoints.length > 1) {
      setState(() {
        _strokes.add(WritingStroke(List.of(_currentPoints)));
        _currentPoints = [];
      });
    }
  }

  void _clearCanvas() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentPoints = [];
      _lastFeedback = null;
      _showDemo = false;
    });
  }

  void _checkWriting() async {
    if (_strokes.isEmpty) return;
    HapticFeedback.lightImpact();
    final feedback = WritingFeedbackEngine.generate(
      template: _currentTemplate,
      userStrokes: _strokes,
    );
    setState(() {
      _lastFeedback = feedback;
      _showDemo = feedback.showDemo;
    });
    try {
      LumoVoice.instance.speak(feedback.message);
    } catch (_) {}
    if (feedback.type == FeedbackType.correct) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(2);
      widget.appState.addXp(10);
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      _nextTask();
    } else if (_showDemo) {
      _demoCtrl.forward(from: 0);
    }
  }

  void _nextTask() {
    if (_taskIdx + 1 >= _totalTasks) {
      _showFinish();
      return;
    }
    setState(() {
      _taskIdx++;
      _pickNextLetter();
    });
    _entryCtrl.forward(from: 0);
    _speakPrompt();
  }

  void _retry() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentPoints = [];
      _lastFeedback = null;
      _showDemo = false;
    });
  }

  void _replayDemo() {
    setState(() => _showDemo = true);
    _demoCtrl.forward(from: 0);
    try {
      LumoVoice.instance.speak(_currentTemplate.description);
    } catch (_) {}
  }

  void _showFinish() {
    final stars =
        ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correctCount * 12);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('✏️ Schreibcoach fertig!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Buchstaben richtig!',
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
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, child) {
                  return Opacity(opacity: _entryCtrl.value, child: child);
                },
                child: Column(children: [
                  _buildPrompt(),
                  const SizedBox(height: 16),
                  _buildCanvas(),
                  const SizedBox(height: 12),
                  if (_lastFeedback != null) _buildFeedback(),
                  const SizedBox(height: 12),
                  _buildControls(),
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
          child: Column(children: [
            Text('Aufgabe ${_taskIdx + 1} / $_totalTasks',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const Text('Schreibcoach',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ]),
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

  Widget _buildPrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
      ),
      child: Row(children: [
        const Text('🦊', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schreib ein ${_currentLetter}!',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _gradient[1])),
              Text('Mit dem Finger - keine Eile!',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _gradient[1].withOpacity(0.7))),
            ],
          ),
        ),
        IconButton(
          onPressed: _speakPrompt,
          icon: Icon(Icons.volume_up_rounded, color: _gradient[0], size: 32),
        ),
      ]),
    );
  }

  Widget _buildCanvas() {
    const canvasHeight = 280.0;
    return AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gradient[0].withOpacity(0.4), width: 3),
          boxShadow: [
            BoxShadow(
                color: _gradient[0].withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: AnimatedBuilder(
              animation: _demoCtrl,
              builder: (ctx, child) {
                return CustomPaint(
                  size: const Size(double.infinity, canvasHeight),
                  painter: _WritingCanvasPainter(
                    strokes: _strokes,
                    currentPoints: _currentPoints,
                    showDemo: _showDemo,
                    demoProgress: _demoCtrl.value,
                    template: _currentTemplate,
                    accent: _gradient[0],
                  ),
                  child: Container(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final f = _lastFeedback!;
    Color bg = const Color(0xFFD1FAE5);
    Color border = const Color(0xFF10B981);
    String icon = '✅';
    if (f.type == FeedbackType.almost) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFCD34D);
      icon = '👍';
    } else if (f.type == FeedbackType.missingStroke ||
        f.type == FeedbackType.demo) {
      bg = const Color(0xFFFEE2E2);
      border = const Color(0xFFEF4444);
      icon = '💡';
    }
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final s = f.matched && f.type == FeedbackType.correct
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.05
            : 1.0;
        return Transform.scale(scale: s, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(f.message,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: border)),
          ),
        ]),
      ),
    );
  }

  Widget _buildControls() {
    final readyForCheck = _strokes.isNotEmpty && _lastFeedback == null;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _btn(Icons.clear_rounded, 'Loeschen', const Color(0xFF6B7280), _clearCanvas),
        _btn(Icons.help_outline_rounded, 'Lumo zeigt', _gradient[0],
            _replayDemo),
        if (_lastFeedback != null && !_lastFeedback!.matched)
          _btn(Icons.refresh_rounded, 'Nochmal', _gradient[0], _retry),
        if (readyForCheck)
          _btn(Icons.check_circle_rounded, 'Fertig',
              const Color(0xFF10B981), _checkWriting),
        if (_lastFeedback != null && _lastFeedback!.matched)
          _btn(Icons.arrow_forward_rounded, 'Weiter',
              const Color(0xFF10B981), _nextTask),
      ],
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// CANVAS PAINTER — zeichnet Linien, User-Strokes und Demo-Strokes
// ════════════════════════════════════════════════════════════════════════

class _WritingCanvasPainter extends CustomPainter {
  _WritingCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.showDemo,
    required this.demoProgress,
    required this.template,
    required this.accent,
  });
  final List<WritingStroke> strokes;
  final List<Offset> currentPoints;
  final bool showDemo;
  final double demoProgress;
  final LetterTemplate template;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Schreiblinien: 3 horizontale Hilfslinien
    final linePaint = Paint()
      ..color = accent.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final topY = h * 0.18;
    final midY = h * 0.5;
    final botY = h * 0.82;
    canvas.drawLine(Offset(20, topY), Offset(w - 20, topY), linePaint);
    canvas.drawLine(Offset(20, midY), Offset(w - 20, midY), linePaint);
    canvas.drawLine(Offset(20, botY), Offset(w - 20, botY), linePaint);

    // Demo-Stroke: skaliere Template (100x100) auf einen Buchstaben-Bereich
    if (showDemo) {
      _drawDemo(canvas, size);
    }

    // User-Strokes
    final userPaint = Paint()
      ..color = accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      _drawStroke(canvas, s.points, userPaint);
    }
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, userPaint);
    }
  }

  void _drawDemo(Canvas canvas, Size size) {
    // Demo wird in einem zentrierten Bereich gezeichnet
    final w = size.width;
    final h = size.height;
    final letterSize = h * 0.7;
    final offsetX = (w - letterSize) / 2;
    final offsetY = (h - letterSize) / 2;

    final demoPaint = Paint()
      ..color = const Color(0xFFFCD34D).withOpacity(0.8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Anzahl Strokes
    final totalStrokes = template.demoStrokes.length;
    if (totalStrokes == 0) return;
    // Welcher Stroke ist gerade dran?
    final currentStrokeIdx = (demoProgress * totalStrokes).floor();
    final localProgress = (demoProgress * totalStrokes) - currentStrokeIdx;

    for (int i = 0; i < totalStrokes; i++) {
      final stroke = template.demoStrokes[i];
      final scaled = stroke
          .map((p) => Offset(
                offsetX + (p.dx / 100) * letterSize,
                offsetY + (p.dy / 100) * letterSize,
              ))
          .toList();
      if (i < currentStrokeIdx) {
        // Vollstaendig gezeichnet
        _drawStroke(canvas, scaled, demoPaint);
      } else if (i == currentStrokeIdx) {
        // Teilweise gezeichnet
        final partLen = (scaled.length * localProgress).ceil();
        if (partLen >= 2) {
          _drawStroke(canvas, scaled.sublist(0, partLen), demoPaint);
        }
      }
      // i > currentStrokeIdx: noch nicht
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WritingCanvasPainter old) =>
      old.strokes.length != strokes.length ||
      old.currentPoints != currentPoints ||
      old.showDemo != showDemo ||
      old.demoProgress != demoProgress ||
      old.template.letter != template.letter;
}
