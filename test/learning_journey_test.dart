import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _base = 'lumo_progress_journey_v1';
const _subject = 'Mathematik';
const _unit = 'Plus bis 20';
final _start = DateTime.utc(2026, 10, 18, 12);

LearningProfileEngine _engine([String child = 'a']) =>
    LearningProfileEngine(repository: ProgressRepository(studentId: child));

Future<JourneySkill> _answer(
  LearningProfileEngine engine,
  String task, {
  String? problem,
  bool correct = true,
  int help = 0,
  bool transfer = false,
  String? error,
  DateTime? now,
}) =>
    engine.recordJourneyEvidence(
      subject: _subject,
      unit: _unit,
      evidence: LearningEvidence(
        taskId: task,
        problemId: problem,
        correct: correct,
        helpLevel: help,
        transferCheck: transfer,
        errorTag: error,
      ),
      now: now ?? _start,
    );

class _RejectJourneyStore extends InMemorySharedPreferencesStore {
  _RejectJourneyStore() : super.withData({});
  bool reject = false;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (reject && key.contains(_base)) return false;
    return super.setValue(type, key, value);
  }
}

class _DelayedJourneyStore extends InMemorySharedPreferencesStore {
  _DelayedJourneyStore() : super.withData({});
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key.contains(_base) && !entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('empty journey loads without creating or changing progress fields',
      () async {
    final engine = _engine();
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    await engine.loadJourney();
    await engine.flush();
    expect(engine.isJourneyLoaded, true);
    expect(engine.journey.records, isEmpty);
    expect(engine.hasUnsavedChanges, false);
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
  });

  test('journal persists only inside the captured child namespace', () async {
    final previous = _engine();
    await previous.recordAnswer(
        subject: 'Deutsch', unit: 'Silben', isCorrect: true);
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    final a = _engine();
    await _answer(a, 'session_a:1');
    await a.flush();
    final key = LearningDataNamespace.keyFor(_base, 'a');
    expect(prefs.getKeys().difference(before.keys.toSet()), {key});
    expect({for (final key in before.keys) key: prefs.get(key)}, before);
    final b = _engine('b');
    await b.loadJourney();
    expect(b.journey.records, isEmpty);
    final restored = _engine();
    await restored.loadJourney();
    expect(
        restored.journey.records[SkillRecord.makeId(_subject, _unit)]!.attempts,
        1);
    expect(restored.skills, isEmpty);
  });

  test('assisted and repeated same-problem success never prove independence',
      () async {
    final engine = _engine();
    await _answer(engine, 'helped', help: 2, transfer: true);
    var skill = await _answer(engine, 'one', problem: 'plus_5_3');
    skill = await _answer(engine, 'two', problem: 'plus_5_3', transfer: true);
    expect(skill.attempts, 3);
    expect(skill.assistedCorrect, 1);
    expect(skill.independentCorrect, 2);
    expect(skill.status, JourneyStatus.practicing);
    expect(skill.explanation, contains('Aufgaben'));
    skill = await _answer(engine, 'three', problem: 'plus_6_4');
    expect(skill.status, JourneyStatus.independentlyChecked);
    expect(skill.dueAt, _start.add(const Duration(days: 1)));
    expect(skill.statusLabel, isNotEmpty);
  });

  test('transfer check must be independent and a delayed recall is required',
      () async {
    final engine = _engine();
    await _answer(engine, 'one');
    await _answer(engine, 'two');
    var skill =
        await _answer(engine, 'supported_transfer', help: 1, transfer: true);
    expect(skill.status, JourneyStatus.practicing);
    skill = await _answer(engine, 'real_transfer', transfer: true);
    expect(skill.status, JourneyStatus.independentlyChecked);
    skill = await _answer(engine, 'same_day');
    expect(skill.status, JourneyStatus.independentlyChecked);
    expect(skill.recommendationReason(_start), contains('später'));
    skill = await _answer(engine, 'recall',
        now: _start.add(const Duration(days: 1)));
    expect(skill.status, JourneyStatus.retained);
    expect(skill.dueAt, _start.add(const Duration(days: 4)));
    expect(skill.recommendationReason(_start.add(const Duration(days: 4))),
        contains('Wiederholung'));
    skill = await _answer(engine, 'recall_2', now: skill.dueAt);
    expect(skill.dueAt, _start.add(const Duration(days: 11)));
    skill = await _answer(engine, 'recall_3', now: skill.dueAt);
    expect(skill.dueAt, _start.add(const Duration(days: 25)));
    skill = await _answer(engine, 'recall_4', now: skill.dueAt);
    expect(skill.dueAt, _start.add(const Duration(days: 39)));
    expect(skill.explanation, contains('Faustregel'));
  });

