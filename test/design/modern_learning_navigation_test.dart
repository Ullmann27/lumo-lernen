import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  Future<LumoAppState> open(WidgetTester tester, int grade) async {
    await tester.binding.setSurfaceSize(const Size(800, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    app.update(app.state.copyWith(grade: grade));
    await tester
        .pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
    await tester.pump(const Duration(milliseconds: 900));
    return app;
  }

  testWidgets('all classes stay in the shared subject and topic navigation',
      (tester) async {
    final app = await open(tester, 2);
    for (final grade in [1, 3, 4, 2]) {
      final picker = find.byKey(ValueKey('grade-pill-$grade'));
      expect(picker, findsOneWidget,
          reason: 'A class must be reachable without opening the old academy.');
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pump();
      for (final subject in [
        'Mathematik',
        'Deutsch',
        'Englisch',
        'Sachunterricht'
      ]) {
        final card = find.byKey(ValueKey('learning-subject-$subject'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pump();
        expect(find.text('Themen · $subject'), findsOneWidget);
        expect(find.byKey(const ValueKey('learning-back-to-subjects')),
            findsOneWidget);
        await tester.ensureVisible(
            find.byKey(const ValueKey('learning-back-to-subjects')));
        await tester
            .tap(find.byKey(const ValueKey('learning-back-to-subjects')));
        await tester.pump();
      }
      expect(app.state.grade, 2);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'normal mathematics route opens the original answer crystal module',
      (tester) async {
    await open(tester, 1);
    await tester.tap(find.byKey(const ValueKey('learning-subject-Mathematik')));
    await tester.pump();
    final unit =
        find.byKey(const ValueKey('learning-unit-Mathematik-Minus bis 10'));
    await tester.ensureVisible(unit);
    await tester.tap(unit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(MinusBis10Screen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'foreign class opens actual practice without changing the profile',
      (tester) async {
    final app = await open(tester, 2);
    await tester.tap(find.byKey(const ValueKey('grade-pill-4')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('learning-subject-Mathematik')));
    await tester.pump();
    final unit = find.byKey(
        const ValueKey('learning-unit-Mathematik-Zahlenraum bis 1 Million'));
    await tester.ensureVisible(unit);
    await tester.tap(unit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(CrossGradePracticeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('cross-grade-question')), findsOneWidget);
    expect(app.state.grade, 2);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final back = find.byKey(const ValueKey('learning-back-to-subjects'));
    await tester.scrollUntilVisible(back, -200,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.pump();
    expect(find.text('Themen · Mathematik'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
