import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_sound.dart';
import 'quiz_show_music.dart';
import 'quiz_studio_scene.dart';
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
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Wer wird Lumo-Meister?',
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(color: Color(0xAA19B7FF), blurRadius: 12),
              ],
            ),
          ),
        ),
        backgroundColor: const Color(0xFF071432),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF092A67), Color(0xFF04102C),
                Color(0xFF12285C)],
            ),
            border: Border(
              bottom: BorderSide(color: Color(0xFF2BCAFF), width: 1.2),
            ),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 13),
            child: Icon(Icons.star_rounded,
              color: Color(0xFFFFDA77), size: 27),
          ),
        ],
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
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width <= 360 ? 10 : 20),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  question.subject,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: LumoTextStyles.caption.copyWith(
                    color: finale
                        ? const Color(0xFFFFD873)
                        : LumoVisualTokens.cyanBright,
                    fontWeight: FontWeight.w900,
                  ),
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF064DAB),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(53),
                side: const BorderSide(
                  color: Color(0xFFFFD777), width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
                textStyle: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 17,
                  fontWeight: FontWeight.w900),
              ),
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


/// The three real jokers and the 20-step ladder flank a lit TV-show set.
/// Each control remains inside its own hitbox on phones and unfolded Fold.
class _QuizStage extends StatelessWidget {
  const _QuizStage({required this.state, required this.onJoker});
  final QuizShowState state;
  final ValueChanged<QuizJoker> onJoker;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final compact = c.maxWidth < 400;
      final tablet = c.maxWidth >= 700;
      final leftWidth = tablet ? 106.0
          : compact ? math.max(44.0, c.maxWidth * .17) : 84.0;
      final rightWidth = tablet ? 170.0
          : compact ? math.max(80.0, c.maxWidth * .29) : 130.0;
      final gap = tablet ? 14.0 : compact ? 4.0 : 6.0;
      final usable = math.max(
        38.0, c.maxWidth - leftWidth - rightWidth - gap * 2,
      );
      final foxSize = math.min(
        tablet ? 330.0 : (compact ? 208.0 : 262.0),
        math.max(38.0, usable - 4),
      );
      final current = state.displayQuestionNumber;
      final finale = current == state.questions.length;
      final caption = state.won ? 'LUMO-MEISTER!'
          : finale ? 'MEISTERFRAGE!'
          : current >= 15 ? 'DU SCHAFFST DAS!'
          : 'LUMO LIVE';
      final scale = math.max(1.0, MediaQuery.textScalerOf(context).scale(1));

      return ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: SizedBox(
          key: const ValueKey('lumo-meister-stage'),
          height: (compact ? 414.0 : tablet ? 510.0 : 455.0) * scale,
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: QuizStudioScene()),
              ),
              Positioned.fill(
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
                            label: '50:50',
                            icon: Icons.filter_2_rounded,
                            used: state.usedJokers.contains(QuizJoker.fiftyFifty),
                            onTap: () => onJoker(QuizJoker.fiftyFifty),
                          ),
                          const SizedBox(height: 9),
                          _JokerButton(
                            label: 'Publikum',
                            icon: Icons.groups_rounded,
                            used: state.usedJokers.contains(QuizJoker.audience),
                            onTap: () => onJoker(QuizJoker.audience),
                          ),
                          const SizedBox(height: 9),
                          _JokerButton(
                            label: 'Lumo-Tipp',
                            icon: Icons.lightbulb_rounded,
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
                            Positioned(
                              left: 0, right: 0, top: 7,
                              child: Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xC905204B),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xAA56E7FF)),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.star_rounded,
                                          color: Color(0xFFFFD978), size: 12),
                                        SizedBox(width: 3),
                                        Text('LIVE',
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: Color(0xFFFFE3A0),
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11)),
                                        SizedBox(width: 3),
                                        Icon(Icons.star_rounded,
                                          color: Color(0xFFFFD978), size: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0, right: 0, bottom: 45,
                              child: Center(
                                child: SizedBox(
                                  key: const ValueKey('lumo-meister-fox-slot'),
                                  width: foxSize, height: foxSize * 1.12,
                                  child: Image.asset(
                                    'assets/lumo_design/fox/fox_quiz_host_1982.webp',
                                    key: const ValueKey('lumo-meister-fox'),
                                    width: foxSize, height: foxSize * 1.12,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    semanticLabel:
                                      'Lumo moderiert die Quizshow mit Fliege, Mikrofon und Sternkarte',
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6, left: 0, right: 0,
                              child: IgnorePointer(
                                child: Container(
                                  height: 39,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF06143A),
                                        Color(0xFF1549A0),
                                        Color(0xFF071637),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFFFD26F),
                                      width: 1.8),
                                    borderRadius: BorderRadius.circular(13),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xB3FFB83A),
                                        blurRadius: 15),
                                      BoxShadow(
                                        color: Color(0x8034E5FF),
                                        blurRadius: 20),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded,
                                          color: Color(0xFFFFD978), size: 19),
                                        const SizedBox(width: 7),
                                        Text(caption,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Color(0xFFFFD978),
                                            fontSize: 18,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1)),
                                        const SizedBox(width: 7),
                                        const Icon(Icons.star_rounded,
                                          color: Color(0xFFFFD978), size: 19),
                                      ],
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
              ),
            ],
          ),
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

