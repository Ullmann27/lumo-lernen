import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_sound.dart';
import 'quiz_show_music.dart';
import '../../app/app_theme.dart';
import '../../domain/quiz/quiz_question_bank.dart';
import '../../domain/quiz/quiz_show.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

class QuizShowContent extends StatefulWidget {
  const QuizShowContent({
    super.key,
    required this.appState,
    this.previewQuestionSeed,
  });

  final LumoAppState appState;

  /// Stable questions for QA screenshots. Null uses the normal randomized game.
  @visibleForTesting
  final int? previewQuestionSeed;

  @override
  State<QuizShowContent> createState() => _QuizShowContentState();
}

class _QuizShowContentState extends State<QuizShowContent> {
  static const _engine = QuizShowEngine();
  static const _bank = QuizQuestionBank();
  late QuizShowState _state;
  late QuizShowMusic _music;
  Timer? _lockTimer;
  bool _locking = false;

  @override
  void initState() {
    super.initState();
    if (widget.appState.state.settings.soundEnabled) {
      unawaited(LumoSound.instance.init());
    }
    _music = QuizShowMusic(enabled: widget.appState.state.settings.soundEnabled);
    _startNewGame();
    unawaited(_music.start());
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    unawaited(_music.dispose());
    super.dispose();
  }

  void _playEffect(SoundEffect effect) {
    // Child's audio-off setting also controls quiz SFX. Never start the
    // audioplayers plugin when sound is disabled (including test captures).
    if (!widget.appState.state.settings.soundEnabled) return;
    unawaited(LumoSound.instance.play(effect));
  }

  void _startNewGame() {
    final questions = _bank.generateGameQuestions(
      grade: widget.appState.state.grade,
      random: math.Random(
        widget.previewQuestionSeed ?? DateTime.now().millisecondsSinceEpoch),
    );
    _state = _engine.start(questions: questions);
  }

  void _select(int index) {
    if (_locking) return;
    final next = _engine.selectAnswer(_state, index);
    if (next.selectedOption != _state.selectedOption) {
      _playEffect(SoundEffect.click);
    }
    setState(() => _state = next);
  }

  void _reveal() {
    if (_locking || _state.revealed || _state.gameOver ||
        _state.selectedOption == null) return;
    setState(() => _locking = true);
    _playEffect(SoundEffect.click);
    unawaited(_music.pauseForLockIn());
    _lockTimer?.cancel();
    final reduced = MediaQuery.disableAnimationsOf(context);
    _lockTimer = Timer(Duration(milliseconds: reduced ? 750 : 1600), () {
      if (!mounted || !_locking) return;
      setState(() => _locking = false);
      _resolveAnswer();
    });
  }

  void _resolveAnswer() {
    final before = _state;
    final selected = before.selectedOption;
    final correct = selected != null &&
        selected == before.currentQuestion.correctIndex;

    setState(() {
      final wasGameOver = _state.gameOver;
      final next = _engine.reveal(_state);
      _state = next;

      // Die Engine liefert die Auszahlung nur beim ersten Spielende.
      // Dadurch werden Sterne weder bei Meilensteinen doppelt gebucht noch
      // beim erneuten Rendern des Ergebnisbildschirms nochmals vergeben.
      if (!wasGameOver && next.gameOver && next.awardedStars > 0) {
        widget.appState.addStars(next.awardedStars);
      }
    });

    if (!correct) {
      _playEffect(SoundEffect.error);
    } else if (_state.won || _state.securedStars > before.securedStars) {
      _playEffect(SoundEffect.win);
    }
    if (_state.gameOver) unawaited(_music.stop());
  }

  void _next() {
    if (_locking) return;
    unawaited(_music.resume());
    _playEffect(SoundEffect.click);
    setState(() => _state = _engine.nextQuestion(_state));
  }

  void _joker(QuizJoker joker) {
    if (_locking) return;
    final next = _engine.useJoker(_state, joker);
    if (next.usedJokers.length > _state.usedJokers.length) {
      _playEffect(SoundEffect.click);
    }
    setState(() => _state = next);
  }

