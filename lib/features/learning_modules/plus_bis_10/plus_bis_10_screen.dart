// ════════════════════════════════════════════════════════════════════════
// PLUS BIS 10 — Erstes echtes interaktives Lern-Modul (Klasse 1 Mathematik)
// ════════════════════════════════════════════════════════════════════════
// Heinz Feedback: 'Alle Optionen sind nur Chats - keine aktiven Lern-Module'.
//
// Loesung: Echtes Tap-basiertes Uebungs-Modul mit:
//   - 10 Aufgaben pro Session
//   - Visualisierung mit Aepfeln (Zaehlbar)
//   - 4 Multiple-Choice Antwort-Buttons
//   - Bei richtig: Lumo lobt, Sterne, naechste Aufgabe
//   - Bei falsch: Sanftes Feedback, Erklaerung mit Bildern, nochmal
//   - Am Ende: Auswertung mit Sternen
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import '../../../core/lumo_companion_state.dart';
import '../../../core/lumo_cosmos.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class PlusBis10Screen extends StatefulWidget {
  const PlusBis10Screen({
    super.key,
    required this.appState,
  });

  final LumoAppState appState;

  @override
  State<PlusBis10Screen> createState() => _PlusBis10ScreenState();
}

class _PlusBis10ScreenState extends State<PlusBis10Screen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFFFB923C),
    Color(0xFFEA580C),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  int _wrongAttempts = 0;
  bool _showHint = false;
  bool _answered = false;
  int? _selectedAnswer;

  // Aktuelle Aufgabe
  late int _a;
  late int _b;
  late List<int> _answers;

  int get _correct => _a + _b;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _generateTask();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakTask();
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _generateTask() {
    // a + b mit a+b <= 10, a >= 1, b >= 1
    _a = 1 + _rng.nextInt(5); // 1-5
    _b = 1 + _rng.nextInt(10 - _a); // mind. 1, max. 10 - a
    if (_b < 1) _b = 1;

    // 4 Antworten: richtige + 3 plausibel falsche.
    // Heinz-Scan 2026-05-21: bisherige Loop hatte Edge-Case wo
    // wrong == _correct (innerhalb 0..10) weder if- noch else-if-
    // Branch traf -> potenzielle Endlos-Iteration. Neu: klare
    // 2-Stufen-Strategie: zuerst nahe Plausibel-Werte, dann beliebige
    // 0..10 als Fallback.
    final answers = <int>{_correct};
    // Stufe 1: Plausibel-nahe Werte (correct +/- 1..2)
    final nearby = <int>[
      for (final d in const [-2, -1, 1, 2])
        if (_correct + d >= 0 && _correct + d <= 10) _correct + d,
    ]..shuffle(_rng);
    for (final n in nearby) {
      if (answers.length >= 4) break;
      answers.add(n);
    }
    // Stufe 2: Fallback aus 0..10 (falls correct am Rand liegt, zb
    // 0 oder 10, gibt's weniger nearby).
    int safety = 30;
    while (answers.length < 4 && safety-- > 0) {
      final cand = _rng.nextInt(11);
      if (cand != _correct) answers.add(cand);
    }
    _answers = answers.toList()..shuffle(_rng);
    _showHint = false;
    _answered = false;
    _selectedAnswer = null;
    _wrongAttempts = 0;
  }

  void _speakTask() {
    try {
      LumoVoice.instance.speak('$_a plus $_b - wie viel ist das?');
    } catch (_) {}
  }

  void _handleAnswer(int answer) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
    });

    if (answer == _correct) {
      _handleCorrect();
    } else {
      _handleWrong(answer);
    }
  }

  void _handleCorrect() async {
    setState(() {
      _answered = true;
      _correctCount++;
    });
    _bounceCtrl.forward(from: 0);
    HapticFeedback.mediumImpact();
    widget.appState.addStars(1);
    widget.appState.addXp(5);
    // Cosmos-Belohnung: pflanze einen Baum in der Welt!
    CosmosWorld.instance.grantReward(
      subjectId: 'm1_plus10',
      isMath: true,
      isPerfect: false,
    );
      LumoCompanionState.instance.recordCorrect(topic: 'math');
    try {
      LumoVoice.instance.speak(LumoPhrases.correct());
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    _nextTask();
  }

  void _handleWrong(int answer) async {
    setState(() {
      _wrongAttempts++;
    });
    _shakeCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();
    try {
      LumoVoice.instance.speak(LumoPhrases.wrongGentle());
    } catch (_) {}

    // Nach 2 Fehlversuchen: Hint zeigen
    if (_wrongAttempts >= 2 && !_showHint) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _showHint = true;
        _selectedAnswer = null;
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _selectedAnswer = null;
      });
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
    _entryCtrl.reset();
    _entryCtrl.forward();
    _speakTask();
  }

  void _showFinish() {
    final percent = _correctCount / _totalTasks;
    final stars = (percent * 5).round().clamp(1, 5);
    widget.appState.addStars(stars * 2);
    widget.appState.addXp(_correctCount * 10);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFEF3C7),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Text(
          percent >= 0.8
              ? '🎉 ${LumoPhrases.celebrate()}'
              : '👍 Geschafft!',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Du hast $_correctCount von $_totalTasks Aufgaben richtig!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.star_rounded,
                    size: 42,
                    color: i < stars
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFD1D5DB)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              percent >= 0.8
                  ? 'Du bist ein Plus-Profi! 🦊'
                  : 'Gut! Probier nochmal für mehr Sterne!',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: _gradient[0],
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ]),
        actions: [
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Fertig',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6B7280))),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _taskIdx = 0;
                    _correctCount = 0;
                    _generateTask();
                  });
                  _entryCtrl.reset();
                  _entryCtrl.forward();
                  _speakTask();
                },
                child: Text('Nochmal',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        color: _gradient[0])),
              ),
            ),
          ]),
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
              child: AnimatedBuilder(
                animation: Listenable.merge([_entryCtrl, _shakeCtrl]),
                builder: (_, __) {
                  final shake = _shakeCtrl.value < 1.0
                      ? math.sin(_shakeCtrl.value * math.pi * 4) * 8
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(shake, 0),
                    child: FadeTransition(
                      opacity: _entryCtrl,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTaskCard(),
                            if (_showHint) _buildHintCard(),
                            _buildAnswerButtons(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _gradient),
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
              Text('Aufgabe ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Plus bis 10',
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

  Widget _buildTaskCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFED7AA), width: 2),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        // Aufgaben-Text
        Text('$_a + $_b = ?',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: _gradient[1],
              letterSpacing: 2,
            )),
        const SizedBox(height: 16),
        // Visualisierung mit Aepfeln/Sternen
        _buildVisualization(),
      ]),
    );
  }

  Widget _buildVisualization() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        ...List.generate(_a,
            (i) => const Icon(Icons.apple_rounded, color: Color(0xFFEF4444), size: 38)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('+',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _gradient[1])),
        ),
        ...List.generate(_b,
            (i) => const Icon(Icons.apple_rounded, color: Color(0xFF22C55E), size: 38)),
      ],
    );
  }

  Widget _buildHintCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 2),
      ),
      child: Row(children: [
        const Icon(Icons.lightbulb_rounded,
            color: Color(0xFFCA8A04), size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LumoPhrases.hint(),
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFCA8A04),
                      letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(
                  'Zähle alle Äpfel zusammen: ${List.filled(_a, '🍎').join('')} und ${List.filled(_b, '🍏').join('')}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF78350F))),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildAnswerButtons() {
    return Column(children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: _answers.map((ans) {
          final isSelected = _selectedAnswer == ans;
          final isCorrect = _answered && ans == _correct;
          final isWrong = isSelected && ans != _correct;

          Color bg = Colors.white;
          Color textColor = _gradient[1];
          Color borderColor = const Color(0xFFFED7AA);

          if (isCorrect) {
            bg = const Color(0xFF22C55E);
            textColor = Colors.white;
            borderColor = const Color(0xFF15803D);
          } else if (isWrong) {
            bg = const Color(0xFFFEE2E2);
            textColor = const Color(0xFFB91C1C);
            borderColor = const Color(0xFFEF4444);
          }

          return AnimatedScale(
            scale: isCorrect ? 1.0 + (_bounceCtrl.value * 0.1) : 1.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => _handleAnswer(ans),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: borderColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                alignment: Alignment.center,
                child: Text('$ans',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}
