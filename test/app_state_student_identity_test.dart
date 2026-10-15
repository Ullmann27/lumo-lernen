import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds a real progress read or write while the device changes students.
class _PausedProgressRepository extends ProgressRepository {
  _PausedProgressRepository({required this.pauseLoad})
      : super(studentId: 'student-a');

  final bool pauseLoad;
  final entered = Completer<void>();
  final release = Completer<void>();

  Future<void> _pause() async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
  }

  @override
  Future<Map<String, SkillRecord>> loadSkills() async {
    if (pauseLoad) await _pause();
    return super.loadSkills();
  }

  @override
  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    if (!pauseLoad) await _pause();
    await super.saveSkills(skills);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final pauseLoad in [true, false]) {
    test(
        'answer keeps its student when assignment changes during progress '
        '${pauseLoad ? 'load' : 'save'}', () async {
      final repository = _PausedProgressRepository(pauseLoad: pauseLoad);
      final app = LumoAppState(
        learningProfileFactory: (studentId) => LearningProfileEngine(
          repository: studentId == 'student-a'
              ? repository
              : ProgressRepository(studentId: studentId),
        ),
      );
      addTearDown(() {
        if (!repository.release.isCompleted) repository.release.complete();
        app.dispose();
      });
      await app.school.setActiveStudent('student-a');
      if (!pauseLoad) await app.loadLearningProfile();

      final accepted = app.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        correct: true,
        prompt: '2 + 3 = ?',
        given: '5',
        expected: '5',
        requireSaved: true,
      );
      await repository.entered.future;
      await app.school.setActiveStudent('student-b');
      repository.release.complete();
      await accepted;

      final first = await app.attemptLog.load();
      expect(first, hasLength(1));
      expect(first.single.studentId, 'student-a');
      expect(first.single.prompt, '2 + 3 = ?');
      expect(await app.attemptLog.load(studentId: 'student-b'), isEmpty);
      await app.loadLearningProfile();
      expect(app.learningSkills(), isEmpty); // Visible B has no answer yet.
      expect(app.learningDailyDone(), 0);
      final restoredA = LearningProfileEngine(
          repository: ProgressRepository(studentId: 'student-a'));
      await restoredA.load();
      expect(restoredA.skills['mathematik::plus bis 10']!.correct, 1);
      expect(restoredA.dailyDone(), 1);

      // The next answer uses the new student; no app restart is required.
      await app.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        correct: false,
        prompt: '3 + 3 = ?',
        given: '5',
        expected: '6',
        requireSaved: true,
      );
      final restored = AttemptLogRepository();
      final studentA = await restored.load(studentId: 'student-a');
      final studentB = await restored.load(studentId: 'student-b');
      expect(studentA, hasLength(1));
      expect(studentA.single.correct, isTrue);
      expect(studentB, hasLength(1));
      expect(studentB.single.correct, isFalse);
      expect(studentB.single.prompt, '3 + 3 = ?');
    });
  }

  test(
    'unassigned answers retain the existing local log attribution',
    () async {
      final app = LumoAppState();
      addTearDown(app.dispose);

      await app.recordLearningAnswer(
        subject: 'Deutsch',
        unit: 'Artikel',
        correct: true,
        requireSaved: true,
      );

      final saved = await AttemptLogRepository().load();
      expect(saved, hasLength(1));
      expect(saved.single.studentId, 'self');
    },
  );
}
