import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/lumo_nachhilfe.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';
import 'package:lumo_lernen/features/tutoring/lumo_nachhilfe_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _channel = MethodChannel('lumo_lernen/bridge');
const _codec = StandardMethodCodec();

/// Aufgaben der Godot-Fixtures: 8 + 5 und 6 + 7 (Auftrag) und 3 + 9, damit
/// auch der Weg „Tauschen“ einmal mit echten App-Daten läuft.
const _faelle = [
  (
    name: 'acht_plus_fuenf',
    a: 8,
    b: 5,
    weg: NachhilfeWeg.rechenrahmen,
    stufe: NachhilfeStufe.hinweis,
    fehler: NachhilfeFehlermuster.zehnerVergessen,
  ),
  (
    name: 'sechs_plus_sieben',
    a: 6,
    b: 7,
    weg: NachhilfeWeg.zahlenstrahl,
    stufe: NachhilfeStufe.teilschritt,
    fehler: NachhilfeFehlermuster.einsDaneben,
  ),
  (
    name: 'drei_plus_neun',
    a: 3,
    b: 9,
    weg: NachhilfeWeg.tauschen,
    stufe: NachhilfeStufe.vorzeigen,
    fehler: NachhilfeFehlermuster.keines,
  ),
];

Future<void> _frames(WidgetTester tester, [int count = 40]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => LumoCompanionRequests.instance.clearLearningScope());

  testWidgets(
      'Startweg der 3D-Nachhilfe: echter launchLumo3D-Payload übersteht '
      'Codec und JSON (Fixture für Godot)', (tester) async {
    final exported = <Map<String, Object?>>[];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      for (final fall in _faelle) {
        SharedPreferences.setMockInitialValues(
            {'lumo_3d_save_salt_v1': 'synthetic-tutor-fixture'});
        final app = (await tester.runAsync(() async {
          final state =
              LumoAppState(walletRepository: RewardWalletRepository());
          state.update(state.state.copyWith(grade: 1, subject: 'Mathematik'));
          await state.school.setActiveStudent('synthetic-${fall.name}');
          await state.hydrateFromWallet();
          await state.loadLearningProfile();
          state.updateSettings(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              reduceAnimations: true));
          return state;
        }))!;
        try {
          final aufgabe = NachhilfeAufgabe.addition(fall.a, fall.b)!;
          final taskId = 'synthetic-tutor-${fall.name}';
          // Wie LearningContent._openNachhilfe3D: Die Nachhilfe-Seite liegt
          // über der Aufgabe, dort ist kein Lern-Scope veröffentlicht. Die
          // Sitzung trägt die Aufgaben-ID selbst; Android bildet daraus den
          // Scope (MainActivity), die Szene meldet sie zurück.
          final activity = NativeLearningActivity.fromNachhilfe(aufgabe,
                  startWeg: fall.weg,
                  startStufe: fall.stufe,
                  fehler: fall.fehler)!
              .boundToTask(taskId)!;
          expect(LumoCompanionRequests.instance.learningIdentity.value, isNull);
          final calls = <MethodCall>[];
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(_channel, (call) async {
            calls.add(_codec.decodeMethodCall(_codec.encodeMethodCall(call)));
            return <String, Object?>{'destination': 'learn'};
          });
          late BuildContext context;
          await tester.pumpWidget(MaterialApp(
            home: Builder(builder: (value) {
              context = value;
              return const Scaffold(body: Text('Nachhilfe-Fixture'));
            }),
          ));
          final before = (app.state.stars, app.state.xp);
          final launched = launchLumo3D(context,
              scene: 'learning', appState: app, learning: activity);
          await _frames(tester);
          expect(await launched, isTrue, reason: fall.name);
          expect(calls, hasLength(1));
          final arguments =
              Map<String, Object?>.from(calls.single.arguments as Map);
          expect(arguments['scene'], 'learning');
          expect(arguments['learningVoiceEnabled'], isFalse,
              reason: 'Ton aus: die Szene zeigt nur Text');
          final wire = jsonDecode(jsonEncode(arguments['learning']))
              as Map<String, dynamic>;
          expect(wire['kind'], 'tutor');
          expect(wire['typ'], 'addition_20');
          expect((wire['a'], wire['b']), (fall.a, fall.b));
          expect(wire['startWeg'], fall.weg.name);
          expect(wire['startStufe'], fall.stufe.name);
          final wege = const LumoNachhilfe().wegeFuer(aufgabe);
          expect(wire['wege'], [for (final w in wege) w.name]);
          expect(wire['plaene'], hasLength(wege.length * 4));
          expect(wire['sourceTaskId'], taskId);
          expect(wire.containsKey('scope'), isFalse,
              reason: 'kein veröffentlichter Lern-Scope über der Aufgabe');
          expect(wire['allowedActions'], ['stop'],
              reason: 'ohne Scope nur „Stopp“ – keine Gesprächsaktionen');
          // Pläne sind vorberechnet: der ganze Launch bleibt klein genug für
          // Intent-Extra, JSONObject und die Godot-Prüfung.
          final size = utf8.encode(jsonEncode(wire)).length;
          expect(size, lessThan(32000), reason: '${fall.name}: $size Bytes');
          expect((app.state.stars, app.state.xp), before,
              reason: 'Der Start bucht weder Sterne noch XP.');
          exported.add({
            'name': fall.name,
            'bytes': size,
            'learning': wire,
          });
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          LumoCompanionRequests.instance.clearLearningScope();
          app.dispose();
        }
      }
      const destination = String.fromEnvironment('LUMO_TUTOR_FIXTURE_EXPORT');
      if (destination.isNotEmpty) {
        final document = <String, Object>{
          'schema': 1,
          'boundary': 'Echter Dart-Aufruf launchLumo3D, StandardMethodCodec; '
              'jsonEncode bildet Kotlin JSONObject(learning) nach. '
              'Kein Android-IPC-Beleg.',
          'cases': exported,
        };
        File(destination)
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(
              '${const JsonEncoder.withIndent('  ').convert(document)}\n');
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    }
  });

  test(
      'Rückgabe der 3D-Nachhilfe: nur Hilfestufe und Zwilling, nie das Original',
      () {
    Map<String, Object?> summary([Map<String, Object?> change = const {}]) => {
          'resultId': 'tutor-1',
          'taskId': 'task-1',
          'kind': 'tutor',
          'mode': 'rechenrahmen',
          'originalAnswer': '',
          'originalCorrect': false,
          'originalAttempts': 0,
          'hintLevel': 3,
          'twinSolved': true,
          'twinAttempts': 1,
          'twinPrompt': '7 + 6 = ?',
          ...change,
        };
    String wire(Map<String, Object?> value) => jsonEncode(
        {'status': 'illustrated', 'game': 'learning', 'holo': value});
    final parsed = parseLearningResult(wire(summary()));
    expect(parsed, isNotNull);
    expect(parsed!['kind'], 'tutor');
    expect(parsed['twinSolved'], isTrue);
    expect(parsed['originalCorrect'], isFalse);
    for (final broken in <Map<String, Object?>>[
      {'originalCorrect': true, 'originalAnswer': '13'},
      {'originalAnswer': '13'},
      {'originalAttempts': 1},
      {'hintLevel': 4},
      {'mode': 'zaubern'},
      {'mode': null},
      {'kind': 'nachhilfe'},
      {'twinAttempts': 'eins'},
    ]) {
      expect(parseLearningResult(wire(summary(broken))), isNull,
          reason: '$broken');
    }
    // Holo-Räume bleiben bei Hilfestufe höchstens 2.
    expect(
        parseLearningResult(wire(summary({
          'kind': 'holo_word_problem',
          'mode': 'add',
          'hintLevel': 3,
        }))),
        isNull);
  });

  testWidgets(
      'Nachhilfe: „In 3D mit Lumo“ startet die Szene mit dem App-Payload, '
      'kehrt zur selben Aufgabe zurück und bucht keine Sterne/XP',
      (tester) async {
    final calls = <MethodCall>[];
    var resultId = 'tutor-result-1';
    var twinPrompt = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(_codec.decodeMethodCall(_codec.encodeMethodCall(call)));
      if (call.method != 'launch3D') return null;
      final learning =
          Map<String, Object?>.from((call.arguments as Map)['learning'] as Map);
      final plaene = (learning['plaene'] as List).cast<Map>();
      final ueben = plaene.firstWhere((plan) =>
          plan['stufe'] == 'ueben' && plan['weg'] == learning['startWeg']);
      twinPrompt = '${ueben['a']} + ${ueben['b']} = ?';
      // Was die Godot-Szene nach „Selbst üben“ zurückgibt (Format wie der
      // Godot-Regressionstest es prüft); Kotlin reicht es als Text durch.
      // Wie MainActivity: Scope-Aufgabe, sonst die Quellaufgabe.
      final scope = learning['scope'];
      final scopedTask = scope is Map ? '${scope['taskId'] ?? ''}' : '';
      return <String, Object?>{
        'destination': 'learn',
        'learningResult': jsonEncode({
          'resultId': resultId,
          'taskId':
              scopedTask.isNotEmpty ? scopedTask : learning['sourceTaskId'],
          'kind': 'tutor',
          'mode': learning['startWeg'],
          'originalAnswer': '',
          'originalCorrect': false,
          'originalAttempts': 0,
          'hintLevel': 3,
          'twinSolved': true,
          'twinAttempts': 1,
          'twinPrompt': twinPrompt,
        }),
      };
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues(
        {'lumo_3d_save_salt_v1': 'tutor-3d-flow'});
    LumoAppState? app;
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1400));
      await tester.runAsync(() async {
        app = LumoAppState(walletRepository: RewardWalletRepository());
        app!.update(app!.state.copyWith(
            grade: 1,
            subject: 'Mathematik',
            unit: 'Plus bis 10',
            sessionKind: LumoSessionKind.quickPractice,
            section: LumoSection.learn));
        await app!.school.setActiveStudent('nachhilfe-3d-child');
        await app!.hydrateFromWallet();
        await app!.loadLearningProfile();
        app!.updateSettings(const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            reduceAnimations: true));
      });
      // Seed 1 öffnet eine Plus-Aufgabe mit zwei Summanden ab 1.
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: LearningContent(appState: app!, taskSeed: 1))));
      await _frames(tester);
      final task = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      final aufgabe = NachhilfeAufgabe.ausTask(task)!;
      final before = (app!.state.stars, app!.state.xp);

      Future<void> openTutor3D() async {
        final entry = find.byKey(const ValueKey('nachhilfe-open'));
        await tester.ensureVisible(entry);
        await tester.pump();
        await tester.tap(entry);
        await _frames(tester);
        final screen = find.byType(LumoNachhilfeScreen);
        expect(screen, findsOneWidget);
        expect(tester.widget<LumoNachhilfeScreen>(screen).open3D, isNotNull);
        // Lumos Satz steht als Text (Vorlesen-Knopf prüft der Nachhilfe-Test).
        expect(find.byKey(const ValueKey('nachhilfe-text')), findsOneWidget);
        final button = find.byKey(const ValueKey('nachhilfe-3d'));
        expect(button, findsOneWidget);
        expect(find.text('In 3D mit Lumo'), findsOneWidget);
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await _frames(tester, 60);
      }

      await openTutor3D();
      final launches = calls.where((call) => call.method == 'launch3D');
      expect(launches, hasLength(1));
      final arguments =
          Map<String, Object?>.from(launches.single.arguments as Map);
      expect(arguments['scene'], 'learning');
      expect(arguments['learningVoiceEnabled'], isFalse);
      final learning = Map<String, Object?>.from(arguments['learning'] as Map);
      expect(learning['kind'], 'tutor');
      expect((learning['a'], learning['b']), (aufgabe.a, aufgabe.b));
      expect(learning['sourceTaskId'], task.taskInstanceId,
          reason: 'die 3D-Nachhilfe gehört zur offenen Aufgabe');
      expect(learning['startWeg'], isA<String>());
      expect(learning['plaene'], isNotEmpty);
      // Zurück aus 3D: die Nachhilfe schließt, dieselbe Aufgabe ist offen.
      expect(find.byType(LumoNachhilfeScreen), findsNothing);
      final after = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      expect(after.taskInstanceId, task.taskInstanceId);
      expect(find.byKey(const ValueKey('nachhilfe-open')), findsOneWidget,
          reason: 'die Originalaufgabe ist weiter offen');

      // Dieselbe Rückgabe noch einmal (z. B. erneuter Rückruf): kein zweiter
      // Eintrag. Danach zählt eine neue Ergebnis-ID wieder einmal.
      await openTutor3D();
      expect(calls.where((call) => call.method == 'launch3D'), hasLength(2));
      var saved = false;
      app!.flushLearningProgress().then((_) => saved = true);
      for (var frame = 0; frame < 120 && !saved; frame++) {
        await _frames(tester, 1);
      }
      expect(saved, isTrue);
      await tester.runAsync(() async {
        final history = await app!.attemptLog.load();
        expect(history.where((entry) => entry.prompt == task.prompt), isEmpty,
            reason: 'Die Nachhilfe beantwortet die Originalaufgabe nie.');
        final twin =
            history.where((entry) => entry.prompt == twinPrompt).toList();
        expect(twin, hasLength(1),
            reason: 'Zwilling genau einmal als Nachweis');
        expect(twin.single.correct, isTrue);
        expect(twin.single.hintUsed, isFalse);
      });
      expect((app!.state.stars, app!.state.xp), before,
          reason: 'Die Nachhilfe bucht weder Sterne noch XP.');
      final error = tester.takeException();
      expect(error == null || '$error'.contains('audioplayers'), isTrue,
          reason: '$error');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    }
  });

  testWidgets('3D-Start scheitert: die 2D-Nachhilfe bleibt offen',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      throw PlatformException(code: 'invalid_learning');
    });
    try {
      final aufgabe = NachhilfeAufgabe.addition(8, 5)!;
      var opened = 0;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LumoNachhilfeScreen(
                      aufgabe: aufgabe,
                      reduceMotion: true,
                      open3D: (context, activity) async {
                        opened++;
                        return false;
                      },
                    ),
                  ),
                ),
                child: const Text('Aufgabe'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Aufgabe'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('nachhilfe-3d'));
      await tester.scrollUntilVisible(button, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.byType(LumoNachhilfeScreen), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    }
  });
}
