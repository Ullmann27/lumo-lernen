import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/session_round_resume.dart';
import 'package:lumo_lernen/domain/learning/practice_session_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('quick practice length follows the age', () {
    expect(quickPracticeLength(1), 6);
    expect(quickPracticeLength(2), 8);
    expect(quickPracticeLength(3), 10);
    expect(quickPracticeLength(4), 10);
  });

  group('SessionRounds', () {
    test('short sessions have no rounds', () {
      expect(SessionRounds.applies(6), isFalse);
      expect(SessionRounds.applies(10), isFalse);
      expect(SessionRounds.endsRound(10, 10), isFalse);
      expect(SessionRounds.roundOf(7, 8), 1);
    });

    test('thirty tasks are three rounds of ten', () {
      expect(SessionRounds.count(30), 3);
      expect(SessionRounds.roundOf(1, 30), 1);
      expect(SessionRounds.roundOf(10, 30), 1);
      expect(SessionRounds.roundOf(11, 30), 2);
      expect(SessionRounds.roundOf(30, 30), 3);
      expect(SessionRounds.endsRound(10, 30), isTrue);
      expect(SessionRounds.endsRound(20, 30), isTrue);
      expect(SessionRounds.endsRound(30, 30), isFalse,
          reason: 'the last round ends the session, not a break');
      expect(SessionRounds.endsRound(15, 30), isFalse);
    });

    test('returning mistakes stay in the last round', () {
      expect(SessionRounds.roundOf(22, 20), 2);
      expect(SessionRounds.count(20), 2);
    });
  });

  group('TwinTaskQueue', () {
    test('a mistake returns two tasks later', () {
      final queue = TwinTaskQueue<String>()..schedule('a', question: 1);
      expect(queue.takeFor(2, lastQuestion: 6), isNull);
      expect(queue.takeFor(3, lastQuestion: 6), 'a');
      expect(queue.isEmpty, isTrue);
    });

    test('two mistakes in a row return two and three tasks later', () {
      final queue = TwinTaskQueue<String>()
        ..schedule('a', question: 2)
        ..schedule('b', question: 3);
      expect(queue.takeFor(4, lastQuestion: 10), 'a');
      expect(queue.takeFor(5, lastQuestion: 10), 'b');
    });

    test('a taken place moves the next twin one task further', () {
      final queue = TwinTaskQueue<String>()
        ..schedule('a', question: 2)
        ..schedule('b', question: 2);
      expect(queue.takeFor(4, lastQuestion: 10), 'a');
      expect(queue.takeFor(5, lastQuestion: 10), 'b');
    });

    test('the session grows by at most two tasks', () {
      final queue = TwinTaskQueue<String>();
      expect(queue.extensionFor(6), 0);
      queue.schedule('a', question: 4);
      expect(queue.extensionFor(6), 0, reason: 'fits before the end');
      queue.schedule('b', question: 6);
      expect(queue.extensionFor(6), 2);
      queue.schedule('c', question: 7);
      queue.schedule('d', question: 8);
      expect(queue.extensionFor(6), TwinTaskQueue.maxExtension);
    });

    test('at the end waiting twins take the remaining places', () {
      final queue = TwinTaskQueue<String>()
        ..schedule('a', question: 6) // due 8
        ..schedule('b', question: 7); // due 9, beyond the extended end
      expect(queue.takeFor(7, lastQuestion: 8), 'a',
          reason: 'two waiting twins, two places left');
      expect(queue.takeFor(8, lastQuestion: 8), 'b');
      expect(queue.takeFor(9, lastQuestion: 8), isNull);
    });
  });

  group('SessionRoundResumeStore', () {
    test('saves, restores and clears a round boundary per child', () async {
      final store = SessionRoundResumeStore(studentId: 'child-1');
      const scope = 'module|Mathematik|Minus bis 10';
      expect(await store.load(scope, totalTasks: 30), isNull);

      await store.save(
          scope,
          const SessionRoundPosition(
              completedTasks: 10, totalTasks: 30, correct: 8));
      final position = await store.load(scope, totalTasks: 30);
      expect(position!.completedTasks, 10);
      expect(position.correct, 8);
      expect(position.nextRound, 2);

      // Another child and another module see nothing.
      expect(
          await SessionRoundResumeStore(studentId: 'child-2')
              .load(scope, totalTasks: 30),
          isNull);
      expect(await store.load('module|Mathematik|Geld', totalTasks: 30), isNull);

      await store.clear(scope);
      expect(await store.load(scope, totalTasks: 30), isNull);
    });

    test('uses a new versioned key and stores no task content', () async {
      await SessionRoundResumeStore(studentId: 'child-1').save(
          'lesson|schoolwork|2|Mathematik|Alle',
          const SessionRoundPosition(completedTasks: 20, totalTasks: 30));
      final prefs = await SharedPreferences.getInstance();
      final key = prefs
          .getKeys()
          .singleWhere((k) => k.startsWith('lumo_session_round_resume_v1'));
      final raw = prefs.getString(key)!;
      expect(raw, contains('"version":1'));
      expect(raw, contains('"done":20'));
    });

    test('ignores positions that are stale, mid-round or of another length',
        () async {
      final store = SessionRoundResumeStore(studentId: 'child-1');
      await store.save(
          'a', const SessionRoundPosition(completedTasks: 10, totalTasks: 30),
          now: DateTime(2026, 11, 1));
      expect(
          await store.load('a', totalTasks: 30, now: DateTime(2026, 11, 10)),
          isNotNull);
      expect(
          await store.load('a', totalTasks: 30, now: DateTime(2026, 11, 20)),
          isNull,
          reason: 'after two weeks a fresh start is kinder');
      expect(await store.load('a', totalTasks: 20, now: DateTime(2026, 11, 2)),
          isNull);

      await store.save(
          'b', const SessionRoundPosition(completedTasks: 7, totalTasks: 30));
      expect(await store.load('b', totalTasks: 30), isNull);
      await store.save(
          'c', const SessionRoundPosition(completedTasks: 30, totalTasks: 30));
      expect(await store.load('c', totalTasks: 30), isNull);
    });

    test('unreadable content means round 1, not an error', () async {
      final store = SessionRoundResumeStore(studentId: 'child-1');
      await store.save(
          'a', const SessionRoundPosition(completedTasks: 10, totalTasks: 30));
      final prefs = await SharedPreferences.getInstance();
      final key = prefs
          .getKeys()
          .singleWhere((k) => k.startsWith('lumo_session_round_resume_v1'));
      await prefs.setString(key, 'not json');
      expect(await store.load('a', totalTasks: 30), isNull);
    });
  });
}
