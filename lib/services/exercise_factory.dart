class Exercise {
  final String subject;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  const Exercise({
    required this.subject,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class ExerciseFactory {
  static int _index = 0;

  static const List<Exercise> _exercises = [
    Exercise(
      subject: 'Mathematik',
      question: '12 + 7 = ?',
      options: ['17', '18', '19', '20'],
      correctAnswer: '19',
      explanation: 'Zähle von 12 aus 7 weiter: 13, 14, 15, 16, 17, 18, 19. Die Antwort ist 19.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '18 - 5 = ?',
      options: ['11', '12', '13', '14'],
      correctAnswer: '13',
      explanation: 'Zähle von 18 aus 5 zurück: 17, 16, 15, 14, 13. Die Antwort ist 13.',
    ),
    Exercise(
      subject: 'Zahlenreihe',
      question: '2, 4, 6, ?',
      options: ['7', '8', '9', '10'],
      correctAnswer: '8',
      explanation: 'Die Zahlen werden immer um 2 größer: 2+2=4, 4+2=6, 6+2=8.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was ist der Anfangsbuchstabe von "Mama"?',
      options: ['A', 'M', 'P', 'N'],
      correctAnswer: 'M',
      explanation: 'Das Wort "Mama" beginnt mit dem Buchstaben M.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was reimt sich auf "Haus"?',
      options: ['Baum', 'Maus', 'Ball', 'Tisch'],
      correctAnswer: 'Maus',
      explanation: 'Haus und Maus reimen sich, weil beide auf "-aus" enden.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '5 + 8 = ?',
      options: ['11', '12', '13', '14'],
      correctAnswer: '13',
      explanation: 'Zähle von 5 aus 8 weiter oder von 8 aus 5 weiter: 8+5=13.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Welches Wort fängt mit "S" an?',
      options: ['Tisch', 'Banane', 'Sonne', 'Hund'],
      correctAnswer: 'Sonne',
      explanation: '"Sonne" beginnt mit dem Buchstaben S.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '3 × 4 = ?',
      options: ['10', '11', '12', '13'],
      correctAnswer: '12',
      explanation: '3 × 4 bedeutet 4 mal die 3 addieren: 3+3+3+3 = 12.',
    ),
  ];

  static Exercise nextExercise() {
    final exercise = _exercises[_index % _exercises.length];
    _index++;
    return exercise;
  }

  static List<Exercise> get allExercises => List.unmodifiable(_exercises);
}
