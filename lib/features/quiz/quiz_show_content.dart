import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../domain/quiz/quiz_question_bank.dart';
import '../../domain/quiz/quiz_rewards.dart';
import '../../domain/quiz/quiz_show.dart';
import '../../widgets/fox/lumo_idle_fox.dart';
import '../../widgets/fox/lumo_reaction_companion.dart';
import '../../widgets/premium/lumo_reward_burst.dart';

class QuizShowContent extends StatefulWidget {
  const QuizShowContent({super.key, required this.appState});

  final LumoAppState appState;

  @override
  State<QuizShowContent> createState() => _QuizShowContentState();
}

class _QuizShowContentState extends State<QuizShowContent> {
  static const _engine = QuizShowEngine();
  static const _bank = QuizQuestionBank();
  final _rng = math.Random();

  late QuizShowState _state;

  /// Stimmung des Quiz-Companions. Cheer bei richtiger, think bei
  /// falscher Antwort. Auto-Reset auf idle nach 2s.
  LumoReactionMood _companionMood = LumoReactionMood.idle;
  Timer? _moodResetTimer;

  void _setMood(LumoReactionMood next) {
    _moodResetTimer?.cancel();
    if (!mounted) return;
    setState(() => _companionMood = next);
    if (next != LumoReactionMood.idle) {
      _moodResetTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _companionMood = LumoReactionMood.idle);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _moodResetTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    final questions = _bank.generateGameQuestions(
      grade: widget.appState.state.grade,
      random: math.Random(DateTime.now().millisecondsSinceEpoch),
    );
    _state = _engine.start(questions: questions);
  }

  QuizCoupon _drawCoupon(int level) {
    final pool = QuizRewardCatalog.poolForLevel(level);
    if (pool.isEmpty) {
      return const QuizCoupon(
        id: 'lumo_stern',
        title: 'Lumo-Stern',
        emoji: '⭐',
        description: 'Du hast eine sichere Quiz-Stufe geschafft.',
        milestoneLevel: 1,
      );
    }
    return pool[_rng.nextInt(pool.length)];
  }

  void _select(int index) {
    setState(() => _state = _engine.selectAnswer(_state, index));
  }

  void _reveal() {
    setState(() {
      _state = _engine.reveal(_state, drawCouponForMilestone: _drawCoupon);
    });
    // Phase 3+5: Sterne sprudeln + Lumo-Mood-Reaction.
    final q = _state.currentQuestion;
    final correct = _state.selectedOption == q.correctIndex;
    _setMood(correct ? LumoReactionMood.cheer : LumoReactionMood.think);
    if (correct && mounted) {
      showLumoRewardBurst(context, stars: 1);
    }
  }

  void _next() {
    setState(() => _state = _engine.nextQuestion(_state));
  }

  void _joker(QuizJoker joker) {
    setState(() => _state = _engine.useJoker(_state, joker));
  }

  void _restart() {
    setState(_startNewGame);
  }

