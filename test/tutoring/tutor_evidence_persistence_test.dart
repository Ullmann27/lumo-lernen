import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.withData({});
  bool rejectJourney = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      rejectJourney && key.contains('journey') ? false : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const subject = 'Mathematik';
  const unit = 'Zehner und Einer';
  const observation = LearningEvidence(taskId: 'evidence-a', problemId: 'problem-84',
      correct: true, helpLevel: 3);

  test('actual assisted evidence survives restart, isolated from sibling', () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('tutor-child-a');
    await app.recordTutorEvidence(subject: subject, unit: unit, evidence: observation);
    await app.school.setActiveStudent('tutor-child-b');
    await app.loadTutorJourney();
    expect(app.learningJourney(), isEmpty);
    final restored = await ProgressRepository(studentId: 'tutor-child-a').loadJourney();
    expect(restored.records.values.single.assistedCorrect, 1);
    expect(restored.records.values.single.independentCorrect, 0);
    expect(app.state.stars, 0);
  });

  test('accepted action retains captured owner after selection changes', () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('tutor-child-a');
    final accepted = app.recordTutorEvidence(subject: subject, unit: unit, evidence: observation);
    await app.school.setActiveStudent('tutor-child-b');
    await accepted;
    expect((await ProgressRepository(studentId: 'tutor-child-a').loadJourney())
        .records.values.single.assistedCorrect, 1);
    expect((await ProgressRepository(studentId: 'tutor-child-b').loadJourney()).records, isEmpty);
  });

  test('failed write is visible; retry preserves accepted identity exactly once', () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('tutor-child-a');
    await app.loadLearningProfile();
    store.rejectJourney = true;
    await app.recordTutorEvidence(subject: subject, unit: unit, evidence: observation);
    expect(app.tutorSaveError, isNotNull);
    store.rejectJourney = false;
    await app.flushTutorEvidence();
    await app.recordTutorEvidence(subject: subject, unit: unit, evidence: observation);
    expect(app.tutorSaveError, isNull);
    final restored = await ProgressRepository(studentId: 'tutor-child-a').loadJourney();
    expect(restored.records.values.single.attempts, 1);
    expect(restored.records.values.single.assistedCorrect, 1);
    final prefs = await SharedPreferences.getInstance();
    final journal = prefs.getKeys().where((k) => k.contains('journey')).map(prefs.getString).join();
    expect(journal, isNot(contains('prompt')));
    expect(journal, isNot(contains('given')));
  });
}
