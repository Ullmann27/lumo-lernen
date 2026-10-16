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

    await tester.ensureVisible(find.byKey(const ValueKey('grade-pill-3')));
    await tester.tap(find.byKey(const ValueKey('grade-pill-3')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3. Klasse – dein Lernstoff'), findsOneWidget);
    expect(find.text('Mathematik · Zahlen bis 1000'), findsOneWidget);
    expect(find.text('Deutsch · Wortarten'), findsOneWidget);
    expect(find.text('Sachunterricht · Österreich'), findsOneWidget);
    expect(find.byKey(const ValueKey('academy-grade-icon-mathe3')), findsOneWidget);
    expect(find.byKey(const ValueKey('academy-grade-icon-deutsch3')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('grade-pill-4')));
    await tester.tap(find.byKey(const ValueKey('grade-pill-4')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4. Klasse – frei lernen'), findsOneWidget);
    expect(find.text('Mathematik · Zahlen bis 1 Million'), findsOneWidget);
    expect(find.text('Deutsch · Grammatik'), findsOneWidget);
    expect(find.text('Sachunterricht · Kontinente und Ozeane'), findsOneWidget);
    expect(find.text('Mathematik · Zahlen bis 1000'), findsNothing);
    // Grade selection opens practice without changing the enrolled grade.
    expect(app.state.grade, 3);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  for (final entry in [
    (grade: 3, subject: 'deutsch3', unit: 'Wortarten'),
    (grade: 4, subject: 'deutsch4', unit: 'Die 4 Fälle'),
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
      final focus = find.byKey(ValueKey('academy-grade-focus-${entry.subject}'));
      await tester.scrollUntilVisible(
        focus,
        220,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 25,
      );
      await tester.pump();
      await tester.tap(focus);
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
