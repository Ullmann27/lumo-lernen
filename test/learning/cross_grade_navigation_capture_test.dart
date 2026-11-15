import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/learning/curriculum_activities_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import '../helpers/lumo_capture.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoCompanionRequests.instance.clearLearningScope();
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets('captures full live route and current task contract',
      (tester) async {
    const output = 'docs/learning/nextgen-20261115/evidence/cross-grade';
    const window = ValueKey('cross-grade-whole-window');
    final manifest = <Map<String, Object?>>[];
    final sizes = <String, Size>{
      'phone-small-320x780': const Size(320, 780),
      'fold-cover-logical-344x882': lumoCaptureSizes['fold-cover']!,
      'fold-open-logical-690x829': lumoCaptureSizes['fold-open']!,
    };
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final entry in sizes.entries) {
      await tester.binding.setSurfaceSize(entry.value);
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await tester.pumpWidget(RepaintBoundary(
        key: window,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LumoAppTheme.light(),
          home: CurriculumActivitiesScreen(
              grade: 1, subject: 'Kunst und Gestaltung', appState: app),
        ),
      ));
      await _frames(tester);
      final link =
          find.byKey(const ValueKey('activity-g1_art_notice-practice'));
      await tester.scrollUntilVisible(link, 240,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(link);
      await _frames(tester);
      expect(link.hitTestable(), findsOneWidget);
      await tester.tap(link);
      await _frames(tester);
      expect(find.byType(CrossGradePracticeScreen), findsOneWidget);
      final current = LumoCompanionRequests.instance.taskContext.value;
      expect(current, isNotNull);
      expect(current!.unit, 'Geometrie Formen');
      expect(current.answering, isTrue);
      expect(current.objectIds, contains('task-workspace'));
      expect(current.answerChoices, isNotEmpty);
      await captureLumoBoundary(
          tester, window, '$output/${entry.key}-entry.png',
          pixelRatio: 1.5);
      final prompt = find.byKey(const ValueKey('cross-grade-question'));
      await Scrollable.ensureVisible(tester.element(prompt), alignment: .05);
      await _frames(tester);
      expect(prompt.hitTestable(), findsOneWidget);
      await captureLumoBoundary(tester, window, '$output/${entry.key}-task.png',
          pixelRatio: 1.5);
      manifest.add({
        'viewport': entry.key,
        'logicalWidth': entry.value.width,
        'logicalHeight': entry.value.height,
        'pixelRatio': 1.5,
        'route':
            'CurriculumActivitiesScreen / g1_art_notice / CrossGradePracticeScreen',
        'taskId': current.taskId,
        'prompt': current.prompt,
        'objectIds': current.objectIds,
        'answerChoices': current.answerChoices,
        'profileSource': 'fresh local QA fixture; no real child data',
        'capture': 'unaltered whole Flutter window with actual navigation',
      });
      expect(app.learningSkills(), isEmpty);
      expect(app.state.stars, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app.dispose();
      LumoCompanionRequests.instance.clearLearningScope();
    }
    File('$output/manifest.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
