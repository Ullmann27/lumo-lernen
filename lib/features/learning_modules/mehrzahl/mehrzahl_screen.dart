// ════════════════════════════════════════════════════════════════════════
// MEHRZAHL — Klasse 2 Deutsch (Plural-Bildung)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentyp: 'Wie heisst die Mehrzahl von <Wort>?' mit 4 Antwort-Optionen.
// 10 Aufgaben pro Session.
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

class _PluralWort {
  const _PluralWort(this.singular, this.plural, this.falscheVarianten);
  final String singular;
  final String plural;

  /// 3 plausible falsche Plural-Formen
  final List<String> falscheVarianten;
}

class MehrzahlScreen extends StatefulWidget {
  const MehrzahlScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<MehrzahlScreen> createState() => _MehrzahlScreenState();
}

class _MehrzahlScreenState extends State<MehrzahlScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
  ];

  static const List<_PluralWort> _woerter = [
    _PluralWort('Hund', 'Hunde', ['Hunden', 'Hunder', 'Hundes']),
    _PluralWort('Kind', 'Kinder', ['Kinde', 'Kindern', 'Kindes']),
    _PluralWort('Apfel', 'Äpfel', ['Apfeln', 'Apfels', 'Aepfeln']),
    _PluralWort('Auto', 'Autos', ['Auten', 'Autoe', 'Autos\'']),
    _PluralWort('Buch', 'Bücher', ['Buche', 'Buchen', 'Buchs']),
    _PluralWort('Maus', 'Mäuse', ['Mause', 'Mausen', 'Mauses']),
    _PluralWort('Haus', 'Häuser', ['Hause', 'Hausen', 'Hauses']),
    _PluralWort('Baum', 'Bäume', ['Baums', 'Baumen', 'Baumer']),
    _PluralWort('Stuhl', 'Stühle', ['Stuhle', 'Stuhlen', 'Stuhls']),
    _PluralWort('Tisch', 'Tische', ['Tischen', 'Tischer', 'Tischs']),
    _PluralWort('Blume', 'Blumen', ['Blumes', 'Blume\'s', 'Blumern']),
    _PluralWort('Fenster', 'Fenster', ['Fensters', 'Fenstern', 'Fensteren']),
    _PluralWort('Lampe', 'Lampen', ['Lampes', 'Lampe\'s', 'Lamper']),
    _PluralWort('Vogel', 'Vögel', ['Vogels', 'Vogeln', 'Voegels']),
    _PluralWort('Katze', 'Katzen', ['Katzes', 'Katze\'s', 'Katzer']),
    _PluralWort('Tasche', 'Taschen', ['Tasches', 'Tasche\'s', 'Tascher']),
    _PluralWort('Frau', 'Frauen', ['Fraus', 'Frauer', 'Frauenes']),
    _PluralWort('Mann', 'Männer', ['Mannes', 'Mannen', 'Maenner']),
    _PluralWort('Hand', 'Hände', ['Handen', 'Hands', 'Händer']),
    _PluralWort('Hut', 'Hüte', ['Huten', 'Huts', 'Hüter']),
    _PluralWort('Tür', 'Türen', ['Türs', 'Türe', 'Türer']),
    _PluralWort('Schuh', 'Schuhe', ['Schuhs', 'Schuhen', 'Schuher']),
    _PluralWort('Wolke', 'Wolken', ['Wolkes', 'Wolkers', 'Wolkenes']),
    _PluralWort('Gabel', 'Gabeln', ['Gabels', 'Gabeler', 'Gabele']),
    _PluralWort('Fluss', 'Flüsse', ['Flusses', 'Flusser', 'Flussen']),
    _PluralWort('Pferd', 'Pferde', ['Pferden', 'Pferds', 'Pferder']),
    _PluralWort('Sonne', 'Sonnen', ['Sonnes', 'Sonnens', 'Sonner']),
    _PluralWort('Bär', 'Bären', ['Bärs', 'Bäre', 'Bärern']),
    _PluralWort('Berg', 'Berge', ['Bergs', 'Berger', 'Bergers']),
    _PluralWort('Lied', 'Lieder', ['Liedes', 'Lieds', 'Lieden']),
  ];

  late final LearningModuleProgress _progress;

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();
  late final List<_PluralWort> _round;

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _PluralWort _korrektWort;
  late List<String> _options;
  late int _correctIdx;

  @override
  void initState() {
    super.initState();
    _round = List.of(_woerter)..shuffle(_rng);
    assert(_round.length == _totalTasks);
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Deutsch',
      unit: 'Mehrzahl',
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
    _korrektWort = _round[_taskIdx];
    _options = [_korrektWort.plural, ..._korrektWort.falscheVarianten]
      ..shuffle(_rng);
    _correctIdx = _options.indexOf(_korrektWort.plural);
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance
          .speak('Wie heißt die Mehrzahl von ${_korrektWort.singular}?');
    } catch (_) {}
  }

  void _onAnswer(int idx) async {
    if (_answered || _progress.hasPending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIdx = idx;
      _answered = true;
    });
    final isCorrect = idx == _correctIdx;
    final saved = await _progress.saveAnswer(
      problemKey: 'Mehrzahl: ${_korrektWort.singular}',
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
        LumoVoice.instance
            .speak('Schau nochmal - die Mehrzahl ist ${_korrektWort.plural}!');
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
        title: const Text('📝 Mehrzahl-Quiz fertig!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks richtig!',
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
        title: 'Wörter-Abenteuer',
        moduleTitle: 'Mehrzahl bilden',
        icon: Icons.auto_stories_rounded,
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
            _buildSingularBox(),
            const SizedBox(height: 12),
            _buildOptions(),
          ]),
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
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
        child: Text('Wie heißt die Mehrzahl?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ),
    );
  }

  Widget _buildSingularBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 3),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        Text('1 Stück',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LumoVisualTokens.white)),
        const SizedBox(height: 4),
        Text(_korrektWort.singular,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
        const SizedBox(height: 8),
        Text('▼ viele Stück',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LumoVisualTokens.white)),
      ]),
    );
  }

  Widget _buildOptions() {
    return LumoLessonAnswerGrid(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: _options.asMap().entries.map((entry) {
        final idx = entry.key;
        final opt = entry.value;
        final isCorrect = idx == _correctIdx;
        final isSelected = _selectedIdx == idx;
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
            onTap: _answered ? null : () => _onAnswer(idx),
            child: AnimatedContainer(
              duration: LumoLessonStyle.reducedMotion(context, widget.appState)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              decoration: LumoLessonStyle.answer(
                  background: bgColor, border: borderColor),
              child: Center(
                child: Text(opt,
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
}
