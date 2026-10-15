import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_sound.dart';
import '../../app/app_theme.dart';
import '../../domain/quiz/quiz_question_bank.dart';
import '../../domain/quiz/quiz_show.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

class QuizShowContent extends StatefulWidget {
  const QuizShowContent({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<QuizShowContent> createState() => _QuizShowContentState();
}

class _QuizShowContentState extends State<QuizShowContent> {
  static const _engine = QuizShowEngine();
  static const _bank = QuizQuestionBank();
  late QuizShowState _state;

  @override
  void initState() {
    super.initState();
    unawaited(LumoSound.instance.init());
    _startNewGame();
  }

  void _startNewGame() {
    final questions = _bank.generateGameQuestions(
      grade: widget.appState.state.grade,
      random: math.Random(DateTime.now().millisecondsSinceEpoch),
    );
    _state = _engine.start(questions: questions);
  }

  void _select(int index) {
    final next = _engine.selectAnswer(_state, index);
    if (next.selectedOption != _state.selectedOption) {
      unawaited(LumoSound.instance.play(SoundEffect.click));
    }
    setState(() => _state = next);
  }

  void _reveal() {
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
      unawaited(LumoSound.instance.play(SoundEffect.error));
    } else if (_state.won || _state.securedStars > before.securedStars) {
      unawaited(LumoSound.instance.play(SoundEffect.win));
    }
  }

  void _next() {
    unawaited(LumoSound.instance.play(SoundEffect.click));
    setState(() => _state = _engine.nextQuestion(_state));
  }

  void _joker(QuizJoker joker) {
    final next = _engine.useJoker(_state, joker);
    if (next.usedJokers.length > _state.usedJokers.length) {
      unawaited(LumoSound.instance.play(SoundEffect.click));
    }
    setState(() => _state = next);
  }

  void _restart() {
    unawaited(LumoSound.instance.play(SoundEffect.click));
    setState(_startNewGame);
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
              final wide = constraints.maxWidth >= 720;
              final card = _QuizCard(
                state: _state,
                question: q,
                onSelect: _select,
                onReveal: _reveal,
                onNext: _next,
                onRestart: _restart,
                onJoker: _joker,
              );
              final prizes = _PrizeColumn(state: _state);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: card),
                          const SizedBox(width: 18),
                          SizedBox(width: 280, child: prizes),
                        ],
                      )
                    : Column(
                        children: [
                          card,
                          const SizedBox(height: 16),
                          prizes,
                        ],
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
  });

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
          _QuizHost(
            questionNumber: state.displayQuestionNumber,
            finale: finale,
            won: state.won,
          ),
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
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: LumoTextStyles.heading1.copyWith(
              fontSize: finale ? 30 : 28,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Color(0xAA000000), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _JokerButton(label: '50:50', used: state.usedJokers.contains(QuizJoker.fiftyFifty), onTap: () => onJoker(QuizJoker.fiftyFifty)),
              _JokerButton(label: 'Publikum', used: state.usedJokers.contains(QuizJoker.audience), onTap: () => onJoker(QuizJoker.audience)),
              _JokerButton(label: 'Lumo anrufen', used: state.usedJokers.contains(QuizJoker.callLumo), onTap: () => onJoker(QuizJoker.callLumo)),
            ],
          ),
          if (state.lumoHint != null) ...[
            const SizedBox(height: 14),
            _HintBubble(text: state.lumoHint!),
          ],
          if (state.audienceVotes != null) ...[
            const SizedBox(height: 14),
            _AudienceVotes(votes: state.audienceVotes!),
          ],
          const SizedBox(height: 18),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerButton(
                label: question.options[i],
                index: i,
                hidden: state.fiftyFiftyHiddenOptions.contains(i),
                selected: selected == i,
                revealed: answered,
                correct: question.correctIndex == i,
                onTap: () => onSelect(i),
              ),
            ),
          const SizedBox(height: 8),
          if (state.gameOver)
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(state.won ? 'Nochmal Lumo-Meister werden' : 'Neue Quizrunde starten'),
            )
          else if (!answered)
            FilledButton.icon(
              onPressed: selected == null ? null : onReveal,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Antwort einloggen'),
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


class _QuizHost extends StatelessWidget {
  const _QuizHost({
    required this.questionNumber,
    required this.finale,
    required this.won,
  });

  final int questionNumber;
  final bool finale;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final message = won
        ? 'Du bist Lumo-Meister!'
        : finale
            ? 'Das ist die Meisterfrage!'
            : questionNumber >= 15
                ? 'Jetzt wird es richtig spannend!'
                : 'Bereit? Denk in Ruhe nach.';

    return Semantics(
      label: 'Lumo moderiert die Quizshow',
      child: Row(
        children: [
          LumoCharacter(
            pose: won || finale
                ? LumoDesignFoxPose.trophyWink
                : LumoDesignFoxPose.pointSide,
            size: 92,
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            idleHops: !finale,
            ambientPoses: finale
                ? const <LumoDesignFoxPose>[]
                : const <LumoDesignFoxPose>[
                    LumoDesignFoxPose.thumbWink,
                    LumoDesignFoxPose.teacherStick,
                  ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: finale
                    ? const Color(0x33FFC94A)
                    : const Color(0x3328D7FA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: finale
                      ? const Color(0xFFFFC94A)
                      : LumoVisualTokens.cyanBright.withOpacity(.55),
                ),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
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
  final VoidCallback onTap;

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
        color: bg,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(
          color: border?.withOpacity(.75) ??
              LumoVisualTokens.cyanBright.withOpacity(.38),
          width: 1.2,
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
  const _JokerButton({required this.label, required this.used, required this.onTap});
  final String label;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: used ? null : onTap, child: Text(used ? '$label ✓' : label));
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

class _PrizeColumn extends StatelessWidget {
  const _PrizeColumn({required this.state});
  final QuizShowState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xE8082144),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LumoVisualTokens.cyanBright.withOpacity(.45)),
        boxShadow: [
          BoxShadow(
            color: LumoVisualTokens.cyan.withOpacity(.12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Deine Stern-Leiter',
            style: LumoTextStyles.heading3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Bei einer falschen Antwort bleiben die zuletzt gesicherten Sterne erhalten.',
            style: LumoTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          _Milestone(
            label: 'Frage 5  •  50 Sterne',
            emoji: '⭐',
            active: state.securedStars >= 50,
          ),
          _Milestone(
            label: 'Frage 10  •  200 Sterne',
            emoji: '🌟',
            active: state.securedStars >= 200,
          ),
          _Milestone(
            label: 'Frage 15  •  800 Sterne',
            emoji: '🏅',
            active: state.securedStars >= 800,
          ),
          _Milestone(
            label: 'Frage 20  •  5.000 Sterne',
            emoji: '🎢',
            active: state.securedStars >= 5000,
          ),
          const SizedBox(height: 8),
          Text(
            'Finalziel: 5.000 App-Sterne · Familienausflug nur als Wunsch-Idee mit Eltern',
            style: LumoTextStyles.body.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFD873),
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.label, required this.emoji, required this.active});
  final String label;
  final String emoji;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? const Color(0x6637D2FD)
            : const Color(0x99122C52),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(
          color: active
              ? LumoVisualTokens.cyanBright
              : Colors.white.withOpacity(.10),
        ),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: LumoTextStyles.body.copyWith(
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ]),
    );
  }
}