  test('a mistake schedules practice without touching historical school counts',
      () async {
    final engine = _engine();
    await engine.recordAnswer(subject: _subject, unit: _unit, isCorrect: true);
    await _answer(engine, 'one');
    await _answer(engine, 'two', transfer: true);
    final skill =
        await _answer(engine, 'three', correct: false, error: 'place_value');
    expect(skill.attempts, 3);
    expect(skill.errorCounts, {'place_value': 1});
    expect(skill.independentCorrect, 2);
    expect(skill.status, JourneyStatus.practicing);
    expect(skill.lastSeen, _start);
    expect(skill.dueAt, _start.add(const Duration(days: 1)));
    expect(engine.skills.values.single.correct, 1);
    expect(engine.skills.values.single.wrong, 0);
    expect(engine.dailyDone(), 1);
  });

  test('duplicate events remain idempotent after reload', () async {
    var engine = _engine();
    await _answer(engine, 'session:1', correct: false, error: 'calculation');
    await _answer(engine, 'session:1', correct: false, error: 'calculation');
    engine = _engine();
    final skill = await _answer(engine, 'session:1', correct: true);
    expect(skill.attempts, 1);
    expect(skill.independentCorrect, 0);
    expect(skill.errorCounts, {'calculation': 1});
  });

  test(
      'later practice without transfer remains readable after its old due date',
      () async {
    final engine = _engine();
    await _answer(engine, 'one');
    final later = _start.add(const Duration(days: 10));
    final skill = await _answer(engine, 'two', now: later);
    expect(skill.status, JourneyStatus.practicing);
    final restored = _engine();
    await restored.loadJourney();
    expect(restored.journey.records.values.single.lastSeen, later);
    expect(restored.journey.records.values.single.dueAt.isBefore(later), false);
  });

  test('delayed assisted success resets the independent recall interval',
      () async {
    final engine = _engine();
    await _answer(engine, 'one');
    await _answer(engine, 'two', transfer: true);
    var skill = await _answer(engine, 'helped',
        help: 5, now: _start.add(const Duration(days: 1)));
    expect(skill.status, JourneyStatus.practicing);
    expect(skill.independentCorrect, 2);
    skill = await _answer(engine, 'independent',
        now: _start.add(const Duration(days: 2)));
    expect(skill.status, JourneyStatus.independentlyChecked);
    expect(skill.dueAt, _start.add(const Duration(days: 3)));
    skill = await _answer(engine, 'later_recall', now: skill.dueAt);
    expect(skill.status, JourneyStatus.retained);
  });

  test(
      'clock moving backwards cannot move a saved observation or due date back',
      () async {
    final engine = _engine();
    await _answer(engine, 'one');
    final skill = await _answer(engine, 'two',
        transfer: true, now: _start.subtract(const Duration(days: 5)));
    expect(skill.lastSeen, _start);
    expect(skill.dueAt, _start.add(const Duration(days: 1)));
    expect(skill.status, JourneyStatus.independentlyChecked);
  });

  test('saturated counters still save valid bounded evidence', () async {
    final engine = _engine();
    await _answer(engine, 'wrong', correct: false);
    final id = SkillRecord.makeId(_subject, _unit);
    final record = engine.journey.records.values.single.toJson();
    final saturated = LearningJourney.fromJson({
      'version': 1,
      'records': {
        id: {...record, 'attempts': 10000}
      }
    });
    final updated = saturated.recordEvidence(
      subject: _subject,
      unit: _unit,
      evidence: const LearningEvidence(taskId: 'independent', correct: true),
      now: _start,
    );
    expect(updated.records.values.single.attempts, 10000);
    final restored = LearningJourney.fromJson(updated.toJson());
    expect(restored.records.values.single.attempts, 10000);
  });

