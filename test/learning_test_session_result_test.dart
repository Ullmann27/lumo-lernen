import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/test_result_repository.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

/// Tests-Bildschirm (Bild 05): Die gewählte Schwierigkeit bestimmt die
/// Klassenstufe der Aufgaben, und das Ergebnis eines fertigen Tests wird
/// gespeichert.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  Future<LumoAppState> open(WidgetTester tester,
      {required int grade,
      required int level,
      String subject = 'Mathematik',
      LumoSessionKind kind = LumoSessionKind.test}) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState(walletRepository: RewardWalletRepository());
    state.update(state.state.copyWith(
      childName: 'Mia',
      grade: grade,
      subject: subject,
      unit: 'Alle',
      sessionKind: kind,
      testLevel: level,
    ));
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LearningContent(appState: state))));
    await tester.pump();
    return state;
  }

  int shownDifficulty(WidgetTester tester) => tester
      .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
      .task
      .difficulty;

  // Der Generator mischt Wiederholungen früherer Klassen bei; die gewählte
  // Stufe ist deshalb die höchste Klasse, aus der Aufgaben kommen.
  testWidgets('die Teststufe begrenzt die Klasse der Aufgaben', (tester) async {
    Future<int> highest(int grade, int level, LumoSessionKind kind) async {
      var top = 0;
      for (var i = 0; i < 6; i++) {
        await open(tester, grade: grade, level: level, kind: kind);
        top = shownDifficulty(tester) > top ? shownDifficulty(tester) : top;
        await tester.pumpWidget(const SizedBox.shrink());
      }
      return top;
    }

    expect(await highest(3, -1, LumoSessionKind.test), lessThanOrEqualTo(2));
    expect(await highest(1, -1, LumoSessionKind.test), 1,
        reason: 'nie unter Klasse 1');
    expect(await highest(1, 1, LumoSessionKind.quickPractice), 1,
        reason: 'nur Tests nutzen die Stufe');
    expect(await highest(3, 1, LumoSessionKind.test), lessThanOrEqualTo(4));
  });

  testWidgets('ein fertiger Test speichert sein Ergebnis', (tester) async {
    // Englisch hat nur Auswahlaufgaben; Mathe enthält auch Zeichenaufgaben.
    final state = await open(tester, grade: 1, level: 0, subject: 'Englisch');
    for (var i = 0; i < kLumoTestQuestions; i++) {
      // Beim Aufgabenwechsel blendet die alte Aufgabe noch aus.
      await tester.pump(const Duration(seconds: 1));
      final renderer = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer).last);
      final right = renderer.task.options.firstWhere((option) =>
          '${option.payload ?? option.label}' ==
          '${renderer.task.correctAnswer}');
      await tester.tap(find
          .descendant(
              of: find.byType(AdaptiveTaskRenderer).last,
              matching: find.text(right.label))
          .last);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
    }
    expect(find.text('Einheit beendet'), findsOneWidget);
    final summary =
        await tester.runAsync(() => const TestResultRepository().load('Mia'));
    expect(summary!.last!.subject, 'Englisch');
    expect(summary.last!.correct, kLumoTestQuestions);
    expect(summary.last!.total, kLumoTestQuestions);
    await state.flushRewards();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
