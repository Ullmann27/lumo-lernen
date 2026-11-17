import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_cup.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RejectingStore extends InMemorySharedPreferencesStore {
  _RejectingStore() : super.withData({});
  bool reject = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      reject ? false : super.setValue(valueType, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const ownerA = 'school-child-A';
  LumoCardsCupRepository repository({String child = ownerA, int grade = 1}) =>
      LumoCardsCupRepository(studentId: child, grade: grade);
  String roundId(int index) =>
      'cards-${index.toRadixString(16).padLeft(32, '0')}';

  test('Three ordered rounds survive reopen and concurrent duplicate results',
      () async {
    final repo = repository();
    var cup = await repo.load(canWrite: () => true);
    final cupId = cup.id;
    for (var leg = 0; leg < 3; leg++) {
      final results = await Future.wait(List.generate(
          2,
          (_) => repo.record(
              cupId: cupId,
              round: leg,
              roundId: roundId(leg),
              won: leg != 1,
              canWrite: () => true)));
      expect(results.map((c) => c.results.length), everyElement(leg + 1));
      cup = await repository().load(canWrite: () => true);
      expect(cup.id, cupId);
      expect(cup.nextRound, leg + 1);
    }
    expect(cup.complete, isTrue);
    expect(cup.wins, 2);
    expect(cup.medal, 'Silberpokal');
    expect(
        (await SharedPreferences.getInstance()).getKeys(), {repo.storageKey});
    final next = await repo.restart(cupId: cupId, canWrite: () => true);
    expect(next.id, isNot(cupId));
    expect(next.results, isEmpty);
    await expectLater(
        repo.record(
            cupId: cupId,
            round: 0,
            roundId: roundId(0),
            won: true,
            canWrite: () => true),
        throwsStateError);
  });

  test('Round index, identity and conflicting result cannot advance the cup',
      () async {
    final repo = repository();
    final cup = await repo.load(canWrite: () => true);
    Future<LumoCardsCup> record(int leg, String id, bool won) => repo.record(
        cupId: cup.id, round: leg, roundId: id, won: won, canWrite: () => true);
    await expectLater(record(1, roundId(1), true), throwsStateError);
    await expectLater(record(0, '../bad', true), throwsStateError);
    await record(0, roundId(0), true);
    await expectLater(record(-1, roundId(0), true), throwsStateError);
    await expectLater(record(0, roundId(0), false), throwsStateError);
    await expectLater(record(1, roundId(0), true), throwsStateError);
    await expectLater(
        repo.restart(cupId: cup.id, canWrite: () => true), throwsStateError);
    expect((await repo.load(canWrite: () => true)).results.length, 1);
  });

  test(
      'Per-child and per-grade cups never share progression; stale lease rejects',
      () async {
    final a = repository();
    final b = repository(child: 'school-child-B');
    final grade = repository(grade: 2);
    final cup = await a.load(canWrite: () => true);
    await a.record(
        cupId: cup.id,
        round: 0,
        roundId: roundId(0),
        won: true,
        canWrite: () => true);
    expect((await b.load(canWrite: () => true)).results, isEmpty);
    expect((await grade.load(canWrite: () => true)).results, isEmpty);
    await expectLater(
        a.record(
            cupId: cup.id,
            round: 1,
            roundId: roundId(1),
            won: true,
            canWrite: () => false),
        throwsStateError);
    expect((await a.load(canWrite: () => true)).results.length, 1);
    expect({a.storageKey, b.storageKey, grade.storageKey}.length, 3);
  });

  test('Rejected storage does not advance, and same result retries once',
      () async {
    final store = _RejectingStore();
    SharedPreferencesStorePlatform.instance = store;
    final repo = repository();
    final cup = await repo.load(canWrite: () => true);
    store.reject = true;
    await expectLater(
        repo.record(
            cupId: cup.id,
            round: 0,
            roundId: roundId(0),
            won: true,
            canWrite: () => true),
        throwsStateError);
    expect((await repo.load(canWrite: () => true)).results, isEmpty);
    store.reject = false;
    final saved = await repo.record(
        cupId: cup.id,
        round: 0,
        roundId: roundId(0),
        won: true,
        canWrite: () => true);
    expect(saved.results.length, 1);
  });

  test(
      'Invalid saved cup is rejected without overwriting evidence or classic rounds',
      () async {
    final repo = repository();
    final prefs = await SharedPreferences.getInstance();
    final invalid = jsonEncode({
      'version': 1,
      'id': roundId(1),
      'owner': repo.owner,
      'grade': 1,
      'results': [
        {'roundId': roundId(0), 'won': true},
        {'roundId': roundId(0), 'won': true}
      ]
    });
    await prefs.setString(repo.storageKey, invalid);
    await expectLater(
        repo.load(canWrite: () => true), throwsA(isA<StateError>()));
    expect(prefs.getString(repo.storageKey), invalid);
    final classic =
        LumoCardsSessionRepository(studentId: ownerA, grade: 1, vsBot: true);
    expect(classic.storageKey, 'lumo.cards.round.v1.${classic.owner}.1.solo');
    final slot = LumoCardsSessionRepository(
        studentId: ownerA, grade: 1, vsBot: true, slot: 'cup-${roundId(5)}-2');
    expect(slot.storageKey, '${classic.storageKey}.cup-${roundId(5)}-2');
    expect(
        () => LumoCardsSessionRepository(
            studentId: ownerA, grade: 1, vsBot: true, slot: '../anything'),
        throwsArgumentError);
  });
}
