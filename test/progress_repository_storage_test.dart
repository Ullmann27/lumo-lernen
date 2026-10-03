import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';

class _FalseStore extends InMemorySharedPreferencesStore {
  _FalseStore(Map<String, Object> initial)
      : super.withData(
            initial.map((key, value) => MapEntry('flutter.$key', value)));

  String? rejectedKey;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == rejectedKey) return false;
    return super.setValue(valueType, key, value);
  }
}

String _today() => DateTime.now().toIso8601String().substring(0, 10);

Map<String, Object> _existingProgress() => {
      'lumo_progress_skills': jsonEncode({
        'mathematik::plus bis 10': SkillRecord(
          skillId: 'mathematik::plus bis 10',
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          correct: 2,
        ).toJson(),
      }),
      'lumo_progress_daily': jsonEncode({_today(): 2}),
      'lumo_progress_last': jsonEncode({'Mathematik': 'Plus bis 10'}),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final key in ['skills', 'daily', 'last']) {
    test('platform false for $key remains failure; flush saves the same answer',
        () async {
      final store = _FalseStore(_existingProgress());
      SharedPreferencesStorePlatform.instance = store;
      final engine = LearningProfileEngine();
      await engine.load();
      store.rejectedKey = 'flutter.lumo_progress_$key';
      await expectLater(
          engine.recordAnswer(
              subject: 'Mathematik', unit: 'Plus bis 10', isCorrect: true),
          throwsStateError);
      expect(engine.dailyDone(), 3);
      expect(engine.skills['mathematik::plus bis 10']!.correct, 3);
      store.rejectedKey = null;
      await engine.flush();
      final restored = LearningProfileEngine();
      await restored.load();
      expect(restored.dailyDone(), 3);
      expect(restored.skills['mathematik::plus bis 10']!.correct, 3);
      expect(restored.skills['mathematik::plus bis 10']!.wrong, 0);
      expect(restored.lastTopics['Mathematik'], 'Plus bis 10');
    });

    test('a rejected $key normalization preserves existing valid disk data',
        () async {
      final seed = _existingProgress();
      final store = _FalseStore(seed)
        ..rejectedKey = 'flutter.lumo_progress_$key';
      SharedPreferencesStorePlatform.instance = store;
      final repo = ProgressRepository();
      final Future<Object> pending = switch (key) {
        'skills' => repo.loadSkills(),
        'daily' => repo.loadDaily(),
        _ => repo.loadLastTopics(),
      };
      await expectLater(pending, throwsStateError);
      expect((await store.getAll())['flutter.lumo_progress_$key'],
          seed['lumo_progress_$key']);
      store.rejectedKey = null;
      final restored = LearningProfileEngine();
      await restored.load();
      expect(restored.dailyDone(), 2);
      expect(restored.skills['mathematik::plus bis 10']!.correct, 2);
      expect(restored.lastTopics['Mathematik'], 'Plus bis 10');
    });
  }

  testWidgets(
      'actual module Retry handles native false without duplicate progress',
      (tester) async {
    final store = _FalseStore({});
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await tester.runAsync(() async {
      await app.hydrateFromWallet();
      await app.loadLearningProfile();
    });
    final progress = LearningModuleProgress(
        appState: app, subject: 'Deutsch', unit: 'Artikel');
    store.rejectedKey = 'flutter.lumo_progress_daily';
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: LearningModuleProgressScope(
        progress: progress,
        child: Scaffold(
          body: FilledButton(
            onPressed: () async {
              if (await progress.saveAnswer(correct: true, stars: 1, xp: 7)) {
                completed++;
              }
            },
            child: const Text('Richtige Antwort'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Richtige Antwort'));
    await tester.pumpAndSettle();
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(progress.hasPending, isTrue);
    expect(completed, 0);
    expect(app.learningDailyDone(), 1);
    await tester.tap(find.text('Richtige Antwort'), warnIfMissed: false);
    await tester.pump();
    expect(completed, 0);
    store.rejectedKey = null;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(progress.hasPending, isFalse);
    await tester.runAsync(() async {
      final restored = LumoAppState(walletRepository: RewardWalletRepository());
      await restored.hydrateFromWallet();
      await restored.loadLearningProfile();
      expect(restored.state.stars, 1);
      expect(restored.state.xp, 7);
      expect(restored.learningDailyDone(), 1);
      expect(restored.learningSkills()['deutsch::artikel']!.correct, 1);
      restored.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    app.dispose();
    expect(tester.takeException(), isNull);
  });
}
