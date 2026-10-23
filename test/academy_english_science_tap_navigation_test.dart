import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final item in [
    (
      grade: 3,
      subject: 'Sachunterricht',
      topic: 'Österreich',
      unit: 'Bundesländer Österreichs'
    ),
    (grade: 4, subject: 'Englisch', topic: 'Verben', unit: 'Verben'),
  ]) {
    testWidgets(
        'Academy ${item.grade}: tapping ${item.subject}/${item.topic} starts actual task',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1280));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      app.update(app.state.copyWith(grade: item.grade));
      await tester.pumpWidget(MaterialApp(
        home: LumoAkademieScreen(appState: app),
      ));
      await tester.pump(const Duration(milliseconds: 900));
      final gradeChip = find.byKey(ValueKey('grade-pill-${item.grade}'));
      expect(gradeChip, findsOneWidget);
      await tester.ensureVisible(gradeChip);
      await tester.tap(gradeChip);
      await tester.pump(const Duration(milliseconds: 400));

      final subject = find.byKey(ValueKey('learning-subject-${item.subject}'));
      await tester.ensureVisible(subject);
      await tester.tap(subject);
      await tester.pump(const Duration(milliseconds: 400));

      await tester.scrollUntilVisible(
        find.byKey(ValueKey('learning-unit-${item.subject}-${item.unit}')),
        240,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 35,
      );
      await tester.pump();
      await tester.tap(
          find.byKey(ValueKey('learning-unit-${item.subject}-${item.unit}')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(app.state.grade, item.grade);
      expect(app.state.subject, item.subject);
      expect(app.state.unit, item.unit);
      expect(app.state.section, LumoSection.exercises);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app.dispose();
    }, timeout: const Timeout(Duration(seconds: 45)));
  }
}
