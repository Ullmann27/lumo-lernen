// ════════════════════════════════════════════════════════════════════════
// TIERE LERNEN — Klasse 1 Sachkunde (Tier-Quiz mit echten Bildern)
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: Module mit Bildgenerator-Integration. Hier kommen die
// Bilder live aus Pollinations.ai (sichere Allowlist, Comic-Stil).
//
// Aufgabentypen:
//   - 'Welches Tier macht XYZ?' (Tierlaut -> Bild)
//   - 'Welches Tier ist das?' (Bild -> Name)
//   - 'Wo lebt dieses Tier?' (Bild -> Lebensraum)
//
// 10 Aufgaben pro Session, 4 Multiple-Choice (Bilder oder Texte).
// ════════════════════════════════════════════════════════════════════════

import '../../../widgets/design/lumo_learning_module_frame.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'dart:math' as math;


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../learning_module_progress.dart';
import '../lumo_phrases.dart';

enum _TierFrageTyp { bildZeigen, lautRaten, lebensraum }

class _Tier {
  const _Tier({
    required this.name,
    required this.laut,
    required this.lebensraum,
    required this.emoji,
  });
  final String name;
  final String laut;
  final String lebensraum;

  /// Sichtbares Emoji als Fallback wenn Pollinations-Bild nicht laedt.
  /// Heinz' Wunsch: keine generischen Pfoten mehr, sondern echte Tier-Emojis.
  final String emoji;
}

class TiereScreen extends StatefulWidget {
  const TiereScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<TiereScreen> createState() => _TiereScreenState();
}

