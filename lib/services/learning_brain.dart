import 'package:flutter/foundation.dart';
import 'exercise_factory.dart';

class LearningBrain extends ChangeNotifier {
  int _wrongAttempts = 0;
  final List<String> _wrongTopics = [];

  int get wrongAttempts => _wrongAttempts;
  List<String> get wrongTopics => List.unmodifiable(_wrongTopics);

  bool checkAnswer(Exercise exercise, String answer) {
    final correct = answer == exercise.correctAnswer;
    if (!correct) {
      _wrongAttempts++;
      if (!_wrongTopics.contains(exercise.subject)) {
        _wrongTopics.add(exercise.subject);
      }
      notifyListeners();
    }
    return correct;
  }

  void resetWrongAttempts() {
    _wrongAttempts = 0;
    notifyListeners();
  }

  Exercise createFollowUpTask(Exercise original) {
    return Exercise(
      subject: original.subject,
      question: 'Erinnerung: ${original.question} (Übungsaufgabe)',
      options: original.options,
      correctAnswer: original.correctAnswer,
      explanation: original.explanation,
    );
  }
}
