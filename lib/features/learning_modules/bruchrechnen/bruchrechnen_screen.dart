// ════════════════════════════════════════════════════════════════════════
// BRUCHRECHNEN — Klasse 4 Mathematik (interaktiv mit Pizza-Visualisierung)
// ════════════════════════════════════════════════════════════════════════
// Pizza wird in 2-8 Stuecke geteilt, ein Teil gegessen.
// Kind tippt richtigen Bruch (1/2, 1/3, 1/4, ...).
// 8 Aufgaben pro Session, progressive Schwierigkeit.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class BruchrechnenScreen extends StatefulWidget {
  const BruchrechnenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<BruchrechnenScreen> createState() => _BruchrechnenScreenState();
}

class _BruchrechnenScreenState extends State<BruchrechnenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 8;
  static const List<Color> _gradient = [Color(0xFFF59E0B), Color(0xFFB45309)];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  String? _selectedAnswer;

  // Aktuelle Aufgabe: pizza in _nenner Stuecke, _gegessen Stuecke gegessen.
  // Frage: "Welcher Bruch wurde gegessen?" -> Antwort: gegessen/nenner
  late int _nenner;
  late int _gegessen;
  late List<String> _answers;

  String get _correctText => '$_gegessen/$_nenner';

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
    // Progressiver Schwierigkeitsgrad:
    // Aufgabe 1-2: Halbe (1/2)
    // Aufgabe 3-4: Drittel/Viertel
    // Aufgabe 5-8: bis Achtel
    final maxNenner = _taskIdx < 2
        ? 2
        : _taskIdx < 4
            ? 4
            : 8;
    _nenner = 2 + _rng.nextInt(maxNenner - 1); // 2..maxNenner
    _gegessen = 1 + _rng.nextInt(_nenner - 1); // 1..nenner-1

    // 3 plausible Falschoptionen
    final correctTxt = _correctText;
    final wrongs = <String>{};
    while (wrongs.length < 3) {
      final n = 2 + _rng.nextInt(7); // nenner 2..8
      final g = 1 + _rng.nextInt(n - 1);
      final txt = '$g/$n';
      if (txt != correctTxt && !wrongs.contains(txt)) wrongs.add(txt);
    }
    _answers = [correctTxt, ...wrongs]..shuffle(_rng);
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('Welcher Bruch wurde gegessen?');
    } catch (_) {}
  }

  void _onAnswer(String answer) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final isCorrect = answer == _correctText;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(10);
      try {
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      _nextTask();
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(
            '${LumoPhrases.wrongGentle()} Das war $_gegessen von $_nenner Stuecken.');
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 2400));
      if (!mounted) return;
      _nextTask();
    }
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
    widget.appState.addXp(_correctCount * 12);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🍕 Geschafft!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Brüche richtig!',
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
                builder: (_, child) =>
                    Opacity(opacity: _entryCtrl.value, child: child),
                child: Column(children: [
                  const Text('Welcher Bruch wurde gegessen?',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309))),
                  const SizedBox(height: 16),
                  _buildPizzaVisualization(),
                  const SizedBox(height: 12),
                  Text('Von $_nenner Stücken wurden $_gegessen gegessen.',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E))),
                  const SizedBox(height: 24),
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
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.3),
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
              Text('Bruch ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Bruchrechnen',
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

  Widget _buildPizzaVisualization() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 6) * 5;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(
          painter: _PizzaPainter(
            slices: _nenner,
            eatenSlices: _gegessen,
          ),
        ),
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
      childAspectRatio: 2.0,
      children: _answers.map((a) => _buildAnswerButton(a)).toList(),
    );
  }

  Widget _buildAnswerButton(String value) {
    final isSelected = _selectedAnswer == value;
    final isCorrect = value == _correctText;
    Color bgColor = Colors.white;
    Color textColor = _gradient[1];
    Color borderColor = _gradient[0].withOpacity(0.3);
    if (_answered) {
      if (isSelected && isCorrect) {
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        borderColor = const Color(0xFF10B981);
      } else if (isSelected && !isCorrect) {
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        borderColor = const Color(0xFFEF4444);
      } else if (!isSelected && isCorrect) {
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFCD34D);
      }
    }
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final s = isSelected && isCorrect
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.1
            : 1.0;
        return Transform.scale(scale: s, child: child);
      },
      child: GestureDetector(
        onTap: _answered ? null : () => _onAnswer(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              BoxShadow(
                  color: borderColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Center(
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// PIZZA-PAINTER mit Schatten + gegessenen Stuecken
// ════════════════════════════════════════════════════════════════════════

class _PizzaPainter extends CustomPainter {
  _PizzaPainter({required this.slices, required this.eatenSlices});
  final int slices;
  final int eatenSlices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final sliceAngle = 2 * math.pi / slices;

    // Schatten unter der Pizza
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 4, center.dy + 8),
        width: radius * 2.1,
        height: radius * 0.4,
      ),
      Paint()..color = Colors.black.withOpacity(0.15),
    );

    // Krustenring
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFCD8B43)
          ..style = PaintingStyle.fill);

    // Innerer Käse-Bereich
    canvas.drawCircle(
        center,
        radius * 0.92,
        Paint()
          ..color = const Color(0xFFFCD34D)
          ..style = PaintingStyle.fill);

    // Gegessene Stuecke abdecken (heller / weiss = gegessen)
    for (int i = 0; i < eatenSlices; i++) {
      final startAngle = -math.pi / 2 + i * sliceAngle;
      // Gegessene Stuecke: weisses Feld
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
              Rect.fromCircle(center: center, radius: radius * 0.92),
              startAngle,
              sliceAngle,
              false)
          ..close(),
        Paint()
          ..color = const Color(0xFFF3F4F6)
          ..style = PaintingStyle.fill,
      );
      // Stricheltextur damit man sieht: "weg"
      _drawHatching(canvas, center, radius * 0.92, startAngle, sliceAngle);
    }

    // Belag-Pepperoni-Dots auf den NICHT-gegessenen Stuecken
    final pepRng = math.Random(slices * 17 + eatenSlices);
    for (int i = eatenSlices; i < slices; i++) {
      final startAngle = -math.pi / 2 + i * sliceAngle;
      final midAngle = startAngle + sliceAngle / 2;
      // 2-3 Pepperoni pro Stueck
      final dotCount = 2 + (i % 2);
      for (int d = 0; d < dotCount; d++) {
        final dist = (0.35 + pepRng.nextDouble() * 0.45) * radius;
        final a = midAngle + (pepRng.nextDouble() - 0.5) * sliceAngle * 0.7;
        final cx = center.dx + math.cos(a) * dist;
        final cy = center.dy + math.sin(a) * dist;
        canvas.drawCircle(Offset(cx, cy), 6,
            Paint()..color = const Color(0xFFDC2626));
        canvas.drawCircle(Offset(cx, cy), 4,
            Paint()..color = const Color(0xFFB91C1C));
      }
    }

    // Trennlinien zwischen Stuecken
    final linePaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < slices; i++) {
      final a = -math.pi / 2 + i * sliceAngle;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(a) * radius,
            center.dy + math.sin(a) * radius),
        linePaint,
      );
    }

    // Krustenring oben drauf
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF92400E)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
  }

  void _drawHatching(Canvas canvas, Offset center, double radius,
      double startAngle, double sliceAngle) {
    final hatchPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5;
    // Pfad fuer den Stueck-Bereich
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius),
          startAngle, sliceAngle, false)
      ..close();
    canvas.save();
    canvas.clipPath(path);
    // Diagonale Stricheln
    for (double offset = -radius * 2; offset < radius * 2; offset += 8) {
      canvas.drawLine(
        Offset(center.dx - radius + offset, center.dy - radius),
        Offset(center.dx + offset, center.dy + radius),
        hatchPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PizzaPainter old) =>
      old.slices != slices || old.eatenSlices != eatenSlices;
}
