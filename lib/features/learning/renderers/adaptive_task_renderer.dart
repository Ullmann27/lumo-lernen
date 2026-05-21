import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../widgets/fox/lumo_idle_fox.dart';
import '../../../widgets/fox/lumo_reaction_companion.dart';
import '../../../widgets/premium/lumo_reward_burst.dart';
import '../../schoolbook/widgets/schoolbook_task_widgets.dart';
import 'lumo_premium_visuals.dart';
import 'writing_task_renderer.dart';

class AdaptiveTaskAnswer {
  const AdaptiveTaskAnswer({
    required this.task,
    required this.answer,
    required this.correct,
  });

  final TaskInstance task;
  final Object answer;
  final bool correct;
}

class AdaptiveTaskRenderer extends StatefulWidget {
  const AdaptiveTaskRenderer({
    super.key,
    required this.task,
    this.onAnswered,
    this.onWritingSubmitted,
  });

  final TaskInstance task;
  final ValueChanged<AdaptiveTaskAnswer>? onAnswered;
  final ValueChanged<WritingTaskResult>? onWritingSubmitted;

  @override
  State<AdaptiveTaskRenderer> createState() => _AdaptiveTaskRendererState();
}

class _AdaptiveTaskRendererState extends State<AdaptiveTaskRenderer> {
  Object? _picked;
  final Set<String> _wrongAnswers = <String>{};

  /// Stimmung des begleitenden Lumo-Companion. Cheer/Think kehren
  /// automatisch nach 2 Sekunden zurueck auf idle.
  LumoReactionMood _companionMood = LumoReactionMood.idle;
  Timer? _moodResetTimer;

  bool get _solved => _picked != null && '$_picked' == '${widget.task.correctAnswer}';

  @override
  void dispose() {
    _moodResetTimer?.cancel();
    super.dispose();
  }

  void _setMood(LumoReactionMood next) {
    _moodResetTimer?.cancel();
    setState(() => _companionMood = next);
    if (next != LumoReactionMood.idle) {
      _moodResetTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _companionMood = LumoReactionMood.idle);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    if (task.taskType == TaskType.writingCanvas) {
      return WritingTaskRenderer(
        task: task,
        onSubmitted: widget.onWritingSubmitted,
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: lumoCard(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8ED), Color(0xFFFFFEFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _subjectLabel(task.subject),
            style: LumoTextStyles.label.copyWith(color: LumoColors.orange, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Text(
            task.prompt,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 18),
          // Phase 3: solved=true zeigt den Loesungsweg-Bonus IM Visual.
          // Ab 2 Fehlern auch ohne richtige Antwort -> didaktische Hilfe
          // (Lumo erklaert was die korrekte Loesung WAERE).
          _AdaptiveVisual(
            task: task,
            picked: _picked,
            solved: _solved || _wrongAnswers.length >= 2,
          ),
          if (_wrongAnswers.length >= 2 && !_solved) ...[
            const SizedBox(height: 14),
            _LocalHelpBanner(task: task, wrongCount: _wrongAnswers.length),
          ],
        ]),
      ),
      const SizedBox(height: 18),
      Text(
        _wrongAnswers.length >= 2 && !_solved
            ? 'Versuch es nochmal mit Lumos Hilfe:'
            : 'Wähle die richtige Antwort:',
        style: LumoTextStyles.label.copyWith(color: LumoColors.ink500, fontSize: 16),
      ),
      const SizedBox(height: 12),
      _OptionGrid(
        task: task,
        picked: _picked,
        wrongAnswers: _wrongAnswers,
        solved: _solved,
        onPick: _pick,
      ),
      const SizedBox(height: 16),
      // Phase 3: kleiner Lumo-Companion rechts unten, reagiert sichtbar
      // auf richtige (cheer) oder falsche (think) Antworten.
      Align(
        alignment: Alignment.centerRight,
        child: LumoReactionCompanion(
          mood: _companionMood,
          size: 84,
        ),
      ),
    ]);
  }

  void _pick(AnswerOption option) {
    if (_solved) return;
    final answer = option.payload ?? option.label;
    final answerKey = '$answer';
    if (_wrongAnswers.contains(answerKey)) return;
    final correct = answerKey == '${widget.task.correctAnswer}';

    setState(() {
      if (correct) {
        _picked = answer;
      } else {
        _wrongAnswers.add(answerKey);
      }
    });

    // Lumo-Companion reagiert sichtbar (Phase 3): bei richtiger Antwort
    // jubelt er, bei falscher Antwort guckt er nachdenklich.
    _setMood(correct ? LumoReactionMood.cheer : LumoReactionMood.think);

    if (correct) {
      // Phase 3: Sterne sprudeln raus. Heinz' Wunsch: 'nicht nur Bounce,
      // auch ein Sparkle-Effect, dann LumoRewardBurst (1 Stern)'.
      if (mounted) {
        showLumoRewardBurst(context, stars: 1);
      }
      widget.onAnswered?.call(
        AdaptiveTaskAnswer(task: widget.task, answer: answer, correct: true),
      );
    }
  }

  String _subjectLabel(LearningSubject subject) {
    return switch (subject) {
      LearningSubject.deutsch => 'Deutsch',
      LearningSubject.mathematik => 'Mathematik',
      LearningSubject.sachkunde => 'Sachkunde',
    };
  }
}

