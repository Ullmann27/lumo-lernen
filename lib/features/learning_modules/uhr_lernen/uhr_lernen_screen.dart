// ════════════════════════════════════════════════════════════════════════
// DIE UHR — Klasse 2 Mathematik (interaktiv)
// ════════════════════════════════════════════════════════════════════════
// Visualisierung: echte Analog-Uhr mit Stunden- und Minutenzeiger.
// Kind sieht eine Uhrzeit gezeichnet und waehlt aus 4 Optionen die richtige.
// 8 Aufgaben pro Session: volle Stunden, halbe Stunden, Viertel.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class UhrLernenScreen extends StatefulWidget {
  const UhrLernenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<UhrLernenScreen> createState() => _UhrLernenScreenState();
}

class _UhrLernenScreenState extends State<UhrLernenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 8;
  static const List<Color> _gradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  String? _selectedAnswer;

  // Aktuelle Uhrzeit: 0-11 Stunde, Minute: 0|15|30|45
  late int _hour;
  late int _minute;
  late List<String> _answers;

  String get _correctText => _formatTime(_hour, _minute);

  String _formatTime(int h, int m) {
    if (m == 0) return '$h Uhr';
    if (m == 30) return 'halb ${h + 1}';
    if (m == 15) return 'Viertel nach $h';
    if (m == 45) return 'Viertel vor ${h + 1}';
    return '$h:${m.toString().padLeft(2, '0')}';
  }

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
    // Erste 2 Aufgaben: nur volle Stunden (leicht)
    // Dann auch halbe, dann Viertel
    final difficulty = _taskIdx < 2
        ? 0
        : _taskIdx < 5
            ? 1
            : 2;
    final minuteOptions = difficulty == 0
        ? [0]
        : difficulty == 1
            ? [0, 30]
            : [0, 15, 30, 45];
    _hour = 1 + _rng.nextInt(11); // 1..11
    _minute = minuteOptions[_rng.nextInt(minuteOptions.length)];

    final correctTxt = _correctText;
    final wrongOptions = <String>{};
    final possibles = <List<int>>[];
    for (int hh = 1; hh <= 11; hh++) {
      for (final mm in [0, 15, 30, 45]) {
        if (hh == _hour && mm == _minute) continue;
        possibles.add([hh, mm]);
      }
    }
    possibles.shuffle(_rng);
    for (final p in possibles) {
      if (wrongOptions.length >= 3) break;
      wrongOptions.add(_formatTime(p[0], p[1]));
    }
    _answers = [correctTxt, ...wrongOptions]..shuffle(_rng);
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('Wie spät ist es?');
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
      widget.appState.addXp(8);
      try {
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      _nextTask();
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(LumoPhrases.wrongGentle());
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      // Bei Uhr direkt weiter (richtig wird hervorgehoben)
      await Future.delayed(const Duration(milliseconds: 1500));
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
    widget.appState.addXp(_correctCount * 10);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🕐 Geschafft!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Uhrzeiten richtig!',
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
                  const Text('Wie spät ist es?',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6D28D9))),
                  const SizedBox(height: 16),
                  _buildClockFace(),
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
              Text('Uhrzeit ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Die Uhr',
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

  Widget _buildClockFace() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 6) * 5;
        return Transform.translate(
            offset: Offset(shake, 0), child: child);
      },
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Colors.white, Color(0xFFF3F4F6)],
            stops: [0.7, 1.0],
          ),
          border:
              Border.all(color: _gradient[1], width: 6),
          boxShadow: [
            BoxShadow(
                color: _gradient[0].withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: CustomPaint(
          painter: _ClockPainter(hour: _hour, minute: _minute, color: _gradient[1]),
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
      childAspectRatio: 2.5,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor)),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER für die Analog-Uhr
// ════════════════════════════════════════════════════════════════════════

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.hour, required this.minute, required this.color});
  final int hour;
  final int minute;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    // Stundenmarkierungen (1-12)
    final markPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final textStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: color,
    );
    for (int i = 1; i <= 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      // Markierung
      final markOuter = center +
          Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final markInner = center +
          Offset(math.cos(angle) * (radius - 10),
              math.sin(angle) * (radius - 10));
      canvas.drawLine(markInner, markOuter, markPaint);
      // Zahl
      final tp = TextPainter(
        text: TextSpan(text: '$i', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final textPos = center +
          Offset(math.cos(angle) * (radius - 28) - tp.width / 2,
              math.sin(angle) * (radius - 28) - tp.height / 2);
      tp.paint(canvas, textPos);
    }

    // Stundenzeiger (kürzer, dicker)
    final hourAngle =
        ((hour % 12) + minute / 60) / 12 * 2 * math.pi - math.pi / 2;
    final hourEnd = center +
        Offset(math.cos(hourAngle) * radius * 0.5,
            math.sin(hourAngle) * radius * 0.5);
    final hourPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, hourEnd, hourPaint);

    // Minutenzeiger (länger, dünner)
    final minuteAngle = (minute / 60) * 2 * math.pi - math.pi / 2;
    final minuteEnd = center +
        Offset(math.cos(minuteAngle) * radius * 0.75,
            math.sin(minuteAngle) * radius * 0.75);
    final minutePaint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, minuteEnd, minutePaint);

    // Mittelpunkt
    canvas.drawCircle(center, 8, Paint()..color = color);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.hour != hour || old.minute != minute || old.color != color;
}
