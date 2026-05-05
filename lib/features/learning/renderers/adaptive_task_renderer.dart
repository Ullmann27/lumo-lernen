import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../schoolbook/widgets/schoolbook_task_widgets.dart';
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

  bool get _solved => _picked != null && '$_picked' == '${widget.task.correctAnswer}';

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
            style: LumoTextStyles.label.copyWith(color: LumoColors.orange, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            task.prompt,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 18),
          _AdaptiveVisual(task: task, picked: _picked, solved: _solved),
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
        style: LumoTextStyles.label.copyWith(color: LumoColors.ink500, fontSize: 14),
      ),
      const SizedBox(height: 12),
      _OptionGrid(
        task: task,
        picked: _picked,
        wrongAnswers: _wrongAnswers,
        solved: _solved,
        onPick: _pick,
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

    if (correct) {
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
        const Text('🦊', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              wrongCount == 2 ? 'Lumo hilft jetzt Schritt für Schritt' : 'Noch ein Tipp von Lumo',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 5),
            Text(
              hint,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: LumoColors.ink700, height: 1.3),
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
              onTap: () => onPick(option),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.isPicked,
    required this.isWrongPicked,
    required this.isCorrect,
    required this.solved,
    required this.onTap,
  });

  final String label;
  final bool isPicked;
  final bool isWrongPicked;
  final bool isCorrect;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;

    if (solved && isCorrect) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      textColor = const Color(0xFF14532D);
    } else if (isWrongPicked) {
      bg = const Color(0xFFFFE4E6);
      border = const Color(0xFFF43F5E);
      textColor = const Color(0xFF881337);
    } else if (solved) {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink300;
    } else {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink900;
    }

    return GestureDetector(
      onTap: solved || isWrongPicked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LumoRadius.pill),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (solved && isCorrect)
            const Padding(
              padding: EdgeInsets.only(right: 7),
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
            ),
          if (isWrongPicked)
            const Padding(
              padding: EdgeInsets.only(right: 7),
              child: Icon(Icons.cancel_rounded, color: Color(0xFFF43F5E), size: 20),
            ),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
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
      VisualType.dots => _DotsVisual(task: task),
      VisualType.tenOnes => _TenOnesVisual(task: task),
      VisualType.numberLine => _NumberLineVisual(task: task, picked: picked, solved: solved),
      VisualType.shape => _ShapeVisual(task: task, picked: picked, solved: solved),
      VisualType.syllables => _SyllableVisual(task: task),
      _ => _SchoolbookFallbackVisual(task: task),
    };
  }
}

class _DotsVisual extends StatelessWidget {
  const _DotsVisual({required this.task});

  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final numbers = _allInts(task.prompt);
    final operation = _operationFromTask(task);
    final left = _readInt(data['left']) ?? _readInt(data['start']) ?? (numbers.isNotEmpty ? numbers[0] : 0);
    final right = _readInt(data['right']) ?? _readInt(data['takeAway']) ?? (numbers.length > 1 ? numbers[1] : 0);
    final emoji = _emojiForPrompt(task.prompt);

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
          ? _ObjectMathVisual(left: left, right: right, operation: operation, emoji: emoji)
          : QuantityDotsVisual(left: left, operator: operation == 'subtraction' ? '-' : '+', right: right),
    );
  }
}

class _ObjectMathVisual extends StatelessWidget {
  const _ObjectMathVisual({required this.left, required this.right, required this.operation, required this.emoji});

  final int left;
  final int right;
  final String operation;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    if (operation == 'subtraction') {
      return _ObjectGroup(count: left, crossed: right, emoji: emoji);
    }
    return Wrap(
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
      spacing: 6,
      runSpacing: 6,
      children: List.generate(safeCount, (index) {
        final isCrossed = index < safeCrossed;
        return Stack(alignment: Alignment.center, children: [
          Opacity(
            opacity: isCrossed ? .25 : 1,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.86),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LumoColors.orange.withOpacity(.18)),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          if (isCrossed)
            Transform.rotate(
              angle: -.68,
              child: Container(width: 38, height: 3, color: LumoColors.ink700.withOpacity(.72)),
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
    const shapes = <String, IconData>{
      'Dreieck': Icons.change_history_rounded,
      'Kreis': Icons.radio_button_unchecked_rounded,
      'Quadrat': Icons.crop_square_rounded,
      'Rechteck': Icons.rectangle_outlined,
    };
    return SchoolbookTaskCard(
      title: 'Formenhilfe',
      subtitle: 'Schau genau: Welche Form passt?',
      ribbonLabel: 'Form',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: shapes.entries.map((entry) {
          final selected = '$picked' == entry.key;
          final correct = solved && '${task.correctAnswer}' == entry.key;
          return Container(
            width: 104,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: correct ? const Color(0xFFDCFCE7) : selected ? LumoColors.orangeSurface : Colors.white,
              borderRadius: BorderRadius.circular(LumoRadius.lg),
              border: Border.all(color: correct ? const Color(0xFF22C55E) : selected ? LumoColors.orange : LumoColors.ink100, width: 2),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(entry.value, size: 34, color: correct ? const Color(0xFF22C55E) : LumoColors.orange),
              const SizedBox(height: 6),
              Text(entry.key, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.ink700)),
            ]),
          );
        }).toList(),
      ),
    );
  }
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
      return _DotsVisual(task: task);
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
