import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/photo_lesson/photo_lesson_session.dart';

const _task = LumoTask(
    id: 'photo-math-original-id',
    grade: 1,
    subject: 'Mathematik',
    unit: 'Plus bis 20',
    prompt: '8 + 5 = ?',
    choices: ['12', '13', '14'],
    answer: '13',
    explanation: 'Zwei ergänzen die Acht zur Zehn. Drei bleiben übrig: 13.',
    visual: 'ten_frame');

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.empty();
  bool reject = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      reject ? false : super.setValue(type, key, value);
}

Map<String, dynamic> _json(PhotoLessonSession value) =>
    jsonDecode(jsonEncode(value.toJson())) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round trip preserves task identifiers and actual assisted attempts',
      () {
    final start = PhotoLessonSession.start([_task]);
    final wrong = start.answer('12', correct: false);
    final helped = wrong.withHelp(2);
    final solved = helped.answer('13', correct: true);
    final decoded = PhotoLessonSession.fromJson(_json(solved));
    expect(decoded.tasks.single.id, _task.id);
    expect(decoded.completedCount, 1);
    expect(decoded.independentCount, 0);
    expect(decoded.recommendedPractice!.id, _task.id);
    expect(decoded.attempts.map((a) => a.helpLevel), [0, 2]);
    expect(decoded.needsEvidenceSync, isTrue);
    expect(() => decoded.answer('13', correct: true), throwsStateError);
  });

  test('incorrect generator data and falsified accepted scores are rejected',
      () {
    final start = PhotoLessonSession.start([_task]);
    final badTask = _json(start);
    (badTask['tasks'] as List).single['answer'] = '12';
    expect(() => PhotoLessonSession.fromJson(badTask), throwsFormatException);
    final falseScore = _json(start.answer('12', correct: true));
    expect(
        () => PhotoLessonSession.fromJson(falseScore), throwsFormatException);
    final badHelp = _json(start.answer('13', correct: true));
    (badHelp['attempts'] as List).single['helpLevel'] = 2;
    expect(() => PhotoLessonSession.fromJson(badHelp), throwsFormatException);
  });

  test('repeated completion and unknown task attempts cannot be restored', () {
    final solved =
        PhotoLessonSession.start([_task]).answer('13', correct: true);
    final duplicate = _json(solved);
    final entry = Map<String, dynamic>.from(
        (duplicate['attempts'] as List).single as Map);
    entry['id'] = '${solved.id}.a2';
    (duplicate['attempts'] as List).add(entry);
    expect(() => PhotoLessonSession.fromJson(duplicate), throwsFormatException);
    final wrongOwner = _json(solved);
    (wrongOwner['attempts'] as List).single['taskId'] = 'another-task';
    expect(
        () => PhotoLessonSession.fromJson(wrongOwner), throwsFormatException);
  });

  test('false platform writes cannot masquerade as durable checkpoints',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final repository = PhotoLessonSessionRepository(
        studentId: 'child-a', mayWrite: () => true);
    final start = PhotoLessonSession.start([_task]);
    await repository.save(start);
    final next = start.withHelp(1);
    store.reject = true;
    await expectLater(
        repository.save(next, replacing: start), throwsStateError);
    expect((await repository.load())!.revision, start.revision);
    store.reject = false;
    await repository.save(next, replacing: start);
    expect((await repository.load())!.helpLevel, 1);
  });

  test('profile namespaces and revision leases reject stale writes', () async {
    var mayWrite = true;
    final a = PhotoLessonSessionRepository(
        studentId: 'child-a', mayWrite: () => mayWrite);
    final b = PhotoLessonSessionRepository(
        studentId: 'child-b', mayWrite: () => true);
    final start = PhotoLessonSession.start([_task]);
    await a.save(start);
    expect(await b.load(), isNull);
    final next = start.withHelp(1);
    await a.save(next, replacing: start);
    await expectLater(
        a.save(start.withHelp(2), replacing: start), throwsStateError);
    mayWrite = false;
    await expectLater(
        a.save(next.withHelp(3), replacing: next), throwsStateError);
    expect((await a.load())!.helpLevel, 1);
  });

  test('damaged or newer records are retained and cannot be overwritten',
      () async {
    final key = LearningDataNamespace.keyFor(
        PhotoLessonSessionRepository.storageKey, 'child-a');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, '{"version":99}');
    final repository = PhotoLessonSessionRepository(
        studentId: 'child-a', mayWrite: () => true);
    await expectLater(repository.load(), throwsFormatException);
    await expectLater(repository.save(PhotoLessonSession.start([_task])),
        throwsFormatException);
    expect(prefs.getString(key), '{"version":99}');
  });
}
