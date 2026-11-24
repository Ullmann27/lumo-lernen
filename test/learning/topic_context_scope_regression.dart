import 'dart:io';

import '../../lib/core/lumo_brain.dart';
import '../../lib/features/teacher_mode/topic_curriculum.dart';

/// Pure Dart regression: runnable without Flutter assets or network access.
/// Run: dart test/learning/topic_context_scope_regression.dart
void main() {
  var checks = 0;
  final failures = <String>[];
  void check(String name, bool value) {
    checks++;
    if (!value) failures.add(name);
  }

  final writing = TopicCurriculum.of('d4_aufsatz')!;
  final writingQuestions = writing.quickQuestions.join(' ').toLowerCase();
  check(
    'writing suggestions cover text structure',
    writingQuestions.contains('einleitung') &&
        writingQuestions.contains('schluss'),
  );
  check(
    'writing suggestions contain no fraction arithmetic',
    !RegExp('haelfte|drittel|viertel').hasMatch(writingQuestions),
  );

  final stories = TopicCurriculum.of('m4_textaufgaben')!;
  check(
    'word-problem suggestions ask about a solution path',
    stories.quickQuestions.join(' ').contains('Rechenschritt'),
  );
  check(
    'word-problem suggestions do not ask unrelated number facts',
    !stories.quickQuestions.join(' ').contains('Million'),
  );

  final million = TopicCurriculum.of('m4_million')!;
  final millionNumbers = RegExp(r'\b\d{1,3}(?:\.\d{3})+\b')
      .allMatches('${million.detailedScope} ${million.exampleTask}')
      .map((match) => int.parse(match.group(0)!.replaceAll('.', '')));
  check(
    'million examples stay inside the selected number range',
    millionNumbers.isNotEmpty && millionNumbers.every((n) => n <= 1000000),
  );

  final world = TopicCurriculum.of('s4_europa')!;
  check(
    'geography context matches the visible academy selection',
    world.title == 'Kontinente und Ozeane',
  );
  check(
    'geography context does not forbid its own selected topic',
    !world.forbidden.contains('andere Kontinente'),
  );
  check(
    'beginning reading joins sounds instead of letter names',
    !TopicCurriculum.of('d1_woerter')!.exampleTask.contains('Em-A-Em-A'),
  );

  final brain = LumoBrain.instance;
  final article = brain.ask(
    'Welcher Artikel passt zu Hund?',
    topicId: 'd2_artikel',
  );
  check(
    'article question is not answered by animal facts',
    article.imageTopicHint == null && !article.text.contains('Wau'),
  );
  final noun = brain.ask('Ist Hund ein Nomen?', topicId: 'd3_wortarten');
  check(
    'word-class question stays in German',
    noun.imageTopicHint == null && noun.text.toLowerCase().contains('nomen'),
  );
  check(
    'German topic does not execute arithmetic',
    !brain.ask('Was ist 3 plus 5?', topicId: 'd4_aufsatz').confident,
  );
  check(
    'English animal question does not return a German animal entry',
    !brain.ask('Wie heisst Hund auf Englisch?', topicId: 'en1_1').confident,
  );
  for (final question in [
    'ich weiss es nicht',
    'ich weiß es nicht',
    'sag mir die antwort',
    'aufloesung',
  ]) {
    for (final topic in <String?>['d4_aufsatz', 'm1_plus10', null]) {
      final help = brain.ask(question, topicId: topic);
      check(
        'asks for the missing question instead of inventing its answer: $question / $topic',
        help.confident &&
            help.text.contains('genaue Aufgabe') &&
            help.text.contains('Rätseltext') &&
            !help.text.contains('Loesung:'),
      );
    }
  }
  final knownRiddle = brain.ask(
    'Ich habe vier Beine aber kann nicht laufen. Ich trag dich beim Essen. Was bin ich?',
  );
  check(
    'an explicitly supplied known riddle still has its correct solution',
    knownRiddle.confident && knownRiddle.text.contains('Stuhl'),
  );
  check(
    'animal facts still work in the animal topic',
    brain.ask('Wie macht eine Kuh?', topicId: 's1_tiere').confident,
  );
  check(
    'ordinary arithmetic remains available in its topic',
    brain.ask('Was ist 3 plus 5?', topicId: 'm1_plus10').text.contains('8'),
  );
  check(
    'an answer request with its calculation does not ask for it again',
    brain
        .ask('Sag mir die Antwort auf 3 plus 5', topicId: 'm1_plus10')
        .text
        .contains('8'),
  );
  check(
    'general unscoped animal conversation stays available',
    brain.ask('Wie macht eine Kuh?').confident,
  );
  for (var i = 0; i < 30; i++) {
    final question = brain
        .ask('Mach mir eine Aufgabe', topicId: 's4_europa')
        .text;
    final answer = brain.ask(
      question.replaceFirst('Geografie: ', ''),
      topicId: 's4_europa',
    );
    check(
      'geography task $i stays in scope and has an actual offline answer',
      RegExp('Kontinent|Ozean|Atlantik|Pazifik').hasMatch(question) &&
          answer.confident &&
          answer.text.isNotEmpty,
    );
  }
  for (final question in world.quickQuestions) {
    check(
      'geography quick question has an offline answer: $question',
      brain.ask(question, topicId: 's4_europa').confident,
    );
  }
  check(
    'Austria is actually assigned to Europe',
    brain
        .ask('Auf welchem Kontinent liegt Österreich?', topicId: 's4_europa')
        .text
        .contains('Europa'),
  );
  check(
    'continent topic does not re-enable unrelated capital facts',
    !brain
        .ask('Was ist die Hauptstadt von Italien?', topicId: 's4_europa')
        .confident,
  );
  if (failures.isNotEmpty) {
    stderr.writeln(
      '${failures.length}/$checks failed:\n${failures.join('\n')}',
    );
    exitCode = 1;
  } else {
    stdout.writeln('PASS: $checks topic and offline-response checks.');
  }
}
