import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_player_hand.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_color_picker.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_learning_card_overlay.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_pass_device_overlay.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_result_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets('Played loss displays exactly the one star actually awarded',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final wallet = RewardWalletRepository();
    final app = LumoAppState(walletRepository: wallet);
    addTearDown(app.dispose);
    // A defeat must also end a previous win streak, without showing its bonus.
    await app.recordLumoCardsResult(won: true, resultId: 'previous-win-1');
    await app.recordLumoCardsResult(won: true, resultId: 'previous-win-2');
    final starsBefore = app.state.stars;
    final xpBefore = app.state.xp;
    app.updateSettings(const AppSettings(
        voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
    const boundary = ValueKey('cards-result-reward-capture');
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
          theme: LumoAppTheme.light(),
          debugShowCheckedModeBanner: false,
          home: LumoCardsScreen(
              appState: app, seed: 10, skipIntro: true, vsBot: false)),
    ));
    await tester.pump();
    await tester.pump();

    // Complete a fresh local two-player round via the actual controls. No
    // result injection or near-finish fixture: every hand starts with 7 cards.
    var played = 0;
    for (var tick = 0; tick < 250; tick++) {
      if (find.byType(LumoResultDialog).evaluate().isNotEmpty) break;
      if (find.byType(LumoPassDeviceOverlay).evaluate().isNotEmpty) {
        await tester.tap(find.text('Bereit'));
      } else if (find.byType(LumoColorPicker).evaluate().isNotEmpty) {
        await tester.tap(find.text('Blau'));
      } else if (find.byType(LumoLearningCardOverlay).evaluate().isNotEmpty) {
        final question = tester
            .widget<LumoLearningCardOverlay>(
                find.byType(LumoLearningCardOverlay))
            .question;
        // Decline the bonus so the wallet delta measures only round rewards.
        await tester.tap(find.text(question
            .options[(question.correctIndex + 1) % question.options.length]));
      } else {
        final hand = tester.widget<LumoPlayerHand>(find.byType(LumoPlayerHand));
        final legal = hand.cards.where((card) => LumoCardsRules.isPlayable(
            card: card,
            topCard: hand.topCard,
            selectedColor: hand.selectedColor));
        if (legal.isEmpty) {
          await tester.tap(find.text('Ziehen'));
        } else {
          final card = find.byKey(ValueKey('hand-${legal.first.id}'));
          await tester.ensureVisible(card);
          await tester.pump();
          await tester.tap(card);
          played++;
        }
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(played, greaterThanOrEqualTo(7));
    expect(find.byType(LumoResultDialog), findsOneWidget);
    expect(
        tester.widget<LumoResultDialog>(find.byType(LumoResultDialog)).kindWon,
        isFalse);
    await app.flushRewards();
    await tester.pump();
    final paid = app.state.stars - starsBefore;
    expect(paid, 1);
    expect(app.state.xp, xpBefore);
    expect(app.lumoCardsWinStreak, 0);
    expect(find.text('Du bekommst 1 Trost-Stern. Naechstes Mal du!'),
        findsOneWidget);

    final output = Platform.environment['LUMO_CARDS_RESULT_CAPTURE'];
    if (output != null) {
      await captureLumoBoundary(tester, boundary, output, pixelRatio: 1.5);
    }
    final visibleStars = find.descendant(
      of: find.byKey(const ValueKey('cards-round-summary')),
      matching: find.byIcon(Icons.star_rounded),
    );
    final count = visibleStars.evaluate().length;
    final resultReward =
        tester.widget<LumoResultDialog>(find.byType(LumoResultDialog)).reward;
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(count, paid,
        reason: 'Visible golden stars must equal wallet payout');
    expect(resultReward, paid);
  });
}
