import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/holo_lesson_catalog.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

void main() {
  const adapter = LegacyLumoTaskAdapter();

  LumoTask task(String subject, String unit, int grade, String prompt,
          String answer, List<String> choices) =>
      LumoTask(
        id: 'holo-$unit-$answer',
        grade: grade,
        subject: subject,
        unit: unit,
        prompt: prompt,
        answer: answer,
        choices: choices,
        explanation: 'Erklärung',
        visual: subject == 'Mathematik' ? 'story' : 'sentence',
      );

  group('Textaufgabe im Holo-Raum', () {
    test('8 + 5 im Korb öffnet den Holo-Raum mit Zwillingsaufgabe', () {
      final instance = adapter.toTaskInstance(
        task: task('Mathematik', 'Textaufgaben', 1,
            HoloLessonCatalog.korbPrompt(8, 5), '13', ['12', '13', '14', '3']),
        childId: 'synthetic',
        difficulty: 1,
      );
      final native = NativeLearningActivity.forTask(instance);
      expect(native, isNotNull);
      expect(native!.kind, 'holo_word_problem');
      final options = native.toLaunchOptions();
      expect(options['a'], 8);
      expect(options['b'], 5);
      expect(options['sourceTaskId'], instance.taskInstanceId);
      expect((options['choices'] as List).toSet(), {12, 13, 14, 3});
      final twin = options['twin'] as Map;
      final twinA = twin['a'] as int;
      final twinB = twin['b'] as int;
      expect(HoloLessonCatalog.isBridgingAddition(twinA, twinB), isTrue);
      expect(twinA + twinB, isNot(13), reason: 'andere Summe als das Original');
      expect(twin['prompt'], HoloLessonCatalog.korbPrompt(twinA, twinB));
      expect((twin['choices'] as List).contains(twinA + twinB), isTrue);
      expect(jsonEncode(options), isNotEmpty, reason: 'MethodChannel-tauglich');
    });

    test('Zwillingsaufgaben für alle Zehnerübergänge bis 20', () {
      var checked = 0;
      for (var a = 2; a <= 9; a++) {
        for (var b = 2; b <= 9; b++) {
          if (a + b <= 10) continue;
          for (var seed = 0; seed < 5; seed++) {
            final (x, y) = HoloLessonCatalog.twinNumbers(a, b, seed * 7919);
            expect(HoloLessonCatalog.isBridgingAddition(x, y), isTrue);
            expect(x + y, isNot(a + b));
            final choices = HoloLessonCatalog.mathChoices(x, y, seed);
            expect(choices.toSet().length, 4);
            expect(choices, contains(x + y));
            expect(choices.every((value) => value >= 0 && value <= 20), isTrue);
          }
          checked++;
        }
      }
      expect(checked, 36);
    });

    test('ohne Zehnerübergang oder fremde Geschichte kein Holo-Raum', () {
      for (final (prompt, answer) in [
        (HoloLessonCatalog.korbPrompt(3, 4), '7'),
        (
          'Lisa hat 8 Äpfel und bekommt 5 dazu. Wie viele Äpfel hat sie jetzt?',
          '13'
        ),
      ]) {
        final instance = adapter.toTaskInstance(
          task: task('Mathematik', 'Textaufgaben', 1, prompt, answer,
              [answer, '${int.parse(answer) + 1}', '${int.parse(answer) - 1}']),
          childId: 'synthetic',
          difficulty: 1,
        );
        expect(NativeLearningActivity.holoFor(instance), isNull);
      }
    });

    test('der Generator stellt die Korb-Aufgabe in Klasse 1 und 2', () {
      var found = 0;
      for (final grade in [1, 2]) {
        for (var seed = 0; seed < 400; seed++) {
          final generated = MathTaskTemplates.generate(
              grade: grade, unit: 'Textaufgaben', seed: seed);
          if (!generated.prompt.startsWith('Im Korb liegen')) continue;
          found++;
          final payload = HoloLessonCatalog.wordProblemPayload(
            prompt: generated.prompt,
            correctAnswer: generated.answer,
            choiceLabels: generated.choices,
            taskId: 'seed-$seed',
          );
          final numbers = RegExp(r'\d+')
              .allMatches(generated.prompt)
              .map((m) => int.parse(m[0]!))
              .toList();
          final bridging =
              HoloLessonCatalog.isBridgingAddition(numbers[0], numbers[1]);
          expect(payload != null, bridging,
              reason: '${generated.prompt} ${generated.choices}');
        }
      }
      expect(found, greaterThan(0));
    });
  });

  group('Deutsch im Holo-Raum', () {
    test('mindestens 6 weitere geprüfte Sätze, Umlaute und genau ein Tunwort',
        () {
      expect(HoloLessonCatalog.verbSentences.length, greaterThanOrEqualTo(7));
      final positions = <int>{};
      for (final item in [
        ...HoloLessonCatalog.verbSentences,
        ...HoloLessonCatalog.orderSentences,
      ]) {
        expect(item.words.length, item.types.length);
        expect(item.types.where((type) => type == 'verb').length, 1);
        expect(item.types[item.verbIndex], 'verb');
        expect(item.sentence[0], item.sentence[0].toUpperCase());
        expect(item.sentence.endsWith('.'), isTrue);
        expect(item.question.endsWith('?'), isTrue);
        // Keine Ersatzschreibungen statt echter Umlaute.
        expect(
            RegExp(r'(schlaeft|huepft|fuer|ueber|Baer|Voegel)')
                .hasMatch(item.sentence),
            isFalse,
            reason: item.sentence);
        positions.add(item.verbIndex);
      }
      expect(positions.length, greaterThanOrEqualTo(3),
          reason: 'Das Tunwort steht an verschiedenen Stellen');
      for (final item in HoloLessonCatalog.orderSentences) {
        expect(item.words.toSet().length, item.words.length,
            reason: 'Satzbau braucht eindeutige Karten');
      }
    });

    test('Tunwort im Satz: Generator, Ablenker und Holo-Daten passen', () {
      final seen = <String>{};
      for (var seed = 0; seed < 600; seed++) {
        final generated = GermanTaskTemplates.generate(
            grade: 2, unit: 'Tunwoerter', seed: seed);
        if (generated.promptPattern != 'tunwort-im-satz') continue;
        final payload = HoloLessonCatalog.sentencePayload(
            prompt: generated.prompt,
            correctAnswer: generated.answer,
            taskId: 'seed-$seed');
        expect(payload, isNotNull, reason: generated.prompt);
        final words = payload!['words'] as List;
        expect(words, contains(generated.answer));
        expect(generated.choices.every(words.contains), isTrue,
            reason: 'Ablenker kommen aus demselben Satz');
        expect(
            (payload['twin'] as Map)['sentence'], isNot(payload['sentence']));
        seen.add(payload['sentence'] as String);
      }
      expect(seen, contains('Der kleine Fuchs springt.'));
      expect(seen.length, greaterThanOrEqualTo(6));
    });

    test('Namenwort-Sätze: genau ein Namenwort, bekanntes Bild, Umlaute', () {
      expect(HoloLessonCatalog.nounSentences.length, greaterThanOrEqualTo(6));
      for (final item in HoloLessonCatalog.nounSentences) {
        expect(item.types.length, item.words.length, reason: item.sentence);
        expect(item.types.where((type) => type == 'nomen').length, 1,
            reason: item.sentence);
        expect(item.types[item.nounIndex], 'nomen', reason: item.sentence);
        expect(item.types[item.verbIndex], 'verb', reason: item.sentence);
        expect(item.nounIndex, isNot(item.verbIndex));
        expect(HoloLessonCatalog.nounPictures, contains(item.picture));
        expect(item.noun[0], item.noun[0].toUpperCase(),
            reason: 'Namenwörter sind großgeschrieben');
        expect(item.sentence.contains(RegExp('ae|oe|ue(?!r)')), isFalse,
            reason: 'echte Umlaute: ${item.sentence}');
      }
    });

    test('Namenwort im Satz: Generator, Ablenker und Holo-Daten passen', () {
      final seen = <String>{};
      for (var seed = 0; seed < 600; seed++) {
        final generated = GermanTaskTemplates.generate(
            grade: 2, unit: 'Namenwoerter', seed: seed);
        if (generated.promptPattern != 'namenwort-im-satz') continue;
        final payload = HoloLessonCatalog.sentencePayload(
            prompt: generated.prompt,
            correctAnswer: generated.answer,
            taskId: 'seed-$seed');
        expect(payload, isNotNull, reason: generated.prompt);
        expect(payload!['mode'], 'noun');
        final words = payload['words'] as List;
        expect(words[payload['nounIndex'] as int], generated.answer);
        expect(HoloLessonCatalog.nounPictures, contains(payload['picture']));
        expect(generated.choices.every(words.contains), isTrue,
            reason: 'Ablenker kommen aus demselben Satz');
        final twin = payload['twin'] as Map;
        expect(twin['sentence'], isNot(payload['sentence']));
        expect(twin['nounIndex'], isA<int>());
        expect(HoloLessonCatalog.nounPictures, contains(twin['picture']));
        seen.add(payload['sentence'] as String);
      }
      expect(seen, contains('Der kleine Fuchs springt.'));
      expect(seen.length, greaterThanOrEqualTo(6));
      // Eine falsche Lösung öffnet keinen Holo-Raum.
      expect(
          HoloLessonCatalog.sentencePayload(
              prompt: HoloLessonCatalog.nounPrompt(
                  HoloLessonCatalog.nounSentences.first),
              correctAnswer: 'springt',
              taskId: 'falsch'),
          isNull);
    });

    test('Satz bauen: gemischte Wörter, eine richtige Reihenfolge', () {
      var found = 0;
      for (var seed = 0; seed < 400; seed++) {
        final generated = GermanTaskTemplates.generate(
            grade: 1, unit: 'Erste Sätze', seed: seed);
        if (generated.promptPattern != 'satz-bauen') continue;
        found++;
        expect(generated.choices.toSet().length, generated.choices.length);
        final payload = HoloLessonCatalog.sentencePayload(
            prompt: generated.prompt,
            correctAnswer: generated.answer,
            taskId: 'seed-$seed');
        expect(payload?['mode'], 'order');
        final shown = generated.prompt.split(': ').last.split(' · ');
        expect(shown.join(' '), isNot((payload!['words'] as List).join(' ')));
      }
      expect(found, greaterThan(0));
    });
  });

  group('Silben, Wiewort und Lesen im Holo-Raum', () {
    // Feste, einzeln geprüfte Sprechsilben (Grundschul-Silbenlehre).
    const expectedSyllables = <String, String>{
      'Ball': 'Ball',
      'Hund': 'Hund',
      'Fuchs': 'Fuchs',
      'Baum': 'Baum',
      'Haus': 'Haus',
      'Sonne': 'Son-ne',
      'Apfel': 'Ap-fel',
      'Katze': 'Kat-ze',
      'Blume': 'Blu-me',
      'Hase': 'Ha-se',
      'Ente': 'En-te',
      'Vogel': 'Vo-gel',
      'Banane': 'Ba-na-ne',
      'Tomate': 'To-ma-te',
      'Telefon': 'Te-le-fon',
      'Marille': 'Ma-ril-le',
      'Schmetterling': 'Schmet-ter-ling',
      'Regenbogen': 'Re-gen-bo-gen',
      'Schokolade': 'Scho-ko-la-de',
      'Marmelade': 'Mar-me-la-de',
    };

    test(
        'Silbenwörter: feste Trennung, 1–4 Silben, kein einzelner Anfangsvokal',
        () {
      const words = HoloLessonCatalog.syllableWords;
      expect(words.length, greaterThanOrEqualTo(12));
      expect({for (final item in words) item.word: item.spelling},
          expectedSyllables);
      final counts = <int>{};
      for (final item in words) {
        counts.add(item.syllables.length);
        expect(item.syllables.length, inInclusiveRange(1, 4));
        expect(item.word[0], item.word[0].toUpperCase(), reason: item.word);
        expect(RegExp(r'^[aeiouäöüAEIOUÄÖÜ]$').hasMatch(item.syllables.first),
            isFalse,
            reason: 'kein einzelner Anfangsvokal: ${item.spelling}');
        for (final part in item.syllables) {
          expect(RegExp('[aeiouäöüy]', caseSensitive: false).hasMatch(part),
              isTrue,
              reason: 'jede Silbe hat einen Vokal: ${item.spelling}');
        }
        if (item.picture.isNotEmpty) {
          expect(HoloLessonCatalog.nounPictures, contains(item.picture));
        }
        // Wo die Wortdaten der App das Wort kennen, stimmt die Trennung überein.
        final known = PrimarySchoolWordData.syllablesFor(item.word);
        if (known != null) {
          expect(known, item.syllables, reason: item.word);
        }
      }
      expect(counts, {1, 2, 3, 4});
    });

    test('Silben: Generator, Holo-Daten und ähnliches Wort passen', () {
      final seen = <String>{};
      for (var seed = 0; seed < 400; seed++) {
        final generated =
            GermanTaskTemplates.generate(grade: 1, unit: 'Silben', seed: seed);
        final payload = HoloLessonCatalog.syllablePayload(
            prompt: generated.prompt,
            correctAnswer: generated.answer,
            taskId: 'seed-$seed');
        if (generated.promptPattern == 'silben-klatschen-holo') {
          expect(payload, isNotNull, reason: generated.prompt);
        }
        if (payload == null) continue;
        expect(payload['mode'], 'syllables');
        final syllables = payload['syllables'] as List;
        expect(generated.answer, '${syllables.length}');
        expect(generated.choices.toSet().length, generated.choices.length);
        expect(generated.choices, contains(generated.answer));
        expect(syllables.join(), payload['word']);
        expect(payload['prompt'], generated.prompt);
        final twin = payload['twin'] as Map;
        expect(twin['word'], isNot(payload['word']));
        expect((twin['syllables'] as List).length, isNot(syllables.length),
            reason: 'ähnliches Wort mit anderer Silbenzahl');
        expect(twin['prompt'], 'Wie viele Silben hat ${twin['word']}?');
        expect(jsonEncode(payload), isNotEmpty);
        seen.add(payload['word'] as String);
      }
      expect(seen.length, greaterThanOrEqualTo(12));
      expect(
          HoloLessonCatalog.syllablePayload(
              prompt: 'Wie viele Silben hat Banane?',
              correctAnswer: '2',
              taskId: 'falsch'),
          isNull,
          reason: 'falsche Lösung öffnet keinen Holo-Raum');
      expect(
          HoloLessonCatalog.syllablePayload(
              prompt: 'Wie viele Silben hat Igel?',
              correctAnswer: '2',
              taskId: 'igel'),
          isNull,
          reason: 'nur geprüfte Wörter');
    });

    test('Silben-Aufgabe öffnet über den Adapter den Holo-Raum', () {
      final instance = adapter.toTaskInstance(
        task: task('Deutsch', 'Silben', 1, 'Wie viele Silben hat Banane?', '3',
            ['3', '4', '2']),
        childId: 'synthetic',
        difficulty: 1,
      );
      final native = NativeLearningActivity.forTask(instance);
      expect(native?.kind, 'holo_sentence');
      final options = native!.toLaunchOptions();
      expect(options['mode'], 'syllables');
      expect(options['syllables'], ['Ba', 'na', 'ne']);
      expect(options['picture'], 'banane');
      expect(options['sourceTaskId'], instance.taskInstanceId);
    });

    test('Wiewort-Sätze: genau ein Wiewort, echte Ablenker, Umlaute und ß', () {
      const sentences = HoloLessonCatalog.adjectiveSentences;
      expect(sentences.length, greaterThanOrEqualTo(8));
      const genders = {'Der': 'der', 'Die': 'die', 'Das': 'das'};
      for (final item in sentences) {
        expect(item.types.length, item.words.length, reason: item.sentence);
        expect(item.types.where((type) => type == 'adjektiv').length, 1);
        expect(item.types[item.adjIndex], 'adjektiv');
        expect(item.types.where((type) => type == 'nomen').length, 1);
        expect(item.types.where((type) => type == 'verb').length, 1);
        expect(item.types[item.verbIndex], 'verb');
        final noun = item.words[item.types.indexOf('nomen')];
        final article = genders[item.words.first];
        expect(article, isNotNull, reason: 'Satz beginnt mit Begleiter');
        expect(item.question, 'Welches Wort sagt, wie $article $noun ist?');
        expect(item.adjective, startsWith(item.look),
            reason: 'gebeugtes Wiewort: ${item.sentence}');
        expect(item.contrast == 'size', {'klein', 'groß'}.contains(item.look));
        expect(HoloLessonCatalog.adjectiveLooks, contains(item.look));
        expect(HoloLessonCatalog.nounPictures, contains(item.picture));
        expect(
            RegExp(r'(weiss|grosse|gruene|blueht|waechst|faellt|huepft|schlaeft)')
                .hasMatch(item.sentence),
            isFalse,
            reason: 'echte Umlaute und ß: ${item.sentence}');
      }
      expect(sentences.map((item) => item.look).toSet().length,
          greaterThanOrEqualTo(5));
    });

    test('Wiewort im Satz: Generator, Ablenker und Holo-Daten passen', () {
      final seen = <String>{};
      for (var seed = 0; seed < 600; seed++) {
        final generated = GermanTaskTemplates.generate(
            grade: 2, unit: 'Wiewoerter', seed: seed);
        if (generated.promptPattern != 'wiewort-im-satz') continue;
        final payload = HoloLessonCatalog.sentencePayload(
            prompt: generated.prompt,
            correctAnswer: generated.answer,
            taskId: 'seed-$seed');
        expect(payload, isNotNull, reason: generated.prompt);
        expect(payload!['mode'], 'adjective');
        final words = payload['words'] as List;
        final types = payload['types'] as List;
        expect(words[payload['adjIndex'] as int], generated.answer);
        expect(generated.choices.every(words.contains), isTrue,
            reason: 'Ablenker kommen aus demselben Satz');
        for (final choice in generated.choices) {
          if (choice == generated.answer) continue;
          expect(types[words.indexOf(choice)], isNot('adjektiv'),
              reason: 'Ablenker sind echte andere Wortarten');
        }
        final twin = payload['twin'] as Map;
        expect(twin['sentence'], isNot(payload['sentence']));
        expect(twin['adjIndex'], isA<int>());
        seen.add(payload['sentence'] as String);
      }
      expect(seen, contains('Der kleine Fuchs springt.'));
      expect(seen.length, greaterThanOrEqualTo(6));
      expect(
          HoloLessonCatalog.sentencePayload(
              prompt: HoloLessonCatalog.adjectivePrompt(
                  HoloLessonCatalog.adjectiveSentences.first),
              correctAnswer: 'Fuchs',
              taskId: 'falsch'),
          isNull);
    });

    test('Lese-Sätze: ein Lagewort, Dativ, passende Szenen', () {
      const sentences = HoloLessonCatalog.readingSentences;
      expect(sentences.length, greaterThanOrEqualTo(8));
      const dative = {'tisch': 'dem', 'stuhl': 'dem', 'kiste': 'der'};
      const nouns = {'tisch': 'Tisch', 'stuhl': 'Stuhl', 'kiste': 'Kiste'};
      const things = {
        'ball': 'Ball',
        'apfel': 'Apfel',
        'katze': 'Katze',
        'hund': 'Hund'
      };
      final relationWords = HoloLessonCatalog.relationWords.values.toSet();
      for (final item in sentences) {
        expect(item.words.where(relationWords.contains).length, 1,
            reason: 'genau ein Lagewort: ${item.sentence}');
        expect(item.keyIndex, greaterThanOrEqualTo(0));
        expect(item.words[item.keyIndex + 1], dative[item.place],
            reason: 'Dativ: ${item.sentence}');
        expect(item.words.last, nouns[item.place]);
        expect(item.words[1], things[item.object]);
        expect(item.relations, contains(item.answer));
        expect(item.question,
            'Wo ${item.words[2]} ${item.words[0].toLowerCase()} ${item.words[1]}?');
      }
      final answers = sentences.map((item) => item.answer).toSet();
      expect(answers.length, greaterThanOrEqualTo(4));
    });

    test('Lesen: Generator, Szenen, Antwortlage wechselt, ähnlicher Satz', () {
      final positions = <int>{};
      final seen = <String>{};
      for (var seed = 0; seed < 600; seed++) {
        final generated = GermanTaskTemplates.generate(
            grade: 1, unit: 'Erste Sätze', seed: seed);
        if (generated.promptPattern != 'satz-lesen-bild') continue;
        final payload = HoloLessonCatalog.sentencePayload(
            prompt: generated.prompt,
            correctAnswer: generated.answer,
            taskId: 'seed-$seed');
        expect(payload, isNotNull, reason: generated.prompt);
        expect(payload!['mode'], 'reading');
        final scenes = (payload['scenes'] as List).cast<String>();
        expect(scenes.toSet().length, 3);
        expect(scenes, contains(generated.answer));
        expect(generated.choices.toSet(), scenes.toSet(),
            reason: '2D-Antworten sind dieselben Lagen');
        final words = payload['words'] as List;
        expect(words[payload['keyIndex'] as int],
            HoloLessonCatalog.relationWords[generated.answer]);
        positions.add(scenes.indexOf(generated.answer));
        final twin = payload['twin'] as Map;
        expect(twin['sentence'], isNot(payload['sentence']));
        expect(twin['answer'], isNot(payload['answer']));
        expect((twin['scenes'] as List), contains(twin['answer']));
        seen.add(payload['sentence'] as String);
      }
      expect(positions, {0, 1, 2},
          reason: 'die richtige Szene steht nicht immer an derselben Stelle');
      expect(seen.length, greaterThanOrEqualTo(8));
    });
  });

  group('Rückgabe aus dem Holo-Raum', () {
    Map<String, Object?> summary() => {
          'resultId': 'session-1-2',
          'taskId': 'legacy_1',
          'kind': 'holo_word_problem',
          'mode': 'add',
          'originalAnswer': '13',
          'originalCorrect': true,
          'originalAttempts': 3,
          'hintLevel': 2,
          'twinSolved': true,
          'twinAttempts': 2,
          'twinPrompt': HoloLessonCatalog.korbPrompt(6, 8),
        };

    test('gültige Zusammenfassung wird übernommen', () {
      final parsed = parseLearningResult(jsonEncode(summary()));
      expect(parsed?['originalAnswer'], '13');
      expect(parsed?['hintLevel'], 2);
      final wrapped = parseLearningResult(
          jsonEncode({'status': 'illustrated', 'holo': summary()}));
      expect(wrapped?['resultId'], 'session-1-2');
    });

    test('unplausible Daten werden verworfen', () {
      for (final change in <MapEntry<String, Object?>>[
        const MapEntry('hintLevel', 7),
        const MapEntry('resultId', ''),
        const MapEntry('kind', 'kart'),
        const MapEntry('originalAnswer', ''),
        const MapEntry('twinSolved', 'ja'),
      ]) {
        final broken = summary()..[change.key] = change.value;
        expect(parseLearningResult(jsonEncode(broken)), isNull,
            reason: change.key);
      }
      expect(parseLearningResult('kein json'), isNull);
      expect(parseLearningResult(null), isNull);
    });
  });
}
