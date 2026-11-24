import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/mini_game_learning_task.dart';
import 'package:lumo_lernen/domain/games/mini_game_round.dart';

const _owner =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _roundId = '11111111111111111111111111111111';

class _Store implements MiniGameRoundStore {
  String? raw;
  bool reject = false;
  Completer<void>? gate;
  int writes = 0;
  @override
  Future<String?> read() async => raw;
  @override
  Future<void> write(String snapshot) async {
    writes++;
    final pending = gate;
    if (pending != null) await pending.future;
    if (reject) throw StateError('disk write failed');
    raw = snapshot;
  }
}

class _NativeStore extends InMemorySharedPreferencesStore {
  _NativeStore(Map<String, Object> initial)
      : super.withData(
            initial.map((key, value) => MapEntry('flutter.$key', value)));
  String? reject;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      key == reject ? false : super.setValue(valueType, key, value);
}

Future<MiniGameRoundController> _open(_Store store,
        {int level = 1,
        bool Function()? current,
        MiniGameLevelSave? save,
        MiniGameAward? award}) =>
    MiniGameRoundController.open(
        owner: _owner,
        level: GameLevelCatalog.byId(level)!,
        store: store,
        canUseProfile: current ?? () => true,
        saveLevel: save ?? (_) async {},
        award: award ?? (_, __, ___) async {},
        seed: 42,
        id: _roundId);