  void _restart() {
    _lockTimer?.cancel();
    _locking = false;
    _playEffect(SoundEffect.click);
    setState(_startNewGame);
    unawaited(_music.start());
  }

  @override
  Widget build(BuildContext context) {
    final q = _state.currentQuestion;
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        title: const Text(
          'Wer wird Lumo-Meister?',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: LumoVisualTokens.navigation.withOpacity(.96),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LumoSceneBackground(
        scene: LumoScene.tests,
        dimmed: true,
        showPlaceholderLabel: false,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final card = _QuizCard(
                state: _state, question: q,
                onSelect: _select, onReveal: _reveal, onNext: _next,
                onRestart: _restart, onJoker: _joker,
                 locking: _locking,
              );
              return SingleChildScrollView(
                padding: EdgeInsets.all(constraints.maxWidth < 400 ? 10 : 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: card,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.state,
    required this.question,
    required this.onSelect,
    required this.onReveal,
    required this.onNext,
    required this.onRestart,
    required this.onJoker,
    required this.locking,
  });

  final bool locking;
  final QuizShowState state;
  final QuizQuestion question;
  final ValueChanged<int> onSelect;
  final VoidCallback onReveal;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final ValueChanged<QuizJoker> onJoker;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedOption;
    final answered = state.revealed;
    final isCorrect = selected == question.correctIndex;

    final finale = state.displayQuestionNumber == state.questions.length;
    final tension = state.displayQuestionNumber >= 15;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: finale
              ? const [Color(0xEE32135F), Color(0xEE071D46)]
              : const [Color(0xEE071D46), Color(0xEE0B3159)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: finale
              ? const Color(0xFFFFC94A)
              : LumoVisualTokens.cyanBright.withOpacity(.72),
          width: finale ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (finale
                    ? const Color(0xFFFFC94A)
                    : LumoVisualTokens.cyanBright)
                .withOpacity(tension ? .30 : .16),
            blurRadius: tension ? 32 : 22,
            spreadRadius: tension ? 3 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuizStage(state: state, onJoker: onJoker),
          const SizedBox(height: 10),
          Row(children: [
            _Pill('Frage ${state.displayQuestionNumber} / ${state.questions.length}'),
            const Spacer(),
            Flexible(
              child: Text(
                question.subject,
                textAlign: TextAlign.right,
                style: LumoTextStyles.caption.copyWith(
                  color: finale
                      ? const Color(0xFFFFD873)
                      : LumoVisualTokens.cyanBright,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF061935), Color(0xFF103A70), Color(0xFF061A39),
              ]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD873), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x5545C7FC), blurRadius: 20),
              ],
            ),
            child: Text(
              question.prompt,
              textAlign: TextAlign.center,
              style: LumoTextStyles.heading1.copyWith(
                fontSize: finale ? 30 : 28, color: Colors.white,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Color(0xAA000000), blurRadius: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (state.lumoHint != null) ...[
            const SizedBox(height: 14),
            _HintBubble(text: state.lumoHint!),
          ],
          if (state.audienceVotes != null) ...[
            const SizedBox(height: 14),
            _AudienceVotes(votes: state.audienceVotes!),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, bounds) {
              const gap = 10.0;
              final two = bounds.maxWidth >= 260 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              final width = two ? (bounds.maxWidth - gap) / 2 : bounds.maxWidth;
              return Wrap(
                spacing: gap, runSpacing: 10,
                children: [
                  for (var i = 0; i < question.options.length; i++)
                    SizedBox(
                      width: width,
                      child: _AnswerButton(
                        label: question.options[i], index: i,
                        hidden: state.fiftyFiftyHiddenOptions.contains(i),
                        selected: selected == i, revealed: answered,
                        correct: question.correctIndex == i,
                        onTap: locking ? null : () => onSelect(i),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          if (state.gameOver)
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(state.won ? 'Nochmal Lumo-Meister werden' : 'Neue Quizrunde starten'),
            )
          else if (!answered)
            _LockInButton(
              enabled: selected != null && !locking,
              locking: locking,
              onTap: onReveal,
            )
          else
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Nächste Frage'),
            ),
          if (answered) ...[
            const SizedBox(height: 14),
            _ResultPanel(
              correct: isCorrect,
              answer: question.correctAnswer,
              won: state.won,
              securedStars: state.securedStars,
              awardedStars: state.awardedStars,
            ),
          ],
        ],
      ),
    );
  }
}


/// Three functional jokers, a permanently mounted Lumo stage and the
/// real 50/200/800/5000-star milestones. Each area owns its hitbox.
class _QuizStage extends StatelessWidget {
  const _QuizStage({required this.state, required this.onJoker});
  final QuizShowState state;
  final ValueChanged<QuizJoker> onJoker;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final compact = c.maxWidth < 400;
      final tablet = c.maxWidth >= 700;
      final leftWidth = tablet ? 100.0 : (compact ? 62.0 : 78.0);
      final rightWidth = tablet ? 168.0 : (compact ? 100.0 : 132.0);
      final gap = tablet ? 18.0 : (compact ? 6.0 : 12.0);
      // On the unfolded Fold and tablet, the mascot is the visual hero,
      // not a miniature floating inside an oversized empty stage.
      final foxSize = math.min(tablet ? 320.0 : (compact ? 146.0 : 208.0),
          math.max(40.0, c.maxWidth - leftWidth - rightWidth - gap * 2 - 4));
      final finale = state.displayQuestionNumber == state.questions.length;
      final caption = state.won ? 'LUMO-MEISTER!'
          : finale ? 'MEISTERFRAGE!'
          : state.displayQuestionNumber >= 15 ? 'DU SCHAFFST DAS!'
          : 'LUMO LIVE';
      return SizedBox(
        key: const ValueKey('lumo-meister-stage'),
        // The stage must expand with accessibility font scaling: the
        // three joker buttons and prize ladder otherwise overflow by 47px
        // at 1.5x on Fold / phone widths. The outer page already scrolls.
        height: (compact ? 380.0 : (tablet ? 490.0 : 418.0)) *
            math.max(1.0, MediaQuery.textScalerOf(context).scale(1)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('lumo-meister-joker-rail'),
              width: leftWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _JokerButton(
                    label: '50:50', icon: Icons.filter_2_rounded,
                    used: state.usedJokers.contains(QuizJoker.fiftyFifty),
                    onTap: () => onJoker(QuizJoker.fiftyFifty),
                  ),
                  const SizedBox(height: 7),
                  _JokerButton(
                    label: 'Publikum', icon: Icons.groups_rounded,
                    used: state.usedJokers.contains(QuizJoker.audience),
                    onTap: () => onJoker(QuizJoker.audience),
                  ),
                  const SizedBox(height: 7),
                  _JokerButton(
                    label: 'Lumo-Tipp', icon: Icons.lightbulb_rounded,
                    used: state.usedJokers.contains(QuizJoker.callLumo),
                    onTap: () => onJoker(QuizJoker.callLumo),
                  ),
                ],
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(colors: [
                            Color(0x7755DFFF),
                            Color(0x443959A8),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    Center(
                      child: IgnorePointer(
                        child: SizedBox(
                          key: const ValueKey('lumo-meister-fox-slot'),
                          width: foxSize, height: foxSize,
                          child: LumoCharacter(
                            key: const ValueKey('lumo-meister-fox'),
                            pose: state.won || finale
                                ? LumoDesignFoxPose.trophyWink
                                : state.revealed &&
                                  state.selectedOption ==
                                      state.currentQuestion.correctIndex
                                    ? LumoDesignFoxPose.thumbWink
                                    : LumoDesignFoxPose.pointSide,
                            size: foxSize,
                            reduceMotion: MediaQuery.disableAnimationsOf(context),
                            intro: false, idleHops: false,
                            ambientPoses: const <LumoDesignFoxPose>[],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 3, left: 0, right: 0,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF052251), Color(0xFF126AAF),
                            ]),
                            border: Border.all(color: const Color(0xFFFFD873)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 7),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                caption, maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 13,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              key: const ValueKey('lumo-meister-prize-rail'),
              width: rightWidth,
              child: _QuizPrizeRail(state: state),
            ),
          ],
        ),
      );
    },
  );
}

/// All 20 rows are visual progress, not independent wallet grants.
/// The engine alone awards the four secured milestone prizes.
class _QuizPrizeRail extends StatelessWidget {
  const _QuizPrizeRail({required this.state});
  final QuizShowState state;
  static const amounts = <int>[
    0, 10, 20, 30, 40, 50, 80, 90, 100, 150, 200,
    400, 450, 500, 600, 800, 2000, 2500, 3000, 4000, 5000,
  ];

