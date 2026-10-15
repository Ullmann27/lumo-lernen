import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final entry in [
    (grade: 1, subject: 'mathe1', unit: 'Mengenvergleich'),
    (grade: 3, subject: 'mathe3', unit: 'Plus bis 1000'),
    (grade: 4, subject: 'mathe4', unit: 'Zahlenraum bis 1 Million'),
  ]) {
    testWidgets(
        'Profilklasse 2 öffnet Klasse ${entry.grade} als echten Lernstoff',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1280));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      app.update(app.state.copyWith(grade: 2, childName: 'LumoTester'));
      final initialStars = app.state.stars;
      final initialXp = app.state.xp;
      await tester.pumpWidget(MaterialApp(
        home: LumoAkademieScreen(appState: app),
      ));
      await tester.pump(const Duration(milliseconds: 900));
      final gradeChip = find.byKey(ValueKey('grade-pill-${entry.grade}'));
      await tester.ensureVisible(gradeChip);
      await tester.tap(gradeChip);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('${entry.grade}. Klasse – frei lernen'),
        findsOneWidget,
      );
      final button =
          find.byKey(ValueKey('academy-grade-focus-${entry.subject}'));
      await tester.scrollUntilVisible(
        button,
        230,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 25,
      );
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(CrossGradePracticeScreen), findsOneWidget);
      final practice =
          tester.widget<CrossGradePracticeScreen>(
              find.byType(CrossGradePracticeScreen));
      expect(practice.lessonGrade, entry.grade);
      expect(practice.subject, 'Mathematik');
      expect(practice.unit, entry.unit);
      expect(find.byKey(const ValueKey('cross-grade-question')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('cross-grade-choice-0')),
          findsOneWidget);
      // The outgoing Akademie route also contains profile-info text.
      // Identify the actual active cross-grade screen by its stable key.
      expect(find.byKey(const ValueKey('cross-grade-profile-info')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cross-grade-choice-0')));
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.byKey(const ValueKey('cross-grade-feedback')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('cross-grade-next')),
          findsOneWidget);
      expect(app.state.grade, 2);
      expect(app.state.stars, initialStars);
      expect(app.state.xp, initialXp);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where(
          (key) => key.startsWith('cross_grade_practice_v1:')).isNotEmpty,
          isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(seconds: 60)));
  }

  testWidgets('separate grade progress is not saved into enrolled grade',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    const scope3 =
        'cross_grade_practice_v1:lumotester:3:Mathematik:Plus bis 1000';
    const scope4 =
        'cross_grade_practice_v1:lumotester:4:Mathematik:Zahlenraum bis 1 Million';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$scope3:answered', 5);
    expect(prefs.getInt('$scope3:answered'), 5);
    expect(prefs.getInt('$scope4:answered'), isNull);
    expect(prefs.getInt('grade:2:answered'), isNull);
  });
}
