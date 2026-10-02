import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/app_update_service.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/parental_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RewardWalletRepository.instance.reset();
  });
  test('Proxy-URL entfernt bekannte Endpunkte ohne Domain-Beschädigung', () {
    for (final suffix in ['', '/', '/health', '/chat/', '/tasks?x=1#old']) {
      expect(
        AppSettings.sanitizeProxyUrl(
          'https://lumo-ai-proxy.onrender.com$suffix',
        ),
        'https://lumo-ai-proxy.onrender.com',
      );
    }
    expect(
      AppSettings.sanitizeProxyUrl('https://user:secret@example.com/chat'),
      AppSettings.defaultAiProxyUrl,
    );
  });
  test(
    'APK-Download akzeptiert nur das Lumo-Repo und echte GitHub-Weiterleitungen',
    () {
      expect(
        AppUpdateService.isTrustedReleaseUrl(
          Uri.parse(
            'https://github.com/Ullmann27/lumo-lernen/releases/download/build-260/Lumo-Lernen-latest.apk',
          ),
        ),
        true,
      );
      expect(
        AppUpdateService.isTrustedDownloadRedirect(
          Uri.parse('https://release-assets.githubusercontent.com/file.apk'),
        ),
        true,
      );
      for (final url in [
        'http://github.com/Ullmann27/lumo-lernen/releases/download/x/a.apk',
        'https://github.com.evil.example/a.apk',
        'https://github.com/other/app/releases/download/x/a.apk',
      ]) {
        expect(AppUpdateService.isTrustedReleaseUrl(Uri.parse(url)), false);
      }
    },
  );
  test(
    'Lernbelohnung überlebt neuen App-State, auch eine komplett leere Wallet',
    () async {
      final first = LumoAppState();
      await first.hydrateFromWallet();
      expect(first.state.stars, 0);
      expect(first.state.xp, 0);
      first.correctAnswer('Plus bis 10');
      await first.flushRewards();
      first.dispose();
      final second = LumoAppState();
      await second.hydrateFromWallet();
      expect(second.state.stars, 3);
      expect(second.state.xp, 20);
      second.addStars(-3);
      await second.flushRewards();
      second.dispose();
      final third = LumoAppState();
      await third.hydrateFromWallet();
      expect(third.state.stars, 0);
      third.dispose();
    },
  );
  test(
    'Angezeigte Lernbelohnung wird mit ihren tatsächlichen Werten gespeichert',
    () async {
      final state = LumoAppState();
      state.correctAnswer('Textaufgaben', stars: 7, xp: 45);
      await state.flushRewards();
      expect(state.state.stars, 7);
      expect(state.state.xp, 45);
      state.dispose();
      final restored = LumoAppState();
      await restored.hydrateFromWallet();
      expect(restored.state.stars, 7);
      expect(restored.state.xp, 45);
      restored.dispose();
    },
  );
  testWidgets(
    'Eltern-PIN verweigert falsche Eingabe und akzeptiert die konfigurierte PIN',
    (tester) async {
      bool? passed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  passed = await ParentalGate.show(context, pin: '7291');
                },
                child: const Text('Öffnen'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Bestätigen'));
      await tester.pumpAndSettle();
      expect(passed, isNull);
      expect(find.byType(ParentalGate), findsOneWidget);
      await tester.enterText(find.byType(TextField), '7291');
      await tester.tap(find.text('Bestätigen'));
      await tester.pumpAndSettle();
      expect(passed, true);
    },
  );
  testWidgets(
    'Renderer meldet Fehlversuche, lässt Wiederholung zu und meldet Hilfe',
    (tester) async {
      final events = <AdaptiveTaskAnswer>[];
      final task = TaskInstance(
        taskInstanceId: 'test',
        templateId: 'plus',
        childId: 'local',
        seedHash: '1',
        subject: LearningSubject.mathematik,
        skillId: const SkillId('addition'),
        taskType: TaskType.multipleChoice,
        difficulty: 1,
        parameters: const {},
        prompt: '2 + 3 = ?',
        options: const [
          AnswerOption(id: 'a', label: '4'),
          AnswerOption(id: 'b', label: '6'),
          AnswerOption(id: 'c', label: '5'),
        ],
        correctAnswer: '5',
        visualPayload: const VisualPayload(
          type: VisualType.dots,
          data: {'count': 5},
        ),
        helpPayload: const HelpPayload(),
        generatedAt: DateTime(2026),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdaptiveTaskRenderer(task: task, onAnswered: events.add),
            ),
          ),
        ),
      );
      await tester.tap(find.text('4').last);
      await tester.pump();
      await tester.tap(find.text('6').last);
      await tester.pump();
      await tester.tap(find.text('5').last);
      await tester.pump();
      expect(events.map((e) => e.correct).toList(), [false, false, true]);
      expect(events.last.hintUsed, true);
      expect(tester.takeException(), isNull);
    },
  );
}
