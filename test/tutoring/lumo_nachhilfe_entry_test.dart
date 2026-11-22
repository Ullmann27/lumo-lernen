import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/tutoring/lumo_nachhilfe_screen.dart';

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<LumoAppState> _app(WidgetTester tester, String unit) async {
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(
        grade: 1,
        subject: 'Mathematik',
        unit: unit,
        sessionKind: LumoSessionKind.quickPractice,
        section: LumoSection.learn));
    await app.school.setActiveStudent('nachhilfe-entry-child');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
  });
  return app;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'Plus-Aufgabe bietet Schritt für Schritt mit Lumo an; Rückkehr lässt '
      'Aufgabe, Sterne und XP unverändert', (tester) async {
    LumoAppState? app;
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1400));
      app = await _app(tester, 'Plus bis 10');
      // Seed 1 öffnet eine Plus-Aufgabe mit zwei Summanden ab 1.
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: LearningContent(appState: app, taskSeed: 1))));
      await _frames(tester, 40);
      final task = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      final aufgabe = NachhilfeAufgabe.ausTask(task);
      expect(aufgabe, isNotNull,
          reason: 'Seed 1 muss eine Plus-Aufgabe öffnen: "${task.prompt}"');
      final before = (app.state.stars, app.state.xp);

      final entry = find.byKey(const ValueKey('nachhilfe-open'));
      expect(entry, findsOneWidget);
      expect(find.text('Schritt für Schritt mit Lumo'), findsOneWidget);
      await tester.ensureVisible(entry);
      await tester.pump();
      await tester.tap(entry);
      await _frames(tester, 40);

      final screen = find.byType(LumoNachhilfeScreen);
      expect(screen, findsOneWidget);
      expect(tester.widget<LumoNachhilfeScreen>(screen).aufgabe.text,
          aufgabe!.text);
      // Beide Einstiege sind verbunden. Hier bleibt der direkte 2D-Rückweg
      // geprüft; der tatsächliche 3D-Launch samt Rückgabe hat einen eigenen
      // Vertrag in lumo_nachhilfe_3d_test.dart.
      expect(tester.widget<LumoNachhilfeScreen>(screen).open3D, isNotNull);
      expect(find.byKey(const ValueKey('nachhilfe-3d')), findsOneWidget);
      // Die Lösung der Originalaufgabe steht nirgends auf dem Schirm.
      expect(find.text('${aufgabe.text} = ${aufgabe.ergebnis}'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('nachhilfe-zurueck')));
      await _frames(tester, 40);
      expect(find.byType(LumoNachhilfeScreen), findsNothing);
      final after = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      expect(after.taskInstanceId, task.taskInstanceId,
          reason: 'Das Kind kehrt zu genau derselben Aufgabe zurück.');
      expect((app.state.stars, app.state.xp), before,
          reason: 'Die Nachhilfe bucht weder Sterne noch XP.');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Aufgabe ohne geprüfte Plus-Rechnung zeigt keinen Einstieg',
      (tester) async {
    LumoAppState? app;
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1400));
      app = await _app(tester, 'Plus bis 10');
      // Seed 0 öffnet eine Summe mit null: dafür gibt es keinen Nachhilfeplan.
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: LearningContent(appState: app, taskSeed: 0))));
      await _frames(tester, 40);
      final task = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      expect(NachhilfeAufgabe.ausTask(task), isNull,
          reason: '"${task.prompt}" hat keinen Nachhilfeplan');
      expect(find.byKey(const ValueKey('nachhilfe-open')), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });
}
