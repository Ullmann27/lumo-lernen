import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.withData({});
  bool rejectJourney = false;
  @override
  Future<bool> setValue(String type, String key, Object value) =>
      rejectJourney && key.contains('journey')
          ? Future.value(false)
          : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LumoAppState> app() async {
    final app = LumoAppState();
    await app.school.setActiveStudent('atelier-child-a');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    addTearDown(app.dispose);
    return app;
  }

  test('accompanied observations cannot claim independent evidence', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await app();
    final progress = LearningModuleProgress(
        appState: state, subject: 'Deutsch', unit: 'Silben');
    addTearDown(progress.dispose);
    expect(
        () => progress.saveObservation(const LearningEvidence(
            taskId: 'invalid-observation', correct: true, transferCheck: true)),
        throwsArgumentError);
    expect(
        () => progress.saveAnswer(
            correct: true,
            hintUsed: true,
            learningEvidence:
                const LearningEvidence(taskId: 'invalid-hint', correct: true)),
        throwsArgumentError);
  });

  test('explicit support also marks existing school records as assisted',
      () async {
    SharedPreferences.setMockInitialValues({});
    final state = await app();
    final progress = LearningModuleProgress(
        appState: state, subject: 'Deutsch', unit: 'Silben');
    addTearDown(progress.dispose);
    expect(
        await progress.saveAnswer(
            correct: true,
            learningEvidence: const LearningEvidence(
                taskId: 'supported', correct: true, helpLevel: 2)),
        isTrue);
    final owner = await state.captureLearningProfile();
    expect(
        owner
            .profile.skills[SkillRecord.makeId('Deutsch', 'Silben')]!.hintCount,
        1);
  });

  test('guided building saves evidence without school answers or rewards',
      () async {
    SharedPreferences.setMockInitialValues({});
    final state = await app();
    final progress = LearningModuleProgress(
        appState: state, subject: 'Deutsch', unit: 'Silben');
    addTearDown(progress.dispose);
    expect(
        await progress.saveObservation(const LearningEvidence(
            taskId: 'guided-1',
            problemId: 'banana',
            correct: true,
            helpLevel: 3)),
        isTrue);
    final owner = await state.captureLearningProfile();
    expect(owner.profile.dailyDone(), 0);
    expect(owner.profile.skills, isEmpty);
    final skill =
        owner.profile.journey.records[SkillRecord.makeId('Deutsch', 'Silben')]!;
    expect(skill.assistedCorrect, 1);
    expect(skill.independentCorrect, 0);
    expect(state.state.stars, 0);
  });

  test('failed evidence write retries accepted school answer exactly once',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final state = await app();
    final progress = LearningModuleProgress(
        appState: state, subject: 'Mathematik', unit: 'Plus bis 20');
    addTearDown(progress.dispose);
    store.rejectJourney = true;
    final pending = progress.saveAnswer(
        correct: true,
        learningEvidence: const LearningEvidence(
            taskId: 'independent-1', problemId: 'bridge-7-5', correct: true));
    for (var i = 0; i < 100 && progress.error == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(progress.error, isNotNull);
    expect(progress.hasPending, isTrue);
    store.rejectJourney = false;
    progress.retry();
    expect(await pending, isTrue);
    final owner = await state.captureLearningProfile();
    expect(owner.profile.dailyDone(), 1);
    final id = SkillRecord.makeId('Mathematik', 'Plus bis 20');
    expect(owner.profile.skills[id]!.correct, 1);
    expect(owner.profile.journey.records[id]!.independentCorrect, 1);
    final reloaded = ProgressRepository(studentId: owner.studentId);
    expect((await reloaded.loadJourney()).records[id]!.attempts, 1);
  });
}
