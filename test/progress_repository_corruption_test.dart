import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';

Future<Object> _read(ProgressRepository repository, String field) =>
    switch (field) {
      'skills' => repository.loadSkills(),
      'daily' => repository.loadDaily(),
      'last' => repository.loadLastTopics(),
      _ => throw ArgumentError.value(field),
    };

Map<String, String> _validProfile(String owner) => {
      LearningDataNamespace.keyFor('lumo_progress_skills', owner): jsonEncode({
        'mathematik::plus bis 10': SkillRecord(
          skillId: 'mathematik::plus bis 10',
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          correct: 8,
          wrong: 2,
          lastSeen: DateTime(2026, 10, 10),
        ).toJson(),
      }),
      LearningDataNamespace.keyFor('lumo_progress_daily', owner):
          '{"2026-10-10":8}',
      LearningDataNamespace.keyFor('lumo_progress_last', owner):
          '{"Mathematik":"Plus bis 10"}',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final field in ['skills', 'daily', 'last']) {
    for (final (label, raw) in [
      ('broken JSON', '{"unfinished":'),
      ('array instead of object', '[]'),
      ('null instead of object', 'null'),
      ('number instead of object', '7'),
    ]) {
      test('$field: $label is reported without replacing either profile',
          () async {
        final key =
            LearningDataNamespace.keyFor('lumo_progress_$field', 'fixture-a');
        final initial = <String, Object>{
          ..._validProfile('fixture-a'),
          ..._validProfile('fixture-b'),
          key: raw,
        };
        SharedPreferences.setMockInitialValues(initial);
        final repository = ProgressRepository(studentId: 'fixture-a');

        Object? error;
        try {
          await _read(repository, field);
        } catch (caught) {
          error = caught;
        }

        final preferences = await SharedPreferences.getInstance();
        for (final entry in initial.entries) {
          expect(preferences.getString(entry.key), entry.value,
              reason: 'Loading corrupt fixture-a must not erase its bytes '
                  'or touch fixture-b.');
        }
        expect(error, isA<FormatException>());
      });
    }
  }

  for (final (field, raw) in [
    ('skills', '{"broken-row":false}'),
    (
      'skills',
      '{"valid":${jsonEncode(SkillRecord(
        skillId: 'mathematik::plus bis 10',
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        correct: 8,
        lastSeen: DateTime(2026, 10, 10),
      ).toJson())},"broken-row":[]}'
    ),
    ('daily', '{"2026-10-10":8,"2026-10-11":{"new-format":3}}'),
    ('last', '{"Mathematik":"Plus bis 10","Deutsch":["Silben"]}'),
  ]) {
    test('$field: mixed unsupported rows are not partially rewritten',
        () async {
      final key =
          LearningDataNamespace.keyFor('lumo_progress_$field', 'fixture-a');
      SharedPreferences.setMockInitialValues({
        ..._validProfile('fixture-a'),
        ..._validProfile('fixture-b'),
        key: raw,
      });

      Object? error;
      try {
        await _read(ProgressRepository(studentId: 'fixture-a'), field);
      } catch (caught) {
        error = caught;
      }

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(key), raw);
      for (final entry in _validProfile('fixture-b').entries) {
        expect(preferences.getString(entry.key), entry.value);
      }
      expect(error, isA<FormatException>());
    });
  }

  test('missing fields still represent a new empty profile', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = ProgressRepository(studentId: 'new-fixture');
    expect(await repository.loadSkills(), isEmpty);
    expect(await repository.loadDaily(), isEmpty);
    expect(await repository.loadLastTopics(), isEmpty);
  });
}
