import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/daily_mission_repository.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

const _hostRevision = 'a8e09123805b2bf30706c8dd1914b928ae6b24ca';
const _sourceBlobs = <String, String>{
  'lib/domain/tutoring/native_learning_activity.dart':
      '83463a26665cd0b58aa776c28f6dec1600552e3d',
  'lib/features/learning/adapters/legacy_lumo_task_adapter.dart':
      'f23b67f5b7c34c4d8518cbced2dd56f97d7ddb41',
  'lib/features/learning/renderers/lumo_premium_visuals.dart':
      '13c16636cd84dd809d7539fdc12635dba3e66bd3',
  'tools/auto_install/MainActivity.kt':
      'd57bb538f745aca436fcd9bc547e692f055e82fa',
};
const _channel = MethodChannel('lumo_lernen/bridge');
const _codec = StandardMethodCodec();
const _cases = [
  (
    name: 'sharing_12_by_3',
    prompt: '12 : 3 = ?',
    answer: '4',
    visual: 'division',
    expected: {'kind': 'equal_sharing', 'a': 12, 'b': 3},
  ),
  (
    name: 'groups_3_by_4',
    prompt: '3 × 4 = ?',
    answer: '12',
    visual: 'times_table',
    expected: {'kind': 'equal_groups', 'a': 3, 'b': 4},
  ),
  (
    name: 'groups_4_by_3',
    prompt: '4 × 3 = ?',
    answer: '12',
    visual: 'times_table',
    expected: {'kind': 'equal_groups', 'a': 4, 'b': 3},
  ),
  (
    name: 'fraction_1_plus_2_quarters',
    prompt: '1/4 + 2/4 = ?',
    answer: '3/4',
    visual: 'fraction_add',
    expected: {'kind': 'fraction_parts', 'a': 1, 'b': 4, 'extra': 2},
  ),
  (
    name: 'fraction_reduced_half',
    prompt: '1/4 + 1/4 = ?',
    answer: '1/2',
    visual: 'fraction_add',
    expected: {'kind': 'fraction_parts', 'a': 1, 'b': 4, 'extra': 1},
  ),
];

