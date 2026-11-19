import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/holo_lesson_catalog.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
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
        ('Lisa hat 8 Äpfel und bekommt 5 dazu. Wie viele Äpfel hat sie jetzt?',
            '13'),
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
        final generated =
            GermanTaskTemplates.generate(grade: 2, unit: 'Tunwoerter', seed: seed);
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
        expect((payload['twin'] as Map)['sentence'], isNot(payload['sentence']));
        seen.add(payload['sentence'] as String);
      }
      expect(seen, contains('Der kleine Fuchs springt.'));
      expect(seen.length, greaterThanOrEqualTo(6));
    });

    test('Satz bauen: gemischte Wörter, eine richtige Reihenfolge', () {
      var found = 0;
      for (var seed = 0; seed < 400; seed++) {
        final generated =
            GermanTaskTemplates.generate(grade: 1, unit: 'Erste Sätze', seed: seed);
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
