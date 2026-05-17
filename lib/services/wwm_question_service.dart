import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'class_settings.dart';
import 'exercise_factory.dart';
import 'local_store.dart';
import 'quiz_question_bank.dart';
import 'quiz_show_repository.dart';

class WwmQuestion {
  final String subject;
  final String question;
  final List<String> options; // exactly 4, indices 0-3 map to A-D
  final int correctIndex;
  final String explanation;

  const WwmQuestion({
    required this.subject,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class WwmQuestionService {
  // API key supplied at build time via --dart-define=OPENAI_API_KEY=<key>
  static const _apiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _callCountKey = 'wwm_api_call_count';

  final LocalStore _store;
  final ClassSettings? _classSettings;
  final QuizShowRepository? _quizRepo;

  WwmQuestionService(this._store,
      [this._classSettings, this._quizRepo]);

  int get apiCallCount => _store.get<int>(_callCountKey) ?? 0;

  Future<List<WwmQuestion>> loadQuestions() async {
    if (_apiKey.isEmpty) return _fallbackQuestions();
    try {
      final questions = await _fetchFromOpenAI();
      _store.set(_callCountKey, apiCallCount + 1);
      return questions;
    } catch (_) {
      return _fallbackQuestions();
    }
  }

  Future<String?> getPhoneHint(WwmQuestion question) async {
    if (_apiKey.isEmpty) return null;
    try {
      final resp = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Gib einem Kind (Klasse 1-2) einen kurzen Hinweis '
                  '(1-2 Sätze) für diese Frage, ohne die Antwort direkt zu '
                  'nennen. Antworte auf Deutsch und kindgerecht.\n\n'
                  'Frage: ${question.question}',
            }
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<List<WwmQuestion>> _fetchFromOpenAI() async {
    const prompt = '''Erstelle genau 15 Multiple-Choice-Fragen auf Deutsch für österreichische Volksschulkinder (Klasse 1-2).

Schwierigkeitsverteilung:
- Fragen 1-5: Einfach (Rechnen bis 20, Buchstaben erkennen, einfache Wörter)
- Fragen 6-10: Mittel (Rechnen bis 100, einfache Grammatik, Sachkunde)
- Fragen 11-15: Schwer (Textaufgaben, Muster erkennen, allgemeines Wissen)

Antworte ausschließlich mit einem JSON-Objekt in diesem exakten Format:
{"questions":[{"subject":"Mathematik","question":"Was ist 5 + 3?","options":["6","7","8","9"],"correct":"C","explanation":"5 + 3 = 8"}]}

Regeln: Genau 4 Optionen pro Frage. "correct" gibt den Buchstaben A, B, C oder D an.''';

    final resp = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 3000,
        'temperature': 0.8,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('OpenAI error: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;

    // Handle {"questions":[...]} or any key containing a list
    List<dynamic> questionsJson;
    if (parsed.containsKey('questions') && parsed['questions'] is List) {
      questionsJson = parsed['questions'] as List<dynamic>;
    } else {
      final listValues =
          parsed.values.whereType<List<dynamic>>().toList();
      if (listValues.isEmpty) {
        throw Exception('No question list in response');
      }
      questionsJson = listValues.first;
    }

    return questionsJson
        .map((q) => _parseQuestion(q as Map<String, dynamic>))
        .toList();
  }

  WwmQuestion _parseQuestion(Map<String, dynamic> q) {
    final rawOptions = q['options'] as List? ?? [];
    final options = List<String>.from(rawOptions);
    while (options.length < 4) {
      options.add('–');
    }
    final correctLetter =
        ((q['correct'] as String?)?.toUpperCase().trim() ?? 'A');
    final correctIndex =
        (correctLetter.codeUnitAt(0) - 'A'.codeUnitAt(0)).clamp(0, 3);
    return WwmQuestion(
      subject: q['subject'] as String? ?? 'Allgemein',
      question: q['question'] as String,
      options: options.take(4).toList(),
      correctIndex: correctIndex,
      explanation: q['explanation'] as String? ?? '',
    );
  }

  List<WwmQuestion> _fallbackQuestions() {
    final cs = _classSettings;
    final repo = _quizRepo;

    // If ClassSettings and QuizShowRepository are wired in, use the
    // grade-appropriate, anti-repetition QuizQuestionBank.
    if (cs != null && repo != null) {
      final level = cs.level;
      final quizQuestions =
          QuizQuestionBank.generateGameQuestions(level, repo);
      return quizQuestions
          .map(
            (q) => WwmQuestion(
              subject: q.subject,
              question: q.question,
              options: q.options,
              correctIndex: q.correctIndex,
              explanation: q.explanation,
            ),
          )
          .toList();
    }

    // Legacy static fallback (used only when providers are unavailable).
    final rng = Random();

    final easy = List<Exercise>.from(ExerciseFactory.easyExercises)
      ..shuffle(rng);
    final medium = List<Exercise>.from(ExerciseFactory.mediumExercises)
      ..shuffle(rng);
    final hard = List<Exercise>.from(ExerciseFactory.hardExercises)
      ..shuffle(rng);

    final selected = [
      ...easy.take(5),
      ...medium.take(5),
      ...hard.take(5),
    ];

    return selected.map((exercise) {
      final indexed = exercise.options.asMap().entries.toList()..shuffle(rng);
      final shuffledOptions = indexed.map((e) => e.value).toList();
      final correctIndex =
          shuffledOptions.indexOf(exercise.correctAnswer).clamp(0, 3);
      return WwmQuestion(
        subject: exercise.subject,
        question: exercise.question,
        options: shuffledOptions,
        correctIndex: correctIndex,
        explanation: exercise.explanation,
      );
    }).toList();
  }
}
