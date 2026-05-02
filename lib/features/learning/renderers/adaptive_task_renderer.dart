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

  bool get _answered => _picked != null;

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
          _AdaptiveVisual(task: task, picked: _picked, answered: _answered),
        ]),
      ),
      const SizedBox(height: 18),
      Text(
        'Wähle die richtige Antwort:',
        style: LumoTextStyles.label.copyWith(color: LumoColors.ink500, fontSize: 14),
      ),
      const SizedBox(height: 12),
      _OptionGrid(
        task: task,
        picked: _picked,
        onPick: _pick,
      ),
    ]);
  }

  void _pick(AnswerOption option) {
    if (_answered) return;
    final answer = option.payload ?? option.label;
    final correct = '$answer' == '${widget.task.correctAnswer}';
    setState(() => _picked = answer);
    widget.onAnswered?.call(
      AdaptiveTaskAnswer(task: widget.task, answer: answer, correct: correct),
    );
  }

  String _subjectLabel(LearningSubject subject) {
    return switch (subject) {
      LearningSubject.deutsch => 'Deutsch',
      LearningSubject.mathematik => 'Mathematik',
      LearningSubject.sachkunde => 'Sachkunde',
    };
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.task, required this.picked, required this.onPick});

  final TaskInstance task;
  final Object? picked;
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
          final isCorrect = '$payload' == '${task.correctAnswer}';
          final answered = picked != null;
          return SizedBox(
            width: itemWidth,
            child: _AnswerButton(
              label: option.label,
              isPicked: isPicked,
              isCorrect: isCorrect,
              answered: answered,
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
    required this.isCorrect,
    required this.answered,
    required this.onTap,
  });

  final String label;
  final bool isPicked;
  final bool isCorrect;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;

    if (!answered) {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink900;
    } else if (isCorrect) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      textColor = const Color(0xFF14532D);
    } else if (isPicked) {
      bg = const Color(0xFFFFE4E6);
      border = const Color(0xFFF43F5E);
      textColor = const Color(0xFF881337);
    } else {
      bg = Colors.white;
      border = LumoColors.ink100;
      textColor = LumoColors.ink300;
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LumoRadius.pill),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (answered && isCorrect)
            const Padding(
              padding: EdgeInsets.only(right: 7),
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
            ),
          if (answered && isPicked && !isCorrect)
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
  const _AdaptiveVisual({required this.task, required this.picked, required this.answered});

  final TaskInstance task;
  final Object? picked;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    return switch (task.visualPayload.type) {
      VisualType.dots => _DotsVisual(task: task),
      VisualType.tenOnes => _TenOnesVisual(task: task),
      VisualType.numberLine => _NumberLineVisual(task: task, picked: picked, answered: answered),
      VisualType.shape => _ShapeVisual(task: task, picked: picked, answered: answered),
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
    final operation = data['operation']?.toString() ?? 'addition';
    final left = _readInt(data['left']) ?? _readInt(data['start']) ?? 0;
    final right = _readInt(data['right']) ?? _readInt(data['takeAway']) ?? 0;

    if (operation == 'subtraction' && left > 10 && right > 0) {
      return SchoolbookTaskCard(
        title: 'Rechne wie im Heft',
        subtitle: 'Erst bis zur 10, dann den Rest wegnehmen.',
        ribbonLabel: 'Minus',
        helperText: 'Lumo zeigt dir den gleichen Denkweg wie am Arbeitsblatt: Kugeln anschauen, bis zur 10 wegstreichen, dann fertig rechnen.',
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _DotGroup(count: left, fadedAfter: operation == 'subtraction' ? right : 0)),
        if (operation == 'addition') ...[
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('+', style: TextStyle(fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w900, color: LumoColors.orange)),
          ),
          Expanded(child: _DotGroup(count: right)),
        ],
      ]),
    );
  }
}

class _DotGroup extends StatelessWidget {
  const _DotGroup({required this.count, this.fadedAfter = 0});

  final int count;
  final int fadedAfter;

