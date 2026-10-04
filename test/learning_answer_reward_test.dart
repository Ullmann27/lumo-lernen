import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final kind in [
    LumoSessionKind.schoolwork,
    LumoSessionKind.quickPractice,
  ]) {
    testWidgets(
      'incorrect $kind answer updates the wallet without earning XP',
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
            home: Scaffold(body: LearningContent(appState: state)),
          ),
        );
        await tester.pump();
        final renderer = tester.widget<AdaptiveTaskRenderer>(
          find.byType(AdaptiveTaskRenderer),
        );
        final wrong = renderer.task.options.firstWhere(
          (option) =>
              '${option.payload ?? option.label}' !=
              '${renderer.task.correctAnswer}',
        );
        await tester.tap(
          find
              .descendant(
                of: find.byType(AdaptiveTaskRenderer),
                matching: find.text(wrong.label),
              )
              .last,
        );
        await tester.pump();
        final expectedStars = kind == LumoSessionKind.schoolwork ? 3 : 5;
        expect(state.state.stars, expectedStars);
        expect(state.state.xp, 40);
        if (kind == LumoSessionKind.schoolwork) {
          expect(find.text('-2 Sterne'), findsOneWidget);
          expect(find.text('Lumo erklärt'), findsNothing);
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
