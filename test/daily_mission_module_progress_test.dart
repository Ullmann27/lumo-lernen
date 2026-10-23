import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RejectMissionStore extends InMemorySharedPreferencesStore {
  _RejectMissionStore() : super.withData({});
  bool reject = false;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (reject && key.contains('lumo_daily_mission_v1')) return false;
    return super.setValue(type, key, value);
  }
}

Future<void> _turns() async {
  for (var i = 0; i < 80; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _frames(WidgetTester tester, [int count = 100]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 17));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  test('new assessed standard-module answers count, helped work is fair', () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.loadDailyMission();
    final progress = LearningModuleProgress(
        appState: app, subject: 'Mathematik', unit: 'Minus bis 10');
    addTearDown(progress.dispose);
    expect(await progress.saveAnswer(correct: false), isTrue);
    expect(app.dailyMission!.completedCount, 0);
    expect(await progress.saveAnswer(correct: true, hintUsed: true), isTrue);
    expect(app.dailyMission!.completedCount, 1);
    expect(await progress.saveAnswer(correct: true), isTrue);
    expect(app.dailyMission!.completedCount, 2);
    final reopened = LumoAppState();
    addTearDown(reopened.dispose);
    await reopened.loadDailyMission();
    expect(reopened.dailyMission!.completedCount, 2);
  });

  test('a standard-module retry preserves one accepted task identity', () async {
    final store = _RejectMissionStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.loadDailyMission();
    final progress = LearningModuleProgress(
        appState: app, subject: 'Deutsch', unit: 'Silben');
    addTearDown(progress.dispose);
    store.reject = true;
    final accepted = progress.saveAnswer(correct: true, hintUsed: true);
    expect(identical(accepted, progress.saveAnswer(correct: true)), isTrue);
    await _turns();
    expect(progress.error, isNotNull);
    expect(app.dailyMission!.completedCount, 0);
    store.reject = false;
    progress.retry();
    progress.retry();
    expect(await accepted, isTrue);
    expect(app.dailyMission!.completedCount, 1);
    await app.loadDailyMission();
    expect(app.dailyMission!.completedCount, 1);
    expect(app.learningDailyDone(), 1);
  });

  testWidgets('real Plus bis 10 counts a corrected helped task once',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false,
        reduceAnimations: true, calmMode: true));
    await tester.runAsync(() async {
      await app.hydrateFromWallet();
      await app.loadLearningProfile();
      await app.loadDailyMission();
    });
    await tester.binding.setSurfaceSize(const Size(480, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: PlusBis10Screen(appState: app)));
    await _frames(tester, 30);
    final prompt = tester.widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .singleWhere((text) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(text));
    final correct = RegExp(r'\d+').allMatches(prompt)
        .map((m) => int.parse(m[0]!)).reduce((a, b) => a + b);
    final wrong = tester.widgetList<Text>(find.descendant(
        of: find.byType(GridView), matching: find.byType(Text)))
        .map((text) => int.parse(text.data!)).firstWhere((n) => n != correct);
    Finder button(int n) => find.descendant(
        of: find.byType(GridView), matching: find.text('$n'));
    await tester.ensureVisible(button(wrong));
    await tester.tap(button(wrong));
    await _frames(tester);
    expect(app.dailyMission!.completedCount, 0);
    await tester.ensureVisible(find.text('Tipp'));
    await tester.tap(find.text('Tipp'));
    await tester.pump();
    await tester.ensureVisible(button(correct));
    await tester.tap(button(correct));
    await _frames(tester);
    expect(app.dailyMission!.completedCount, 1);
    await tester.runAsync(app.loadDailyMission);
    expect(app.dailyMission!.completedCount, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