Future<void> _frames(WidgetTester tester) async {
  for (var frame = 0; frame < 40; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real launch payloads survive codec and JSON with saved caller identity',
    (tester) async {
      final exported = <Map<String, Object?>>[];
      final now = DateTime.utc(2026, 11, 13, 12, 46, 30);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        for (final scenario in _cases) {
          SharedPreferences.setMockInitialValues({
            'lumo_3d_save_salt_v1': 'synthetic-studio-json-contract',
          });
          final app = (await tester.runAsync(
            () async => LumoAppState(
              walletRepository: RewardWalletRepository(),
              dailyMissionFactory: (studentId) =>
                  DailyMissionRepository(studentId: studentId, now: () => now),
            ),
          ))!;
          try {
            await tester.runAsync(() async {
              app.update(app.state.copyWith(grade: 4, subject: 'Mathematik'));
              await app.school.setActiveStudent('synthetic-${scenario.name}');
              await app.hydrateFromWallet();
              await app.loadLearningProfile();
              app.updateSettings(
                const AppSettings(
                  voiceEnabled: false,
                  autoReadEnabled: false,
                  reduceAnimations: true,
                  requireDailyMissionForGames: true,
                ),
              );
              await app.loadDailyMission();
            });
            final owner = (await tester.runAsync(app.captureLearningProfile))!;
            final source = LumoTask(
              id: 'synthetic-${scenario.name}',
              grade: 4,
              subject: 'Mathematik',
              unit: 'Mathematik',
              prompt: scenario.prompt,
              answer: scenario.answer,
              choices: [scenario.answer, '97', '98'],
              explanation: 'Wir zeigen dieselbe Aufgabe mit Objekten.',
              visual: scenario.visual,
            );
            final task = const LegacyLumoTaskAdapter().toTaskInstance(
              task: source,
              childId: owner.studentId,
              difficulty: 2,
              now: now,
            );
            final activity = NativeLearningActivity.fromTask(task);
            expect(activity, isNotNull, reason: scenario.name);
            expect(task.prompt, source.prompt);
            final origin = <String, Object?>{
              'taskInstanceId': task.taskInstanceId,
              'seedHash': task.seedHash,
              'templateId': task.templateId,
              'childId': task.childId,
              'legacyId': task.parameters['legacyId'],
              'prompt': task.prompt,
              'correctAnswer': task.correctAnswer,
              'generatedAt': task.generatedAt.toIso8601String(),
            };
            final beforePayload = activity!.toLaunchOptions();
            final calls = <MethodCall>[];
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(_channel, (call) async {
                  // Exercise the real Flutter wire codec. jsonEncode below models the
                  // Kotlin JSONObject(learning) boundary; it is not Android IPC proof.
                  calls.add(
                    _codec.decodeMethodCall(_codec.encodeMethodCall(call)),
                  );
                  return <String, Object?>{'destination': 'learn'};
                });
            late BuildContext context;
            await tester.pumpWidget(
              MaterialApp(
                home: Builder(
                  builder: (value) {
                    context = value;
                    return const Scaffold(
                      body: Text('Synthetische Vertragsaufgabe'),
                    );
                  },
                ),
              ),
            );
            expect(app.dailyMission!.completedCount, 0);
            final launched = launchLumo3D(
              context,
              scene: 'learning',
              appState: app,
              learning: activity,
            );
            await _frames(tester);
            expect(await launched, isTrue);
            expect(calls, hasLength(1));
            expect(calls.single.method, 'launch3D');
            final arguments = Map<String, Object?>.from(
              calls.single.arguments as Map,
            );
            expect(arguments['scene'], 'learning');
            final learning = Map<String, Object?>.from(
              arguments['learning'] as Map,
            );
            expect(learning, scenario.expected);
            final serialized = jsonEncode(learning);
            final decoded = jsonDecode(serialized) as Map<String, dynamic>;
            expect(decoded, scenario.expected);
            for (final key in [
              'a',
              'b',
              if (decoded.containsKey('extra')) 'extra',
            ]) {
              expect(
                decoded[key],
                isA<int>(),
                reason: '${scenario.name}: $key',
              );
            }
            expect(task.taskInstanceId, origin['taskInstanceId']);
            expect(task.seedHash, origin['seedHash']);
            expect(task.prompt, origin['prompt']);
            expect(task.correctAnswer, origin['correctAnswer']);
            expect(activity.toLaunchOptions(), beforePayload);
            expect(
              app.dailyMission!.completedCount,
              0,
              reason: 'Returning from an illustration is not an answer.',
            );
            expect(app.state.stars, 0);

            // Only an explicit answer uses the existing persistence API. Reload
            // actual saved bytes and replay the original identity through a new
            // repository instance, without adding an identity to the native wire.
            late Map<String, dynamic> saved;
            late int replayCount;
            await tester.runAsync(() async {
              await app.recordLearningAnswer(
                subject: source.subject,
                unit: source.unit,
                correct: true,
                hintUsed: true,
                requireSaved: true,
                taskId: task.taskInstanceId,
                prompt: task.prompt,
                given: '${task.correctAnswer}',
                expected: '${task.correctAnswer}',
              );
              final prefs = await SharedPreferences.getInstance();
              final key = LearningDataNamespace.keyFor(
                'lumo_daily_mission_v1',
                owner.studentId,
              );
              saved = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
              final restarted = DailyMissionRepository(
                studentId: owner.studentId,
                now: () => now,
              );
              expect((await restarted.load()).completedCount, 1);
              replayCount = (await restarted.recordAnswer(
                taskId: task.taskInstanceId,
                subject: source.subject,
                correct: true,
              )).completedCount;
            });
            final taskHash = sha256
                .convert(utf8.encode(task.taskInstanceId))
                .toString();
            expect(saved['acceptedTaskIds'], [taskHash]);
            expect(app.dailyMission!.completedCount, 1);
            expect(replayCount, 1);
            exported.add({
              'name': scenario.name,
              'serialized_payload': serialized,
              'expected': scenario.expected,
              'origin': origin,
              'persistence': {
                'mission_task_sha256': taskHash,
                'count_after_native_return': 0,
                'count_after_answer': app.dailyMission!.completedCount,
                'count_after_replay': replayCount,
              },
            });
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            app.dispose();
          }
        }

        expect(exported, hasLength(_cases.length));
        expect(
          exported
              .map((item) => (item['origin'] as Map)['taskInstanceId'])
              .toSet(),
          hasLength(_cases.length),
        );
        final document = <String, Object>{
          'schema': 1,
          'host_revision': _hostRevision,
          'host_source_blobs': _sourceBlobs,
          'boundary':
              'Real Dart launch and StandardMethodCodec; jsonEncode models '
              'Kotlin JSONObject(learning). This is not Android IPC evidence.',
          'cases': exported,
        };
        const fixturePath = String.fromEnvironment(
          'LUMO_LEARNING_CONTRACT_FIXTURE',
          defaultValue: 'test/fixtures/learning_host_payloads.json',
        );
        expect(
          jsonDecode(File(fixturePath).readAsStringSync()),
          document,
          reason: 'Both runtimes consume the same frozen host fixture.',
        );
        const destination = String.fromEnvironment(
          'LUMO_LEARNING_CONTRACT_EXPORT',
        );
        if (destination.isNotEmpty) {
          for (final source in _sourceBlobs.entries) {
            final bytes = File(source.key).readAsBytesSync();
            final blob = sha1.convert([
              ...utf8.encode('blob ${bytes.length}\u0000'),
              ...bytes,
            ]).toString();
            expect(
              blob,
              source.value,
              reason: 'Export provenance: ${source.key}',
            );
          }
          final file = File(destination)..parent.createSync(recursive: true);
          file.writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert(document)}\n',
          );
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, null);
      }
    },
  );
}