  @override
  Widget build(BuildContext context) {
    final current = state.displayQuestionNumber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF15356D), Color(0xFF071735)]),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFFFC94A), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x55FFCE65), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          for (int step = 20; step >= 1; step--)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Container(
                  key: ValueKey('lumo-meister-prize-step-$step'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(colors: step == current
                      ? const [Color(0xFF00BDF4), Color(0xFF0649A1)]
                      : const [Color(0xFF112F5E), Color(0xFF081831)]),
                    border: Border.all(
                      color: step == current
                        ? const Color(0xFF55EEFF)
                        : const Color(0x664C8DCE),
                      width: step == current ? 1.4 : 0.6),
                    boxShadow: step == current
                      ? const [BoxShadow(
                          color: Color(0x9955EFFF), blurRadius: 9)]
                      : null,
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 22,
                      child: Text(step.toString(),
                        maxLines: 1, textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFFFDF79),
                          fontSize: 11,
                          fontWeight: step % 5 == 0
                            ? FontWeight.w900 : FontWeight.w700,
                        )),
                    ),
                    const Expanded(child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Icon(Icons.star_rounded,
                        color: Color(0xFFFFD45C), size: 13))),
                    SizedBox(width: 42, child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_amount(step),
                        style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 12,
                          fontWeight: step % 5 == 0
                            ? FontWeight.w900 : FontWeight.w700,
                          color: step == current || step % 5 == 0
                            ? const Color(0xFFFFE59E) : Colors.white,
                        )),
                    )),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _amount(int step) {
    final value = amounts[step];
    if (value < 1000) return value.toString();
    return '${value ~/ 1000}.${(value % 1000).toString().padLeft(3, '0')}';
  }
}