  @override
  Widget build(BuildContext context) {
    final safeCount = count.clamp(0, 24).toInt();
    final safeFadedAfter = fadedAfter.clamp(0, safeCount).toInt();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(safeCount, (index) {
        final faded = safeFadedAfter > 0 && index < safeFadedAfter;
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: faded ? LumoColors.ink300.withOpacity(.28) : LumoColors.orange.withOpacity(.82),
            shape: BoxShape.circle,
          ),
          child: faded
              ? Center(child: Container(width: 14, height: 2, color: LumoColors.ink500.withOpacity(.45)))
              : null,
        );
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
      subtitle: 'Wie im Stellenwert-Heft: Stangen sind Zehner, Punkte sind Einer.',
      ribbonLabel: '$target',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(tens, (_) => Container(
                width: 18,
                height: 72,
                decoration: BoxDecoration(
                  color: LumoColors.orange.withOpacity(.78),
                  borderRadius: BorderRadius.circular(LumoRadius.sm),
                ),
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
  const _NumberLineVisual({required this.task, required this.picked, required this.answered});

  final TaskInstance task;
  final Object? picked;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final start = _readInt(data['start']);
    final takeAway = _readInt(data['takeAway']);
    if (start != null && takeAway != null && start > 10 && takeAway > 0) {
      return SchoolbookTaskCard(
        title: 'Zahlenstrahl-Sprung',
        subtitle: 'Ein großer Minus-Sprung wird in zwei kleine Sprünge geteilt.',
        ribbonLabel: '0–20',
        child: NumberLineJumpVisual(start: start, takeAway: takeAway),
      );
    }

    final numbers = task.options
        .map((option) => _readInt(option.payload ?? option.label))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    final answer = _readInt(task.correctAnswer);
    if (numbers.length < 2 || answer == null) return const SizedBox.shrink();
    final pickedNumber = picked == null ? null : _readInt(picked);

    return SchoolbookTaskCard(
      title: 'Zahlenstrahl',
      subtitle: 'Suche die Zahl auf der Linie.',
      ribbonLabel: 'Linie',
      child: Stack(alignment: Alignment.center, children: [
        Container(height: 6, decoration: BoxDecoration(color: LumoColors.orange.withOpacity(.18), borderRadius: BorderRadius.circular(LumoRadius.pill))),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: numbers.map((number) {
          final selected = pickedNumber == number;
          final correct = answered && number == answer;
          return Container(
            width: selected || correct ? 42 : 34,
            height: selected || correct ? 42 : 34,
            decoration: BoxDecoration(
              color: correct ? const Color(0xFF22C55E) : selected ? LumoColors.orange : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: correct ? const Color(0xFF22C55E) : LumoColors.orange.withOpacity(.55), width: 2),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: correct || selected ? Colors.white : LumoColors.ink900),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }
}

class _ShapeVisual extends StatelessWidget {
  const _ShapeVisual({required this.task, required this.picked, required this.answered});

  final TaskInstance task;
  final Object? picked;
  final bool answered;

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
          final correct = answered && '${task.correctAnswer}' == entry.key;
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
    final syllables = rawSyllables is List
        ? rawSyllables.map((e) => e.toString()).toList(growable: false)
        : null;
    return SchoolbookTaskCard(
      title: 'Silben klatschen',
      subtitle: 'Sprich das Wort langsam und klatsche bei jeder Silbe.',
      ribbonLabel: 'Silben',
      accentColor: LumoColors.purple,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (word.isNotEmpty) ...[
          Text(
            word,
            style: LumoTextStyles.heading2.copyWith(color: LumoColors.ink900),
          ),
          const SizedBox(height: 12),
        ],
        SyllableChipRow(
          word: word.isEmpty ? 'Wort' : word,
          syllables: syllables,
          accentColor: LumoColors.purple,
        ),
      ]),
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
        child: NumberHouseVisual(
          target: target,
          rows: <List<int>>[
            <int>[left, right],
            <int>[(left + 1).clamp(0, target).toInt(), (target - left - 1).clamp(0, target).toInt()],
            <int>[0, target],
          ],
          missingIndex: 1,
        ),
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
      final icon = data['icon']?.toString();
      return SchoolbookTaskCard(
        title: icon == null ? 'Schreib wie im Heft' : 'Bild und Wort',
        subtitle: icon == null ? 'Lies genau und schreibe das passende Wort.' : 'Schau das Bild an und finde das passende Wort.',
        ribbonLabel: icon ?? 'Wort',
        accentColor: LumoColors.purple,
        child: WritingLineBox(placeholder: word, cells: target.length.clamp(3, 10).toInt()),
      );
    }

    if (visual == 'blitz_grid') {
      final rawItems = data['items'];
      final items = rawItems is List ? rawItems.map((item) => item.toString()).toList(growable: false) : <String>[task.prompt.replaceFirst('Blitzlicht:', '').replaceAll('?', '').trim()];
      return SchoolbookTaskCard(
        title: 'Blitzlicht',
        subtitle: 'Kurze Aufgaben, ruhig rechnen, dann antworten.',
        ribbonLabel: 'Tempo',
        child: BlitzlichtGrid(items: items, columns: 1),
      );
    }

    final prompt = task.prompt;
    final minus = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(prompt);
    final plus = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(prompt);
    if (minus != null) {
      final start = int.tryParse(minus.group(1) ?? '') ?? 0;
      final takeAway = int.tryParse(minus.group(2) ?? '') ?? 0;
      if (start > 10 && takeAway > 0) {
        return SchoolbookTaskCard(
          title: 'Minus über die 10',
          subtitle: 'So wie im Heft: erst bis zur 10, dann weiter.',
          ribbonLabel: '10',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TwentyFrameVisual(start: start, takeAway: takeAway),
            const SizedBox(height: 16),
            NumberLineJumpVisual(start: start, takeAway: takeAway),
          ]),
        );
      }
    }
    if (plus != null) {
      final left = int.tryParse(plus.group(1) ?? '') ?? 0;
      final right = int.tryParse(plus.group(2) ?? '') ?? 0;
      // Bei kleinen Zahlen (<= 10) zeigen wir Mengenpunkte mit Operator,
      // damit Klasse 1 die Mengen wirklich sehen kann.
      if (left > 0 && right > 0 && left <= 10 && right <= 10) {
        return SchoolbookTaskCard(
          title: 'Plus rechnen',
          subtitle: 'Zähle die Plättchen und addiere sie zusammen.',
          ribbonLabel: '+',
          child: QuantityDotsVisual(left: left, operator: '+', right: right),
        );
      }
      return SchoolbookTaskCard(
        title: 'Blitzlicht',
        subtitle: 'Kurz rechnen, ruhig bleiben.',
        ribbonLabel: '+',
        child: BlitzlichtGrid(items: <String>['$left + $right = ?', '${left + 1} + $right = ?', '$left + ${right + 1} = ?'], columns: 1),
      );
    }

    // Deutsch: Satz-Aufgaben werden in Wortkarten zerlegt
    final unitFromParams = task.parameters['unit']?.toString() ?? '';
    if (task.subject == LearningSubject.deutsch && unitFromParams == 'Satz bauen' && task.correctAnswer is String) {
      final correctSentence = task.correctAnswer.toString();
      final words = correctSentence
          .replaceAll('.', '')
          .replaceAll('?', '')
          .replaceAll('!', '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList(growable: false);
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

    // Deutsch: Anfangs- oder Endlaut-Aufgaben
    if (task.subject == LearningSubject.deutsch &&
        (unitFromParams.startsWith('Anfangslaut') || unitFromParams.startsWith('Endlaut'))) {
      final word = task.visualPayload.data['word']?.toString() ??
          task.parameters['word']?.toString() ??
          task.correctAnswer.toString();
      final highlight = unitFromParams.startsWith('End') ? 'end' : 'start';
      return SchoolbookTaskCard(
        title: highlight == 'end' ? 'Endlaut hören' : 'Anfangslaut hören',
        subtitle: highlight == 'end'
            ? 'Sprich das Wort und höre genau auf den letzten Laut.'
            : 'Sprich das Wort und höre genau auf den ersten Laut.',
        ribbonLabel: 'Laut',
        accentColor: LumoColors.purple,
        child: SoundHighlightWord(word: word, highlight: highlight, color: LumoColors.purple),
      );
    }

    return const SizedBox.shrink();
  }
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  final match = RegExp(r'-?\d+').firstMatch('$value');
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}