Future<void> _solve(MiniGameRoundController controller) async {
  final task = controller.round.task;
  if (task.input == MiniGameInput.boxes) {
    final response = controller.round.response;
    final missing =
        task.targetCount! - response.boxes.where((box) => box).length;
    final empty = [
      for (var i = 0; i < response.boxes.length; i++)
        if (!response.boxes[i]) i
    ];
    for (final i in empty.take(missing)) {
      await controller.toggleBox(i);
    }
    await controller.answer();
  } else if (task.input == MiniGameInput.orderedWords) {
    for (final word in task.answer.split(' ')) {
      await controller.orderWord(task.choices.indexOf(word));
    }
    await controller.answer();
  } else {
    await controller.answer(task.answer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'all 49 live mini-game levels produce verified complete decks over 30 seeds',
      () {
    var tasks = 0;
    for (final level
        in GameLevelCatalog.levels.where((level) => level.id != 50)) {
      for (var seed = 0; seed < 30; seed++) {
        final deck = MiniGameLearningDeck.build(level, seed);
        expect(deck, hasLength(MiniGameLearningDeck.taskCount(level)));
        for (final task in deck) {
          expect(task.isValid, isTrue, reason: '${level.id}: ${task.prompt}');
          expect(task.hints, hasLength(3));
          if (task.input == MiniGameInput.boxes) {
            expect(task.initialBoxes, hasLength(10));
            expect(task.initialBoxes.where((box) => box).length,
                lessThan(task.targetCount!));
          } else if (task.input == MiniGameInput.letters) {
            expect(task.word[task.gapIndex!], task.answer);
          }
          final syllables = task.visual.data['syllables'];
          if (syllables is List) {
            expect(syllables.join().toLowerCase(), task.cue.toLowerCase());
            expect(syllables.length.toString(), task.answer);
          }
          tasks++;
        }
      }
    }
    expect(tasks, 7530);
    expect(() => MiniGameLearningDeck.build(GameLevelCatalog.byId(50)!, 0),
        throwsArgumentError,
        reason: 'The real Level 50 entry belongs to QuizShow.');
  });

  test(
      'wrong letter stays on its task; confirmed retry preserves first-answer reward',
      () async {
    final store = _Store();
    final controller = await _open(store, level: 25);
    final first = controller.round.task;
    final wrong = first.choices.firstWhere((choice) => choice != first.answer);
    await controller.answer(wrong);
    expect(controller.round.index, 0);
    expect(await controller.next(), isFalse);
    expect(await controller.answer(wrong), isFalse,
        reason: 'The same confirmed button cannot count again.');
    await controller.help(2);
    await _solve(controller);
    expect(controller.round.firstCorrectCount, 0);
    expect(controller.round.response.help, 2);
    for (var i = 1; i < 6; i++) {
      await controller.next();
      await _solve(controller);
    }
    expect(controller.round.complete, isTrue);
    expect(controller.round.solvedCount, 6);
    expect(controller.round.firstCorrectCount, 5);
    expect(controller.round.walletStars, 4);
    expect(controller.round.xp, 40);
    expect(controller.round.independentCount, 5);
    controller.close();
  });

  test(
      'accepted answer and help survive retry and reopening without duplication',
      () async {
    final store = _Store();
    final controller = await _open(store);
    await controller.help(2);
    final correct = controller.round.task.answer;
    store.reject = true;
    await expectLater(controller.answer(correct), throwsStateError);
    expect(controller.hasPending, isTrue);
    expect(controller.canWork, isFalse);
    expect(await controller.answer(correct), isFalse);
    expect(controller.round.response.attempts, [correct]);
    store.reject = false;
    await controller.retry();
    controller.close();
    final reopened = await _open(store);
    expect(reopened.restored, isTrue);
    expect(reopened.round.response.attempts, [correct]);
    expect(reopened.round.response.help, 2);
    expect(reopened.round.independentCount, 0);
    await reopened.next();
    expect(reopened.round.index, 1);
    expect(reopened.round.response.help, 0);
    reopened.close();
  });

  test('duplicate next while disk is pending advances exactly one task',
      () async {
    final store = _Store();
    final controller = await _open(store);
    await _solve(controller);
    final gate = Completer<void>();
    store.gate = gate;
    final first = controller.next();
    expect(await controller.next(), isFalse);
    gate.complete();
    await first;
    expect(controller.round.index, 1);
    expect(controller.round.response.attempts, isEmpty);
    controller.close();
  });

  test('partial color quantities and ordered words resume exactly', () async {
    for (final level in [2, 47]) {
      final store = _Store();
      final controller = await _open(store, level: level);
      if (level == 2) {
        await controller.toggleBox(0);
      } else {
        await controller.orderWord(2);
        await controller.orderWord(0);
      }
      final before = jsonEncode(controller.round.response.toJson());
      controller.close();
      final resumed = await _open(store, level: level);
      expect(jsonEncode(resumed.round.response.toJson()), before);
      expect(resumed.round.response.attempts, isEmpty);
      resumed.close();
    }
  });

  test(
      'failed level save cannot award; reward receipt replays safely after a crash',
      () async {
    final store = _Store();
    var failLevel = true;
    var awards = 0;
    final receiptIds = <String>{};
    Future<void> award(String id, int stars, int xp) async {
      if (receiptIds.add(id)) awards++;
      expect(stars, 3);
      expect(xp, 40);
    }

    Future<void> save(int stars) async {
      if (failLevel) throw StateError('level');
    }

    final controller = await _open(store, save: save, award: award);
    for (var i = 0; i < 5; i++) {
      await _solve(controller);
      await controller.next();
    }
    await expectLater(controller.settleResult(), throwsStateError);
    expect(awards, 0);
    failLevel = false;
    store.reject = true;
    await expectLater(controller.settleResult(), throwsStateError);
    expect(awards, 1);
    controller.close();
    store.reject = false;
    final resumed = await _open(store, save: save, award: award);
    expect(resumed.round.finishRequested, isTrue);
    expect(resumed.round.rewarded, isFalse);
    await resumed.settleResult();
    await resumed.settleResult();
    expect(resumed.round.rewarded, isTrue);
    expect(awards, 1);
    resumed.close();
  });

  test('profile switch during level write cannot reward a different child',
      () async {
    final store = _Store();
    var current = true;
    var awards = 0;
    final levelGate = Completer<void>();
    final controller = await _open(store,
        current: () => current,
        save: (_) => levelGate.future,
        award: (_, __, ___) async {
          awards++;
        });
    for (var i = 0; i < 5; i++) {
      await _solve(controller);
      await controller.next();
    }
    final finishing = controller.settleResult();
    await Future<void>.delayed(Duration.zero);
    current = false;
    levelGate.complete();
    await expectLater(finishing, throwsStateError);
    expect(awards, 0);
    expect(controller.round.rewarded, isFalse);
    expect(await controller.select(controller.round.task.answer), isFalse);
    controller.close();
  });

  test('malformed or foreign round bytes are never overwritten on open',
      () async {
    final store = _Store()..raw = '{bad';
    await expectLater(_open(store), throwsFormatException);
    expect(store.raw, '{bad');
    expect(store.writes, 0);
    final foreign = MiniGameRound.fresh(
        owner: 'b' * 64, level: GameLevelCatalog.byId(1)!, seed: 1);
    store.raw = jsonEncode(foreign.toJson());
    final bytes = store.raw;
    await expectLater(_open(store), throwsFormatException);
    expect(store.raw, bytes);
    expect(store.writes, 0);
  });

  test(
      'native false is an error and cannot become cached proof of level success',
      () async {
    final platform = _NativeStore({'lumo.games.curriculum50.child': '[]'});
    SharedPreferencesStorePlatform.instance = platform;
    platform.reject = 'flutter.lumo.games.stars.child';
    const repo = GameProgressRepository();
    await expectLater(
        repo.recordResult(childId: 'child', levelId: 1, starsEarned: 3),
        throwsStateError);
    expect(await repo.loadStars('child'), isEmpty);
    expect((await platform.getAll())['flutter.lumo.games.stars.child'], isNull);
    platform.reject = null;
    await repo.recordResult(childId: 'child', levelId: 1, starsEarned: 3);
    expect(await repo.loadStars('child'), {1: 3});
  });

  test('level result cannot replace malformed legacy progress', () async {
    SharedPreferences.setMockInitialValues(
        {'lumo.games.stars.child': '{broken'});
    const repo = GameProgressRepository();
    expect(await repo.loadStars('child'), isEmpty);
    await expectLater(
        repo.recordResult(childId: 'child', levelId: 1, starsEarned: 3),
        throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo.games.stars.child'), '{broken');
  });

  test('round journal reset affects only the selected legacy child scope',
      () async {
    const repo = GameProgressRepository();
    await repo.saveRound(
        childId: 'first', owner: _owner, levelId: 2, snapshot: '{}');
    await repo.saveRound(
        childId: 'second',
        owner: _owner,
        levelId: 2,
        snapshot: '{"kept":true}');
    await repo.reset('first');
    expect(await repo.loadRound(childId: 'first', owner: _owner, levelId: 2),
        isNull);
    expect(await repo.loadRound(childId: 'second', owner: _owner, levelId: 2),
        '{"kept":true}');
  });
}
