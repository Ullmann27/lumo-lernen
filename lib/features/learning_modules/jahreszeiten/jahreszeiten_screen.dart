// ════════════════════════════════════════════════════════════════════════
// JAHRESZEITEN — Klasse 2 Sachkunde (mit lokalen Originalillustrationen)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welche Jahreszeit zeigt das Bild?' (Bild -> Jahreszeit)
//   - 'In welcher Jahreszeit passiert X?' (Aktivitaet/Wetter -> Jahreszeit)
// 30 Aufgaben pro Session.
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

enum _Jahreszeit { fruehling, sommer, herbst, winter }

extension _JahreszeitName on _Jahreszeit {
  String get label {
    switch (this) {
      case _Jahreszeit.fruehling:
        return 'Frühling';
      case _Jahreszeit.sommer:
        return 'Sommer';
      case _Jahreszeit.herbst:
        return 'Herbst';
      case _Jahreszeit.winter:
        return 'Winter';
    }
  }

  String get asset {
    switch (this) {
      case _Jahreszeit.fruehling:
        return 'assets/lumo_design/icons/season_spring.png';
      case _Jahreszeit.sommer:
        return 'assets/lumo_design/icons/season_summer.png';
      case _Jahreszeit.herbst:
        return 'assets/lumo_design/icons/season_autumn.png';
      case _Jahreszeit.winter:
        return 'assets/lumo_design/icons/season_winter.png';
    }
  }

  // Describe what is visible, rather than giving away the answer to a reader.
  String get sceneDescription {
    switch (this) {
      case _Jahreszeit.fruehling:
        return 'Bäume mit rosa Blüten und Blumen auf einer grünen Wiese';
      case _Jahreszeit.sommer:
        return 'Grüne Bäume, gelbe Blumen und eine helle Sonne';
      case _Jahreszeit.herbst:
        return 'Bäume mit orangefarbenen Blättern, gefallene Blätter und Kürbisse';
      case _Jahreszeit.winter:
        return 'Schnee, kahle Äste und ein Schneemann mit blauem Schal';
    }
  }
}

class _Hinweis {
  const _Hinweis(this.text, this.jz);
  final String text;
  final _Jahreszeit jz;
}

enum _JahreszeitFrageTyp { bildErraten, hinweisErraten }

class JahreszeitenScreen extends StatefulWidget {
  const JahreszeitenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<JahreszeitenScreen> createState() => _JahreszeitenScreenState();
}

class _JahreszeitenScreenState extends State<JahreszeitenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFF06B6D4),
    Color(0xFF0E7490),
  ];

  static const List<_Hinweis> _hinweise = [
    _Hinweis('Es schneit und ist kalt', _Jahreszeit.winter),
    _Hinweis('Schneemann bauen', _Jahreszeit.winter),
    _Hinweis('Weihnachten', _Jahreszeit.winter),
    _Hinweis('Eis laufen', _Jahreszeit.winter),
    _Hinweis('Blumen blühen', _Jahreszeit.fruehling),
    _Hinweis('Ostern', _Jahreszeit.fruehling),
    _Hinweis('Vögel singen wieder', _Jahreszeit.fruehling),
    _Hinweis('Schmetterlinge', _Jahreszeit.fruehling),
    _Hinweis('Schwimmen gehen', _Jahreszeit.sommer),
    _Hinweis('Eis essen', _Jahreszeit.sommer),
    _Hinweis('Sommerferien', _Jahreszeit.sommer),
    _Hinweis('Es ist heiß', _Jahreszeit.sommer),
    _Hinweis('Bunte Blätter fallen', _Jahreszeit.herbst),
    _Hinweis('Drachen steigen lassen', _Jahreszeit.herbst),
    _Hinweis('Kürbis und Halloween', _Jahreszeit.herbst),
    _Hinweis('Wind und Regen', _Jahreszeit.herbst),
  ];

  late final LearningModuleProgress _progress;

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedIdx;

  late _JahreszeitFrageTyp _typ;
  late _Jahreszeit _correctJz;
  late _Hinweis _aktuellerHinweis;
  late List<_Jahreszeit> _options;

  @override
  void initState() {
    super.initState();
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Sachunterricht',
      unit: 'Jahreszeiten',
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

  // Heinz CLAUDE.md Punkt 5: 'Wiederholungslogik verbessern'.
  // Bei 30 Aufgaben aus 4 Jahreszeiten ist Repeat unvermeidbar - aber
  // mindestens NIE 2x dieselbe Jahreszeit hintereinander.
  _Jahreszeit? _lastJz;

  void _generateTask() {
    _typ = _JahreszeitFrageTyp.values[_rng.nextInt(2)];
    if (_typ == _JahreszeitFrageTyp.bildErraten) {
      _Jahreszeit pick;
      int safety = 6;
      do {
        pick = _Jahreszeit.values[_rng.nextInt(4)];
      } while (pick == _lastJz && --safety > 0);
      _correctJz = pick;
      _lastJz = pick;
    } else {
      _aktuellerHinweis = _hinweise[_rng.nextInt(_hinweise.length)];
      _correctJz = _aktuellerHinweis.jz;
    }
    _options = List.of(_Jahreszeit.values)..shuffle(_rng);
    _answered = false;
    _selectedIdx = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    if (_typ == _JahreszeitFrageTyp.bildErraten) {
      text = 'Welche Jahreszeit zeigt das Bild?';
    } else {
      text = 'In welcher Jahreszeit passiert das: ${_aktuellerHinweis.text}?';
    }
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _onAnswer(int idx, bool isCorrect) async {
    if (_answered || _progress.hasPending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIdx = idx;
      _answered = true;
    });
    final saved = await _progress.saveAnswer(
      cosmosSubjectId: 's1_jahreszeiten',
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
        LumoVoice.instance.speak('Richtig! Das ist ${_correctJz.label}!');
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance
            .speak('Schau nochmal - das ist ${_correctJz.label}!');
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
        title: const Text('🌸 Jahreszeiten-Quiz fertig!',
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
        title: 'Welt-Abenteuer',
        moduleTitle: 'Jahreszeiten',
        icon: Icons.nature_rounded,
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
            if (_typ == _JahreszeitFrageTyp.bildErraten)
              _buildSeasonImage()
            else
              _buildHinweisBox(),
            const SizedBox(height: 12),
            _buildOptions(),
          ]),
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    final text = _typ == _JahreszeitFrageTyp.bildErraten
        ? 'Welche Jahreszeit ist das?'
        : 'Wann passiert das?';
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

  Widget _buildSeasonImage() {
    return LayoutBuilder(builder: (context, constraints) {
      final extent = constraints.maxWidth >= 500 ? 224.0 : 160.0;
      return Semantics(
        label: _correctJz.sceneDescription,
        image: true,
        child: SizedBox(
          width: extent,
          height: extent,
          child: Image.asset(
            _correctJz.asset,
            key: const ValueKey('learning-season-illustration'),
            fit: BoxFit.contain,
            cacheWidth: 512,
            excludeFromSemantics: true,
          ),
        ),
      );
    });
  }

  Widget _buildHinweisBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: LumoVisualTokens.cyan.withValues(alpha: .6), width: 2),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Text('"${_aktuellerHinweis.text}"',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white)),
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
        final jz = entry.value;
        final isCorrect = jz == _correctJz;
        final isSelected = _selectedIdx == idx;
        Color bgColor = LumoVisualTokens.lessonAnswer;
        Color borderColor = LumoVisualTokens.cyan.withValues(alpha: .8);
        Color textColor = LumoVisualTokens.white;
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
                child: Text(jz.label,
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
