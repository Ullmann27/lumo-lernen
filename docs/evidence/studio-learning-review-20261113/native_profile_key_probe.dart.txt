// Diagnostic fixture: this deliberately reproduces a pre-existing collision.
// It is not an acceptance test for correct profile isolation.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

Future<void> frames(WidgetTester tester, [int count = 30]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('diagnose real launcher identity for two stored student profiles',
      (tester) async {
    const channel = MethodChannel('lumo_lernen/bridge');
    SharedPreferences.setMockInitialValues(
        {'lumo_3d_save_salt_v1': 'synthetic-native-profile-review'});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    LumoVoice.instance.isEnabled = false;
    final calls = <MethodCall>[];
    final results = <bool>[];
    LumoAppState? app;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, Object?>{'destination': 'games'};
    });
    try {
      late String firstId;
      late String secondId;
      await tester.runAsync(() async {
        app = LumoAppState();
        app!.update(app!.state.copyWith(childName: 'Testkind', grade: 2));
        final classes = await app!.school.addClass('Review-Klasse', 2);
        final classId = classes.classes.single.id;
        final first = await app!.school.addStudent(classId, 'Testkind');
        firstId = first.students.single.id;
        final both = await app!.school.addStudent(classId, 'Testkind');
        secondId = both.students.last.id;
        expect(firstId, isNot(secondId));
        expect(both.students.map((student) => student.name),
            ['Testkind', 'Testkind']);
        await app!.school.setActiveStudent(firstId);
        await app!.loadLearningProfile();
        app!.updateSettings(const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            soundEnabled: false,
            reduceAnimations: true,
            requireDailyMissionForGames: false));
      });
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              results.add(await launchLumo3D(context,
                  scene: 'puzzle', appState: app));
            },
            child: const Text('Puzzle öffnen'),
          );
        }),
      )));

      final owners = <String>[];
      for (final id in [firstId, secondId]) {
        await tester.runAsync(() async {
          await app!.school.setActiveStudent(id);
          await app!.loadLearningProfile();
          final lease = await app!.captureLearningProfile();
          owners.add(lease.studentId);
          expect(lease.studentId, id);
        });
        await tester.tap(find.text('Puzzle öffnen'));
        await frames(tester);
      }
      expect(results, [true, true]);
      expect(calls, hasLength(2));
      expect(calls.every((call) => call.method == 'launch3D'), isTrue);
      final firstOptions = Map<String, Object?>.from(calls[0].arguments as Map);
      final secondOptions = Map<String, Object?>.from(calls[1].arguments as Map);
      expect(owners[0], isNot(owners[1]));
      expect(firstOptions['scene'], 'puzzle');
      expect(secondOptions['scene'], 'puzzle');
      expect(firstOptions['childKey'], secondOptions['childKey'],
          reason: 'Known issue: stable school selection does not enter key.');
      expect(firstOptions.containsKey('profileId'), isFalse);
      expect(secondOptions.containsKey('profileId'), isFalse);

      app!.update(app!.state.copyWith(grade: 3));
      await tester.tap(find.text('Puzzle öffnen'));
      await frames(tester);
      expect(results, [true, true, true]);
      final renamedOptions = Map<String, Object?>.from(calls[2].arguments as Map);
      expect(renamedOptions['childKey'], isNot(secondOptions['childKey']),
          reason: 'Known issue: a grade change creates another native key.');
      print('[NativeProfileReview] COLLISION_CONFIRMED ${jsonEncode({
        'distinctStoredProfiles': owners.length,
        'learningProfileOwnersDistinct': owners[0] != owners[1],
        'scene': firstOptions['scene'],
        'firstChildKey': firstOptions['childKey'],
        'secondChildKey': secondOptions['childKey'],
        'profileIdPresent': secondOptions.containsKey('profileId'),
        'gradeChangeChildKey': renamedOptions['childKey'],
        'scope': 'In-memory school storage, actual UI tap, production launcher; mocked Android boundary only',
      })}');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });
}