class _LocalHelpBanner extends StatelessWidget {
  const _LocalHelpBanner({required this.task, required this.wrongCount});

  final TaskInstance task;
  final int wrongCount;

  @override
  Widget build(BuildContext context) {
    final hint = _buildHint(task);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const LumoIdleFox(size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              wrongCount == 2 ? 'Lumo hilft jetzt Schritt für Schritt' : 'Noch ein Tipp von Lumo',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 5),
            Text(
              hint,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: LumoColors.ink700, height: 1.35),
            ),
          ]),
        ),
      ]),
    );
  }

  String _buildHint(TaskInstance task) {
    final prompt = task.prompt.toLowerCase();
    final numbers = _allInts(task.prompt);
    if (task.subject == LearningSubject.mathematik && numbers.length >= 2) {
      final a = numbers[0];
      final b = numbers[1];
      final op = _operationFromTask(task);
      if (op == 'subtraction') {
        return 'Du startest mit $a. Dann nimmst du $b weg. Decke $b Dinge ab oder streiche sie. Was übrig bleibt, ist die Antwort.';
      }
      return 'Zähle zuerst $a Dinge, dann noch $b dazu. Danach zählst du alle zusammen.';
    }
    if (prompt.contains('silbe')) {
      return 'Sprich das Wort langsam. Bei jeder Silbe klatschst du einmal mit.';
    }
    if (prompt.contains('anfangs') || prompt.contains('laut')) {
      return 'Sprich das Wort ganz langsam und höre nur auf den ersten oder letzten Laut.';
    }
    return 'Lies die Aufgabe noch einmal langsam. Suche zuerst die wichtigen Wörter und dann die passende Antwort.';
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.task,
    required this.picked,
    required this.wrongAnswers,
    required this.solved,
    required this.onPick,
  });

  final TaskInstance task;
  final Object? picked;
  final Set<String> wrongAnswers;
  final bool solved;
  final ValueChanged<AnswerOption> onPick;

  @override
  Widget build(BuildContext context) {
    // Phase 2D: nach 2 Fehlversuchen die korrekte Antwort sanft glowen.
    // Konsistent mit _LocalHelpBanner, der ab demselben Schwellwert sichtbar
    // wird - Hinweis ohne Spoiler-Effekt nach dem ersten Versuch.
    final glowCorrect = wrongAnswers.length >= 2 && !solved;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 460;
      final itemWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: task.options.map((option) {
          final payload = option.payload ?? option.label;
          final isPicked = picked != null && '$picked' == '$payload';
          final isWrongPicked = wrongAnswers.contains('$payload');
          final isCorrect = '$payload' == '${task.correctAnswer}';
          return SizedBox(
            width: itemWidth,
            child: _AnswerButton(
              label: option.label,
              isPicked: isPicked,
              isWrongPicked: isWrongPicked,
              isCorrect: isCorrect,
              solved: solved,
              highlightCorrect: glowCorrect && isCorrect,
              onTap: () => onPick(option),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _AnswerButton extends StatefulWidget {
  const _AnswerButton({
    required this.label,
    required this.isPicked,
    required this.isWrongPicked,
    required this.isCorrect,
    required this.solved,
    required this.onTap,
    this.highlightCorrect = false,
  });

  final String label;
  final bool isPicked;
  final bool isWrongPicked;
  final bool isCorrect;
  final bool solved;
  final bool highlightCorrect;
  final VoidCallback onTap;

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.highlightCorrect) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnswerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightCorrect != widget.highlightCorrect) {
      if (widget.highlightCorrect) {
        _glow.repeat(reverse: true);
      } else {
        _glow.stop();
        _glow.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;

    if (widget.solved && widget.isCorrect) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      textColor = const Color(0xFF14532D);
    } else if (widget.isWrongPicked) {
      bg = const Color(0xFFFFE4E6);
      border = const Color(0xFFF43F5E);
      textColor = const Color(0xFF881337);
    } else if (widget.solved) {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink300;
    } else if (widget.highlightCorrect) {
      // Sanfter gruener Glow auf der korrekten Antwort nach 2 Fehlern.
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFF34D399);
      textColor = const Color(0xFF065F46);
    } else {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink900;
    }

    // Heinz' Wunsch: Mathe-Zahlen (kurze Labels) deutlich groesser
    // darstellen, normale Antworten satter, lange Texte ohne Overflow.
    // Heuristik nach Label-Laenge.
    final labelLen = widget.label.length;
    final double labelFontSize;
    final double verticalPadding;
    final int maxLines;
    if (labelLen <= 3) {
      // Mathe-Zahlen: '8', '10', '100' - sehr gross + viel Padding
      labelFontSize = 38;
      verticalPadding = 24;
      maxLines = 1;
    } else if (labelLen <= 8) {
      // Kurzwoerter: 'Hase', 'Forelle', 'Mama'
      labelFontSize = 28;
      verticalPadding = 20;
      maxLines = 1;
    } else {
      // Lange Saetze - kompakter, ohne Overflow
      labelFontSize = 20;
      verticalPadding = 16;
      maxLines = 2;
    }

    return GestureDetector(
      onTap: widget.solved || widget.isWrongPicked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) {
          // Sanfter pulsierender Schatten nur wenn highlightCorrect aktiv.
          final pulse = widget.highlightCorrect ? _glow.value : 0.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
                horizontal: 18, vertical: verticalPadding),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              border: Border.all(color: border, width: 2),
              boxShadow: widget.highlightCorrect
                  ? [
                      BoxShadow(
                        color: const Color(0xFF34D399)
                            .withOpacity(0.28 + pulse * 0.32),
                        blurRadius: 14 + pulse * 10,
                        spreadRadius: 1 + pulse * 2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.solved && widget.isCorrect)
            const Padding(
              padding: EdgeInsets.only(right: 7),
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 24),
            ),
          if (widget.isWrongPicked)
            const Padding(
              padding: EdgeInsets.only(right: 7),
              child: Icon(Icons.cancel_rounded, color: Color(0xFFF43F5E), size: 24),
            ),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: labelFontSize,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AdaptiveVisual extends StatelessWidget {
  const _AdaptiveVisual({required this.task, required this.picked, required this.solved});

  final TaskInstance task;
  final Object? picked;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return switch (task.visualPayload.type) {
      VisualType.dots => _DotsVisual(task: task, solved: solved),
      VisualType.tenOnes => _TenOnesVisual(task: task),
      VisualType.numberLine => _NumberLineVisual(task: task, picked: picked, solved: solved),
      VisualType.shape => _ShapeVisual(task: task, picked: picked, solved: solved),
      VisualType.syllables => _SyllableVisual(task: task),
      // Heinz' neue Visuals (Mai 2026):
      VisualType.quantityCompare => QuantityCompareVisual(task: task),
      VisualType.clock => ClockFaceVisual(task: task),
      VisualType.money => MoneyCoinsVisual(task: task),
      VisualType.fractionPizza => FractionPizzaVisual(task: task),
      VisualType.barChart => BarChartMiniVisual(task: task),
      VisualType.rhymeBubble => RhymeBubbleVisual(task: task),
      VisualType.syllableClap => SyllableClapVisual(task: task),
      VisualType.wordFamilyTree => WordFamilyTreeVisual(task: task),
      VisualType.sentenceBlocks => SentenceBlocksVisual(task: task),
      VisualType.wordTypeColor => WordTypeColorVisual(task: task),
      VisualType.articleCards => ArticleCardsVisual(task: task),
      _ => _SchoolbookFallbackVisual(task: task),
    };
  }
}

class _DotsVisual extends StatelessWidget {
  const _DotsVisual({required this.task, required this.solved});

  final TaskInstance task;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final numbers = _allInts(task.prompt);
    final operation = _operationFromTask(task);
    final left = _readInt(data['left']) ?? _readInt(data['start']) ?? (numbers.isNotEmpty ? numbers[0] : 0);
    final right = _readInt(data['right']) ?? _readInt(data['takeAway']) ?? (numbers.length > 1 ? numbers[1] : 0);
    final emoji = _emojiForPrompt(task.prompt);
    final answer = int.tryParse('${task.correctAnswer}') ??
        (operation == 'subtraction' ? left - right : left + right);

    if (operation == 'subtraction' && left > 10 && right > 0) {
      return SchoolbookTaskCard(
        title: 'Wegnehmen-Bild',
        subtitle: 'Erst anschauen, dann wegnehmen und zählen.',
        ribbonLabel: '−',
        helperText: 'Start: $left. Wegnehmen: $right. Ergebnis: ${task.correctAnswer}.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TwentyFrameVisual(start: left, takeAway: right),
          const SizedBox(height: 16),
          NumberLineJumpVisual(start: left, takeAway: right),
        ]),
      );
    }

    return SchoolbookTaskCard(
      title: operation == 'subtraction' ? 'Wegnehmen-Bild' : 'Mengenbild',
      subtitle: operation == 'subtraction' ? 'Streiche weg und zähle, was bleibt.' : 'Lege beide Mengen zusammen.',
      ribbonLabel: operation == 'subtraction' ? '−' : '+',
      child: emoji != null
          ? _ObjectMathVisual(
              left: left,
              right: right,
              answer: answer,
              operation: operation,
              emoji: emoji,
              solved: solved,
            )
          : QuantityDotsVisual(left: left, operator: operation == 'subtraction' ? '-' : '+', right: right),
    );
  }
}

