// ════════════════════════════════════════════════════════════════════════
// GELD LERNEN — Klasse 2 Mathematik
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Wie viel Geld siehst du?' (Muenzen zaehlen, bis 10 Euro)
//   - 'Welche Münze ist 2 Euro?' (Muenze finden)
//   - 'Du hast X Euro, was kannst du kaufen?' (Kaufen-Aufgabe)
// 10 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import '../../../widgets/design/lumo_learning_module_frame.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';
import '../learning_module_progress.dart';

class _Muenze {
  const _Muenze({
    required this.wert,
    required this.label,
    required this.color,
    required this.borderColor,
  });
  final int wert; // in Cent (100 = 1 Euro)
  final String label;
  final Color color;
  final Color borderColor;
}

enum _GeldFrageTyp { zaehlen, muenzeFinden }

class GeldScreen extends StatefulWidget {
  const GeldScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<GeldScreen> createState() => _GeldScreenState();
}

class _GeldScreenState extends State<GeldScreen> with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFFCA8A04),
    Color(0xFF92400E),
  ];

  // Euro-Muenzen
  static const List<_Muenze> _muenzen = [
    _Muenze(
        wert: 10,
        label: '10c',
        color: Color(0xFFCA8A04),
        borderColor: Color(0xFF92400E)),
    _Muenze(
        wert: 20,
        label: '20c',
        color: Color(0xFFEAB308),
        borderColor: Color(0xFF92400E)),
    _Muenze(
        wert: 50,
        label: '50c',
        color: Color(0xFFFCD34D),
        borderColor: Color(0xFF92400E)),
    _Muenze(
        wert: 100,
        label: '1€',
        color: Color(0xFFFEF3C7),
        borderColor: Color(0xFF6B7280)),
    _Muenze(
        wert: 200,
        label: '2€',
        color: Color(0xFFF5F3FF),
        borderColor: Color(0xFFCA8A04)),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  late final LearningModuleProgress _progress;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedAnswer;

  late _GeldFrageTyp _typ;
  late List<_Muenze> _muenzenAufTisch;
  late int _gesamtWert; // in Cent
  late _Muenze _gefragteMuenze;
  late List<int> _answers; // in Cent

  @override
  void initState() {
    super.initState();
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Mathematik',
      unit: 'Geld',
    );
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _generateTask();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakTask());
  }

  @override
  void dispose() {
    _progress.dispose();
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _generateTask() {
    _typ = _GeldFrageTyp.values[_rng.nextInt(_GeldFrageTyp.values.length)];
    if (_typ == _GeldFrageTyp.zaehlen) {
      // 1-4 Muenzen zaehlen, max 10 Euro total.
      // FIX: Vorher hat `continue` im for-Loop den Index weiterlaufen lassen,
      // sodass weniger Muenzen herauskamen als gewollt - z.B. 1 Muenze
      // statt 4. Jetzt mit retry-Limit: bei Limit-Treffern wird nur die
      // zu teure Muenze uebersprungen, der Slot aber neu versucht.
      _muenzenAufTisch = [];
      _gesamtWert = 0;
      final count = 1 + _rng.nextInt(4); // 1..4 Muenzen
      var safety = 0;
      while (_muenzenAufTisch.length < count && safety < 30) {
        safety++;
        final m = _muenzen[_rng.nextInt(_muenzen.length)];
        if (_gesamtWert + m.wert > 1000) continue;
        _muenzenAufTisch.add(m);
        _gesamtWert += m.wert;
      }
      if (_muenzenAufTisch.isEmpty) {
        // Fallback (sollte mit Safety eigentlich nicht mehr noetig sein)
        _muenzenAufTisch.add(_muenzen[0]);
        _gesamtWert = _muenzen[0].wert;
      }
      final wrong = <int>{};
      while (wrong.length < 3) {
        final delta = (10 + _rng.nextInt(50)) * (_rng.nextBool() ? 1 : -1);
        final cand = _gesamtWert + delta;
        if (cand > 0 && cand != _gesamtWert) wrong.add(cand);
      }
      _answers = [_gesamtWert, ...wrong]..shuffle(_rng);
    } else {
      // muenzeFinden: zeige 4 Muenzen, frage nach einer bestimmten
      _gefragteMuenze = _muenzen[_rng.nextInt(_muenzen.length)];
      _muenzenAufTisch = (List.of(_muenzen)..shuffle(_rng)).take(4).toList();
      if (!_muenzenAufTisch.contains(_gefragteMuenze)) {
        _muenzenAufTisch[0] = _gefragteMuenze;
        _muenzenAufTisch.shuffle(_rng);
      }
      // answers werden direkt ueber muenzenAufTisch indiziert
    }
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    if (_typ == _GeldFrageTyp.zaehlen) {
      text = 'Wie viel Geld siehst du?';
    } else {
      text = 'Welche Münze ist ${_gefragteMuenze.label}?';
    }
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  String _formatCent(int cent) {
    if (cent < 100) return '$cent Cent';
    if (cent % 100 == 0) return '${cent ~/ 100} Euro';
    return '${cent ~/ 100} Euro ${cent % 100}';
  }

  void _onAnswer(int idx, bool isCorrect) async {
    if (_answered || _progress.hasPending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = idx;
      _answered = true;
    });
    final saved = await _progress.saveAnswer(
      problemKey: _typ == _GeldFrageTyp.zaehlen ? 'Münzen: ${(_muenzenAufTisch.map((m) => m.wert).toList()..sort()).join(",")}' : 'Münze finden: ${_gefragteMuenze.wert}' ,
      correct: isCorrect,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 7 : 0,
    );
    if (!saved || !mounted) return;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      setState(() => _correctCount++);
      try {
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(LumoPhrases.wrongGentle());
      } catch (_) {}
    }
    if (!await _progress.feedbackDelay(const Duration(milliseconds: 1300)) ||
        !mounted) {
      return;
    }
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

  Future<void> _showFinish() async {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    final saved =
        await _progress.saveBonus(stars: stars, xp: _correctCount * 10);
    if (!saved || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('💰 Geld-Quiz fertig!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
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
    return LearningModuleProgressScope(
      progress: _progress,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: 'Mathe-Abenteuer',
        moduleTitle: 'Geld lernen',
        icon: Icons.payments_rounded,
        taskIndex: _taskIdx,
        totalTasks: _totalTasks,
        correctAnswers: _correctCount,
        progressLabel: 'Aufgabe',
        canLeave: () => !_progress.hasPending,
        child: AnimatedBuilder(
          animation: _entryCtrl,
          builder: (_, child) {
            return Opacity(
                opacity: LumoLessonStyle.reducedMotion(context, widget.appState)
                    ? 1
                    : _entryCtrl.value,
                child: child);
          },
          child: Column(children: [
            _buildTaskHeader(),
            const SizedBox(height: 12),
            if (_typ == _GeldFrageTyp.zaehlen) ...[
              _buildCoinsOnTable(),
              const SizedBox(height: 12),
              _buildCentAnswerGrid(),
            ] else ...[
              _buildCoinAnswerGrid(),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    String text;
    if (_typ == _GeldFrageTyp.zaehlen) {
      text = 'Wie viel Geld siehst du?';
    } else {
      text = 'Welche Münze ist ${_gefragteMuenze.label}?';
    }
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = LumoLessonStyle.reducedMotion(context, widget.appState)
            ? 0.0
            : math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 2),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ),
    );
  }

  Widget _buildCoinsOnTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 2),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children:
            _muenzenAufTisch.map((m) => _buildCoinWidget(m, size: 70)).toList(),
      ),
    );
  }

  Widget _buildCoinWidget(_Muenze m, {double size = 60}) {
    // 3D-Muenze: RadialGradient mit Highlight oben links und Schatten
    // unten rechts. Innen ein leicht abgesetzter Ring fuer den geprägten
    // Eindruck. Heinz Polish-Runde 2: vorher waren die Muenzen flach.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [
            Color.lerp(m.color, Colors.white, 0.45)!,
            m.color,
            Color.lerp(m.color, m.borderColor, 0.55)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: m.borderColor, width: 2.4),
        boxShadow: [
          BoxShadow(
            color: m.borderColor.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.55),
            blurRadius: 4,
            offset: const Offset(-1, -1),
            spreadRadius: -1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.82,
        height: size * 0.82,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: m.borderColor.withOpacity(0.55), width: 1.2),
        ),
        child: Text(m.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: size * 0.26,
                fontWeight: FontWeight.w900,
                color: m.borderColor,
                height: 1.0)),
      ),
    );
  }

  Widget _buildCentAnswerGrid() {
    return LumoLessonAnswerGrid(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _answers.asMap().entries.map((entry) {
        final idx = entry.key;
        final val = entry.value;
        final isCorrect = val == _gesamtWert;
        final isSelected = _selectedAnswer == idx;
        Color bgColor = LumoVisualTokens.lessonAnswer;
        Color textColor = LumoVisualTokens.white;
        Color borderColor = LumoVisualTokens.cyan.withValues(alpha: .8);
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
          textColor = const Color(0xFF713F12);
          borderColor = const Color(0xFFFCD34D);
        }
        return AnimatedBuilder(
          animation: _bounceCtrl,
          builder: (_, child) {
            final scale = isSelected &&
                    isCorrect &&
                    !LumoLessonStyle.reducedMotion(context, widget.appState)
                ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.08
                : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: LumoLessonAnswerTap(
            correct: _answered && isSelected ? isCorrect : null,
            onTap: _answered ? null : () => _onAnswer(idx, isCorrect),
            child: AnimatedContainer(
              duration: LumoLessonStyle.reducedMotion(context, widget.appState)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              decoration: LumoLessonStyle.answer(
                  background: bgColor, border: borderColor),
              child: Center(
                child: Text(_formatCent(val),
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoinAnswerGrid() {
    return LumoLessonAnswerGrid(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: _muenzenAufTisch.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        final isCorrect = m.wert == _gefragteMuenze.wert;
        final isSelected = _selectedAnswer == idx;
        Color borderColor = LumoVisualTokens.cyan.withValues(alpha: .8);
        if (_answered && isSelected) {
          borderColor =
              isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        } else if (_answered && isCorrect) {
          borderColor = const Color(0xFFFCD34D);
        }
        return AnimatedBuilder(
          animation: _bounceCtrl,
          builder: (_, child) {
            final scale = isSelected &&
                    isCorrect &&
                    !LumoLessonStyle.reducedMotion(context, widget.appState)
                ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.1
                : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: LumoLessonAnswerTap(
            correct: _answered && isSelected ? isCorrect : null,
            onTap: _answered ? null : () => _onAnswer(idx, isCorrect),
            child: AnimatedContainer(
              duration: LumoLessonStyle.reducedMotion(context, widget.appState)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              decoration: LumoLessonStyle.answer(
                  background: LumoVisualTokens.lessonAnswer,
                  border: borderColor),
              child: Center(child: _buildCoinWidget(m, size: 80)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