class _LockInButton extends StatelessWidget {
  const _LockInButton({
    required this.enabled, required this.locking, required this.onTap,
  });
  final bool enabled;
  final bool locking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: locking,
      child: AnimatedContainer(
        key: const ValueKey('lumo-meister-lock-bar'),
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: enabled || locking
            ? const [Color(0xFF064EAA), Color(0xFF12275A), Color(0xFF05418C)]
            : const [Color(0xFF293C60), Color(0xFF162B4C)]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: locking || enabled
              ? const Color(0xFFFFCD62) : const Color(0xFF557AA6),
            width: 1.7),
          boxShadow: locking
            ? const [BoxShadow(color: Color(0x88FFD66B), blurRadius: 19)]
            : const [BoxShadow(color: Color(0x6638CAFF), blurRadius: 12)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 13),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(locking ? Icons.hourglass_top_rounded
                      : Icons.check_circle_outline_rounded,
                      color: const Color(0xFFFFD873)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(
                    locking ? 'Lumo prüft deine Antwort …'
                        : 'Antwort einloggen',
                    maxLines: 2, textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enabled || locking
                        ? Colors.white : Colors.white60,
                      fontFamily: 'Nunito', fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  )),
                ]),
                if (locking) ...[
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                      milliseconds: reduceMotion ? 750 : 1600),
                    builder: (context, progress, _) =>
                      LinearProgressIndicator(
                        value: progress, minHeight: 5,
                        backgroundColor: const Color(0xFF11295A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD76A)),
                      ),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x3328D7FA),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        border: Border.all(color: LumoVisualTokens.cyanBright.withOpacity(.55)),
      ),
      child: Text(
        text,
        style: LumoTextStyles.label.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.index,
    required this.hidden,
    required this.selected,
    required this.revealed,
    required this.correct,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool hidden;
  final bool selected;
  final bool revealed;
  final bool correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return Opacity(
        opacity: .28,
        child: _shell(
          'Antwort verborgen',
          Colors.white70,
          const Color(0xCC102A50),
          LumoVisualTokens.cyan.withOpacity(.25),
        ),
      );
    }

    final color = revealed && correct
        ? Colors.white
        : revealed && selected
            ? Colors.white
            : Colors.white;
    final bg = revealed && correct
        ? const Color(0xFF16794B)
        : revealed && selected
            ? const Color(0xFF9F3042)
            : selected
                ? const Color(0xFFE58A22)
                : const Color(0xE6122C52);

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: _shell('${String.fromCharCode(65 + index)}  $label', color, bg, color),
    );
  }

  Widget _shell(String text, Color fg, Color bg, Color? border) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          bg, Color.lerp(bg, const Color(0xFF1688CB), .28)!,
        ]),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(
          color: border?.withOpacity(.75) ??
              LumoVisualTokens.cyanBright.withOpacity(.38),
          width: selected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (border ?? LumoVisualTokens.cyanBright).withOpacity(.14),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: fg),
      ),
    );
  }
}

