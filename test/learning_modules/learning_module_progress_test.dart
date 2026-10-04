import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';

class BlockedModuleWallet extends RewardWalletRepository {
  bool reject = false;
  Completer<void>? gate;
  int attempts = 0;

  @override
  Future<RewardWallet> applyRewardDelta(
      {int starsDelta = 0, int xpDelta = 0}) async {
    attempts++;
    if (reject) throw StateError('Wallet disk unavailable');
    await gate?.future;
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }
}

class BlockedModuleProgress extends ProgressRepository {
  bool rejectRead = false;
  bool rejectWrite = false;
  Completer<void>? gate;

  @override
  Future<Map<String, SkillRecord>> loadSkills() async {
    if (rejectRead) throw StateError('Profile read unavailable');
    return super.loadSkills();
  }

  @override
  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    if (rejectWrite) throw StateError('Profile disk unavailable');
    await gate?.future;
    await super.saveSkills(skills);
  }
}

Future<void> _turns() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<LumoAppState> _app(
    {BlockedModuleWallet? wallet, BlockedModuleProgress? repository}) async {
  final app = LumoAppState(
      walletRepository: wallet ?? RewardWalletRepository(),
      learningProfile: LearningProfileEngine(repository: repository));
  await app.hydrateFromWallet();
  await app.loadLearningProfile();
  return app;
}

LearningModuleProgress _progress(LumoAppState app) => LearningModuleProgress(
    appState: app, subject: 'Mathematik', unit: 'Minus bis 10');

Future<void> _stored(
    {required int correct,
    int wrong = 0,
    int hints = 0,
    required int stars,
    required int xp}) async {
  final reopened = await _app();
  expect(reopened.learningDailyDone(), correct);
  final record = reopened
      .learningSkills()[SkillRecord.makeId('Mathematik', 'Minus bis 10')];
  if (correct + wrong == 0) {
    expect(record, isNull);
  } else {
    expect(record!.correct, correct);
    expect(record.wrong, wrong);
    expect(record.hintCount, hints);
  }
  expect(reopened.state.stars, stars);
  expect(reopened.state.xp, xp);
  reopened.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'wallet write failure retries its existing reward and records one accepted answer',
      () async {
    final wallet = BlockedModuleWallet()..reject = true;
    final app = await _app(wallet: wallet);
    final progress = _progress(app);
    final accepted = progress.saveAnswer(correct: true, stars: 1, xp: 5);
    final duplicate = progress.saveAnswer(correct: true, stars: 1, xp: 5);
    expect(identical(accepted, duplicate), isTrue);
    await _turns();
    expect(progress.hasPending, isTrue);
    expect(progress.error, contains('Antwort'));
    expect(app.learningDailyDone(), 0);
    wallet.reject = false;
    wallet.gate = Completer<void>();
    progress.retry();
    progress.retry();
    await _turns();
    expect(progress.saving, isTrue);
    wallet.gate!.complete();
    expect(await accepted, isTrue);
    expect(wallet.attempts, 2);
    await _stored(correct: 1, stars: 1, xp: 5);
    progress.dispose();
    app.dispose();
  });

  test(
      'profile write failure flushes a counted answer without double Daily or hint',
      () async {
    final repo = BlockedModuleProgress();
    final app = await _app(repository: repo);
    final progress = _progress(app);
    repo.rejectWrite = true;
    final accepted =
        progress.saveAnswer(correct: true, hintUsed: true, stars: 1, xp: 5);
    await _turns();
    expect(progress.error, isNotNull);
    expect(app.learningDailyDone(), 1);
    repo.rejectWrite = false;
    progress.retry();
    expect(await accepted, isTrue);
    await _stored(correct: 1, hints: 1, stars: 1, xp: 5);
    progress.dispose();
    app.dispose();
  });

  test('false answers persist exactly once on retry and never increment Daily',
      () async {
    final repo = BlockedModuleProgress();
    final app = await _app(repository: repo);
    final progress = _progress(app);
    repo.rejectWrite = true;
    final accepted = progress.saveAnswer(correct: false);
    await _turns();
    expect(progress.error, isNotNull);
    expect(app.learningDailyDone(), 0);
    repo.rejectWrite = false;
    progress.retry();
    expect(await accepted, isTrue);
    await _stored(correct: 0, wrong: 1, stars: 0, xp: 0);
    progress.dispose();
    app.dispose();
  });

  test('failed profile load cannot replace saved history with an empty profile',
      () async {
    final old = await _app();
    await old.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Minus bis 10',
        correct: true,
        requireSaved: true);
    old.dispose();
    final repo = BlockedModuleProgress()..rejectRead = true;
    final app = await _app(repository: repo);
    expect(app.learningProfileLoaded, isFalse);
    final progress = _progress(app);
    final accepted = progress.saveAnswer(correct: false);
    await _turns();
    expect(progress.error, isNotNull);
    await _stored(correct: 1, stars: 0, xp: 0);
    repo.rejectRead = false;
    progress.retry();
    expect(await accepted, isTrue);
    await _stored(correct: 1, wrong: 1, stars: 0, xp: 0);
    progress.dispose();
    app.dispose();
  });

  test(
      'unmount while the wallet is delayed still completes wallet AND learning storage',
      () async {
    final wallet = BlockedModuleWallet()..gate = Completer<void>();
    final app = await _app(wallet: wallet);
    final progress = _progress(app);
    final accepted = progress.saveAnswer(correct: true, stars: 1, xp: 5);
    await _turns();
    progress.dispose();
    expect(await accepted, isFalse); // UI continuation cancelled only.
    wallet.gate!.complete();
    await _turns();
    await _stored(correct: 1, stars: 1, xp: 5);
    app.dispose();
  });

  test(
      'intermediate rewards and once-per-session bonus never invent learning answers',
      () async {
    final wallet = BlockedModuleWallet();
    final app = await _app(wallet: wallet);
    final progress = _progress(app);
    expect(await progress.saveReward(stars: 0, xp: 4), isTrue);
    expect(await progress.saveReward(stars: 0, xp: 4), isTrue);
    expect(await progress.saveBonus(stars: 3, xp: 19), isTrue);
    expect(await progress.saveBonus(stars: 3, xp: 19), isTrue);
    await _stored(correct: 0, stars: 3, xp: 27);
    expect(wallet.attempts, 3);
    expect(progress.resetSession(), isTrue);
    expect(await progress.saveBonus(stars: 3, xp: 19), isTrue);
    await _stored(correct: 0, stars: 6, xp: 46);
    progress.dispose();
    app.dispose();
  });

  testWidgets(
      'feedback cannot advance in background and cancels cleanly on unmount',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    final progress = _progress(app);
    var advanced = false;
    final feedback = progress.feedbackDelay(const Duration(seconds: 1));
    feedback.then((saved) => advanced = saved);
    progress.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(advanced, isFalse);
    progress.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(await feedback, isTrue);
    expect(advanced, isTrue);
    final cancelled = progress.feedbackDelay(const Duration(seconds: 2));
    progress.dispose();
    expect(await cancelled, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    app.dispose();
  });
}
