import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/design/lumo_answer_crystal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final (kind, scale) in [
    (LumoSessionKind.schoolwork, 1.0),
    (LumoSessionKind.quickPractice, 1.0),
    (LumoSessionKind.schoolwork, 2.0),
    (LumoSessionKind.quickPractice, 2.0),
  ]) {
    testWidgets(
      'incorrect $kind at text scale $scale keeps stars and XP unchanged',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final wallet = RewardWalletRepository();
        final state = LumoAppState(walletRepository: wallet);
        await tester.pump();
        state.update(
          state.state.copyWith(
            subject: 'Mathematik',
            unit: 'Plus bis 10',
            sessionKind: kind,
          ),
        );
        await wallet.addStars(5);
        await wallet.addXp(40);
        await state.hydrateFromWallet();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: LearningContent(appState: state)),
          ),
        );
        await tester.pump();
        final renderer = tester.widget<AdaptiveTaskRenderer>(
          find.byType(AdaptiveTaskRenderer),
        );
        // Regression: the real schoolwork/quick-practice Maths route must
        // actually render crystals; a standalone design fixture is not enough.
        expect(find.byType(LumoAnswerCrystal), findsWidgets);
        expect(
          tester
              .widgetList<LumoAnswerCrystal>(find.byType(LumoAnswerCrystal))
              .every((crystal) => crystal.state == LumoCrystalState.neutral),
          isTrue,
        );
        final wrong = renderer.task.options.firstWhere(
          (option) =>
              '${option.payload ?? option.label}' !=
              '${renderer.task.correctAnswer}',
        );
        await tester.ensureVisible(find
            .descendant(
                of: find.byType(AdaptiveTaskRenderer),
                matching: find.text(wrong.label))
            .last);
        await tester.pump();
        await tester.tap(
          find
              .descendant(
                of: find.byType(AdaptiveTaskRenderer),
                matching: find.text(wrong.label),
              )
              .last,
        );
        await tester.pump();
        // A wrong answer never costs stars. Schoolwork used to deduct two;
        // rewards now only reflect what succeeded.
        const expectedStars = 5;
        expect(state.state.stars, expectedStars);
        expect(state.state.xp, 40);
        if (kind == LumoSessionKind.schoolwork) {
          expect(find.textContaining('-2'), findsNothing);
          expect(find.text('Kein Stern geht verloren'), findsOneWidget);
          // One try only, but the card explains why the answer is right.
          expect(find.byKey(const ValueKey('solution-why-box')), findsOneWidget);
          expect(find.text('So kommst du darauf:'), findsOneWidget);
          expect(find.textContaining('Richtige Antwort:'), findsOneWidget);
          expect(find.text('Lumo erklärt'), findsNothing);
        } else {
          // Practice: a second try with feedback instead of a result card.
          expect(
              find.byKey(const ValueKey('mistake-feedback-card')), findsOneWidget);
        }
        await state.flushRewards();
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();

        final restored =
            LumoAppState(walletRepository: RewardWalletRepository());
        await tester.pump();
        await restored.hydrateFromWallet();
        expect(restored.state.stars, expectedStars);
        expect(restored.state.xp, 40);
        restored.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