class _JokerButton extends StatelessWidget {
  const _JokerButton({
    required this.label, required this.icon,
    required this.used, required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: used ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 68),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        backgroundColor: used
            ? const Color(0xFF26344E) : const Color(0xFF113C84),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white60,
        side: BorderSide(
          color: used ? Colors.white24 : LumoVisualTokens.cyanBright,
          width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: used
            ? Colors.white38 : const Color(0xFFFFD873)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(used ? label + ' ✓' : label,
            maxLines: 1, style: const TextStyle(
              fontSize: 11, fontFamily: 'Nunito',
              fontWeight: FontWeight.w900)),
        ),
      ]),
    ),
  );
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(LumoRadius.lg)),
      child: Text('🦊 $text', style: LumoTextStyles.body),
    );
  }
}

class _AudienceVotes extends StatelessWidget {
  const _AudienceVotes({required this.votes});
  final List<int> votes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(votes.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(width: 28, child: Text(String.fromCharCode(65 + i), style: LumoTextStyles.label)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: votes[i] / 100,
                  minHeight: 10,
                  color: LumoColors.orange,
                  backgroundColor: LumoColors.orange.withOpacity(.13),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 42, child: Text('${votes[i]}%', textAlign: TextAlign.right, style: LumoTextStyles.caption)),
          ]),
        );
      }),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.correct,
    required this.answer,
    required this.won,
    required this.securedStars,
    required this.awardedStars,
  });

  final bool correct;
  final String answer;
  final bool won;
  final int securedStars;
  final int awardedStars;

  @override
  Widget build(BuildContext context) {
    final color = correct ? Colors.green : Colors.redAccent;
    final text = won
        ? '🏆 Lumo-Meister! 20 von 20 geschafft – 5.000 virtuelle App-Sterne gewonnen! Ein Familienausflug ist nur eine Wunsch-Idee, über die deine Eltern entscheiden.'
        : correct
            ? securedStars > 0
                ? '✅ Richtig! Sichere Stufe: $securedStars Sterne.'
                : '✅ Richtig! Weiter geht’s.'
            : awardedStars > 0
                ? '💡 Richtig wäre: $answer\n⭐ Du sicherst $awardedStars Sterne.'
                : '💡 Richtig wäre: $answer\nBeim nächsten Versuch schaffst du die erste Stern-Stufe!';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        text,
        style: LumoTextStyles.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