class _ObjectMathVisual extends StatelessWidget {
  const _ObjectMathVisual({
    required this.left,
    required this.right,
    required this.answer,
    required this.operation,
    required this.emoji,
    this.solved = false,
  });

  final int left;
  final int right;
  final int answer;
  final String operation;
  final String emoji;

  /// Wenn true wird zusaetzlich der Loesungsweg gezeigt:
  /// Addition: '... = N Aepfel' mit allen N Objekten zusammen.
  /// Subtraktion: '... = N Aepfel' mit den verbleibenden Objekten.
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final mainVisual = operation == 'subtraction'
        ? _ObjectGroup(count: left, crossed: right, emoji: emoji)
        : Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _ObjectGroup(count: left, crossed: 0, emoji: emoji),
              Text('+', style: LumoTextStyles.heading1.copyWith(color: LumoColors.orange, fontWeight: FontWeight.w900)),
              _ObjectGroup(count: right, crossed: 0, emoji: emoji),
            ],
          );

    if (!solved) return mainVisual;

    // Phase 3 Vollausbau: Loesungsweg sichtbar. Nach richtiger Antwort
    // zeigt Lumo dem Kind '3 + 5 = 8 Aepfel' mit echten Objekten.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainVisual,
        const SizedBox(height: 14),
        _SolutionPath(
          operation: operation,
          left: left,
          right: right,
          answer: answer,
          emoji: emoji,
        ),
      ],
    );
  }
}

