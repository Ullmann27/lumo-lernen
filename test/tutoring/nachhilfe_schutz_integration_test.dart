import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/tutoring/lumo_nachhilfe_screen.dart';

/// Echte Lernseite: In Tests und Schularbeiten gibt es keine Nachhilfe und
/// keine lösungsverratenden Hilfen; beim Üben öffnet sie für die neuen
/// Themen, und nur die eigenständige Prüfaufgabe wird als Antwort gebucht.
Future<void> _frames(WidgetTester tester, [int count = 30]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<LumoAppState> _app(WidgetTester tester,
    {required int grade,
    required String unit,
    required LumoSessionKind kind}) async {
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(
        grade: grade,
        subject: 'Mathematik',
        unit: unit,
        sessionKind: kind,
        section: LumoSection.learn));
    await app.school.setActiveStudent('nachhilfe-schutz-$unit-${kind.name}');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
  });
  return app;
}

/// Öffnet Aufgaben mit wachsendem Seed, bis eine geprüfte Rechnung kommt.
Future<TaskInstance?> _rechenaufgabe(
    WidgetTester tester, LumoAppState app) async {
  for (var seed = 0; seed < 8; seed++) {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LearningContent(
                key: ValueKey('seed-$seed'), appState: app, taskSeed: seed))));
    await _frames(tester);
    final renderer = find.byType(AdaptiveTaskRenderer);
    if (renderer.evaluate().isEmpty) continue;
    final task = tester.widget<AdaptiveTaskRenderer>(renderer).task;
    if (NachhilfeAufgabe.ausTask(task) != null) return task;
  }
  return null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final kind in [LumoSessionKind.test, LumoSessionKind.schoolwork]) {
    for (final (grade, unit) in [(1, 'Plus bis 10'), (2, 'Einmaleins')]) {
      testWidgets('${kind.name} $unit: keine Nachhilfe, keine Hilfe-Knöpfe',
          (tester) async {
        LumoAppState? app;
        try {
          await tester.binding.setSurfaceSize(const Size(690, 1400));
          app = await _app(tester, grade: grade, unit: unit, kind: kind);
          final task = await _rechenaufgabe(tester, app);
          expect(task, isNotNull,
              reason: 'In acht Aufgaben muss eine reine Rechnung sein.');
          expect(find.byKey(const ValueKey('nachhilfe-open')), findsNothing);
          expect(find.text('Schritt für Schritt mit Lumo'), findsNothing);
          expect(find.text('Hilf mir'), findsNothing);
          expect(find.byType(LumoNachhilfeScreen), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          app?.dispose();
          await tester.binding.setSurfaceSize(null);
        }
      });
    }
  }

  testWidgets(
      'Üben Einmaleins: Nachhilfe öffnet; nur die eigenständige Prüfaufgabe '
      'wird gebucht, ohne Sterne oder XP', (tester) async {
    LumoAppState? app;
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1400));
      app = await _app(tester,
          grade: 2, unit: 'Einmaleins', kind: LumoSessionKind.quickPractice);
      final task = await _rechenaufgabe(tester, app);
      expect(task, isNotNull);
      final aufgabe = NachhilfeAufgabe.ausTask(task!)!;
      final vorher = (app.state.stars, app.state.xp);
      final entry = find.byKey(const ValueKey('nachhilfe-open'));
      expect(entry, findsOneWidget, reason: task.prompt);
      await tester.ensureVisible(entry);
      await tester.pump();
      await tester.tap(entry);
      await _frames(tester, 40);
      final screen = find.byType(LumoNachhilfeScreen);
      expect(screen, findsOneWidget);
      expect(tester.widget<LumoNachhilfeScreen>(screen).aufgabe, aufgabe);
      expect(find.byKey(const ValueKey('nachhilfe-3d')), findsNothing,
          reason: '3D gibt es nur für Plus bis 20.');

      // Stufe 5: eigenständige Prüfaufgabe.
      final stufe5 = find.byKey(const ValueKey('nachhilfe-stufe-ueben'));
      await tester.ensureVisible(stufe5);
      await tester.tap(stufe5);
      await _frames(tester, 5);
      const tutor = LumoNachhilfe();
      final twin = tutor
          .plan(aufgabe, tutor.wegFuer(aufgabe), NachhilfeStufe.ueben)
          .aufgabe;
      expect(find.text('${twin.text} = ?'), findsOneWidget);
      for (final z in '${twin.ergebnis}'.split('')) {
        final taste = find.byKey(ValueKey('nachhilfe-ziffer-$z'));
        await tester.ensureVisible(taste);
        await tester.tap(taste);
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('nachhilfe-ziffer-ok')));
      await _frames(tester, 20);
      expect(find.text('Richtig! Das hast du ganz allein gelöst.'),
          findsOneWidget);
      await tester.runAsync(() async {
        await app!.flushAttemptLog();
      });
      final attempts = (await tester.runAsync(() => app!.attemptLog.load()))!;
      final gebucht =
          attempts.where((a) => a.prompt == '${twin.text} = ?').toList();
      expect(gebucht, hasLength(1));
      expect(gebucht.single.correct, isTrue);
      expect(gebucht.single.hintUsed, isFalse,
          reason: 'Allein beim ersten Versuch gelöst.');
      expect(attempts.where((a) => a.prompt == task.prompt), isEmpty,
          reason: 'Die Originalaufgabe bleibt offen.');

      final zurueck = find.byKey(const ValueKey('nachhilfe-zur-aufgabe'));
      await tester.ensureVisible(zurueck);
      await tester.tap(zurueck);
      await _frames(tester, 40);
      expect(find.byType(LumoNachhilfeScreen), findsNothing);
      final danach = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      expect(danach.taskInstanceId, task.taskInstanceId);
      expect((app.state.stars, app.state.xp), vorher);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });
}