class _TiereScreenState extends State<TiereScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  // 12 Tiere fuer Quiz - alle in der Allowlist - mit echten Tier-Emojis
  static const List<_Tier> _tiere = [
    _Tier(name: 'Kuh', laut: 'Muh', lebensraum: 'Bauernhof', emoji: '🐄'),
    _Tier(name: 'Hund', laut: 'Wau Wau', lebensraum: 'Zuhause', emoji: '🐶'),
    _Tier(name: 'Katze', laut: 'Miau', lebensraum: 'Zuhause', emoji: '🐱'),
    _Tier(name: 'Schaf', laut: 'Mäh', lebensraum: 'Bauernhof', emoji: '🐑'),
    _Tier(name: 'Pferd', laut: 'Wieher', lebensraum: 'Bauernhof', emoji: '🐴'),
    _Tier(
        name: 'Huhn', laut: 'Gack Gack', lebensraum: 'Bauernhof', emoji: '🐔'),
    _Tier(name: 'Ente', laut: 'Quak', lebensraum: 'See', emoji: '🦆'),
    _Tier(name: 'Frosch', laut: 'Quak Quak', lebensraum: 'See', emoji: '🐸'),
    _Tier(name: 'Löwe', laut: 'Brüll', lebensraum: 'Zoo', emoji: '🦁'),
    _Tier(name: 'Elefant', laut: 'Tröt', lebensraum: 'Zoo', emoji: '🐘'),
    _Tier(name: 'Pinguin', laut: 'Watschel', lebensraum: 'Zoo', emoji: '🐧'),
    _Tier(name: 'Affe', laut: 'Uh Uh', lebensraum: 'Zoo', emoji: '🐵'),
  ];

  late final LearningModuleProgress _progress;

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();
  late final List<({int kind, int animal})> _round;

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  String? _selectedAnswer;

  late _TierFrageTyp _typ;
  late _Tier _correctTier;
  late List<_Tier> _answerOptions;

  @override
  void initState() {
    super.initState();
    _round = [
      for (var kind = 0; kind < _TierFrageTyp.values.length; kind++)
        for (var animal = 0; animal < _tiere.length; animal++)
          // Ducks and frogs have very similar calls, and "Watschel" is
          // movement, not a penguin sound. Avoid misleading sound questions.
          if (kind != _TierFrageTyp.lautRaten.index ||
              !const <int>[6, 7, 10].contains(animal))
            (kind: kind, animal: animal),
    ]..shuffle(_rng);
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Sachunterricht',
      unit: 'Tiere',
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
    // Thirty distinct prompt/animal pairs are prepared at session start.
    // Sampling with replacement previously repeated the same question.
    final plan = _round[_taskIdx];
    _typ = _TierFrageTyp.values[plan.kind];
    _correctTier = _tiere[plan.animal];
    final shuffled = List.of(_tiere.where((tier) => tier != _correctTier))
      ..shuffle(_rng);
    // 3 falsche Antworten + 1 richtige
    final wrong = shuffled.take(3).toList();
    _answerOptions = [_correctTier, ...wrong]..shuffle(_rng);
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    switch (_typ) {
      case _TierFrageTyp.bildZeigen:
        text = 'Welches Tier ist das?';
        break;
      case _TierFrageTyp.lautRaten:
        text = 'Welches Tier macht "${_correctTier.laut}"?';
        break;
      case _TierFrageTyp.lebensraum:
        text = 'Wo kann man das Tier ${_correctTier.name} bei uns häufig sehen?';
        break;
    }
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _onAnswer(String answer) async {
    if (_answered || _progress.hasPending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final correctAnswer = _typ == _TierFrageTyp.lebensraum
        ? _correctTier.lebensraum
        : _correctTier.name;
    final isCorrect = answer == correctAnswer;
    final saved = await _progress.saveAnswer(
      problemKey: '${_round[_taskIdx].kind}:${_round[_taskIdx].animal}',
      cosmosSubjectId: 's1_tiere',
      cosmosIsMath: false,
      correct: isCorrect,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 7 : 0,
    );
    if (!saved || !mounted) return;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      setState(() => _correctCount++);
      try {
        LumoVoice.instance.speak('Richtig! Das ist ein ${_correctTier.name}!');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance
            .speak('Schau nochmal - das ist ein ${_correctTier.name}!');
      } catch (_) {}
    }
    final canAdvance =
        await _progress.feedbackDelay(const Duration(milliseconds: 1400));
    if (!canAdvance || !mounted) return;
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

  void _showFinish() async {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    final saved = await _progress.saveBonus(
      stars: stars,
      xp: _correctCount * 10,
    );
    if (!saved || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Tier-Quiz fertig!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Tiere erkannt!',
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
        title: 'Welt-Abenteuer',
        moduleTitle: 'Tiere lernen',
        icon: Icons.pets_rounded,
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
            const SizedBox(height: 20),
            _buildMainImage(),
            const SizedBox(height: 20),
            _buildAnswerOptions(),
          ]),
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    String text;
    switch (_typ) {
      case _TierFrageTyp.bildZeigen:
        text = 'Welches Tier ist das?';
        break;
      case _TierFrageTyp.lautRaten:
        text = 'Welches Tier macht "${_correctTier.laut}"?';
        break;
      case _TierFrageTyp.lebensraum:
        text = 'Wo lebt ein ${_correctTier.name}?';
        break;
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

  /// Zeigt das Tier mit lebensraum-passendem Hintergrund-Gradient und
  /// grossem Tier-Emoji. Pollinations.ai ist raus - wie bei Farben kamen
  /// die Bilder im Cloud-Setup nie zuverlaessig durch. Der Lebensraum-
  /// Gradient gibt Atmosphaere (Bauernhof=gruen-gelb, Zoo=orange-braun,
  /// See=blau-tuerkis, Zuhause=warm-rosa).
  Widget _buildMainImage() {
    // Bei "Welches Tier macht ...?" verriet das grosse Tierbild die Antwort.
    // Bis zur Antwort einen neutralen Lautsprecher zeigen, danach das Tier.
    final hideAnswer = _typ == _TierFrageTyp.lautRaten && !_answered;
    final colors = hideAnswer
        ? const [Color(0xFFFFF3D6), Color(0xFFFFC46B)]
        : _lebensraumGradient(_correctTier.lebensraum);
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final s = 1.0 + math.sin(_bounceCtrl.value * math.pi * 2) * 0.02;
        return Transform.scale(scale: s, child: child);
      },
      child: Container(
        width: 220,
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [colors[0], colors[1]],
            radius: 0.9,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: [
            BoxShadow(
              color: colors[1].withOpacity(.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Text(hideAnswer ? '🔊' : _correctTier.emoji,
            style: const TextStyle(fontSize: 140, height: 1.0)),
      ),
    );
  }

  /// Liefert ein passendes Farbpaar fuer den Lebensraum, damit der
  /// Hintergrund Atmosphaere transportiert.
  List<Color> _lebensraumGradient(String lebensraum) {
    switch (lebensraum) {
      case 'Bauernhof':
        return const [Color(0xFFFFF7CC), Color(0xFFA7E07A)]; // gelb-gruen
      case 'Zoo':
        return const [Color(0xFFFFD8A8), Color(0xFFC77D3D)]; // sand-braun
      case 'See':
        return const [Color(0xFFCCEFFF), Color(0xFF4DB6E8)]; // hellblau-tief
      case 'Zuhause':
      default:
        return const [Color(0xFFFFE6D5), Color(0xFFF5A38C)]; // warm-rosa
    }
  }

  Widget _buildAnswerOptions() {
    final options = _typ == _TierFrageTyp.lebensraum
        ? _buildLebensraumOptions()
        : _answerOptions.map((t) => t.name).toList();
    return LumoLessonAnswerGrid(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: options.map((opt) => _buildAnswerButton(opt)).toList(),
    );
  }

  List<String> _buildLebensraumOptions() {
    final all = ['Bauernhof', 'Zoo', 'See', 'Zuhause'];
    return all;
  }

  Widget _buildAnswerButton(String text) {
    final correctAnswer = _typ == _TierFrageTyp.lebensraum
        ? _correctTier.lebensraum
        : _correctTier.name;
    final isSelected = _selectedAnswer == text;
    final isCorrect = text == correctAnswer;
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
        onTap: _answered ? null : () => _onAnswer(text),
        child: AnimatedContainer(
          duration: LumoLessonStyle.reducedMotion(context, widget.appState)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          decoration:
              LumoLessonStyle.answer(background: bgColor, border: borderColor),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
          ),
        ),
      ),
    );
  }
}