/// Lumos Loesungsweg-Karte: animiertes 'Aha-Bild' das nach einer
/// richtigen Antwort erscheint. Heinz' Phase 3 Wunsch:
/// 'nach Tap zeigt Lumo IMMER den Loesungsweg visuell'.
class _SolutionPath extends StatelessWidget {
  const _SolutionPath({
    required this.operation,
    required this.left,
    required this.right,
    required this.answer,
    required this.emoji,
  });

  final String operation;
  final int left;
  final int right;
  final int answer;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final isSubtraction = operation == 'subtraction';
    final headline = isSubtraction
        ? '$left − $right = $answer'
        : '$left + $right = $answer';
    final hint = isSubtraction
        ? 'Wenn du $right wegnimmst, bleiben $answer übrig.'
        : 'Wenn du $left und $right zusammenlegst, hast du $answer.';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: const Color(0xFF34D399), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(.18),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🦊', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('Lumos Lösungsweg',
                  style: LumoTextStyles.label.copyWith(
                      color: const Color(0xFF047857), fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Text(
              headline,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF065F46),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            // Ergebnis als visuelle Menge - die N Aepfel zusammen.
            _ObjectGroup(count: answer, crossed: 0, emoji: emoji),
            const SizedBox(height: 10),
            Text(
              hint,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF065F46),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectGroup extends StatelessWidget {
  const _ObjectGroup({required this.count, required this.crossed, required this.emoji});

  final int count;
  final int crossed;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final safeCount = count.clamp(0, 20).toInt();
    final safeCrossed = crossed.clamp(0, safeCount).toInt();
    if (safeCount == 0) {
      return Text('0', style: LumoTextStyles.heading2.copyWith(color: LumoColors.ink500));
    }
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: List.generate(safeCount, (index) {
        final isCrossed = index < safeCrossed;
        return Stack(alignment: Alignment.center, children: [
          Opacity(
            opacity: isCrossed ? .25 : 1,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: LumoColors.orange.withOpacity(.24), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: LumoColors.orange.withOpacity(.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          if (isCrossed)
            Transform.rotate(
              angle: -.68,
              child: Container(
                  width: 48,
                  height: 3.5,
                  color: LumoColors.ink700.withOpacity(.72)),
            ),
        ]);
      }),
    );
  }
}

class _TenOnesVisual extends StatelessWidget {
  const _TenOnesVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final tens = (_readInt(data['tens']) ?? 0).clamp(0, 9).toInt();
    final ones = (_readInt(data['ones']) ?? 0).clamp(0, 9).toInt();
    final target = tens * 10 + ones;
    return SchoolbookTaskCard(
      title: 'Zehner und Einer',
      subtitle: 'Stangen sind Zehner, Punkte sind Einer.',
      ribbonLabel: '$target',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(tens, (_) => Container(
                width: 18,
                height: 72,
                decoration: BoxDecoration(color: LumoColors.orange.withOpacity(.78), borderRadius: BorderRadius.circular(LumoRadius.sm)),
              )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(ones, (_) => Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: LumoColors.gold.withOpacity(.85), shape: BoxShape.circle),
              )),
        ),
      ]),
    );
  }
}

