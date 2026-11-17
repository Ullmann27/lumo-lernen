import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/learning_modules/wortarten/wortarten_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets('grade picker visibly distinguishes 3rd and 4th-class topics',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 880));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(grade: 3));
    await tester.pumpWidget(MaterialApp(
      home: LumoAkademieScreen(appState: app),
    ));
    await tester.pump(const Duration(milliseconds: 900));
    for (final entry in [
      (
        grade: 3,
        math: 'Plus bis 1000',
        german: 'Wortarten',
        science: 'Bundesländer Österreichs'
      ),
      (
        grade: 4,
        math: 'Zahlenraum bis 1 Million',
        german: 'Die 4 Fälle',
        science: 'Kontinente und Ozeane'
      ),
    ]) {
      await tester
          .ensureVisible(find.byKey(ValueKey('grade-pill-${entry.grade}')));
      await tester.tap(find.byKey(ValueKey('grade-pill-${entry.grade}')));
      await tester.pump();
      expect(
          find.text(entry.grade == 3
              ? '3. Klasse · aus deinem Profil'
              : '4. Klasse · frei lernen'),
          findsOneWidget);
      for (final topic in [
        (subject: 'Mathematik', unit: entry.math),
        (subject: 'Deutsch', unit: entry.german),
        (subject: 'Sachunterricht', unit: entry.science),
      ]) {
        final subject =
            find.byKey(ValueKey('learning-subject-${topic.subject}'));
        await tester.ensureVisible(subject);
        await tester.tap(subject);
        await tester.pump();
        final unit = find
            .byKey(ValueKey('learning-unit-${topic.subject}-${topic.unit}'));
        await tester.scrollUntilVisible(unit, 180,
            scrollable: find.byType(Scrollable).first, maxScrolls: 25);
        expect(unit, findsOneWidget);
        if (entry.grade == 4 && topic.subject == 'Mathematik') {
          expect(
              find.byKey(
                  const ValueKey('learning-unit-Mathematik-Plus bis 1000')),
              findsNothing);
        }
        final back = find.byKey(const ValueKey('learning-back-to-subjects'));
        await tester.scrollUntilVisible(back, -180,
            scrollable: find.byType(Scrollable).first, maxScrolls: 25);
        await Scrollable.ensureVisible(tester.element(back), alignment: .5);
        await tester.pump();
        expect(back.hitTestable(), findsOneWidget);
        await tester.tap(back);
        await tester.pump();
      }
    }
    // Grade selection opens practice without changing the enrolled grade.
    expect(app.state.grade, 3);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  for (final entry in [
    (grade: 3, unit: 'Wortarten'),
    (grade: 4, unit: 'Die 4 Fälle'),
  ]) {
    testWidgets('class ${entry.grade} German focus opens its real lesson',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1280));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      app.update(app.state.copyWith(grade: entry.grade));
      await tester.pumpWidget(MaterialApp(
        home: LumoAkademieScreen(appState: app),
      ));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.tap(find.byKey(ValueKey('grade-pill-${entry.grade}')));
      await tester.pump();
      final subject = find.byKey(const ValueKey('learning-subject-Deutsch'));
      await tester.ensureVisible(subject);
      await tester.tap(subject);
      await tester.pump();
      final topic = find.byKey(ValueKey('learning-unit-Deutsch-${entry.unit}'));
      await tester.scrollUntilVisible(topic, 180,
          scrollable: find.byType(Scrollable).first, maxScrolls: 25);
      await tester.pump();
      await tester.tap(topic);
      // Navigator pushes a dedicated Flutter route for the third-grade
      // lesson. Its first frame is built offstage (the HeroController
      // measures it), so one frame must run before the transition, otherwise
      // the new screen exists only offstage and find.byType skips it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      expect(app.state.grade, entry.grade);
      if (entry.grade == 3) {
        // Class 3 has a dedicated, interactive Wortarten module. Opening it
        // through Navigator leaves the enclosing app section unchanged.
        expect(find.byType(WortartenScreen), findsOneWidget);
      } else {
        // Class 4 grammar intentionally launches the generator-backed unit.
        expect(app.state.section, LumoSection.exercises);
        expect(app.state.subject, 'Deutsch');
        expect(app.state.unit, entry.unit);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    });
  }
}
