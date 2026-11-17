import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning_modules/artikel_lernen/artikel_lernen_screen.dart';
import 'package:lumo_lernen/features/learning_modules/farben/farben_screen.dart';
import 'package:lumo_lernen/features/learning_modules/formen/formen_screen.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';
import 'package:lumo_lernen/features/learning_modules/tiere/tiere_screen.dart';
import 'package:lumo_lernen/features/learning_modules/wetter/wetter_screen.dart';
import '../helpers/lumo_capture.dart';

const _out = String.fromEnvironment(
  'LUMO_LERN_OPTIK_OUT',
  defaultValue: '.ci-results/lern-optik',
);

const _boundary = ValueKey('lern-optik-capture');

TaskInstance _wordImageTask() {
  return TaskInstance(
    taskInstanceId: 'g1-word-image-hund',
    templateId: 'g1_word_image',
    childId: 'capture',
    seedHash: '0',
    subject: LearningSubject.deutsch,
    skillId: const SkillId('g1_word_image'),
    taskType: TaskType.imageWord,
    difficulty: 1,
    parameters: const {'unit': 'Wort-Bild-Zuordnung', 'grade': 1},
    prompt: 'Welches Wort passt zum Bild: 🐶?',
    options: const [
      AnswerOption(id: 'a', label: 'Hund', payload: 'Hund'),
      AnswerOption(id: 'b', label: 'Katze', payload: 'Katze'),
      AnswerOption(id: 'c', label: 'Maus', payload: 'Maus'),
      AnswerOption(id: 'd', label: 'Haus', payload: 'Haus'),
    ],
    correctAnswer: 'Hund',
    visualPayload: const VisualPayload(type: VisualType.none),
    helpPayload: const HelpPayload(),
    generatedAt: DateTime(2026, 11, 10),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    await loadLumoCaptureFonts();
    await loadLumoCaptureEmojiFont();
  });

  tearDown(() => LumoVoice.instance.isEnabled = false);

  Future<LumoAppState> app() async {
    return LumoAppState(walletRepository: RewardWalletRepository());
  }

  Future<void> pumpCapture(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: _boundary,
          child: child,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  final sizes = <String, Size>{
    'phone': lumoCaptureSizes['phone']!,
    'fold': lumoCaptureSizes['fold-open']!,
  };

  for (final entry in sizes.entries) {
    testWidgets('word-image ${entry.key}', (tester) async {
      await pumpCapture(
        tester,
        entry.value,
        Scaffold(
          backgroundColor: const Color(0xFF071433),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AdaptiveTaskRenderer(task: _wordImageTask()),
            ),
          ),
        ),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_out/word_image_${entry.key}.png',
      );
      expect(find.byType(AdaptiveTaskRenderer), findsOneWidget);
    });

    testWidgets('tiere ${entry.key}', (tester) async {
      final state = await app();
      addTearDown(state.dispose);
      await pumpCapture(
        tester,
        entry.value,
        TiereScreen(appState: state),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_out/tiere_${entry.key}.png',
      );
      expect(find.byType(TiereScreen), findsOneWidget);
    });

    testWidgets('farben ${entry.key}', (tester) async {
      final state = await app();
      addTearDown(state.dispose);
      await pumpCapture(
        tester,
        entry.value,
        FarbenScreen(appState: state),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_out/farben_${entry.key}.png',
      );
      expect(find.byType(FarbenScreen), findsOneWidget);
    });

    testWidgets('artikel ${entry.key}', (tester) async {
      final state = await app();
      addTearDown(state.dispose);
      await pumpCapture(
        tester,
        entry.value,
        ArtikelLernenScreen(appState: state),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_out/artikel_${entry.key}.png',
      );
      expect(find.byType(ArtikelLernenScreen), findsOneWidget);
    });

    testWidgets('plus10 ${entry.key}', (tester) async {
      final state = await app();
      addTearDown(state.dispose);
      await pumpCapture(
        tester,
        entry.value,
        PlusBis10Screen(appState: state),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_out/plus10_${entry.key}.png',
      );
      expect(find.byType(PlusBis10Screen), findsOneWidget);
    });

    testWidgets('formen ${entry.key}', (tester) async {
      final state = await app();
      addTearDown(state.dispose);
      await pumpCapture(
        tester,
        entry.value,
        FormenScreen(appState: state),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_out/formen_${entry.key}.png',
      );
      expect(find.byType(FormenScreen), findsOneWidget);
    });

    testWidgets('wetter ${entry.key}', (tester) async {
      final state = await app();
      addTearDown(state.dispose);
      await pumpCapture(
        tester,
        entry.value,
        WetterScreen(appState: state),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_out/wetter_${entry.key}.png',
      );
      expect(find.byType(WetterScreen), findsOneWidget);
    });
  }
}