  @override
  Widget build(BuildContext context) {
    final q = _state.currentQuestion;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(
        title: const Text('Wer wird Lumo-Champion?'),
        backgroundColor: Colors.white,
        foregroundColor: LumoColors.ink900,
        elevation: 0,
      ),
      body: SafeArea(
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
            // Phase 3: Quiz-Companion unten rechts - reagiert auf
            // jede Antwort sichtbar mit cheer/think. Idle wenn nichts
            // los ist. Konsistent mit AdaptiveTaskRenderer + beiden
            // Schreibcoaches.
            final companion = Align(
              alignment: Alignment.centerRight,
              child: LumoReactionCompanion(
                mood: _companionMood,
                size: 80,
                // Phase 3: Tap auf Lumo schlaegt einen Joker vor.
                onTap: () {
                  _setMood(LumoReactionMood.think);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: const Text(
                          '🦊 Wenn du unsicher bist, probier einen Joker - 50:50 hilft am meisten!',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      backgroundColor: const Color(0xFF7C3AED),
                      duration: const Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                    ));
                },
              ),
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(children: [
                            card,
                            const SizedBox(height: 14),
                            companion,
                          ]),
                        ),
                        const SizedBox(width: 18),
                        SizedBox(width: 280, child: prizes),
                      ],
                    )
                  : Column(children: [
                      card,
                      const SizedBox(height: 16),
                      prizes,
                      const SizedBox(height: 14),
                      companion,
                    ]),
            );
          },
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: lumoCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFEAD5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _Pill('Frage ${state.displayQuestionNumber} / ${state.questions.length}'),
            const Spacer(),
            Text(question.subject, style: LumoTextStyles.caption),
          ]),
          const SizedBox(height: 18),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: LumoTextStyles.heading1.copyWith(fontSize: 34, height: 1.15),
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
          // Phase 5 Premium: bei genau 4 Optionen 2x2 Grid (kindgerechter,
          // satter), bei 3 oder anderer Anzahl vertikal listen.
          LayoutBuilder(builder: (context, c) {
            final use2x2 = question.options.length == 4 && c.maxWidth >= 320;
            if (use2x2) {
              final itemWidth = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < question.options.length; i++)
                    SizedBox(
                      width: itemWidth,
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
                ],
              );
            }
            return Column(
              children: [
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
              ],
            );
          }),
          const SizedBox(height: 8),
          if (state.gameOver)
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(state.won ? 'Nochmal Champion werden' : 'Neue Quizrunde starten'),
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
            _ResultPanel(correct: isCorrect, answer: question.correctAnswer, won: state.won),
          ],
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
        color: LumoColors.orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
      ),
      child: Text(text, style: LumoTextStyles.label.copyWith(color: LumoColors.orange)),
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
      return Opacity(opacity: .28, child: _shell('Antwort verborgen', LumoColors.ink300, Colors.white, null));
    }

    final color = revealed && correct
        ? Colors.green
        : revealed && selected
            ? Colors.redAccent
            : selected
                ? LumoColors.orange
                : LumoColors.ink700;
    final bg = revealed && correct
        ? const Color(0xFFE8FCEB)
        : revealed && selected
            ? const Color(0xFFFFE8E8)
            : selected
                ? const Color(0xFFFFEDD5)
                : Colors.white;

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: _shell('${String.fromCharCode(65 + index)}  $label', color, bg, color),
    );
  }

  Widget _shell(String text, Color fg, Color bg, Color? border) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      // Phase 5: Buttons satter - mehr vertikales Padding, dickerer
      // Border, kraeftigerer Schatten. Mindesthoehe sorgt fuer
      // gleichmaessiges 2x2-Grid-Aussehen.
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(
          color: border?.withOpacity(.65) ?? const Color(0xFFFFD7AD),
          width: 2,
        ),
        boxShadow: [BoxShadow(color: fg.withOpacity(.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: fg,
          height: 1.2,
        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border:
            Border.all(color: const Color(0xFF8B5CF6).withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const LumoIdleFox(size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: LumoTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5B21B6),
                  height: 1.35)),
        ),
      ]),
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
  const _ResultPanel({required this.correct, required this.answer, required this.won});
  final bool correct;
  final String answer;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final color = correct ? Colors.green : Colors.redAccent;
    final text = won
        ? '🏆 Lumo-Champion! Du hast alle Fragen geschafft.'
        : correct
            ? '✅ Richtig! Weiter geht’s.'
            : '💡 Richtig wäre: $answer';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(text, style: LumoTextStyles.body.copyWith(color: LumoColors.ink900, fontWeight: FontWeight.w800)),
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
      decoration: lumoCard(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sichere Stufen', style: LumoTextStyles.heading3),
          const SizedBox(height: 10),
          _Milestone(label: 'Frage 5', emoji: '🍦', active: state.currentQuestionIndex >= 4),
          _Milestone(label: 'Frage 10', emoji: '🎬', active: state.currentQuestionIndex >= 9),
          _Milestone(label: 'Frage 15', emoji: '🧸', active: state.currentQuestionIndex >= 14),
          if (state.earnedCoupons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Gewonnen', style: LumoTextStyles.heading3),
            const SizedBox(height: 8),
            for (final c in state.earnedCoupons)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(LumoRadius.md)),
                child: Text('${c.emoji} ${c.title}', style: LumoTextStyles.body),
              ),
          ],
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
        color: active ? const Color(0xFFFFEDD5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(LumoRadius.md),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Text(label, style: LumoTextStyles.body.copyWith(fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