  test('native false keeps accepted evidence dirty and flush retries once',
      () async {
    final store = _RejectJourneyStore();
    SharedPreferencesStorePlatform.instance = store;
    final engine = _engine();
    await engine.loadJourney();
    store.reject = true;
    await expectLater(_answer(engine, 'session:1'), throwsStateError);
    expect(engine.journey.records.values.single.attempts, 1);
    expect(engine.hasUnsavedChanges, true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LearningDataNamespace.keyFor(_base, 'a')), isNull);
    store.reject = false;
    await engine.flush();
    await _answer(engine, 'session:1');
    final restored = _engine();
    await restored.loadJourney();
    expect(restored.journey.records.values.single.attempts, 1);
    expect(engine.hasUnsavedChanges, false);
    expect(engine.isLoaded, false);
  });

  test('simultaneous accepted evidence cannot overwrite a newer snapshot',
      () async {
    final engine = _engine();
    await Future.wait(List.generate(20, (i) => _answer(engine, 'task:$i')));
    final restored = _engine();
    await restored.loadJourney();
    expect(restored.journey.records.values.single.attempts, 20);
    expect(engine.hasUnsavedChanges, false);
  });

  test('a late snapshot leaves newer evidence dirty until the queued save',
      () async {
    final store = _DelayedJourneyStore();
    SharedPreferencesStorePlatform.instance = store;
    final engine = _engine();
    await engine.loadJourney();
    final first = _answer(engine, 'one');
    await store.entered.future;
    final second = _answer(engine, 'two');
    await Future<void>.delayed(Duration.zero);
    expect(engine.journey.records.values.single.attempts, 2);
    expect(engine.hasUnsavedChanges, true);
    store.release.complete();
    await Future.wait([first, second]);
    final restored = _engine();
    await restored.loadJourney();
    expect(restored.journey.records.values.single.attempts, 2);
    expect(engine.hasUnsavedChanges, false);
  });

  test('many distinct error codes stay bounded in a readable summary',
      () async {
    final engine = _engine();
    for (var i = 0; i < 40; i++) {
      await _answer(engine, 'wrong:$i', correct: false, error: 'error_$i');
    }
    final restored = _engine();
    await restored.loadJourney();
    final skill = restored.journey.records.values.single;
    expect(skill.attempts, 40);
    expect(skill.errorCounts.length, 32);
    expect(skill.errorCounts['other'], 9);
    expect(
        skill.errorCounts.values.fold<int>(0, (sum, value) => sum + value), 40);
  });

  test(
      'recent dedupe and distinct-problem windows are bounded without stopping learning',
      () async {
    final engine = _engine();
    for (var i = 0; i < 140; i++) {
      await _answer(engine, 'task:$i', problem: 'problem:$i');
    }
    final skill = engine.journey.records.values.single;
    expect(skill.attempts, 140);
    final json = skill.toJson();
    expect((json['recentTaskIds'] as List).length, 128);
    expect((json['independentProblemIds'] as List).length, 128);
    await _answer(engine, 'task:139');
    expect(engine.journey.records.values.single.attempts, 140);
    await _answer(engine, 'task:0');
    expect(engine.journey.records.values.single.attempts, 141);
  });

  for (final bad in [
    '',
    '{broken',
    '{}',
    '[]',
    jsonEncode({'version': 2, 'records': {}}),
    jsonEncode({'version': 1, 'records': {}, 'futureField': true}),
  ]) {
    test('invalid or unknown journal bytes stay intact: $bad', () async {
      final key = LearningDataNamespace.keyFor(_base, 'a');
      SharedPreferences.setMockInitialValues({key: bad});
      final engine = _engine();
      await expectLater(engine.loadJourney(), throwsFormatException);
      await expectLater(_answer(engine, 'attempt'), throwsFormatException);
      await engine.flush();
      expect(engine.journey.records, isEmpty);
      expect(engine.isJourneyLoaded, false);
      expect(engine.hasUnsavedChanges, false);
      expect((await SharedPreferences.getInstance()).getString(key), bad);
    });
  }

  test('schema rejects malformed counters, identity, dates and extra fields',
      () async {
    final engine = _engine();
    await _answer(engine, 'one');
    final original = engine.journey.toJson();
    final id = SkillRecord.makeId(_subject, _unit);
    final record = engine.journey.records.values.single.toJson();
    for (final changes in [
      {'attempts': -1},
      {'attempts': 1.5},
      {'assistedCorrect': 9},
      {'lastSeen': 'not-a-date'},
      {'lastSeen': '2026-02-30T12:00:00.000Z'},
      {
        'recentTaskIds': ['duplicate', 'duplicate']
      },
      {
        'independentProblemIds': [4]
      },
      {
        'errorCounts': {'raw answer': 1}
      },
      {'rawAnswer': 'private'},
    ]) {
      final raw = jsonEncode({
        ...original,
        'records': {
          id: {...record, ...changes}
        }
      });
      final key = LearningDataNamespace.keyFor(_base, 'a');
      SharedPreferences.setMockInitialValues({key: raw});
      await expectLater(_engine().loadJourney(), throwsFormatException);
      expect((await SharedPreferences.getInstance()).getString(key), raw);
    }
  });

  test('invalid event metadata is rejected before accepting a mutation',
      () async {
    final engine = _engine();
    await engine.loadJourney();
    for (final evidence in [
      const LearningEvidence(taskId: 'my raw answer is 5', correct: true),
      const LearningEvidence(taskId: 'one', correct: true, helpLevel: -1),
      const LearningEvidence(taskId: 'one', correct: true, helpLevel: 6),
      const LearningEvidence(
          taskId: 'one', correct: false, errorTag: 'Alice said 3'),
    ]) {
      await expectLater(
          engine.recordJourneyEvidence(
              subject: _subject, unit: _unit, evidence: evidence),
          throwsArgumentError);
    }
    expect(engine.journey.records, isEmpty);
    expect(engine.hasUnsavedChanges, false);
  });

  test(
      'reset clears the loaded journal and a pending retry cannot resurrect it',
      () async {
    final store = _RejectJourneyStore();
    SharedPreferencesStorePlatform.instance = store;
    final engine = _engine();
    await engine.loadJourney();
    store.reject = true;
    await expectLater(_answer(engine, 'one'), throwsStateError);
    await expectLater(engine.reset(), throwsStateError);
    expect(engine.journey.records.values.single.attempts, 1);
    expect(engine.hasUnsavedChanges, true);
    store.reject = false;
    await engine.reset();
    await engine.flushJourney();
    final restored = _engine();
    await restored.loadJourney();
    expect(restored.journey.records, isEmpty);
    expect(engine.journey.records, isEmpty);
    expect(engine.hasUnsavedChanges, false);
  });
}
