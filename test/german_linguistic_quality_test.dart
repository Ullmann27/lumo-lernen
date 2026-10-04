import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';

GermanTaskTemplate template(String id) =>
    GermanTaskTemplates.templates.singleWhere((item) => item.id == id);

void main() {
  setUp(PrimarySchoolWordData.resetSessionVariety);

  test('all current-grade families are reachable through the real selector',
      () {
    for (var grade = 1; grade <= 4; grade++) {
      final selected = <String>{};
      for (var seed = 0; seed < 256; seed++) {
        final task = GermanTaskTemplates.generate(
            grade: grade, unit: 'Alle', seed: seed);
        if (task.difficulty == grade) selected.add(task.promptPattern);
        expect(task.difficulty, lessThanOrEqualTo(grade));
      }
      expect(
          selected,
          containsAll(GermanTaskTemplates.templatesForGradeStrict(grade)
              .map((item) => item.promptPattern)),
          reason: 'Klasse $grade');
    }
  });

  test('focused word-class units never ask a different word class', () {
    for (final entry in <String, String>{
      'Namenwoerter': 'Namenwort',
      'Tunwoerter': 'Tunwort',
      'Wiewoerter': 'Wiewort'
    }.entries) {
      for (var seed = 0; seed < 48; seed++) {
        final task =
            GermanTaskTemplates.generate(grade: 2, unit: entry.key, seed: seed);
        expect(task.prompt, 'Welches Wort ist ein ${entry.value}?');
        final type = PrimarySchoolWordData.dictionary[task.answer]!.wordType;
        expect(
            type,
            switch (entry.key) {
              'Namenwoerter' => WordType.noun,
              'Tunwoerter' => WordType.verb,
              _ => WordType.adjective
            });
      }
    }
  });

  test('sound data handles multiple letters, silent h and final devoicing', () {
    const initial = <String, String>{
      'Schule': 'Sch',
      'Stift': 'Sch',
      'Vogel': 'F',
      'Auto': 'Au'
    };
    const ending = <String, String>{
      'Hund': 'T',
      'Rad': 'T',
      'Pferd': 'T',
      'Buch': 'Ch',
      'Tisch': 'Sch',
      'Schuh': 'U'
    };
    initial.forEach((word, sound) => expect(
        PrimarySchoolWordData.initialSoundFor(word), sound,
        reason: word));
    ending.forEach((word, sound) =>
        expect(PrimarySchoolWordData.finalSoundFor(word), sound, reason: word));
    expect(PrimarySchoolWordData.finalSoundFor('unbekannt'), isNull);
    for (var seed = 0; seed < 100; seed++) {
      for (final id in <String>['g1_start_sound', 'g1_end_sound']) {
        final task = template(id).concretize(seed);
        final word = RegExp(r'(?:beginnt|endet) (.+)\?')
            .firstMatch(task.prompt)!
            .group(1)!;
        final expected = id == 'g1_start_sound'
            ? PrimarySchoolWordData.initialSoundFor(word)
            : PrimarySchoolWordData.finalSoundFor(word);
        expect(task.answer, expected);
      }
    }
  });

  test(
      'syllable answers use spoken syllables instead of three-character chunks',
      () {
    const expected = <String, List<String>>{
      'Schnee': <String>['Schnee'],
      'Freund': <String>['Freund'],
      'Auge': <String>['Au', 'ge'],
      'Igel': <String>['I', 'gel'],
      'Ameise': <String>['A', 'mei', 'se'],
      'Karotte': <String>['Ka', 'rot', 'te'],
      'Schmetterling': <String>['Schmet', 'ter', 'ling'],
    };
    expected.forEach((word, syllables) =>
        expect(PrimarySchoolWordData.syllablesFor(word), syllables));
    final counts = <String>{};
    for (var seed = 0; seed < 100; seed++) {
      final task = template('g1_syllables').concretize(seed);
      counts.add(task.answer);
      expect(
          task.choices.every((choice) => int.tryParse(choice) != null), isTrue);
      expect(task.choices.toSet().length, task.choices.length);
    }
    expect(counts, containsAll(<String>['1', '2', '3']));
  });

  test('false rhyme pairs and additional correct rhyme options are absent', () {
    for (final pair in <List<String>>[
      <String>['Mond', 'Hund'],
      <String>['Mann', 'Kran'],
      <String>['Höhle', 'Mühle'],
      <String>['Raupe', 'Lupe'],
      <String>['Karte', 'Torte'],
      <String>['Blume', 'Pflaume'],
      <String>['Kugel', 'Nudel'],
      <String>['Löffel', 'Würfel'],
    ]) {
      expect(PrimarySchoolWordData.rhymePartnersFor(pair.first),
          isNot(contains(pair.last.toLowerCase())));
    }
    for (var seed = 0; seed < 200; seed++) {
      final task = template('g1_rhyme').concretize(seed);
      final word = RegExp(r'auf (.+)\?').firstMatch(task.prompt)!.group(1)!;
      final partners = PrimarySchoolWordData.rhymePartnersFor(word);
      expect(
          task.choices
              .where((choice) => partners.contains(choice.toLowerCase()))
              .toList(),
          <String>[task.answer]);
    }
  });

  test('picture questions always contain an actual matching picture', () {
    const images = <String, String>{
      'Hund': '🐶',
      'Katze': '🐱',
      'Maus': '🐭',
      'Hase': '🐰',
      'Fuchs': '🦊',
      'Kuh': '🐮',
      'Schwein': '🐷',
      'Biene': '🐝',
      'Apfel': '🍎',
      'Banane': '🍌',
      'Birne': '🍐',
      'Karotte': '🥕',
      'Baum': '🌳',
      'Auto': '🚗',
      'Bus': '🚌',
      'Buch': '📘',
      'Ball': '⚽',
      'Sonne': '☀️',
      'Mond': '🌙',
      'Haus': '🏠',
    };
    for (var seed = 0; seed < 80; seed++) {
      final task = template('g1_word_image').concretize(seed);
      expect(images.containsKey(task.answer), isTrue);
      expect(task.prompt, contains(images[task.answer]!));
      expect(task.prompt, isNot(contains('🖼️')));
    }
  });

  test('capitalization exercises have exactly one uncapitalized noun', () {
    for (var seed = 0; seed < 6; seed++) {
      final task = template('g3_capitalization').concretize(seed);
      final sentence = RegExp('„(.+)“').firstMatch(task.prompt)!.group(1)!;
      final errors = RegExp(r'[A-Za-zÄÖÜäöüß]+')
          .allMatches(sentence)
          .map((m) => m.group(0)!)
          .where((word) =>
              word == word.toLowerCase() &&
              const <String>{
                'kinder',
                'garten',
                'bruder',
                'buch',
                'schule',
                'papa',
                'suppe',
                'hund',
                'katze',
                'baum'
              }.contains(word))
          .toList();
      expect(errors, <String>[task.answer.toLowerCase()]);
      expect(sentence[0], sentence[0].toUpperCase());
    }
  });

  test(
      'adverb questions offer one time/place adverb and no adverbial adjectives',
      () {
    const adverbs = <String>{
      'heute',
      'draußen',
      'morgen',
      'dort',
      'oft',
      'hier'
    };
    final answers = <String>{};
    for (var seed = 0; seed < 6; seed++) {
      final task = template('g4_adverbs').concretize(seed);
      final candidates = task.choices
          .where((word) => adverbs.contains(word.toLowerCase()))
          .toList();
      expect(candidates, <String>[task.answer]);
      expect(task.prompt, contains(task.answer));
      answers.add(task.answer.toLowerCase());
    }
    expect(answers, adverbs);
  });

  test('grammar questions name the tense/person and cover all four cases', () {
    for (var seed = 0; seed < 20; seed++) {
      expect(
          template('g3_tense').concretize(seed).prompt, contains('Präteritum'));
      expect(template('g3_verb_form').concretize(seed).prompt,
          isNot(startsWith('Sie ')));
      expect(template('g3_ie_or_i').concretize(seed).choices,
          isNot(contains('fiel')));
      expect(template('g3_ie_or_i').concretize(seed).choices,
          isNot(contains('Sieh')));
    }
    final cases = <String>{
      for (var seed = 0; seed < 8; seed++)
        template('g4_four_cases').concretize(seed).answer
    };
    expect(cases, <String>{
      'Wer-Fall (1.)',
      'Wessen-Fall (2.)',
      'Wem-Fall (3.)',
      'Wen-Fall (4.)'
    });
  });

  test('adapter preserves valid German content, choices and scoring answer',
      () {
    const adapter = LegacyLumoTaskAdapter();
    final factory = ExerciseFactory(seed: 67);
    for (final unit in <String>[
      'Reime',
      'Silben',
      'Anfangslaute',
      'Endlaute',
      'Artikel',
      'Tunwoerter',
      'Wiewoerter',
      'Wort-Bild-Zuordnung'
    ]) {
      for (var i = 0; i < 10; i++) {
        final task = factory.next(grade: 2, subject: 'Deutsch', unit: unit);
        expect(identical(adapter.qualityCheckedTask(task), task), isTrue,
            reason: '${task.prompt} -> ${task.answer}');
        final rendered = adapter.toTaskInstance(
            task: task, childId: 'test', difficulty: task.difficulty);
        expect(rendered.prompt, task.prompt);
        expect(rendered.options.map((option) => option.label), task.choices);
        expect(rendered.correctAnswer.toString(), task.answer);
      }
    }
  });
}
