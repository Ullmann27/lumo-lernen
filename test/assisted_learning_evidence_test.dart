import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/weakness_detection_engine.dart';
import 'package:lumo_lernen/domain/learning/adaptive_learning_engine.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/learning/reward_engine.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_learning_tree_card.dart';

const _skill = SkillId('addition');
const _updater = SkillStateUpdater();
const _detector = WeaknessDetectionEngine();

TaskResult _answer(int id, {bool correct = true, bool helped = true}) =>
    TaskResult(
      taskInstanceId: 'distinct-$id',
      childId: 'child-a',
      skillId: _skill,
      correct: correct,
      helpUsed: helped,
      responseTimeMs: 2500,
      frustrationSignal: !correct,
      detectedErrorTypes: correct ? const [] : [ErrorType.countingError],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('three illustrated answers remain practice without assessed mastery',
      () {
    var state = const SkillState(
        childId: 'child-a', skillId: _skill, masteryScore: .20);
    for (var index = 0; index < 3; index++) {
      state = _updater.applyResult(before: state, result: _answer(index));
      expect(state.masteryScore, .20);
      expect(state.currentDifficulty, 1);
      expect(state.consecutiveCorrect, 0);
    }
    expect(state.attempts, 3);
    expect(state.correct, 3);
    expect(state.helpCount, 3);
  });

  test('guided errors do not become a weakness or frustration diagnosis', () {
    var state = const SkillState(
        childId: 'child-a',
        skillId: _skill,
        masteryScore: .65,
        currentDifficulty: 3);
    for (var index = 0; index < 3; index++) {
      state = _updater.applyResult(
          before: state, result: _answer(index, correct: false));
    }
    expect(state.wrong, 3);
    expect(state.helpCount, 3);
    expect(state.masteryScore, .65);
    expect(state.currentDifficulty, 3);
    expect(state.consecutiveWrong, 0);
    expect(state.frustrationSignals, 0);
    expect(state.recentErrorTypes, isEmpty);
  });

  test('assisted counts cannot re-enter mastery on the next assessed answer',
      () {
    var state = const SkillState(
        childId: 'child-a', skillId: _skill, masteryScore: .20);
    for (var index = 0; index < 3; index++) {
      state = _updater.applyResult(before: state, result: _answer(index));
    }
    state = _updater.applyResult(
        before: state, result: _answer(4, correct: false, helped: false));
    expect(state.masteryScore, lessThanOrEqualTo(.20));
    expect(state.consecutiveCorrect, 0);
    expect(state.consecutiveWrong, 1);
    expect(state.currentDifficulty, 1);
  });

  test('genuine unaided transfer can subsequently raise difficulty', () {
    var state = const SkillState(
        childId: 'child-a', skillId: _skill, masteryScore: .20);
    for (var index = 0; index < 3; index++) {
      state = _updater.applyResult(before: state, result: _answer(index));
    }
    for (var index = 3; index < 6; index++) {
      state = _updater.applyResult(
          before: state, result: _answer(index, helped: false));
      expect(state.consecutiveCorrect, index - 2);
    }
    expect(state.masteryScore, greaterThan(.20));
    expect(state.currentDifficulty, 2);
    expect(state.attempts, 6);
    expect(state.helpCount, 3);
  });

  test('a completed guided answer keeps practice rewards without mastery bonus',
      () {
    const before =
        SkillState(childId: 'child-a', skillId: _skill, masteryScore: .20);
    final result = _answer(0);
    final after = _updater.applyResult(before: before, result: result);
    final reward = const RewardEngine().calculateAnswerReward(
        result: result,
        before: before,
        after: after,
        allowRetry: true,
        firstAttempt: true);
    expect(reward.reasons, contains(RewardReason.usedHelpAndFinished));
    expect(reward.reasons, isNot(contains(RewardReason.improvedMastery)));
  });

  test('difficulty window is unchanged by accompanied practice', () {
    var state = const SkillState(
        childId: 'child-a',
        skillId: _skill,
        masteryScore: .8,
        attempts: 3,
        correct: 3,
        consecutiveCorrect: 3,
        currentDifficulty: 2);
    const engine = DifficultyEngine();
    final target =
        engine.windowFor(skill: state, mode: LearningMode.practice).target;
    for (var index = 0; index < 3; index++) {
      state = _updater.applyResult(
          before: state, result: _answer(index, correct: index != 1));
      expect(engine.windowFor(skill: state, mode: LearningMode.practice).target,
          target);
    }
    expect(
        engine
            .windowFor(
                skill: const SkillState(
                    childId: 'child-a',
                    skillId: _skill,
                    masteryScore: .8,
                    attempts: 3,
                    correct: 3,
                    helpCount: 1,
                    consecutiveCorrect: 3,
                    currentDifficulty: 2),
                mode: LearningMode.practice)
            .target,
        2,
        reason: 'Mixed legacy practice cannot prove an independent streak.');
  });

  test('requesting help neither erases nor inflates existing independent proof',
      () {
    var state = const SkillState(
        childId: 'child-a',
        skillId: _skill,
        attempts: 2,
        correct: 2,
        masteryScore: .8,
        consecutiveCorrect: 2,
        handwritingScore: .6,
        repetitionNeed: .3);
    final evidence = state.assessed.toJson();
    for (var index = 0; index < 3; index++) {
      state = _updater.applyResult(
          before: state, result: _answer(index, correct: index != 1));
    }
    expect(state.assessed.toJson(), evidence);
    expect(state.masteryScore, .8);
    expect(state.repetitionNeed, .3);
    expect(state.handwritingScore, .6);
    expect(state.consecutiveCorrect, 2);
    expect(
        state.copyWith(lastSeenAt: DateTime(2026)).assessed.toJson(), evidence);
  });

  test('profile reload preserves practice without inventing assessment',
      () async {
    final repository = ProgressRepository(studentId: 'evidence-a');
    final engine = LearningProfileEngine(repository: repository);
    for (var index = 0; index < 3; index++) {
      await engine.recordAnswer(
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          isCorrect: true,
          hintUsed: true);
    }
    final restored = LearningProfileEngine(repository: repository);
    await restored.load();
    final record = restored.skills['mathematik::plus bis 20']!;
    expect(record.correct, 3);
    expect(record.hintCount, 3);
    expect(record.mastery, 0);
    expect(record.difficulty, 1);
    expect(_detector.isMastered(record), isFalse);
    expect(_detector.isWeak(record), isFalse);
    expect(LumoTreeProgress.isMastered(record), isFalse);
    expect(LumoTreeProgress.needsReview(record), isFalse);
    expect(restored.dailyDone(), 3,
        reason: 'Practice still counts as activity.');
    for (var index = 0; index < 5; index++) {
      await restored.recordAnswer(
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          isCorrect: true,
          hintUsed: false);
    }
    final transfer = (await repository.loadSkills()).values.single;
    expect(transfer.correct, 8);
    expect(transfer.hintCount, 3);
    expect(transfer.difficulty, 2);
    expect(_detector.isMastered(transfer), isTrue);
  });

  test('guided profile errors do not trigger a diagnosis after JSON restore',
      () async {
    final repository = ProgressRepository(studentId: 'evidence-errors');
    final engine = LearningProfileEngine(repository: repository);
    for (var index = 0; index < 3; index++) {
      await engine.recordAnswer(
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          isCorrect: false,
          hintUsed: true);
    }
    final record = (await repository.loadSkills()).values.single;
    expect(record.wrong, 3);
    expect(record.hintCount, 3);
    expect(record.weaknessScore, 0);
    expect(_detector.isWeak(record), isFalse);
    expect(LumoTreeProgress.needsReview(record), isFalse);
  });

  test('legacy mixed JSON keeps all history without claiming an attribution',
      () async {
    final legacy = <String, Object>{
      'skillId': 'mathematik::plus bis 20',
      'subject': 'Mathematik',
      'unit': 'Plus bis 20',
      'correct': 8,
      'wrong': 3,
      'hintCount': 4,
      'currentStreak': 5,
      'currentMisses': 3,
      'difficulty': 3,
      'lastSeen': '2026-11-10T12:00:00.000',
    };
    final key =
        LearningDataNamespace.keyFor('lumo_progress_skills', 'legacy-a');
    final untouched =
        LearningDataNamespace.keyFor('lumo_progress_skills', 'legacy-b');
    final bytes = jsonEncode({'mathematik::plus bis 20': legacy});
    SharedPreferences.setMockInitialValues({key: bytes, untouched: bytes});
    final repository = ProgressRepository(studentId: 'legacy-a');
    final record = (await repository.loadSkills()).values.single;
    final roundtrip = record.toJson();
    for (final entry in legacy.entries) {
      expect(roundtrip[entry.key], entry.value);
    }
    expect(record.mastery, 0);
    expect(_detector.isMastered(record), isFalse);
    expect(_detector.isWeak(record), isFalse);
    expect(LumoTreeProgress.isMastered(record), isFalse);
    expect(LumoTreeProgress.needsReview(record), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(untouched), bytes);
    final again = (await repository.loadSkills()).values.single;
    expect(again.toJson(), roundtrip);
  });

  test('legacy explicitly unaided history remains assessed after JSON restore',
      () {
    final raw = SkillRecord(
            skillId: 'math',
            subject: 'Mathematik',
            unit: 'Plus',
            correct: 8,
            wrong: 1,
            currentStreak: 5)
        .toJson()
      ..remove('independentEvidence');
    final restored = SkillRecord.fromJson(jsonDecode(jsonEncode(raw)));
    expect(restored.assessed.correct, 8);
    expect(restored.assessed.wrong, 1);
    expect(restored.assessed.correctStreak, 5);
    expect(_detector.isMastered(restored), isTrue);
    raw.remove('hintCount');
    final unattributed = SkillRecord.fromJson(raw);
    expect(unattributed.correct, 8);
    expect(unattributed.assessed.attempts, 0,
        reason:
            'A missing hint field is not proof that assistance was absent.');
  });

  for (final invalidEvidence in <Object?>[
    null,
    {
      'version': 2,
      'correct': 3,
      'wrong': 0,
      'correctStreak': 3,
      'wrongStreak': 0
    },
    {'version': 1, 'correct': 3},
    {
      'version': 1,
      'correct': 3.5,
      'wrong': 0,
      'correctStreak': 3,
      'wrongStreak': 0
    },
    {
      'version': 1,
      'correct': 30,
      'wrong': 0,
      'correctStreak': 3,
      'wrongStreak': 0
    },
    {
      'version': 1,
      'correct': 3,
      'wrong': 0,
      'correctStreak': 3,
      'wrongStreak': 1
    },
  ]) {
    test(
        'unsupported evidence is not normalized over saved bytes: $invalidEvidence',
        () async {
      final raw = SkillRecord(
              skillId: 'math', subject: 'Mathematik', unit: 'Plus', correct: 3)
          .toJson();
      raw['independentEvidence'] = invalidEvidence;
      final key = LearningDataNamespace.keyFor(
          'lumo_progress_skills', 'invalid-evidence');
      final bytes = jsonEncode({'math': raw});
      SharedPreferences.setMockInitialValues({key: bytes});
      await expectLater(
          ProgressRepository(studentId: 'invalid-evidence').loadSkills(),
          throwsFormatException);
      expect((await SharedPreferences.getInstance()).getString(key), bytes);
    });
  }
}