class _NumberLineVisual extends StatelessWidget {
  const _NumberLineVisual({required this.task, required this.picked, required this.solved});

  final TaskInstance task;
  final Object? picked;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final start = _readInt(data['start']);
    final takeAway = _readInt(data['takeAway']);
    if (start != null && takeAway != null && start > 0 && takeAway > 0) {
      return SchoolbookTaskCard(
        title: 'Zahlenstrahl-Sprung',
        subtitle: 'Springe Schritt für Schritt zurück.',
        ribbonLabel: '0–20',
        child: NumberLineJumpVisual(start: start, takeAway: takeAway),
      );
    }
    final numbers = task.options.map((option) => _readInt(option.payload ?? option.label)).whereType<int>().toSet().toList()..sort();
    if (numbers.length < 2) return const SizedBox.shrink();
    final answer = _readInt(task.correctAnswer);
    final pickedNumber = picked == null ? null : _readInt(picked);
    return SchoolbookTaskCard(
      title: 'Zahlenstrahl',
      subtitle: 'Suche die Zahl auf der Linie.',
      ribbonLabel: 'Linie',
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: numbers.map((number) {
        final selected = pickedNumber == number;
        final correct = solved && number == answer;
        return Container(
          width: correct || selected ? 42 : 34,
          height: correct || selected ? 42 : 34,
          decoration: BoxDecoration(
            color: correct ? const Color(0xFF22C55E) : selected ? LumoColors.orange : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: correct ? const Color(0xFF22C55E) : LumoColors.orange.withOpacity(.55), width: 2),
          ),
          child: Center(
            child: Text('$number', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: correct || selected ? Colors.white : LumoColors.ink900)),
          ),
        );
      }).toList()),
    );
  }
}

