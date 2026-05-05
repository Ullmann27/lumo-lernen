import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/lumo_hint_request.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';

void main() {
  group('requestHint stabilization', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('requestHint does not record a wrong attempt', () async {
      final engine = LearningProfileEngine();
      await engine.load();

      await engine.recordHintRequested(subject: 'Mathematik', unit: 'Plus bis 20');

      final record = engine.skills['mathematik::plus bis 20']!;
      expect(record.wrong, 0);
      expect(record.correct, 0);
      expect(record.attempts, 0);
      expect(record.hintCount, 1);
      expect(engine.hintHistory, hasLength(1));
    });

    test('requestHint keeps daily progress unchanged', () async {
      final engine = LearningProfileEngine();
      await engine.load();

      await engine.recordHintRequested(subject: 'Mathematik', unit: 'Minus bis 20');

      expect(engine.dailyDone(), 0);
    });

    test('correct answer after requestHint is still rewarded as correct', () async {
      final engine = LearningProfileEngine();
      await engine.load();

      await engine.recordHintRequested(subject: 'Mathematik', unit: 'Plus bis 10');
      await engine.recordAnswer(subject: 'Mathematik', unit: 'Plus bis 10', isCorrect: true);

      final record = engine.skills['mathematik::plus bis 10']!;
      expect(record.correct, 1);
      expect(record.wrong, 0);
      expect(record.attempts, 1);
      expect(record.hintCount, 1);
      expect(engine.dailyDone(), 1);
    });

    test('LumoAppState requestHint gives supportive feedback without weak-skill penalty', () async {
      final appState = LumoAppState();
      appState.update(appState.state.copyWith(subject: 'Mathematik', unit: 'Plus bis 20'));

      await appState.requestHint(subject: 'Mathematik', unit: 'Plus bis 20');

      expect(appState.state.practiceErrors, 0);
      expect(appState.state.weakSkills, isEmpty);
      expect(appState.state.mood, LumoMood.comfort);
      expect(appState.state.lumoMessage, contains('Gute Idee'));
      expect(appState.learningProfile.skills['mathematik::plus bis 20']!.hintCount, 1);
    });
  });
}
