// Fach-Nachhilfe Englisch, Lesen und Sachunterricht in der echten Lernseite:
// Einstieg nur beim Üben (nie in Tests/Schularbeiten), Prüfaufgabe als
// Vergleichsaufgabe nach Hilfe gespeichert, „Hilf mir“ wechselt die
// Erklärweise ohne die Lösung zu verraten.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/tutoring/fach_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/features/tutoring/fach_nachhilfe_screen.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _quiet = AppSettings(
  aiProxyEnabled: false,
  voiceEnabled: false,
  autoReadEnabled: false,
  soundEnabled: false,
  reduceAnimations: true,
);

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _drain(WidgetTester tester, LumoAppState app) async {
  var done = false;
  unawaited(Future.wait<void>([
    app.flushLearningProgress(),
    app.flushTutorEvidence(),
  ]).then<void>((_) {}, onError: (Object _) {}).whenComplete(() => done = true));
  for (var round = 0; round < 600 && !done; round++) {
    await _settle(tester, 1);
  }
  expect(done, isTrue, reason: 'learning storage did not finish');
  await _settle(tester, 4);
}

Future<LumoAppState> _open(WidgetTester tester,
    {int grade = 1,
    String subject = 'Mathematik',
    String unit = 'Plus bis 10',
    LumoSessionKind kind = LumoSessionKind.quickPractice}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.ensureSettingsLoaded();
    await app.loadLearningProfile();
    app.updateSettings(_quiet);
    app.update(app.state.copyWith(
      childName: 'Mira',
      grade: grade,
      subject: subject,
      unit: unit,
      sessionKind: kind,
      testLevel: 0,
    ));
  });
  await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LearningContent(appState: app))));
  await _settle(tester);
  addTearDown(() async {
    await _drain(tester, app);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester, 4);
    app.dispose();
    LumoCompanionRequests.instance.clearLearningScope();
  });
  return app;
}

AdaptiveTaskRenderer _renderer(WidgetTester tester) =>
    tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));

/// „Hilf mir“ in Lumos Lernknöpfen.
Future<void> _hilfMir(WidgetTester tester) async {
  final button = find.widgetWithText(OutlinedButton, 'Hilf mir');
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await _settle(tester, 2);
}

String _hinweis(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('lumo-hint-readable-text')))
    .data!;

Future<List<Attempt>> _log(WidgetTester tester, LumoAppState app) async {
  await _drain(tester, app);
  return (await tester.runAsync(() => app.attemptLog.load()))!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LumoVoiceClips.ensureFreeLoaded);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final (fach, stufe, thema) in [
    ('Englisch', 1, 'Tiere'),
    ('Lesen', 2, 'Sätze lesen'),
    ('Sachunterricht', 3, 'Wasserkreislauf'),
  ]) {
    testWidgets(
        '$fach: Schritt für Schritt mit Lumo öffnet die Fach-Nachhilfe; '
        'Prüfaufgabe = Vergleichsaufgabe mit Bezug, keine Sterne',
        (tester) async {
      final app =
          await _open(tester, grade: stufe, subject: fach, unit: thema);
      final task = _renderer(tester).task;
      final vorher = (app.state.stars, app.state.xp);
      final open = find.byKey(const ValueKey('fach-nachhilfe-open'));
      expect(open, findsOneWidget, reason: task.prompt);
      expect(find.byKey(const ValueKey('nachhilfe-open')), findsNothing);
      await tester.ensureVisible(open);
      await tester.pump();
      await tester.tap(open);
      await _settle(tester, 20);
      final screen = find.byType(FachNachhilfeScreen);
      expect(screen, findsOneWidget);
      final widget = tester.widget<FachNachhilfeScreen>(screen);
      expect(widget.aufgabe.prompt, task.prompt);
      expect(widget.pruefung, isNotNull);
      expect(widget.pruefung!.antwort, isNot(widget.aufgabe.antwort));
      // Stufe 5: ähnliche Aufgabe ganz allein.
      final stufe5 = find.byKey(const ValueKey('fach-stufe-ueben'));
      await tester.ensureVisible(stufe5);
      await tester.tap(stufe5);
      await tester.pump(const Duration(milliseconds: 50));
      final p = widget.pruefung!;
      final richtig = find.byKey(ValueKey('fach-pruef-${p.antwort}'));
      await tester.ensureVisible(richtig);
      await tester.tap(richtig);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Richtig! Das hast du ganz allein gelöst.'),
          findsOneWidget);
      final zurueck = find.byKey(const ValueKey('fach-zur-aufgabe'));
      await tester.ensureVisible(zurueck);
      await tester.pump();
      await tester.tap(zurueck);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester, 4);
      expect(find.byType(FachNachhilfeScreen), findsNothing);
      final log = await _log(tester, app);
      final v = log.singleWhere((a) => a.check == Attempt.vergleichNachHilfe);
      expect(v.subject, fach);
      expect(v.prompt, p.prompt);
      expect(v.reference, task.prompt);
      expect(v.confirmsAfterHelp, isTrue);
      expect((app.state.stars, app.state.xp), vorher);
      // Die Originalaufgabe ist weiter offen und zählt jetzt als mit Hilfe.
      expect(find.byType(AdaptiveTaskRenderer), findsOneWidget);
      expect(_renderer(tester).task.prompt, task.prompt);
    });

    testWidgets('$fach: „Hilf mir“ – jedes Mal anders, nie die Lösung',
        (tester) async {
      await _open(tester, grade: stufe, subject: fach, unit: thema);
      final task = _renderer(tester).task;
      final aufgabe = FachAufgabe.aus(
          fach: fach,
          thema: thema,
          prompt: task.prompt,
          antwort: '${task.correctAnswer}',
          auswahl: [for (final o in task.options) o.label])!;
      final texte = <String>[];
      for (var i = 0; i < 6; i++) {
        await _hilfMir(tester);
        texte.add(_hinweis(tester));
      }
      for (var i = 1; i < texte.length; i++) {
        expect(texte[i], isNot(texte[i - 1]));
      }
      expect(texte.toSet().length, greaterThanOrEqualTo(5));
      for (final t in texte.skip(3)) {
        // Die Fach-Erklärweisen (ab der vierten Hilfe) verraten nichts.
        expect(const FachNachhilfe().verraet(t, aufgabe), isFalse,
            reason: '${task.prompt}: „$t“');
      }
    });

    for (final kind in [LumoSessionKind.test, LumoSessionKind.schoolwork]) {
      testWidgets('$fach ${kind.name}: keine Fach-Nachhilfe, keine Hilfe',
          (tester) async {
        await _open(tester,
            grade: stufe, subject: fach, unit: thema, kind: kind);
        expect(find.byKey(const ValueKey('fach-nachhilfe-open')), findsNothing);
        expect(find.widgetWithText(OutlinedButton, 'Hilf mir'), findsNothing);
        expect(find.byType(FachNachhilfeScreen), findsNothing);
        expect(_renderer(tester).nextHelp, isNull);
      });
    }
  }

  test('Startstufe wie Mathe: nach drei Versuchen zeigt Lumo', () {
    expect(const FachNachhilfe().startStufe(versuche: 3),
        NachhilfeStufe.vorzeigen);
  });
}
