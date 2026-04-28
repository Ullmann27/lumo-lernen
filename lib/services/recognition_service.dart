import '../core/school_exercise_generator.dart';

class RecognitionResult {
  const RecognitionResult({
    required this.rawText,
    required this.extractedTasks,
    required this.needsParentReview,
    required this.summary,
  });

  final String rawText;
  final List<LumoTask> extractedTasks;
  final bool needsParentReview;
  final String summary;
}

class RecognitionService {
  RecognitionService({ExerciseFactory? factory}) : _factory = factory ?? ExerciseFactory();

  final ExerciseFactory _factory;

  RecognitionResult parseText(String input, {int grade = 1}) {
    final text = input.trim();
    final tasks = <LumoTask>[];
    final math = RegExp(r'(\d{1,3})\s*([+\-])\s*(\d{1,3})').allMatches(text);
    for (final match in math) {
      final a = int.parse(match.group(1)!);
      final op = match.group(2)!;
      final b = int.parse(match.group(3)!);
      final answer = op == '+' ? a + b : a - b;
      tasks.add(LumoTask(
        id: 'ocr-${DateTime.now().microsecondsSinceEpoch}-${tasks.length}',
        grade: grade,
        subject: 'Mathematik',
        unit: op == '+' ? 'Plus bis 100' : 'Minus bis 100',
        prompt: '$a $op $b = ?',
        choices: _numberChoices(answer),
        answer: '$answer',
        explanation: op == '+' ? 'Plus bedeutet: Es kommt etwas dazu.' : 'Minus bedeutet: Es geht etwas weg.',
        visual: op == '+' ? 'dots' : 'line',
      ));
    }

    if (text.toLowerCase().contains('silbe')) {
      tasks.add(_factory.next(grade: grade, subject: 'Deutsch', unit: 'Silben'));
    }
    if (text.toLowerCase().contains('reim')) {
      tasks.add(_factory.next(grade: grade, subject: 'Deutsch', unit: 'Reime'));
    }
    if (text.toLowerCase().contains('anfang')) {
      tasks.add(_factory.next(grade: grade, subject: 'Deutsch', unit: 'Anfangslaute'));
    }

    return RecognitionResult(
      rawText: text,
      extractedTasks: tasks,
      needsParentReview: tasks.isEmpty || text.length > 120,
      summary: tasks.isEmpty ? 'Ich konnte noch keine sichere Aufgabe erkennen.' : 'Ich habe ${tasks.length} Aufgabe(n) erkannt.',
    );
  }

  List<String> _numberChoices(int answer) {
    final choices = <String>{'$answer', '${answer + 1}', '${(answer - 1).clamp(0, 999)}'};
    return choices.toList()..shuffle();
  }
}
