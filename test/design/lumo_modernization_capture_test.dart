// Echte Renderings der überarbeiteten Bereiche (kein Konzeptbild): der
// tatsächliche Widget-Baum mit echten Schriften und Bildern auf Fold-Außen-,
// Handy- und Fold-Innengröße. Läuft nur mit LUMO_CAPTURE_DIR=<ordner>.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/journal/lumo_journal_screen.dart';
import 'package:lumo_lernen/features/learning/lumo_rechentricks_poster_screen.dart';
import 'package:lumo_lernen/features/learning/renderers/writing_task_renderer.dart';
import 'package:lumo_lernen/features/lumo_welt/lumo_welt_screen.dart';
import 'package:lumo_lernen/features/magic_hub/lumo_magic_hub_screen.dart';
import 'package:lumo_lernen/features/photo_lesson/lumo_photo_lesson_screen.dart';
import 'package:lumo_lernen/features/reading/lumo_reading_buddy_screen.dart';
import 'package:lumo_lernen/features/rewards/achievements_wall_screen.dart';
import 'package:lumo_lernen/features/story/lumo_quest_hub_screen.dart';
import 'package:lumo_lernen/domain/writing/expanded_writing_template_repository.dart';
import 'package:lumo_lernen/domain/writing/writing_path_geometry.dart';
import 'package:lumo_lernen/features/writing/lumo_writing_coach_screen.dart';
import 'package:lumo_lernen/features/writing/widgets/lumo_letter_practice_board.dart';

import '../helpers/lumo_capture.dart';

final String? _out = Platform.environment['LUMO_CAPTURE_DIR'];
const _boundary = ValueKey('lumo-modernization-capture');

TaskInstance _writingTask(String target) => TaskInstance(
      taskInstanceId: 'capture-$target',
      templateId: 'writing-capture',
      childId: 'child-local',
      seedHash: 'capture',
      subject: LearningSubject.deutsch,
      skillId: const SkillId('de.letter_writing'),
      taskType: TaskType.writingCanvas,
      difficulty: 1,
      parameters: <String, Object?>{'symbol': target},
      prompt: 'Spure den Buchstaben $target nach.',
      correctAnswer: target,
      options: const [],
      visualPayload: VisualPayload(
          type: VisualType.writingPath,
          data: <String, Object?>{'symbol': target}),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 10, 16),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadLumoCaptureFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });

  final screens = <String, Widget Function(LumoAppState)>{
    'rechentricks': (_) => const LumoRechentricksPosterScreen(),
    'achievements': (s) => AchievementsWallScreen(appState: s),
    'journal': (s) => LumoJournalScreen(appState: s),
    'lumo_welt': (s) => LumoWeltScreen(appState: s),
    'foto_lektion': (s) => LumoPhotoLessonScreen(appState: s),
    'reading_buddy': (s) => LumoReadingBuddyScreen(appState: s),
    'lumo_quest': (s) => LumoQuestHubScreen(appState: s),
    'lumo_magic': (s) => LumoMagicHubScreen(appState: s),
    'schreibcoach': (s) => LumoWritingCoachScreen(appState: s),
    'schreibaufgabe': (_) => Scaffold(
          backgroundColor: LumoColors.appBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: WritingTaskRenderer(
                  task: _writingTask('B'), onSubmitted: (_) {}),
            ),
          ),
        ),
  };

  for (final size in lumoCaptureSizes.entries) {
    for (final screen in screens.entries) {
      testWidgets('capture ${screen.key} ${size.key}', (tester) async {
        await tester.binding.setSurfaceSize(size.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final state = LumoAppState(walletRepository: RewardWalletRepository());
        await tester.pump();
        state.update(state.state.copyWith(childName: 'Mia', grade: 2));
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LumoAppTheme.light(),
          home: RepaintBoundary(key: _boundary, child: screen.value(state)),
        ));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
        await captureLumoBoundary(
            tester, _boundary, '$_out/${screen.key}_${size.key}.png');
        // Layout problems are part of the evidence, not a capture failure.
        final error = tester.takeException();
        if (error != null) {
          File('$_out/${screen.key}_${size.key}.error.txt')
              .writeAsStringSync('$error');
        }
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      }, skip: _out == null);
    }
  }

  // The trainer itself: empty, and after a child traced along the guide.
  for (final size in lumoCaptureSizes.entries) {
    for (final symbol in ['B', 'a']) {
      testWidgets('capture trainer $symbol ${size.key}', (tester) async {
        await tester.binding.setSurfaceSize(size.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final template =
            const ExpandedWritingTemplateRepository().findOrFallback(symbol);
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LumoAppTheme.light(),
          home: RepaintBoundary(
            key: _boundary,
            child: LumoLetterPracticePage(
              template: template,
              progressLabel: 'Buchstabe 3 von 8',
              onDone: (_) {},
              onClose: () {},
            ),
          ),
        ));
        await tester.pump();
        final name = symbol == 'a' ? 'klein_a' : symbol;
        await captureLumoBoundary(
            tester, _boundary, '$_out/trainer_${name}_${size.key}_leer.png');
        final rect = tester
            .getRect(find.byKey(const ValueKey('lumo-learning-ink-surface')));
        // Trace each guide stroke with a slight, child-like wobble.
        for (final line in template.strokes) {
          final points = WritingPathGeometry.sample(line.pathData);
          Offset at(int i) =>
              rect.topLeft +
              Offset(points[i].x / 100 * rect.width + (i % 5 - 2) * .8,
                  points[i].y / 100 * rect.height + (i % 3 - 1) * 1.1);
          final gesture = await tester.startGesture(at(0));
          for (var i = 1; i < points.length; i += 2) {
            await gesture.moveTo(at(i));
          }
          await gesture.up();
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 400));
        await captureLumoBoundary(
            tester, _boundary, '$_out/trainer_${name}_${size.key}_geuebt.png');
        final error = tester.takeException();
        if (error != null) {
          File('$_out/trainer_${name}_${size.key}.error.txt')
              .writeAsStringSync('$error');
        }
        await tester.pumpWidget(const SizedBox());
      }, skip: _out == null);
    }
  }
}
