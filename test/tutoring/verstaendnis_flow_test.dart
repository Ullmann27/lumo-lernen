// Lumo erkennt Verständnis – in der echten Lernseite (LearningContent).
//
// Nach einer Hilfe kommt eine ähnliche Aufgabe; ihre erste Antwort wird als
// Vergleichsaufgabe mit Bezug zur Ausgangsaufgabe gespeichert. Nur ohne Hilfe
// richtig ist sie ein Indiz. „Hilf mir“ wechselt die Erklärweise, statt
// denselben Hinweis zu wiederholen – auch bei der ähnlichen Aufgabe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/competency.dart';
import 'package:lumo_lernen/domain/tutoring/verstaendnis.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_mistake_help_card.dart';
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

String _value(AnswerOption option) => '${option.payload ?? option.label}';

List<AnswerOption> _wrongOptions(TaskInstance task) => task.options
    .where((option) => _value(option) != '${task.correctAnswer}')
    .toList();

AnswerOption _rightOption(TaskInstance task) => task.options
    .firstWhere((option) => _value(option) == '${task.correctAnswer}');

Future<void> _tap(WidgetTester tester, AnswerOption option) async {
  final target = find
      .descendant(
          of: find.byType(AdaptiveTaskRenderer),
          matching: find.text(option.label))
      .last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _next(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pump(const Duration(milliseconds: 400));
  await _settle(tester, 2);
}

Future<void> _solve(WidgetTester tester) async {
  final renderer = _renderer(tester);
  renderer.onAnswered!(AdaptiveTaskAnswer(
      task: renderer.task, answer: renderer.task.correctAnswer, correct: true));
  await tester.pump();
  await _next(tester);
}

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

String _methode(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('lumo-hint-method'))).data!;

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

  testWidgets(
      'nach Hilfe: ähnliche Aufgabe allein richtig → Vergleichsaufgabe mit '
      'Bezug gespeichert, erstes Anzeichen', (tester) async {
    final app = await _open(tester);
    final source = _renderer(tester).task;
    await _tap(tester, _wrongOptions(source).first);
    await _tap(tester, _rightOption(_renderer(tester).task));
    await _next(tester);
    await _solve(tester); // Aufgabe 2
    expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
    final twin = _renderer(tester).task;
    await _tap(tester, _rightOption(twin));
    expect(find.text('Jetzt allein geschafft!'), findsOneWidget);

    final log = await _log(tester, app);
    final vergleich =
        log.where((a) => a.check == Attempt.vergleichNachHilfe).toList();
    expect(vergleich, hasLength(1));
    expect(vergleich.single.prompt, twin.prompt);
    expect(vergleich.single.reference, source.prompt,
        reason: 'nachvollziehbar: worauf sich der Nachweis bezieht');
    expect(
        vergleich.single.competency,
        const CompetencyClassifier().classify(
            subject: 'Mathematik', unit: 'Plus bis 10', prompt: source.prompt));
    expect(vergleich.single.correct, isTrue);
    expect(vergleich.single.hintUsed, isFalse);
    expect(vergleich.single.confirmsAfterHelp, isTrue);
    // Die übrigen Antworten sind gewöhnliche Antworten.
    expect(log.where((a) => a.check == null), hasLength(log.length - 1));
    final indiz = VerstaendnisIndiz.aus(log,
        kompetenz: vergleich.single.competency, fach: 'Mathematik');
    expect(indiz.stufe, VerstaendnisStufe.erstesAnzeichen,
        reason: 'eine Aufgabe ist nur ein erstes Anzeichen');
  });

  testWidgets(
      'ähnliche Aufgabe mit Tipp gelöst: gespeichert, aber kein Indiz',
      (tester) async {
    final app = await _open(tester);
    final source = _renderer(tester).task;
    await _tap(tester, _wrongOptions(source).first);
    await _tap(tester, _rightOption(_renderer(tester).task));
    await _next(tester);
    await _solve(tester);
    expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
    final twin = _renderer(tester).task;
    final tipp = find.byKey(const ValueKey('lesson-hint-button'));
    await tester.ensureVisible(tipp);
    await tester.tap(tipp);
    await tester.pump();
    await _tap(tester, _rightOption(twin));

    final log = await _log(tester, app);
    final vergleich =
        log.singleWhere((a) => a.check == Attempt.vergleichNachHilfe);
    expect(vergleich.hintUsed, isTrue);
    expect(vergleich.confirmsAfterHelp, isFalse);
    expect(
        VerstaendnisIndiz.aus(log,
                kompetenz: vergleich.competency, fach: 'Mathematik')
            .hatIndiz,
        isFalse);
  });

  testWidgets(
      '„Hilf mir“ mehrmals: jedes Mal eine andere Erklärweise, nie zweimal '
      'derselbe Hinweis, kein Ergebnis', (tester) async {
    await _open(tester, grade: 2, unit: 'Plus bis 100');
    final task = _renderer(tester).task;
    final ergebnis = '${task.correctAnswer}';
    final texte = <String>[];
    final methoden = <String>[];
    for (var i = 0; i < 7; i++) {
      await _hilfMir(tester);
      texte.add(_hinweis(tester));
      methoden.add(_methode(tester));
    }
    for (var i = 1; i < texte.length; i++) {
      expect(texte[i], isNot(texte[i - 1]), reason: 'Hilfe ${i + 1}');
      expect(methoden[i], isNot(methoden[i - 1]));
    }
    expect(methoden.first, 'Kleiner Tipp');
    expect(methoden.toSet().length, greaterThanOrEqualTo(5),
        reason: '$methoden');
    for (final t in texte) {
      expect(RegExp('(^|[^0-9])$ergebnis([^0-9]|\$)').hasMatch(t), isFalse,
          reason: '${task.prompt}: „$t“');
    }
  });

  testWidgets(
      'Methodenwechsel: bei der ähnlichen Aufgabe beginnt Lumo mit einer '
      'anderen Erklärweise', (tester) async {
    await _open(tester);
    final source = _renderer(tester).task;
    await _hilfMir(tester);
    expect(_methode(tester), 'Kleiner Tipp');
    await _tap(tester, _wrongOptions(source).first);
    await _tap(tester, _rightOption(_renderer(tester).task));
    await _next(tester);
    await _solve(tester);
    expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
    await _hilfMir(tester);
    expect(_methode(tester), isNot('Kleiner Tipp'),
        reason: 'Der kleine Tipp hat bei der ähnlichen Aufgabe nicht '
            'geholfen – Lumo erklärt jetzt anders.');
  });

  for (final kind in [LumoSessionKind.test, LumoSessionKind.schoolwork]) {
    testWidgets('${kind.name}: keine Hilfe, kein Methodenwechsel, keine '
        'Vergleichsaufgabe', (tester) async {
      final app = await _open(tester, kind: kind);
      expect(find.widgetWithText(OutlinedButton, 'Hilf mir'), findsNothing);
      expect(find.byKey(const ValueKey('lesson-hint-button')), findsNothing);
      expect(_renderer(tester).nextHelp, isNull);
      final task = _renderer(tester).task;
      await _tap(tester, _wrongOptions(task).first);
      final log = await _log(tester, app);
      expect(log.where((a) => a.check != null), isEmpty);
      expect(log.where((a) => a.method != null), isEmpty);
    });
  }
}