class _ShapeVisual extends StatelessWidget {
  const _ShapeVisual({required this.task, required this.picked, required this.solved});

  final TaskInstance task;
  final Object? picked;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    // Premium-Formen mit echtem CustomPainter statt nur Material-Icon.
    // Jede Form bekommt eigene Farbe + Schatten + Verlauf.
    const shapes = <String, _ShapeKind>{
      'Dreieck': _ShapeKind.triangle,
      'Kreis': _ShapeKind.circle,
      'Quadrat': _ShapeKind.square,
      'Rechteck': _ShapeKind.rectangle,
    };
    const colors = <String, Color>{
      'Dreieck': Color(0xFFFFB800),
      'Kreis': Color(0xFF60A5FA),
      'Quadrat': Color(0xFFF472B6),
      'Rechteck': Color(0xFF34D399),
    };
    return SchoolbookTaskCard(
      title: 'Formenhilfe',
      subtitle: 'Schau genau: Welche Form passt?',
      ribbonLabel: 'Form',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: shapes.entries.map((entry) {
          final selected = '$picked' == entry.key;
          final correct = solved && '${task.correctAnswer}' == entry.key;
          final shapeColor = colors[entry.key] ?? LumoColors.orange;
          return Container(
            width: 110,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: correct
                    ? const [Color(0xFFDCFCE7), Colors.white]
                    : selected
                        ? [LumoColors.orangeSurface, Colors.white]
                        : [Colors.white, shapeColor.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(LumoRadius.lg),
              border: Border.all(
                color: correct
                    ? const Color(0xFF22C55E)
                    : selected
                        ? LumoColors.orange
                        : shapeColor.withOpacity(0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: shapeColor.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: _ShapePainter(
                      kind: entry.value,
                      color: correct ? const Color(0xFF22C55E) : shapeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.key,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _ShapeKind { triangle, circle, square, rectangle }

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.kind, required this.color});
  final _ShapeKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withOpacity(0.65)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = color.withOpacity(0.85)
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case _ShapeKind.triangle:
        final path = Path()
          ..moveTo(w / 2, h * 0.10)
          ..lineTo(w * 0.90, h * 0.88)
          ..lineTo(w * 0.10, h * 0.88)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, stroke);
        break;
      case _ShapeKind.circle:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.40, paint);
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.40, stroke);
        break;
      case _ShapeKind.square:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.14, h * 0.14, w * 0.72, h * 0.72),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, stroke);
        break;
      case _ShapeKind.rectangle:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.08, h * 0.25, w * 0.84, h * 0.50),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.kind != kind || old.color != color;
}

class _SyllableVisual extends StatelessWidget {
  const _SyllableVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final word = task.visualPayload.data['word']?.toString() ?? task.parameters['word']?.toString() ?? '';
    final rawSyllables = task.visualPayload.data['syllables'];
    final syllables = rawSyllables is List ? rawSyllables.map((e) => e.toString()).toList(growable: false) : null;
    return SchoolbookTaskCard(
      title: 'Silben klatschen',
      subtitle: 'Sprich das Wort langsam und klatsche bei jeder Silbe.',
      ribbonLabel: 'Silben',
      accentColor: LumoColors.purple,
      child: SyllableChipRow(word: word.isEmpty ? 'Wort' : word, syllables: syllables, accentColor: LumoColors.purple),
    );
  }
}

class _SchoolbookFallbackVisual extends StatelessWidget {
  const _SchoolbookFallbackVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final visual = task.parameters['visual']?.toString() ?? '';
    final data = task.visualPayload.data;

    if (visual == 'number_house') {
      final target = _readInt(data['target']) ?? _readInt(task.correctAnswer) ?? 10;
      final left = _readInt(data['left']) ?? 0;
      final right = _readInt(data['right']) ?? _readInt(task.correctAnswer) ?? 0;
      return SchoolbookTaskCard(
        title: 'Rechenhaus',
        subtitle: 'Die Dachzahl ist das Ganze. Die Zimmer ergeben zusammen das Dach.',
        ribbonLabel: '$target',
        helperText: 'Schau zuerst auf das Dach. Dann suchst du die Partnerzahl zu $left.',
        child: NumberHouseVisual(target: target, rows: <List<int>>[<int>[left, right], <int>[0, target]], missingIndex: 1),
      );
    }

