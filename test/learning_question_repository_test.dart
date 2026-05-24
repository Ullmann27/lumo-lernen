import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_asset_paths.dart';
import 'package:lumo_lernen/features/games/lumo_cards/learning_question_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';

/// Tests fuer das LearningQuestionRepository.
///
/// Zwei Schichten:
///  1. Schema-Tests auf den 4 JSON-Files direkt (via File.readAsStringSync,
///     keine rootBundle-Abhaengigkeit). Faengt Tippfehler / kaputte Items.
///  2. Repository-Verhalten via debugSetQuestions (kein echtes Laden -
///     Repository-Logik wird isoliert getestet).
void main() {
  group('Lernfragen-Bundles (Schema)', () {
    test('alle 4 Bundle-Files existieren + sind valides JSON-Array', () {
      for (final path in LumoAssetPaths.allQuestionBundles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Bundle fehlt: $path');
        final raw = file.readAsStringSync();
        final parsed = jsonDecode(raw);
        expect(parsed, isA<List>(), reason: '$path: nicht JSON-Array');
      }
    });

    test('jede der 4 Bundle-Files enthaelt genau 50 Items', () {
      for (final path in LumoAssetPaths.allQuestionBundles) {
        final raw = File(path).readAsStringSync();
        final list = jsonDecode(raw) as List;
        expect(list.length, 50, reason: '$path sollte 50 Fragen haben');
      }
    });

    test('jedes Item hat prompt + 4 options + correctIndex 0-3', () {
      for (final path in LumoAssetPaths.allQuestionBundles) {
        final raw = File(path).readAsStringSync();
        final list = jsonDecode(raw) as List;
        for (int i = 0; i < list.length; i++) {
          final item = list[i] as Map<String, dynamic>;
          expect(item['prompt'], isA<String>(),
              reason: '$path[$i]: prompt fehlt');
          expect((item['prompt'] as String).isNotEmpty, isTrue,
              reason: '$path[$i]: prompt leer');
          expect(item['options'], isA<List>(),
              reason: '$path[$i]: options nicht List');
          final opts = item['options'] as List;
          expect(opts.length, 4,
              reason: '$path[$i]: options muss genau 4 sein');
          expect(item['correctIndex'], isA<int>(),
              reason: '$path[$i]: correctIndex nicht int');
          final ci = item['correctIndex'] as int;
          expect(ci >= 0 && ci <= 3, isTrue,
              reason: '$path[$i]: correctIndex $ci ausserhalb 0-3');
        }
      }
    });

    test('options-Eintraege sind nicht leer', () {
      for (final path in LumoAssetPaths.allQuestionBundles) {
        final list = jsonDecode(File(path).readAsStringSync()) as List;
        for (int i = 0; i < list.length; i++) {
          final opts = (list[i] as Map)['options'] as List;
          for (int j = 0; j < opts.length; j++) {
            expect(opts[j].toString().isNotEmpty, isTrue,
                reason: '$path[$i].options[$j] leer');
          }
        }
      }
    });
  });

  group('LearningQuestionRepository', () {
    setUp(() => LearningQuestionRepository.instance.debugReset());

    test('vor init() liefert random() den Fallback', () {
      final q = LearningQuestionRepository.instance.random();
      expect(q.prompt, contains('1 + 1'),
          reason: 'Fallback "Wie viel ist 1 + 1?" greift wenn nicht init');
    });

    test('isReady=false wenn keine Daten gesetzt', () {
      expect(LearningQuestionRepository.instance.isReady, isFalse);
    });

    test('debugSetQuestions setzt isReady=true + count', () {
      LearningQuestionRepository.instance.debugSetQuestions(const [
        LearningQuestion(
            prompt: 'a',
            options: ['1', '2', '3', '4'],
            correctIndex: 0),
        LearningQuestion(
            prompt: 'b',
            options: ['1', '2', '3', '4'],
            correctIndex: 1),
      ]);
      expect(LearningQuestionRepository.instance.isReady, isTrue);
      expect(LearningQuestionRepository.instance.count, 2);
    });

    test('random() picked nur aus dem gesetzten Pool', () {
      LearningQuestionRepository.instance.debugSetQuestions(const [
        LearningQuestion(
            prompt: 'alpha',
            options: ['1', '2', '3', '4'],
            correctIndex: 0),
        LearningQuestion(
            prompt: 'beta',
            options: ['1', '2', '3', '4'],
            correctIndex: 1),
      ]);
      final seen = <String>{};
      // 30 Picks - bei 2 Fragen sollten beide vorkommen.
      for (int i = 0; i < 30; i++) {
        seen.add(LearningQuestionRepository.instance.random(Random(i)).prompt);
      }
      expect(seen, contains('alpha'));
      expect(seen, contains('beta'));
      expect(seen.every((p) => p == 'alpha' || p == 'beta'), isTrue);
    });

    test('mit seeded Random ist random() deterministisch', () {
      LearningQuestionRepository.instance.debugSetQuestions(const [
        LearningQuestion(
            prompt: 'A',
            options: ['1', '2', '3', '4'],
            correctIndex: 0),
        LearningQuestion(
            prompt: 'B',
            options: ['1', '2', '3', '4'],
            correctIndex: 1),
        LearningQuestion(
            prompt: 'C',
            options: ['1', '2', '3', '4'],
            correctIndex: 2),
      ]);
      final a = LearningQuestionRepository.instance.random(Random(42));
      final b = LearningQuestionRepository.instance.random(Random(42));
      expect(a.prompt, b.prompt);
    });

    test('init() liefert Fallback wenn Pool leer geblieben ist', () {
      // Ohne echte rootBundle bleibt der Pool leer - random() faellt zurueck.
      LearningQuestionRepository.instance.debugReset();
      LearningQuestionRepository.instance.debugSetQuestions(const []);
      final q = LearningQuestionRepository.instance.random();
      expect(q.prompt, contains('1 + 1'));
    });
  });
}
