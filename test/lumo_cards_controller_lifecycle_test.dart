import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_game_controller.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';

LumoCardsGameController _controller({bool vsBot = false}) =>
    LumoCardsGameController(
      player1Name: 'Du',
      player2Name: 'Lumo',
      vsBot: vsBot,
      enableVoice: false,
      seed: 20,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    LumoSound.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets('Paused handover cannot expose or advance the next hand',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    controller.drawCard();
    expect(controller.state.phase, GamePhase.passDevice);
    controller.turnClock.pause();
    final paused = controller.state;
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.confirmHandover();
    expect(controller.state, same(paused));
    expect(notifications, 0);
    await tester.pump(const Duration(seconds: 3));
    expect(controller.state, same(paused));

    controller.turnClock.resume();
    controller.confirmHandover();
    expect(controller.state.phase, GamePhase.playing);
    expect(controller.state.currentPlayerIndex, paused.currentPlayerIndex);
    expect(notifications, 1);
  });

  testWidgets('Disposed controller ignores delayed card and restart callbacks',
      (tester) async {
    final controller = _controller(vsBot: true);
    final previous = controller.state;
    final tapped = previous.currentPlayer.hand.first;
    controller.dispose();

    expect(() => controller.playCard(tapped), returnsNormally);
    expect(controller.drawCard, returnsNormally);
    expect(() => controller.selectColor(LumoCardColor.blue), returnsNormally);
    expect(() => controller.answerLearningQuestion(0), returnsNormally);
    expect(controller.confirmHandover, returnsNormally);
    expect(controller.restart, returnsNormally);
    expect(controller.state, same(previous));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Listener disposal does not schedule another bot action',
      (tester) async {
    final controller = _controller(vsBot: true);
    // Navigation can synchronously remove a game in response to a state event.
    controller.addListener(controller.dispose);
    controller.drawCard();
    final stopped = controller.state;
    await tester.pump(const Duration(seconds: 5));
    expect(controller.state, same(stopped));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Paused input stays inert and restart cancels the old bot turn',
      (tester) async {
    final controller = _controller(vsBot: true);
    addTearDown(controller.dispose);
    controller.drawCard();
    expect(controller.state.currentPlayerIndex, 1);
    controller.turnClock.pause();
    final paused = controller.state;
    controller.drawCard();
    controller.playCard(paused.players.first.hand.first);
    controller.selectColor(LumoCardColor.green);
    controller.answerLearningQuestion(0);
    controller.confirmHandover();
    expect(controller.state, same(paused));
    await tester.pump(const Duration(seconds: 5));
    expect(controller.state, same(paused));

    // Restart is deliberately allowed through the existing pause panel.
    controller.restart();
    final restarted = controller.state;
    expect(restarted.currentPlayerIndex, 0);
    expect(restarted.players.first.hand.length, 7);
    controller.turnClock.resume();
    await tester.pump(const Duration(seconds: 5));
    expect(controller.state, same(restarted));
    expect(tester.takeException(), isNull);
  });
}
