// Run with the Dart VM's default (assertions disabled), outside flutter test.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:lumo_lernen/core/choice_question_quality.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';
import 'package:lumo_lernen/domain/quiz/quiz_show.dart';

void main() {
  var assertionsEnabled = false;
  assert(assertionsEnabled = true);
  if (assertionsEnabled) throw StateError('Run this probe without assertions');
  var cards = 0;
  for (final file in Directory('assets/learning_questions')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))) {
    for (final value in jsonDecode(file.readAsStringSync()) as List) {
      final item = value as Map<String, dynamic>;
      final options = (item['options'] as List).cast<String>();
      final index = item['correctIndex'] as int;
      final issues = ChoiceQuestionQuality.problems(
          prompt: item['prompt'] as String,
          options: options,
          correctIndex: index,
          minOptions: 4);
      if (issues.isNotEmpty) throw StateError('${item['prompt']}: $issues');
      if (ChoiceQuestionQuality.problems(
              prompt: item['prompt'] as String,
              options: options,
              correctIndex: (index + 1) % 4)
          .isEmpty) {
        throw StateError('Wrong card answer passed without assertions');
      }
      cards++;
    }
  }
  final questions = <String, QuizQuestion>{};
  for (var grade = 1; grade <= 4; grade++) {
    for (var seed = 0; seed < 64; seed++) {
      final round = const QuizQuestionBank()
          .generateGameQuestions(grade: grade, random: Random(seed));
      if (round.length != 20) throw StateError('Incomplete release round');
      for (final question in round) {
        questions[question.id] = question;
      }
    }
  }
  for (final question in questions.values) {
    final wrong = QuizQuestion(
        id: question.id,
        prompt: question.prompt,
        options: question.options,
        correctIndex: (question.correctIndex + 1) % 4,
        difficulty: question.difficulty,
        subject: question.subject);
    if (QuizQuestionBank.acceptsQuestion(wrong)) {
      throw StateError('Wrong quiz answer passed without assertions');
    }
  }
  if (cards != 200 || questions.length != 108) {
    throw StateError(
        'Question inventory changed: $cards / ${questions.length}');
  }
  stdout.writeln('PASS assertions=false; $cards card entries; '
      '${questions.length} quiz identities; wrong-answer mutations blocked.');
}