/// One accessible, glossy answer card with a separate gold letter medallion.
/// Kept as native Flutter controls so state, focus and touch remain real.
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
    final letter = String.fromCharCode(65 + index);
    final enabled = !hidden && !revealed && onTap != null;
    final showCorrect = revealed && correct;
    final showError = revealed && selected && !correct;
    final colors = showCorrect
      ? const [Color(0xFF034D3A), Color(0xFF139D73)]
      : showError
        ? const [Color(0xFF51152F), Color(0xFFB73A55)]
        : selected
          ? const [Color(0xFF673E0D), Color(0xFFCE8B1C)]
          : const [Color(0xFF061637), Color(0xFF0547A4), Color(0xFF042B79)];
    final border = showCorrect
      ? const Color(0xFF7BFFC6)
      : showError
        ? const Color(0xFFFF92A2)
        : selected
          ? const Color(0xFFFFE69C)
          : const Color(0xFF48E4FF);
    return Opacity(
      opacity: hidden ? .27 : 1,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: '$letter: $label',
        child: AnimatedContainer(
          key: ValueKey('lumo-meister-answer-$index'),
          duration: const Duration(milliseconds: 210),
          constraints: const BoxConstraints(minHeight: 66),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: border, width: 2.1),
            boxShadow: [
              BoxShadow(
                color: border.withOpacity(selected ? .51 : .31),
                blurRadius: selected ? 19 : 13,
                spreadRadius: selected ? 1.5 : .5,
              ),
              const BoxShadow(
                color: Color(0x99000B2A),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(27),
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                child: Row(children: [
                  Container(
                    width: 41, height: 41,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F4B94), Color(0xFF06122C)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF6CCBFF), width: 1.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x664CE5FF), blurRadius: 9),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(letter,
                      style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 24,
                        color: Color(0xFFFFD978),
                        fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(hidden ? '—' : label,
                      key: ValueKey('lumo-meister-answer-text-$index'),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                  ),
                ]),
              ),
            ),
          ),
        ),
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
  Widget build(BuildContext context) {
    return Opacity(
      opacity: used ? .50 : 1,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0A69C8), Color(0xFF071D56),
              Color(0xFF0745A3)],
          ),
          border: Border.all(
            color: used ? const Color(0xFF69809F)
                : const Color(0xFF61E6FF),
            width: 1.8),
          boxShadow: used ? null : const [
            BoxShadow(color: Color(0xBB00C7FF), blurRadius: 13),
            BoxShadow(color: Color(0x5502A9FF), blurRadius: 22),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: used ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 27,
                    color: used ? Colors.white54
                      : const Color(0xFFFFD978)),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        ? 'Lumo-Meister! 20 von 20 geschafft – 5.000 virtuelle App-Sterne gewonnen! Ein Familienausflug ist nur eine Wunsch-Idee, über die deine Eltern entscheiden.'
        : correct
            ? securedStars > 0
                ? 'Richtig! Sichere Stufe: $securedStars Sterne.'
                : 'Richtig! Weiter geht’s.'
            : awardedStars > 0
                ? 'Richtig wäre: $answer\nDu sicherst $awardedStars Sterne.'
                : 'Richtig wäre: $answer\nBeim nächsten Versuch schaffst du die erste Stern-Stufe!';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Icon(won ? Icons.emoji_events_rounded
              : correct ? Icons.check_circle_rounded
              : Icons.lightbulb_rounded,
            color: correct ? const Color(0xFF87FFBE)
                : const Color(0xFFFFD776), size: 26),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: LumoTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