    if (visual == 'sound_choice') {
      final word = data['word']?.toString() ?? task.prompt.replaceFirst('St oder Sp?', '').trim();
      return SchoolbookTaskCard(
        title: 'St oder Sp?',
        subtitle: 'Sprich den Anfang langsam und höre genau hin.',
        ribbonLabel: 'Laut',
        accentColor: LumoColors.purple,
        child: SoundChoiceCard(word: word, choices: const <String>['St', 'Sp']),
      );
    }

    if (visual == 'writing_line') {
      final target = data['target']?.toString() ?? '${task.correctAnswer}';
      final word = data['word']?.toString() ?? target;
      return SchoolbookTaskCard(
        title: 'Schreib wie im Heft',
        subtitle: 'Lies genau und schreibe das passende Wort.',
        ribbonLabel: 'Wort',
        accentColor: LumoColors.purple,
        child: WritingLineBox(placeholder: word, cells: target.length.clamp(3, 10).toInt()),
      );
    }

    final numbers = _allInts(task.prompt);
    if (task.subject == LearningSubject.mathematik && numbers.length >= 2) {
      return _DotsVisual(task: task, solved: false);
    }

    final unitFromParams = task.parameters['unit']?.toString() ?? '';
    if (task.subject == LearningSubject.deutsch && unitFromParams == 'Satz bauen' && task.correctAnswer is String) {
      final words = task.correctAnswer.toString().replaceAll(RegExp(r'[.!?]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList(growable: false);
      if (words.length >= 2) {
        return SchoolbookTaskCard(
          title: 'Satz aus Wortkarten',
          subtitle: 'So sieht der richtige Satz aus. Nun finde ihn unten.',
          ribbonLabel: 'Satz',
          accentColor: LumoColors.blue,
          child: WordCardRow(words: words, accentColor: LumoColors.blue),
        );
      }
    }

    if (task.subject == LearningSubject.deutsch && (unitFromParams.startsWith('Anfangslaut') || unitFromParams.startsWith('Endlaut'))) {
      final word = task.visualPayload.data['word']?.toString() ?? task.parameters['word']?.toString() ?? task.correctAnswer.toString();
      final highlight = unitFromParams.startsWith('End') ? 'end' : 'start';
      return SchoolbookTaskCard(
        title: highlight == 'end' ? 'Endlaut hören' : 'Anfangslaut hören',
        subtitle: highlight == 'end' ? 'Sprich das Wort und höre genau auf den letzten Laut.' : 'Sprich das Wort und höre genau auf den ersten Laut.',
        ribbonLabel: 'Laut',
        accentColor: LumoColors.purple,
        child: SoundHighlightWord(word: word, highlight: highlight, color: LumoColors.purple),
      );
    }

    return const SizedBox.shrink();
  }
}

String _operationFromTask(TaskInstance task) {
  final dataOperation = task.visualPayload.data['operation']?.toString();
  if (dataOperation == 'subtraction' || dataOperation == 'addition') return dataOperation!;
  final p = task.prompt.toLowerCase();
  if (p.contains('-') || p.contains('isst') || p.contains('iszt') || p.contains('weg') || p.contains('bleiben') || p.contains('übrig') || p.contains('gibt') || p.contains('verliert')) {
    return 'subtraction';
  }
  return 'addition';
}

String? _emojiForPrompt(String prompt) {
  final p = prompt.toLowerCase();
  if (p.contains('schokolade')) return '🍫';
  if (p.contains('apfel') || p.contains('äpfel')) return '🍎';
  if (p.contains('banane')) return '🍌';
  if (p.contains('birne')) return '🍐';
  if (p.contains('keks')) return '🍪';
  if (p.contains('ball')) return '⚽';
  if (p.contains('stern')) return '⭐';
  if (p.contains('blume')) return '🌸';
  return null;
}

List<int> _allInts(String value) {
  return RegExp(r'-?\d+').allMatches(value).map((match) => int.parse(match.group(0)!)).toList(growable: false);
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  final match = RegExp(r'-?\d+').firstMatch('$value');
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}
